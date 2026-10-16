// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {FablesLedger} from "./base/FablesLedger.sol";
import {FablesBaseHook} from "./base/FablesBaseHook.sol";

/// @title FablesRamp
/// @notice The unified non-calendar fee hook. One singleton serves every non-equity pool —
///         memecoin, blue-chip, token-issuer — each as a per-pool FLAT fee with a bounded, TTL-
///         expiring operator override (`pokeFee` on the base hook). There is no autonomous dynamic
///         fee: a pool charges its configured `flatPips`, and any responsiveness is applied off-chain
///         and poked on top within a band strictly inside `[floorPips, cap]` — the block below gives
///         the real floor, which a poke cannot go under.
/// @dev WHY NO ON-CHAIN VOLATILITY FEE. An earlier design priced the fee off realized volatility (a
///      Parkinson tick-range estimator, `VolLib`). It was measured against real data and removed. A
///      price-derived estimator can only read realized volatility from the pool's OWN series, and
///      that has two dead ends: for memecoins it saturates, so the ramp pins at its ceiling and is a
///      flat fee in all but name; for blue-chips the quantity that actually matters — LVR / adverse
///      selection against the external mid — is invisible without an ORACLE. A flat fee plus an
///      oracle-driven off-chain poke is both simpler and strictly better where it matters, so the
///      estimator (and the sell-surcharge / quote-orientation machinery it carried) is gone.
///
///      The floor / flat / cap are per-pool and admin-adjustable within the deployment's absolute
///      ceiling, so calibration is a config change, not a redeploy. The poke can only ever move the
///      live fee inside `[max(floorPips, min(preFee, cap)/2), cap]` and lapses back to `flatPips` on
///      expiry, where `preFee` is `flatPips + premiumPips` in the premium direction and `flatPips`
///      in the other. The direction matters and this line used to state the premium term
///      unconditionally: `_resolveFee` computes the discount floor from `preFee`, so on the
///      NON-premium side the real floor is `max(floorPips, min(flatPips, cap)/2)`. A keeper
///      composing the non-premium side from the unconditional form gets a floor that is too high —
///      the safe direction, but wrong, and the old parenthetical made it sound as though the term
///      always applied.
///
///      A keeper failure is benign regardless: the flat is the fee the pool really charges when
///      unattended.
contract FablesRamp is FablesLedger {
    using PoolIdLibrary for PoolKey;

    error InvalidConfig();

    event PoolConfigured(PoolId indexed poolId, uint24 floorPips, uint24 flatPips, uint24 maxFee);

    /// @notice The flat fee (pips) each pool charges autonomously, before any poke and the cap.
    mapping(PoolId poolId => uint24 flatPips) internal _flatPips;

    constructor(IPoolManager poolManager_, address authority_, uint24 absoluteMaxFee_)
        FablesBaseHook(poolManager_, authority_, absoluteMaxFee_)
    {}

    function _hookPermissions() internal pure virtual override returns (Hooks.Permissions memory permissions) {
        permissions.beforeInitialize = true;
        permissions.beforeSwap = true;
    }

    /// @notice The flat fee configured for a pool, in pips.
    function flatFee(PoolId poolId) external view returns (uint24) {
        return _flatPips[poolId];
    }

    /// @notice Registers or updates a pool's flat fee and its poke bounds. `floorPips` is the
    ///         cheapest a poke may reach, `flatPips` the fee charged with no live poke, `cap` the
    ///         ceiling; a poke never escapes `[floorPips, cap]` and expires back to `flatPips`.
    function setPoolConfig(PoolKey calldata key, uint24 floorPips, uint24 flatPips, uint24 cap) external restricted {
        _checkOwnPool(key);
        if (flatPips < floorPips || flatPips > cap) revert InvalidConfig();
        PoolId poolId = key.toId();
        _flatPips[poolId] = flatPips;
        // Also validates floorPips >= MIN_POOL_FEE, floorPips <= cap <= ABSOLUTE_MAX_FEE.
        _setPoolBounds(poolId, floorPips, cap);
        emit PoolConfigured(poolId, floorPips, flatPips, cap);
    }

    /// @notice The autonomous fee is simply the pool's flat rate; the base resolver applies the poke
    ///         override and the cap on top.
    function _autonomousFee(PoolId poolId, IPoolManager.SwapParams memory) internal view override returns (uint256) {
        return _flatPips[poolId];
    }
}
