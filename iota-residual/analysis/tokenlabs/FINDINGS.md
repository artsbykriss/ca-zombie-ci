# TokenLabs vIOTA (IOTA L1) — live re-verification & findings

*Prepared by a read-only research subagent (zombie-hunt II, tier 3), 2026-10-15. All data from keyless
public RPC `https://api.mainnet.iota.cafe` (read-only calls: `iota_getObject`, `iotax_queryEvents`,
`iotax_queryTransactionBlocks`, `iota_getNormalizedMoveModulesByPackage`). No transaction was signed or sent.*

**Recorded reference point**

| item | value |
|---|---|
| latest checkpoint | `204,076,768` when the event sweep ran; `204,082,530` on re-verification |
| current IOTA epoch | `528` (`iotax_getCommitteeInfo`) |
| total transaction blocks | `959,186,072` |
| pool / metadata object version | `845,339,840` (digest `D68ukny2pSDxkqAZCmTDeDAU7B37wXXcyEbkMtmQcHxu` / `BqrSjuCx7JCptcuDbocRKAUnR5MHBbbuJH1goV7L3QZ`) |

⚠️ **Read-race caveat discovered during verification.** A stake tx of exactly 101,252.0 IOTA landed at 2026-10-15
08:02:53 UTC *between* my reads (pool read at 08:01, vault/supply reads at 08:07), so the first snapshot mixed a pre-stake
pool with post-stake vaults. Both snapshots were then checked against each other and the formula below reproduces the
observed ratio in **both** (§2). Anyone re-reading these objects should pin one checkpoint; live object reads of different
objects taken minutes apart on a busy day can belong to different transaction versions.

Raw JSON for everything in §2–§4 is in `live/` and `events/` next to this file.

---

## 1. THE PACKAGE HAS TWO VERSIONS — the live one is NOT `0xe4ab…`

This is the single most important structural correction to the brief.

| role | package id | notes |
|---|---|---|
| **v1 (original, published)** | `0xe4abf8b6183c106282addbfb8483a043e1a60f1fd3dd91fb727fa284306a27fd` | object version `1`, `Immutable`. Published in tx `6h4aXERta56Z5EBgi9k2hFt8NcwCdhEHLVrTHRguef29` (2026-02-02 21:10:38 UTC) |
| **v2 (ACTIVE)** | `0x6ab984dfae09bbef27551765622a85f461e0b46629eee60807b6e5399c0f7f0f` | object version `2`, `Immutable`. Created by the upgrade tx `6rX7AeYmoYnHyAZzw815sTAsSohP7Tut6eKbPUdzjBdx` (2026-02-21 12:14:44 UTC, sender `0x5555…b54ae7c`) |

Evidence: the live user transactions call **`0x6ab984df…::native_pool::stake` / `::unstake`**, while the objects they
mutate are the *original* types `0xe4abf8b6…::native_pool::NativePool` and `0xe4abf8b6…::cert::Metadata<CERT>`
(verified on tx `ByBrU3kwbjagdBA2X91s9pDV8dBWgf41ZZ42BZ4GATQC` and `BrCgRmN8Vv6dBGEzZ5CR8w5DzszHGkFzcwFxLcwKdb3Y`).
Sui/IOTA keeps the *original* package id in type strings across upgrades, so events and object types keep printing
`0xe4ab…` — but the code that runs is v2.

* `pkg_abi.txt` in this folder (29 `native_pool` functions) is the **v1** ABI. The **v2** ABI (31 functions) is in
  `pkg_abi_v2_active.txt`. **v2 adds:** `native_pool::change_validator_cap_base`, `native_pool::get_validator_cap_base`,
  `validator_set::get_validator_priority`, and the event `ValidatorCapBaseChangedEvent`, plus a **new dynamic field on the
  pool object**: name `validator_cap_base`, type `u64`, object `0x4e98e0716ae95e09ed91dda6f67ab204a40899f9d747c8f750e1b43b2cf35676`
  (version 455,954,043), current value **`4000000000000000` = 4,000,000 IOTA**.
* `NativePool`, `ValidatorSet`, `Metadata`, `math` and `ownership` **struct layouts are unchanged** between v1 and v2.
* The `native_pool::migrate` / `cert::migrate` (1→2) events fired minutes after the upgrade:
  pool migrate tx `7Qm6KaztM4iBUjBx21CuWHrjyCF4n2pTuMd932nrFoAL` (12:16:24), cert migrate tx
  `3spZUUzqXRXuPYqRHUGanYHvbgsrYn9nx69JqT3Uagz9` (12:15:55), unpause tx `CifZA71mS26tPuCkoQXMqQwAXJFFt28LGU6xK4esi9Qv` (12:16:52).
* **Audit gap:** the MoveBit report (`audit_excerpts.md`) is dated Jan 14 2026 and its scope is the *v1* file set; the
  strings `validator_cap_base`, `get_validator_priority` and `ValidatorCapBaseChangedEvent` appear **nowhere** in the report
  text. The v2 delta is therefore **not covered by the published audit**.

## 2. Live pool + vIOTA state

Pool object `0xb435fa61ee8d5473ab36de02c88756f8c74fcc031b4e3a2fe2a6647bb06b2872`
(`…::native_pool::NativePool`), object version `845,339,840`, digest `D68ukny2pSDxkqAZCmTDeDAU7B37wXXcyEbkMtmQcHxu`,
`initial_shared_version 427,133,775` (same as publish tx), raw: `live/pool_latest.json` + `live/obj_*` re-read.

| field | value (wei, 9 decimals) | human |
|---|---|---|
| `total_staked` | 3,597,964,219,313,557 | 3,597,964.219313557 IOTA — **equals Σ over the 17 vaults exactly** |
| `total_rewards` | 255,612,938,399,482 | 255,612.938399482 IOTA |
| `collected_rewards` | 0 | 0 |
| `pending` | 0 | 0 |
| `paused` | `false` | — |
| `min_stake` | 1,000,000,000 | 1 IOTA |
| `base_reward_fee` | 99 | — |
| `rewards_threshold` | 100 | — |
| `max_validator_stake_per_epoch` | 1,000,000,000,000,000 | 1,000,000 IOTA |
| `staked_update_epoch` | 0 | never set (informational only — the field is not used to gate anything I could observe) |
| `rewards_update_ts` | 1,791,968,409,786 | 2026-10-14 09:00:09 UTC |
| `version` | 2 | migration guard |
| `validator_cap_base` (v2 dyn. field) | 4,000,000,000,000,000 | 4,000,000 IOTA |
| validators configured | 17 (priorities 100/25/25/25/8×9/5×4) | — |

(One stake of 101,252.0 IOTA at 2026-10-15 08:02:53 changed `total_staked` from 3,496,712,219,313,557 →
3,597,964,219,313,557 and minted 94,328.402370174 vIOTA; the two snapshots are both used in the ratio check below.)

**vIOTA / CERT**

| item | value |
|---|---|
| `cert::Metadata<CERT>` | `0xb45b32d8d58c6499795036faa92b0561c6df089cdd4fc6ae8a0543981a698bf1` (shared, v. `845,339,840`) |
| `total_supply` | **3,590,070,089,452,751** (3,590,070.089452751 vIOTA), `Metadata.version = 2` |
| `CoinMetadata` | `0x50d127ae6898a79eea54a85262441eadb2b008e2aeb2ef57457e756d73cd4671` — symbol `vIOTA`, name `vIOTA`, decimals `9`, "Tokenlabs Liquid Stake - Reward-bearing staked IOTA token" |

**Exchange ratio — derived on-chain, verified to 11 decimal places on two snapshots.** `math::to_shares(ratio: u256, amount: u64)`
computes `shares = amount * ratio / RATIO_MAX` (audit MAT-4), and

**ratio = (`total_staked` + `total_rewards`) / `Metadata<CERT>.total_supply`**  (all three fields of the same pool/metadata)

```
snapshot A (post-stake, object version 845,339,840):
   (3,597,964,219,313,557 + 255,612,938,399,482) / 3,590,070,089,452,751 = 1.073398864561
   observed in StakedEvent 2026-10-15 08:02:53 (101,252.0 IOTA -> 94,328.402370174 vIOTA) = 1.073398864561
snapshot B (pre-stake, object version 845,129,973, supply net of the 94,328.402370174 vIOTA minted after it):
   (3,496,712,219,313,557 + 255,612,938,399,482) / 3,495,741,687,082,577 = 1.073398864561
   observed in StakedEvent 2026-10-15 05:30:16 = 1.073398864572   (floor-division rounding)
```

i.e. **1 vIOTA = 1.073398864561 IOTA** at the reference checkpoint. No other combination of the known fields reproduces it
(`total_staked/supply` = 0.97400, `Σvault/supply` = 1.00220 — and `total_staked` *equals* `Σvault` anyway, see the
consistency check just above). The numerator's component `total_staked` is confirmed consistent with the sum of the 17
`validator_set::Vault` entries (`live/vault_objects.json`); **only one vault is non-empty**:
`0xe7f6929a0d929a0ef8c590b840cfbfd12326fc00844841ed623c8c7cd2c3a1a2` holds **3,597,964.219313557 IOTA in 529 `StakedIota`
receipts**, `stake_epoch = 528` (current). The other 16 vaults are `0`.
*Uncertainty:* `collected_rewards` is 0 right now, so a formula variant that subtracts it cannot be distinguished today.

## 3. Activity timeline (from `iotax_queryEvents`, raw in `events/`)

| when (UTC) | what |
|---|---|
| 2026-02-02 21:10:38 | **protocol published** (pool, metadata, CoinMetadata, OwnerCap, OperatorCap, UpgradeCap created) |
| 2026-02-02 21:28 | `change_base_reward_fee` 95 → **99** |
| 2026-02-02 → 02-24 | validator set tuning: `update_validators` many times, `change_max_validator_stake_per_epoch` 12× (up to 1,000,000 IOTA), `add_pending` 3× (500/800 IOTA) |
| 2026-02-21 12:13:19 | **`set_pause(true)`** — protocol paused |
| 2026-02-21 12:14:44 | **package upgrade v1 → v2** (`0x6ab984df…`), sender `0x5555…b54ae7c` |
| 2026-02-21 12:15:55 / 12:16:24 | `cert::migrate` 1→2, `native_pool::migrate` 1→2 |
| 2026-02-21 12:16:52 | **`set_pause(false)`** — 3.5 min downtime in total |
| 2026-02-21 14:45–16:28 | `change_validator_cap_base` 3× (new v2 admin function) |
| 2026-03-15, 2026-04-18 | `change_base_reward_fee` (3 more events; last change 2026-04-18 20:28) |
| 2026-08-30 10:58:31 | last `update_validators` / `ValidatorsUpdatedEvent` |
| 2026-08-26 → 2026-10-14 | **daily cron at 09:00:0x UTC: `update_rewards` + `collect_fee_new`** (50 consecutive days observed, `hasNextPage=true`), always tx-sender `0x5555…b54ae7c` |
| 2026-10-06 → 2026-10-15 | user `stake_to_validators` calls (last 2026-10-06 23:07) and `stake` calls (last 2026-10-15 08:02) |
| 2026-10-14 09:00:10 | last `FeeCollectedEvent` (`to = 0x5555…b54ae7c`, `value = 11,128,691,291` = 11.13 IOTA) |
| 2026-10-14 11:08:26 | last `UnstakedEvent` (3,498.10 IOTA paid for 3,258.90 vIOTA) |
| 2026-10-15 05:30:16 | last `StakedEvent` *returned by `iotax_queryEvents`* (98.04 IOTA → 91.336 vIOTA). The event index was several hours behind the tx index during this sweep: the 08:02:53 stake's own `StakedEvent` is present inside its transaction, just not yet in event queries |
| 2026-10-15 08:02:53 | newest `stake` tx `E7LLLSCZrbGQFDviKkpnH2cQWc8BMWdGY85dEiCRPAZS`, sender `0x5534b441f7bd…`, amount **exactly 101,252.0 IOTA** → 94,328.402370174 vIOTA, status `success` (the event index lags a few hours behind the tx index for this type) |

**The protocol is live and active** (several stakes per day, occasional large unstakes, daily reward accounting).
Event history returned by this RPC reaches back to 2026-02-02 (the launch), and the global
`0x3::validator::StakingRequestEvent` query reaches back to 2025-05-05 (IOTA mainnet launch), so the index is *not*
truncated at February — the February start of TokenLabs events is the protocol's real launch.

**`rebalance` and `publish_ratio`: ZERO calls, ever.**
* `iotax_queryTransactionBlocks` `MoveFunction` filter returns **0 transactions with `hasNextPage=false`** for
  `native_pool::rebalance` and `native_pool::publish_ratio` on **both** the v1 and the v2 package id.
* Correspondingly there is **no `RebalanceEvent` and no `RatioUpdatedEvent` in the entire event history**.
* `publish_ratio(&NativePool, &Metadata<CERT>)` takes **only immutable references** (v2 ABI, `pkg_abi_v2_active.txt`), so it
  cannot write anything — it can only emit `RatioUpdatedEvent { ratio }`. It has never been called, so the protocol has
  **never published its ratio on chain** (the ratio is computed on demand, as §2 shows).
* `rebalance(&mut NativePool, &mut IotaSystemState, &mut TxContext)` is a **public entry with no capability argument**;
  per the audit it "moves staked IOTA from bad validators into other validators". Nobody has ever called it.

No `MinStakeChangedEvent`, `RewardsThresholdChangedEvent`, `RewardsRevertedEvent`, `OwnerCapTransferred`,
`OperatorCapTransferred` have ever been emitted.

## 4. Capabilities (owners)

| object | id | owner |
|---|---|---|
| `ownership::OwnerCap` | `0x78c15e70e20c79065c7f1fd80eedfb5cc0d40fc27229bf438dbcdbd99761c171` | `0x5555679093281ffa85c51c24b55fc45ff0f1bb6a57c0bee2c61eae3d5b54ae7c` |
| `ownership::OperatorCap` | `0x636bda347a5e4f54f39f0cac782e91a112b2bf05cf634509ed3bae6b7dc4d656` | `0x5555679093281ffa85c51c24b55fc45ff0f1bb6a57c0bee2c61eae3d5b54ae7c` |
| package `UpgradeCap` (created at publish, re-created by the Feb-21 upgrade) | `0xed9b69c2062589d8af3f96524bfdf1c304a25c6ee7f80563f397e88ae8350f45` | `AddressOwner 0x5555679093281ffa85c51c24b55fc45ff0f1bb6a57c0bee2c61eae3d5b54ae7c` |

Every privileged call observed (`set_pause`, `change_base_reward_fee`, `update_validators`, `update_rewards`,
`collect_fee_new`, `change_validator_cap_base`, both `migrate`s, the package upgrade) has been sent by
**`0x5555679093281ffa85c51c24b55fc45ff0f1bb6a57c0bee2c61eae3d5b54ae7c`**, which is also a heavy user (it stakes and its
address is the `to` field of `FeeCollectedEvent`). Both caps and the upgrade right sit with one key.

**Single pool.** The publish transaction created exactly one `NativePool`, one `ValidatorSet` (inside it), one
`cert::Metadata`, one `CoinMetadata`, one `OwnerCap` and one `OperatorCap`. None of the modules exposes a public
pool/metadata constructor (`native_pool` has no `create` in the public ABI; `validator_set::create` is friend-only), so
there is **no second pool instance** to be found — the shared object `0xb435fa61…` is the only `NativePool` and
`0x8a49f19e…` the only `ValidatorSet`.

## 5. Framework epoch semantics (short version — full quotes in `framework/README.md`)

* `request_add_stake` sets `stake_activation_epoch = ctx.epoch() + 1` (validator.move:277) and returns a self-custodial
  `StakedIota { id, pool_id, stake_activation_epoch, principal }` (staking_pool.move:73-82, 107-124). Permissionless.
* `request_withdraw_stake` (staking_pool.move:129-177) gates **only** on
  `if (staked_iota.stake_activation_epoch > ctx.epoch())`: if the stake is not yet active it returns **principal only,
  immediately**; otherwise it returns **principal + rewards immediately**, with the rewards computed as
  `value_at_current_rate − principal`, capped by `rewards_pool.value()` (line 284).
  **It never returns 0 and never defers payment** — `pending_total_iota_withdraw`/`pending_pool_token_withdraw` are pure
  epoch-boundary accounting (`process_pending_stake_withdraw`, lines 245-250), and line 174 literally says
  `// TODO: implement withdraw bonding period here.` The unused constant `EWithdrawalInSameEpoch` (line 29) is dead code.
* Rewards are added to `pool.rewards_pool` at the epoch boundary (`deposit_rewards`, lines 219-222) and become claimable
  from the moment the epoch-boundary exchange-rate entry exists (`process_pending_stakes_and_withdraws`, lines 224-241).
  There is no "claim-only" function; rewards surface when the `StakedIota` is withdrawn.
* Funds are paid in the **same transaction** (entry wrapper `iota_system.move:254-271` converts the returned
  `Balance<IOTA>` to a `Coin<IOTA>` and transfers it to the sender).

## 6. Security-relevant observations

**6.1 Unstaking is instant, unqueued and uncapped — the user's IOTA comes from the vault receipts.**
The last observed user unstake paid out in the same transaction (`balanceChanges`: `+3,498,103,488,649` IOTA,
`−3,258,901,632,321` vIOTA, status `success`). TokenLabs' `unstake` unwinds the pool's own `StakedIota` receipts through
the framework and pays the user from them; the framework itself has **no unbonding period**, so TokenLabs inherits "pay
now, settle the pool's books at the epoch boundary". Consequences worth probing: (a) a large unstake must be serviced by
the vault's receipts at the *current* framework exchange rate, and the framework caps the reward leg at the validator
pool's `rewards_pool` balance — a large withdrawal immediately after a big reward event can pay less than the UI's
expected rewards; (b) TokenLabs' own `pending` buffer is **0** and `add_pending` has not been called since February, so
there is no liquidity buffer to smooth withdrawals — everything is expected to come out of the framework immediately;
(c) the observed behaviour after a withdrawal is that the *reward portion is re-staked* (in the last unstake tx a
`0x3::validator::StakingRequestEvent` of 6.37 IOTA immediately follows the 3,497 IOTA withdrawal), i.e. the vault's
receipt set is continuously rolled over.

**6.2 The exchange ratio is fed by an operator-supplied number.** `update_rewards(&mut NativePool, &Clock, u64,
&OperatorCap)` receives only a `Clock` — it has no access to `IotaSystemState`, so it *cannot* read the validators'
accrued rewards; the `u64` must be computed off-chain and submitted by the operator (`RewardsUpdated { value }` records
it). That number is a **direct input to the mint/burn ratio** (§2): setting `total_rewards` too high over-values vIOTA
(unstakers are overpaid until the vault's real IOTA is exhausted), too low dilutes unstakers. The owner can post-hoc
rewrite it via `update_rewards_revert(&mut NativePool, u64, &OwnerCap)`. This is a trusted-updater design with a single
key (`0x5555…b54ae7c`) and should be treated as the protocol's primary centralisation assumption. Observed values are
small relative to TVL (255.6 IOTA = 0.007 % of the 3.6 M IOTA staked) and move in both directions between events, i.e.
the number is a *rolling buffer*, not cumulative lifetime rewards — I did **not** verify the exact accrual/fee formula
(the source is not public); `base_reward_fee = 99`, `rewards_threshold = 100`, `collected_rewards = 0`, and the daily
`collect_fee_new` currently realises ≈ 11 IOTA/day by unstaking from the vaults and sending it to `0x5555…b54ae7c`.

**6.3 `total_staked` IS maintained correctly (retraction of an earlier stale-read suspicion) — but the read-race is a
monitoring trap.** `pool.total_staked` equals Σ `vault.total_staked` **exactly**
(3,597,964,219,313,557 both ways) and is updated by the `stake` path (verified: it moved by exactly the 101,252.0 IOTA
stake of 2026-10-15 08:02:53). `staked_update_epoch` stays `0` (dead field; it is not used as a gate as far as I could
observe). The trap is temporal: my first snapshot read the pool 2 minutes before that stake and the vaults 5 minutes
after, which produced a phantom 101,252 IOTA "inconsistency" until both snapshots were re-taken together (§2). Anyone
monitoring this protocol against a single `iota_getObject` read must pin a checkpoint, and must not compare
`get_total_staked()` (pool object) with the vault tables read at a different moment.

**6.4 `rebalance` is a permissionless, cap-free state-mutating entry that has never been exercised.**
Anyone can call `rebalance(pool, iota_system, tx_ctx)`: it is a public entry whose only inputs are two shared objects.
Per the audit it re-allocates stake away from "bad" validators; it cannot hand IOTA to the caller (funds stay in the
pool's vaults), but it is an unauthenticated path that can force stake churn across validators and rewrite the pool's
internal accounting, and it is on the *never-executed* list, so its production behaviour is unproven. The same applies to
`stake_to_validators_non_entry` paths. Note the design tension: the protocol *does* have a logic that moves stake between
validators at stake time (`stake_to_validators`, `update_validators` with priorities) yet never uses `rebalance`.

**6.5 Total concentration in one validator.** 100 % of the 3.5979 M IOTA TVL sits in the single validator
`0xe7f6929a0d929a0ef8c590b840cfbfd12326fc00844841ed623c8c7cd2c3a1a2` (vault `total_staked = 3,597,964.219313557`,
529 receipts), even though 17 validators are configured with priorities (100/25/…/5) and `validator_cap_base = 4 M IOTA`.
The vault fill logic therefore appears to be "fill by priority up to `validator_cap_base`", and the TVL is 90 % of that
cap — the moment TVL crosses 4 M IOTA it must spill into the next validator, which is the first real exercise of the
distribution logic. A single validator's downtime/slashing is a 100 % TVL event; note the framework rewards a
non-performant validator less (rewards are score-adjusted) but does not slash delegated principal in IOTA.

**6.6 Capability concentration & upgradeability.** `OwnerCap`, `OperatorCap` and (from the upgrade tx) the `UpgradeCap`
are all with `0x5555…b54ae7c`. That key can pause the protocol, change fee/limits, push the reward bookkeeping, collect
fees, re-run `migrate`, and publish further *compatible* upgrades of the package. There is no timelock, and no
multisig evidence was found (single AddressOwner on all three objects).

**6.7 The v2 delta is unaudited.** The published audit covers the Jan-2026 v1 files; the v2 package (Feb 21 2026) added
`change_validator_cap_base` / `get_validator_cap_base` / `validator_set::get_validator_priority` /
`ValidatorCapBaseChangedEvent` and the `validator_cap_base` dynamic field. `validator_cap_base` (4 M IOTA) is the value
that actually bounds per-validator exposure now, and it was never reviewed.

## 7. Files produced

| path | content |
|---|---|
| `FINDINGS.md` | this document |
| `framework/README.md` | framework staking semantics with quoted source + line numbers, provenance & deployment check |
| `framework/*.move` | `staking_pool.move`, `validator.move`, `validator_set.move`, `iota_system.move`, `iota_system_state_inner.move`, `coin.move`, `balance.move` (`develop` branch, byte-identical to `mainnet` branch) |
| `audit_excerpts.md`, `movebit_audit_2026-01-14.pdf` | MoveBit/BitLab audit: findings, code excerpts, actors; PDF source `https://movebit.xyz/reports/20260202-Tokenlabs-Final-Audit-Report.pdf` |
| `pkg_abi_v2_active.txt` | ABI of the **live** v2 package `0x6ab984df…` (31 `native_pool` fns) |
| `pkg_abi.txt` (pre-existing) | ABI of **v1** `0xe4ab…` (29 fns) — kept for reference, superseded |
| `live/*.json` | pool (`pool_latest.json` = version 845,339,840; `pool_prestake_v845129973.json` = the earlier snapshot), metadata, CoinMetadata, vault table + vault objects, cap objects, sample txs, system state, committee info, MoveFunction query results |
| `events/*.json` | raw event queries per event type (last 50) + module-level queries |
