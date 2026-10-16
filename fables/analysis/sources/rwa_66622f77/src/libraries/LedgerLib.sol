// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
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
    Action,
    CallbackData,
    PayoutData,
    FeesForgone,
    FeesCollected,
    DistributorSwept,
    ClaimFeeSwept
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

    /// @dev The ledger's live claim-fee policy, bundled so the unlock callback passes it in one
    ///      argument. `bps` is the current rate, `allTimeMin` the walk's floor, `recipient` zero
    ///      when no claim fee is taken.
    struct ClaimFeeState {
        uint16 bps;
        uint16 allTimeMin;
        address recipient;
    }

    /// @dev How far back a sync walks the claim-fee rate history; must equal the ledger's own
    ///      `MAX_CLAIM_FEE_WALK`. Beyond it the all-time minimum is used, which can only charge LESS.
    uint256 private constant MAX_CLAIM_FEE_WALK = 32;
    /// @dev Must equal the ledger's own `MAX_CLAIM_FEE_BPS`.
    uint16 private constant MAX_CLAIM_FEE_BPS = 2000;

    error InvalidClaimFee();
    error InvalidSink();
    error DistributorNotFFAware();

    /// @param id The range id being credited (the `FeesCollected` topic).
    /// @param key The pool key of the range being credited (for the claim mints and currencies).
    /// @param fee0 Fees realized on currency0 this collection.
    /// @param fee1 Fees realized on currency1 this collection.
    /// @param claimFeeBps The ledger's current claim-fee rate (an UPPER bound on what the backlog pays).
    /// @param claimFeeAllTimeMin The lowest rate the ledger has ever stood at (the walk's fallback).
    /// @param claimFeeRecipient Zero means no claim fee is taken at all.
    struct CreditParams {
        uint256 id;
        PoolKey key;
        uint128 fee0;
        uint128 fee1;
        uint16 claimFeeBps;
        uint16 claimFeeAllTimeMin;
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
        ClaimFeeChange[] storage claimFeeHistory,
        IPoolManager poolManager,
        CreditParams memory p
    ) internal {
        // Roll the range's agreed rate forward FIRST, above every early return: the rate a backlog
        // is charged is the rate that stood when it started accruing, and this is where that is
        // knowable. The effective rate is read at the OLD index, then the index moves to the head.
        uint16 feeBps = claimFeeFor(
            claimFeeHistory, claimFeeSyncIndex[p.id], p.claimFeeRecipient, p.claimFeeBps, p.claimFeeAllTimeMin
        );
        claimFeeSyncIndex[p.id] = uint64(claimFeeHistory.length);
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
        // reachable from seven entry points, so ANY party chooses how many windows an epoch's fees
        // are split across — and a plain floor division contributes exactly zero whenever
        // `fee * totalStaked < totalShares`. Splitting one accrual into enough windows therefore
        // drove both the voters' revenue and the staker's emission weight to zero for a few dollars
        // of gas. The unstaked side was never exposed to this because it is credited in Q128.
        uint256 stakedCut0 = _takeStakedCut(range, p.fee0, total, true);
        uint256 stakedCut1 = _takeStakedCut(range, p.fee1, total, false);
        if (stakedCut0 > 0) distributorOwed[p.key.currency0] += stakedCut0;
        if (stakedCut1 > 0) distributorOwed[p.key.currency1] += stakedCut1;
        _creditStaked(range, stakedCut0, stakedCut1);

        uint256 unstakedTotal = total - range.totalStaked;
        if (unstakedTotal == 0) {
            // everything is staked: remainder (rounding dust) also goes to the distributor
            distributorOwed[p.key.currency0] += p.fee0 - stakedCut0;
            distributorOwed[p.key.currency1] += p.fee1 - stakedCut1;
            _creditStaked(range, p.fee0 - stakedCut0, p.fee1 - stakedCut1); // the rounding remainder too
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
        if (feeBps != 0 && p.claimFeeRecipient != address(0)) {
            uint256 c0 = (net0 * feeBps) / 10_000;
            uint256 c1 = (net1 * feeBps) / 10_000;
            if (c0 > 0) claimFeeOwed[p.key.currency0] += c0;
            if (c1 > 0) claimFeeOwed[p.key.currency1] += c1;
            net0 -= c0;
            net1 -= c1;
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
        uint16 currentAllTimeMin
    ) internal returns (uint16 newAllTimeMin) {
        if (bps > MAX_CLAIM_FEE_BPS) revert InvalidClaimFee();
        if (bps != 0 && recipient == address(0)) revert InvalidClaimFee();
        if (recipient == address(this)) revert InvalidClaimFee();
        if (recipient != address(0) && recipient == distributor) revert InvalidClaimFee();

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
            position.owed0 += uint128(FullMath.mulDiv(unstaked, range.accFee0X128 - position.checkpoint0X128, 1 << 128));
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
        ClaimFeeChange[] storage claimFeeHistory,
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
            ranges,
            rangeKeys,
            distributorOwed,
            claimFeeOwed,
            claimFeeSyncIndex,
            claimFeeHistory,
            poolManager,
            cf,
            payload
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
        ClaimFeeChange[] storage claimFeeHistory,
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

        // Fees always come to the ledger and are credited using the share totals as they stand
        // BEFORE this action's mint/burn (callers order it so). Fee amounts are non-negative credits,
        // computed inline so no extra locals weigh on this frame's stack.
        creditFees(
            ranges,
            rangeKeys,
            distributorOwed,
            claimFeeOwed,
            claimFeeSyncIndex,
            claimFeeHistory,
            poolManager,
            CreditParams({
                id: uint256(keccak256(abi.encode(data.key.toId(), data.tickLower, data.tickUpper))),
                key: data.key,
                // fee deltas are always non-negative credits
                // forge-lint: disable-next-line(unsafe-typecast)
                fee0: uint128(uint256(int256(feesAccrued.amount0()))),
                // forge-lint: disable-next-line(unsafe-typecast)
                fee1: uint128(uint256(int256(feesAccrued.amount1()))),
                claimFeeBps: cf.bps,
                claimFeeAllTimeMin: cf.allTimeMin,
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
        address to = Currency.unwrap(currency) == distributorFF ? ffFeeSink : distributor;
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
    function _resolvePrincipal(IPoolManager poolManager, Currency currency, int128 amount, address user) private {
        if (amount < 0) {
            // widen before negating: -int128 panics on type(int128).min; the negation of a negative
            // int128 is always a positive int256, so the uint256 cast is exact
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 owed = uint256(-int256(amount));
            poolManager.sync(currency);
            IERC20(Currency.unwrap(currency)).safeTransferFrom(user, address(poolManager), owed);
            poolManager.settle();
        } else if (amount > 0) {
            // forge-lint: disable-next-line(unsafe-typecast)
            poolManager.take(currency, user, uint256(uint128(amount)));
        }
    }
}
