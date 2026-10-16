// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {SessionLib} from "../libraries/SessionLib.sol";
import {CalendarLib} from "../libraries/CalendarLib.sol";

/// @title MarketCalendar
/// @notice Session and fee-floor views combining SessionLib's pure math with a fully
///         rewritable storage overlay.
/// @dev Every calendar assumption is correctable in storage, in both directions: any day can
///      be forced closed (missed holidays, unscheduled closures, years beyond the baked
///      table) or forced open (a spuriously baked closure), session hours can be moved, and
///      the DST mode can be pinned should the US statutory rule change. When no override is
///      set, behavior is fully autonomous from the baked calendar. Access control is left to
///      the inheriting contract via `_checkCalendarAdmin`.
abstract contract MarketCalendar {
    /// @notice A day-override bitmap that no real calendar could mean: a day index past 31, or one
    ///         day marked both force-closed and force-open.
    error InvalidDayOverride();
    /// @notice More forced closures in one month than any exchange calendar has.
    error TooManyForcedClosures(uint256 closures);

    /// @notice Per-day correction state. NONE follows the baked calendar.
    enum DayOverride {
        NONE,
        FORCE_CLOSED,
        FORCE_OPEN
    }

    event DayOverridesSet(uint256 indexed yearMonth, uint64 packed);
    event SessionHoursSet(uint32 openSec, uint32 closeSec);
    event DstModeSet(SessionLib.DstMode mode);

    /// @dev `closeSec_` is bounded STRICTLY below a day. `SessionLib.classify` closes Friday
    ///      evening with `sec >= closeS`, and `sec` is `et % SECONDS_PER_DAY`, so a close of
    ///      exactly 86400 made that predicate unsatisfiable and the rule dead code — Friday
    ///      afternoon through midnight would have priced at the OPEN floor across the whole
    ///      weekend gap, with Saturday and Sunday still reading CLOSED so nothing looked wrong.
    ///      `MAX_SESSION_LENGTH` does not catch it: it bounds the session's length, not where in
    ///      the day it sits.
    error InvalidSessionHours();

    /// @notice How UTC is converted to ET. Defaults to the current US statutory rule.
    SessionLib.DstMode public dstMode;

    /// @notice Session open, as ET second-of-day.
    uint32 public openSec = uint32(SessionLib.OPEN_SEC);

    /// @notice Session close, as ET second-of-day.
    uint32 public closeSec = uint32(SessionLib.CLOSE_SEC);

    /// @dev yearMonth = year * 100 + month; 2 bits per day at offset (d - 1) * 2:
    ///      bit0 = force closed, bit1 = force open (closed wins if both are set).
    mapping(uint256 yearMonth => uint64 packed) private _dayOverrides;

    /// @notice Reverts unless the caller may administer the calendar.
    function _checkCalendarAdmin() internal virtual;

    /// @notice Largest number of days in one month this calendar will force CLOSED.
    /// @dev A real exchange calendar has a handful of holidays a month; the record is three. Ten is
    ///      far above any legitimate month and far below "the bitmap was packed wrong". The bound
    ///      exists because this setter is hand-fed a bit-packed integer, which is the one input
    ///      shape where a transposed nibble is invisible on review and catastrophic in effect.
    uint256 public constant MAX_FORCED_CLOSURES = 10;

    /// @notice Sets the per-day override bitmap for one month, replacing the previous one.
    /// @dev VALIDATED, unlike every earlier version of this function — it was the only calendar
    ///      setter with no checks at all, and it is the one with the deepest downward authority over
    ///      the fee. One bit takes a real trading day to `closedFloor`: measured on the shipped RWA
    ///      config, 3500 -> 200 at the post-holiday open (95%), 2500 -> 200 at the closing ramp
    ///      (92%). For comparison the poke — which this codebase calls "the one hot key in the
    ///      system" — may never cut more than `MAX_POKE_DISCOUNT_BPS` (50%) of the live autonomous
    ///      fee, and that ceiling is re-checked at resolution. A calendar bit cut 8x deeper on a
    ///      value `pokeFloor` is structurally blind to, because the floor it collapses to IS one of
    ///      the configured floors and so looks legitimate.
    ///
    ///      Three checks, each aimed at a real way a hand-packed bitmap goes wrong:
    ///        - a day index no month has (bits 62-63 are day 32);
    ///        - both bits set for one day, which is a packing error rather than an intent — the
    ///          resolver silently lets closed win, so this would never surface on its own;
    ///        - more forced closures than any exchange calendar has, which is the signature of a
    ///          shifted or inverted mask rather than a holiday list.
    ///      None of them constrains a legitimate calendar. All of them turn a silent, delayed,
    ///      pool-wide fee collapse into a reverted transaction.
    function setDayOverrides(uint256 yearMonth, uint64 packed) external {
        _checkCalendarAdmin();
        // Day 32 does not exist in any month; its bits can only be a packing mistake.
        if (packed & (uint64(3) << 62) != 0) revert InvalidDayOverride();
        uint256 closures = 0;
        for (uint256 d = 0; d < 31; d++) {
            uint64 bits = (packed >> (d * 2)) & 3;
            if (bits == 3) revert InvalidDayOverride(); // force-closed AND force-open
            if (bits & 1 != 0) closures++;
        }
        if (closures > MAX_FORCED_CLOSURES) revert TooManyForcedClosures(closures);
        _dayOverrides[yearMonth] = packed;
        emit DayOverridesSet(yearMonth, packed);
    }

    /// @notice Moves the session hours (ET seconds-of-day).
    /// @notice Longest trading session the calendar will accept, fixed in bytecode. NYSE runs
    ///         6.5h; 12h leaves room for any plausible venue without allowing a 24h "session".
    /// @dev A floor as well as a ceiling. `MAX_SESSION_LENGTH` closed the lengthening direction —
    ///      a day-long session made every weekday second read OPEN — but said nothing about the
    ///      other one. `setSessionHours(34200, 34201)` passed every check and made the OPEN
    ///      session one second per day, which deletes `SessionLib.floorFor`'s entire opening
    ///      descent: the highest-priced window in the hook, and the one that prices the weekend
    ///      and holiday gaps, simply stops existing. Measured at 60s into a Monday open following
    ///      a weekend: 58033 pips before, 3000 after. The spike is `prior * spikeMult`, not one of
    ///      the three configured floors, so `pokeFloor` cannot detect its absence either.
    uint32 public constant MIN_SESSION_LENGTH = 1 hours;
    uint32 public constant MAX_SESSION_LENGTH = 12 hours;

    function setSessionHours(uint32 openSec_, uint32 closeSec_) external {
        _checkCalendarAdmin();
        // The session's LENGTH is the sole input deciding OPEN vs OVERNIGHT, and nothing bounded
        // it. `setSessionHours(1, 86400)` made every weekday second read OPEN, and combined with
        // FORCE_OPEN day overrides it collapsed all three fee tiers onto the cheapest one for the
        // whole week — a 6x subsidy handed to exactly the gap arbitrage the closed tier prices.
        // `pokeFloor` cannot detect that, because `setPoolConfig` sets it to the MINIMUM of the
        // three tiers. This role is deliberately separated from the fund-moving one on the
        // premise that its worst case is "flipping a day between two configured fee floors";
        // this bound is what makes that premise true.
        if (
            openSec_ == 0 || openSec_ >= closeSec_ || closeSec_ >= SessionLib.SECONDS_PER_DAY
                || closeSec_ - openSec_ > MAX_SESSION_LENGTH || closeSec_ - openSec_ < MIN_SESSION_LENGTH
        ) {
            revert InvalidSessionHours();
        }
        openSec = openSec_;
        closeSec = closeSec_;
        emit SessionHoursSet(openSec_, closeSec_);
    }

    /// @notice Sets the DST handling mode.
    function setDstMode(SessionLib.DstMode mode) external {
        _checkCalendarAdmin();
        dstMode = mode;
        emit DstModeSet(mode);
    }

    /// @notice Override state for a given ET civil date.
    function dayOverride(uint256 y, uint256 m, uint256 d) public view returns (DayOverride) {
        uint256 bits = (_dayOverrides[y * 100 + m] >> ((d - 1) * 2)) & 3;
        if (bits & 1 == 1) return DayOverride.FORCE_CLOSED;
        if (bits == 2) return DayOverride.FORCE_OPEN;
        return DayOverride.NONE;
    }

    /// @notice Trading session at the given timestamp.
    /// @dev A thin wrapper over `CalendarLib.sessionAt`, which is inlined into this contract.
    function sessionAt(uint256 timestamp) public view returns (SessionLib.Session) {
        return CalendarLib.sessionAt(_dayOverrides, openSec, closeSec, dstMode, timestamp);
    }

    /// @notice Fee floor (in pips) at the given timestamp for the given configuration, including
    ///         the opening descent and the closing ramp. Caller clamps to pool fee bounds.
    /// @dev The whole computation — the DST/ET context, the override-aware session classification,
    ///      the opening descent and the closing ramp — lives in `CalendarLib`, inlined into this
    ///      contract; it reads this contract's override storage and session config by reference.
    function feeFloorAt(SessionLib.FloorConfig memory cfg, uint256 timestamp) public view returns (uint256) {
        return CalendarLib.feeFloorAt(_dayOverrides, openSec, closeSec, dstMode, cfg, timestamp);
    }
}
