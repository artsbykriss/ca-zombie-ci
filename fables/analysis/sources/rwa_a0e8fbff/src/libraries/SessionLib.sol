// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/// @title SessionLib
/// @notice Pure time math mapping unix timestamps to US equity trading sessions and fee floors.
/// @dev Derives everything from the timestamp: civil-date arithmetic, the US DST rule
///      (second Sunday of March / first Sunday of November), and the published NYSE full-day
///      holiday calendar for 2026-2030 baked in as constants. Contains no storage; consumers
///      that need corrections or later years overlay a storage calendar (see MarketCalendar).
///      Valid for timestamps from 2026-01-01 onward.
library SessionLib {
    /// @notice Trading session tiers. CLOSED covers weekends and full-day closures.
    enum Session {
        OPEN,
        OVERNIGHT,
        CLOSED
    }

    /// @notice How the UTC->ET offset is derived. AUTO follows the current US statutory DST
    ///         rule; the FIXED modes are an escape hatch should that rule ever change.
    enum DstMode {
        AUTO,
        FIXED_EST,
        FIXED_EDT
    }

    /// @notice Per-pool fee floor configuration. All fee values are pips (1e-6).
    /// @param openFloor Floor during regular trading hours.
    /// @param overnightFloor Floor outside regular hours on trading days.
    /// @param closedFloor Floor on weekends and full-day closures.
    /// @param spikeMult A routine (overnight-preceded) open descends from `overnightFloor * spikeMult`.
    /// @param closedSpike A post-closure open (Monday, the morning after a holiday) descends from this
    ///        ABSOLUTE peak instead. That open is the most toxic — a whole weekend of off-venue price
    ///        discovery the pool is blind to — yet `closedFloor` is the cheapest tier, so pricing its
    ///        spike as `closedFloor * spikeMult` put the LOWEST spike on the WORST open. Setting it
    ///        absolutely decouples the post-weekend peak from the (cheap) weekend floor.
    /// @param descentWindow Seconds of linear descent after the open, shared by both openings; 0
    ///        disables the opening spike entirely.
    /// @param closeFloor Peak floor across the closing window; 0 disables the closing ramp. The
    ///        closing auction is the day's largest liquidity event and stamps a reference the pool
    ///        is blind to, so the window straddling it is the second toxic band the calendar knows
    ///        about in advance — the opening bell being the first.
    /// @param closeBefore Seconds before the session close the ramp lifts from `openFloor` to
    ///        `closeFloor`.
    /// @param closeAfter Seconds after the session close the peak is held.
    struct FloorConfig {
        uint24 openFloor;
        uint24 overnightFloor;
        uint24 closedFloor;
        uint8 spikeMult;
        uint24 closedSpike;
        uint32 descentWindow;
        uint24 closeFloor;
        uint32 closeBefore;
        uint32 closeAfter;
    }

    uint256 internal constant SECONDS_PER_DAY = 86400;
    uint256 internal constant EST_OFFSET = 18000; // UTC-5
    uint256 internal constant EDT_OFFSET = 14400; // UTC-4
    uint256 internal constant OPEN_SEC = 34200; // 09:30 ET
    uint256 internal constant CLOSE_SEC = 57600; // 16:00 ET

    /// @notice Session for a timestamp using only the baked-in calendar, default session
    ///         hours and AUTO DST.
    /// @dev Convenience path; storage-aware consumers compose `etDayAndSec` + `classify`.
    function sessionAt(uint256 timestamp) internal pure returns (Session) {
        (uint256 day, uint256 sec) = etDayAndSec(timestamp, DstMode.AUTO);
        (uint256 y, uint256 m, uint256 d) = civilFromDay(day);
        return classify(day, sec, OPEN_SEC, CLOSE_SEC, bakedClosed(y, m * 100 + d), false);
    }

    /// @notice Classifies an ET day + second-of-day into a session.
    /// @param openS Session open, as ET second-of-day.
    /// @param closeS Session close, as ET second-of-day.
    /// @param closedDay True when the day is a full-day closure beyond the weekend rule
    ///        (baked holiday and/or storage override, composed by the caller).
    /// @param forceTradingDay True to treat the day as a regular trading day, skipping the
    ///        weekend and closure rules entirely (calendar correction path).
    function classify(uint256 day, uint256 sec, uint256 openS, uint256 closeS, bool closedDay, bool forceTradingDay)
        internal
        pure
        returns (Session)
    {
        if (!forceTradingDay) {
            uint256 dow = dayOfWeek(day);
            if (dow == 0 || dow == 6) return Session.CLOSED; // Sunday / Saturday
            if (dow == 5 && sec >= closeS) return Session.CLOSED; // Friday after close
            if (closedDay) return Session.CLOSED;
        }
        if (sec >= openS && sec < closeS) return Session.OPEN;
        return Session.OVERNIGHT;
    }

    /// @notice Fee floor for a precomputed session state.
    /// @param sec ET second-of-day (only read when `session` is OPEN).
    /// @param openS Session open, as ET second-of-day (descent anchor).
    /// @param fromClosed True when the session preceding this open was CLOSED; selects the
    ///        descent's starting tier.
    /// @dev The caller clamps the result to the pool's fee bounds.
    function floorFor(FloorConfig memory cfg, uint256 sec, uint256 openS, Session session, bool fromClosed)
        internal
        pure
        returns (uint256)
    {
        if (session == Session.CLOSED) return cfg.closedFloor;
        if (session == Session.OVERNIGHT) return cfg.overnightFloor;
        if (cfg.descentWindow == 0) return cfg.openFloor;

        uint256 elapsed = sec - openS;
        if (elapsed >= cfg.descentWindow) return cfg.openFloor;

        // The opening spike decays linearly back to `openFloor` over `descentWindow`. Its STARTING
        // height depends on what preceded the open: a post-closure open (Monday, the morning after a
        // holiday) starts from the ABSOLUTE `closedSpike`, a routine overnight-preceded open from the
        // multiplicative `overnightFloor * spikeMult`. Pricing the post-closure spike off the cheap
        // `closedFloor` put the smallest spike on the most toxic open — the bug this fixes.
        uint256 spike = fromClosed ? uint256(cfg.closedSpike) : uint256(cfg.overnightFloor) * cfg.spikeMult;
        if (spike <= cfg.openFloor) return cfg.openFloor;

        return cfg.openFloor + ((spike - cfg.openFloor) * (cfg.descentWindow - elapsed)) / cfg.descentWindow;
    }

    /// @notice The closing ramp's floor at ET second-of-day `sec`, or 0 when outside its window.
    /// @dev A pure function of the config, `sec` and the session close `closeS`. It knows nothing
    ///      about which day it is — the caller gates it to actual trading days, since a weekend or
    ///      holiday has no closing auction to price. Shape mirrors the study: lift linearly from
    ///      `openFloor` up to `closeFloor` over the `closeBefore` seconds approaching the close,
    ///      then hold `closeFloor` for `closeAfter` seconds after it. The caller takes the max of
    ///      this and the session floor, so this only ever RAISES the fee.
    function closeRampFloor(FloorConfig memory cfg, uint256 sec, uint256 closeS) internal pure returns (uint256) {
        if (cfg.closeFloor == 0) return 0;

        // ramp in: [closeS - closeBefore, closeS) — guarded so a close near midnight cannot wrap
        if (cfg.closeBefore != 0 && closeS >= cfg.closeBefore) {
            uint256 rampStart = closeS - cfg.closeBefore;
            if (sec >= rampStart && sec < closeS) {
                uint256 rise = uint256(cfg.closeFloor) - cfg.openFloor; // closeFloor >= openFloor by config
                return cfg.openFloor + (rise * (sec - rampStart)) / cfg.closeBefore;
            }
        }

        // hold: [closeS, closeS + closeAfter). `sec` is always < SECONDS_PER_DAY, so this never
        // spills into the next ET day even if closeS + closeAfter would exceed it.
        if (sec >= closeS && sec < closeS + cfg.closeAfter) {
            return cfg.closeFloor;
        }

        return 0;
    }

    /// @notice ET day index and second-of-day for a timestamp under the given DST mode.
    function etDayAndSec(uint256 timestamp, DstMode mode) internal pure returns (uint256 day, uint256 sec) {
        uint256 et = timestamp - utcOffset(timestamp, mode);
        day = et / SECONDS_PER_DAY;
        sec = et % SECONDS_PER_DAY;
    }

    /// @notice UTC offset in seconds for US Eastern Time at the given timestamp.
    /// @dev AUTO is day-granular around the DST switch; both switch days are Sundays, where
    ///      the session is CLOSED under either offset, so fee output is unaffected.
    function utcOffset(uint256 timestamp, DstMode mode) internal pure returns (uint256) {
        if (mode == DstMode.FIXED_EST) return EST_OFFSET;
        if (mode == DstMode.FIXED_EDT) return EDT_OFFSET;
        (uint256 y, uint256 m, uint256 d) = civilFromDay(timestamp / SECONDS_PER_DAY);
        return utcOffsetFromDate(y, m, d);
    }

    /// @notice AUTO-rule UTC offset from a precomputed civil date (single-pass callers).
    function utcOffsetFromDate(uint256 y, uint256 m, uint256 d) internal pure returns (uint256) {
        if (m > 3 && m < 11) return EDT_OFFSET;
        if (m < 3 || m > 11) return EST_OFFSET;
        if (m == 3) {
            uint256 secondSunday = 8 + (7 - dayOfWeek(dayFromCivil(y, 3, 1))) % 7;
            return d >= secondSunday ? EDT_OFFSET : EST_OFFSET;
        }
        uint256 firstSunday = 1 + (7 - dayOfWeek(dayFromCivil(y, 11, 1))) % 7;
        return d < firstSunday ? EDT_OFFSET : EST_OFFSET;
    }

    /// @notice Day of week for a days-since-epoch value. 0 = Sunday .. 6 = Saturday.
    function dayOfWeek(uint256 day) internal pure returns (uint256) {
        return (day + 4) % 7;
    }

    /// @notice Civil date from days since the unix epoch.
    function civilFromDay(uint256 day) internal pure returns (uint256 y, uint256 m, uint256 d) {
        unchecked {
            uint256 z = day + 719468;
            uint256 era = z / 146097;
            uint256 doe = z % 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;
            d = doy - (153 * mp + 2) / 5 + 1;
            m = mp < 10 ? mp + 3 : mp - 9;
            y = yoe + era * 400 + (m <= 2 ? 1 : 0);
        }
    }

    /// @notice Days since the unix epoch from a civil date.
    function dayFromCivil(uint256 y_, uint256 m, uint256 d) internal pure returns (uint256) {
        unchecked {
            uint256 y = y_ - (m <= 2 ? 1 : 0);
            uint256 era = y / 400;
            uint256 yoe = y - era * 400;
            uint256 doy = (153 * (m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1;
            uint256 doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
            return era * 146097 + doe - 719468;
        }
    }

    /// @notice Baked NYSE full-day closure check. `mmdd` is month * 100 + day in ET.
    /// @dev Published calendar with observance shifts applied. Covers 2026-2030; returns
    ///      false outside that range — later years and one-off closures come from the
    ///      storage overlay.
    function bakedClosed(uint256 y, uint256 mmdd) internal pure returns (bool) {
        if (y == 2026) {
            return mmdd == 101 || mmdd == 119 || mmdd == 216 || mmdd == 403 || mmdd == 525 || mmdd == 619 || mmdd == 703
                || mmdd == 907 || mmdd == 1126 || mmdd == 1225;
        }
        if (y == 2027) {
            return mmdd == 101 || mmdd == 118 || mmdd == 215 || mmdd == 326 || mmdd == 531 || mmdd == 618 || mmdd == 705
                || mmdd == 906 || mmdd == 1125 || mmdd == 1224;
        }
        if (y == 2028) {
            return mmdd == 117 || mmdd == 221 || mmdd == 414 || mmdd == 529 || mmdd == 619 || mmdd == 704 || mmdd == 904
                || mmdd == 1123 || mmdd == 1225;
        }
        if (y == 2029) {
            return mmdd == 101 || mmdd == 115 || mmdd == 219 || mmdd == 330 || mmdd == 528 || mmdd == 619 || mmdd == 704
                || mmdd == 903 || mmdd == 1122 || mmdd == 1225;
        }
        if (y == 2030) {
            return mmdd == 101 || mmdd == 121 || mmdd == 218 || mmdd == 419 || mmdd == 527 || mmdd == 619 || mmdd == 704
                || mmdd == 902 || mmdd == 1128 || mmdd == 1225;
        }
        return false;
    }
}
