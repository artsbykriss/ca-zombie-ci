// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// @title L2-14 · SBCWrapper (mGNO) on Gnosis Chain — live-extractability boundary tests
/// @notice Read-only fork verification. No mainnet transactions. All actions run on a foundry fork.
///
/// Target: SBCWrapperProxy 0x647507A70Ff598F386CB96ae5046486389368C66 (impl 0x0b91d1e3…)
///   - wraps GNO -> mGNO at tokenRate[GNO] = 32e18  (1 GNO => 32 mGNO)
///   - unwrap(GNO, amount) burns mGNO and pays floor(amount / 32) GNO to the caller (no pause gate)
///   - admin = Gnosis Safe 8-of-15 (0x7a48Dac6…) — privileged
///
/// What this suite proves:
///   T1  live state + exact solvency (wrapper GNO balance == mGNO supply/32 + 1 GNO)
///   T2  the wrapper round-trip (swap then unwrap) is value-neutral to the wei (no mint/rounding gain)
///   T3  the ONLY profitable fresh-attacker path: buy mispriced mGNO from the drained ELK pool
///       (ELK is itself liquid on Gnosis) and unwrap it -> net ≈ +$0.34 (dust), pool-capped
///   T4  hard bound on that path: value of all purchasable mGNO across every known pool
///   T5  negative paths: ERC677 self-swap free-mint, mGNO.mint/burn, unwrap to disabled tokens,
///       enableToken/pauseToken/claimTokens/pause/upgradeTo/setAdmin, system-withdrawal spoof
///   T6  full redemption by the 98.88% holder keeps the wrapper solvent (H-O path, fair)
///   T7  legacy mGNO deposit contract 0x6DA1365c… (32 mGNO) is permanently stuck (admin slot = 0)
///   T8  design note: global pause does not stop unwrap (redemption stays live during incidents)
///   T9  operational note: the ERC677 deposit path is broken post GNO migration (atomic revert)
contract SBCWrapperTest is Test {
    // ---- Gnosis chain constants (verified on-chain; see analysis/pin_state.json @ block 48766267) ----
    address constant WRAPPER = 0x647507A70Ff598F386CB96ae5046486389368C66;
    address constant MGNO = 0x722fc4DAABFEaff81b97894fC623f91814a1BF68;
    address constant GNO = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address constant STAKE = 0xb7D311E2Eb55F2f68a9440da38e7989210b9A05e;
    address constant DEPOSIT = 0x0B98057eA310F4d31F2a452B414647007d1645d9;
    address constant WXDAI = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address constant ELK = 0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE;
    address constant PAIR_WXDAI_ELK = 0xFB14c8888Ae9E78265a9A61a5b63C93f9545DDf6;
    address constant PAIR_MGNO_ELK = 0x71DE7EA9Cf04eec0530373494544FA57d4dc7a0e;
    address constant PAIR_MGNO_SUSHI = 0xA7B76d37bEEEffc0185DcF4629568194AA151c95;
    address constant OLD_DEPOSIT = 0x6DA1365c3baAD9b6cCB76C2560523dBBBCc94Cde;
    address constant TOP_HOLDER = 0x6b504204a85E0231b1a1B1926B9264939F29c65e;
    address constant ADMIN_SAFE = 0x7a48Dac683DA91e4faa5aB13D91AB5fd170875bd;

    uint256 constant RATE = 32e18; // tokenRate[GNO]
    // DefiLlama GNO/USD at measurement time (2026-10-15): $113.55707835718617
    uint256 constant GNO_USD_1E6 = 113_557_078;

    // ERC20 balance storage slots on Gnosis (verified by hand, see analysis/)
    uint256 constant GNO_BAL_SLOT = 3; // PermittableToken proxy layout
    uint256 constant MGNO_BAL_SLOT = 0; // SBCToken proxy layout

    function _rpc() internal view returns (string memory) {
        string memory rpc = vm.envOr("GNOSIS_RPC_URL", string(""));
        if (bytes(rpc).length == 0) return "https://gnosis-rpc.publicnode.com";
        return rpc;
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
        emit log_named_uint("fork block", block.number);
    }

    // ---------------------------------------------------------------- helpers
    function _giveToken(address token, uint256 slot, address to, uint256 amt) internal {
        bytes32 s = keccak256(abi.encode(to, slot));
        vm.store(token, s, bytes32(amt));
    }

    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256)
    {
        // Uniswap-V2 / ElkPair 0.3% fee
        return (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1;
    }

    // ---------------------------------------------------------------- T1
    function test_T1_live_state_and_exact_solvency() public {
        assertFalse(IWrapper(WRAPPER).paused(), "wrapper paused");
        assertEq(IWrapper(WRAPPER).sbcToken(), MGNO, "sbcToken != mGNO");
        assertEq(IWrapper(WRAPPER).sbcDepositContract(), DEPOSIT, "deposit contract mismatch");
        assertEq(IWrapper(WRAPPER).tokenStatus(GNO), 1, "GNO not ENABLED");
        assertEq(IWrapper(WRAPPER).tokenRate(GNO), RATE, "rate != 32e18");
        assertEq(IWrapper(WRAPPER).tokenStatus(STAKE), 0, "STAKE enabled?");
        assertEq(IWrapper(WRAPPER).tokenStatus(MGNO), 0, "mGNO enabled?");
        assertEq(IWrapper(WRAPPER).admin(), ADMIN_SAFE, "admin != Safe");

        uint256 supply = IERC20(MGNO).totalSupply();
        uint256 bal = IERC20(GNO).balanceOf(WRAPPER);
        // exact solvency: balance == floor(supply/32) + 1 GNO
        assertGe(bal, supply / 32, "INSOLVENT");
        assertEq(bal, supply / 32 + 1e18, "not the expected exact +1 GNO buffer");

        emit log_named_uint("mGNO totalSupply (wei)", supply);
        emit log_named_uint("wrapper GNO balance (wei)", bal);
        emit log_named_uint("wrapper GNO in USD (1e6)", (bal / 1e18) * GNO_USD_1E6);
    }

    // ---------------------------------------------------------------- T2
    function test_T2_roundtrip_is_value_neutral_to_the_wei() public {
        address attacker = makeAddr("rt_attacker");
        _giveToken(GNO, GNO_BAL_SLOT, attacker, 10e18);

        vm.startPrank(attacker);
        IERC20(GNO).approve(WRAPPER, type(uint256).max);
        IWrapper(WRAPPER).swap(GNO, 1e18, "");
        uint256 mgno = IERC20(MGNO).balanceOf(attacker);
        assertEq(mgno, 32e18, "swap mint != 32 mGNO per GNO");
        uint256 got = IWrapper(WRAPPER).unwrap(GNO, mgno);
        vm.stopPrank();

        assertEq(got, 1e18, "roundtrip returned != input");
        assertEq(IERC20(GNO).balanceOf(attacker), 10e18, "roundtrip changed balance");
        emit log_string("roundtrip 1 GNO -> 32 mGNO -> 1 GNO: exact, no rounding gain");
    }

    // ---------------------------------------------------------------- T3
    function test_T3_elk_pool_arb_is_live_and_profitable() public {
        address attacker = makeAddr("arb_attacker");
        vm.deal(attacker, 1 ether); // attacker's own capital (gas + dust)

        (uint112 rWX, uint112 rELK1,) = IPair(PAIR_WXDAI_ELK).getReserves();
        (uint112 rMGNO, uint112 rELK2,) = IPair(PAIR_MGNO_ELK).getReserves();
        assertGt(rMGNO, 0, "mGNO pool empty");
        assertEq(IPair(PAIR_MGNO_ELK).token0(), MGNO, "pair2 token0");
        assertEq(IPair(PAIR_MGNO_ELK).token1(), ELK, "pair2 token1");
        assertEq(IPair(PAIR_WXDAI_ELK).token0(), WXDAI, "pair1 token0");
        assertEq(IPair(PAIR_WXDAI_ELK).token1(), ELK, "pair1 token1");

        // buy 99.9% of the pool's mGNO
        uint256 outMGNO = (uint256(rMGNO) * 999) / 1000;
        uint256 inELK = _getAmountIn(outMGNO, rELK2, rMGNO);
        uint256 inWXDAI = _getAmountIn(inELK, rWX, rELK1) * 102 / 100 + 1; // small buffer

        vm.startPrank(attacker);
        IWXDAI(WXDAI).deposit{value: inWXDAI}();
        IERC20(WXDAI).transfer(PAIR_WXDAI_ELK, inWXDAI);
        IPair(PAIR_WXDAI_ELK).swap(0, inELK, attacker, ""); // WXDAI in -> ELK out
        uint256 elkBal = IERC20(ELK).balanceOf(attacker);
        assertGe(elkBal, inELK, "did not receive ELK");
        IERC20(ELK).transfer(PAIR_MGNO_ELK, inELK);
        IPair(PAIR_MGNO_ELK).swap(outMGNO, 0, attacker, ""); // ELK in -> mGNO out
        uint256 mgnoGot = IERC20(MGNO).balanceOf(attacker);
        assertEq(mgnoGot, outMGNO, "mGNO out mismatch");
        uint256 gnoOut = IWrapper(WRAPPER).unwrap(GNO, mgnoGot);
        vm.stopPrank();

        uint256 usd1e6 = (gnoOut * GNO_USD_1E6) / 1e18;
        emit log_named_uint("mGNO bought from ELK pool (wei)", mgnoGot);
        emit log_named_uint("GNO received on unwrap (wei)", gnoOut);
        emit log_named_uint("gross value in USD (1e6)", usd1e6);
        emit log_named_uint("WXDAI spent for ELK (wei)", inWXDAI);
        emit log_named_uint("ELK spent for mGNO (wei)", inELK);

        assertGt(gnoOut, 0.0029e18, "profit too small / path broken");
        assertGt(usd1e6, 330_000, "expected >= $0.33 gross");
    }

    // ---------------------------------------------------------------- T4
    function test_T4_total_extractable_bound_across_all_pools() public {
        (uint112 rMGNO_ELK,,) = IPair(PAIR_MGNO_ELK).getReserves();
        (, uint112 rMGNO_SUSHI,) = IPair(PAIR_MGNO_SUSHI).getReserves();
        // The other holder-contracts (Safes, EIP-7702 EOAs, StakeWise pools, stuck legacy deposit)
        // cannot be bought from — they are not markets.
        uint256 totalMgno = uint256(rMGNO_ELK) + uint256(rMGNO_SUSHI);
        uint256 totalGno = totalMgno / 32;
        uint256 usd1e6 = (totalGno * GNO_USD_1E6) / 1e18;
        emit log_named_uint("purchasable mGNO ELK pool (wei)", rMGNO_ELK);
        emit log_named_uint("purchasable mGNO SUSHI pool (wei)", rMGNO_SUSHI);
        emit log_named_uint("redeemable GNO (wei)", totalGno);
        emit log_named_uint("total E-U bound USD (1e6)", usd1e6);
        assertLt(usd1e6, 350_000, "E-U bound unexpectedly large");
        assertGt(rMGNO_SUSHI, 0, "sushi pool dust missing");
    }

    // ---------------------------------------------------------------- T5
    function test_T5_negative_paths_all_revert() public {
        address attacker = makeAddr("neg_attacker");
        _giveToken(MGNO, MGNO_BAL_SLOT, attacker, 32e18); // enough mGNO for ERC677 attempts

        vm.startPrank(attacker);
        // ERC677 self-swap free mint (mGNO is not an enabled swap token)
        vm.expectRevert(bytes("SBCWrapper: token is not enabled"));
        IMGNO(MGNO).transferAndCall(WRAPPER, 1e18, "");
        // mint / burn require minter
        vm.expectRevert(bytes("SBCToken: not a minter"));
        IMGNO(MGNO).mint(attacker, 1e18);
        vm.expectRevert(bytes("SBCToken: not a minter"));
        IMGNO(MGNO).burn(attacker, 1e18);
        // unwrap to disabled tokens
        vm.expectRevert(bytes("SBCWrapper: token is not enabled"));
        IWrapper(WRAPPER).unwrap(STAKE, 32e18);
        vm.expectRevert(bytes("SBCWrapper: token is not enabled"));
        IWrapper(WRAPPER).unwrap(MGNO, 32e18);
        // admin surfaces
        vm.expectRevert();
        IWrapper(WRAPPER).enableToken(attacker, 1e18);
        vm.expectRevert();
        IWrapper(WRAPPER).pauseToken(GNO);
        vm.expectRevert();
        IWrapper(WRAPPER).claimTokens(GNO, attacker);
        vm.expectRevert();
        IWrapper(WRAPPER).pause();
        vm.expectRevert();
        IWrapper(WRAPPER).upgradeTo(attacker);
        vm.expectRevert();
        IWrapper(WRAPPER).setAdmin(attacker);
        // system withdrawal spoof on the live deposit contract
        uint64[] memory amounts = new uint64[](0);
        address[] memory addrs = new address[](0);
        vm.expectRevert(bytes("This function should be called only by SYSTEM_WITHDRAWAL_EXECUTOR or _admin()"));
        IDeposit(DEPOSIT).executeSystemWithdrawals(amounts, addrs);
        vm.stopPrank();
        emit log_string("all negative paths revert as expected");
    }

    // ---------------------------------------------------------------- T6
    function test_T6_top_holder_full_redemption_keeps_solvency() public {
        uint256 bal = IERC20(MGNO).balanceOf(TOP_HOLDER);
        uint256 supply = IERC20(MGNO).totalSupply();
        uint256 before = IERC20(GNO).balanceOf(WRAPPER);

        vm.prank(TOP_HOLDER);
        uint256 got = IWrapper(WRAPPER).unwrap(GNO, bal);

        uint256 afterBal = IERC20(GNO).balanceOf(WRAPPER);
        uint256 remainingSupply = supply - bal;
        assertEq(got, bal / 32, "redemption amount");
        assertEq(before - afterBal, bal / 32, "wrapper paid != amount");
        assertGe(afterBal, remainingSupply / 32, "wrapper insolvent for the rest");
        emit log_named_uint("top holder redeemed GNO (wei)", got);
        emit log_named_uint("wrapper GNO left (wei)", afterBal);
        emit log_named_uint("remaining mGNO supply (wei)", remainingSupply);
    }

    // ---------------------------------------------------------------- T7
    function test_T7_legacy_mgno_deposit_contract_is_stuck() public {
        bytes32 adminSlot =
            vm.load(OLD_DEPOSIT, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);
        assertEq(uint256(adminSlot), 0, "legacy deposit admin != 0");
        assertEq(IERC20(MGNO).balanceOf(OLD_DEPOSIT), 32e18, "legacy deposit mGNO != 32");
        address attacker = makeAddr("stuck_attacker");
        vm.prank(attacker);
        vm.expectRevert();
        IDeposit(OLD_DEPOSIT).claimTokens(MGNO, attacker);
        emit log_string("legacy mGNO deposit contract: admin=0x0 -> 32 mGNO permanently stuck (S)");
    }

    // ---------------------------------------------------------------- T8
    function test_T8_global_pause_does_not_block_unwrap() public {
        address attacker = makeAddr("pause_attacker");
        _giveToken(GNO, GNO_BAL_SLOT, attacker, 1e18);

        vm.startPrank(attacker);
        IERC20(GNO).approve(WRAPPER, type(uint256).max);
        IWrapper(WRAPPER).swap(GNO, 1e18, "");
        vm.stopPrank();

        vm.prank(ADMIN_SAFE); // simulate the admin (test-only impersonation)
        IWrapper(WRAPPER).pause();
        assertTrue(IWrapper(WRAPPER).paused());

        vm.prank(attacker);
        uint256 got = IWrapper(WRAPPER).unwrap(GNO, 32e18);
        assertEq(got, 1e18, "unwrap blocked by pause");
        emit log_string("unwrap() has no whenNotPaused: redemptions remain live while paused");
    }

    // ---------------------------------------------------------------- T9
    function test_T9_erc677_deposit_path_is_broken_atomically() public {
        address attacker = makeAddr("dep_attacker");
        _giveToken(GNO, GNO_BAL_SLOT, attacker, 1e18);

        // valid-shaped deposit data: 32 bytes withdrawal credentials + one 176-byte validator slot
        bytes memory data = abi.encodePacked(bytes32(uint256(0x1234)), new bytes(176));

        // (a) exact gate: wrapper forwards to the deposit contract, which now expects GNO as
        //     stake_token but sees mGNO as msg.sender (GNO pranked to isolate the inner call)
        vm.prank(GNO);
        vm.expectRevert(bytes("DepositContract: not a deposit token"));
        IWrapper(WRAPPER).onTokenTransfer(attacker, 1e18, data);

        // (b) realistic user path via GNO.transferAndCall: GNO's token re-reverts without
        //     bubbling the inner reason, but the whole call still reverts atomically
        vm.startPrank(attacker);
        IERC20(GNO).approve(WRAPPER, type(uint256).max);
        vm.expectRevert();
        IERC20(GNO).transferAndCall(WRAPPER, 1e18, data);
        vm.stopPrank();
        assertEq(IERC20(GNO).balanceOf(attacker), 1e18, "funds lost in broken deposit path");
        emit log_string("deposit path broken post-migration: atomic revert, no fund loss");
    }
}

// ---------------------------------------------------------------- interfaces
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function transferAndCall(address, uint256, bytes calldata) external;
}

interface IWXDAI {
    function deposit() external payable;
}

interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256, uint256, address, bytes calldata) external;
}

interface IWrapper {
    function paused() external view returns (bool);
    function admin() external view returns (address);
    function sbcToken() external view returns (address);
    function sbcDepositContract() external view returns (address);
    function tokenStatus(address) external view returns (uint8);
    function tokenRate(address) external view returns (uint256);
    function swap(address, uint256, bytes calldata) external;
    function unwrap(address, uint256) external returns (uint256);
    function onTokenTransfer(address, uint256, bytes calldata) external returns (bool);
    function enableToken(address, uint256) external;
    function pauseToken(address) external;
    function claimTokens(address, address) external;
    function pause() external;
    function upgradeTo(address) external;
    function setAdmin(address) external;
}

interface IMGNO is IERC20 {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

interface IDeposit {
    function stake_token() external view returns (address);
    function executeSystemWithdrawals(uint64[] calldata, address[] calldata) external;
    function claimTokens(address, address) external;
}
