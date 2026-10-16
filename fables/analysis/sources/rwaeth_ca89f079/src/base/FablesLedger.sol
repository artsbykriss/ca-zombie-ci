// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {ERC6909} from "v4-core/src/ERC6909.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {FablesBaseHook} from "./FablesBaseHook.sol";
import {
    RangeState,
    UserPosition,
    RangeKey,
    ClaimFeeChange,
    PoolClaimFee,
    Action,
    CallbackData,
    PayoutData,
    FeesForgone,
    FeesCollected,
    DistributorSwept,
    ClaimFeeSwept
} from "./LedgerTypes.sol";
import {LedgerLib} from "../libraries/LedgerLib.sol";

/// @title FablesLedger
/// @notice Per-range liquidity ledger inside the singleton hook: users deposit concentrated
///         liquidity in any tick range; the hook holds one PoolManager position per range and
///         mints ERC-6909 receipts 1:1 with liquidity units.
/// @dev Founding constraints, in order of importance:
///       - WITHDRAWALS ARE UNCONDITIONAL. No admin state can BLOCK the path: no pause, no oracle,
///         no distributor, no claim fee on principal; staked shares auto-unstake. It does READ
///         three admin-written values — `claimFeeRecipient` and the per-pool rate in
///         `_poolClaimFee` (which set the skim taken at collection, i.e. the AMOUNT credited), and
///         `maxFee[poolId]` in `_checkKey` (which `_setPoolBounds` can never return to zero). The
///         storage declaration and `withdrawAndClaim` both say this; this line used to claim the
///         path "reads no admin state" flatly, which is the shape that lets a reader conclude the
///         one-way `claimFeeRecipient` guard and `claimFeeFor`'s min-over-window are not
///         load-bearing here.
///         It also makes no token call on the ledger's own behalf: collected fees settle as
///         PoolManager ERC-6909 claims, never as transfers to this contract. A token that
///         blocklists THIS contract therefore cannot freeze anyone's principal, and the only
///         transfer on the path is the PoolManager paying the withdrawer directly.
///       - SOLVENT BY CONSTRUCTION. Shares are liquidity units (no exchange rate), so
///         totalShares(range) == position liquidity is an invariant, not an aspiration, and
///         there is no share-price inflation attack surface.
///       - Fees accrue per range via Q128 accumulators, checkpointed on every share change;
///         claims are pull-only. A claim fee (default 0) applies to FEES exclusively.
///       - The staking switch ships dormant: staked shares route their fee accrual to a
///         settable distributor instead of the holder. It costs nothing until used and
///         cannot be retrofitted later (contracts are immutable).
/// @dev The slice of the Voter this contract needs: does `account` back `poolId` with a lock it
///      owns? Declared here rather than importing the Voter so the hook does not carry the whole
///      voting contract in its bytecode, and so the two can be deployed in either order.
///
///      NO `IVoterEscrowRef` HERE. An interface of that name used to sit between this block and the
///      `IBallotGate` it describes, carrying a doc claiming to be the probe `setBallotGate` uses.
///      It was neither: it had no reference anywhere in this file, and `setBallotGate` deliberately
///      does the back-reference check with a RAW staticcall — because `try`/`catch` over an
///      interface is not enough here. A contract with a payable catch-all succeeds with empty
///      returndata, and the decode then reverts in the SUCCESS branch, past both catches.
///
///      That matters because the dead interface's doc read as an invitation to "tidy" the raw call
///      into `try IVoterEscrowRef(escrow).voter()`, which reopens exactly that hole on the setter
///      binding the anti-rental guarantee. Deleted for that reason, not for tidiness.
interface IBallotGate {
    /// @dev The escrow the gate is wired to. Read by `setBallotGate` to prove that THIS gate is the
    ///      one that escrow calls back — see the cross-check there.
    function ve() external view returns (address);
    function ballotBacks(address account, uint256 tokenId, PoolId poolId) external view returns (bool);
    // NEITHER IS REACHED BY ANY LEDGER PATH, and neither is probed by `setBallotGate`, which checks
    // the four that `stake`/`syncRanges` actually call. They are declared for integrators reading
    // this interface as the gate's shape.
    //
    // That is worth stating rather than leaving as a silent gap: the setter's own NatSpec records
    // that its probe once tracked `isGaugeLive` while `stake` had already moved to `isGaugeEarning`,
    // and staying on the old member reopened the hole. Two unreachable members sitting here are the
    // standing invitation to re-add the wrong probe, or to route a future `stake` gate through a
    // member nothing verifies exists.
    function isGaugeKilled(PoolId poolId) external view returns (bool);
    function isGaugeLive(PoolId poolId) external view returns (bool);
    function isGaugeEarning(PoolId poolId) external view returns (bool);
    function gaugeWeightNow(PoolId poolId) external view returns (uint256);
}

abstract contract FablesLedger is FablesBaseHook, ERC6909, ReentrancyGuardTransient, IUnlockCallback {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    error LedgerPaused();
    error DeskBelowMinWeight();
    error PauseTooLong();
    error ZeroLiquidity();
    /// @notice The transaction was mined after the caller's stated deadline.
    error DeadlineExpired();
    error InsufficientUnstakedShares();
    error ZeroShares();
    error ZeroAddress();
    error InvalidSink();
    // Reverted from inside `LedgerLib` on the admin paths, so they surface through this
    // contract with these selectors; declared here for that ABI surface and cost no bytecode.
    error InvalidClaimFee();
    error DistributorNotFFAware();
    error ClaimFeeAboveMax();
    error NothingToClaim();
    error NotAVoterOfThisPool();
    error BallotGateUnset();
    error DeskRetired();
    error InvalidBallotGate();
    error InvalidMsgValue();
    error RefundFailed();

    event Deposited(address indexed owner, uint256 indexed rangeId, uint128 liquidity);
    event Withdrawn(address indexed owner, uint256 indexed rangeId, uint128 liquidity);
    event FeesClaimed(address indexed owner, uint256 indexed rangeId, uint256 amount0, uint256 amount1);
    event Staked(address indexed owner, uint256 indexed rangeId, uint128 shares);
    // `FeesForgone` is declared in `LedgerTypes.sol`, so `LedgerLib` emits it with
    // the identical signature the settlement indexer reads.
    event Unstaked(address indexed owner, uint256 indexed rangeId, uint128 shares);
    // `FeesCollected` is declared in `LedgerTypes.sol` (with its full per-field settlement
    // rationale), so `LedgerLib.creditFees` emits it with the identical signature
    // the indexer reads.
    // `DistributorSwept` and `ClaimFeeSwept` are declared in `LedgerTypes.sol`, so
    // `LedgerLib`'s sweep functions emit them with the identical signatures the
    // indexer reads.
    event ClaimFeeSet(PoolId indexed poolId, uint16 bps, address recipient);
    event DistributorSet(address distributor);
    event FFFeeSinkSet(address sink);
    event PausedSet(uint256 pausedUntil);
    event PoolPausedSet(PoolId indexed poolId, uint256 pausedUntil);
    event BallotGateSet(address gate);

    /// @dev ALIASED from `LedgerLib`, not redeclared — the library is the one that enforces it, so
    ///      the two can no longer disagree. 20%, fixed in bytecode.
    uint16 public constant MAX_CLAIM_FEE_BPS = LedgerLib.MAX_CLAIM_FEE_BPS;
    /// @dev How far back a sync will walk the rate history. Beyond it the all-time minimum is
    ///      used, which can only ever charge LESS — never more — than the true window minimum.
    ///      This cap, not a cooldown, is what bounds the cost: it holds whatever the history
    ///      length. The AccessManager delay on the SETTERS makes growing the history slow as well,
    ///      but that is a second line and not this cap's warrant — and the routine grower is now
    ///      `setClaimFeeBps` on REVENUE_OPS, not `setClaimFee` on ADMIN. The whole point of that
    ///      split was to let the two carry different delays, so if REVENUE_OPS is ever moved to
    ///      delay 0 the second line goes and this cap is the only bound left. It is sized to be
    ///      sufficient alone.
    ///      ALIASED from `LedgerLib` for the same reason as `MAX_CLAIM_FEE_BPS` above.
    uint256 public constant MAX_CLAIM_FEE_WALK = LedgerLib.MAX_CLAIM_FEE_WALK;

    // `RangeState` now lives in `LedgerTypes.sol` (shared with `LedgerLib`); its layout is
    // unchanged. See that file for the per-field notes.

    // `UserPosition` now lives in `LedgerTypes.sol` (shared with `LedgerLib`); its layout is
    // unchanged. See that file for the per-field notes.

    /// @notice Admin levers. None of them can BLOCK a withdrawal — but two ARE read on that path.
    /// @dev `claimFeeRecipient`, and the per-pool rate in `_poolClaimFee`, are read on every
    ///      `withdraw`: `_withdrawTo` -> `_syncRange` -> `unlockCallback` -> `LedgerLib.creditFees`
    ///      -> `_split`, where `claimFeeRecipient != address(0)` gates the skim. So an admin write
    ///      changes the AMOUNT credited; it cannot stop the exit, which is the guarantee that
    ///      actually matters and the one this line used to overstate.
    ///
    ///      `withdrawAndClaim`'s own NatSpec says this correctly and at length ("a caller who
    ///      refuses a rate here and then withdraws pays exactly the rate they refused"), so the two
    ///      blocks answered the same question in opposite directions — the shape that let the
    ///      PoolManager sentinel be missed on three of four `take` paths in an earlier round. Two
    ///      lenses reported it independently.
    ///
    ///      `distributor`, `distributorFF` and `ffFeeSink` really are unread on that path.
    address public claimFeeRecipient;
    address public distributor;
    /// @notice The protocol token, cached from the distributor. Refused by `sweepDistributor`.
    address public distributorFF;
    /// @notice Destination for FF-denominated staked-fee revenue. See `sweepDistributor`.
    address public ffFeeSink;

    // `ClaimFeeChange` now lives in `LedgerTypes.sol` (shared with `LedgerLib`, which walks the
    // history inside `creditFees`); its layout is unchanged.

    /// @notice Every claim-fee rate this ledger has ever stood at, oldest first.
    /// @dev v4 accrues fees LAZILY: nothing is paid until a position is touched, so a range's
    ///      backlog is an opaque lump earned over a window of arbitrary length that may span any
    ///      number of rate changes. A single per-range snapshot could not describe that. It gave
    ///      `min(rate now, rate at last touch)`, which is right at both ends and wrong in the
    ///      middle — a rate that dipped and recovered between two touches billed the WHOLE
    ///      backlog at the high rate, including everything earned while the protocol was
    ///      advertising the low one.
    ///      Keyed by pool: one singleton may serve many pools, and a single hook-wide rate would
    ///      force every pool on it onto the same protocol fee. The recipient stays hook-wide (one
    ///      sink), and clearing it still zeroes every pool at once, because the effective rate is
    ///      `recipient == 0 ? 0 : bps` at every read.
    mapping(PoolId poolId => PoolClaimFee policy) internal _poolClaimFee;

    /// @notice How many rate changes had been recorded when each range last realized its fees —
    ///         i.e. where in the history its current backlog opened.
    /// @dev An INDEX, not a timestamp, and not a rate. Not a rate because a single rate cannot
    ///      answer "what was in force across this window". Not a timestamp because several rate
    ///      changes and several syncs can share one `block.timestamp`, and a cursor that cannot
    ///      order two events in the same block would charge a backlog at a rate that was set
    ///      after it was already realized.
    mapping(uint256 rangeId => uint64 index) public claimFeeSyncIndex;

    /// @notice Exploit-response switch: freezes deposits, claims, staking, transfers and
    ///         sweeps. Principal withdrawal and unstaking are deliberately NOT pausable, ever.
    /// @dev An expiry, not a flag. A pause that never lapses is indistinguishable from a
    ///      confiscation of everything it touches: fees already credited to a holder become
    ///      permanently unclaimable and a receipt becomes permanently untransferable, with no
    ///      recourse if the key that set it is gone. Bounding the duration in bytecode keeps
    ///      the emergency power without letting it become a permanent one — renewing is always
    ///      possible, but it is a deliberate, visible act each time rather than the default.
    uint256 public pausedUntil;

    /// @notice Per-pool freeze: deposits, claims, staking and transfers, scoped to one pool.
    /// @dev NOT the sweeps. `pausedUntil` also freezes `sweepDistributor` and `sweepClaimFee`, and
    ///      this cannot: both pots are keyed by CURRENCY and aggregate across every pool on the
    ///      singleton, so there is no pool in scope to test. An incident that touches the fee pots
    ///      themselves — rather than one pool's LP traffic — still needs the hook-wide `pause`.
    /// @dev One singleton may serve many pools, which makes a single hook-wide switch the wrong
    ///      granularity for an incident: containing one pool would have to freeze every other
    ///      pool's LPs to do it. A pool is frozen when EITHER lever is live, so the hook-wide
    ///      switch keeps its exact meaning and this only ever narrows the blast radius. Same
    ///      bounded-expiry reasoning as above — an unlappable freeze is a confiscation.
    mapping(PoolId poolId => uint256 until) public pausedUntilOf;

    /// @notice The Voter, consulted to decide who may collect a staked range's fees.
    address public ballotGate;

    /// @notice Longest a single pause can last before it must be renewed on purpose.
    uint256 public constant MAX_PAUSE = 7 days;

    /// @notice True while the ledger is paused for EVERY pool.
    function paused() public view returns (bool) {
        // day-scale window; second-level drift is immaterial
        // forge-lint: disable-next-line(block-timestamp)
        return pausedUntil > block.timestamp;
    }

    /// @notice True while `poolId` is frozen, by either the hook-wide or its own pause.
    function pausedFor(PoolId poolId) public view returns (bool) {
        // forge-lint: disable-next-line(block-timestamp)
        return pausedUntil > block.timestamp || pausedUntilOf[poolId] > block.timestamp;
    }

    modifier whenNotPaused() {
        if (paused()) revert LedgerPaused();
        _;
    }

    /// @dev For entry points that name a pool. Falls through to the hook-wide pause, so a hook
    ///      frozen as a whole still refuses every pool.
    modifier whenPoolNotPaused(PoolId poolId) {
        if (pausedFor(poolId)) revert LedgerPaused();
        _;
    }

    /// @dev For entry points that name a RANGE rather than a pool. An unknown range resolves to
    ///      the zero key, whose pool has no pause set, so it degrades to the hook-wide check —
    ///      never to "unpausable".
    modifier whenRangeNotPaused(uint256 id) {
        if (pausedFor(_rangeKeys[id].key.toId())) revert LedgerPaused();
        _;
    }

    // `RangeKey` now lives in `LedgerTypes.sol` (shared with `LedgerLib`, which reads a range's
    // descriptor for the `FeesCollected` growth read); its layout is unchanged.

    mapping(uint256 rangeId => RangeKey descriptor) internal _rangeKeys;
    mapping(uint256 rangeId => RangeState state) internal _ranges;
    mapping(uint256 rangeId => mapping(address owner => UserPosition position)) internal _positions;
    mapping(Currency currency => uint256 owed) public distributorOwed;

    /// @notice Claim-fee cut accrued for the recipient. Pull, never push: a blocked or
    ///         paused recipient must not be able to block anyone else's claim.
    mapping(Currency currency => uint256 owed) public claimFeeOwed;

    /* ---------------------------------- views ---------------------------------- */

    /// @notice True while a ledger operation is mid-flight. Always false to an external
    ///         caller; only a token callback fired from inside this contract can observe it
    ///         set. Integrators pricing receipts from within such a callback should refuse.
    function isSettling() external view returns (bool) {
        return _reentrancyGuardEntered();
    }

    function rangeId(PoolId poolId, int24 tickLower, int24 tickUpper) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(poolId, tickLower, tickUpper)));
    }

    /// @notice The pool key and tick range a `rangeId` was registered under. `set` is false for an
    ///         id that has never been deposited into.
    /// @dev `rangeId` is a one-way hash, and the `Deposited`/`Staked`/`FeesCollected` events carry
    ///      only the id — so an off-chain settlement run seeing a `rangeId` cannot otherwise attribute
    ///      that range's fees to a pool/gauge without decoding deposit calldata. This exposes the
    ///      stored preimage so the mapping is available from the public ABI, first deposit onward.
    function rangeKey(uint256 id)
        external
        view
        returns (PoolKey memory key, int24 tickLower, int24 tickUpper, bool set)
    {
        RangeKey storage descriptor = _rangeKeys[id];
        return (descriptor.key, descriptor.tickLower, descriptor.tickUpper, descriptor.set);
    }

    /// @notice v4's per-liquidity fee accumulator for a range, right now.
    /// @dev The read the boundary snapshotter is built on. Settlement attributes forgone fees to
    ///      the week they were GENERATED, so an interval of collection that straddles a week
    ///      boundary has to be split AT the boundary — and nothing happens on chain at a boundary
    ///      unless somebody syncs, so that one value cannot come from the log stream. It comes
    ///      from calling this at the boundary block instead.
    ///
    ///      A view rather than a stored snapshot, deliberately: reading it at a historical block
    ///      is exact, whereas a stored snapshot would be exact only if someone remembered to
    ///      write it in time — the punctuality dependency this whole change exists to remove.
    ///
    ///      IT IS NOT MONOTONIC ACROSS A LIQUIDITY RESET. An earlier version of this comment
    ///      claimed the accumulator "moves only when a swap crosses the range". It also moves
    ///      when a tick is initialised or cleared: v4 deletes `feeGrowthOutside` once the last
    ///      liquidity at a tick is removed and re-bases it against the current global on the next
    ///      deposit, so a range that empties and refills reads a fresh, unrelated baseline. Two
    ///      readings either side of that are not comparable, and settlement must treat a backwards
    ///      step as a reset rather than as a delta — which it does, loudly.
    function rangeGrowth(uint256 id) external view returns (uint256 growth0, uint256 growth1) {
        RangeKey storage descriptor = _rangeKeys[id];
        if (!descriptor.set) return (0, 0);
        return
            StateLibrary.getFeeGrowthInside(
                poolManager, descriptor.key.toId(), descriptor.tickLower, descriptor.tickUpper
            );
    }

    function rangeState(uint256 id) external view returns (RangeState memory) {
        return _ranges[id];
    }

    function userPosition(uint256 id, address owner) external view returns (UserPosition memory) {
        return _positions[id][owner];
    }

    /* ---------------------------------- admin ---------------------------------- */

    function setClaimFee(PoolKey calldata key, Currency[] calldata settleFirst, uint16 bps, address recipient)
        external
        restricted
        nonReentrant
    {
        // The recipient is hook-wide but the rate HISTORY is per pool, and the effective rate is
        // `recipient == 0 ? 0 : bps` at every read. So clearing the recipient would drop EVERY
        // pool's advertised rate to zero while appending that fact to only ONE pool's history —
        // and restoring it would then bill every other pool's backlog, accrued while the protocol
        // advertised nothing, at the full rate. That is exactly the retroactive charge the whole
        // minimum-over-the-window design exists to make impossible.
        //
        // Making the recipient one-way closes it completely rather than partially. Before the
        // first recipient is set, every pool's rate is necessarily zero (a non-zero rate without a
        // recipient is refused below), so the gate cannot change any rate. After it is set it
        // never returns to zero, so it cannot change one either — leaving each pool's own history
        // a COMPLETE record of what that pool ever advertised. Switching a pool off is
        // `setClaimFee(key, …, 0, recipient)`, which appends the zero to that pool's history where
        // its own ranges will walk it. Rotating between two non-zero sinks stays free.
        if (recipient == address(0) && claimFeeRecipient != address(0)) revert InvalidClaimFee();
        // The pool must exist. Deploy order is pools first (scripts 02/03) then protocol wiring
        // (script 06), so this costs no ordering freedom — and without it a mistyped key writes a
        // rate to an unreachable phantom entry while the pool it was meant for silently keeps its
        // default of zero, with an event that names the wrong pool as the only trace.
        _checkKey(key);
        _settleSinks(settleFirst);
        // Validation, the history append and the all-time-min update live in `LedgerLib`
        // (inlined); the value-vars are written here around it. The
        // recipient may be neither this hook (the permissionless sweep would `take` the revenue
        // straight to it) nor the distributor (which cannot pay FF out as a fee) — and that guard
        // holds in EITHER call ordering, `setDistributor` enforcing the mirror.
        PoolClaimFee storage pcf = _poolClaimFee[key.toId()];
        _checkSinkTarget(recipient);
        pcf.allTimeMin = LedgerLib.recordClaimFee(pcf.history, bps, recipient, distributor, ffFeeSink, pcf.allTimeMin);
        pcf.bps = bps;
        claimFeeRecipient = recipient;
        emit ClaimFeeSet(key.toId(), bps, recipient);
    }

    /// @notice Sets one pool's claim-fee RATE against the sink already in force. Same history
    ///         append, same all-time-min, same retroactive-in-the-LP's-favour semantics as
    ///         `setClaimFee` — it simply cannot name a destination.
    /// @dev Exists so the rate can carry a role of its own. `setClaimFee` writes the rate and the
    ///      hook-wide recipient in one call because the FIRST activation genuinely needs both at
    ///      once (a non-zero rate with no recipient is refused, and the recipient is one-way, so
    ///      the two cannot be ordered apart at genesis). That coupling then forced everything
    ///      afterwards — every ordinary rate tweak on any pool — to carry the authority to move
    ///      every pool's revenue, and with no role assigned it fell through to ADMIN_ROLE at the
    ///      admin delay. Wrong on both axes: too much power for a routine change, and too slow.
    ///
    ///      Splitting it here rather than in the role wiring is what makes the separation real.
    ///      Two selectors can hold two roles; one selector cannot, however the AccessManager is
    ///      configured. So the ops role gets THIS one and can only ever set a number, while
    ///      naming or rotating the sink stays on `setClaimFee` under ADMIN.
    ///
    ///      Requires a recipient to already exist. That is not a restriction — it is the same
    ///      `bps != 0 && recipient == 0` refusal `recordClaimFee` already makes, hoisted so the
    ///      failure names the actual cause. Genesis stays an ADMIN act; everything after is ops.
    /// @dev NO `settleFirst`, deliberately, and this setter is the reason `_settleSinks` needs one
    ///      at all to be justified. `_settleSinks` exists so a sink ROTATION settles the outgoing
    ///      destination before the new one takes effect — and this setter takes no recipient and
    ///      cannot rotate anything: the pots are keyed by currency and paid to the same unchanged
    ///      address either way.
    ///
    ///      So the settle changed nothing it was justified by, while handing REVENUE_OPS — a
    ///      non-ADMIN role — a way to move both revenue pots to their sinks during a hook-wide
    ///      freeze, because `_settleSinks` calls the INTERNAL sweeps and only the permissionless
    ///      ones are `whenNotPaused`. Three separate comments described this role as one that "can
    ///      only ever set a number"; now that is true. Two lenses reached this independently and
    ///      both prescribed deleting the parameter rather than adding a pause gate.
    function setClaimFeeBps(PoolKey calldata key, uint16 bps) external restricted nonReentrant {
        address recipient = claimFeeRecipient;
        if (recipient == address(0)) revert InvalidClaimFee();
        _checkKey(key);
        PoolClaimFee storage pcf = _poolClaimFee[key.toId()];
        _checkSinkTarget(recipient);
        pcf.allTimeMin = LedgerLib.recordClaimFee(pcf.history, bps, recipient, distributor, ffFeeSink, pcf.allTimeMin);
        pcf.bps = bps;
        emit ClaimFeeSet(key.toId(), bps, recipient);
    }

    /// @notice Where FF-denominated staked-share fee revenue is swept. Separate from
    ///         `distributor` because the epoch distributor cannot pay FF out as a fee.
    function setFFFeeSink(Currency[] calldata settleFirst, address sink) external restricted nonReentrant {
        _settleSinks(settleFirst);
        // The two addresses this sink exists to avoid, and the contract already holds both.
        // Pointing it at the epoch distributor routes FF into the one place that can neither
        // declare nor rescue it; pointing it at the hook leaves it as an unaccounted balance
        // with no payout path. `setDistributor` spends a try/catch preventing the mirror
        // mistake — and the sweep that would destroy the funds is permissionless, so the
        // operator gets no window to notice.
        // Clearing is always free, matching `LedgerLib.validateDistributor`, which early-returns on
        // the zero address before any comparison. Without the first term the two guards stop being
        // mirrors: once ops clears the distributor, `sink == distributor` becomes `sink == 0` and
        // the FF sink can no longer be cleared until a distributor is put back. An unset sink is a
        // safe resting state — the sweep reads `to == 0` and keeps the accrual waiting.
        // The sixth edge of the mutual-exclusion lattice, which was the only one missing. The
        // other five are refused in both call orderings with an explicit "reachable in EITHER
        // ordering" rationale; `ffFeeSink == claimFeeRecipient` was refused by neither setter.
        // Co-mingling the two revenue streams at one address is benign today — the accruals are
        // separate per-currency pots swept by separate calls, and `DistributorSwept`/
        // `ClaimFeeSwept` still tell them apart — but the asymmetry is invisible against the
        // stated rule, and on an immutable contract any future change that keys either pot by
        // something the two sinks share turns it into a real collision.
        if (sink != address(0) && (sink == distributor || sink == claimFeeRecipient || sink == address(this))) {
            revert InvalidSink();
        }
        _checkSinkTarget(sink);
        ffFeeSink = sink;
        emit FFFeeSinkSet(sink);
    }

    /// @dev The user-facing half of a PAIR: this guards caller-supplied payout targets,
    ///      `_checkSinkTarget` guards admin-supplied sinks, and between them — PLUS each sink
    ///      setter's own `address(this)` refusal in `recordClaimFee`, `validateDistributor` and
    ///      `setFFFeeSink` — all five `take` destinations IN THIS CONTRACT refuse both sentinels,
    ///      `address(this)` and the PoolManager. `_checkSinkTarget` ALONE refuses only the
    ///      PoolManager; reading "between them" as "these TWO FUNCTIONS do it" would license
    ///      deleting those three setter-side refusals, which reopens the original hole. (`FablesNativeETH`'s two wrap-sweeps add a SIXTH
    ///      `take` destination, `address(this)` itself, deliberately: the hook must receive the ETH
    ///      in order to wrap it. Saying "five" without that made a reader grepping the family find a
    ///      sixth site whose destination is exactly the sentinel this paragraph says all of them
    ///      refuse, and re-derive from scratch why it is safe.)
    ///
    ///      ONE DESTINATION IS NOT COVERED by either sentinel and is named here rather than left to
    ///      be discovered: a SIBLING native hook. Every native hook shares one `receive()`
    ///      allowlisted to the PoolManager — the SAME PoolManager both hooks are bound to — so
    ///      `withdraw(..., to = anotherFablesNativeHook)` succeeds, and the ETH lands in a contract
    ///      with no rescue function whose `_refundNative` is delta-bounded and so never pays out a
    ///      pre-existing balance. The outcome is byte-identical to the `address(this)` case these
    ///      sentinels exist for; the check is simply instance-scoped. It is self-inflicted only
    ///      (nobody can set another user's `to`), and closing it needs a registry or a `weth()`-
    ///      shaped probe on `to` — a design change, not a comparison. `_refundNative`'s own note
    ///      says bounding by the delta "closes the sibling-hook route too": that closes the
    ///      RECIRCULATION race, where a stranger claims the parked ETH, not the LOSS.
    ///
    ///      Stated as a pair deliberately. An earlier version of this block called itself "the
    ///      mirror of the guard all three ADMIN sink setters already carry", which
    ///      `_checkSinkTarget`'s own doc eight lines below then had to retract as false: the admin
    ///      setters refused `address(this)` and NOT the PoolManager, which is why
    ///      `_checkSinkTarget` had to be written. Two adjacent blocks answering "do the admin
    ///      setters mirror this?" in opposite directions is the same ambiguity that let the manager
    ///      sentinel be missed on three of four paths in the first place.
    ///
    ///      The reason is shared: a payout is a `poolManager.take` to the named address, so naming
    ///      the hook destroys the revenue and naming the manager sends it nowhere — and
    ///      `withdraw`/`claimFees` reach that identical `take` with a target checked only against
    ///      zero.
    ///
    ///      Both legs are real losses, which is why this guard is the fix rather than anything
    ///      downstream. The ERC20 leg lands on this contract, which has no rescue function of any
    ///      kind: permanently gone. The NATIVE leg lands here and stays here — `_refundNative`
    ///      returns only the caller's own unspent remainder, so a parked balance is not payable to
    ///      anyone. Before that was true it was worse than a loss: the mis-addressed withdrawal
    ///      became a race prize for whoever called `deposit` next. Closing the race did not make
    ///      the money recoverable, and this check is what stops it being lost in the first place.
    ///
    ///      Nothing legitimate passes the hook here: `to` exists so a holder can route around a
    ///      token that blocklists their own address, and the hook is never a useful destination.
    ///
    ///      THE POOL MANAGER IS THE SECOND SENTINEL, and it destroys value the same way for a
    ///      different reason. `take(currency, poolManager, amount)` is a SELF-TRANSFER: the manager
    ///      sends to itself, its own balance is unchanged, and the flash-accounting delta nets to
    ///      zero — so `_settle`'s `paid = balanceOfSelf - reserves` computes 0 and the whole
    ///      withdrawal completes as if it had worked. Measured: the manager's currency0 balance
    ///      identical before and after (8974944408554067 both sides) while the LP's shares were
    ///      burned and `owed0`/`owed1` zeroed. Full loss of principal AND fees, and nothing on
    ///      chain says so.
    ///
    ///      Both sentinels are self-harm from a typo rather than an attack — nobody can pass a
    ///      target for someone else — but the failure is silent, total and unrecoverable, and the
    ///      guard is one comparison on a path that already does one. Three independent audit
    ///      lenses reached the manager sentinel separately, which is the signal that settled it.
    function _checkPayoutTarget(address to) internal view {
        if (to == address(this) || to == address(poolManager)) revert InvalidSink();
    }

    /// @dev The PoolManager sentinel for an ADMIN-supplied SINK, mirroring `_checkPayoutTarget`'s
    ///      for a user-supplied payout target.
    ///
    ///      `_checkPayoutTarget`'s NatSpec claimed to be "the user-facing mirror of the guard all
    ///      three ADMIN sink setters already carry". That was FALSE: those setters refused
    ///      `address(this)` and not the manager, so the sentinel existed on one of four paths that
    ///      reach the same `take`. THREE independent audit lenses found the gap separately, which
    ///      is what settled it.
    ///
    ///      The loss is identical and it is worse in one respect: a sink is set once and the sweep
    ///      that destroys the pot is PERMISSIONLESS, so a stranger triggers it. Measured with
    ///      `claimFeeRecipient = poolManager`: a stranger's `sweepClaimFee` retired the whole
    ///      accrual, burned the hook's backing claims, left the manager's ERC20 balance
    ///      byte-identical, and emitted `ClaimFeeSwept` as if it had worked.
    ///
    ///      Rotating away does not save it either — `_settleSinks` runs at the HEAD of every sink
    ///      setter, so the documented rotation sweeps the pot into the void on the way out.
    function _checkSinkTarget(address sink) internal view {
        if (sink == address(poolManager)) revert InvalidSink();
    }

    /// @dev Pushes every named pot to its CURRENT destination before that destination changes.
    ///      The pots are keyed by currency alone and the destination is resolved at sweep time,
    ///      so rotating a sink silently re-pointed revenue that accrued entirely under the old
    ///      one. The permissionless sweep was the old sink's only defence, and it is
    ///      `whenNotPaused` while the setters are not — so a pause covering the rotation removed
    ///      even that. Settling here makes the rotation deterministic FOR THE CURRENCIES THE CALLER NAMES, exactly as
    ///      `FablesTreasurySplitter.setSplit` does for its own recipients.
    function _settleSinks(Currency[] calldata currencies) internal {
        for (uint256 i = 0; i < currencies.length; i++) {
            _sweepDistributor(currencies[i]);
            _sweepClaimFee(currencies[i]);
        }
    }

    function setDistributor(Currency[] calldata settleFirst, address distributor_) external restricted nonReentrant {
        _settleSinks(settleFirst);
        // The sink guards (distributor may equal neither the FF sink nor the claim-fee recipient
        // nor this hook — reachable in either call ordering, so both setters reject it) and the FF
        // probe (a live distributor must name the protocol token so a later sweep can refuse FF)
        // live in `LedgerLib.validateDistributor` (inlined). It returns
        // the token to cache, or zero when clearing.
        _checkSinkTarget(distributor_);
        distributorFF = LedgerLib.validateDistributor(distributor_, ffFeeSink, claimFeeRecipient);
        distributor = distributor_;
        emit DistributorSet(distributor_);
    }

    /// @notice Pauses for `duration` seconds, or lifts the pause when `duration` is zero.
    function setPaused(uint256 duration) external restricted {
        if (duration > MAX_PAUSE) revert PauseTooLong();
        pausedUntil = duration == 0 ? 0 : block.timestamp + duration;
        emit PausedSet(pausedUntil);
    }

    /// @notice Freezes the ledger. Cannot unfreeze, and cannot shorten a freeze already running.
    /// @dev A separate selector from `setPaused` so the fast key really is one-way. Binding the
    ///      combined `setPaused` to a zero-delay role looked like an emergency stop but handed
    ///      that same key the UNPAUSE — `setPaused(0)` clears the freeze — so a compromised
    ///      guardian could lift the multisig's freeze every block. This entry point can only
    ///      ever move `pausedUntil` forward, which is what makes it safe to run at zero delay,
    ///      and `setPaused` stays on the delayed ADMIN_ROLE for lifting it.
    function pause(uint256 duration) external restricted {
        if (duration == 0 || duration > MAX_PAUSE) revert PauseTooLong();
        uint256 until_ = block.timestamp + duration;
        if (until_ <= pausedUntil) revert PauseTooLong(); // never shortens a running freeze
        pausedUntil = until_;
        emit PausedSet(until_);
    }

    /// @notice Pauses ONE pool for `duration` seconds, or lifts that pool's pause when zero.
    /// @dev The per-pool twin of `setPaused`, and delayed for the same reason: it can unfreeze.
    ///      Lifting a pool's own pause does not lift the hook-wide one, so this can never widen
    ///      access beyond what `setPaused` already allows.
    function setPoolPaused(PoolKey calldata key, uint256 duration) external restricted {
        if (duration > MAX_PAUSE) revert PauseTooLong();
        _checkKey(key);
        PoolId poolId = key.toId();
        uint256 until_ = duration == 0 ? 0 : block.timestamp + duration;
        pausedUntilOf[poolId] = until_;
        emit PoolPausedSet(poolId, until_);
    }

    /// @notice Freezes ONE pool. Cannot unfreeze, and cannot shorten a freeze already running.
    /// @dev The per-pool twin of `pause`, and one-way for the same reason: this is the selector a
    ///      zero-delay guardian key gets, so it must not be able to hand that key an unpause.
    ///      Containing a single pool no longer costs every other pool on the singleton its
    ///      deposits, claims, staking and transfers.
    function pausePool(PoolKey calldata key, uint256 duration) external restricted {
        if (duration == 0 || duration > MAX_PAUSE) revert PauseTooLong();
        _checkKey(key);
        PoolId poolId = key.toId();
        uint256 until_ = block.timestamp + duration;
        if (until_ <= pausedUntilOf[poolId]) revert PauseTooLong(); // never shortens a running freeze
        pausedUntilOf[poolId] = until_;
        emit PoolPausedSet(poolId, until_);
    }

    /* ---------------------------------- internals: guards & sync ---------------------------------- */

    /// @dev Rejects pools that are not this hook's, so `callerDelta - feesAccrued` really is
    ///      principal (a foreign hook holding liquidity-delta flags would break that identity)
    ///      and receipts can only ever be minted for vetted pools.
    function _checkKey(PoolKey calldata key) internal view {
        if (address(key.hooks) != address(this) || maxFee[key.toId()] == 0) revert PoolNotConfigured();
        // Mirrors `beforeInitialize`: a native pool can only exist behind a hook whose
        // `_nativeAllowed` override ships the payable/settlement machinery, so on such a hook the
        // ledger paths must accept it; on every other hook the pool cannot have been initialized,
        // and this guard keeps receipts unmintable for a key that never passed the gate.
        if (key.currency0.isAddressZero() && !_nativeAllowed()) revert NativeNotSupported();
    }

    /// @dev Collect-only touch: materializes v4's lazily-accrued fees into the range's
    ///      accumulators BEFORE any share or stake mutation, so fees are always split at the
    ///      state that earned them. No-op for empty or unknown ranges.
    function _syncRange(uint256 id) internal {
        RangeKey memory descriptor = _rangeKeys[id];
        if (!descriptor.set || _ranges[id].totalShares == 0) {
            // A range with nothing in it has no backlog to mis-price, so this is the one moment its
            // rate can be set forward rather than backward.
            //
            // BELT AND BRACES, and the reason matters more than the write. This used to add that
            // "without it a brand-new range would carry a zero snapshot into its first real accrual
            // and pay nothing", which is FALSE: `LedgerLib.creditFees` rolls `claimFeeSyncIndex`
            // UNCONDITIONALLY, above its own zero-fee early return, and `deposit` always reaches it
            // via `_modify` — so on the deposit path the end state is identical either way. The one
            // caller that reaches this branch and commits is `claimFees` on an emptied range that
            // still has `owed`, where there is no backlog left to price and the roll is inert.
            //
            // Naming the wrong mechanism is the danger: a reader who trusts the old sentence
            // believes `creditFees` does NOT roll the index, and that is exactly the premise that
            // licenses deleting the roll there — which is the load-bearing one.
            //
            // So this is belt and braces on a path where `creditFees` would roll the index anyway: a
            // refill IS a `deposit`, so it reaches `creditFees`, and without this write the stale
            // index would only ever reach a `feeBps` local that is discarded, because `feesAccrued`
            // is zero on a position that was empty. An earlier version of this block ended by
            // claiming the write "guards the emptied-then-refilled range" — the sentence its own
            // middle paragraph refutes, and the reason `test_r10_anEmptiedRangeDoesNotKeepAStale-
            // ClaimFeeIndex` passes with the write removed. Kept for one SSTORE on a first deposit.
            claimFeeSyncIndex[id] = uint64(_poolClaimFee[descriptor.key.toId()].history.length);
            return;
        }
        // A zero delta moves no principal, so the bounds are irrelevant here and `_checkBound`
        // exempts a zero delta outright; passing the widest value states that plainly.
        _modifyMem(
            descriptor.key,
            descriptor.tickLower,
            descriptor.tickUpper,
            0,
            address(this),
            type(uint128).max,
            type(uint128).max
        );
    }

    /* ---------------------------------- actions ---------------------------------- */

    /// @notice Deposits `liquidity` units into the hook-owned position for the given range and
    ///         mints receipts 1:1. Caller must have approved this contract for both tokens.
    /// @param amount0Max The most currency0 the caller will pay for this liquidity.
    /// @param amount1Max The most currency1 the caller will pay for this liquidity.
    /// @param deadline Latest block timestamp at which this deposit may execute.
    /// @dev The bounds are NOT optional ceremony. `liquidity` says nothing about what it costs: the
    ///      token amounts fall out of the pool's live price inside `modifyLiquidity`, and whatever v4
    ///      asks for is pulled from the caller. Without a ceiling, the only limit was the caller's own
    ///      ERC-20 allowance, so a price move between signing and execution bought the whole position
    ///      one-sided at a price nobody agreed to. See `LedgerLib._checkBound`.
    /// @dev Payable for the native-capable variant only. On an ERC20 pool any attached value
    ///      reverts — accepting it would strand ETH on a contract with no path back out. On a
    ///      native pool the caller must attach AT LEAST `amount0Max`: the actual amount owed is
    ///      only learned inside the unlock callback, `_checkBound` caps it at `amount0Max`, so
    ///      prepaying the ceiling guarantees settlement can never under-fund — and the unspent
    ///      remainder is returned at the end — or the whole call REVERTS. `_refundNative` sends it
    ///      with a bare `call` and does `if (!success) revert RefundFailed()`, so a caller with no
    ///      payable `receive`/`fallback` cannot deposit on a native pool unless the refund is
    ///      exactly zero, which needs `msg.value == amount0Max == owed` to the wei. Reproducing that
    ///      equality means reproducing v4's round-UP on the settled principal while `LiquidityAmounts`
    ///      quotes round-DOWN — the same one-wei mismatch the seed scripts' `_cap` exists to absorb.
    ///      In practice the ETH desk's ledger is therefore EOA/Safe-only: a router or vault without
    ///      a payable fallback is refused. That is deliberate and argued at `_refundNative`; the
    ///      defect was that this line, the one an integrator reads, stated the opposite half.
    // State is written after `_syncRange` -> poolManager.unlock, which Slither reads as
    // reentrancy. Every one of these paths carries OZ's ReentrancyGuardTransient, whose
    // tstore-based guard Slither does not model. Proven rather than asserted by
    // test_reentrancyGuardStopsAReEntryMidCallback, which re-enters from a hostile token's
    // transferFrom mid-callback and asserts the revert is ReentrancyGuardReentrantCall.
    // slither-disable-next-line reentrancy-no-eth
    function deposit(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint128 amount0Max,
        uint128 amount1Max,
        uint256 deadline
    ) external payable nonReentrant whenPoolNotPaused(key.toId()) {
        if (liquidity == 0) revert ZeroLiquidity();
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) revert DeadlineExpired();
        _checkKey(key);
        if (key.currency0.isAddressZero()) {
            if (msg.value < amount0Max) revert InvalidMsgValue();
            // Whatever was already sitting here before this call. MUST be read now: after
            // `settle{value: owed}` the same expression yields `pre - owed`. Transient rather than
            // a stack local, which `deposit` has none to spare for.
            _setForeignNative(address(this).balance - msg.value);
        } else if (msg.value != 0) {
            revert InvalidMsgValue();
        }

        uint256 id = rangeId(key.toId(), tickLower, tickUpper);
        if (!_rangeKeys[id].set) {
            _rangeKeys[id] = RangeKey({key: key, tickLower: tickLower, tickUpper: tickUpper, set: true});
        }
        // Collect pending fees at PRE-mint totals (no token call: fees settle as claims), then
        // finish all bookkeeping, and only then touch the pool. The pool touch is the only
        // step that can hand control to a token, so by the time it can, `totalShares` and the
        // position's liquidity already agree — nothing observes a torn state.
        _syncRange(id);
        _settleUser(id, msg.sender);
        // Crossing UP from zero (re)creates the v4 position, so its ticks re-initialize and its
        // `feeGrowthInside` re-bases. Bumped BEFORE the pool touch so the collection it may trigger
        // carries the new value (H2).
        bool recreated = _ranges[id].totalShares == 0;
        if (recreated) _ranges[id].resetSeq += 1;
        _ranges[id].totalShares += liquidity;
        _mint(msg.sender, id, liquidity);
        _modify(key, tickLower, tickUpper, int256(uint256(liquidity)), msg.sender, amount0Max, amount1Max);
        // AFTER the pool touch, which is the first instant the fresh base is readable: emit the
        // zero-fee collection that anchors it. Every re-base is thereby bracketed — the exit's own
        // sync collected everything in the old base, nothing accrues while empty, and this baseline
        // opens the new base — so settlement never meets two growth readings it cannot compare, and
        // the epoch a backlog is credited to can never depend on when a stranger forces a collection.
        if (recreated) LedgerLib.emitRebaseBaseline(_ranges, _rangeKeys, poolManager, id);
        emit Deposited(msg.sender, id, liquidity);
        // LAST, after every state write and event (unlike the AlphixETH precedent, which refunded
        // mid-function): the refund hands control to the caller, and by now there is nothing left
        // for reentrant code to observe torn — and `nonReentrant` (transient) blocks re-entry into
        // every ledger door regardless.
        if (key.currency0.isAddressZero()) _refundNative();
    }

    /// @dev Refunds EXACTLY this caller's unspent remainder: the balance delta across the call,
    ///      which is `msg.value - spent`. Any balance that was already here is left untouched.
    ///
    ///      Two weaker forms were tried and both failed, so the reasoning is recorded rather than
    ///      re-derived. Refunding `address(this).balance` outright handed a parked balance to the
    ///      next depositor. Refunding `min(balance, msg.value)` looked like it fixed that, and does
    ///      not: it bounds what the REFUND pays out, but not what the SETTLE spends.
    ///      `LedgerLib._resolvePrincipal` pays the currency0 leg with `poolManager.settle{value:
    ///      owed}` out of the hook's COMMINGLED balance, so with a park P >= owed the post-settle
    ///      balance is still >= `msg.value` and the depositor is refunded in full while P paid for
    ///      their position. Six of the twelve round-3 lenses found this independently; measured, a
    ///      stranger drained an entire 0.0296-ETH park at zero net cost and converted it with a
    ///      follow-up `withdraw`.
    ///
    ///      The same form also left half the grief open. It closes the `msg.value == 0` shape (a
    ///      band below spot owes no currency0), but a caller who pays EXACTLY — `msg.value ==
    ///      owed` — should be refunded nothing and was instead refunded the park, so one
    ///      force-sent wei still reverted a non-payable integrator. The delta form returns zero in
    ///      both cases.
    ///
    ///      This DELIBERATELY ends the "force-sent dust returns to circulation" behaviour. The
    ///      hook cannot distinguish a stranger's donation from a victim's mis-addressed principal,
    ///      and recirculation is the mechanism that hands the second one out — so the trade is
    ///      made explicitly here: dust strands, and principal is safe FROM RECIRCULATION.
    ///
    ///      NOT "principal is safe" flatly, which is what this said. `_checkPayoutTarget` only
    ///      refuses `address(this)`, which is instance-scoped, while every native hook shares one
    ///      PoolManager-allowlisted `receive()` on the SAME PoolManager — so bounding by the delta
    ///      closes the sibling-hook RECIRCULATION race (a stranger claiming the parked ETH) and NOT
    ///      the LOSS: principal a user mis-addresses to a sibling native hook is as unrecoverable as
    ///      the `address(this)` case, because that hook has no rescue and its own `_refundNative` is
    ///      delta-bounded and never pays out a pre-existing balance. Closing THAT needs a registry or
    ///      a `weth()`-shaped probe on `to`, and both were rejected: it is self-inflicted only
    ///      (nobody sets another user's `to`), a probe puts an external call on the one path whose
    ///      founding constraint is that it is unconditional, and a registry is admin-written state
    ///      read on the withdrawal path, which "no admin state can BLOCK the path" forbids outright.
    ///      Naming it is the resolution; see `_checkPayoutTarget`'s inventory.
    ///
    ///      Full-gas call, hard revert on failure: a caller that cannot receive ETH must not be
    ///      able to leave its own overpayment behind.
    // The destination is literally msg.sender, the sole caller is `deposit` (nonReentrant), the
    // call is the last statement after every state write, and the amount is a measured DELTA — so
    // it can only ever return the caller's own overpayment, never a park. See DECISIONS D11.
    // slither-disable-next-line arbitrary-send-eth
    function _refundNative() internal {
        uint256 pre = _foreignNative();
        uint256 balance = address(this).balance;
        uint256 refund = balance > pre ? balance - pre : 0;
        if (refund == 0) return;
        (bool success,) = msg.sender.call{value: refund}("");
        if (!success) revert RefundFailed();
    }

    /// @dev Transient slot holding the hook's pre-existing native balance for one `deposit`.
    ///      Transient storage clears at end of transaction, so it cannot leak between calls, and
    ///      it costs no stack.
    bytes32 private constant _FOREIGN_NATIVE_SLOT = keccak256("fables.ledger.foreignNative");

    function _setForeignNative(uint256 value) private {
        bytes32 slot = _FOREIGN_NATIVE_SLOT;
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }

    function _foreignNative() private view returns (uint256 value) {
        bytes32 slot = _FOREIGN_NATIVE_SLOT;
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }

    /// @notice Burns receipts and removes the corresponding liquidity to the caller. Cannot be
    ///         BLOCKED by admin state; auto-unstakes if the unstaked balance is insufficient.
    /// @dev "Reads no admin state" is what this line used to say, and the contract header records
    ///      that sentence as the defect it corrected — it DOES read three admin-written values
    ///      (`claimFeeRecipient` and the per-pool rate in `_poolClaimFee`, and `maxFee[poolId]` in
    ///      `_checkKey`). The correction landed in the header, the storage declaration and
    ///      `withdrawAndClaim`, but not here, on the published userdoc an integrator actually reads.
    ///      The distinction matters because the flat claim is what lets a reader conclude the
    ///      one-way `claimFeeRecipient` guard and `claimFeeFor`'s min-over-window are not load-
    ///      bearing on this path. What is true, and what the exit guarantee rests on, is that none
    ///      of those three can REFUSE the withdrawal — only re-size the fee credit alongside it.
    /// @dev Fees are COLLECTED first via `_syncRange` — a claims-only touch that makes no token
    ///      call — so the withdrawer's cut is credited at pre-burn totals. CREDITED, not paid: this
    ///      function moves principal only, and the fee balance is drawn by `claimFees` (or in one
    ///      call by `withdrawAndClaim`). This block used to say the withdrawer "receives their cut",
    ///      which is the misreading `withdrawAndClaim` was added to answer, and it was left standing
    ///      when that function landed. Shares
    ///      are burned before the pool touch that pays principal, so the only step that can
    ///      hand control to a token sees `totalShares` and position liquidity already in
    ///      agreement. Over-withdrawing still reverts, now at `_burn`, before anything moves.
    /// @param to Where the principal lands. `claimFees` already takes one so a holder can route
    ///        around a token that blocks their own address; `withdraw` hardcoded `msg.sender`,
    ///        which meant a blocklist on the LP froze their principal in BOTH currencies — and
    ///        the documented escape (transfer the receipt to a clean address) is pausable, so a
    ///        pause concurrent with a blocklist closed every exit. That contradicted this
    ///        contract's headline guarantee that withdrawals are unconditional.
    /// @param amount0Min The least currency0 the caller will accept back for this liquidity.
    /// @param amount1Min The least currency1 the caller will accept back for this liquidity.
    /// @param deadline Latest block timestamp at which this withdrawal may execute.
    /// @dev The mirror of `deposit`'s ceiling. A liquidity figure does not say what mix it returns —
    ///      the price decides — so an exit during a moved market handed back a lopsided pair the LP
    ///      never consented to. Deliberately still NOT pausable: a bound the caller chose is not a
    ///      reason to trap them, and passing zeroes remains a valid "any mix will do".
    // State is written after `_syncRange` -> poolManager.unlock, which Slither reads as
    // reentrancy. Every one of these paths carries OZ's ReentrancyGuardTransient, whose
    // tstore-based guard Slither does not model. Proven rather than asserted by
    // test_reentrancyGuardStopsAReEntryMidCallback, which re-enters from a hostile token's
    // transferFrom mid-callback and asserts the revert is ReentrancyGuardReentrantCall.
    // slither-disable-next-line reentrancy-no-eth
    function withdraw(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        uint128 amount0Min,
        uint128 amount1Min,
        uint256 deadline
    ) external nonReentrant {
        _withdrawTo(key, tickLower, tickUpper, liquidity, to, amount0Min, amount1Min, deadline);
    }

    /// @notice Withdraw principal AND pay out the fees the caller has accrued, in one call.
    /// @dev WHY THIS IS A SEPARATE FUNCTION AND NOT A CHANGE TO `withdraw`. `withdraw` is the one
    ///      FUND-MOVING entry point in this contract with no pause modifier (`unstake` and
    ///      `syncRanges` also carry none, deliberately, and each says so at its own definition — this
    ///      line used to claim it was the only one at all): an LP can always get their
    ///      principal out, whatever the admin has done. Folding a fee payout into it would make
    ///      that guarantee conditional on a transfer it does not otherwise need. An out-of-range
    ///      position settles only ONE currency (`_resolvePrincipal` skips a zero amount), while
    ///      fees can be owed in BOTH — so the fold would add a transfer in a token the withdrawal
    ///      never touches, and these are tokenized equities and a regulated stablecoin, the asset
    ///      class that actually ships blocklists and transfer-agent freezes. The LPs most exposed
    ///      would be exactly the ones this convenience is for: people who move ranges often, i.e.
    ///      people whose price has left the range.
    ///
    ///      So the two guarantees are kept apart. `withdraw` is unconditional and always will be.
    ///      THIS function is the convenience path, and it CAN revert where `withdraw` cannot — on
    ///      the `maxFeeBps` bound below, on the pause, or on a fee-leg transfer. Principal is never
    ///      stranded: `withdraw` always works, and `claimFees` explicitly serves a holder whose
    ///      shares are gone but whose `owed` is not.
    ///
    ///      ONE THING `withdraw` IS NOT, and an earlier version of this comment got it wrong:
    ///      it is not an escape from the claim-fee rate. `withdraw` runs `_syncRange` like every
    ///      other door, and that sync takes the claim-fee cut at whatever rate the range's snapshot
    ///      stands at — with no `maxFeeBps` to refuse it. So a caller who refuses a rate here and
    ///      then withdraws pays exactly the rate they refused. That is not a hole to plug: v4 hands
    ///      back accrued fees on EVERY `modifyLiquidity`, so there is no withdrawal that does not
    ///      collect, and a bound on `withdraw` could therefore only ever block an exit — which
    ///      inverts the one priority this contract will not trade. What bounds the exposure instead
    ///      is that the rate can only ever FALL over a given backlog: `claimFeeFor` bills the minimum
    ///      advertised across the range's own window, so `effectiveClaimFee(id)` is a hard ceiling
    ///      on what THIS withdrawal will pay.
    ///
    ///      NOT MONOTONE ACROSS TIME, and that changed this round. `_effectiveClaimFee` now returns
    ///      0 for a FULLY STAKED range, because `_split` skips the skim entirely there — so any
    ///      other holder's `unstake` restores the taxable base and the next reading RISES. Every
    ///      guarantee the two consent guards rest on holds within a single call, which is all they
    ///      need; a keeper caching the reading across blocks on the old monotonicity would be wrong.
    /// @dev WHAT EACH KIND OF LP GETS, since the three differ and the difference is the point:
    ///      - An UNSTAKED Fables LP receives their principal plus their accrued fees, already net
    ///        of the claim fee. That cut was taken at accrual, at the rate in force when the range
    ///        was last synced, so this pays what is owed and never re-charges.
    ///      - A STAKED Fables LP gets exactly what a plain `withdraw` gives them. Their fees went
    ///        to the distributor when they accrued — that is the trade they took in exchange for
    ///        emissions — so `owed0`/`owed1` hold only the unstaked slice, and for a fully staked
    ///        position that is zero. This function does NOT revert in that case; it simply pays
    ///        nothing extra, which is why the payout below is guarded rather than asserted.
    ///      - A vanilla Uniswap LP never reaches this contract at all.
    /// @dev PAUSABLE, and that is the whole point of the modifier. This function pays fees, and a
    ///      fee payout is exactly what the freeze exists to stop — the pause's own NatSpec says it
    ///      "freezes deposits, claims, staking, transfers and sweeps". Composing an unpausable
    ///      principal path with a pausable fee path inherits NEITHER guard unless one is written
    ///      here, and without it any holder drained their whole `owed` mid-incident for the price
    ///      of burning ONE liquidity unit. The asymmetry that made it worse than a nicety: the two
    ///      sweeps' PERMISSIONLESS doors are pause-gated, so during a freeze nobody outside could
    ///      move protocol revenue while every LP could still pull theirs. (`_settleSinks` is the
    ///      deliberate exception: it calls the INTERNAL sweeps, which carry no pause check, so an
    ///      admin rotating a sink still settles the outgoing one during a freeze — rotation has to
    ///      stay deterministic, which is the whole reason `_settleSinks` exists. It is not a door
    ///      anyone else can open.) And `_payout` burns the hook's ERC-6909
    ///      claims, which are keyed by CURRENCY and shared across every pool on the singleton, so
    ///      a drain in a contained pool drew down the claims backing the others. Eleven independent
    ///      audit lenses reported this; do not remove the modifier on the grounds that `withdraw`
    ///      does not carry one. `withdraw` moves no fees.
    /// @param maxFeeBps The highest claim-fee rate the caller will accept, mirroring `claimFees`.
    ///        Pass 10_000 to opt out of the bound entirely.
    function withdrawAndClaim(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        uint128 amount0Min,
        uint128 amount1Min,
        uint256 deadline,
        uint16 maxFeeBps
    ) external nonReentrant whenPoolNotPaused(key.toId()) {
        // Checked BEFORE the withdrawal's own `_syncRange`, exactly as `claimFees` checks it before
        // its sync: the rate that will be charged is the range's snapshot, and consenting to it
        // after the fact is not consent. This is the one place this function is stricter than
        // `withdraw`, and the NatSpec above says why that is acceptable here and would not be there.
        //
        // ONE CONSEQUENCE OF THE PAUSE MODIFIER, stated so nobody later "fixes" it the wrong way.
        // The modifier fires before this check, so during a freeze the bound is unreachable and the
        // only exit is `withdraw` — which has no bound and still runs the claim-fee skim, because
        // `LedgerLib._onModify` credits fees unconditionally: the collection IS the
        // `modifyLiquidity`, not the `_syncRange` before it. So a freeze can cost an LP the option
        // of waiting for a rate cut. That is not a regression and it is not a reason to bound
        // `withdraw`: the skim happens on collection whichever door is used, `effectiveClaimFee` is
        // a min-over-window that can only fall and is capped by `MAX_CLAIM_FEE_BPS`, a pause is
        // bounded by `MAX_PAUSE`, and the LP can simply wait it out and use the bounded door.
        // Bounding `withdraw` would instead make principal exit refusable, which is the founding
        // constraint this whole file is built around.
        //
        // Note the option IS exclusively the LP's during a freeze, unlike in normal operation
        // where any stranger's one-unit `deposit` forces the sync and closes the window: `deposit`
        // is itself `whenPoolNotPaused`, so while a pool is frozen only the holder's own
        // `withdraw`/`unstake` — or a voter-gated `syncRanges` on a staked range — can force it.
        // That makes the freeze the one moment the timing is theirs alone, which strengthens the
        // case for gating the bounded door rather than weakening it.
        uint256 id = rangeId(key.toId(), tickLower, tickUpper);
        if (_effectiveClaimFee(id) > maxFeeBps) revert ClaimFeeAboveMax();

        // Principal first, fees second, and the order is load-bearing. `_withdrawTo` runs
        // `_syncRange` + `_settleUser`, so by the time it returns, `owed0`/`owed1` already hold
        // everything this holder earned right up to this block — including the fees collected by
        // the withdrawal's own touch. Claiming first would leave that last slice unpaid.
        _withdrawTo(key, tickLower, tickUpper, liquidity, to, amount0Min, amount1Min, deadline);

        UserPosition storage position = _positions[id][msg.sender];
        (uint256 amount0, uint256 amount1) = (position.owed0, position.owed1);
        if (amount0 == 0 && amount1 == 0) return; // fully staked, or nothing accrued: not an error
        (position.owed0, position.owed1) = (0, 0);
        // No cut here: it was taken at accrual. Same as `claimFees`.
        _payout(key.currency0, key.currency1, amount0, amount1, to);
        emit FeesClaimed(msg.sender, id, amount0, amount1);
    }

    /// @dev The body of `withdraw`, extracted so `withdrawAndClaim` can compose it. Both callers
    ///      are `nonReentrant`, and OpenZeppelin's transient guard cannot be re-entered from
    ///      within itself, so one external entry point cannot call the other — hence the split.
    ///      Behaviour is unchanged from when this was `withdraw`'s body.
    function _withdrawTo(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        uint128 amount0Min,
        uint128 amount1Min,
        uint256 deadline
    ) internal {
        if (liquidity == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();
        _checkPayoutTarget(to);
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) revert DeadlineExpired();
        _checkKey(key);
        uint256 id = rangeId(key.toId(), tickLower, tickUpper);

        _syncRange(id);
        _settleUser(id, msg.sender);

        UserPosition storage position = _positions[id][msg.sender];
        // balances are sums of uint128 liquidity mints, bounded by pool max liquidity
        // forge-lint: disable-next-line(unsafe-typecast)
        uint128 unstaked = uint128(balanceOf[msg.sender][id]) - position.staked;
        if (unstaked < liquidity) {
            uint128 fromStaked = liquidity - unstaked;
            position.staked -= fromStaked; // reverts on underflow: not enough total shares
            _ranges[id].totalStaked -= fromStaked;
            emit Unstaked(msg.sender, id, fromStaked);
        }
        _burn(msg.sender, id, liquidity);
        _ranges[id].totalShares -= liquidity;
        // Crossing DOWN to zero empties the position, clearing its ticks and re-basing
        // `feeGrowthInside`. Bumped BEFORE the pool touch so the collection it may trigger carries
        // the new value (H2), pairing with the up-crossing bump in `deposit`. No baseline emission
        // here, deliberately: the ticks are about to be cleared, so a reading taken now describes a
        // base no future collection will ever be in — the anchor worth having is the refill's, and
        // `deposit` emits it. Nothing accrues while the position is empty, so the seam carries no value.
        if (_ranges[id].totalShares == 0) _ranges[id].resetSeq += 1;
        _modify(key, tickLower, tickUpper, -int256(uint256(liquidity)), to, amount0Min, amount1Min);
        emit Withdrawn(msg.sender, id, liquidity);
    }

    /// @notice Syncs the range's fees from the pool and pays the caller's accrued share, minus
    ///         the claim fee (fees only — principal is never touched).
    /// @param to Recipient of the fees; lets a holder route around a token that blocks their
    ///        own address without stranding the other currency.
    // State is written after `_syncRange` -> poolManager.unlock, which Slither reads as
    // reentrancy. Every one of these paths carries OZ's ReentrancyGuardTransient, whose
    // tstore-based guard Slither does not model. Proven rather than asserted by
    // test_reentrancyGuardStopsAReEntryMidCallback, which re-enters from a hostile token's
    // transferFrom mid-callback and asserts the revert is ReentrancyGuardReentrantCall.
    // slither-disable-next-line reentrancy-no-eth
    function claimFees(PoolKey calldata key, int24 tickLower, int24 tickUpper, address to, uint16 maxFeeBps)
        external
        nonReentrant
        whenPoolNotPaused(key.toId())
    {
        // Mirrors `withdraw`. On an ERC20 pool a zero recipient reverts inside the token; on a
        // NATIVE pool v4's transfer is a bare `call`, which SUCCEEDS against address(0) and destroys
        // the fees after this function has already zeroed what was owed. Same input, opposite
        // outcome by currency type, and the silent one is the unrecoverable one.
        if (to == address(0)) revert ZeroAddress();
        _checkPayoutTarget(to);
        // The rate the caller is willing to pay. Uniswap v4 accrues fees lazily, so the hook
        // only learns of them when a ledger operation syncs the range — which means the rate
        // applied is whatever stands at sync time, and an LP whose range has been quiet since
        // before a `setClaimFee` would otherwise pay the new rate on the whole backlog. Taking
        // the cut at accrual bounds that window to the last sync; this bounds it to consent.
        // Checks the rate this call will actually charge — the range's snapshot — not the live
        // rate. Comparing against `claimFeeBps` once the charge moved to the snapshot made the
        // guard read one variable and the skim another, so it permitted exactly the skims it was
        // meant to block (snapshot high, live zero) and reverted claims that would have cost
        // nothing (snapshot zero, live high).
        _checkKey(key);
        uint256 id = rangeId(key.toId(), tickLower, tickUpper);
        if (_effectiveClaimFee(id) > maxFeeBps) revert ClaimFeeAboveMax();
        // Third free-sync door, same shape as the zero-amount ones closed on stake/unstake and
        // transfer: an address with no position here still reached `_syncRange` before hitting
        // the `owed == 0` exit, letting a stranger force a range's rate snapshot forward. A
        // holder who has withdrawn but still has unclaimed fees must remain able to claim, so
        // the test is "has shares OR is owed something", not "has shares".
        UserPosition storage claimant = _positions[id][msg.sender];
        if (balanceOf[msg.sender][id] == 0 && claimant.owed0 == 0 && claimant.owed1 == 0) {
            revert NothingToClaim();
        }
        _syncRange(id);
        _settleUser(id, msg.sender);

        UserPosition storage position = _positions[id][msg.sender];
        (uint256 amount0, uint256 amount1) = (position.owed0, position.owed1);
        if (amount0 == 0 && amount1 == 0) return;
        (position.owed0, position.owed1) = (0, 0);

        // No cut here: it was already taken at accrual, at the rate in force when the range was
        // last synced, so a later change cannot reach back into what is already owed.
        _payout(key.currency0, key.currency1, amount0, amount1, to);
        emit FeesClaimed(msg.sender, id, amount0, amount1);
    }

    /// @notice Stakes receipts: their future fee accrual routes to the distributor.
    // State is written after `_syncRange` -> poolManager.unlock, which Slither reads as
    // reentrancy. Every one of these paths carries OZ's ReentrancyGuardTransient, whose
    // tstore-based guard Slither does not model. Proven rather than asserted by
    // test_reentrancyGuardStopsAReEntryMidCallback, which re-enters from a hostile token's
    // transferFrom mid-callback and asserts the revert is ReentrancyGuardReentrantCall.
    // slither-disable-next-line reentrancy-no-eth
    function stake(PoolKey calldata key, int24 tickLower, int24 tickUpper, uint128 shares, uint256 minGaugeWeight)
        external
        nonReentrant
        whenPoolNotPaused(key.toId())
    {
        if (shares == 0) revert ZeroShares();
        _checkKey(key);
        // A desk that is not a LIVE gauge — killed, retired, or never added at all — has no voters
        // and earns no emissions, so forgoing fees to it buys nothing and strands the money: it
        // reaches the distributor with nobody entitled to claim it and sits there until the release
        // window 26 weeks later. `isGaugeLive` folds the class check together with the kill/retire
        // state: a never-gauged pool reads class NONE while `isGaugeKilled` alone returns false (the
        // LIVE default of an empty history), so the kill check by itself lets a stake strand into a
        // pool that was configured on the hook but never gauged — the exact gap FablesBribes closes
        // with `gaugeClass != NONE`. Staking is the only side that closes — unstaking, withdrawing,
        // claiming and ordinary LPing all stay open, because a wind-down must never trap anyone.
        // `isGaugeEarning`, not `isGaugeLive`. The comment above states the condition this guard is
        // for — "has no voters and earns no emissions, so forgoing fees to it buys nothing and
        // strands the money" — and `isGaugeLive` never tested the voters half of it: it is class +
        // kill state only. A LIVE, never-killed desk with no ballot pointed at it earns `_shareOf`
        // exactly zero while its stakers' fees are still swept to the distributor and booked to the
        // treasury, silently and indefinitely. `isGaugeEarning` adds the missing term.
        // FAILS CLOSED. An unset `ballotGate` used to make this guard a no-op, which is not only a
        // genesis condition: `ballotGate` is per-LEDGER, so every hook added to a running protocol
        // has its own, and between the new pool becoming depositable (`initialize` is permissionless)
        // and `setBallotGate` landing behind its config delay, staking was accepted on a desk with no
        // gauge at all. Fees swept, nothing earned, nobody told. Staking before the gate is wired
        // could never earn anyway — `_shareOf` needs a gauge — so refusing costs nothing real and
        // removes a window whose length is set by a multisig delay.
        address gate = ballotGate;
        if (gate == address(0) || !IBallotGate(gate).isGaugeEarning(key.toId())) revert DeskRetired();
        // THE CONSENT BOUND, and the reason the boolean above is not enough on its own.
        //
        // `isGaugeEarning` asks "is a ballot pointed here", and any address can make that true for
        // ONE WEI: `createPermanentLock(1)` books `bias = 1 * MAX_LOCK` with `slope == 0`, which
        // satisfies `bias > t * slope` forever. The two halves of the staker's trade then use
        // different denominators — the fees they give up are split among THIS desk's voters, so
        // the lone dust voter takes ~100% of them, while the emissions they receive are sized by
        // the desk's share of the GLOBAL vote, which rounds to zero. The gate's own NatSpec says it
        // exists to stop a staker "forgoing fees to it buys nothing"; a dust ballot satisfies the
        // gate and produces exactly that outcome, with the nominal voter collecting the proceeds.
        //
        // Fixed with a caller-supplied bound rather than a protocol-wide floor, deliberately. A
        // protocol floor needs either a magic constant — arbitrary, and wrong for some desk — or a
        // cross-gauge sum, which is gas every staker pays forever to protect a party who can state
        // their own terms in one argument. `claimFees` already establishes exactly this pattern
        // with `maxFeeBps`: the caller names the worst price they accept and the contract enforces
        // it. `0` means "no opinion" and preserves the old behaviour, the same way
        // `maxFeeBps = 10_000` opts out of the claim-fee bound today.
        //
        // Bounded on WEIGHT, not on emission share: share needs the epoch's global total, which is
        // only meaningful against a fully checkpointed frontier and would make this revert for
        // every desk at the start of every epoch. Weight is the same quantity `_shareOf` divides,
        // it is O(1) from two slots the gate already touches, and the caller compares it against a
        // total they can read off-chain.
        //
        // THAT CLAIM WAS ONCE FALSE OF THIS VERY LINE, which is worth recording because the fix
        // lives in another contract. `gaugeWeightNow` used to refuse to answer past its own
        // frontier's week — returning 0 rather than a stale number — so a bounded stake reverted
        // `DeskBelowMinWeight` on a FULLY BACKED desk for the whole pre-checkpoint part of every
        // epoch: exactly the fail-shut this paragraph says weight was chosen to avoid. The gate
        // now returns a CONSERVATIVE LOWER BOUND instead, and that is what makes this bound sound
        // in both directions: an un-applied expiry can only make the reading too LOW, so a stale
        // gauge can refuse a stake the caller would have accepted, never admit one into a desk
        // weaker than they demanded. See `FablesVoter.gaugeWeightNow`.
        //
        // The reading is therefore a floor, not a quote: `minGaugeWeight` says "refuse unless the
        // desk is at least this strong", and a desk that is stronger than it looks is still
        // refused. That direction is the caller's protection, so it is the right one to keep.
        //
        // ENTRY ONLY, and that is a real limit rather than an oversight: nothing re-checks it, so
        // an LP whose desk loses its backers later keeps forfeiting fees until they `unstake` —
        // which is always available and never pausable. Re-validating on every collection would put
        // a cross-contract call on the hot path of every swap-adjacent sync. The signal belongs in
        // the app. `Staked` does NOT carry the weight — it is `(owner, rangeId, shares)` — so an
        // indexer raising that signal must read `IBallotGate.gaugeWeightNow(poolId)` itself — and
        // `Staked` carries `rangeId`, not `poolId`, so it must go through `rangeKey(id)` first. This
        // line claimed the event carried it, which made the only stated mitigation for a deliberate
        // design gap point at a field that does not exist.
        // Called ONLY when a bound is set. `minGaugeWeight` is a parameter, not storage, so an
        // unconditional call would make every staker on every pool depend on a gate member that
        // nothing had checked exists — which is exactly the silent-brick class `setBallotGate`'s
        // probe was built for, and which an unconditional first cut of this line re-opened.
        // Skipping the call at zero also keeps the no-opinion path at its old gas.
        if (minGaugeWeight != 0 && IBallotGate(gate).gaugeWeightNow(key.toId()) < minGaugeWeight) {
            revert DeskBelowMinWeight();
        }
        uint256 id = rangeId(key.toId(), tickLower, tickUpper);
        _syncRange(id); // fees earned before this stake stay with their earner
        _settleUser(id, msg.sender);
        UserPosition storage position = _positions[id][msg.sender];
        if (uint128(balanceOf[msg.sender][id]) - position.staked < shares) revert InsufficientUnstakedShares();
        position.staked += shares;
        _ranges[id].totalStaked += shares;
        emit Staked(msg.sender, id, shares);
    }

    /// @notice Unstakes receipts; permissionless, instant, dependency-free.
    /// @dev Deliberately NOT pausable, unlike `stake`. Unstaking only ever SHRINKS what the
    ///      distributor is owed and makes no external call, so it cannot be an exploit vector —
    ///      while pausing it would mean an LP cannot stop routing their fees to a distributor
    ///      the admin also chooses. Freezing the exit from a revenue assignment is not an
    ///      exploit response, it is the exploit.
    // State is written after `_syncRange` -> poolManager.unlock, which Slither reads as
    // reentrancy. Every one of these paths carries OZ's ReentrancyGuardTransient, whose
    // tstore-based guard Slither does not model. Proven rather than asserted by
    // test_reentrancyGuardStopsAReEntryMidCallback, which re-enters from a hostile token's
    // transferFrom mid-callback and asserts the revert is ReentrancyGuardReentrantCall.
    // slither-disable-next-line reentrancy-no-eth
    function unstake(PoolKey calldata key, int24 tickLower, int24 tickUpper, uint128 shares) external nonReentrant {
        // A zero-share call did real work: it forced a full fee sync for free, from any address,
        // with no balance and no approval, and is not pausable. That was the cheapest trigger for
        // the claim-fee raid, and it also let anyone spam the Staked/Unstaked stream the
        // settlement indexer reads.
        if (shares == 0) revert ZeroShares();
        _checkKey(key);
        uint256 id = rangeId(key.toId(), tickLower, tickUpper);
        _syncRange(id); // fees owed to the distributor are banked before the stake shrinks
        _settleUser(id, msg.sender);
        UserPosition storage position = _positions[id][msg.sender];
        position.staked -= shares; // reverts on underflow
        _ranges[id].totalStaked -= shares;
        emit Unstaked(msg.sender, id, shares);
    }

    /// @notice Pushes accumulated staked-share fees to the distributor. Callable by anyone.
    function sweepDistributor(Currency currency) external nonReentrant whenNotPaused {
        _sweepDistributor(currency);
    }

    /// @dev A thin wrapper over `LedgerLib.sweepDistributor` (inlined).
    ///      FF-denominated staked-fee revenue does NOT go to the epoch distributor — which treats
    ///      every FF it holds as the emission tranche, where fee revenue would strand — but to the
    ///      dedicated `ffFeeSink`; both destinations are resolved inside the library, and an unset
    ///      one simply keeps the accrual waiting. Virtual because the distributor speaks only
    ///      ERC20: the native-capable hook overrides the NATIVE currency's sweep to wrap into WETH
    ///      at this boundary, so everything downstream stays ERC20-pure.
    function _sweepDistributor(Currency currency) internal virtual {
        LedgerLib.sweepDistributor(distributorOwed, poolManager, currency, distributor, distributorFF, ffFeeSink);
    }

    /* ---------------------------------- transfers ---------------------------------- */

    /// @dev Staked shares are locked: only the unstaked balance is transferable.
    function transfer(address receiver, uint256 id, uint256 amount)
        public
        override
        nonReentrant
        whenRangeNotPaused(id)
        returns (bool)
    {
        // Same free, permissionless fee-sync primitive that was closed on stake/unstake: a
        // zero-amount transfer needs no balance and no approval, moves nothing, and still forces
        // a full unlock + modifyLiquidity round trip against any range.
        if (amount == 0) revert ZeroShares();
        _checkTransferable(msg.sender, id, amount);
        _syncRange(id); // the sender keeps the fees their shares already earned
        _settleUser(id, msg.sender);
        _settleUser(id, receiver);
        return super.transfer(receiver, id, amount);
    }

    function transferFrom(address sender, address receiver, uint256 id, uint256 amount)
        public
        override
        nonReentrant
        whenRangeNotPaused(id)
        returns (bool)
    {
        // Same free, permissionless fee-sync primitive that was closed on stake/unstake: a
        // zero-amount transfer needs no balance and no approval, moves nothing, and still forces
        // a full unlock + modifyLiquidity round trip against any range.
        if (amount == 0) revert ZeroShares();
        _checkTransferable(sender, id, amount);
        _syncRange(id); // the sender keeps the fees their shares already earned
        _settleUser(id, sender);
        _settleUser(id, receiver);
        // `sender` is not `msg.sender` BY DESIGN: this IS ERC-6909's delegated transfer, and the
        // authorization lives one frame down. v4-core's `ERC6909.transferFrom` accepts only
        // `msg.sender == sender`, `isOperator[sender][msg.sender]`, or a checked
        // `allowance[sender][msg.sender][id] -= amount` that reverts on underflow — and this
        // contract overrides none of `approve`, `setOperator`, `isOperator`, `allowance`. The
        // rule's premise (an arbitrary `from` with no allowance check) is therefore absent, and
        // these are the hook's OWN receipt shares, not an external ERC-20 balance. Verified by
        // attacking it three ways — no approval, one wei over the allowance, and a self-appointed
        // operator — each refused, with positive controls proving the fixture could have succeeded.
        // nosemgrep: solidity.security.arbitrary-send-erc20.arbitrary-send-erc20
        return super.transferFrom(sender, receiver, id, amount);
    }

    function _checkTransferable(address owner, uint256 id, uint256 amount) internal view {
        if (balanceOf[owner][id] - _positions[id][owner].staked < amount) revert InsufficientUnstakedShares();
    }

    /* ---------------------------------- internals ---------------------------------- */

    // `Action`, `CallbackData` and `PayoutData` now live in `LedgerTypes.sol` (shared with
    // `LedgerLib.onUnlock`, which holds the unlock-callback body).

    function _modify(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta,
        address user,
        uint128 amount0Limit,
        uint128 amount1Limit
    ) internal {
        _modifyMem(key, tickLower, tickUpper, liquidityDelta, user, amount0Limit, amount1Limit);
    }

    function _modifyMem(
        PoolKey memory key,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta,
        address user,
        uint128 amount0Limit,
        uint128 amount1Limit
    ) internal {
        poolManager.unlock(
            abi.encode(
                Action.MODIFY,
                abi.encode(CallbackData(key, tickLower, tickUpper, liquidityDelta, user, amount0Limit, amount1Limit))
            )
        );
    }

    /// @dev Burns the ledger's claims and pays `to` in real tokens, via `LedgerLib.payout`
    ///      (inlined). A failure here (paused or blocklisted token, blocked recipient) affects
    ///      only this claim, never principal.
    function _payout(Currency currency0, Currency currency1, uint256 amount0, uint256 amount1, address to) internal {
        LedgerLib.payout(poolManager, currency0, currency1, amount0, amount1, to);
    }

    /// @inheritdoc IUnlockCallback
    /// @dev A thin shell: it checks the caller and hands the whole callback body to
    ///      `LedgerLib.onUnlock` (inlined), which decodes the action, applies a liquidity
    ///      modify or a payout, and settles fees and principal.
    function unlockCallback(bytes calldata rawData) external returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        return LedgerLib.onUnlock(
            _ranges,
            _rangeKeys,
            distributorOwed,
            claimFeeOwed,
            claimFeeSyncIndex,
            _poolClaimFee,
            poolManager,
            LedgerLib.ClaimFeeState({recipient: claimFeeRecipient}),
            rawData
        );
    }

    /// @dev The whole fee collection — claim-fee rate roll-forward, the claim mints, the staked /
    ///      unstaked split, the claim-fee skim and the `FeesCollected` emit — lives in
    ///      `LedgerLib.creditFees` (inlined), which mutates this contract's own storage
    ///      (mappings passed by reference). Behaviour is identical.
    function _creditFees(uint256 id, PoolKey memory key, uint128 fee0, uint128 fee1) internal {
        LedgerLib.creditFees(
            _ranges,
            _rangeKeys,
            distributorOwed,
            claimFeeOwed,
            claimFeeSyncIndex,
            _poolClaimFee,
            poolManager,
            LedgerLib.CreditParams({id: id, key: key, fee0: fee0, fee1: fee1, claimFeeRecipient: claimFeeRecipient})
        );
    }

    /// @notice Realizes v4's lazily-accrued fees for a list of ranges, splitting each between its
    ///         unstaked holders and the voters' pot. Callable only by a VOTER of the pool, on the
    ///         strength of a lock they own; unpausable, and it
    ///         moves no tokens out of this contract — it only turns fees the pool already holds
    ///         into balances this ledger has attributed.
    /// @dev Settlement needs this. v4 pays nothing until a position is touched, and a `rangeId`
    ///      is `(pool, tickLower, tickUpper)`, so an LP on bespoke bounds is the ONLY party who
    ///      can touch their range. Staked shares give their fees up to voters, which left
    ///      voters' revenue hostage to whether the LP who forgoes it ever felt like syncing —
    ///      and left each epoch's emission split guessing at fees that had not been booked yet.
    ///      Ops calls this over the staked ranges at each epoch boundary, which is also what
    ///      makes the `FeesCollected` accumulator levels line up with epoch boundaries so the
    ///      week's forgone fees are attributable exactly.
    /// @dev It takes the claim fee like every other door, and it must. An earlier version skipped
    ///      the skim here on the grounds that "the protocol forgoes its claim fee on syncs it did
    ///      not initiate — it still collects on every owner-driven path". The second clause was
    ///      false. v4 pays nothing until a position is touched, so an owner-driven sync can only
    ///      ever skim fees accrued SINCE THE LAST TOUCH — and a free door that collects the whole
    ///      backlog sets that to nothing. Whoever touches a range last wins, so any voter of the
    ///      pool could hold the protocol's revenue on every staked range in it at zero forever,
    ///      for gas, by sweeping just before each owner claim. Charging uniformly is the only
    ///      shape with no door to arbitrage between.
    ///
    ///      It costs the caller nothing they are owed: the skim is taken from the UNSTAKED
    ///      residue, after `stakedCut` has already been set aside for the voters' pot. A voter
    ///      syncing to fund their own claim is not paying for the privilege.
    ///
    ///      The rate is still `min(live, snapshot)`, so a raise can never reach back over a
    ///      backlog earned under the old rate — which was the other thing the exemption was
    ///      protecting, and is protected here by `_effectiveClaimFee` instead of by a hole.
    /// @dev SCOPE, stated because four of the twelve round-2 lenses stopped here and one wrote a
    ///      passing PoC. This gate does NOT make the epoch-attribution choice exclusive to voters,
    ///      and nothing in this contract could: `deposit(key, tl, tu, 1, max, max, deadline)`
    ///      reaches the identical `_syncRange(id)` on the identical range for one liquidity unit,
    ///      with no gauge, ledger or ballot requirement — as does the range holder's own
    ///      `withdraw`/`claimFees`. So the timing power is public, and this gate restricts only
    ///      third-party pokes of ranges the caller has no position in.
    ///
    ///      Left as-is on purpose rather than tightened or dropped. Tightening (gating
    ///      `_syncRange` itself when a range has staked shares) would refuse a first-time
    ///      depositor into that range, which is a real user and not the threat. Dropping the gate
    ///      is a LOOSENING of an audited contract to remove an inconsistency that costs nothing,
    ///      and it would also strand `setBallotGate`'s `ballotBacks` probe, which exists because
    ///      this is one of the ledger's only two runtime calls into the gate.
    ///
    ///      What makes the residual acceptable is that the power itself is nearly inert. The
    ///      settlement indexer attributes fees from the `feeGrowthInside`/`resetSeq` levels carried
    ///      on `FeesCollected`, not from the block a collection happened in, so moving a
    ///      collection between weeks does not move the money. The one live edge is the claim-fee
    ///      window: a stranger syncing just before a scheduled rate CUT pins that range's backlog
    ///      at the pre-cut rate. That is bounded by `MAX_CLAIM_FEE_BPS`, can never charge more
    ///      than the rate the protocol was publicly advertising at the time (`claimFeeFor` takes
    ///      the minimum over the window), and is already characterized in `claimFeeFor`'s NatSpec.
    function syncRanges(uint256 tokenId, uint256[] calldata ids) external nonReentrant {
        address gate = ballotGate;
        if (gate == address(0)) revert BallotGateUnset();
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            // Staked ranges only. A range with nothing staked owes the voters nothing.
            if (_ranges[id].totalStaked == 0) continue;
            // And only a voter of THIS pool, on the strength of a lock they own. Collecting is
            // already harmless to principal — `_syncRange` passes `liquidityDelta == 0`, so it
            // can never move a position, and it merely books an unstaked holder's share into an
            // accumulator only they can draw down. The gate is not there to stop theft; it is
            // there because fees are attributed to the week they are COLLECTED in, so whoever
            // chooses the moment chooses the epoch. That choice belongs to the people the money
            // is owed to, not to whoever is watching.
            if (!IBallotGate(gate).ballotBacks(msg.sender, tokenId, _rangeKeys[id].key.toId())) {
                revert NotAVoterOfThisPool();
            }
            _syncRange(id);
        }
    }

    /// @notice Points the sync gate at the Voter. Until it is set, nothing can be synced through
    ///         this door at all — a closed door being the safe default for one that decides who
    ///         may reach into someone else's position.
    /// @dev Probed, not merely stored. `setDistributor` spends a `try/catch` on its counterpart
    ///      for exactly this reason and this setter did not, so an EOA or a wrong-ABI contract
    ///      made `syncRanges` revert on `abi.decode` for every staked range — permanently
    ///      unusable, with no on-chain signal. `address(0)` stays explicitly allowed: a closed
    ///      door is the safe default for one that decides who may reach into someone else's
    ///      position, and `syncRanges` refuses outright while the gate is unset.
    function setBallotGate(address gate) external restricted {
        if (gate != address(0)) {
            // Explicit, because `try/catch` alone does NOT cover this. Since solc 0.8.10 a
            // high-level call expecting return data skips the extcodesize check and lets the ABI
            // decoder revert instead — and that revert happens in the SUCCESS branch, so `catch`
            // never sees it. An EOA here would have produced a bare revert indistinguishable
            // from out-of-gas: the very "no on-chain signal" this setter is guarding against.
            if (gate.code.length == 0) revert InvalidBallotGate();
            try IBallotGate(gate).ballotBacks(address(this), 0, PoolId.wrap(bytes32(0))) returns (bool) {}
            catch {
                revert InvalidBallotGate();
            }
            // BOTH members, not just the one this contract happens to call first. `stake` calls
            // `isGaugeEarning`, so a gate implementing only `ballotBacks` passed this setter and
            // then made `stake` revert on the ABI decode for every pool at once — with no
            // on-chain signal, which is the exact failure the probe above exists to prevent. The
            // probe must track the member `stake` actually calls: it was `isGaugeLive` before the
            // guard moved to `isGaugeEarning`, and staying on the old member reopened the gap.
            try IBallotGate(gate).isGaugeEarning(PoolId.wrap(bytes32(0))) returns (bool) {}
            catch {
                revert InvalidBallotGate();
            }
            // The THIRD member `stake` reaches, probed for the same reason as the two above. It is
            // called only when a caller sets `minGaugeWeight`, so a gate missing it would brick not
            // every stake but every BOUNDED one — a rarer failure and therefore a quieter one, with
            // the same shape: passes this setter, reverts on the ABI decode later, no signal.
            try IBallotGate(gate).gaugeWeightNow(PoolId.wrap(bytes32(0))) returns (uint256) {}
            catch {
                revert InvalidBallotGate();
            }
            // AND THE GATE MUST BE THE VOTER THAT ESCROW ACTUALLY CALLS BACK. Every probe above
            // asks "can this address answer?"; none asks "is this the SAME Voter the escrow is
            // wired to?" — and nothing anywhere did. The Voter's anti-rental guarantee rests
            // entirely on `ve.voter() == address(voter)`, which `FablesVoter` never asserts: it
            // only checks `msg.sender == address(ve)` inside its hooks, which is a one-way test.
            //
            // The two can genuinely come apart. `VotingEscrowFF.setVoter` is WRITE-ONCE, while this
            // setter and a `FablesBribes` redeploy can both follow a Voter migration — and the
            // Phase-2 backlog already contains a `_shareOf` change that requires exactly such a
            // migration. Split them and borrow-vote-return works permanently and SILENTLY: the
            // escrow calls the old Voter, which holds no ballot for that token, so nothing reverts
            // and no event fires, while the new Voter keeps crediting the borrowed vote.
            //
            // Two lines now; impossible after `setVoter` is burned.
            try IBallotGate(gate).ve() returns (address escrow) {
                // `escrow.code.length` FIRST, and for the reason this function already states
                // twenty lines up: since solc 0.8.10 a high-level call expecting return data skips
                // the extcodesize check and lets the ABI decoder revert instead — and that revert
                // lands in the SUCCESS branch, where `catch` does not reach it. `escrow` is
                // attacker-influenced (it is whatever the gate chose to name), so without this an
                // EOA there propagates a bare decoder revert instead of `InvalidBallotGate`.
                //
                // Every branch still fails closed and `setBallotGate` is `restricted` and
                // re-callable, so this is diagnostics rather than a hole — but the rule is this
                // file's own, and the newest patch to it broke it.
                if (escrow == address(0) || escrow.code.length == 0) revert InvalidBallotGate();
                // RAW STATICCALL WITH A LENGTH CHECK, not `try/catch`, and the difference was
                // measured rather than assumed. `catch` covers a revert FROM the call; it does not
                // cover a failure to decode the call's RETURN DATA. So a contract with a payable
                // catch-all succeeds with empty returndata, the decoder reverts in the success
                // branch, and that propagates past both catches as a bare `revert(0,0)` — the very
                // "no on-chain signal" this setter exists to prevent, one shape further out than the
                // `code.length` check above.
                //
                // This is the pattern `HookFamily._answers` already states the rule for: check
                // `ret.length >= 32` rather than bare success, because a call into an address with
                // no matching function can succeed with empty returndata. One error covers all three
                // shapes — revert, empty/short returndata, wrong value.
                (bool ok, bytes memory ret) = escrow.staticcall(abi.encodeWithSignature("voter()"));
                if (!ok || ret.length < 32 || abi.decode(ret, (address)) != gate) revert InvalidBallotGate();
            } catch {
                revert InvalidBallotGate();
            }
        }
        ballotGate = gate;
        emit BallotGateSet(gate);
    }

    /// @dev The rate a sync of `id` will ACTUALLY charge: the range's snapshot, capped by the
    ///      policy standing now. A reduction binds immediately, so the snapshot is an upper
    ///      bound rather than a figure that can outlive the policy it came from; only an
    ///      increase waits for the range's next sync, which is what stops a raise reaching back
    ///      over a backlog earned entirely under the old rate.
    /// @dev Both the skim and `claimFees`'s consent guard read this one function. They used to
    ///      compute it separately, and drifted apart twice: the guard read the live rate while
    ///      the skim charged the snapshot, then the guard read the snapshot while the skim
    ///      charged the minimum. Each time the two disagreed the guard rejected claims that
    ///      would have cost nothing, or waved through skims it existed to block. One definition
    ///      is the only shape that cannot drift again.
    function _effectiveClaimFee(uint256 id) internal view returns (uint16) {
        // A FULLY STAKED RANGE IS CHARGED NOTHING, so the bound must say nothing too.
        //
        // The skim lives in `LedgerLib._split`'s `unstakedTotal != 0` path; the fully-staked branch
        // returns before it, routing the whole fee to the distributor. So at `totalStaked ==
        // totalShares` the claim fee actually charged is ZERO at any configured `bps` — while this
        // function still returned the pool's live rate, and the guards it feeds
        // (`claimFees`/`withdrawAndClaim` against `maxFeeBps`) then refused a claim that would have
        // cost the caller nothing. A caller passing `maxFeeBps = 0` — "charge me nothing" — was
        // turned away from exactly the case where nothing is charged.
        //
        // This function's own contract is that it equals what the next sync will charge; the rate
        // and the taxable base were separated when the skim moved onto the unstaked residue, and
        // only the rate was tracked. The direction was always safe (it over-stated, never under),
        // so this is correctness rather than solvency — but "safe" is not "right" on a guard whose
        // whole job is to be exact.
        // THE SKIM'S REAL PRECONDITION, which is `totalStaked == totalShares` — nothing more.
        // `_split` skips the claim-fee skim in TWO states: `unstakedTotal == 0` (fully staked) and
        // an EMPTY range, where `_syncRange` returns before `_split` is reached at all. The round-6
        // form carried a `totalShares != 0` conjunct that excluded the second, so an emptied range
        // with `owed` still booked reported the live rate and `claimFees(..., maxFeeBps = 0)` was
        // refused on exactly the case where nothing is charged. Three independent lenses PoC'd it.
        //
        // Dropping the conjunct only ever WIDENS acceptance in states where the skim is provably
        // zero (`0 == 0` for an empty range), so it cannot admit a skim that was previously refused.
        RangeState storage range = _ranges[id];
        if (range.totalStaked == range.totalShares) return 0;
        return claimFeeFor(_rangeKeys[id].key.toId(), claimFeeSyncIndex[id]);
    }

    /// @notice The rate a backlog that opened at history index `sinceIndex` will actually be
    ///         charged: the LOWEST rate that stood at any point from then until now.
    /// @dev The minimum, and not a time-weighted average, because a time-weighted average is not
    ///      computable here and pretending otherwise would be a guess dressed as arithmetic. v4
    ///      hands over one lump for the whole window and says nothing about WHEN inside it the
    ///      fees were earned — a week's backlog might all have accrued in one busy hour. Any
    ///      apportionment would be invented.
    ///
    ///      Given that, the minimum is the only defensible answer, for two reasons that matter
    ///      more than the revenue:
    ///
    ///        - It can never charge an LP a rate the protocol was not actually advertising while
    ///          their fees were accruing. Every other rule can.
    ///        - It bounds the timing game, though it does not remove it. Anyone can force a range
    ///          to realize its fees (`deposit` of one unit does it), so a third party picks the
    ///          moment a backlog is priced. Waiting can only ever LOWER the rate — so there is
    ///          nothing to gain by delaying. But a scheduled cut is public before it lands, and
    ///          collecting just BEFORE it closes the window at the old rate. An earlier version
    ///          of this comment claimed there was nothing to front-run; that is false, and the
    ///          exposure is bounded only by `MAX_CLAIM_FEE_BPS` and by the rate shipping at zero.
    ///
    ///      The cost is that ops must treat a dip as retroactive. Lowering the rate for an hour
    ///      applies that hour's rate to every backlog spanning it, however long. That is a real
    ///      constraint on the lever, and the right way round: it makes a cut generous rather than
    ///      a raise reaching backwards.
    function claimFeeFor(PoolId poolId, uint64 sinceIndex) public view returns (uint16) {
        PoolClaimFee storage pcf = _poolClaimFee[poolId];
        return LedgerLib.claimFeeFor(pcf.history, sinceIndex, claimFeeRecipient, pcf.bps, pcf.allTimeMin);
    }

    /// @notice This pool's current claim-fee rate.
    function claimFeeBps(PoolId poolId) external view returns (uint16) {
        return _poolClaimFee[poolId].bps;
    }

    /// @notice The lowest rate this POOL has ever stood at (the bounded walk's fallback).
    function claimFeeAllTimeMin(PoolId poolId) external view returns (uint16) {
        return _poolClaimFee[poolId].allTimeMin;
    }

    /// @notice Number of recorded claim-fee changes.
    function claimFeeHistoryLength(PoolId poolId) external view returns (uint256) {
        return _poolClaimFee[poolId].history.length;
    }

    /// @notice One recorded claim-fee change.
    function claimFeeChangeAt(PoolId poolId, uint256 index) external view returns (ClaimFeeChange memory) {
        return _poolClaimFee[poolId].history[index];
    }

    /// @notice The rate a range's current backlog will be charged if it is synced now.
    function effectiveClaimFee(uint256 id) external view returns (uint16) {
        return _effectiveClaimFee(id);
    }

    // `_creditFees` emits `FeesCollected` from inside `LedgerLib.creditFees` (inlined), which
    // also reads the range's live `feeGrowthInside` there; both used to be `_emitCollected` /
    // `_growthOf` here, factored into `LedgerLib` for organization.

    /// @dev A thin wrapper over `LedgerLib.settleUser` (inlined), so the per-holder fee and
    ///      emission-weight checkpoint math — this contract's other `FullMath.mulDiv` cluster —
    ///      lives in `LedgerLib`. Called from nine paths, all of which are cheap internal jumps.
    function _settleUser(uint256 id, address owner) internal {
        LedgerLib.settleUser(_ranges[id], _positions[id][owner], balanceOf[owner][id], owner, id);
    }

    /// @notice Pushes accrued claim-fee revenue to the recipient. Callable by anyone.
    function sweepClaimFee(Currency currency) external nonReentrant whenNotPaused {
        _sweepClaimFee(currency);
    }

    /// @dev A thin wrapper over `LedgerLib.sweepClaimFee` (inlined).
    /// @dev Virtual for the same reason `_sweepDistributor` is, and it was a defect that it was
    ///      not. The library's last hop is `poolManager.take(currency, claimFeeRecipient, amount)`,
    ///      which for NATIVE is a bare `call` in v4 — so on an ETH pool this pays raw ETH to an
    ///      address nothing checks is payable. `FablesTreasurySplitter`, the contract whose own
    ///      NatSpec names "ledger claim fees" as one of its three inputs, has no `receive`, no
    ///      `fallback` and no native accounting at all, so the sweep reverted `NativeTransferFailed`
    ///      permanently and the revenue sat as hook-held claims with no other exit.
    ///
    ///      Worse than the stranding: `_settleSinks` runs at the head of `setClaimFee`,
    ///      `setDistributor` and `setFFFeeSink`, so listing the native currency in `settleFirst` —
    ///      which is exactly what those setters tell operators to do — reverted the whole rotation,
    ///      taking the healthy distributor sweep down with it. Rotating away from the bricked sink
    ///      therefore required an EMPTY `settleFirst`, which silently re-points the already-accrued
    ///      native pot at the new recipient: the precise outcome `_settleSinks` exists to prevent.
    ///
    ///      The asymmetry was the tell. One sweep of a matched pair was given a native branch and
    ///      the other was not, on the unexamined belief that only the distributor speaks ERC20.
    function _sweepClaimFee(Currency currency) internal virtual {
        LedgerLib.sweepClaimFee(claimFeeOwed, poolManager, currency, claimFeeRecipient);
    }
}
