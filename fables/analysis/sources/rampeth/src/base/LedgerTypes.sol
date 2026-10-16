// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

/// @title LedgerTypes
/// @notice Shared ledger types split into their own file so `FablesLedger` and its inlined
///         helper library `LedgerLib` can both reference `RangeState` without a circular import. The
///         struct layout is unchanged from when it lived inside the ledger, so storage is
///         identical; moving the declaration touches no slot.
struct RangeState {
    uint128 totalShares;
    uint128 totalStaked;
    uint256 accFee0X128; // fee per unstaked share, Q128
    uint256 accFee1X128;
    /// @dev Fee per STAKED share, Q128 — the fees staked shares gave up. This is the
    ///      emission weight. Within a pool, fee growth per unit of liquidity is identical
    ///      for every in-range position at any instant, so this quantity IS in-range
    ///      liquidity-seconds, measured in the units that matter. A position the price
    ///      never reaches accrues exactly zero here, which is the whole point.
    uint256 accStaked0X128;
    uint256 accStaked1X128;
    /// @dev Sub-unit remainder left over by the staked-cut division, carried into the next
    ///      window so no accrual can be truncated away by splitting it across syncs. Held as
    ///      a FRACTION of one fee unit in Q128, never as a numerator over `totalShares`:
    ///      see `LedgerLib._takeStakedCut` for why the denominator must not appear here.
    uint128 stakedResidual0;
    uint128 stakedResidual1;
    /// @dev Emitted-collection counter (H6) and zero-liquidity-crossing counter (H2). Both are
    ///      settlement anchors, not accounting: see the `FeesCollected` params. They share a slot.
    uint64 collectionSeq;
    uint64 resetSeq;
}

/// @notice One claim-fee rate and the moment it took effect. Shared with `LedgerLib`, which walks
///         the history to price a range's backlog inside `creditFees`.
struct ClaimFeeChange {
    uint64 fromTs;
    uint16 bps;
}

/// @dev The two things `poolManager.unlock` calls back to do, decoded in `LedgerLib.onUnlock`.
enum Action {
    MODIFY,
    PAYOUT
}

/// @dev A liquidity-modify unlock: apply `liquidityDelta` to the range and settle principal + fees.
///
///      `amount0Limit`/`amount1Limit` carry the CALLER'S CONSENT to the only place that can enforce
///      it. A liquidity quantity does not say what it costs — the token amounts come out of the
///      pool's live price inside `modifyLiquidity` — so without these the settled principal was
///      whatever the price happened to make it, pulled from the caller with no ceiling. On a
///      deposit they are the MOST the caller will pay per currency; on a withdraw, the LEAST they
///      will accept. Ignored entirely when `liquidityDelta == 0` (an internal fee sync moves no
///      principal).
struct CallbackData {
    PoolKey key;
    int24 tickLower;
    int24 tickUpper;
    int256 liquidityDelta;
    address user;
    uint128 amount0Limit;
    uint128 amount1Limit;
}

/// @dev A payout unlock: redeem held claims into real tokens for `to`, kept off the withdraw path.
struct PayoutData {
    Currency currency0;
    Currency currency1;
    uint256 amount0;
    uint256 amount1;
    address to;
}

/// @dev Emitted when accrued staked-share revenue is pushed to the distributor (or the FF sink).
///      File-level so `LedgerLib.sweepDistributor` emits it with the identical
///      signature the settlement indexer reads.
event DistributorSwept(Currency indexed currency, address indexed distributor, uint256 amount);

/// @dev Mirrors `DistributorSwept` for the claim-fee sink. Its absence was a hole in the indexer's
///      reconstruction of the fee split, which is derived from logs alone.
event ClaimFeeSwept(Currency indexed currency, address indexed recipient, uint256 amount);

/// @dev The claim-fee cut taken out of ONE range's collection, at the rate that stood while those
///      fees accrued. This is the only moment that rate is knowable off-chain: `LedgerLib.creditFees`
///      rolls `claimFeeSyncIndex[rangeId]` forward on EVERY sync, including the zero-fee ones that
///      emit nothing at all, so a log reader cannot reconstruct `sinceIndex` and therefore cannot
///      price the cut after the fact. `FeesCollected` already makes the DISTRIBUTOR side per-range
///      attributable through `stakedCut0/1`; this MAKES THE SAME HOLE CLOSABLE on the claim side —
///      not closed, which is what this line used to say. Nothing consumes it: a grep across
///      `indexer/src`, `indexer/runner`, `indexer/ops`, the subgraph mapping, its manifest and its
///      `FablesLedger` ABI returns no reference, so per-pool claim-fee revenue is still not
///      attributed anywhere. No money is at risk (`claimFeeOwed` is keyed by currency and swept
///      whole to one hook-wide recipient, so this is reporting only), but the same round that added
///      `sweepReconciliation` to fix four orphaned events — `DistributorSwept`, `ClaimFeeSwept` and
///      both native wrap events, all with zero consumers — emitted a fifth. Closing it is one
///      subgraph handler; until that exists, the claim above overstates what shipped. Emitted
///      only when a cut is actually taken, so a ledger resting at a zero rate pays no gas for it.
///      `poolId` is indexed because one hook may serve many pools: a per-pool revenue reader then
///      needs no `rangeKey` round-trip, which also keeps attribution working against a non-archive
///      RPC, where the historical read fails outright.
event ClaimFeeAccrued(uint256 indexed rangeId, PoolId indexed poolId, uint256 cut0, uint256 cut1, uint16 feeBps);

/// @dev One pool's claim-fee policy. Bundled so the per-pool rate, its walk floor and its rate
///      history travel as ONE storage handle through the unlock plumbing: the previous shape
///      passed a bare `ClaimFeeChange[]` plus two scalars, and splitting those per pool would have
///      added three parameters to frames that already documented stack-too-deep pressure.
struct PoolClaimFee {
    /// @dev Current rate for this pool. An UPPER bound on what any backlog pays, never a floor.
    uint16 bps;
    /// @dev Lowest rate this POOL has ever stood at; the fallback once a backlog outruns the walk.
    uint16 allTimeMin;
    /// @dev Every rate this pool has stood at, oldest first.
    ClaimFeeChange[] history;
}

struct UserPosition {
    uint128 staked;
    uint128 owed0;
    uint128 owed1;
    uint256 checkpoint0X128;
    uint256 checkpoint1X128;
    uint256 stakedCheckpoint0X128;
    uint256 stakedCheckpoint1X128;
    /// @notice Cumulative fees this holder's STAKED shares gave up, per currency. The basis
    ///         for their emission share within the pool — settlement buckets the deltas by
    ///         epoch from `FeesForgone`, and this running total is the on-chain anchor
    ///         anyone can check a root against.
    uint256 forgone0;
    uint256 forgone1;
}

/// @dev The emission weight, emitted per holder as it accrues. Settlement buckets these by
///      epoch to split a pool's vote-won emissions among the LPs who actually earned them.
///      File-level so `LedgerLib` emits it with the identical signature the
///      settlement indexer already reads.
event FeesForgone(address indexed owner, uint256 indexed rangeId, uint256 amount0, uint256 amount1);

/// @dev Range descriptor, stored on first deposit so paths without a PoolKey argument (ERC-6909
///      transfers) can still sync the pool's lazily-accrued fees first. File-level so `LedgerLib`
///      can read a range's `feeGrowthInside` for the `FeesCollected` emit.
struct RangeKey {
    PoolKey key;
    int24 tickLower;
    int24 tickUpper;
    bool set;
}

/// @dev Emitted on every fee collection so the split between voters (staked) and holders
///      (unstaked) is reproducible from logs — the epoch-settlement trust model assumes exactly
///      that. File-level so `LedgerLib` emits it with the identical signature the
///      indexer reads.
///
///      Carries the per-staked-share accumulator LEVELS, which is what makes emission weight
///      attributable in time. `FeesForgone` fires when a holder is settled, and a settle can be
///      triggered by anyone (a dust transfer settles the receiver) at any block — so its timestamp
///      says when someone poked the position, not when the fees were earned. These levels move only
///      inside the collection itself, so integrating them against the Staked/Unstaked timeline
///      gives each holder's weight per epoch regardless of when anyone settles.
///
///      `feeGrowthInside0X128`/`1X128` are v4's own per-liquidity accumulator for the range, read at
///      the instant of collection: a week's forgone fees become a function of what the position
///      GENERATED rather than of when somebody collected it, so settlement can split a segment that
///      straddles a week boundary AT the boundary, identically for every holder. `totalShares`/
///      `totalStaked` carry the staked fraction rather than reconstructing it. `collectionSeq`
///      increments on EVERY emitted collection, so a DROPPED log is a visible gap and its epoch is
///      quarantined rather than under-paid (H6); `resetSeq` increments whenever the range's v4
///      position crosses zero liquidity in EITHER direction — the deterministic re-base signal that
///      replaced the indexer's steerable magnitude heuristic (H2).
event FeesCollected(
    uint256 indexed rangeId,
    uint256 fee0,
    uint256 fee1,
    uint256 stakedCut0,
    uint256 stakedCut1,
    uint256 accStaked0X128,
    uint256 accStaked1X128,
    uint256 feeGrowthInside0X128,
    uint256 feeGrowthInside1X128,
    uint128 totalShares,
    uint128 totalStaked,
    uint64 collectionSeq,
    uint64 resetSeq
);
