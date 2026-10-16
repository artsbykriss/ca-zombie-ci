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
    /// @param forceTradingDay True to treat the day as a regular trading day, skipping the full-day
    ///        weekend and closure rules (calendar correction path). The Friday-close -> weekend
    ///        transition still applies: forcing a Friday open runs its session, not its weekend.
    function classify(uint256 day, uint256 sec, uint256 openS, uint256 closeS, bool closedDay, bool forceTradingDay)
        internal
        pure
        returns (Session)
    {
        uint256 dow = dayOfWeek(day);
        // The weekend begins at Friday's close regardless of a force-open correction: forcing a
        // Friday to trade runs its SESSION, it does not delete the weekend that follows. Keeping
        // this rule outside the `forceTradingDay` skip is what stops a corrected Friday's
        // post-close hours pricing as OVERNIGHT instead of the weekend CLOSED tier.
        // ACCEPTED RESIDUAL, keyed on Friday rather than on "the next ET day has no session".
        //
        // Forcing a SATURDAY or SUNDAY to trade therefore runs its session and then prices its
        // post-close hours at the OVERNIGHT tier, not the CLOSED one. The owner accepted this
        // deliberately in round 13, to keep the calendar levers as flexible as possible: it is a fee
        // tier on a day the market is shut, it needs a CONFIG_DELAY-gated CALENDAR_OPS action, it
        // moves no funds, and it never touches an OPEN-session second. On a pool where
        // `closedFloor > overnightFloor` — live GLD today, 6000 vs 3000 — the direction is an
        // UNDERCHARGE.
        //
        // AND THE DESCRIPTION HAS ONE EXCEPTION, measured rather than assumed. `CalendarLib._ctx`
        // derives the DST offset from the UTC civil date, so the offset flips at UTC midnight of the
        // switch Sunday = 19:00 EST / 20:00 EDT on the SATURDAY before. That +/-1h CROSSES Sat/Sun
        // midnight, so for one hour per switch a second is attributed to the ADJACENT DAY and takes
        // that day's tier AND its override bits: in March a real Saturday 23:00-24:00 reads as
        // Sunday, in November a real Sunday 00:00-01:00 reads as the force-open Saturday. Measured
        // on the live GLD shape, the November instance prices an ordinary un-forced Sunday hour at
        // 3000 where 6000 is correct. Twice a year, at a publicly computable timestamp, never inside
        // a session, no funds. Only reachable because force-open weekends are supported.
        //
        // IF THIS IS EVER CONSTRAINED, the honest predicate is "the next ET day has no session", not
        // `dow == 6` — that leaves Sunday. And the DST half does NOT live here: by the time
        // `classify` runs the DAY is already wrong. It would need `_ctx`'s AUTO rule made
        // instant-granular (switching at the real 02:00-local instant) rather than day-granular.
        //
        // ONE COUPLING WORTH WRITING DOWN, because nothing else in this file states it. In the
        // NOVEMBER case the closing ramp IS actually evaluated: `CalendarLib.feeFloorAt` gates on
        // `closeFloor != 0 && sec >= openSec && !_dayFullyClosed(day)`, and in that hour the computed
        // second is 23:xx (>= openSec) and the computed day is the FORCE_OPEN Saturday, which
        // `_dayFullyClosed` reports as NOT closed. Both conjuncts hold. It returns 0 only because the
        // hold cannot reach that far:
        //     latest reachable end of the hold  = CLOSE_SEC + MAX_SESSION_SHIFT + MAX_DESCENT_WINDOW
        //                                       = 81000
        //     earliest crossing second (23:00)  = 82800
        //     margin                            = 1800 seconds — THIRTY MINUTES
        // Raising either bound by more than 30 minutes puts a DST-misread hour inside the
        // closing-auction hold, pricing it at `closeFloor` on a day that had no auction. The three
        // constants live in three DIFFERENT FILES and none of them mentions the others, let alone
        // this. Note also that `MAX_DESCENT_WINDOW` is NAMED for the opening descent but bounds
        // `closeAfter` here, which is why raising it for one purpose silently spends the margin of
        // the other.
        //
        // "By more than 30 minutes" is exact, not approximate: the hold's own test is
        // `sec < closeSec + closeAfter`, so at a margin of exactly +1800 the hold ends at 82800 and
        // the crossing second is still OUTSIDE it; at +1801 it is inside.
        //
        // THE 30-MINUTE MARGIN IS NOVEMBER'S ALONE. Do not carry the figure across: March has two
        // independent lines and neither is this one. Its FIRST is `sec >= openSec` — the crossing
        // seconds there are 0-3599 and the lowest legal `openSec` is 32400, so breaching it needs
        // a session shift of 30601 s (8h30m01s), seventeen times what November needs. Its SECOND is
        // `_dayFullyClosed`, which returns true on the plain SUNDAY the March case computes, so the
        // ramp gate's third conjunct fails regardless of any session-hour raise.
        if (dow == 5 && sec >= closeS) return Session.CLOSED; // Friday after close -> weekend
        if (!forceTradingDay) {
            if (dow == 0 || dow == 6) return Session.CLOSED; // Sunday / Saturday
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
    function closeRampFloor(FloorConfig memory cfg, uint256 sec, uint256 openS, uint256 closeS)
        internal
        pure
        returns (uint256)
    {
        if (cfg.closeFloor == 0) return 0;

        // ramp in: [closeS - window, closeS] — CLOSED at the bell, and that is the load-bearing
        // bound. `window` is `closeBefore` CLAMPED to how much of the ET day actually precedes it.
        //
        // The interval used to be half-open, and the hold below is `[closeS, closeS + closeAfter)`.
        // With `closeAfter == 0` — a ramp-only config `setPoolConfig` accepts, since it rejects
        // only BOTH windows being zero — the hold is EMPTY, so the bell second itself matched
        // neither branch and fell through to the weekday post-close floor. Measured on the shipped
        // NVDA curve with `closeAfter` forced to 0: 15:59:59 -> 1499, 16:00:00 -> 400. A 73.3% drop
        // at the single most adversely-selected instant of the day, at a publicly computable UTC
        // timestamp anyone can target — deeper than `MAX_POKE_DISCOUNT_BPS` lets the HOT key go.
        //
        // Closing the interval also fixes the second, quieter half: `(sec - rampStart) == window`
        // at the bell, so the ramp now returns `openFloor + rise` EXACTLY, which is `closeFloor`.
        // Before, the ramp topped out one step short (700 + 800*1799/1800 = 1499 against a
        // configured 1500), so a ramp-only pool advertised a peak via `floorConfig()` that it could
        // never charge at any second — the "reads as configured, acts as off" third state this
        // validator rejects in three other places.
        //
        // THIS CHANGES A LIVE POOL'S PRICE AT THE BELL, and an earlier version of this comment said
        // the opposite. It claimed the shipped config was unchanged because `closeAfter = 900` — the
        // value in `script/phase1/P1_02_ConfigurePools.s.sol`. That is not what is on chain. Read
        // from mainnet, NVDA hook 0x66622f77...6080:
        //
        //     floorConfig = (1000, 800, 300, 5, 4000, 7200, 2200, 1800, 0)
        //                                                              ^^^ closeAfter IS ZERO
        //
        // So the ramp-only shape is not a hypothetical this fix guards against — it is the
        // production configuration of the only live pool that has a closing ramp at all, and the
        // bell second was genuinely unpriced there. At `sec == closeS` on that config:
        //
        //     Mon-Thu   800 (overnightFloor) -> 2200 (closeFloor)
        //     Friday    300 (closedFloor)    -> 2200
        //
        // That is the fix working — 16:00:00 is the closing auction and 2200 is what the pool
        // configured for it — but it is a REPRICING of a live market, not a no-op, and it must be
        // reviewed as one before this ships. The 1499/400 figures below are the P1_02 curve and are
        // kept because they are what the finding was measured on; they are not the live numbers.
        //
        // Rejecting `closeAfter == 0` in `setPoolConfig` is the alternative, and it is a PRICING
        // decision rather than a correctness one, so it is left to whoever sets the config.
        //
        // What can be said factually: with `closeAfter == 0` the hold `[closeS, closeS + 0)` is
        // EMPTY, so the ramp's peak is attained at exactly one second out of the day and the fee
        // falls to the overnight (Mon–Thu) or closed (Friday) tier at `closeS + 1`. On the live
        // NVDA config that is 2200 -> 800 and 2200 -> 300, drops of 6364 and 8636 bps, deeper than
        // `MAX_POKE_DISCOUNT_BPS` bounds the hot key's lever — and reachable by waiting one second
        // at a publicly computable timestamp.
        //
        // An earlier version of this comment called that shape "a coherent policy a live pool is
        // already running". The second half is true and the first is unsupported: measured across
        // the slate, EVERY shipped script that sets `closeFloor != 0` also sets `closeAfter != 0`
        // (P1_02 NVDA 900, W2_02 TSLA 900, 02_ConfigureRWAPool 3600), and every config with
        // `closeAfter == 0` has `closeFloor == 0`, i.e. no ramp at all. NVDA is the only live pool
        // with the combination and it acquired it through a hand `setPoolConfig`, not a script. So
        // it reads as a configuration slip that this comment then enshrined as intent — which is
        // the shape the repo's own rule about stale comments exists to catch.
        //
        // The guard used to be `closeS >= cfg.closeBefore`, which silently deleted the entire
        // ramp-in when it did not hold. Nothing couples the two values: `closeBefore` is bounded
        // by `FablesRWA.setPoolConfig` against a constant, while `closeS` comes from
        // `MarketCalendar.setSessionHours` (a different setter, a different role) and can be
        // shortened again at read time by `setEarlyClose`. So two individually-valid admin calls
        // could leave a pool advertising a closing ramp via `floorConfig()` while only the
        // `closeAfter` hold ever fired — the "reads as configured, acts as off" third state that
        // `setPoolConfig`'s own validator rejects in three other places. Clamping instead of
        // skipping keeps the ramp's endpoints intact (it still starts at `openFloor` and reaches
        // `closeFloor` exactly at the bell), just over a shorter approach, and it moves in the
        // safe direction: a compressed ramp charges MORE than the deleted one, never less. This is
        // the same "re-check the coupling at the point of use" that `CalendarLib._classify`
        // already applies to `MIN_EARLY_CLOSE_LENGTH` against a stale `earlyClose`. (Named
        // precisely: there is no `MIN_SESSION_LENGTH` re-check at the point of use, and this line
        // used to send a reader looking for a guard that does not exist.)
        if (cfg.closeBefore != 0 && closeS > openS) {
            // Clamped to the SESSION, not merely to the day. Clamping to `closeS` alone left the
            // case `closeBefore > closeS - openS`: `rampStart` is then positive but earlier than
            // the open, so the bell prices partway up the auction ramp instead of at `openFloor`
            // — measured 1508 pips against an `openFloor` of 800 with a half-day close and a 6h
            // `closeBefore`. `feeFloorAt`'s own `sec >= openSec` gate keeps pre-open hours off the
            // ramp, so the direction is safe (it over-charges) — but the margin has to be computed
            // from the constants that actually hold, and an earlier version of this argument used
            // two that do not.
            //
            // RECOMPUTED. `closeBefore` is 1800 on the live NVDA pool and in `P1_02` (the 3600
            // figure belongs to the superseded `02_ConfigureRWAPool`), and `setEarlyClose` enforces
            // `MIN_EARLY_CLOSE_LENGTH = 3 hours`, which dominates the one-hour bound that argument
            // rested on. The shortest legal early close therefore leaves `rampStart` at
            // `openSec + 9000` — a margin of 9000 seconds, not the zero it claimed.
            //
            // The clamp is still correct and still load-bearing: `closeBefore` is bounded only by
            // `MAX_DESCENT_WINDOW` (6h), so raising it past 3h would consume that margin silently.
            // Clamping to the session length removes the class rather than relying on a margin two
            // superseded constants happened to provide.
            uint256 session = closeS - openS;
            uint256 window = session < cfg.closeBefore ? session : cfg.closeBefore;
            uint256 rampStart = closeS - window;
            if (sec >= rampStart && sec <= closeS) {
                // GUARDED AT RUNTIME, not merely by config, exactly as `floorFor`'s mirror
                // (`if (spike <= cfg.openFloor) return cfg.openFloor;`) is. `setPoolConfig` does
                // enforce `closeFloor >= openFloor`, but `MarketCalendar.feeFloorAt` is PUBLIC and
                // takes a CALLER-SUPPLIED `FloorConfig`, so on that path the invariant is an
                // assumption about a stranger's argument and the subtraction panics 0x11 instead of
                // returning by name.
                //
                // Provably a no-op on every configured pool: `setPoolConfig` already refuses
                // `closeFloor < openFloor`, and at equality `rise` is 0 and the ramp returns
                // `openFloor` anyway. So this refuses nothing legitimate and only stops a public
                // view from being a panic oracle.
                // PLACEMENT IS LOAD-BEARING — do not hoist this to the top of the function.
                // Inside the window test it can only replace the ramp expression, and at
                // `closeFloor == openFloor` that expression already yields `openFloor`, which is
                // what makes it a no-op. ABOVE the window test it is NOT one: outside the ramp this
                // function returns 0, and `CalendarLib.feeFloorAt` does `if (ramp > floor) floor =
                // ramp` — so a hoisted guard returning `openFloor` would lift every OVERNIGHT and
                // CLOSED second at or after `openSec` to `openFloor` on any pool configured with
                // `closeFloor == openFloor`, which `setPoolConfig` permits.
                if (cfg.closeFloor <= cfg.openFloor) return cfg.openFloor;
                uint256 rise = uint256(cfg.closeFloor) - cfg.openFloor;
                return cfg.openFloor + (rise * (sec - rampStart)) / window;
            }
        }

        // hold: [closeS, closeS + closeAfter). `sec` is always < SECONDS_PER_DAY, so this never
        // spills into the next ET day even if closeS + closeAfter would exceed it. `closeS` itself
        // is now taken by the ramp above whenever a ramp exists, at the same value — this branch
        // owns the bell only when `closeBefore == 0`, where there is no ramp to own it.
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
