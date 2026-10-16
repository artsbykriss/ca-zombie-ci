// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {FablesLedger} from "./base/FablesLedger.sol";
import {FablesBaseHook} from "./base/FablesBaseHook.sol";
import {MarketCalendar} from "./base/MarketCalendar.sol";
import {SessionLib} from "./libraries/SessionLib.sol";

/// @title FablesRWA
/// @notice Session-aware dynamic-fee hook for tokenized equity pairs. One singleton serves
///         every pool, keyed by PoolId.
/// @dev The autonomous fee is the session floor: open / overnight / closed tiers with a linear
///      opening descent and a closing ramp around the bell, driven entirely by block.timestamp
///      through MarketCalendar. The two bells are where a tokenised stock's LP loss concentrates —
///      the opening and closing auctions stamp a reference the pool is blind to — and a calendar is
///      the only signal that knows the toxic minute before it arrives. An operator poke (see
///      FablesBaseHook) can temporarily replace the floor.
contract FablesRWA is FablesLedger, MarketCalendar {
    /// @notice Longest opening descent, fixed in bytecode. Unbounded, it overflowed a uint32
    ///         add inside beforeSwap and reverted every swap during the open session — a
    ///         time-gated denial of service from one unvalidated config field.
    uint32 public constant MAX_DESCENT_WINDOW = 6 hours;

    using PoolIdLibrary for PoolKey;

    error InvalidFloorConfig();

    event PoolConfigured(PoolId indexed poolId, SessionLib.FloorConfig config, uint24 maxFee);

    mapping(PoolId poolId => SessionLib.FloorConfig config) internal _floorConfig;

    constructor(IPoolManager poolManager_, address authority_, uint24 absoluteMaxFee_)
        FablesBaseHook(poolManager_, authority_, absoluteMaxFee_)
    {}

    /// @notice Floor configuration for a pool.
    function floorConfig(PoolId poolId) external view returns (SessionLib.FloorConfig memory) {
        return _floorConfig[poolId];
    }

    /// @notice Ceiling on the routine opening-descent multiplier. `descentWindow` got a bytecode
    ///         bound after an overflow; the multiplier beside it had none, so a config could ask for
    ///         255x the overnight floor and rely on the downstream cap clamp to hide it. The
    ///         live multiples are 5x (NVDA: overnight 800) and 8x (TSLA: overnight 500); the "17x"
    ///         this line used to cite occurs only in a test fixture and reproduces from no shipped
    ///         config. 20 leaves headroom for recalibration, but note it is NOT below the regime
    ///         where the cap clamp bites: that threshold is `cap / overnightFloor`, which on live
    ///         NVDA (cap 8000, overnight 800) is 10 — so this bound is already twice past it, and
    ///         on TSLA it lands exactly on it. The post-closure spike is set absolutely via
    ///         `closedSpike`, so it needs no multiplier.
    ///
    ///         `closedSpike` IS NOT BOUNDED BY THE POOL CAP. This line used to say it was, in
    ///         parentheses, and `setPoolConfig` twenty lines below says the opposite deliberately
    ///         ("Either may sit ABOVE the cap and be clamped at resolution"), as does
    ///         `FablesBaseHook` ("the one fee field the validator never compares against `cap`").
    ///         The resolution-time clamp exists BECAUSE the config-time bound does not, so a reader
    ///         trusting the old parenthetical would delete the clamp as dead — restoring the state
    ///         where every legal poke resolves to the cap and the hot key's lever is a silent
    ///         no-op during the opening descent.
    uint8 public constant MAX_SPIKE_MULT = 20;

    /// @notice Registers or updates a pool's floors and fee cap. SHOULD be set before the
    ///         pool is initialized.
    /// @dev NOT ENFORCED, and re-configuring a LIVE pool is a supported operation — the `@notice`
    ///      said "must" and the code has never checked it. The live NVDA pool contradicts it
    ///      directly: it was reconfigured by hand after launch, and `SessionLib.closeRampFloor`'s
    ///      whole analysis is written about that configuration. `_setPoolBounds` re-validates the
    ///      entire band and the premium invariant on every write, so a live reconfiguration is safe
    ///      — but it is a REPRICING of an open market and should be reviewed as one.
    function setPoolConfig(PoolKey calldata key, SessionLib.FloorConfig calldata config, uint24 cap)
        external
        restricted
    {
        _checkOwnPool(key);
        if (
            config.openFloor == 0 || config.overnightFloor == 0 || config.closedFloor == 0 || config.openFloor > cap
                || config.overnightFloor > cap || config.closedFloor > cap || config.descentWindow > MAX_DESCENT_WINDOW
                || config.spikeMult > MAX_SPIKE_MULT
                // A descent window must actually lift the spike above `openFloor`, or `floorFor`
                // returns the flat floor and the descent never happens while the event and
                // `floorConfig()` still advertise one — the "reads as configured, acts as off" third
                // state this validation forbids. Two openings share the window: a routine open
                // descends from `overnightFloor * spikeMult`, a post-closure open (Monday, the
                // morning after a holiday) from the ABSOLUTE `closedSpike`. Require BOTH starting
                // heights to clear `openFloor`. Either may sit ABOVE the cap and be clamped at
                // resolution — the opening spike is the one place a config legitimately reaches for
                // the ceiling, and `closedSpike` is the routine spike's absolute twin, so both clamp.
                || (config.descentWindow != 0
                    && (uint256(config.overnightFloor) * config.spikeMult <= config.openFloor
                        || config.closedSpike <= config.openFloor))
                // `closedSpike` is an absolute peak with nothing to decay over when the window is
                // off — a value set here would read as configured while doing nothing. Reject it,
                // the same "no inert third state" rule the descent and closing ramp both obey.
                || (config.descentWindow == 0 && (config.closedSpike != 0 || config.spikeMult != 0))
                // No ordering is imposed on the three floors, and that is a DELIBERATE gap with one
                // consequence worth naming: `SessionLib.classify` forces Friday's post-bell hours to
                // CLOSED while Monday's pre-bell hours fall through to OVERNIGHT, so the two flanks of
                // one weekend price at different tiers. With `closedFloor > overnightFloor` the later
                // flank — carrying the whole weekend of off-venue discovery — is the cheaper one.
                // NOT ENFORCED, and NOT universally true of the live slate. An earlier version of this
                // comment said "every shipped config has `closedFloor < overnightFloor`, which puts the
                // gradient the right way round". Read from mainnet, the GOLD pool
                // (hook 0xB608a78761f179f7C56f15E7D13921B92F00a080) carries
                // `(3000, 3000, 6000, 0, 0, 0, 0, 0, 0)` — `closedFloor 6000 > overnightFloor 3000` — so
                // it drops 5000 bps at Monday 00:00:00 ET and prices the whole 9.5-hour Monday pre-open,
                // the flank this very comment calls the one "carrying the whole weekend of off-venue
                // discovery", at half the Saturday rate. `W3_02._flatTiers` makes all three floors
                // `vm.envOr`-overridable, so the shape is reachable from a shipped script too.
                //
                // What IS true is weaker, and enough: the three floors are independent session prices
                // — the calibrated shape is open > overnight > closed, because the open and its bells
                // are the toxic windows rather than the closure — and the calendar no longer promotes
                // flanking hours to CLOSED, so nothing downstream depends on their relative order.
                // Closing ramp. It must elevate (>= openFloor, or its ramp math underflows) and sit
                // under the cap (or the resolver clamps it, hiding the config). Same "no inert third
                // state" rule as the opening descent: a peak with no window, or windows with no
                // peak, reads as configured while doing nothing — reject both.
                || config.closeFloor > cap
                || (config.closeFloor != 0
                    && (config.closeFloor < config.openFloor
                        || (config.closeBefore == 0 && config.closeAfter == 0)
                        || config.closeBefore > MAX_DESCENT_WINDOW
                        || config.closeAfter > MAX_DESCENT_WINDOW))
                || (config.closeFloor == 0 && (config.closeBefore != 0 || config.closeAfter != 0))
        ) revert InvalidFloorConfig();
        PoolId poolId = key.toId();
        _floorConfig[poolId] = config;
        // the cheapest session the calendar can put this pool in; a poke may correct down to it
        uint24 floor = config.openFloor;
        if (config.overnightFloor < floor) floor = config.overnightFloor;
        if (config.closedFloor < floor) floor = config.closedFloor;
        _setPoolBounds(poolId, floor, cap);
        emit PoolConfigured(poolId, config, cap);
    }

    /// @dev The session floor is direction-agnostic (see fera's intentional-symmetry note:
    ///      the descent is calibrated so healing arbs stay profitable without discrimination).
    function _autonomousFee(PoolId poolId, IPoolManager.SwapParams memory) internal view override returns (uint256) {
        return feeFloorAt(poolId, _floorConfig[poolId], block.timestamp);
    }

    /// @dev A pool this hook serves is exactly one with a configured fee cap — the same test
    ///      `beforeInitialize` and the ledger's `_checkKey` use.
    function _checkCalendarPool(PoolId poolId) internal view override {
        if (maxFee[poolId] == 0) revert PoolNotConfigured();
    }

    function _checkCalendarAdmin() internal override {
        _checkCanCall(_msgSender(), _msgData());
    }
}
