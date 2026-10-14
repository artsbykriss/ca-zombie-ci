// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/// Fountain Protocol (Oasis Emerald) — live-state & attack-path PoC.
/// Read-only: forks public Emerald RPC at a pinned block; no mainnet txs.
/// Run: forge test -vvv (CI) with OASIS_RPC env (defaults to public endpoint).

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface ICToken {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function underlying() external view returns (address);
    function getCash() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function getAccountSnapshot(address) external view returns (uint256, uint256, uint256, uint256);
    function accrualBlockTimestamp() external view returns (uint256);
    function accrueInterest() external returns (uint256);
    function mint(uint256) external returns (uint256);
    function mint() external payable;
    function redeem(uint256) external returns (uint256);
    function redeemUnderlying(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
    function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function _addReserves(uint256) external returns (uint256);
    function sweepToken(address token) external;
}

interface IComptroller {
    function admin() external view returns (address);
    function pauseGuardian() external view returns (address);
    function oracle() external view returns (address);
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint256);
    function seizeGuardianPaused() external view returns (bool);
    function transferGuardianPaused() external view returns (bool);
    function mintGuardianPaused(address) external view returns (bool);
    function borrowGuardianPaused(address) external view returns (bool);
    function markets(address) external view returns (bool, uint256, bool);
    function getAllMarkets() external view returns (address[] memory);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
    function compAccrued(address) external view returns (uint256);
    function claimComp(address holder) external;
    function enterMarkets(address[] calldata) external returns (uint256[] memory);
    function comptrollerImplementation() external view returns (address);
    function _setSeizePaused(bool) external returns (bool);
    function _setMintPaused(address, bool) external returns (bool);
}

interface IOracle {
    function getUnderlyingPrice(address cToken) external view returns (int256);
    function price(string calldata symbol) external view returns (int256);
}

interface IBand {
    function getReferenceData(string calldata, string calldata)
        external view returns (uint256 rate, uint256 lastUpdatedBase, uint256 lastUpdatedQuote);
}

/// Malicious "token" used to probe the unprotected sweepToken callback path.
contract MaliciousToken {
    ICToken public immutable market;
    bool public attempted;
    uint256 public seizeResult;
    constructor(ICToken m) { market = m; }
    function balanceOf(address) external pure returns (uint256) { return 0; }
    function transfer(address, uint256) external returns (bool) {
        attempted = true;
        // msg.sender here is the cToken market; try to abuse it as a cToken caller
        seizeResult = market.seize(address(this), 0x9046fe485De18BB60a72172bC5Ce99Afa06Cf616, 1);
        return true;
    }
}

contract FountainForkTest is Test {
    // ---- pinned fork ----
    uint256 constant FORK_BLOCK = 22_380_248;

    // comptrollers
    address constant COMP_CLASSIC = 0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841;
    address constant COMP_USD     = 0x1C0C30795802Bf2B3232a824f41629BbBCF63127;
    address constant COMP_LPT     = 0x7c4d0c834701C6E7F57b8c1424d30aDC46eA0840;
    // classic markets
    address constant FROSE_C = 0xD7d588bAbFb99E82Cd6dd0cA7677A5599AA678B5;
    address constant FETH_C  = 0x275b88547185D955F66E5dd1066E040af468fC66;
    address constant FUSDT_C = 0x352CC3320dEBfFa3046cF66A4e0a80d528f00285;
    address constant FUSDC_C = 0x61D90F6Ab2B2b1bAfFa39beBb5d8Ad57028dA258;
    // lpt markets
    address constant FROSE_L = 0x63f1Fe2E1da490611FC16E4a5d92b7ec7d0911a9;
    // usd markets
    address constant FUSDT_USD = 0x2552707D66C102c12b0f8284824F80e1299cB6B7;
    address constant FUSDC_W_USD = 0xbe5a2C8DA347311c46b1F0868aA52b8eb59938B3;
    address constant FUSDC_CELER_USD = 0x54cc15A99E40Cc4A6D8a2dDc1b8eE65A2D7414E1;
    // tokens
    address constant FTP = 0xd1dF9CE4b6159441D18BD6887dbd7320a8D52a05;
    address constant USDC = 0xE8A638b3B7565Ee7c5eb9755E58552aFc87b94DD;
    address constant USDT = 0xdC19A122e268128B5eE20366299fc7b5b199C8e3;
    // oracle + band
    address constant ORACLE_CLASSIC = 0x3789ae7132f2CAd96553d378d13c58Eb8508258F;
    address constant BAND = 0xDA7a001b254CD22e46d3eAB04d937489c93174C3;
    // actors
    address constant UNDERWATER = 0x4EC0306F5d0E40Bc6890031980691E832321b09a; // classic shortfall
    address constant SUPPLIER_FUSDT = 0xF8aaE8D5dd1d7697a4eC6F561737e68a2ab8539e; // top fUSDT holder
    address constant ATTACKER = address(0xBADBEEF);

    IComptroller compC = IComptroller(COMP_CLASSIC);
    IComptroller compL = IComptroller(COMP_LPT);
    IComptroller compU = IComptroller(COMP_USD);

    function setUp() public {
        // In CI the authoritative run uses a local anvil fork (started by ci/run.sh);
        // set OASIS_RPC to point elsewhere. Default: local anvil.
        string memory rpc = vm.envOr("OASIS_RPC", string("http://127.0.0.1:8545"));
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    // ------------------------------------------------------------------
    // 1. live-state re-verification
    // ------------------------------------------------------------------
    function test_A_live_state_pauses_and_cash() public {
        // classic: mint+borrow paused per market; transfer+seize paused globally
        assertTrue(compC.seizeGuardianPaused(), "classic seize paused");
        assertTrue(compC.transferGuardianPaused(), "classic transfer paused");
        address[4] memory mC = [FROSE_C, FETH_C, FUSDT_C, FUSDC_C];
        for (uint i = 0; i < 4; i++) {
            assertTrue(compC.mintGuardianPaused(mC[i]), "classic mint paused");
            assertTrue(compC.borrowGuardianPaused(mC[i]), "classic borrow paused");
            (bool listed, uint cf,) = compC.markets(mC[i]);
            assertTrue(listed, "listed");
            assertEq(cf, 0.6e18, "cf 0.6");
        }
        // lpt: same
        assertTrue(compL.seizeGuardianPaused(), "lpt seize paused");
        assertTrue(compL.transferGuardianPaused(), "lpt transfer paused");
        assertTrue(compL.mintGuardianPaused(FROSE_L), "lpt mint paused");
        assertTrue(compL.borrowGuardianPaused(FROSE_L), "lpt borrow paused");
        // usd: open
        assertFalse(compU.seizeGuardianPaused(), "usd seize open");
        assertFalse(compU.transferGuardianPaused(), "usd transfer open");
        assertFalse(compU.mintGuardianPaused(FUSDT_USD), "usd mint open");
        assertFalse(compU.borrowGuardianPaused(FUSDT_USD), "usd borrow open");
        // cash (live at pinned block)
        assertEq(ICToken(FROSE_C).getCash(), 322_698_736_853_286_673_828_371);
        assertEq(ICToken(FETH_C).getCash(), 4_641_647_468_444_006_221);
        assertEq(ICToken(FUSDT_C).getCash(), 78_869_089_434);
        assertEq(ICToken(FUSDC_C).getCash(), 337_935_183);
        assertEq(ICToken(FROSE_L).getCash(), 57_083_286_889_792);
        // roles
        assertEq(compC.admin(), 0x5d4Ae9eCBeEa7038324582d8b4b745a715ddfB72); // Timelock
        assertEq(compL.admin(), 0x4ce41518591272a42406b4829f6c4F66907891e9); // EOA
        assertEq(compU.admin(), 0x4ce41518591272a42406b4829f6c4F66907891e9);
        assertEq(compC.pauseGuardian(), 0xc8C8Ae893611a617d128742ABE5aed7952c71b7c); // FTPGuardian
    }

    function test_B_mint_is_paused() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("mint is paused"));
        ICToken(FUSDT_C).mint(100e6);

        vm.deal(ATTACKER, 10 ether);
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("mint is paused"));
        ICToken(FROSE_C).mint{value: 1 ether}();

        // lpt too
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("mint is paused"));
        ICToken(FROSE_L).mint{value: 1 ether}();
    }

    function test_C_borrow_is_paused() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("borrow is paused"));
        ICToken(FUSDT_C).borrow(1e6);
    }

    function test_D_ctoken_transfer_is_paused() public {
        // even a legitimate holder cannot move cTokens
        uint256 bal = ICToken(FUSDT_C).balanceOf(SUPPLIER_FUSDT);
        assertGt(bal, 1e12, "holder has cTokens");
        vm.prank(SUPPLIER_FUSDT);
        vm.expectRevert(bytes("transfer is paused"));
        ICToken(FUSDT_C).transfer(ATTACKER, 1e12);
    }

    function test_E_seize_is_paused() public {
        // direct seize() is gated by the global pause before any auth check
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("seize is paused"));
        ICToken(FROSE_C).seize(ATTACKER, UNDERWATER, 1);
    }

    function test_F_liquidation_blocked_even_with_live_shortfall() public {
        // the borrower is deeply underwater at live oracle prices
        (uint err, uint liq, uint shortfall) = compC.getAccountLiquidity(UNDERWATER);
        assertEq(err, 0);
        assertEq(liq, 0);
        assertGt(shortfall, 1e21, "shortfall > $1000");
        // fund liquidator with USDC, approve, attempt liquidation of fUSDC debt seizing fROSE
        deal(USDC, ATTACKER, 200e6);
        vm.prank(ATTACKER);
        IERC20(USDC).approve(FUSDC_C, type(uint256).max);
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("seize is paused"));
        ICToken(FUSDC_C).liquidateBorrow(UNDERWATER, 100e6, FROSE_C);
    }

    function test_G_claimComp_fresh_attacker_gets_zero() public {
        assertEq(compC.compAccrued(ATTACKER), 0);
        uint256 before = IERC20(FTP).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        compC.claimComp(ATTACKER);
        assertEq(IERC20(FTP).balanceOf(ATTACKER), before, "no free FTP");
    }

    // ------------------------------------------------------------------
    // 2. H-O: holder-only recovery still works
    // ------------------------------------------------------------------
    function test_H_ho_supplier_redeem_works() public {
        uint256 usdtBefore = IERC20(USDT).balanceOf(SUPPLIER_FUSDT);
        vm.prank(SUPPLIER_FUSDT);
        uint256 e = ICToken(FUSDT_C).redeemUnderlying(1_000e6);
        assertEq(e, 0, "redeem ok");
        assertEq(IERC20(USDT).balanceOf(SUPPLIER_FUSDT) - usdtBefore, 1_000e6, "received USDT");
    }

    function test_I_ho_claimComp_holder_works() public {
        uint256 accrued = compC.compAccrued(UNDERWATER);
        assertGt(accrued, 1e18, "has accrued FTP");
        uint256 before = IERC20(FTP).balanceOf(UNDERWATER);
        vm.prank(UNDERWATER);
        compC.claimComp(UNDERWATER);
        assertGt(IERC20(FTP).balanceOf(UNDERWATER) - before, 0, "claimed FTP");
    }

    // ------------------------------------------------------------------
    // 3. usd comptroller (open) — dust only, no profitable path
    // ------------------------------------------------------------------
    function test_J_usd_open_but_dust_and_no_shortfall() public {
        assertEq(ICToken(FUSDT_USD).getCash(), 553_299);
        assertEq(ICToken(FUSDT_USD).totalBorrows(), 700_000);
        assertEq(ICToken(FUSDC_W_USD).getCash(), 0);
        assertEq(ICToken(FUSDC_CELER_USD).getCash(), 0);
        // the only borrower is over-collateralised -> no liquidation profit
        (uint err, uint liq, uint shortfall) = compU.getAccountLiquidity(0x9046fe485De18BB60a72172bC5Ce99Afa06Cf616);
        assertEq(err, 0);
        assertGt(liq, 0);
        assertEq(shortfall, 0);
    }

    function test_K_usd_empty_market_inflation_is_a_wash() public {
        // attacker mints the minimum into an empty market (fUSDC_wormhole; underlying = USDC)
        deal(USDC, ATTACKER, 1_000e6);
        vm.startPrank(ATTACKER);
        IERC20(USDC).approve(FUSDC_W_USD, type(uint256).max);
        assertEq(ICToken(FUSDC_W_USD).mint(1), 0); // 1 unit = 1e-6 USDC
        assertEq(ICToken(FUSDC_W_USD).totalSupply(), 100); // 1e16 exchange rate
        // donate 100 USDC via permissionless _addReserves
        assertEq(ICToken(FUSDC_W_USD)._addReserves(100e6), 0);
        uint256 exch = ICToken(FUSDC_W_USD).exchangeRateStored();
        uint256 mine = ICToken(FUSDC_W_USD).balanceOf(ATTACKER);
        uint256 claimable = mine * exch / 1e18;
        // claimable <= what was put in (no profit); nobody else is in the market
        assertLe(claimable, 100e6 + 1);
        assertEq(ICToken(FUSDC_W_USD).totalSupply(), mine);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // 4. oracle staleness + lpt bad debt
    // ------------------------------------------------------------------
    function test_L_oracle_is_stale() public {
        (uint256 rate, uint256 lastBase,) = IBand(BAND).getReferenceData("ETH", "USD");
        assertApproxEqRel(rate, 1_742_936_894_706_000_000_000, 1e15); // 0.1% (raw Band rate)
        assertLt(lastBase, block.timestamp - 30 days, "band ETH stale >30d");
        int256 p = IOracle(ORACLE_CLASSIC).getUnderlyingPrice(FETH_C);
        assertEq(p, int256(1_742_936_894_710_000_000_000));
        // ROSE price used by the protocol
        int256 pr = IOracle(ORACLE_CLASSIC).price("ROSE");
        assertEq(pr, int256(617_994));
    }

    function test_M_lpt_bad_debt_locked() public {
        // 13.3M ROSE of debt, ~0 cash -> suppliers cannot redeem meaningfully
        assertGt(ICToken(FROSE_L).totalBorrows(), 13_000_000e18);
        assertLt(ICToken(FROSE_L).getCash(), 1e15); // < 0.001 ROSE
        assertTrue(compL.mintGuardianPaused(FROSE_L));
        assertTrue(compL.borrowGuardianPaused(FROSE_L));
        assertTrue(compL.seizeGuardianPaused());
    }

    // ------------------------------------------------------------------
    // 6. sweepToken (inherited pre-fix Compound: no admin guard) — negative result
    // ------------------------------------------------------------------
    function test_O_sweeptoken_no_privilege_escalation() public {
        // sweepToken in this (pre-2021-fix) Compound fork is callable by anyone and sends
        // non-underlying token balances to the admin. Test that the "cToken calls attacker
        // contract" callback cannot be escalated into a seize() (caller must be a listed market).
        MaliciousToken mt = new MaliciousToken(ICToken(FUSDT_USD));
        uint256 victimBefore = ICToken(FUSDT_USD).balanceOf(0x9046fe485De18BB60a72172bC5Ce99Afa06Cf616);
        // anyone can call it; the market calls mt.balanceOf + mt.transfer
        ICToken(FUSDT_USD).sweepToken(address(mt));
        assertTrue(mt.attempted(), "callback reached");
        // the nested seize() came from mt (not a listed market) -> rejected, no tokens moved
        assertTrue(mt.seizeResult() != 0, "seize rejected");
        assertEq(ICToken(FUSDT_USD).balanceOf(0x9046fe485De18BB60a72172bC5Ce99Afa06Cf616), victimBefore, "no seize");
        // and the same on a classic market (seize globally paused there anyway -> revert)
        MaliciousToken mt2 = new MaliciousToken(ICToken(FUSDT_C));
        vm.expectRevert(bytes("seize is paused"));
        ICToken(FUSDT_C).sweepToken(address(mt2));
    }

    // ------------------------------------------------------------------
    // 5. admin paths are privileged
    // ------------------------------------------------------------------
    function test_N_admin_paths_privileged() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("only pause guardian and admin can pause"));
        compC._setSeizePaused(false);
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("only pause guardian and admin can pause"));
        compC._setMintPaused(FUSDT_C, false);
    }
}
