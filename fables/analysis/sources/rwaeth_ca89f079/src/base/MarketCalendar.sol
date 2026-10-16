// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {PoolId} from "v4-core/src/types/PoolId.sol";
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
    error TooManyDayOverrides(uint256 marks);

    /// @notice Per-day correction state. NONE follows the baked calendar.
    enum DayOverride {
        NONE,
        FORCE_CLOSED,
        FORCE_OPEN
    }

    event DayOverridesSet(PoolId indexed poolId, uint256 indexed yearMonth, uint64 packed);
    event SessionHoursSet(PoolId indexed poolId, uint32 openSec, uint32 closeSec);
    event DstModeSet(PoolId indexed poolId, SessionLib.DstMode mode);
    event EarlyCloseSet(PoolId indexed poolId, uint256 y, uint256 m, uint256 d, uint32 closeSec);

    /// @dev `closeSec_` is bounded STRICTLY below a day. `SessionLib.classify` closes Friday
    ///      evening with `sec >= closeS`, and `sec` is `et % SECONDS_PER_DAY`, so a close of
    ///      exactly 86400 made that predicate unsatisfiable and the rule dead code — Friday
    ///      afternoon through midnight would have priced at the OPEN floor across the whole
    ///      weekend gap, with Saturday and Sunday still reading CLOSED so nothing looked wrong.
    ///      `MAX_SESSION_LENGTH` does not catch it: it bounds the session's length, not where in
    ///      the day it sits.
    error InvalidSessionHours();
    /// @notice A pinned DST mode that contradicts the rule in force at the moment of the call.
    error DstModeDisagreesWithClock();

    /// @notice One pool's trading calendar.
    /// @dev Keyed by pool because a singleton serves many pools and they do not share a clock: an
    ///      index product and a newly listed single name want different session pricing, and two
    ///      venues want different hours outright. A pool that has never been configured reads the
    ///      defaults below, so adding a pool changes nothing until its calendar is set on purpose.
    struct PoolCalendar {
        /// @dev How UTC is converted to ET. The zero value is AUTO, the current US statutory rule,
        ///      which is exactly the default an unconfigured pool should get.
        SessionLib.DstMode dstMode;
        /// @dev Session open/close as ET second-of-day. Zero `openSec` means "never set", which is
        ///      unambiguous: `setSessionHours` rejects a zero open.
        uint32 openSec;
        uint32 closeSec;
        /// @dev yearMonth = year * 100 + month; 2 bits per day at offset (d - 1) * 2:
        ///      bit0 = force closed, bit1 = force open (closed wins if both are set).
        mapping(uint256 yearMonth => uint64 packed) dayOverrides;
        /// @dev yearMonthDay = y * 10000 + m * 100 + d, to an ET second-of-day close. Zero means
        ///      no early close. The bitmap above can only make a day fully closed; a half day is a
        ///      SHORTER session, which no arrangement of those two bits can express.
        mapping(uint256 yearMonthDay => uint32 closeSec) earlyClose;
    }

    mapping(PoolId poolId => PoolCalendar calendar) private _calendars;

    /// @notice This pool's DST mode.
    function dstMode(PoolId poolId) public view returns (SessionLib.DstMode) {
        return _calendars[poolId].dstMode;
    }

    /// @notice This pool's session open, as ET second-of-day.
    function openSec(PoolId poolId) public view returns (uint32) {
        uint32 o = _calendars[poolId].openSec;
        return o == 0 ? uint32(SessionLib.OPEN_SEC) : o;
    }

    /// @notice This pool's session close, as ET second-of-day.
    /// @dev THE SENTINEL IS `openSec`, NOT `closeSec` — read deliberately, and it only works because
    ///      `setSessionHours` is the sole writer of both and refuses `openSec_ == 0`. So "no
    ///      calendar configured" is expressible as `openSec == 0` alone, and a pool that legitimately
    ///      closes at second 0 is not misread as unconfigured.
    ///
    ///      The coupling is stated here because it is invisible at the call site: `openSec()` reads
    ///      its own slot for the sentinel and this reads a different one, so a future setter that
    ///      wrote `closeSec` alone would be silently ignored on any pool whose `openSec` was never
    ///      set.
    function closeSec(PoolId poolId) public view returns (uint32) {
        uint32 o = _calendars[poolId].openSec;
        return o == 0 ? uint32(SessionLib.CLOSE_SEC) : _calendars[poolId].closeSec;
    }

    /// @notice This pool's early close for one ET civil date, or zero when it is a full day.
    function earlyClose(PoolId poolId, uint256 y, uint256 m, uint256 d) external view returns (uint32) {
        return _calendars[poolId].earlyClose[y * 10000 + m * 100 + d];
    }

    /// @notice Reverts unless the caller may administer the calendar.
    function _checkCalendarAdmin() internal virtual;

    /// @notice Reverts unless `poolId` is a pool this hook actually serves.
    /// @dev These setters took no target at all while the calendar was hook-wide. Now that they
    ///      name a pool, a mistyped 32-byte id would write to an unreachable entry, emit an event
    ///      naming a pool that does not exist, and leave the intended pool on its old calendar —
    ///      a silent no-op on exactly the lever whose job is to reprice a known-toxic window.
    function _checkCalendarPool(PoolId poolId) internal view virtual;

    /// @notice Largest number of days in one month this calendar will override, in EITHER direction.
    /// @dev A real exchange calendar has a handful of holidays a month; the record is three, and
    ///      forced OPENINGS are rarer still. Ten is far above any legitimate month and far below
    ///      "the bitmap was packed wrong". The bound exists because this setter is hand-fed a
    ///      bit-packed integer, which is the one input shape where a transposed nibble is invisible
    ///      on review and catastrophic in effect.
    /// @dev Counts BOTH bits. An earlier version bounded only the FORCE_CLOSED direction, on the
    ///      reasoning that forcing a day open can only ever RAISE its own fee (closedFloor ->
    ///      overnight/open). That reasoning missed the neighbour: `CalendarLib.feeFloorAt` derives
    ///      `fromClosed` from `_dayFullyClosed(day - 1)`, and `_dayFullyClosed` reads FORCE_OPEN as
    ///      "not closed" — so a bit on day D-1 swaps day D's opening descent from the absolute
    ///      `closedSpike` down to `overnightFloor * spikeMult`. On the shipped RWA config that is
    ///      3500 -> 3000 pips at the Monday bell, i.e. the FORCE_OPEN half of the same word is a
    ///      downward lever on a window neither `pokeFloor` nor any configured floor can see. A
    ///      one-sided bound on a two-sided word is the bug; the direction that happens to be cheap
    ///      today is a property of the current numbers, not of the check.
    uint256 public constant MAX_DAY_OVERRIDES = 10;

    /// @notice Sets the per-day override bitmap for one month, replacing the previous one.
    /// @dev VALIDATED, unlike every earlier version of this function — it was the only calendar
    ///      setter with no checks at all, and it is the one with the deepest downward authority over
    ///      the fee. One bit takes a real trading day to `closedFloor`: measured on the shipped RWA
    ///      config, 3500 -> 200 at the post-holiday open (95%), 2500 -> 200 at the closing ramp
    ///
    ///      EVERY PIP FIGURE IN THIS FILE IS FROM `script/phase1/P1_02_ConfigurePools.s.sol`
    ///      (`{700, 400, 300, 8, 3200, 7200, 1500, 1800, 900}`), NOT from chain. The live NVDA pool
    ///      was reconfigured on 2026-08-28 and now reads
    ///      `{1000, 800, 300, 5, 4000, 7200, 2200, 1800, 0}` — so the post-weekend open is
    ///      4000 -> 800 rather than 3200 -> 400, and the closing ramp peaks at 2200 rather than
    ///      1500. The RATIOS these comments reason about survive (every cut quoted is still far
    ///      past `MAX_POKE_DISCOUNT_BPS`) and every conclusion stands; the absolute numbers are the
    ///      calibration they were measured on, kept because they are what the findings were
    ///      demonstrated against. Do not quote them as "the shipped config".
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
    ///        - more overridden days, in either direction, than any exchange calendar has, which is
    ///          the signature of a shifted or inverted mask rather than a holiday list.
    ///      None of them constrains a legitimate calendar. All of them turn a silent, delayed,
    ///      pool-wide fee collapse into a reverted transaction.
    function setDayOverrides(PoolId poolId, uint256 yearMonth, uint64 packed) external {
        _checkCalendarAdmin();
        _checkCalendarPool(poolId);
        // The KEY, not just the bitmap. `setEarlyClose` validates its civil date; this setter wrote
        // under whatever `yearMonth` it was handed, so a mistyped month landed in a slot the reader
        // can never produce (`_overrideBits` only ever reads `y * 100 + m` with m in 1..12) — the
        // correction silently did nothing while emitting a success event, on the deepest downward
        // fee lever in the hook.
        uint256 month = yearMonth % 100;
        if (month == 0 || month > 12 || yearMonth / 100 < 1970) revert InvalidDayOverride();
        // Day 32 does not exist in any month; its bits can only be a packing mistake.
        if (packed & (uint64(3) << 62) != 0) revert InvalidDayOverride();
        uint256 marks = 0;
        for (uint256 d = 0; d < 31; d++) {
            uint64 bits = (packed >> (d * 2)) & 3;
            if (bits == 3) revert InvalidDayOverride(); // force-closed AND force-open
            if (bits != 0) {
                // THE DAY, not just the month. The bounds above validate `yearMonth` and the mask
                // above rejects day 32, but nothing asked whether the marked day EXISTS in this
                // month — so `setDayOverrides(poolId, 202602, 1 << 58)` (February 30th) passed every
                // check, was stored, and emitted `DayOverridesSet`, while `CalendarLib._overrideBits`
                // can never read that day index in February. A silent no-op with a success receipt,
                // on what this file calls the deepest downward fee lever in the hook.
                //
                // This is the identical check `setEarlyClose` spends nine lines justifying for its
                // own single date, and it refuses nothing legitimate: every real exchange closure
                // names a real calendar date.
                (uint256 ry, uint256 rm, uint256 rd) =
                    SessionLib.civilFromDay(SessionLib.dayFromCivil(yearMonth / 100, month, d + 1));
                if (ry != yearMonth / 100 || rm != month || rd != d + 1) revert InvalidDayOverride();
                marks++; // BOTH directions — see MAX_DAY_OVERRIDES
            }
        }
        if (marks > MAX_DAY_OVERRIDES) revert TooManyDayOverrides(marks);
        _calendars[poolId].dayOverrides[yearMonth] = packed;
        emit DayOverridesSet(poolId, yearMonth, packed);
    }

    /// @notice Shortest trading session the calendar will accept, fixed in bytecode.
    /// @dev A floor as well as a ceiling. `MAX_SESSION_LENGTH` closed the lengthening direction —
    ///      a day-long session made every weekday second read OPEN — but said nothing about the
    ///      other one. `setSessionHours(34200, 34201)` passed every check and made the OPEN
    ///      session one second per day, which deletes `SessionLib.floorFor`'s entire opening
    ///      descent: the highest-priced window in the hook, and the one that prices the weekend
    ///      and holiday gaps, simply stops existing. Measured at 60s into a Monday open following
    ///      a weekend: 58033 pips before, 3000 after. The spike a post-weekend open descends from is
    ///      the absolute `closedSpike` (`SessionLib.floorFor`'s `fromClosed` branch), not
    ///      `prior * spikeMult` as this line used to say — that was the pre-`closedSpike` shape. The
    ///      conclusion is unchanged and is what matters: `closedSpike` is likewise not one of the
    ///      three configured floors `pokeFloor` minimises over, so the poke floor cannot detect its
    ///      absence either.
    /// @dev DOMINATED by `MAX_SESSION_SHIFT`, which pins the session to [5.5h, 7.5h] — so this
    ///      bound is currently unreachable. Kept because it is the bound that becomes load-bearing
    ///      again the moment `MAX_SESSION_SHIFT` is widened; see the note there before deleting it
    ///      as dead. The warrant recorded below describes a call that now reverts on the CLOSE
    ///      drift first.
    uint32 public constant MIN_SESSION_LENGTH = 1 hours;

    /// @notice Longest trading session the calendar will accept, fixed in bytecode. NYSE runs
    ///         6.5h; 12h leaves room for any plausible venue without allowing a 24h "session".
    /// @dev Also DOMINATED by `MAX_SESSION_SHIFT` (see `MIN_SESSION_LENGTH`). "12h leaves room for
    ///      any plausible venue" implies a 12-hour session is configurable; it is not, and no venue
    ///      whose hours differ from 09:30-16:00 ET by more than half an hour can be expressed at
    ///      all. `PoolCalendar`'s NatSpec justifies the per-pool calendar with "two venues want
    ///      different hours outright", which is the same setter described in the opposite terms —
    ///      the per-pool calendar today buys per-pool HOLIDAYS and half-days, not venue hours.
    uint32 public constant MAX_SESSION_LENGTH = 12 hours;

    /// @notice How far the session's OPEN may be moved from the default 09:30 ET bell.
    /// @dev The third bound this setter needed, and the one that was missing while the other two
    ///      were being added. Length was bounded in both directions — a day-long session made
    ///      every second read OPEN, a one-second session deleted the opening descent — but POSITION
    ///      was bounded only by `closeSec_ < SECONDS_PER_DAY`. That is not a bound on anything a
    ///      fee depends on: `setSessionHours(3600, 7200)` passes every length check (exactly
    ///      `MIN_SESSION_LENGTH`) and relocates the entire priced session to 01:00-02:00 ET, at
    ///      which point every real trading second classifies OVERNIGHT.
    ///
    ///      On the shipped NVDA config {openFloor 700, overnightFloor 400, spikeMult 8,
    ///      closedSpike 3200, descentWindow 7200, closeFloor 1500} that is 3200 -> 400 pips at the
    ///      Monday bell (87.5% off the most adversely-selected minute of the week), 700 -> 400 for
    ///      every regular-hours second, and the closing ramp never fires at all. `pokeFloor` is
    ///      structurally blind to it because `setPoolConfig` sets that floor to the MINIMUM of the
    ///      three tiers (300 here) and the attack lands on 400.
    ///
    ///      It also inverted the role hierarchy. `pokeFee` — the system's designated HOT key — is
    ///      capped at `MAX_POKE_DISCOUNT_BPS` (50%) re-derived at RESOLUTION and expires within
    ///      `MAX_POKE_TTL`. This delayed key could cut deeper, everywhere, permanently, which is
    ///      exactly the premise `setSessionHours`'s own comment claims the length bound
    ///      establishes: "its worst case is 'flipping a day between two configured fee floors'".
    ///      Only a position bound makes that sentence true.
    ///
    ///      ONE HOUR, bounded by the EVENTS it protects rather than by an existing fixture. The
    ///      first cut of this constant was 4 hours, reverse-engineered from four test sites
    ///      annotating a 13:00 ET open as "inside MAX_SESSION_SHIFT". That is wider than the thing
    ///      it guards: the opening descent is `descentWindow` (2h on the shipped curve) and the
    ///      closing ramp is `closeBefore + closeAfter` (45 min), so a 4h relocation moves BOTH
    ///      priced windows entirely clear of the bells they exist to price — reproducing, through
    ///      this setter, the same collapse the early-close floor had just removed. Measured on the
    ///      shipped NVDA curve at `setSessionHours(P, 19800, 43200)`: the post-weekend bell goes
    ///      3200 -> 700 and the 16:00 auction 1500 -> 400, the latter again a deeper cut than
    ///      `MAX_POKE_DISCOUNT_BPS` permits the system's HOT key.
    ///
    ///      THIRTY MINUTES, sized to the narrowest window rather than the widest. The closing band
    ///      is `closeBefore + closeAfter` = 45 min on the shipped curve, so any shift at or above
    ///      that width slides the real 16:00 auction entirely out of the band that prices it — 1h
    ///      was still enough, and 4h was enough twice over. At 30 min the real bell stays inside
    ///      `[closeSec_ - closeBefore, closeSec_ + closeAfter]` for a late shift and the opening
    ///      descent (2h) always still contains the real 09:30.
    ///
    ///      Every pool in the slate runs the default 09:30/16:00 hours, and a genuine half day is
    ///      `setEarlyClose`'s job, not a reason to move `closeSec` — so this costs no configuration
    ///      the protocol actually uses while leaving room for a statutory DST-adjacent correction.
    uint32 public constant MAX_SESSION_SHIFT = 30 minutes;

    /// @notice Shortest session a per-day early close may leave.
    /// @dev The `earlyClose` overlay writes `effClose` directly into `CalendarLib._classify`, so it
    ///      answers to neither `setSessionHours` bound. Reusing `MIN_SESSION_LENGTH` (1h) there let
    ///      the whole afternoon and the closing auction be collapsed onto `overnightFloor` one date
    ///      at a time, with no per-month count bound of the kind `MAX_DAY_OVERRIDES` puts on the
    ///      sibling lever. The two real US half days are 3.5h.
    /// @dev ABSOLUTE rather than relative, and that is safe only because `MAX_SESSION_SHIFT` is
    ///      tight. An absolute floor on a quantity that is really relative to the pool's own hours
    ///      was a genuine hazard while the shift was 4 hours: a legally-configured 4h venue could
    ///      express at most one hour of shortening, and a pool whose open had moved to 11:30 could
    ///      not express the real 13:00 half day at all — the one configuration this setter exists
    ///      for. Both shapes are unreachable now. With both anchors pinned to +/-30 min the open
    ///      lies in [09:00, 10:00] and the close in [15:30, 16:30], so the SHORTEST reachable
    ///      session is 5.5h and the real 13:00 half day clears this floor from the latest legal
    ///      open at exactly 3h. A relative bound would buy nothing and cost a coupling.
    uint32 public constant MIN_EARLY_CLOSE_LENGTH = 3 hours;

    /// @dev Distance between a configured anchor and where the real market clock puts it.
    function _drift(uint256 value, uint256 anchor) private pure returns (uint256) {
        return value > anchor ? value - anchor : anchor - value;
    }

    /// @notice Moves the session hours (ET seconds-of-day).
    function setSessionHours(PoolId poolId, uint32 openSec_, uint32 closeSec_) external {
        _checkCalendarAdmin();
        _checkCalendarPool(poolId);
        // The session's LENGTH is the sole input deciding OPEN vs OVERNIGHT, and nothing bounded
        // it. `setSessionHours(1, 86400)` made every weekday second read OPEN, and combined with
        // FORCE_OPEN day overrides it collapsed all three fee tiers onto the cheapest one for the
        // whole week — a 6x subsidy handed to exactly the gap arbitrage the closed tier prices.
        // `pokeFloor` cannot detect that, because `setPoolConfig` sets it to the MINIMUM of the
        // three tiers. This role is deliberately separated from the fund-moving one on the
        // premise that its worst case is "flipping a day between two configured fee floors";
        // this bound is what makes that premise true.
        // POSITION, then length. The length bounds below say how long the session is; this one
        // says where it sits, and without it the two above bound nothing a fee depends on — a
        // session of exactly `MIN_SESSION_LENGTH` parked at 01:00 ET passes both and makes every
        // real trading second read OVERNIGHT. See `MAX_SESSION_SHIFT`.
        //
        // BOTH ANCHORS, not just the open. The fee surface keys off each end separately:
        // `SessionLib.floorFor` measures the opening descent from `openSec`, and
        // `closeRampFloor` centres the closing ramp on `closeSec`. Bounding only the open left the
        // identical attack reachable from the other end — `setSessionHours(id, 34200, 37800)` moves
        // nothing (drift 0) and still pulls the close 5.5 hours early, so the whole real afternoon
        // reads OVERNIGHT and the 16:00 auction prices at the overnight tier. "Bounding the open
        // and the length bounds the close" is false, because the length band is 1h-12h while the
        // real session is 6.5h: the slack is the attack.
        //
        // THE BOUND IS SYMMETRIC AND BOTH WINDOWS IT PROTECTS ARE NOT. This is a known,
        // deliberately-unclosed gap, recorded here with its measured cost so nobody rediscovers it
        // as a surprise. The opening descent runs `[openSec, openSec + descentWindow)` — forward
        // only, no backward reach — so ANY late shift of the open, down to one second, moves the
        // real 09:30 bell out of the descent and into OVERNIGHT. The closing band is
        // `[closeSec - closeBefore, closeSec + closeAfter)`, so an early shift is covered only out
        // to `closeAfter`, which on the shipped curve is half what this bound permits.
        //
        // Measured on the shipped NVDA curve, all inside `MAX_SESSION_SHIFT`:
        //     open  +1s     the 09:30 post-weekend bell  3200 -> 400   8750 bps
        //     close -900s   the 16:00 auction            1500 -> 400   7333 bps
        //     close +1800s  the 16:00 auction            1500 -> 700   5333 bps
        // Each exceeds `MAX_POKE_DISCOUNT_BPS` (5000) — the yardstick this file uses to justify
        // this very bound.
        //
        // AND THIS BOUND NOW DOMINATES BOTH LENGTH BOUNDS, which matters to whoever widens it.
        // Pinning both anchors to +/-30 min of the fixed NYSE constants pins `openSec_` to
        // [32400, 36000] and `closeSec_` to [55800, 59400], so the session length is confined to
        // [5.5h, 7.5h] — `MIN_SESSION_LENGTH` (1h) and `MAX_SESSION_LENGTH` (12h) are both
        // unreachable, i.e. dead, while their own NatSpec still presents them as the live defence.
        // In fact the WHOLE second `require` block is unreachable, not just the two length checks:
        // `openSec_ == 0`, `openSec_ >= closeSec_` and `closeSec_ >= SECONDS_PER_DAY` are all
        // excluded by the same anchoring.
        // `MIN_SESSION_LENGTH`'s stated warrant, `setSessionHours(34200, 34201)`, now reverts on the
        // CLOSE drift long before either length check runs. Widening `MAX_SESSION_SHIFT` — which is
        // this setter's own stated escape hatch — therefore re-arms the collapse those constants
        // were introduced for, and a maintainer reading their NatSpec would believe otherwise.
        //
        // NOT closed here, and the reason is scope rather than doubt. The correct bound is
        // DIRECTIONAL and per-pool:
        //     `openSec_ <= OPEN_SEC` AND `OPEN_SEC - openSec_ < descentWindow`
        //     `CLOSE_SEC - closeSec_ < closeAfter`, `closeSec_ - CLOSE_SEC <= closeBefore`
        //
        // THE FIRST CONJUNCT IS THE CORRECTION. This prescription used to give the open half as
        // `OPEN_SEC - openSec_ < descentWindow` alone, which closes the WRONG DIRECTION: the hazard
        // named two paragraphs up is a LATE open ("ANY late shift of the open, down to one second,
        // moves the real 09:30 bell out of the descent and into OVERNIGHT"), and for
        // `openSec_ > OPEN_SEC` that subtraction underflows to ~2^256, so the guard is vacuously
        // true exactly where it is needed and only ever constrains the early side. Whoever
        // implements this must carry both terms.
        //
        // One more note for that round: the repo's own recorded mainnet read gives the live NVDA
        // config as `closeAfter == 0`, so `CLOSE_SEC - closeSec_ < closeAfter` forbids ANY early
        // close shift on that pool. That is arithmetically correct and should not be softened as
        // over-restrictive.
        //
        // The directional bound needs the floor config this contract does not own — it lives in `FablesRWA`. That is a
        // behavioural change to an audited contract behind a new virtual, on a lever held by a
        // DELAYED role, so it belongs in its own round through the fix protocol rather than riding
        // along. What makes the exposure tolerable meanwhile: `CALENDAR_OPS` carries
        // `CONFIG_DELAY`, so a bad pairing is observable before it binds.
        if (_drift(openSec_, SessionLib.OPEN_SEC) > MAX_SESSION_SHIFT) revert InvalidSessionHours();
        if (_drift(closeSec_, SessionLib.CLOSE_SEC) > MAX_SESSION_SHIFT) revert InvalidSessionHours();
        if (
            openSec_ == 0 || openSec_ >= closeSec_ || closeSec_ >= SessionLib.SECONDS_PER_DAY
                || closeSec_ - openSec_ > MAX_SESSION_LENGTH || closeSec_ - openSec_ < MIN_SESSION_LENGTH
        ) {
            revert InvalidSessionHours();
        }
        _calendars[poolId].openSec = openSec_;
        _calendars[poolId].closeSec = closeSec_;
        emit SessionHoursSet(poolId, openSec_, closeSec_);
    }

    /// @notice Sets the DST handling mode.
    /// @dev BOUNDED BY OUTCOME, like every other lever on this role. A pinned mode is a ±1h shift of
    ///      the entire ET clock: `CalendarLib._ctx` subtracts `EST_OFFSET` or `EDT_OFFSET` before
    ///      every session and floor decision, so pinning `FIXED_EST` during EDT makes the real 09:30
    ///      bell compute as 08:30 and read OVERNIGHT. Measured on the shipped NVDA curve, that is
    ///      3200 -> 400 pips at the post-weekend open (87.5%) and 1500 -> 700 at the closing ramp —
    ///      both deeper than `MAX_POKE_DISCOUNT_BPS` permits the system's HOT key, from a setter
    ///      that validated nothing beyond the enum. It was the last unbounded calendar route once
    ///      `MAX_SESSION_SHIFT` and `MIN_EARLY_CLOSE_LENGTH` closed the other two.
    ///
    ///      The bound is agreement WITH THE CURRENT RULE AT THE MOMENT OF THE CALL, not agreement
    ///      forever — and that distinction is what keeps the escape hatch these modes exist for.
    ///      The stated purpose is a change in the US statutory rule, after which AUTO is wrong; a
    ///      "must always agree with AUTO" bound would make the hatch unusable precisely when it is
    ///      needed. Requiring agreement only at call time still admits it: pin during the season in
    ///      which the new rule already matches, and the pin persists through the season where AUTO
    ///      would have diverged. Adopting permanent EDT means pinning `FIXED_EDT` between March and
    ///      November; adopting permanent EST means pinning `FIXED_EST` between November and March.
    ///      The wait is bounded by six months and a statutory change carries far more lead time than
    ///      that, while the attack — pinning the mode that is wrong RIGHT NOW — is refused outright.
    ///
    ///      AUTO is always accepted: it is the zero value, the default an unconfigured pool reads,
    ///      and returning to it can only ever restore the real clock.
    function setDstMode(PoolId poolId, SessionLib.DstMode mode) external {
        _checkCalendarAdmin();
        _checkCalendarPool(poolId);
        if (mode != SessionLib.DstMode.AUTO) {
            (uint256 y, uint256 m, uint256 d) = SessionLib.civilFromDay(block.timestamp / SessionLib.SECONDS_PER_DAY);
            uint256 live = SessionLib.utcOffsetFromDate(y, m, d);
            uint256 pinned = mode == SessionLib.DstMode.FIXED_EST ? SessionLib.EST_OFFSET : SessionLib.EDT_OFFSET;
            if (pinned != live) revert DstModeDisagreesWithClock();
        }
        _calendars[poolId].dstMode = mode;
        emit DstModeSet(poolId, mode);
    }

    /// @notice Sets (or clears, with zero) this pool's early close for one ET civil date.
    /// @dev THE US HALF DAYS ARE NOT "THE AFTERNOONS BEFORE THANKSGIVING AND CHRISTMAS", which is
    ///      what this line used to say and is wrong in a way that costs money in BOTH directions.
    ///      The NYSE rule is:
    ///        - the day AFTER Thanksgiving (Black Friday), not the day before — the Wednesday is a
    ///          full session;
    ///        - December 24, when Christmas falls Tue-Fri (otherwise Dec 24 is the observed
    ///          closure, or a weekend);
    ///        - July 3, when July 4 falls Tue-Fri.
    ///      So "two" is wrong as well: some years have three.
    ///
    ///      An operator following the old text sets the early close on the Wednesday and BREAKS a
    ///      full trading day — measured, that day's real 16:00 auction drops from `closeFloor` to
    ///      `overnightFloor`, an 80% cut at the most adversely-selected minute — while the actual
    ///      half day stays unset and its real 13:00 auction is priced three hours late.
    ///
    ///      Unlike full closures, half days get NO baked coverage (`SessionLib.bakedClosed` handles
    ///      2026-2030 for closures only), so every one of these is a manual call, per pool:
    ///        2026-11-27, 2026-12-24
    ///        2027-11-26
    ///        2028-07-03, 2028-11-24
    ///        2029-07-03, 2029-11-23, 2029-12-24
    ///        2030-07-03, 2030-11-29, 2030-12-24
    ///
    ///      These close at
    ///      13:00 ET. The day-override bitmap cannot say that: its two bits only choose between a
    ///      full session and no session, so before this a half day had to be priced either as a
    ///      whole trading day (the closing ramp lands three hours after the actual auction) or as
    ///      a full closure (the morning session, which really does trade, priced at the closed
    ///      tier). Bounded by the same session-length rules as `setSessionHours` at the point of
    ///      use: an early close outside `(open, close]` is ignored rather than honoured, so this
    ///      overlay can only ever SHORTEN a day.
    function setEarlyClose(PoolId poolId, uint256 y, uint256 m, uint256 d, uint32 closeSec_) external {
        _checkCalendarAdmin();
        _checkCalendarPool(poolId);
        // The YEAR too, matching `setDayOverrides`. It contributes the `y * 10000` term of the key,
        // so a dropped century writes the half day to a slot the resolver can never read — the same
        // silent no-op with a success event that the sibling's check exists to prevent.
        if (y < 1970 || m == 0 || m > 12 || d == 0 || d > 31) revert InvalidDayOverride();
        // AND THE DATE MUST EXIST. `d <= 31` accepts Feb 30, Apr 31, and every other date no month
        // has — and `CalendarLib` derives its `d` from `civilFromDay`, so it can never produce one.
        // The write therefore lands on a key nothing ever reads: a SILENT NO-OP with a success
        // receipt and an `EarlyCloseSet` event, on the lever whose whole job is repricing a known
        // toxic window. An operator sets the half day, sees it emitted, and the auction prices
        // three hours late anyway. Round-tripping through the civil-date conversion is the exact
        // check, and it costs one call: this is the same class the `y >= 1970` and `m <= 12` bounds
        // on this same line already close, with the day component left short.
        (uint256 ry, uint256 rm, uint256 rd) = SessionLib.civilFromDay(SessionLib.dayFromCivil(y, m, d));
        if (ry != y || rm != m || rd != d) revert InvalidDayOverride();
        if (closeSec_ != 0) {
            uint32 o = openSec(poolId);
            // `MIN_SESSION_LENGTH` (1h) here is DOMINATED by the `MIN_EARLY_CLOSE_LENGTH` (3h) check
            // below and can never fire on its own. Kept only so this bound reads the same as
            // `setSessionHours`'s — and named as the dominated one because the hazard is
            // directional: a reader trimming the apparent duplicate is far likelier to delete the
            // LATER 3h bound, which is the load-bearing one. That would restore the collapse the 3h
            // constant was raised to close (measured: 1500 -> 400 pips on the real 16:00 auction).
            if (closeSec_ <= o || closeSec_ > closeSec(poolId) || closeSec_ - o < MIN_SESSION_LENGTH) {
                revert InvalidSessionHours();
            }
            // MIN_EARLY_CLOSE_LENGTH, not MIN_SESSION_LENGTH. This overlay writes `effClose`
            // straight into `CalendarLib._classify`, so it bypasses `setSessionHours` entirely —
            // both of that setter's bounds, including the `MAX_SESSION_SHIFT` one added for exactly
            // this class. Inheriting its 1-hour floor let the same collapse through the per-day
            // door: an early close at `openSec + 1h` makes 10:30-16:00 read OVERNIGHT and centres
            // the closing ramp on 10:30, so on the shipped NVDA curve the real 16:00 auction prices
            // at 400 pips instead of 1500. That is a 73% cut, deeper than `MAX_POKE_DISCOUNT_BPS`
            // allows the system's HOT key, from a role whose stated worst case is "flipping a day
            // between two configured fee floors".
            //
            // 1 hour was never a half day; it was copied from the length check on
            // `setSessionHours`, where it guards a different failure (deleting the opening
            // descent). The two real US half days are 3.5h, so a 3h floor admits every genuine
            // early close and refuses the compressions that are only useful as an attack.
            if (closeSec_ - o < MIN_EARLY_CLOSE_LENGTH) revert InvalidSessionHours();
        }
        _calendars[poolId].earlyClose[y * 10000 + m * 100 + d] = closeSec_;
        emit EarlyCloseSet(poolId, y, m, d, closeSec_);
    }

    /// @notice Override state for a given ET civil date.
    function dayOverride(PoolId poolId, uint256 y, uint256 m, uint256 d) public view returns (DayOverride) {
        // `d == 0` would underflow `(d - 1) * 2` into a bare arithmetic panic on a public view.
        // Named, for the same reason every other bound on this pair is named.
        if (d == 0 || d > 31) revert InvalidDayOverride();
        uint256 bits = (_calendars[poolId].dayOverrides[y * 100 + m] >> ((d - 1) * 2)) & 3;
        if (bits & 1 == 1) return DayOverride.FORCE_CLOSED;
        if (bits == 2) return DayOverride.FORCE_OPEN;
        return DayOverride.NONE;
    }

    /// @notice Trading session at the given timestamp.
    /// @dev A thin wrapper over `CalendarLib.sessionAt`, which is inlined into this contract.
    function sessionAt(PoolId poolId, uint256 timestamp) public view returns (SessionLib.Session) {
        PoolCalendar storage cal = _calendars[poolId];
        return CalendarLib.sessionAt(
            cal.dayOverrides, cal.earlyClose, openSec(poolId), closeSec(poolId), cal.dstMode, timestamp
        );
    }

    /// @notice Fee floor (in pips) at the given timestamp for the given configuration, including
    ///         the opening descent and the closing ramp. Caller clamps to pool fee bounds.
    /// @dev The whole computation — the DST/ET context, the override-aware session classification,
    ///      the opening descent and the closing ramp — lives in `CalendarLib`, inlined into this
    ///      contract; it reads this contract's override storage and session config by reference.
    function feeFloorAt(PoolId poolId, SessionLib.FloorConfig memory cfg, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        PoolCalendar storage cal = _calendars[poolId];
        return CalendarLib.feeFloorAt(
            cal.dayOverrides, cal.earlyClose, openSec(poolId), closeSec(poolId), cal.dstMode, cfg, timestamp
        );
    }
}
