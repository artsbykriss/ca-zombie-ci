// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {FullMath} from "v4-core/src/libraries/FullMath.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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
    ClaimFeeSwept,
    ClaimFeeAccrued
} from "../base/LedgerTypes.sol";

/// @dev The slice of the distributor the ledger probes when wiring it: the protocol token it must
///      cache to later refuse. Declared here so `validateDistributor` can run the probe.
interface IDistributorFF {
    function ff() external view returns (address);
}

/// @title LedgerLib
/// @notice The fee-collection split for `FablesLedger`. `FablesLedger` is inherited by every hook,
///         so this cluster (three `FullMath.mulDiv` sites and the staked/claim split) is compiled
///         into each one. Kept a separate unit purely for organization.
/// @dev An `internal`-function library, so its code is INLINED into the calling hook (a JUMP, not a
///      DELEGATECALL). It runs in the hook's own context — `address(this)` is the hook,
///      `poolManager.mint` mints to the hook, and every write lands in the hook's storage — and the
///      storage handles it needs are passed by reference. The target chain's ~98,304-byte runtime
///      limit makes the old EIP-170 delegatecall split unnecessary.
library LedgerLib {
    /// @notice A deposit's settled principal exceeded the caller's stated ceiling for that currency.
    error PrincipalAboveMax(uint256 paid, uint256 max);
    /// @notice A withdrawal's settled principal fell short of the caller's stated floor.
    error PrincipalBelowMin(uint256 received, uint256 min);

    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;
    using SafeERC20 for IERC20;

    /// @dev The ledger's live claim-fee policy. The RATE and its history are per pool and now
    ///      travel as a storage handle (`PoolClaimFee`), so all that remains hook-wide is the
    ///      recipient: one sink for every pool, and zero means no claim fee is taken anywhere.
    struct ClaimFeeState {
        address recipient;
    }

    /// @dev How far back a sync walks the claim-fee rate history. Beyond it the all-time minimum is
    ///      used, which can only charge LESS.
    ///
    ///      `internal`, and the LEDGER now aliases THIS one rather than declaring its own — so the
    ///      two cannot drift, in the same way `FablesVoter` reads `MAX_LOCK` off the escrow instead
    ///      of redeclaring it. Both used to be `private` here and `public` there, pinned only by
    ///      prose ("must equal the ledger's own"): the pair a test could reach (`MAX_CLAIM_FEE_BPS`)
    ///      was held by an incidental `2001` literal in one test, and the pair it could not
    ///      (`MAX_CLAIM_FEE_WALK`, private on this side) was held by nothing at all. Drift on the
    ///      walk fails SAFE — the fallback is `allTimeMin`, which undercharges — but "fails safe"
    ///      is a reason not to panic, not a reason to leave two numbers that must agree.
    uint256 internal constant MAX_CLAIM_FEE_WALK = 32;
    /// @dev The claim-fee ceiling, 20%. Aliased by the ledger; see the note above.
    uint16 internal constant MAX_CLAIM_FEE_BPS = 2000;

    error InvalidClaimFee();
    error InvalidSink();
    error DistributorNotFFAware();

    /// @param id The range id being credited (the `FeesCollected` topic).
    /// @param key The pool key of the range being credited (for the claim mints and currencies).
    /// @param fee0 Fees realized on currency0 this collection.
    /// @param fee1 Fees realized on currency1 this collection.
    /// @param claimFeeRecipient Zero means no claim fee is taken at all. The rate and its history
    ///        are read per pool from the `poolClaimFee` handle, not carried here.
    struct CreditParams {
        uint256 id;
        PoolKey key;
        uint128 fee0;
        uint128 fee1;
        address claimFeeRecipient;
    }

    /// @notice The whole fee collection for one range: rolls the claim-fee rate forward, mints the
    ///         fee claims, splits them between the distributor (voter) bucket and the unstaked
    ///         accumulators, skims the claim fee, and emits `FeesCollected`. Behaviour is
    ///         byte-for-byte what lived in the ledger's `_creditFees`.
    /// @dev Inlined into the hook (internal), so `address(this)` is the hook, `poolManager.mint`
    ///      mints to the hook, and the passed mappings/array ARE the hook's own storage. Fee tokens
    ///      are settled as PoolManager claims (never token transfers), so this cannot revert on a
    ///      hostile token and take a withdrawal down with it.
    function creditFees(
        mapping(uint256 => RangeState) storage ranges,
        mapping(uint256 => RangeKey) storage rangeKeys,
        mapping(Currency => uint256) storage distributorOwed,
        mapping(Currency => uint256) storage claimFeeOwed,
        mapping(uint256 => uint64) storage claimFeeSyncIndex,
        mapping(PoolId => PoolClaimFee) storage poolClaimFee,
        IPoolManager poolManager,
        CreditParams memory p
    ) internal {
        // Roll the range's agreed rate forward FIRST, above every early return: the rate a backlog
        // is charged is the rate that stood when it started accruing, and this is where that is
        // knowable. The effective rate is read at the OLD index, then the index moves to the head.
        PoolClaimFee storage pcf = poolClaimFee[p.key.toId()];
        uint16 feeBps = claimFeeFor(pcf.history, claimFeeSyncIndex[p.id], p.claimFeeRecipient, pcf.bps, pcf.allTimeMin);
        claimFeeSyncIndex[p.id] = uint64(pcf.history.length);
        if (p.fee0 == 0 && p.fee1 == 0) return;
        // The mints, split and emit are in `_split` so this frame does not carry the eight storage
        // handles alongside the split's own locals — the legacy pipeline's stack-too-deep.
        _split(ranges[p.id], rangeKeys[p.id], distributorOwed, claimFeeOwed, poolManager, p, feeBps);
    }

    /// @dev The claim mints, the staked/unstaked split and the `FeesCollected` emit for one range
    ///      with fees. Split off `creditFees` so its frame holds only the two owed mappings it
    ///      writes, not all eight ledger handles.
    function _split(
        RangeState storage range,
        RangeKey storage descriptor,
        mapping(Currency => uint256) storage distributorOwed,
        mapping(Currency => uint256) storage claimFeeOwed,
        IPoolManager poolManager,
        CreditParams memory p,
        uint16 feeBps
    ) private {
        // Settle fees as PoolManager claims: exact by construction (immune to a token that later
        // turns on transfer fees) and, critically, no token contract is called, so this cannot
        // revert and take the withdraw path down with it. It must happen on every path with fees,
        // because these claims are how the fee half of `callerDelta` gets resolved.
        if (p.fee0 > 0) poolManager.mint(address(this), p.key.currency0.toId(), p.fee0);
        if (p.fee1 > 0) poolManager.mint(address(this), p.key.currency1.toId(), p.fee1);

        uint256 total = range.totalShares;
        if (total == 0) {
            // Unreachable: fees imply a position, and a position implies shares. If it ever did
            // happen the claims are already minted and there is no shareholder to raise an
            // accumulator for, so the fees go to the voter pot rather than sitting unattributed.
            distributorOwed[p.key.currency0] += p.fee0;
            distributorOwed[p.key.currency1] += p.fee1;
            _emitCollected(range, descriptor, poolManager, EmitArgs(p.id, p.fee0, p.fee1, p.fee0, p.fee1));
            return;
        }

        // Carrying the remainder is load-bearing, not tidiness. `_syncRange` is permissionless and
        // reachable from EIGHT call sites (nine external doors — `withdraw` and `withdrawAndClaim`
        // share `_withdrawTo`), so ANY party chooses how many windows an epoch's fees
        // are split across — and a plain floor division contributes exactly zero whenever
        // `fee * totalStaked < totalShares`. Splitting one accrual into enough windows therefore
        // drove both the voters' revenue and the staker's emission weight to zero for a few dollars
        // of gas.
        //
        //      THE UNSTAKED SIDE was never exposed to this at the ACCUMULATOR level, because
        //      `accFee` is credited in Q128.
        //      The per-holder credit in `settleUser` IS in base units and therefore floors, and a third
        //      party can force a settle on any holder with a 1-unit `transfer` — so the same
        //      split-the-window shape exists there. What bounds it is not Q128: each forced settle
        //      covers the whole interval from that holder's checkpoint, so `Σ floor(aᵢ)` versus
        //      `floor(Σ aᵢ)` denies at most ONE base unit per attacker transaction, at the cost of a
        //      full v4 unlock plus a liquidity unit given away. Inert for every denomination this
        //      protocol hosts; real only for a token with very few decimals and high unit value.
        //
        //      AND THE DENIED UNIT IS STRANDED, NOT REDISTRIBUTED, which this framed purely as a
        //      griefing bound and did not say. `_split` mints claims for the FULL fee while the
        //      unstaked share reaches holders only through `accFee{0,1}X128`, which floors twice —
        //      once at `mulDiv(net, 2^128, unstakedTotal)` and again at each holder's draw. The
        //      un-drawn remainder stays as hook-held ERC-6909 claims with NO redemption path: the
        //      sweeps are bounded by their own counters and `_payout` by `owed`, and there is no
        //      rescue function on any hook by design. Sub-unit per holder per collection, so
        //      economically inert at every denomination this protocol hosts — but it is the same
        //      accounted-for-yet-unreleasable class round 9 closed elsewhere, and a reader costing
        //      the floor should know the unit leaves the system rather than moving to someone else.
        //      Attributing the safety to Q128 rather than to that bound is how the wrong guard gets
        //      deleted later.
        uint256 stakedCut0 = _takeStakedCut(range, p.fee0, total, true);
        uint256 stakedCut1 = _takeStakedCut(range, p.fee1, total, false);
        if (stakedCut0 > 0) distributorOwed[p.key.currency0] += stakedCut0;
        if (stakedCut1 > 0) distributorOwed[p.key.currency1] += stakedCut1;
        _creditStaked(range, stakedCut0, stakedCut1);

        uint256 unstakedTotal = total - range.totalStaked;
        if (unstakedTotal == 0) {
            // EVERYTHING IS STAKED, so the cut is EXACT and all three terms below are provably
            // zero. `_takeStakedCut` with `staked == total` computes `mulmod(fee, total, total) == 0`,
            // so no new fraction is generated and the carried residual (`< 2^128`) cannot flush a
            // whole unit either — `cut == mulDiv(fee, total, total) == fee`. Verified over 200k
            // random (residual, fee, total) triples: zero violations, and the residual is neither
            // grown nor spent while fully staked.
            //
            // So these lines redistribute nothing; an earlier version of this comment described
            // rounding dust moving to the distributor, which the arithmetic makes impossible. They
            // are kept as a guard against a future change to `_takeStakedCut` that stops being
            // exact at the boundary — not because they carry value today.
            distributorOwed[p.key.currency0] += p.fee0 - stakedCut0; // provably 0
            distributorOwed[p.key.currency1] += p.fee1 - stakedCut1; // provably 0
            _creditStaked(range, p.fee0 - stakedCut0, p.fee1 - stakedCut1); // provably (0, 0)
            _emitCollected(range, descriptor, poolManager, EmitArgs(p.id, p.fee0, p.fee1, p.fee0, p.fee1));
            return;
        }

        // The claim fee is taken HERE, at the rate in force while these fees were earned, and never
        // again at claim time. Charging it on withdrawal instead made it retroactive: a single
        // `setClaimFee` could reach back and take a share of everything every LP had already
        // accrued under a lower rate. The skim comes off the UNSTAKED residue, after the staked
        // cut has been set aside, so a voter syncing to fund their own claim never pays for it.
        uint256 net0 = p.fee0 - stakedCut0;
        uint256 net1 = p.fee1 - stakedCut1;
        // NO RESIDUAL CARRY HERE, unlike `_takeStakedCut` thirty lines up — and the asymmetry is
        // deliberate rather than an omission, so it is written down. The same "any party chooses the
        // window count" argument applies, but the exposure does not: whenever `net * feeBps >= 10_000`
        // the skim is non-zero and only the FRACTION is lost, so splitting one accrual into `k`
        // windows forgoes at most `k-1` base units in total — under one base unit per COLLECTION,
        // each costing a full v4 unlock. That is the same bound `settleUser` states for its own
        // floor, and it is economically inert for every denomination this protocol hosts.
        //
        // `_takeStakedCut` needs its carry for a different reason, and the difference is the size of
        // the fee flow ONE zeroed window can carry — not "sub-unit versus not", since a carry-less
        // floor there also loses sub-unit amounts per window. Measured: this skim zeroes only while
        // `net` is under `10_000 / feeBps` base units — 4 at the shipped 2000 bps ceiling, 9,999 at
        // the smallest non-zero rate — a small CONSTANT, independent of pool size. `_takeStakedCut`
        // zeroes while `fee * staked < totalShares`, i.e. up to `totalShares - 1` (1e18-1 on a
        // typical position), so its loss is unbounded AS A FRACTION OF THE STAKED SIDE'S
        // ENTITLEMENT. That is what justifies a carry on one and not the other.
        //
        // The unit above is per COLLECTION, not per transaction: a contract can interleave
        // swap/sync/swap/sync in one call, since the reentrancy guard is transient and released per
        // external call. It only strengthens the bound — each extra fee-bearing window needs fresh
        // accrual, i.e. a swap paying at least `MIN_POOL_FEE`, orders of magnitude above the sub-unit
        // it denies.
        if (feeBps != 0 && p.claimFeeRecipient != address(0)) {
            uint256 c0 = (net0 * feeBps) / 10_000;
            uint256 c1 = (net1 * feeBps) / 10_000;
            if (c0 > 0) claimFeeOwed[p.key.currency0] += c0;
            if (c1 > 0) claimFeeOwed[p.key.currency1] += c1;
            net0 -= c0;
            net1 -= c1;
            // The pot this lands in is keyed by CURRENCY alone, so once one hook serves several
            // pools a sweep can no longer say which pool earned what. This log is the record that
            // can: it names the pool and the rate at the one instant both are known.
            if (c0 > 0 || c1 > 0) emit ClaimFeeAccrued(p.id, p.key.toId(), c0, c1, feeBps);
        }
        range.accFee0X128 += FullMath.mulDiv(net0, 1 << 128, unstakedTotal);
        range.accFee1X128 += FullMath.mulDiv(net1, 1 << 128, unstakedTotal);
        _emitCollected(range, descriptor, poolManager, EmitArgs(p.id, p.fee0, p.fee1, stakedCut0, stakedCut1));
    }

    /// @notice The rate a backlog that opened at history index `sinceIndex` is charged: the LOWEST
    ///         rate that stood from then until now, capped by the current policy. Held here so both
    ///         `creditFees` and the hook's consent guard read one definition that cannot drift.
    /// @dev The minimum (not a time-weighted average, which is not computable from v4's single lump)
    ///      can never charge an LP a rate the protocol was not advertising while their fees accrued,
    ///      and it bounds the timing game: waiting can only ever LOWER the rate. Beyond
    ///      `MAX_CLAIM_FEE_WALK` entries it falls back to the all-time minimum, which cannot
    ///      overcharge — the direction an approximation here must fail in.
    function claimFeeFor(
        ClaimFeeChange[] storage claimFeeHistory,
        uint64 sinceIndex,
        address claimFeeRecipient,
        uint16 claimFeeBps,
        uint16 claimFeeAllTimeMin
    ) internal view returns (uint16) {
        // The backlog opened before this ledger had a claim fee at all, and the rate then was zero.
        if (sinceIndex == 0) return 0;

        uint16 rate = claimFeeRecipient == address(0) ? 0 : claimFeeBps;
        uint256 start = uint256(sinceIndex) - 1; // the entry in force when the backlog opened
        uint256 i = claimFeeHistory.length;
        uint256 walked = 0;
        while (i > start && walked < MAX_CLAIM_FEE_WALK) {
            ClaimFeeChange storage change = claimFeeHistory[i - 1];
            if (change.bps < rate) rate = change.bps;
            i--;
            walked++;
        }
        if (i == start) return rate; // the whole window was covered exactly

        // Truncated by the cap. Fall back to the all-time minimum: bounded by definition, and it
        // CANNOT overcharge — the direction an approximation here has to fail in.
        uint16 floor_ = claimFeeAllTimeMin;
        return floor_ < rate ? floor_ : rate;
    }

    /// @notice Validates a new claim-fee rate, appends it to the history, and returns the updated
    ///         all-time minimum. The hook writes the `claimFeeBps`/`claimFeeRecipient` value-vars
    ///         around this call.
    /// @dev A non-zero rate needs a recipient. The recipient may be neither this hook (the
    ///      permissionless sweep `take`s to it, so naming the hook destroys the revenue) nor the
    ///      distributor (which cannot pay FF out as a fee — the same shape `setFFFeeSink` refuses).
    function recordClaimFee(
        ClaimFeeChange[] storage claimFeeHistory,
        uint16 bps,
        address recipient,
        address distributor,
        address ffFeeSink,
        uint16 currentAllTimeMin
    ) internal returns (uint16 newAllTimeMin) {
        if (bps > MAX_CLAIM_FEE_BPS) revert InvalidClaimFee();
        if (bps != 0 && recipient == address(0)) revert InvalidClaimFee();
        if (recipient == address(this)) revert InvalidClaimFee();
        if (recipient != address(0) && recipient == distributor) revert InvalidClaimFee();
        // ...and the FF sink, so the `ffFeeSink == claimFeeRecipient` edge is refused in EITHER
        // call ordering, like every other pairing in this lattice. `setFFFeeSink` carries the
        // mirror.
        if (recipient != address(0) && recipient == ffFeeSink) revert InvalidClaimFee();

        uint256 length = claimFeeHistory.length;
        uint16 effective = recipient == address(0) ? 0 : bps;
        // week-granular history; block.timestamp is the ordering key, not a precise clock
        // forge-lint: disable-next-line(block-timestamp)
        claimFeeHistory.push(ClaimFeeChange({fromTs: uint64(block.timestamp), bps: effective}));
        newAllTimeMin = (length == 0 || effective < currentAllTimeMin) ? effective : currentAllTimeMin;
    }

    /// @notice Validates a new distributor against the FF and claim-fee sinks (a forbidden pairing
    ///         is reachable in EITHER call ordering, so both setters must reject it), probes it for
    ///         the protocol token, and returns that token to cache.
    /// @dev Zero clears the distributor and its cached FF. A live distributor must name the protocol
    ///      token (so a later sweep can refuse FF): a probe that reverts or answers zero is refused,
    ///      because a distributor this ledger cannot recognise FF for is one it must not feed.
    function validateDistributor(address distributor_, address ffFeeSink, address claimFeeRecipient)
        internal
        view
        returns (address distributorFF)
    {
        if (distributor_ == address(0)) return address(0);
        if (distributor_ == ffFeeSink) revert InvalidSink();
        if (distributor_ == claimFeeRecipient) revert InvalidSink();
        if (distributor_ == address(this)) revert InvalidSink();
        // A CONTRACT FIRST. `try/catch` does not cover an EOA: since solc 0.8.10 a high-level
        // call expecting return data skips the extcodesize check and lets the ABI decoder revert
        // instead — in the SUCCESS branch, where `catch` never sees it. So `setDistributor(EOA)`
        // refused with empty returndata rather than `DistributorNotFFAware`, on a setter whose
        // NatSpec promises "a probe that reverts or answers zero is refused".
        if (distributor_.code.length == 0) revert DistributorNotFFAware();
        try IDistributorFF(distributor_).ff() returns (address ffToken) {
            if (ffToken == address(0)) revert DistributorNotFFAware();
            return ffToken;
        } catch {
            revert DistributorNotFFAware();
        }
    }

    /// @dev The value fields of one `FeesCollected` emit, grouped into memory so the 13-field emit
    ///      does not carry them all as stack slots (the legacy pipeline's stack-too-deep, the reason
    ///      this was a separate function in the ledger too).
    struct EmitArgs {
        uint256 id;
        uint256 fee0;
        uint256 fee1;
        uint256 cut0;
        uint256 cut1;
    }

    /// @notice Emits the zero-fee collection that BRACKETS a liquidity re-base, so settlement always
    ///         holds a `feeGrowthInside` reading in the fresh base.
    /// @dev Called by `deposit` right after the pool touch that (re)creates the v4 position — the
    ///      first instant the new base is readable. Without it, the seam between "position emptied"
    ///      and "first collection with fees" carried NO reading in the new base: the next collection
    ///      compared its growth against a carry still in the OLD base, the split across the re-base
    ///      was unknowable, and settlement could only credit the whole interval to the epoch the
    ///      collection landed in — an epoch whichever address forced the collection got to choose
    ///      (`_syncRange` is reachable from `deposit` with one wei). Emitting the baseline here makes
    ///      every value-bearing interval same-base by construction: no fees can accrue while the
    ///      position is empty, and the exit's own sync collected everything before it, so this log
    ///      carries zero value and exists purely to anchor the base. It consumes a `collectionSeq`
    ///      like any emission, which is what makes DROPPING it detectable as a sequence gap.
    function emitRebaseBaseline(
        mapping(uint256 => RangeState) storage ranges,
        mapping(uint256 => RangeKey) storage rangeKeys,
        IPoolManager poolManager,
        uint256 id
    ) internal {
        _emitCollected(ranges[id], rangeKeys[id], poolManager, EmitArgs(id, 0, 0, 0, 0));
    }

    /// @dev Bumps the collection sequence (H6) and reads v4's live `feeGrowthInside` for the range
    ///      at the instant of collection, then hands off to `_log`. The growth read and the emit are
    ///      split into separate frames so the wide 13-field log does not tip the legacy pipeline into
    ///      stack-too-deep (the reason the ledger split them too).
    function _emitCollected(
        RangeState storage range,
        RangeKey storage descriptor,
        IPoolManager poolManager,
        EmitArgs memory e
    ) private {
        range.collectionSeq += 1;
        (uint256 growth0, uint256 growth1) = _growthOf(descriptor, poolManager);
        _log(e.id, e.fee0, e.fee1, e.cut0, e.cut1, growth0, growth1, range);
    }

    /// @dev v4's `feeGrowthInside` for a range descriptor, in its own frame so its intermediates do
    ///      not coexist with the wide emit.
    function _growthOf(RangeKey storage descriptor, IPoolManager poolManager) private view returns (uint256, uint256) {
        return
            StateLibrary.getFeeGrowthInside(
                poolManager, descriptor.key.toId(), descriptor.tickLower, descriptor.tickUpper
            );
    }

    /// @dev The wide emit alone. The value fields arrive as stack params and the range — read six
    ///      times for its accumulator LEVELS, share totals and sequence anchors — is the LAST param,
    ///      so it sits shallowest on the stack; that is the eight-slot frame the ledger's own
    ///      `_emitCollected` used to schedule the 13-field log.
    function _log(
        uint256 id,
        uint256 fee0,
        uint256 fee1,
        uint256 cut0,
        uint256 cut1,
        uint256 growth0,
        uint256 growth1,
        RangeState storage range
    ) private {
        emit FeesCollected(
            id,
            fee0,
            fee1,
            cut0,
            cut1,
            range.accStaked0X128,
            range.accStaked1X128,
            growth0,
            growth1,
            range.totalShares,
            range.totalStaked,
            range.collectionSeq,
            range.resetSeq
        );
    }

    /// @dev `fee * staked / total`, plus whatever previous windows could not express. `mulmod`
    ///      gives the exact remainder without the overflow a plain `fee * staked` would risk. The
    ///      remainder is carried as a FRACTION of one fee unit (Q128), never as the raw numerator
    ///      `carried % total`: `total` is `totalShares`, which every withdraw shrinks, so a
    ///      numerator written under a large denominator would later be spent under a small one and
    ///      break `cut <= fee`. A fraction of one unit means the same at every denominator, so the
    ///      carry survives arbitrary share movement and `cut <= fee` holds unconditionally.
    function _takeStakedCut(RangeState storage range, uint128 fee, uint256 total, bool isToken0)
        private
        returns (uint256 cut)
    {
        uint128 staked = range.totalStaked;
        uint256 carried = uint256(isToken0 ? range.stakedResidual0 : range.stakedResidual1)
            + FullMath.mulDiv(mulmod(fee, staked, total), 1 << 128, total);
        cut = FullMath.mulDiv(fee, staked, total) + (carried >> 128);
        // masked to the low 128 bits by construction: `carried < 2^129` and the whole unit, if
        // any, was just flushed into `cut` on the line above
        // forge-lint: disable-next-line(unsafe-typecast)
        uint128 keep = uint128(carried);
        if (isToken0) range.stakedResidual0 = keep;
        else range.stakedResidual1 = keep;
    }

    /// @dev Raises the per-staked-share accumulators by the fees staked shares just forwent.
    function _creditStaked(RangeState storage range, uint256 cut0, uint256 cut1) private {
        uint128 staked = range.totalStaked;
        if (staked == 0) return;
        if (cut0 > 0) range.accStaked0X128 += FullMath.mulDiv(cut0, 1 << 128, staked);
        if (cut1 > 0) range.accStaked1X128 += FullMath.mulDiv(cut1, 1 << 128, staked);
    }

    /// @notice Checkpoints one holder's accrued fees and emission weight against the range's
    ///         current accumulator levels. Called on every path that changes a holder's share
    ///         count, so the accrual is always taken at the levels in force before the change.
    /// @dev The hook's other `FullMath.mulDiv` cluster, kept alongside `creditFees` for organization.
    ///      `balance` is the holder's ERC-6909 balance, passed by value; the position is mutated in
    ///      place and `FeesForgone` is emitted with its `LedgerTypes` signature, so the settlement
    ///      indexer sees the identical event whether the ledger or the library ran it.
    function settleUser(
        RangeState storage range,
        UserPosition storage position,
        uint256 balance,
        address owner,
        uint256 id
    ) internal {
        uint256 unstaked = balance - position.staked;
        if (unstaked != 0) {
            // BOUNDED, and this is the only narrowing in this file that did not say so — which is
            // what made two lenses stop on it. The accrual is `unstaked * Δacc / 2^128`, and
            // `Δacc` was itself built from `FullMath.mulDiv(net, 2^128, unstakedTotal)` over the
            // collections since this holder's last checkpoint. Since `unstaked <= unstakedTotal`
            // at every one of those collections, the product telescopes to at most the sum of
            // `net` over the window — i.e. a holder can never be credited more of a currency than
            // the range actually collected. Every balance-mutating path settles first (deposit,
            // withdraw, withdrawAndClaim, claimFees, stake, unstake, both transfers — NOT
            // `syncRanges`, which mutates no balance and never settles a user), and v4's
            // `SafeCast.toInt128` caps ONE collection at 2^127-1, so crossing 2^128 needs two or
            // more collections summing past 3.4e38 base units of a single currency on one range.
            // No asset this ledger is intended to host reaches that, and pool listing is
            // admin-`restricted`.
            //
            // The proof rests on two premises the sentence above leaves implicit, and both hold.
            // (1) `staked_j <= balance_j` per holder — enforced at every mutation site (`stake`'s
            // pre-check, `unstake`, both transfers' `_checkTransferable`, and `withdraw`'s
            // auto-unstake, which lands on exact equality) — which is what makes a holder's
            // unstaked shares a sub-quantity of `unstakedTotal` rather than merely intuitively
            // smaller. (2) Collections with `unstakedTotal == 0` never move `accFee` at all: they
            // take the early returns above, so they cannot appear in the sum. `accFee0X128` and
            // `accFee1X128` have exactly one writer each — the `+=` below — with no reset and no
            // assignment, so the accumulator is monotonic and `accFee - checkpoint` cannot
            // underflow either. A range that empties and refills is covered: reaching a non-zero
            // balance requires a `deposit` or `transfer`, both of which settle the holder at
            // balance 0 first and advance their checkpoint, so the window starts after the refill.
            //
            // Deliberately NOT SafeCast — but the trade is narrower than "revert vs truncate".
            // Note first that the unconditional-withdrawal guarantee is ALREADY conditional at
            // exactly this magnitude: `owed0 += ...` is checked arithmetic, so an accumulated
            // balance near `type(uint128).max` reverts `withdraw` today, SafeCast or not. What
            // SafeCast would add is extending that revert from the accumulated case to the
            // single-window one, and there it is strictly worse: `Δacc` only grows while
            // `unstaked` is frozen (it cannot change without a settle), so the revert would be
            // permanent and unrecoverable — principal, fees and transferability all bricked, with
            // no path that skips the settle. Truncation loses one window's fees and leaves every
            // other property working. Clamping is not a middle option; it only relocates the same
            // revert to the `+=`. The one genuinely failure-free alternative is widening
            // `owed0`/`owed1` to uint256, which costs a storage slot per position on an audited
            // layout to buy a bound that needs 3.4e38 base units of a single currency on one
            // range — declined on that basis, not on the guarantee.
            // forge-lint: disable-next-line(unsafe-typecast)
            position.owed0 += uint128(FullMath.mulDiv(unstaked, range.accFee0X128 - position.checkpoint0X128, 1 << 128));
            // forge-lint: disable-next-line(unsafe-typecast)
            position.owed1 += uint128(FullMath.mulDiv(unstaked, range.accFee1X128 - position.checkpoint1X128, 1 << 128));
        }
        position.checkpoint0X128 = range.accFee0X128;
        position.checkpoint1X128 = range.accFee1X128;

        // Emission weight. Staked shares earn nothing here in tokens — they gave these fees to the
        // voters — but what they gave up is exactly what they are paid emissions for, so it has to
        // be measured per holder and not merely per range. An out-of-range position accrues zero,
        // so it can never farm emissions for free.
        uint128 staked = position.staked;
        if (staked != 0) {
            uint256 d0 = FullMath.mulDiv(staked, range.accStaked0X128 - position.stakedCheckpoint0X128, 1 << 128);
            uint256 d1 = FullMath.mulDiv(staked, range.accStaked1X128 - position.stakedCheckpoint1X128, 1 << 128);
            if (d0 != 0 || d1 != 0) {
                position.forgone0 += d0;
                position.forgone1 += d1;
                emit FeesForgone(owner, id, d0, d1);
            }
        }
        position.stakedCheckpoint0X128 = range.accStaked0X128;
        position.stakedCheckpoint1X128 = range.accStaked1X128;
    }

    /// @notice The PoolManager unlock callback body: a PAYOUT redeems held claims into real tokens,
    ///         and a MODIFY applies the liquidity delta then settles fees (into the ledger's
    ///         accumulators) and principal (to/from the user). The hook's `unlockCallback` is a thin
    ///         shell that checks the caller and calls this; it is inlined, so `address(this)` is the
    ///         hook throughout and every write lands in the hook's storage.
    function onUnlock(
        mapping(uint256 => RangeState) storage ranges,
        mapping(uint256 => RangeKey) storage rangeKeys,
        mapping(Currency => uint256) storage distributorOwed,
        mapping(Currency => uint256) storage claimFeeOwed,
        mapping(uint256 => uint64) storage claimFeeSyncIndex,
        mapping(PoolId => PoolClaimFee) storage poolClaimFee,
        IPoolManager poolManager,
        ClaimFeeState memory cf,
        bytes calldata rawData
    ) internal returns (bytes memory) {
        (Action action, bytes memory payload) = abi.decode(rawData, (Action, bytes));
        if (action == Action.PAYOUT) {
            PayoutData memory pd = abi.decode(payload, (PayoutData));
            _redeem(poolManager, pd.currency0, pd.amount0, pd.to);
            _redeem(poolManager, pd.currency1, pd.amount1, pd.to);
            return "";
        }
        _onModify(
            ranges, rangeKeys, distributorOwed, claimFeeOwed, claimFeeSyncIndex, poolClaimFee, poolManager, cf, payload
        );
        return "";
    }

    /// @dev The MODIFY arm, in its own frame so the two balance deltas, the fee pair and the
    ///      principal pair do not coexist with the eight ledger handles.
    function _onModify(
        mapping(uint256 => RangeState) storage ranges,
        mapping(uint256 => RangeKey) storage rangeKeys,
        mapping(Currency => uint256) storage distributorOwed,
        mapping(Currency => uint256) storage claimFeeOwed,
        mapping(uint256 => uint64) storage claimFeeSyncIndex,
        mapping(PoolId => PoolClaimFee) storage poolClaimFee,
        IPoolManager poolManager,
        ClaimFeeState memory cf,
        bytes memory payload
    ) private {
        CallbackData memory data = abi.decode(payload, (CallbackData));
        (BalanceDelta callerDelta, BalanceDelta feesAccrued) = poolManager.modifyLiquidity(
            data.key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: data.tickLower,
                tickUpper: data.tickUpper,
                liquidityDelta: data.liquidityDelta,
                salt: bytes32(0)
            }),
            ""
        );

        // WHAT MAKES THIS SAFE IS THE EARLIER `_syncRange`, NOT THE ORDERING. An earlier version of
        // this comment said fees "are credited using the share totals as they stand BEFORE this
        // action's mint/burn (callers order it so)" — and both callers do the opposite:
        // `FablesLedger.deposit` mints and raises `totalShares` before `_modify`, and `_withdrawTo`
        // burns before it. The credit here therefore always sees POST-mutation totals.
        //
        // It is still correct, for a different reason: the separate `_syncRange` earlier in each
        // caller has already drained v4's lazily-accrued fees, so `feesAccrued` is zero by the time
        // this runs and the totals cannot mis-split anything. Naming the wrong mechanism is what
        // makes it dangerous — a reader who believes the ordering is the invariant deletes
        // `_syncRange` as a redundant round trip, and a one-wei depositor is then credited a share
        // of fees earned entirely before they arrived.
        //
        // Fee amounts are non-negative credits, computed inline so no extra locals weigh on this
        // frame's stack.
        creditFees(
            ranges,
            rangeKeys,
            distributorOwed,
            claimFeeOwed,
            claimFeeSyncIndex,
            poolClaimFee,
            poolManager,
            CreditParams({
                id: uint256(keccak256(abi.encode(data.key.toId(), data.tickLower, data.tickUpper))),
                key: data.key,
                // fee deltas are always non-negative credits
                // forge-lint: disable-next-line(unsafe-typecast)
                fee0: uint128(uint256(int256(feesAccrued.amount0()))),
                // forge-lint: disable-next-line(unsafe-typecast)
                fee1: uint128(uint256(int256(feesAccrued.amount1()))),
                claimFeeRecipient: cf.recipient
            })
        );

        // Principal = callerDelta minus fees, settled in its own frame so the two deltas do not
        // coexist with the credit call above.
        _settlePrincipal(
            poolManager,
            data.key,
            callerDelta,
            feesAccrued,
            data.user,
            data.liquidityDelta,
            data.amount0Limit,
            data.amount1Limit
        );
    }

    /// @dev Settles both currencies' principal for a modify: `callerDelta - feesAccrued` per side,
    ///      after checking each side against the caller's stated bound.
    function _settlePrincipal(
        IPoolManager poolManager,
        PoolKey memory key,
        BalanceDelta callerDelta,
        BalanceDelta feesAccrued,
        address user,
        int256 liquidityDelta,
        uint128 amount0Limit,
        uint128 amount1Limit
    ) private {
        int128 principal0 = callerDelta.amount0() - feesAccrued.amount0();
        int128 principal1 = callerDelta.amount1() - feesAccrued.amount1();
        _checkBound(principal0, liquidityDelta, amount0Limit);
        _checkBound(principal1, liquidityDelta, amount1Limit);
        _resolvePrincipal(poolManager, key.currency0, principal0, user);
        _resolvePrincipal(poolManager, key.currency1, principal1, user);
    }

    /// @dev The caller's consent, checked against what the price actually decided.
    ///
    ///      A `liquidity` figure is not a price: the same liquidity costs `L*(1/sqrt(Pa) -
    ///      1/sqrt(Pb))` of currency0 with the price at or below the range and `L*(sqrt(Pb) -
    ///      sqrt(Pa))` of currency1 at or above it, against a roughly even split mid-range. So a
    ///      price move between signing and execution silently converts the whole position into one
    ///      leg at a price nobody agreed to — and the pull was previously bounded only by the
    ///      caller's ERC-20 allowance. Worst on a freshly initialized pool, where there is no
    ///      liquidity to cross, so walking the price to any target consumes no input and pays no
    ///      fee: the manipulation is free, not merely cheap, which makes the FIRST deposit into a
    ///      new pool the highest-value target in the system.
    ///
    ///      Checked per currency, in the direction the action moves value:
    ///        - adding liquidity, the caller PAYS, so the bound is a ceiling;
    ///        - removing it, the caller RECEIVES, so the bound is a floor.
    ///      A zero delta is an internal fee sync that moves no principal, and is exempt.
    function _checkBound(int128 principal, int256 liquidityDelta, uint128 limit) private pure {
        if (liquidityDelta > 0) {
            // widen before negating: -int128 panics on type(int128).min
            // negating a NEGATIVE int128 inside int256 is always positive, so the uint256 cast is exact
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 paid = principal < 0 ? uint256(-int256(principal)) : 0;
            if (paid > limit) revert PrincipalAboveMax(paid, limit);
        } else if (liquidityDelta < 0) {
            // guarded positive on the same line, so the uint256 cast is exact
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 received = principal > 0 ? uint256(int256(principal)) : 0;
            if (received < limit) revert PrincipalBelowMin(received, limit);
        }
    }

    /// @dev Redeems held claims into real tokens for `to`. Kept off the withdraw path.
    function _redeem(IPoolManager poolManager, Currency currency, uint256 amount, address to) private {
        if (amount == 0) return;
        poolManager.burn(address(this), currency.toId(), amount);
        poolManager.take(currency, to, amount);
    }

    /// @notice Burns the ledger's claims and pays `to` in real tokens, via a PAYOUT unlock. A
    ///         failure here (paused/blocklisted token, blocked recipient) affects only this claim,
    ///         never principal. The hook's `_payout` is a one-line call into this.
    function payout(
        IPoolManager poolManager,
        Currency currency0,
        Currency currency1,
        uint256 amount0,
        uint256 amount1,
        address to
    ) internal {
        if (amount0 == 0 && amount1 == 0) return;
        poolManager.unlock(
            abi.encode(Action.PAYOUT, abi.encode(PayoutData(currency0, currency1, amount0, amount1, to)))
        );
    }

    /// @notice Pushes a currency's accrued staked-share revenue to the distributor — or, for the
    ///         protocol token, to the dedicated FF sink, since the epoch distributor treats every FF
    ///         it holds as the emission tranche and would strand fee revenue arriving there.
    function sweepDistributor(
        mapping(Currency => uint256) storage distributorOwed,
        IPoolManager poolManager,
        Currency currency,
        address distributor,
        address distributorFF,
        address ffFeeSink
    ) internal {
        uint256 amount = distributorOwed[currency];
        if (amount == 0) return;
        // `distributorFF != address(0)` is load-bearing, not redundant: NATIVE currency unwraps to
        // address(0) and `validateDistributor` caches address(0) whenever the distributor is cleared,
        // so without it the "is this the protocol token?" test also answers yes for native ETH and
        // routes native revenue to the FF sink. Unreachable today only because `FablesNativeETH`
        // overrides the native branch before this line and every other hook refuses native pools —
        // i.e. the safety lives in a different contract. Pinning it here makes it local.
        address to =
            (distributorFF != address(0) && Currency.unwrap(currency) == distributorFF) ? ffFeeSink : distributor;
        if (to == address(0)) return; // unset sink: the accrual simply keeps waiting
        distributorOwed[currency] = 0;
        payout(poolManager, currency, currency, amount, 0, to);
        emit DistributorSwept(currency, to, amount);
    }

    /// @notice Pushes a currency's accrued claim-fee revenue to the recipient. Pull-shaped: a
    ///         blocked recipient cannot wedge anyone else's sweep.
    function sweepClaimFee(
        mapping(Currency => uint256) storage claimFeeOwed,
        IPoolManager poolManager,
        Currency currency,
        address claimFeeRecipient
    ) internal {
        uint256 amount = claimFeeOwed[currency];
        if (claimFeeRecipient == address(0) || amount == 0) return;
        claimFeeOwed[currency] = 0;
        payout(poolManager, currency, currency, amount, 0, claimFeeRecipient);
        emit ClaimFeeSwept(currency, claimFeeRecipient, amount);
    }

    /// @dev Settles one currency's principal: a negative delta is owed BY the user (pulled and
    ///      settled to the pool manager), a positive delta is paid TO the user.
    // `user` is not attacker-chosen. It is `CallbackData.user`, reachable only through
    // `FablesLedger.unlockCallback`, which refuses any caller but the PoolManager. There are THREE
    // constructions of CallbackData, not two: `msg.sender` (deposit), `address(this)` (sync), and
    // `to` in `_withdrawTo` — which IS caller-supplied and may be any address. An earlier version
    // of this comment enumerated only the first two, which is the wrong basis for the suppression
    // below.
    //
    // The real invariant is a property of the withdraw path rather than of the writers: a removal
    // has `liquidityDelta < 0`, and v4-core's `SqrtPriceMath.getAmount0Delta`/`getAmount1Delta`
    // return a POSITIVE amount for negative liquidity, so `principal = callerDelta - feesAccrued`
    // is non-negative and `_resolvePrincipal` can only ever reach the `poolManager.take(currency,
    // user, ...)` branch. The `safeTransferFrom(user, ...)` branch is unreachable with a
    // third-party `user`. (`_checkBound` does NOT establish this — with `liquidityDelta < 0` and
    // `amountNMin == 0` a negative principal would pass it silently.)
    // Proven adversarially by test_fuzz_aDepositIsPaidForByTheCallerAndNobodyElse, which asserts
    // the ATTACKER's balance falls and a funded, approved victim's does not.
    // slither-disable-next-line arbitrary-send-erc20
    function _resolvePrincipal(IPoolManager poolManager, Currency currency, int128 amount, address user) private {
        if (amount < 0) {
            // widen before negating: -int128 panics on type(int128).min; the negation of a negative
            // int128 is always a positive int256, so the uint256 cast is exact
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 owed = uint256(-int256(amount));
            // Sync FIRST for both branches — the CurrencySettler-canonical order. For native it
            // clears the synced-currency slot so `settle` reads the attached value; skipping it
            // and relying on "no ERC20 was synced yet this unlock" would make correctness hinge
            // on resolution ORDER (native leg before ERC20 leg), a coupling nobody would see.
            poolManager.sync(currency);
            if (currency.isAddressZero()) {
                // The hook prepaid: `deposit` requires `msg.value >= amount0Max` and `_checkBound`
                // caps `owed` at `amount0Max`, so the balance this spends from can never be short.
                // Only a native-capable hook can reach here — every other hook's `_checkKey`
                // refuses native pools before an unlock is ever taken.
                poolManager.settle{value: owed}();
            } else {
                IERC20(Currency.unwrap(currency)).safeTransferFrom(user, address(poolManager), owed);
                poolManager.settle();
            }
        } else if (amount > 0) {
            // `take` moves native and ERC20 alike — the PoolManager itself pays the recipient.
            // forge-lint: disable-next-line(unsafe-typecast)
            poolManager.take(currency, user, uint256(uint128(amount)));
        }
    }
}
