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
///       - WITHDRAWALS ARE UNCONDITIONAL. The withdraw path reads no admin state: no pause,
///         no oracle, no distributor, no claim fee on principal; staked shares auto-unstake.
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
interface IBallotGate {
    function ballotBacks(address account, uint256 tokenId, PoolId poolId) external view returns (bool);
    function isGaugeKilled(PoolId poolId) external view returns (bool);
    function isGaugeLive(PoolId poolId) external view returns (bool);
    function isGaugeEarning(PoolId poolId) external view returns (bool);
}

abstract contract FablesLedger is FablesBaseHook, ERC6909, ReentrancyGuardTransient, IUnlockCallback {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    error LedgerPaused();
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
    event ClaimFeeSet(uint16 bps, address recipient);
    event DistributorSet(address distributor);
    event FFFeeSinkSet(address sink);
    event PausedSet(uint256 pausedUntil);
    event BallotGateSet(address gate);

    uint16 public constant MAX_CLAIM_FEE_BPS = 2000; // 20%, fixed in bytecode
    /// @dev How far back a sync will walk the rate history. Beyond it the all-time minimum is
    ///      used, which can only ever charge LESS — never more — than the true window minimum.
    ///      This cap, not a cooldown, is what bounds the cost: it holds whatever the history
    ///      length, and the AccessManager execution delay on `setClaimFee` already stops the
    ///      history being grown quickly in the first place.
    uint256 public constant MAX_CLAIM_FEE_WALK = 32;

    // `RangeState` now lives in `LedgerTypes.sol` (shared with `LedgerLib`); its layout is
    // unchanged. See that file for the per-field notes.

    // `UserPosition` now lives in `LedgerTypes.sol` (shared with `LedgerLib`); its layout is
    // unchanged. See that file for the per-field notes.

    /// @notice Admin levers. None of them is readable from the withdraw path.
    uint16 public claimFeeBps;
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
    ClaimFeeChange[] internal _claimFeeHistory;

    /// @notice The lowest rate this ledger has ever stood at. The fallback for a backlog older
    ///         than the bounded walk can reach.
    uint16 public claimFeeAllTimeMin;

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

    /// @notice The Voter, consulted to decide who may collect a staked range's fees.
    address public ballotGate;

    /// @notice Longest a single pause can last before it must be renewed on purpose.
    uint256 public constant MAX_PAUSE = 7 days;

    /// @notice True while the ledger is paused.
    function paused() public view returns (bool) {
        // day-scale window; second-level drift is immaterial
        // forge-lint: disable-next-line(block-timestamp)
        return pausedUntil > block.timestamp;
    }

    modifier whenNotPaused() {
        if (paused()) revert LedgerPaused();
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

    function setClaimFee(Currency[] calldata settleFirst, uint16 bps, address recipient)
        external
        restricted
        nonReentrant
    {
        _settleSinks(settleFirst);
        // Validation, the history append and the all-time-min update live in `LedgerLib`
        // (inlined); the value-vars are written here around it. The
        // recipient may be neither this hook (the permissionless sweep would `take` the revenue
        // straight to it) nor the distributor (which cannot pay FF out as a fee) — and that guard
        // holds in EITHER call ordering, `setDistributor` enforcing the mirror.
        claimFeeAllTimeMin = LedgerLib.recordClaimFee(_claimFeeHistory, bps, recipient, distributor, claimFeeAllTimeMin);
        claimFeeBps = bps;
        claimFeeRecipient = recipient;
        emit ClaimFeeSet(bps, recipient);
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
        if (sink == distributor || sink == address(this)) revert InvalidSink();
        ffFeeSink = sink;
        emit FFFeeSinkSet(sink);
    }

    /// @dev Pushes every named pot to its CURRENT destination before that destination changes.
    ///      The pots are keyed by currency alone and the destination is resolved at sweep time,
    ///      so rotating a sink silently re-pointed revenue that accrued entirely under the old
    ///      one. The permissionless sweep was the old sink's only defence, and it is
    ///      `whenNotPaused` while the setters are not — so a pause covering the rotation removed
    ///      even that. Settling here makes the rotation deterministic, exactly as
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
            // A range with nothing in it has no backlog to mis-price, so this is the one moment
            // its rate can be set forward rather than backward. Without it a brand-new range
            // would carry a zero snapshot into its first real accrual and pay nothing.
            claimFeeSyncIndex[id] = uint64(_claimFeeHistory.length);
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
    ///      remainder is refunded in full at the end (see `_refundNative`).
    function deposit(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint128 amount0Max,
        uint128 amount1Max,
        uint256 deadline
    ) external payable nonReentrant whenNotPaused {
        if (liquidity == 0) revert ZeroLiquidity();
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) revert DeadlineExpired();
        _checkKey(key);
        if (key.currency0.isAddressZero()) {
            if (msg.value < amount0Max) revert InvalidMsgValue();
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

    /// @dev Returns the hook's ENTIRE native balance to the caller, not `msg.value - spent`: the
    ///      hook never holds ETH between transactions (deposits are the only pay-in and they end
    ///      here; sweeps wrap-and-forward within their own call), so the whole balance IS this
    ///      deposit's unspent remainder — plus any dust a stranger force-sent, which this returns
    ///      to circulation instead of stranding. Full-gas call, hard revert on failure: a caller
    ///      that cannot receive ETH must not be able to leave it behind.
    function _refundNative() internal {
        uint256 balance = address(this).balance;
        if (balance == 0) return;
        (bool success,) = msg.sender.call{value: balance}("");
        if (!success) revert RefundFailed();
    }

    /// @notice Burns receipts and removes the corresponding liquidity to the caller. Reads no
    ///         admin state; auto-unstakes if the unstaked balance is insufficient.
    /// @dev Fees are collected first via `_syncRange` — a claims-only touch that makes no
    ///      token call — so the withdrawer still receives their cut at pre-burn totals. Shares
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
        if (liquidity == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();
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
    function claimFees(PoolKey calldata key, int24 tickLower, int24 tickUpper, address to, uint16 maxFeeBps)
        external
        nonReentrant
        whenNotPaused
    {
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
    function stake(PoolKey calldata key, int24 tickLower, int24 tickUpper, uint128 shares)
        external
        nonReentrant
        whenNotPaused
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
        whenNotPaused
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
        whenNotPaused
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
            _claimFeeHistory,
            poolManager,
            LedgerLib.ClaimFeeState({bps: claimFeeBps, allTimeMin: claimFeeAllTimeMin, recipient: claimFeeRecipient}),
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
            _claimFeeHistory,
            poolManager,
            LedgerLib.CreditParams({
                id: id,
                key: key,
                fee0: fee0,
                fee1: fee1,
                claimFeeBps: claimFeeBps,
                claimFeeAllTimeMin: claimFeeAllTimeMin,
                claimFeeRecipient: claimFeeRecipient
            })
        );
    }

    /// @notice Realizes v4's lazily-accrued fees for a list of ranges, splitting each between
    ///         its unstaked holders and the voters' pot. Permissionless, unpausable, and it
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
        return claimFeeFor(claimFeeSyncIndex[id]);
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
    function claimFeeFor(uint64 sinceIndex) public view returns (uint16) {
        return LedgerLib.claimFeeFor(_claimFeeHistory, sinceIndex, claimFeeRecipient, claimFeeBps, claimFeeAllTimeMin);
    }

    /// @notice Number of recorded claim-fee changes.
    function claimFeeHistoryLength() external view returns (uint256) {
        return _claimFeeHistory.length;
    }

    /// @notice One recorded claim-fee change.
    function claimFeeChangeAt(uint256 index) external view returns (ClaimFeeChange memory) {
        return _claimFeeHistory[index];
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
    function _sweepClaimFee(Currency currency) internal {
        LedgerLib.sweepClaimFee(claimFeeOwed, poolManager, currency, claimFeeRecipient);
    }
}
