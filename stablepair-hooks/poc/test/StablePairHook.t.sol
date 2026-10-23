// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {IPoolManagerMin, IDynamicFeeHookMin, PoolKey, SwapParams, Currency, IERC20Min} from "../src/V4Minimal.sol";
import {SwapHarness} from "../src/SwapHarness.sol";
import {StableFeeCalculation} from "../src/deps/StableFeeCalculation.sol";

/// @title StablePairHook / VolatilePairHook (Uniswap v4, UUPS) — unprivileged-attacker fork PoC
/// @notice Read-only fork reproduction. No mainnet transactions are signed or sent; every call runs
///         against a local anvil fork of Ethereum mainnet.
contract StablePairHookTest is Test {
    // --- live mainnet addresses (Ethereum) ---
    address constant PM = 0x000000000004444c5dc75cB358380D2e3dE08A90; // v4 PoolManager
    address constant STABLE = 0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0; // StablePairHook proxy
    address constant VOLATILE = 0x000022Ec4eBD6b12294396E852E4C3876b253Cc0; // VolatilePairHook proxy
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDG = 0xe343167631d89B6Ffc58B88d6b7fB0228795491D;
    address constant ZERO = address(0);

    // Uniswap governance timelock that holds DEFAULT_ADMIN_ROLE / CONFIG_MANAGER_ROLE on mainnet
    address constant ADMIN = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;

    uint160 constant MIN_SQRT = 4295128740; // TickMath.MIN_SQRT_PRICE + 1
    uint160 constant MAX_SQRT = 1461446703485210103287273052203988822378723970341; // MAX_SQRT_PRICE - 1
    uint24 constant DYNAMIC_FEE = 0x800000;

    bytes32 constant SWAP_TOPIC =
        keccak256("Swap(bytes32,address,int128,int128,uint160,uint128,int24,uint24)");

    SwapHarness harness;

    PoolKey keyUsdcUsdt; // StablePair, USDC/USDT
    PoolKey keyUsdcUsdg; // StablePair, USDC/USDG
    PoolKey keyEthUsdc; // VolatilePair, ETH/USDC

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpc);

        harness = new SwapHarness(IPoolManagerMin(PM));

        keyUsdcUsdt = PoolKey(Currency.wrap(USDC), Currency.wrap(USDT), DYNAMIC_FEE, 1, STABLE);
        keyUsdcUsdg = PoolKey(Currency.wrap(USDC), Currency.wrap(USDG), DYNAMIC_FEE, 1, STABLE);
        keyEthUsdc = PoolKey(Currency.wrap(ZERO), Currency.wrap(USDC), DYNAMIC_FEE, 4, VOLATILE);

        deal(USDC, address(harness), 2_000_000e6);
        deal(USDT, address(harness), 2_000_000e6);
    }

    // ---------------------------------------------------------------- helpers

    function _poolId(PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k));
    }

    function _bal(address token) internal view returns (uint256) {
        return IERC20Min(token).balanceOf(address(harness));
    }

    /// @notice Executes one exact-in swap through the harness and returns (delta, feeE6 applied).
    function _swapAndFee(PoolKey memory k, bool zeroForOne, uint256 amountIn)
        internal
        returns (int256 delta, uint256 feeE6)
    {
        vm.recordLogs();
        delta = harness.doSwap(
            k, SwapParams({zeroForOne: zeroForOne, amountSpecified: -int256(amountIn), sqrtPriceLimitX96: zeroForOne ? MIN_SQRT : MAX_SQRT})
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 pid = _poolId(k);
        bool found;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics.length > 1 && logs[i].topics[0] == SWAP_TOPIC && logs[i].topics[1] == pid) {
                // Swap data words: amount0, amount1, sqrtPriceX96, liquidity, tick, fee
                feeE6 = _lastFeeWord(logs[i].data);
                found = true;
                break;
            }
        }
        require(found, "no Swap event captured");
    }

    /// @dev Extracts the trailing uint24 `fee` field from a PoolManager Swap event data blob.
    function _lastFeeWord(bytes memory d) internal pure returns (uint256 fee) {
        assembly {
            fee := and(mload(add(add(d, 0x20), sub(mload(d), 32))), 0xffffff)
        }
    }

    function _getFee(PoolKey memory k) internal view returns (uint24 a, uint24 b) {
        return IDynamicFeeHookMin(k.hooks).getFee(k);
    }

    // ------------------------------------------------------------ 1. auth/config

    function test_1_flags_and_delta_bits_off() public {
        (
            bool bI,
            bool aI,
            bool bAL,
            bool aAL,
            bool bRL,
            bool aRL,
            bool bS,
            bool aS,
            bool bD,
            bool aD,
            bool bSD,
            bool aSD,
            bool aALD,
            bool aRLD
        ) = IDynamicFeeHookMin(STABLE).getHookPermissions();

        assertTrue(bI && aI && bAL && aAL && bS && aS, "6 flags set");
        assertFalse(bRL || aRL || bD || aD, "remove/donate off");
        // return-delta bits are OFF -> hook cannot alter swap amounts
        assertFalse(bSD, "beforeSwapReturnDelta OFF");
        assertFalse(aSD, "afterSwapReturnDelta OFF");
        assertFalse(aALD, "afterAddLiquidityReturnDelta OFF");
        assertFalse(aRLD, "afterRemoveLiquidityReturnDelta OFF");
    }

    function test_2_roles_and_pool_manager() public {
        assertEq(IDynamicFeeHookMin(STABLE).poolManager(), PM, "pool manager");
        assertEq(IDynamicFeeHookMin(VOLATILE).poolManager(), PM, "pool manager volatile");

        bytes32 adminRole = IDynamicFeeHookMin(STABLE).DEFAULT_ADMIN_ROLE();
        bytes32 poolInitRole = IDynamicFeeHookMin(STABLE).POOL_INITIALIZER_ROLE();
        bytes32 cfgRole = IDynamicFeeHookMin(STABLE).CONFIG_MANAGER_ROLE();

        // governance timelock holds admin + config; a separate EOA holds pool-initializer
        assertTrue(IDynamicFeeHookMin(STABLE).hasRole(adminRole, ADMIN), "admin is timelock");
        assertTrue(IDynamicFeeHookMin(STABLE).hasRole(cfgRole, ADMIN), "config is timelock");
        // the attacker (this test contract) holds nothing
        assertFalse(IDynamicFeeHookMin(STABLE).hasRole(adminRole, address(this)), "attacker has no admin");
        assertFalse(IDynamicFeeHookMin(STABLE).hasRole(poolInitRole, address(this)), "attacker has no pool-init");
        assertFalse(IDynamicFeeHookMin(STABLE).hasRole(cfgRole, address(this)), "attacker has no config");
    }

    function test_3_attacker_cannot_initialize_pool() public {
        // fresh, uninitialized pool id (different tickSpacing) so we reach the hook's guard
        PoolKey memory k = PoolKey(Currency.wrap(USDC), Currency.wrap(USDT), DYNAMIC_FEE, 10, STABLE);
        vm.prank(address(0xBAD));
        vm.expectRevert(); // AccessControlUnauthorizedAccount
        IDynamicFeeHookMin(STABLE).initializePool(k, uint160(1 << 96), "");
    }

    function test_4_direct_pool_manager_initialize_reverts() public {
        PoolKey memory k = PoolKey(Currency.wrap(USDC), Currency.wrap(USDT), DYNAMIC_FEE, 10, STABLE);
        // the hook's _beforeInitialize unconditionally reverts -> direct PoolManager.initialize is blocked
        vm.prank(address(0xBAD));
        vm.expectRevert();
        IPoolManagerMin(PM).initialize(k, uint160(1 << 96));
    }

    function test_5_attacker_cannot_update_fee_config() public {
        vm.prank(address(0xBAD));
        vm.expectRevert(); // AccessControlUnauthorizedAccount
        IDynamicFeeHookMin(STABLE).updateFeeConfig(_poolId(keyUsdcUsdt), "");
    }

    // ------------------------------------------------------------ 2. live fees

    function test_6_live_getFee_values() public {
        (uint24 a0, uint24 a1) = _getFee(keyUsdcUsdt);
        (uint24 b0, uint24 b1) = _getFee(keyUsdcUsdg);
        (uint24 c0, uint24 c1) = _getFee(keyEthUsdc);

        console2.log("USDC/USDT  feeE6 zeroForOne/oneForZero:", a0, a1);
        console2.log("USDC/USDG  feeE6 zeroForOne/oneForZero:", b0, b1);
        console2.log("ETH/USDC   feeE6 zeroForOne/oneForZero:", c0, c1);

        // fees are always <= 100% (clamped in the library) and never negative (uint24)
        assertLe(a0, 1e6);
        assertLe(a1, 1e6);
        assertLe(b0, 1e6);
        assertLe(b1, 1e6);
        assertLe(c0, 1e6);
        assertLe(c1, 1e6);
    }

    // ------------------------------------------------- 3. 0-fee swap + round trip

    /// @notice A fresh, unprivileged account can execute the pool's 0-fee direction through
    ///         PoolManager.unlock -> swap, and the applied fee is exactly 0.
    function test_7_zero_fee_swap_executes() public {
        // pick a live StablePair pool that currently has a 0-fee direction
        PoolKey memory chosen;
        bool zeroForOne;
        bool found;
        (uint24 a0, uint24 a1) = _getFee(keyUsdcUsdt);
        if (a0 == 0) {
            chosen = keyUsdcUsdt;
            zeroForOne = true;
            found = true;
        } else if (a1 == 0) {
            chosen = keyUsdcUsdt;
            zeroForOne = false;
            found = true;
        } else {
            (uint24 b0, uint24 b1) = _getFee(keyUsdcUsdg);
            if (b0 == 0) {
                chosen = keyUsdcUsdg;
                zeroForOne = true;
                found = true;
            } else if (b1 == 0) {
                chosen = keyUsdcUsdg;
                zeroForOne = false;
                found = true;
            }
        }
        require(found, "no live 0-fee direction found on the stable pools");

        (, uint256 feeE6) = _swapAndFee(chosen, zeroForOne, 10_000e6);
        assertEq(feeE6, 0, "applied fee must be 0");
        console2.log("0-fee swap applied feeE6:", feeE6);
        console2.log("zeroForOne:", zeroForOne);
    }

    /// @notice A self round-trip on the live pool is net-negative for the attacker: they pay the
    ///         fee on the charged leg plus two-way price impact.
    function test_8_round_trip_is_negative() public {
        uint256 startUsdc = _bal(USDC);
        uint256 startUsdt = _bal(USDT);

        _swapAndFee(keyUsdcUsdt, true, 50_000e6); // sell 50k USDC -> USDT
        uint256 gainedUsdt = _bal(USDT) - startUsdt; // only the USDT produced by leg 1
        _swapAndFee(keyUsdcUsdt, false, gainedUsdt); // buy USDC back with exactly that USDT

        uint256 endUsdc = _bal(USDC);
        uint256 endUsdt = _bal(USDT);

        int256 dUsdc = int256(endUsdc) - int256(startUsdc);
        int256 dUsdt = int256(endUsdt) - int256(startUsdt);
        console2.log("round-trip delta USDC (6dp):", dUsdc);
        console2.log("round-trip delta USDT (6dp):", dUsdt);

        // the attacker ends with strictly fewer USDC than they started with
        assertLt(endUsdc, startUsdc, "attacker lost USDC on the round trip");
    }

    // ------------------------------------------------- 4. fee bounds (no negative)

    function test_9_fee_math_never_negative_or_over_100pct() public {
        // 0 fee stays 0
        assertEq(StableFeeCalculation.toFeeE6(0), 0);
        // sub-pip rounds up to 1 pip, never down to 0
        assertEq(StableFeeCalculation.toFeeE6(1), 1);
        // a full-scale (100%) fee clamps to MAX_FEE_E6 = 999998
        assertEq(StableFeeCalculation.toFeeE6(1e12), 999998);
        // absurdly large input still clamps
        assertEq(StableFeeCalculation.toFeeE6(type(uint256).max), 999998);

        // far-boundary fee at extreme deviation -> ~100% but clamped
        uint256 far = StableFeeCalculation.calculateFarBoundaryFee(1, 7); // priceRatio ~ 0
        assertLe(StableFeeCalculation.toFeeE6(far), 999998);
        // inside-range fee is well-defined and < 100%
        uint256 inside = StableFeeCalculation.calculateInsideOptimalRangeFee(
            (uint256(1) << 96) - 1, 7, true, true
        );
        assertLt(inside, 1e12);
    }

    // ------------------------------------------------- 5. stale-cache mechanism

    /// @notice Directly reproduces the source-documented primitive: with the per-block price cache
    ///         on the opposite side of the reference, a same-block corrective swap is charged 0;
    ///         after the block advances (self-heal) the same swap pays a non-zero fee.
    function test_10_stale_cache_zero_fee_and_self_heal() public {
        // current pool price and reference
        (uint160 sqrtNow,,,) = _slot0(keyUsdcUsdt);
        (,,, uint160 refSqrt) = _feeConfig(keyUsdcUsdt);
        console2.log("slot0 sqrtPriceX96:", uint256(sqrtNow));
        console2.log("reference sqrtPriceX96:", uint256(refSqrt));

        // Force the documented state: cache below the reference while the real price is above it.
        // (In the wild this arises from a zero-liquidity in-block crossing; here we set it directly.)
        // Must sit clearly outside the optimal band (band is only ~optimalFeeE6 = 7e-6 wide), so use
        // 0.1% below the reference: below the lower close boundary => "outside optimal range" branch.
        uint160 staleCache = refSqrt - uint160(refSqrt / 1000);
        _setFeeStateCache(keyUsdcUsdt, staleCache);

        // The real price is ABOVE the reference, the cache BELOW => a zeroForOne (corrective,
        // price-moving-down) swap is classified as "away" and charged 0.
        (, uint256 feeStale) = _swapAndFee(keyUsdcUsdt, true, 5_000e6);
        console2.log("same-block corrective swap feeE6 (stale cache):", feeStale);
        assertEq(feeStale, 0, "stale cache -> corrective swap charged 0");

        // self-heals next block: advance one block and repeat the same direction
        vm.roll(block.number + 1);
        (, uint256 feeFresh) = _swapAndFee(keyUsdcUsdt, true, 5_000e6);
        console2.log("next-block corrective swap feeE6 (fresh cache):", feeFresh);
        assertGt(feeFresh, 0, "fresh cache -> same swap pays a fee");
    }

    // ---------------------------------------------------------------- plumbing

    function _slot0(PoolKey memory k) internal view returns (uint160 sqrtPriceX96, int24 tick, uint24 proto, uint24 lp) {
        // StateView on Ethereum mainnet
        (bool ok, bytes memory ret) =
            address(0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227).staticcall(
                abi.encodeWithSignature("getSlot0(bytes32)", _poolId(k))
            );
        require(ok, "getSlot0 failed");
        return abi.decode(ret, (uint160, int24, uint24, uint24));
    }

    function _feeConfig(PoolKey memory k) internal view returns (uint24, uint24, uint8, uint160) {
        (bool ok, bytes memory ret) =
            k.hooks.staticcall(abi.encodeWithSignature("feeConfig(bytes32)", _poolId(k)));
        require(ok, "feeConfig failed");
        return abi.decode(ret, (uint24, uint24, uint8, uint160));
    }

    /// @dev Writes the StableFeeConfiguration ERC-7201 feeState[poolId] cache slot on the fork.
    ///      Namespaced location from the verified source; struct is one packed slot
    ///      (uint40 decayingFeeE12 | uint160 sqrtAmmPriceX96 | uint40 blockNumber).
    function _setFeeStateCache(PoolKey memory k, uint160 sqrtPriceX96) internal {
        bytes32 LOC = 0x4e65cbff7fdec8e7b73e40370c540338cf2b602902c10f166d6a73c4a7ee9e00;
        bytes32 stateMap = bytes32(uint256(LOC) + 1);
        bytes32 slot = keccak256(abi.encode(_poolId(k), stateMap));
        // packed layout: uint40 decayingFeeE12 | uint160 sqrtAmmPriceX96 | uint40 blockNumber
        uint256 packed = (uint256(block.number) << 200) | (uint256(sqrtPriceX96) << 40);
        vm.store(k.hooks, slot, bytes32(packed));
    }
}
