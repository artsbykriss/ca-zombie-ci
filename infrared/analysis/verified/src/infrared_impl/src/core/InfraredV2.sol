// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {InfraredV1_10} from "src/core/InfraredV1_10.sol";

/// @title  InfraredV2
/// @notice pol-vnext upgrade. Inherits InfraredV1_10 **without modifying its
///         bytecode or the inherited storage layout** and adds no new storage
///         or selectors of its own. The vnext reward semantics are delivered
///         entirely by the reworked `RewardsLib`: harvested WBERA is unwrapped,
///         minted into iBERA, and **iBERA is distributed directly** to vaults
///         and per-user harvest recipients in place of the legacy BGT/iBGT
///         payout.
/// @dev    The harvest pipeline is **not** re-exposed with V2 selectors. The
///         existing `harvestBase`, `harvestVault`, `harvestOldVault`,
///         `claimExternalVaultRewards`, and `externalVaultRewards` selectors
///         on `InfraredV1_10` are made BGT+WBERA-aware by changes to
///         `RewardsLib` alone: balance-delta logic measures both reward
///         streams around `vault.getReward()`, and `_wberaAndIbera()` /
///         `_sweepWberaToReceivor()` pull the vnext token addresses out of
///         the calling Infrared contract via `IInfrared(address(this))`
///         (works because external library calls run via DELEGATECALL).
///         A single keeper invocation covers both pre- and
///         post-vnext-migration state — no V1/V2 selector split needed.
/// @dev    The reward-allocator role is **not** delegated. Infrared is the
///         BeaconDeposit operator for its own validators and so is the
///         implicit allocator via vnext's operator-fallback path; no
///         `setValRewardAllocator` passthrough is needed.
/// @dev    Booster-slice incentives (post-fork) flow to us **passively** via
///         the Phase-2 LST integration: Berachain's `BGTIncentiveFeeCollector`
///         pays WBERA to every registered `LSTStakerVault` (ours included,
///         once `InfraredBeraAdapter` is deployed and registered), and the
///         adapter converts that WBERA to iBERA shares automatically. This
///         contract does **not** run the auction itself.
/// @dev    Event-unit warning (legacy V1_10 events seen post-fork):
///           - `BaseHarvested(_sender, _bgtAmt)` — the `_bgtAmt` slot is now
///             **BGT redeemed + WBERA swept**; post-fork it carries the
///             WBERA-as-native-BERA total only.
///           - `VaultHarvested(_sender, _asset, _vault, _bgtAmt)` — the
///             `_bgtAmt` slot is **BGT delta + iBERA shares minted**;
///             post-fork it is iBERA shares only. Off-chain consumers reading
///             this slot as "BGT amount" will be misled in unit but not in
///             semantics (both quantities are denominated in BERA-equivalent
///             reward).
///           - `ExternalVaultClaimed(user, asset, vault, bgtAmt)` — same
///             treatment as `VaultHarvested`.
///         No new events are emitted from this contract for those legacy
///         paths; reading the new vnext units off the existing `_bgtAmt`
///         field is the deliberate trade-off for keeping InfraredV1_10
///         (a live contract) untouched.
/// @custom:oz-upgrades-from src/core/InfraredV1_10.sol:InfraredV1_10
// solhint-disable-next-line no-empty-blocks
contract InfraredV2 is InfraredV1_10 {}
