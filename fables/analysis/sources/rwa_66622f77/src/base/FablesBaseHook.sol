// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

/// @title FablesBaseHook
/// @notice Singleton dynamic-fee hook base: per-pool fee caps, an autonomous per-pool fee
///         supplied by the inheriting contract, and a TTL-bounded poked override on top.
/// @dev The fee resolves as: poked fee while fresh, otherwise the autonomous fee; always
///      clamped to the pool's cap. The poke fully replaces the autonomous fee (it can lower
///      as well as raise) and expires on its own, so the system never depends on an operator
///      but can always be corrected by one. Uses only the fee-override return of
///      `beforeSwap` — no delta flags.
abstract contract FablesBaseHook is AccessManaged {
    using LPFeeLibrary for uint24;
    using PoolIdLibrary for PoolKey;

    error NotPoolManager();
    error NotDynamicFeePool();
    error NativeNotSupported();
    error PoolNotConfigured();
    error FeeAboveCap();
    error InvalidTtl();
    error InvalidMaxFee();
    error FeeBelowFloor();

    event FeePoked(PoolId indexed poolId, uint24 fee, uint40 expiry);
    event PokeCleared(PoolId indexed poolId);

    struct Poke {
        uint24 fee;
        uint40 expiry;
    }

    /// @notice Longest a poked fee can outlive its transaction.
    uint40 public constant MAX_POKE_TTL = 72 hours;

    /// @notice Hard ceiling on any pool's fee cap, fixed at deployment. No role can configure
    ///         or poke a fee above it; changing it means deploying a new singleton.
    uint24 public immutable ABSOLUTE_MAX_FEE;

    IPoolManager public immutable poolManager;

    /// @notice Per-pool fee cap in pips; zero means the pool is not configured.
    mapping(PoolId poolId => uint24 cap) public maxFee;
    /// @notice Most of the live autonomous fee a poke may cut away. A poke is for reacting
    ///         fast, not for switching the curve off; a mis-classified market day is corrected
    ///         through the calendar overlay, which is what that overlay exists for.
    uint16 public constant MAX_POKE_DISCOUNT_BPS = 5000;

    /// @notice Cheapest fee any pool may be configured to charge, fixed in bytecode.
    uint24 public constant MIN_POOL_FEE = 100; // 0.01%, Uniswap's smallest standard tier

    /// @notice Cheapest fee each pool can charge autonomously — the lower bound on a poke.
    mapping(PoolId poolId => uint24 floor) public pokeFloor;

    /// @notice Active poked override per pool; ignored once expired.
    mapping(PoolId poolId => Poke poke) public pokeOf;

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager poolManager_, address authority_, uint24 absoluteMaxFee_) AccessManaged(authority_) {
        if (absoluteMaxFee_ == 0 || absoluteMaxFee_ > LPFeeLibrary.MAX_LP_FEE) revert InvalidMaxFee();
        ABSOLUTE_MAX_FEE = absoluteMaxFee_;
        poolManager = poolManager_;
        Hooks.validateHookPermissions(IHooks(address(this)), _hookPermissions());
    }

    /// @notice Callback set this hook uses; never includes delta flags.
    function _hookPermissions() internal pure virtual returns (Hooks.Permissions memory permissions) {
        permissions.beforeInitialize = true;
        permissions.beforeSwap = true;
    }

    /// @notice Pools must use the dynamic-fee flag and be configured before initialization.
    function beforeInitialize(address, PoolKey calldata key, uint160) external view onlyPoolManager returns (bytes4) {
        if (!key.fee.isDynamicFee()) revert NotDynamicFeePool();
        if (maxFee[key.toId()] == 0) revert PoolNotConfigured();
        // `_checkKey` refuses native currency0, but that guard sits on the ledger paths, not on
        // the gate that creates the pool — so a native pool could be configured, initialized and
        // traded with dynamic fees while every deposit, withdraw, stake and claim reverted. A
        // pool no LP can ever hold a position in should not exist at all.
        if (key.currency0.isAddressZero()) revert NativeNotSupported();
        return IHooks.beforeInitialize.selector;
    }

    /// @notice Returns the per-swap fee override; never touches swap deltas.
    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        view
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = _resolveFee(key.toId(), params);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    /// @notice Fee the pool would charge a swap in the given direction right now, in pips.
    /// @dev Uses a zero-amount probe, so size-dependent components read as zero here.
    function currentFee(PoolId poolId, bool zeroForOne) external view returns (uint24) {
        return _resolveFee(
            poolId, IPoolManager.SwapParams({zeroForOne: zeroForOne, amountSpecified: 0, sqrtPriceLimitX96: 0})
        );
    }

    /// @notice Temporarily replaces the autonomous fee for a pool. Expires on its own.
    /// @dev Bounded on BOTH sides. The ceiling is the pool cap; the floor is the cheapest fee
    ///      the pool is configured to charge autonomously, so ops can still correct a fee that
    ///      is wrongly high (a mis-classified market day, say) but cannot go anywhere the pool
    ///      would not have gone by itself. This role is the one hot key in the system, granted
    ///      with no execution delay because reacting fast is its whole purpose — which makes it
    ///      the likeliest to be compromised. Without a floor, whoever held it could set every
    ///      pool to zero for 72 hours and renew for the price of gas, so LPs earn nothing while
    ///      arbitrageurs take the pool apart for free. A ceiling alone bounds the wrong end.
    function pokeFee(PoolId poolId, uint24 fee, uint40 ttl) external restricted {
        uint24 cap = maxFee[poolId];
        if (cap == 0) revert PoolNotConfigured();
        if (fee > cap) revert FeeAboveCap();
        if (fee < pokeFloor[poolId]) revert FeeBelowFloor();
        if (ttl == 0 || ttl > MAX_POKE_TTL) revert InvalidTtl();
        uint40 expiry = uint40(block.timestamp) + ttl;
        pokeOf[poolId] = Poke({fee: fee, expiry: expiry});
        emit FeePoked(poolId, fee, expiry);
    }

    /// @notice Clears an active poke, returning the pool to its autonomous fee.
    function clearPoke(PoolId poolId) external restricted {
        delete pokeOf[poolId];
        emit PokeCleared(poolId);
    }

    /// @notice Autonomous per-pool fee in pips for a swap, before poke and cap are applied.
    function _autonomousFee(PoolId poolId, IPoolManager.SwapParams memory params)
        internal
        view
        virtual
        returns (uint256);

    function _resolveFee(PoolId poolId, IPoolManager.SwapParams memory params) internal view returns (uint24) {
        uint256 autonomous = _autonomousFee(poolId, params);
        uint256 fee = autonomous;
        Poke memory poke = pokeOf[poolId];
        // second-level timestamp drift is immaterial against a >=1h TTL
        // forge-lint: disable-next-line(block-timestamp)
        if (poke.expiry > block.timestamp) {
            fee = poke.fee;
            // The poke's bounds are enforced at RESOLUTION, not only when it was set. Checking
            // once at `pokeFee` left two holes: raising a pool's floor afterwards left a live
            // poke charging under the new floor for up to 72h, and the static floor said nothing
            // about the pool's CURRENT fee — so the hot key could pin a pool that its own curve
            // had ramped to 400bps back down to its 100bps configured floor, renewably, handing
            // a permanent subsidy to exactly the toxic flow the curve exists to price.
            uint256 floor_ = pokeFloor[poolId];
            uint256 discountFloor = (autonomous * (10_000 - MAX_POKE_DISCOUNT_BPS)) / 10_000;
            if (floor_ < discountFloor) floor_ = discountFloor;
            if (fee < floor_) fee = floor_;
        }
        uint256 cap = maxFee[poolId];
        if (fee > cap) fee = cap;
        // casting to 'uint24' is safe: fee is clamped to cap, which _setPoolBounds bounds to MAX_LP_FEE < 2^24
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint24(fee);
    }

    /// @dev Records the pool's bounds. `floor` is the cheapest fee its own curve can produce;
    ///      it is what a poke may not undercut. Each hook computes it from its own config.
    function _setPoolBounds(PoolId poolId, uint24 floor, uint24 cap) internal {
        if (cap == 0 || cap > ABSOLUTE_MAX_FEE) revert InvalidMaxFee();
        // A lower bound on the CONFIG, not just on the poke. `pokeFee` was carefully bounded on
        // both sides while the config path — which sets the very floor the poke is measured
        // against — could be driven to 1 pip on a live pool, draining LPs by the same route the
        // poke floor exists to block.
        if (floor < MIN_POOL_FEE || floor > cap) revert InvalidMaxFee();
        maxFee[poolId] = cap;
        pokeFloor[poolId] = floor;
    }
}
