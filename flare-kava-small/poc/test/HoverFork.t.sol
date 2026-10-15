// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Hover (Kava EVM, chain id 2222) — fork-verification suite for the L2-06 deep-dive.
//
// Read-only adversarial test suite. It runs against LIVE Kava state on a fork (no transactions
// are sent to the real chain; everything happens inside the Foundry fork VM).
//
// Goal: prove/disprove that an external, unprivileged attacker can extract value from Hover today.
//
// Verdict encoded by the tests: $0 extractable (gates: mint+borrow globally paused, liquidation
// restricted to a 2-address allowlist, oracle (Pyth) stale -> all liquidity checks revert).
//
// Run:  forge test --match-path test/HoverFork.t.sol -vv
// Fork: vm.createSelectFork(vm.envOr("KAVA_RPC_URL", string("https://evm.kava.io")))

import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function symbol() external view returns (string memory);
}

interface ICToken {
    function totalSupply() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function getCash() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function mint(uint256) external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
    function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function getAccountSnapshot(address) external view returns (uint256, uint256, uint256, uint256);
    function admin() external view returns (address);
}

// hKAVA is a native (KAVA) market: payable mint/repay, liquidateBorrow takes KAVA.
interface ICNativeToken {
    function totalSupply() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function getCash() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function redeem(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable returns (uint256);
    function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IComptroller {
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function oracle() external view returns (address);
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint256);
    function pauseGuardian() external view returns (address);
    function mintGuardianPaused(address) external view returns (bool);
    function borrowGuardianPaused(address) external view returns (bool);
    function transferGuardianPaused() external view returns (bool);
    function seizeGuardianPaused() external view returns (bool);
    function liquidatorsWhitelistVerifier() external view returns (address);
    function liquidateBorrowAllowed(address cTokenBorrowed, address cTokenCollateral, address liquidator, address borrower, uint256 repayAmount) external returns (uint256);
    function seizeAllowed(address cTokenCollateral, address cTokenBorrowed, address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);
    function accountAssets(address, uint256) external view returns (address);
    function getAssetsIn(address) external view returns (address[] memory);
    function claimReward(uint8 rewardType, address payable holder) external;
    function rewardAccrued(uint8, address) external view returns (uint256);
    function protocolTokenAddress() external view returns (address);
    function rewardNativeToken() external view returns (uint8);
}

interface IAllowList {
    function allowed(address) external returns (bool);
    function allowedAddressesLength() external view returns (uint256);
    function allowedAddresses(uint256) external view returns (address);
    function allow(address) external;
    function owner() external view returns (address);
}

interface IOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
    function owner() external view returns (address);
}

interface IPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint publishTime;
    }
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (Price memory);
    function getPriceUnsafe(bytes32 id) external view returns (Price memory);
    function singleUpdateFeeInWei() external view returns (uint256);
    function getValidTimePeriod() external view returns (uint256);
}

interface ILiquidatorBot {
    // bot2 exposes a public entry with selector 0x1f147b2d observed on-chain:
    //   liquidateBorrow(borrower, cTokenBorrowed, cTokenCollateral, repayAmount)
    // (called by a third-party keeper EOA 0x960ee067…; profit goes to profitWallet())
    function profitWallet() external view returns (address);
    function owner() external view returns (address);
    function withdraw(address token) external;
}

interface IWhitelistedLiquidator {
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
}

contract ForceFeed {
    constructor() payable {}

    function boom(address payable target) external {
        selfdestruct(target);
    }
}

contract HoverFork is Test {
    // ---- addresses (Kava EVM mainnet, chain id 2222) ----
    address constant COMPTROLLER = 0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC;
    address constant COMPTROLLER_IMPL = 0xb618fb7C9921fB35A75FDdf5Ee1bBdf19080020C;
    address constant ORACLE = 0xE8Ae943de7f036Cfa505127641Eee7c5b6606878;
    address constant PYTH = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    address constant ADMIN_SAFE = 0xcecC934494adED6c0c82C52656a845862176ceeE;
    address constant ALLOWLIST = 0x49AE3cc17eD67c9Bc9cd11E4d799c329bC90203F;
    address constant BOT1 = 0x9b9FB7e3291C43F3146A9F590a421aC3C0377709; // whitelisted liquidator bot #1
    address constant BOT2 = 0x608cB0F61c1e574025D3e8168078d13e2320781D; // whitelisted liquidator bot #2 (used historically)
    address constant BOT_OWNER_AND_PROFIT_WALLET = 0xbA6f82F77fCf03d33150fceC7384644AC12F4DD5;
    address constant hKAVA = 0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636; // CNative market (KAVA)
    address constant hATOM = 0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd; // CErc20 market (ATOM)
    address constant hUSDT = 0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961; // CErc20 market (USDT)
    address constant uUSDT = 0x919C1c267BC06a7039e03fcc2eF738525769109c;
    address constant uATOM = 0x15932E26f5BD4923d46a2b205191C4b5d5f43FE3;
    address constant HOV = 0xCe82db637A2D750380ef27063518eAa263fbe10E;
    // deeply underwater hUSDT borrower (collateral hKAVA < hUSDT debt), found by full Borrow-log enumeration
    address constant BORROWER_UNDERWATER = 0x5b484cF225cc252918034653d5fF92cf979E6cB2;

    // Pyth price-feed ids used by the oracle's tokenConfigs (verified on-chain)
    bytes32 constant FEED_KAVA = 0xA6e905d4E85AB66046deF2eF0Ce66A7eA2a60871e68ae54aed50ec2fd96d8584;
    bytes32 constant FEED_ATOM = 0xb00B60F88B03A6a625a8D1c048C3f66653edf217439983d037e7222c4e612819;
    bytes32 constant FEED_USDT = 0x2b89B9Dc8FDF9f34709A5b106B472f0F39bb6Ca9ce04b0fd7f2e971688e2e53b;

    IComptroller comptroller = IComptroller(COMPTROLLER);
    IOracle oracle = IOracle(ORACLE);
    IPyth pyth = IPyth(PYTH);
    IAllowList allowlist = IAllowList(ALLOWLIST);
    ICToken cATOM = ICToken(hATOM);
    ICToken cUSDT = ICToken(hUSDT);
    ICNativeToken cKAVA = ICNativeToken(hKAVA);
    ILiquidatorBot bot2 = ILiquidatorBot(BOT2);

    address attacker;

    function setUp() public {
        vm.createSelectFork(vm.envOr("KAVA_RPC_URL", string("https://evm.kava.io")));
        attacker = makeAddr("attacker");
        vm.deal(attacker, 100 ether); // attacker capital for gas/reverts (cheat-funded, sim only)
        console2.log("fork block:", block.number);
    }

    // ------------------------------------------------------------------
    // T1 — live-state invariants (reproduces the campaign headline state)
    // ------------------------------------------------------------------
    function test_T1_state_invariants() public {
        assertEq(comptroller.admin(), ADMIN_SAFE, "comptroller admin should be the 2-of-8 Safe");
        assertEq(comptroller.pendingAdmin(), address(0), "no pending admin transfer");
        assertEq(comptroller.oracle(), ORACLE, "oracle");
        assertEq(comptroller.closeFactorMantissa(), 0.5e18, "closeFactor 50%");
        assertEq(comptroller.liquidationIncentiveMantissa(), 1.05e18, "liquidation incentive 105%");
        assertEq(comptroller.pauseGuardian(), address(0), "no pause guardian");
        assertEq(comptroller.seizeGuardianPaused(), false, "seize not globally paused");
        assertEq(comptroller.transferGuardianPaused(), false, "transfer not globally paused");
        assertEq(ICToken(hKAVA).admin(), ADMIN_SAFE, "hKAVA admin");
        assertEq(ICToken(hUSDT).admin(), ADMIN_SAFE, "hUSDT admin");

        // cash / book values
        console2.log("hKAVA totalSupply   :", cKAVA.totalSupply());
        console2.log("hKAVA cash (wei)    :", cKAVA.getCash());
        console2.log("hKAVA totalBorrows  :", cKAVA.totalBorrows());
        console2.log("hKAVA totalReserves :", cKAVA.totalReserves());
        console2.log("hKAVA exchangeRate  :", cKAVA.exchangeRateStored());
        console2.log("hUSDT cash (units)  :", cUSDT.getCash());
        console2.log("hUSDT totalBorrows  :", cUSDT.totalBorrows());
        console2.log("hUSDT totalSupply   :", cUSDT.totalSupply());
        console2.log("hATOM cash (units)  :", cATOM.getCash());

        // native market: cash must equal the contract's native balance
        assertEq(cKAVA.getCash(), hKAVA.balance, "hKAVA getCash == native balance");
        assertGt(cKAVA.totalSupply(), 0, "hKAVA has supply (not an empty market)");
        assertGt(cUSDT.totalSupply(), 0, "hUSDT has supply (not an empty market)");
        assertGt(cATOM.totalSupply(), 0, "hATOM has supply (not an empty market)");
        // hUSDT is the insolvent market: (near-)zero cash against ~12.1k USDT of borrows
        assertLt(cUSDT.getCash(), 1e6, "hUSDT cash is dust (<= 1 USDT)");
        assertGt(cUSDT.totalBorrows(), 1e10, "hUSDT borrows > 10,000 USDT");
        // exchange rate consistency: value = totalSupply * rate / 1e18 must be ~ cash+borrows-reserves
        uint256 valueHKAVA = cKAVA.totalSupply() * cKAVA.exchangeRateStored() / 1e18;
        assertApproxEqRel(valueHKAVA, cKAVA.getCash() + cKAVA.totalBorrows() - cKAVA.totalReserves(), 0.01e18, "hKAVA accounting");
    }

    // ------------------------------------------------------------------
    // T2 — gates: the two hard walls (pause flags + allowlist) and the oracle wall
    // ------------------------------------------------------------------
    function test_T2a_mint_and_borrow_globally_paused() public {
        // every market has mint+borrow amount-checked by a *reverting* flag in Comptroller
        assertTrue(comptroller.mintGuardianPaused(hKAVA), "hKAVA mint paused");
        assertTrue(comptroller.mintGuardianPaused(hATOM), "hATOM mint paused");
        assertTrue(comptroller.mintGuardianPaused(hUSDT), "hUSDT mint paused");
        assertTrue(comptroller.borrowGuardianPaused(hKAVA), "hKAVA borrow paused");
        assertTrue(comptroller.borrowGuardianPaused(hATOM), "hATOM borrow paused");
        assertTrue(comptroller.borrowGuardianPaused(hUSDT), "hUSDT borrow paused");

        vm.startPrank(attacker);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "MP")); // Comptroller.mintAllowed: require(!mintGuardianPaused[cToken], "MP")
        cUSDT.mint(1e6);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "BP")); // Comptroller.borrowAllowed: require(!borrowGuardianPaused[cToken], "BP")
        cUSDT.borrow(1e6);
        vm.stopPrank();

        // empty-market / donation class is closed: mint is the only way to create cTokens and it is paused
        console2.log("mint/borrow revert reasons verified (MP / BP)");
    }

    function test_T2b_liquidation_allowlist_blocks_outsiders() public {
        assertEq(allowlist.allowedAddressesLength(), 2, "exactly 2 whitelisted liquidators");
        assertEq(allowlist.allowedAddresses(0), BOT1, "allowlist[0]");
        assertEq(allowlist.allowedAddresses(1), BOT2, "allowlist[1]");
        assertEq(allowlist.owner(), ADMIN_SAFE, "allowlist owner = admin Safe");

        assertEq(allowlist.allowed(BOT2), true, "bot2 whitelisted");
        assertEq(allowlist.allowed(attacker), false, "attacker NOT whitelisted");
        assertEq(allowlist.allowed(ADMIN_SAFE), false, "even the admin Safe is not on the allowlist");

        // cannot self-whitelist
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Ownable: caller is not the owner"));
        allowlist.allow(attacker);

        // comptroller agrees: attacker liquidator -> Error.UNAUTHORIZED (1)
        uint256 code = comptroller.liquidateBorrowAllowed(hUSDT, hKAVA, attacker, BORROWER_UNDERWATER, 1e6);
        assertEq(code, 1, "UNAUTHORIZED for external liquidator");
        console2.log("liquidateBorrowAllowed(attacker) =", code, "(1 = UNAUTHORIZED)");

        // direct seize() from an outsider: msg.sender must be a *listed market* (Error 9 = MARKET_NOT_LISTED)
        uint256 sz = cKAVA.seize(attacker, BORROWER_UNDERWATER, 1); // not reverting, returns error code
        assertEq(sz, 3, "seize -> COMPTROLLER_REJECTION");
        uint256 szAllowed = comptroller.seizeAllowed(hKAVA, attacker, attacker, BORROWER_UNDERWATER, 1);
        assertEq(szAllowed, 9, "seizeAllowed: MARKET_NOT_LISTED (caller is not a market)");
    }

    function test_T2c_oracle_is_stale_all_liquidity_checks_revert() public {
        // All three markets propagate Pyth's custom error StalePrice() = 0x19abf40e from
        // getPriceNoOlderThan(feedId, maxStalePeriod) inside the oracle.
        vm.expectRevert(bytes4(0x19abf40e));
        oracle.getUnderlyingPrice(hKAVA);
        vm.expectRevert(bytes4(0x19abf40e));
        oracle.getUnderlyingPrice(hATOM);
        vm.expectRevert(bytes4(0x19abf40e));
        oracle.getUnderlyingPrice(hUSDT);

        // last Pyth publish times (all three feeds published in the same batch)
        IPyth.Price memory p = pyth.getPriceUnsafe(FEED_KAVA);
        console2.log("Pyth KAVA/USD price (1e8 unscaled):", uint256(uint64(p.price)));
        console2.logInt(p.expo);
        console2.log("publishTime:", uint256(p.publishTime));
        assertLt(p.publishTime, block.timestamp, "feed is in the past");
        assertGt(block.timestamp - p.publishTime, 1 days, "feed is > 1 day stale");
        console2.log("staleness (seconds):", block.timestamp - p.publishTime);
        // oracle is a Pyth asset-config oracle; owner is the admin Safe
        assertEq(oracle.owner(), ADMIN_SAFE, "oracle owner");
        assertEq(pyth.singleUpdateFeeInWei(), 0, "Pyth update fee is 0 (refresh is fee-free, gas only)");
    }

    // ------------------------------------------------------------------
    // T3 — extraction attempts, each asserting attacker net profit <= 0
    // ------------------------------------------------------------------
    function test_T3a_attacker_cannot_route_liquidation_through_whitelisted_bot() public {
        // bot2's public entry point (used historically by a third-party keeper EOA) — but the
        // profit wallet is a storage variable owned by the protocol team, not the caller.
        assertEq(bot2.profitWallet(), BOT_OWNER_AND_PROFIT_WALLET, "bot profit wallet");
        assertEq(bot2.owner(), BOT_OWNER_AND_PROFIT_WALLET, "bot owner");

        uint256 kavaBefore = attacker.balance;
        uint256 usdtBefore = IERC20(uUSDT).balanceOf(attacker);

        vm.startPrank(attacker);
        // the whole liquidation reverts today (oracle stale); we accept any revert
        (bool ok, ) = BOT2.call(abi.encodeWithSelector(bytes4(0x1f147b2d), BORROWER_UNDERWATER, hUSDT, hKAVA, uint256(1e6)));
        vm.stopPrank();
        console2.log("bot2.liquidateBorrow from attacker succeeded:", ok);

        assertEq(attacker.balance, kavaBefore, "attacker KAVA unchanged (no profit)");
        assertEq(IERC20(uUSDT).balanceOf(attacker), usdtBefore, "attacker USDT unchanged (no profit)");

        // and even if it had succeeded, the proceeds go to the bot's profitWallet
        assertTrue(BOT_OWNER_AND_PROFIT_WALLET != attacker, "profit wallet != attacker");
    }

    function test_T3b_attacker_without_ctokens_cannot_redeem_value() public {
        uint256 kavaBefore = attacker.balance;
        vm.prank(attacker);
        // redeem without any cToken balance: reverts or returns an error code — either way no KAVA out
        (bool ok, bytes memory ret) = hKAVA.call(abi.encodeWithSelector(ICToken.redeem.selector, uint256(1e10)));
        console2.log("hKAVA.redeem() by empty attacker succeeded:", ok);
        if (ok && ret.length >= 32) {
            console2.log("  return code:", abi.decode(ret, (uint256)));
        }
        assertEq(attacker.balance, kavaBefore, "no KAVA gained");
        assertEq(cKAVA.balanceOf(attacker), 0, "attacker owns no hKAVA cTokens");
        assertEq(cUSDT.balanceOf(attacker), 0, "attacker owns no hUSDT cTokens");
    }

    function test_T3c_attacker_cannot_claim_rewards_it_did_not_earn() public {
        uint256 kavaBefore = attacker.balance;
        uint256 usdtBefore = IERC20(uUSDT).balanceOf(attacker);
        uint256 hovBefore = IERC20(HOV).balanceOf(attacker);
        vm.prank(attacker);
        // claimReward flows to `holders[i]` — an attacker can only claim for itself
        comptroller.claimReward(1, payable(attacker)); // 1 = native (KAVA) reward type
        assertEq(comptroller.rewardAccrued(1, attacker), 0, "nothing accrued to attacker");
        assertEq(attacker.balance, kavaBefore, "no KAVA drained from the reward pot");
        assertEq(IERC20(uUSDT).balanceOf(attacker), usdtBefore, "no USDT");
        assertEq(IERC20(HOV).balanceOf(attacker), hovBefore, "no HOV");
        // the comptroller's reward pot exists but is only claimable by holders with accrued rewards
        console2.log("comptroller native KAVA pot:", COMPTROLLER.balance);
    }

    function test_T3d_donation_and_forcefeed_are_attacker_losses() public {
        // (1) direct send: the native market's payable fallback tries to MINT -> reverts "MP"
        vm.prank(attacker);
        (bool ok, bytes memory ret) = hKAVA.call{value: 1 ether}("");
        assertFalse(ok, "direct KAVA donation to hKAVA reverts (fallback mints, mint is paused)");
        console2.logBytes(ret);

        // (2) forced donation via selfdestruct is possible, but it only raises the exchange rate
        //     for EXISTING holders (attacker owns 0 cTokens) => pure loss for the attacker.
        uint256 rateBefore = cKAVA.exchangeRateStored();
        uint256 attackerBefore = attacker.balance;
        vm.prank(attacker);
        ForceFeed ff = new ForceFeed{value: 2 ether}();
        ff.boom(payable(hKAVA));
        uint256 rateAfter = cKAVA.exchangeRateStored();
        assertGt(rateAfter, rateBefore, "forced donation raises the exchange rate (benefits existing holders)");
        assertEq(attacker.balance, attackerBefore - 2 ether, "attacker net -2 KAVA");
        assertEq(cKAVA.balanceOf(attacker), 0, "attacker got no cTokens from the donation");
        console2.log("rate before/after force-feed:", rateBefore, rateAfter);
    }

    // ------------------------------------------------------------------
    // T4 — tripwire: with the oracle refreshed, liquidations become live AGAIN
    //      (for the 2 whitelisted bots only), and still fail for outsiders.
    // ------------------------------------------------------------------
    function test_T4_tripwire_oracle_refresh_opens_liquidations_for_bot_only() public {
        _mockFreshOracle();

        // oracle now returns prices
        uint256 kavaPrice = oracle.getUnderlyingPrice(hKAVA);
        uint256 usdtPrice = oracle.getUnderlyingPrice(hUSDT);
        uint256 atomPrice = oracle.getUnderlyingPrice(hATOM);
        console2.log("oracle KAVA:", kavaPrice);
        console2.log("oracle USDT:", usdtPrice);
        console2.log("oracle ATOM:", atomPrice);
        assertGt(kavaPrice, 0, "oracle live after refresh");
        assertGt(usdtPrice, 0, "oracle live after refresh");

        // with fresh prices, the whitelisted bot passes the allowlist (0 = NO_ERROR/liquidatable,
        // or 3 = INSUFFICIENT_SHORTFALL if the position has since been closed) — never 1 (UNAUTHORIZED)
        uint256 botCode = comptroller.liquidateBorrowAllowed(hUSDT, hKAVA, BOT2, BORROWER_UNDERWATER, 1e6);
        assertTrue(botCode != 1, "bot2 must pass the allowlist check once the oracle is fresh");
        console2.log("liquidateBorrowAllowed(bot2) =", botCode, "(0 = NO_ERROR, 3 = no shortfall)");

        // ... while an external attacker is still UNAUTHORIZED
        uint256 atkCode = comptroller.liquidateBorrowAllowed(hUSDT, hKAVA, attacker, BORROWER_UNDERWATER, 1e6);
        assertEq(atkCode, 1, "attacker still UNAUTHORIZED");
        console2.log("liquidateBorrowAllowed(attacker) =", atkCode, "(1 = UNAUTHORIZED)");

        // and even the bot's *caller* does not receive the proceeds: the profit wallet is a storage var
        assertEq(bot2.profitWallet(), BOT_OWNER_AND_PROFIT_WALLET, "proceeds to the protocol-team wallet");
    }

    /// Simulates "somebody refreshed the Pyth feeds" — the real refresh path is the
    /// permissionless, zero-fee Pyth.updatePriceFeeds(bytes[]) call.
    /// Prices are mocked at the oracle level (Compound scale: USD * 1e(36-decimals)).
    function _mockFreshOracle() internal {
        vm.mockCall(ORACLE, abi.encodeWithSelector(IOracle.getUnderlyingPrice.selector, hKAVA), abi.encode(uint256(68508639233163750)));                 // KAVA $0.06851 · 18 dec
        vm.mockCall(ORACLE, abi.encodeWithSelector(IOracle.getUnderlyingPrice.selector, hATOM), abi.encode(uint256(1686436195010359500) * 1e12));        // ATOM $1.68644 · 6 dec
        vm.mockCall(ORACLE, abi.encodeWithSelector(IOracle.getUnderlyingPrice.selector, hUSDT), abi.encode(uint256(999102731755602500) * 1e12));        // USDT $0.99910 · 6 dec
    }
}
