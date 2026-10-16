// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {SessionLib} from "./SessionLib.sol";

/// @title CalendarLib
/// @notice The per-swap fee-floor computation for `MarketCalendar`.
/// @dev An `internal`-function library, so its code is INLINED into the calling hook (a JUMP, not a
///      DELEGATECALL) and it reads the hook's own override storage (passed by reference) and its
///      session-hour / DST config (passed by value) directly. It layers the rewritable per-day
///      overrides on top of `SessionLib`'s pure baked calendar. Kept a separate unit purely for
///      organization; the target chain's ~98,304-byte runtime limit makes the old EIP-170 split
///      unnecessary.
library CalendarLib {
    /// @notice Trading session at `timestamp`, override-aware.
    function sessionAt(
        mapping(uint256 => uint64) storage dayOverrides,
        uint32 openSec,
        uint32 closeSec,
        SessionLib.DstMode dstMode,
        uint256 timestamp
    ) internal view returns (SessionLib.Session) {
        (uint256 day, uint256 sec, uint256 y, uint256 m, uint256 d) = _ctx(dstMode, timestamp);
        return _classify(dayOverrides, openSec, closeSec, day, sec, y, m, d);
    }

    /// @notice Fee floor (pips) at `timestamp` for `cfg`, including the opening descent and the
    ///         closing ramp. The caller clamps to the pool's fee bounds.
    function feeFloorAt(
        mapping(uint256 => uint64) storage dayOverrides,
        uint32 openSec,
        uint32 closeSec,
        SessionLib.DstMode dstMode,
        SessionLib.FloorConfig memory cfg,
        uint256 timestamp
    ) internal view returns (uint256) {
        // The ET context and session classification are in their own frame so this one does not
        // carry the civil-date locals alongside the descent/ramp math (legacy stack-too-deep).
        (SessionLib.Session session, uint256 sec, uint256 day) =
            _sessionCtx(dayOverrides, openSec, closeSec, dstMode, timestamp);

        bool fromClosed = false;
        if (
            session == SessionLib.Session.OPEN && cfg.descentWindow != 0
                && sec < uint256(openSec) + uint256(cfg.descentWindow)
        ) {
            fromClosed = day != 0 && _dayFullyClosed(dayOverrides, day - 1);
        }
        uint256 floor = SessionLib.floorFor(cfg, sec, openSec, session, fromClosed);

        // The closing ramp only applies on days that actually held a session — a weekend or
        // holiday has no closing auction to price. Gating on the day (rather than the session at
        // `sec`) is what taxes the Friday close, whose post-close hour classifies as CLOSED.
        if (cfg.closeFloor != 0 && !_dayFullyClosed(dayOverrides, day)) {
            uint256 ramp = SessionLib.closeRampFloor(cfg, sec, closeSec);
            if (ramp > floor) floor = ramp;
        }
        return floor;
    }

    /// @dev The ET session at `timestamp` plus the ET day and second-of-day, in one frame so
    ///      `feeFloorAt` never holds the civil-date parts (y/m/d) of the context.
    function _sessionCtx(
        mapping(uint256 => uint64) storage dayOverrides,
        uint32 openSec,
        uint32 closeSec,
        SessionLib.DstMode dstMode,
        uint256 timestamp
    ) private view returns (SessionLib.Session session, uint256 sec, uint256 day) {
        uint256 y;
        uint256 m;
        uint256 d;
        (day, sec, y, m, d) = _ctx(dstMode, timestamp);
        session = _classify(dayOverrides, openSec, closeSec, day, sec, y, m, d);
    }

    /// @dev The two override bits for an ET civil date: bit0 = force closed, bit1 = force open
    ///      (closed wins if both are set).
    function _overrideBits(mapping(uint256 => uint64) storage dayOverrides, uint256 y, uint256 m, uint256 d)
        private
        view
        returns (uint256)
    {
        return (dayOverrides[y * 100 + m] >> ((d - 1) * 2)) & 3;
    }

    /// @dev Single-pass time context: computes the UTC civil date once for the DST offset and
    ///      reuses it for the ET date whenever the ET day equals the UTC day (all but the
    ///      late-evening ET hours), saving a second civil-date computation on most swaps.
    function _ctx(SessionLib.DstMode dstMode, uint256 timestamp)
        private
        pure
        returns (uint256 day, uint256 sec, uint256 y, uint256 m, uint256 d)
    {
        uint256 utcDay = timestamp / SessionLib.SECONDS_PER_DAY;
        (uint256 uy, uint256 um, uint256 ud) = SessionLib.civilFromDay(utcDay);

        uint256 offset;
        if (dstMode == SessionLib.DstMode.FIXED_EST) offset = SessionLib.EST_OFFSET;
        else if (dstMode == SessionLib.DstMode.FIXED_EDT) offset = SessionLib.EDT_OFFSET;
        else offset = SessionLib.utcOffsetFromDate(uy, um, ud);

        uint256 et = timestamp - offset;
        day = et / SessionLib.SECONDS_PER_DAY;
        sec = et % SessionLib.SECONDS_PER_DAY;
        if (day == utcDay) {
            (y, m, d) = (uy, um, ud);
        } else {
            (y, m, d) = SessionLib.civilFromDay(day);
        }
    }

    function _classify(
        mapping(uint256 => uint64) storage dayOverrides,
        uint32 openSec,
        uint32 closeSec,
        uint256 day,
        uint256 sec,
        uint256 y,
        uint256 m,
        uint256 d
    ) private view returns (SessionLib.Session) {
        uint256 bits = _overrideBits(dayOverrides, y, m, d);
        bool force = bits == 2; // FORCE_OPEN
        bool closedDay = (bits & 1 == 1) || (!force && SessionLib.bakedClosed(y, m * 100 + d));

        // The trading-day hours flanking a closure price at their own OVERNIGHT tier — not the
        // closed one; the descent's starting tier (see feeFloorAt) is the only place a neighbouring
        // day's closure still matters. See MarketCalendar's history for the markout study behind it.
        return SessionLib.classify(day, sec, openSec, closeSec, closedDay, force);
    }

    /// @dev True when the given ET day had no trading session at all (weekend or closure),
    ///      override-aware. Used to pick the opening descent's starting tier.
    function _dayFullyClosed(mapping(uint256 => uint64) storage dayOverrides, uint256 day) private view returns (bool) {
        (uint256 y, uint256 m, uint256 d) = SessionLib.civilFromDay(day);
        uint256 bits = _overrideBits(dayOverrides, y, m, d);
        if (bits == 2) return false; // FORCE_OPEN
        if (bits & 1 == 1) return true; // FORCE_CLOSED
        uint256 dow = SessionLib.dayOfWeek(day);
        if (dow == 0 || dow == 6) return true;
        return SessionLib.bakedClosed(y, m * 100 + d);
    }
}
