# bOSMO / Backbone Labs — independent verification (child)

**Target:** `osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv`
**Chain:** Osmosis (`osmosis-1`) · **Code:** `741` · **Label:** `bOsmo-gravedigger-1` · **cw2:** `3.0.15`
**Admin/creator:** `osmo1lu92zj8q6cmrptu09rp3343x9969r9qr4w9r7h` · **Owner:** `osmo14dx3mv5shprckx724g2x5wppve0mzshtn05dnn`
**Snapshot:** block **72,830,341**, **2026-10-19T22:45:29Z** (all amounts below at this snapshot unless stated). Re-checked at block **72,830,598**, **2026-10-19T22:51:41Z**: `code_id 741`, admin, bank, bOSMO balance, `pending_batch 126`, and `state` are all identical (no submission/migration in between).
**Mode:** read-only; no tx signed/sent; public LCD/gRPC only; no keys used.

---

## Verdict (short)

| Item | Value |
|---|---|
| **E-U max net — join open batch 126** | **18,386.17 OSMO** |
| **E-U max net — submit 126 first, then batch 127** | **18,465.43 OSMO** |
| **Hard ceiling** | **18,893.31 OSMO** = the contract's entire remaining delegation (`N0`); payout cannot exceed `U ≤ N`. Because batch 126's `427.875822 OSMO` is already owed to its two owners, a single attacker's realised maximum is **18,465.43 OSMO** (scenario B); scenario A splits the same `N0` with batch 126 (attacker 18,386.17 + others ~507.14). |
| USD @ live DefiLlama OSMO **$0.0524936** (2026-10-19 ~22:27Z) | **$965.16** / **$969.32** (ceiling **$991.78**) |
| USD @ stated **$0.057396** | **$1,055.29** / **$1,059.84** (ceiling **$1,084.40**) |
| USD @ CoinGecko **$0.051936** | $954.8 / $959.0 (ceiling $981.2) |
| **Confidence** | **HIGH** on code/liveness/mechanism; **MEDIUM** on exact net (delegation-target race + admin can migrate/pause during the 14-day unbond) |
| **What closes it** | (1) admin migrates to fixed code (376a7fce or later) — one EOA tx; (2) owner pauses `135p8` (removes it from `VALIDATORS_ACTIVE`, making `E=0`); (3) SubDAO/governance redeems its remaining 359,940.35 bOSMO first; (4) any other batch drains the delegations; (5) admin changes denom / wipes batch state before withdrawal. |

**Honest read:** at the live DefiLlama price the max net is **just below $1k (~$965–$969)**; at the $0.057396 reference it is **just above $1k (~$1,055–$1,060)**. The true hard ceiling is ~$992 at the live price. This is a marginal ~$1k extraction, not a multi-thousand-dollar one. The mechanism is real and live.

---

## 1. Live state (block 72,830,341)

| Field | Value |
|---|---|
| `state.total_usteak` | `497,945,621,653` usteak = 497,945.621653 bOSMO (equals total supply) |
| `state.total_native` | `18,893,309,122` uOSMO = 18,893.309122 OSMO |
| `state.exchange_rate` | `0.037942514805695093` OSMO/bOSMO |
| `state.unlocked_coins` | `[]` |
| `config.validators` (= `VALIDATORS_ACTIVE`) | `135p8…`, `u2wsa…` (both) |
| `config.paused_validators` | `[]` |
| `config.epoch_period` / `unbond_period` | `259,200 s` (3 d) / `1,209,600 s` (14 d) |
| `config.fee_rate` / `max_fee_rate` | `0.1` / `0.1` (applies to **reward reinvestment only**, not bond/unbond) |
| `config.dust_collector` | `null` |
| `pending_batch` | id `126`, `usteak_to_burn = 7,517,966,316`, `est_unbond_start_time = 1792381669` = **2026-10-19T03:47:49Z (already past → ripe)** |
| Bank uOSMO | `47,660,549,593` = 47,660.549593 OSMO |
| Bank bOSMO | `7,517,966,316` = exactly pending batch 126's shares |
| Bank other | 3,000,000 + 1,000,000 of two IBC denoms (dust) |
| Delegations | `135p8… = 9,446,654,561`, `u2wsa… = 9,446,654,561`; total `18,893,309,122` |
| Unbonding (batches 124+125) | `1,301,208,705,547` uOSMO, completions 2026-10-24T01:59:16Z and 2026-10-30T03:47:49Z |
| Supply `factory/…/boneOsmo` | `497,945,621,653` (matches `state.total_usteak`) |
| `code_info` | code_id 741, admin `osmo1lu92…`, one instance; wasm SHA-256 = `3A06364B5A83A5B1A2F54EEF8BFD06BEAF6704EE22AE0DF1BDD1B04D06ED02B2` = `data_hash` |

The `state` query is exact: `total_native` is the sum of the two live delegations; the 47.66k uOSMO bank balance is **not** included in `total_native` or in the exchange rate.

---

## 2. Validator sets, decoded from raw state

The publicnode `/state` endpoint returns **hex keys** and **base64 values**. All 189 models were paginated (2 pages). Relevant entries:

| Raw key (hex) | Decoded key | Value (b64 → JSON) |
|---|---|---|
| `000E76616C696461746F72735F3030316F736D6F76616C6F706572317532777361…` | `\x00\x0evalidators_001` + `osmovaloper1u2wsa88eh738mk35a3cncgu7lc6cqf74jdl50x` | `e30=` → `{}` |
| `001576616C696461746F72735F6163746976655F3030316F736D6F76616C6F7065723133357038…` | `\x00\x15validators_active_001` + `osmovaloper135p8cjwa3hnnnksjxchda0a6339z9zm7cudyxn` | `e30=` → `{}` |
| `001576616C696461746F72735F6163746976655F3030316F736D6F76616C6F706572317532777361…` | `\x00\x15validators_active_001` + `osmovaloper1u2wsa88eh738mk35a3cncgu7lc6cqf74jdl50x` | `e30=` → `{}` |
| `636F6E74726163745F696E666F` | `contract_info` (cw2) | `{"contract":"steak-hub-tf","version":"3.0.15"}` |

Therefore, exactly as the deployed pre-fix code expects:

```
VALIDATORS          = { u2wsa }
VALIDATORS_ACTIVE   = { 135p8, u2wsa }
ACTIVE - VALIDATORS = { 135p8 }              <-- the validator that is double-counted
```

`135p8` is BackBone Labs' own validator (`moniker: BackBone Labs | Delegate for $SOUL Claim Drop`). Current status: **jailed, BOND_STATUS_UNBONDED**, unbonding time 2026-06-10 (stale). `u2wsa` (NFTSwitch.xyz) is **BOND_STATUS_UNBONDING**, unbonding time 2026-10-28. Neither is currently bonded, but both still hold the contract's delegations and both remain in `VALIDATORS_ACTIVE`; this matters for bond/undelegate (see §6).

---

## 3. Exact integer math and the live exploit

### 3.1 Deployed formulas (v3.0.15, commit `def0b49^`; pre-fix `376a7fce` of 2024-10-14)

```text
bond():
  m = floor(S * d / N)                       # S = state.steak_minted, N = sum(all delegations)
  delegate d to the ACTIVE validator with the smallest current delegation

submit_batch():                              # BUG
  N_all = sum(query_all_delegations)
  N_extra = sum(query_delegations(VALIDATORS_ACTIVE - VALIDATORS))
  U = floor((N_all + N_extra) * B / S1)      # S1 = supply BEFORE burning B
  undelegate U; burn B; record batch {total_shares: B, amount_unclaimed: U}

withdraw_unbonded():
  payout = floor(U * user_shares / B)
```

`Uint128::multiply_ratio` is floor(a·b/denominator) with a 256-bit intermediate. The raw `u128` subtraction in `compute_undelegations` is compiled with `overflow-checks = true` (see §4.1), so `U > N` **panics/reverts**; the attacker must keep `U ≤ N`.

### 3.2 Two exact on-chain validations of the deployed binary

| Check | Historical values | Formula | On-chain result |
|---|---|---|---|
| Mint (bond 0.1 OSMO, height 72,593,027) | S=523,613,718,149; N=20,414,535,035; d=100,000 uOSMO | `floor(S·d/N)` | **2,564,906** usteak — exact match |
| Batch 125 submit (height 72,610,033) | S=523,613,718,149; N=20,414,535,035; E=10,617,557,927; B=25,668,096,496 | `floor((N+E)·B/S)` | **1,521,225,913** uOSMO — exact match |

The batch-125 match is a direct fingerprint of the double-count: without `E` the formula gives `1,000,742,029`; the extra `10,617,557,927` (the 135p8 delegation at that moment) produces exactly the recorded `1,521,225,913`. This is not a source-reading inference; the deployed contract paid it.

### 3.3 Live rates

| Rate | Value |
|---|---|
| Mint (fair) | `N0/S0 = 0.03794251480569509` OSMO/bOSMO (26.355659 shares/OSMO) |
| Buggy redeem | `(N0+E0)/S0 = 0.05691377220854264` OSMO/bOSMO |
| Overpay ratio | **exactly 1.5×** (because `E0 = N0/2` exactly: 2×9,446,654,561 = 18,893,309,122) |

### 3.4 Exploit scenarios (exact floors)

`S0=497,945,621,653; N0=18,893,309,122; E0=9,446,654,561; B0=7,517,966,316`.

The bond goes to `135p8` (first in `VALIDATORS_ACTIVE` ascending order; both delegations are exactly equal at the snapshot, and the selection uses strict `<`). So the attacker's own deposit also increases the double-counted `E`: `E = E0 + d`, `N = N0 + d`.

| Variable | **A: join open batch 126 now** | **B: submit 126 first, then batch 127** |
|---|---:|---:|
| `d` (OSMO deposited) | **23,636.25** | **23,651.00** |
| `m` (bOSMO minted) | 622,948.956363 | 628,152.304250 |
| `b` (bOSMO burned; ≤ m) | 622,948.889321 | 628,140.054254 |
| `B` (batch total shares) | 630,466.855637 | 628,140.054254 |
| `N` after bond | 42,529.559122 | 42,116.433300 |
| `E` after bond | 33,082.904561 | 32,883.716650 |
| `S1` at submit | 1,120,894.578016 | 1,118,579.959587 |
| `U` undelegated (OSMO) | **42,529.559121** (= N) | **42,116.433299** (= N) |
| `payout` (OSMO) | **42,022.417801** | **42,116.433299** |
| **net = payout − d** | **18,386.167801 OSMO** | **18,465.433299 OSMO** |
| net USD @ $0.0524936 | **$965.16** | **$969.32** |
| net USD @ $0.057396 | **$1,055.29** | **$1,059.84** |
| net USD @ $0.051936 | $954.8 | $959.0 |

Notes:
- Exact base units (6 dp): **A** `d=23,636,250,000 uOSMO`, `m=622,948,956,363 usteak`, `U=42,529,559,121 uOSMO`, `payout=42,022,417,801 uOSMO`, `net=18,386,167,801 uOSMO`. **B** `d=23,651,000,000 uOSMO`, `m=628,152,304,250 usteak`, `U=42,116,433,299 uOSMO`, `payout=42,116,433,299 uOSMO`, `net=18,465,433,299 uOSMO`.
- In A, the existing 7,517.966316 bOSMO in batch 126 receives ~507.14 OSMO of the 42,529.56; the attacker gets 98.8%. Net is 97.3% of `N0`.
- In B, batch 126 is submitted first (permissionless) paying its owners `U126 = 427.875822 OSMO`; delegations fall to `N_after = 18,465,433,300`, supply to `S_after = 490,427,655,337`, `E_after = 9,232,716,650`. The attacker's batch 127 has `B0=0`, so they capture all of `N_after`; net = `N_after` exactly.
- The residual minted-but-unburned shares (A: 0.067042 bOSMO; B: 12.25 bOSMO) are dust at the fair rate (<0.5 OSMO).

**Net-vs-`d` shape (scenario A, exact):**

| `d` OSMO | `m` bOSMO | `b` burned | `U` OSMO | payout OSMO | net OSMO | net/d |
|---:|---:|---:|---:|---:|---:|---:|
| 1,000 | 26,355.659 | 26,355.659 | 1,960.179 | 1,525.134 | 525.134 | 0.525 |
| 5,000 | 131,778.297 | 131,778.297 | 8,480.881 | 8,023.159 | 3,023.159 | 0.605 |
| 10,000 | 263,556.595 | 263,556.595 | 17,207.743 | 16,730.504 | 6,730.504 | 0.673 |
| 20,000 | 527,113.190 | 527,113.190 | 35,643.490 | 35,142.273 | 15,142.273 | 0.757 |
| **23,636.25** | 622,948.956 | 622,948.889 | **42,529.559** | 42,022.418 | **18,386.168** | **0.778** |
| 30,000 | 790,669.784 | 705,688.931 | 48,893.309 | 48,377.921 | 18,377.921 | 0.613 |
| 50,000 | 1,317,782.974 | 967,171.038 | 68,893.309 | 68,361.922 | 18,361.922 | 0.367 |
| 100,000 | 2,635,565.948 | 1,624,056.085 | 118,893.309 | 118,345.473 | 18,345.473 | 0.184 |

Beyond ~23,636 OSMO, burning all minted shares would make `U > N` and revert; the attacker burns only `b_cap` so `U = N`. Net is essentially flat (~18.3–18.4k) and asymptotes to `N0 = 18,893.31` as `d → ∞`. The hard ceiling is `N0`: payout ≤ `U` ≤ `N = N0 + capital`, so `net ≤ N0` regardless of donations/capital.

**Capital/time/cost:**
- Capital: ~23,636–23,651 OSMO ≈ $1,241–$1,242 at $0.05249; ≈ $1,357–$1,358 at $0.057396.
- Scenario A locks for 14 days (batch 126 is ripe; `queue_unbond` auto-submits it in the same tx). Scenario B locks ~17 days (3-day epoch + 14-day unbond).
- Capital cost at 10% APR: ~91–111 OSMO (~$4.8–$5.8); at 20% ~$10–$12. Gas: <0.1 OSMO. Net after capital cost ≈ $955–$1,050 at the live/reference prices.
- Price risk: profit is denominated in OSMO; a 10% OSMO move changes the USD net by ~$96–$106.

### 3.5 Sensitivity — the one ordering detail that matters

If the attacker's bond instead lands on `u2wsa` (e.g., another bond hits `135p8` in the same block first), `E` stays at `E0` and the maximum net falls to the ceiling `E0 = 9,446.65 OSMO` (~$496 @ $0.05249; ~$542 @ $0.057396). The practical value at `d≈200k` is ~8,631 OSMO (~$453–$495). The current equality of the two delegations and the ascending set order favour the `135p8` case; an atomic bond→unbond helper would remove the race, but Osmosis code **upload is permissioned** (`code_upload_access: AnyOfAddresses`, ~50 addresses), so a bespoke helper is not freely deployable; existing whitelisted codes can be instantiated by anybody, so an existing generic executor might still be usable.

**Correction to prior local sim (`analysis/sim_results.json`):** its "batch 126 already submitted" case used `T` unchanged and reported 18,893.21 OSMO net. Submitting batch 126 necessarily reduces delegations by `U126 = 427.875822 OSMO`; the correct post-126 state is `N=18,465.433300`, `S=490,427,655.337`, `E=9,232,716.650`, and the correct net is **18,465.433299 OSMO** (not 18,893.21). The difference is exactly the 427.88 OSMO paid to the existing batch-126 owners.

---

## 4. Other entry points, the bank balance, bOSMO, community pool

### 4.1 Bank 47,660.549593 uOSMO — **not E-U**

| Component | OSMO |
|---|---:|
| Bank uOSMO | 47,660.549593 |
| Matured previous-batch claims (`est_unbond_end_time < now`, from `previous_batches_all`) | 2,427.040960 |
| In-flight batches 124 (1,299,687.479634) + 125 (1,521.225913) | 1,301,208.705547 |
| Incoming unbonding (sum of 4 entries; matches 124+125 exactly) | 1,301,208.705547 |
| **Residual unallocated** = bank + incoming − all batch liabilities | **45,233.508633** |

The 45.23k OSMO is not `total_native`, is not in any batch's `amount_unclaimed`, and has been stable at ~41.4k–47.7k since at least block 70M (gRPC historical balance 41,395,353,925 at 70M/72M; 47,655,192,840 at 72,237,940; 47,660,549,593 since 72,610,033). It is likely legacy "gravedigger"/protocol-owned residual or an unlabelled compensation pot; it is **S/P**, not E-U.

No permissionless entry point moves it:
- `bond` takes only `info.funds`; `queue_unbond` takes only bOSMO.
- `harvest`/`reinvest`: `prev_denom` is overwritten to the current bank at the start of every harvest; reinvest only delegates `current − prev` (rewards). It cannot delegate the surplus.
- `rebalance`: queries only `VALIDATORS` (=u2wsa) and rebalances among `VALIDATORS_ACTIVE`; currently produces no redelegations; no bank movement.
- `reconcile`: only deducts from batches when `bank < expected`; here bank+incoming > all liabilities, so it deducts nothing and moves nothing.
- `collect_dust`: permissionless but **filters out `uosmo` and `boneOsmo`**; `dust_collector` is `null`, so it is a no-op. Even if set, only the owner can set it.
- `withdraw_unbonded`: only the recorded `(batch_id, user)` requests; pays `floor(U·shares/B)`. It cannot pay the surplus.
- `withdraw_unbonded_admin`: owner-only; asserts owner, then calls `withdraw_unbonded(user = address, receiver = address)` — it can only pay an address's own requests back to itself, **not** redirect to the owner.
- `migrate`: admin-only (chain-enforced); the admin is a single-sig BaseAccount and can migrate at any time (P).
- `callback`: only `info.sender == contract`.

**Overflow-path hypothesis (rejected):** if `overflow-checks` were off, the raw `u128` subtraction in `compute_undelegations` would wrap when `U > N`, produce no undelegations, and let a batch record an `amount_unclaimed` up to the bank, draining the 47.66k and pushing E-U to ~$3.5k. The deployed wasm contains `attempt to subtract with overflow` (6×) and `attempt to add with overflow` (7×), and the v3.0.15 workspace `[profile.release]` sets `overflow-checks = true`; the wasm hash matches code 741. This path reverts; reject it with high confidence.

### 4.2 Contract bOSMO 7,517.966316 — **not free**

The bank's bOSMO is exactly `pending_batch[126].usteak_to_burn = 7,513,339,595 + 4,626,721` (the two unbond requests of `osmo1nf3f77…` and `osmo1aqt3…`). `submit_batch` burns exactly this balance. It is already owned by those two requesters and is not reachable by an attacker. At the buggy rate it will pay them `U126 = 427.875822 OSMO` (fair value 285.25; overpay ~142.6 OSMO).

### 4.3 Community pool / SubDAO bOSMO

- **Distribution-module community pool:** `5,014,598` usteak = **5.014598 bOSMO** (from `/cosmos/distribution/v1beta1/community_pool`). Governance-only (P); at the buggy rate it is worth ~0.285 OSMO. Not E-U.
- **Osmosis Liquidity SubDAO** `osmo1rvq5cq2j35k7sqqz49e5e8zezl45fcywcawazh46qnc0g96d0d6sasqsgc` (DAO DAO, code 365, self-admin): holds **359,940.348746 bOSMO** (72.3% of supply). This is the remaining Margined-vault bOSMO after the 776,000 bOSMO redemption. It is governance-gated (P), but it is a **direct competitor**: a proposal could redeem up to ~331,969 bOSMO (the `U ≤ N` cap) and capture the entire remaining `N0 = 18,893.31 OSMO`. SubDAO proposal **212 “[1049] Queue bOSMO unbond”** already executed the 776k redemption (batch 124); the latest 60 proposals contain no pending bOSMO redemption. A new proposal is the main P-path race.

---

## 5. DEX pools containing bOSMO

All 3,666 poolmanager pools were scanned for the bOSMO denom; **9 pools** contain it. Reserves (pool addresses' bank balances):

| Pool | Type | bOSMO | Quote reserves | Notes |
|---|---|---:|---|---|
| `osmo166yrd7…vgv4c` (custom CW pool, code 732) | ConstantProduct bOSMO/uOSMO | **1,302.974947** | **29.894991 uOSMO** | The only OSMO-quoted pool; spot ≈ 0.022944 OSMO/bOSMO |
| `1882` | GAMM bOSMO/LAB | 22.221966 | 11,899 LAB | 50/50; no OSMO leg |
| `1922` | CL bOSMO/uOSMO | 20.580491 | 0.036780 uOSMO + IBC dust | nearly empty |
| `3187` | GAMM bOSMO/allBTC/IBC | 9.331685 | 12 allBTC + 688,270 IBC | dust |
| `3240` | CL IBC/bOSMO | 6.015889 | 745,302 IBC | dust |
| `2158` | GAMM bOSMO/fMAD | 0.016726 | 26,149 fMAD | dust |
| `2588` | stableswap bOSMO/3 stables | 0.000796 | stable basket | dust |
| `2251`, `3479`, `3482` | CL | 0 liquidity | — | empty |

**Buying bOSMO below redemption value:** the custom pool is the only meaningful venue. With `x=1,302.974947 bOSMO`, `y=29.894991 OSMO`, 0.1% fee, and redemption `R=0.05691377`, the optimal buy is `b≈475.3 bOSMO`, cost `Δy≈17.19 OSMO`, redemption `≈27.05 OSMO`, gross profit `≈9.86 OSMO` (~$0.52–$0.57). Buying more approaches `x` with cost → ∞. This is **immaterial**.

**Minting and selling into pools:** the custom pool's marginal price is now 0.02294, **below** the 0.03794 mint cost, so mint→sell is currently a loss. It was profitable earlier on Oct 13–15: bot `osmo10z5dgmur6…` did ~40 cycles; e.g. tx `ADB3ADDE…` at height 72,581,455 bonded 5.171358 OSMO, got 132.640492 bOSMO, sold for 5.985716 OSMO → +0.814 OSMO gross before ~0.109 OSMO fees. That route is now drained; remaining DEX bOSMO is ~1,361 total (~77.5 OSMO at the buggy rate), so DEX E-U is at most ~$0.5–$1.

The forum's warning ("some bOSMO pools still price bOSMO well above what it can now be redeemed for") describes the **mint→sell** direction, not buy→redeem; that arbitrage has already been taken.

---

## 6. Migration / liveness

| Check | Result |
|---|---|
| `code_id` still assigned | **741**; one instance only (`/code/741/contracts`) |
| Admin migrated? | **No** — contract_info admin `osmo1lu92…`, code_id 741; cw2 `3.0.15` |
| `code_id 741` instantiate permission | `Everybody` (irrelevant to this instance; would only create a new unfunded copy) |
| Global pause | **None** in config/code; `paused_validators: []` |
| Owner pause switch | Owner can `pause_validator("135p8")`; that removes it from `VALIDATORS_ACTIVE`, making `E=0` and closing the bug. Not done. |
| Admin key | Single-sig `BaseAccount`, sequence 37 (active); can `migrate` at any time (P) |
| Owner key | Single-sig `BaseAccount`, sequence 1 |
| `epoch_period` / `unbond_period` | 259,200 s (3 d) / 1,209,600 s (14 d); chain staking unbonding_time also 1,209,600 s |
| Pending batch 126 | id 126, 7,517,966,316 shares, est start **2026-10-19T03:47:49Z** — already ripe; anyone can submit it |
| Validators | `135p8`: jailed, UNBONDED (unbonding 2026-06-10); `u2wsa`: UNBONDING (2026-10-28). Both still hold the contract's delegations and both are in `VALIDATORS_ACTIVE`. |
| Bond/undelegate to these validators | SDK v0.50.14-v30-osmo: `MsgDelegate` has **no jailed check** (only `CancelUnbondingDelegation` does). Keeper `Delegate` explicitly handles UNBONDED/UNBONDING. `MsgUndelegate` also has no jailed check; completion is now+14 days. So bond/undelegate work. |
| Forum | `forum.osmosis.zone/t/4161` posted 2026-10-15 by JohnnyWyles: “Until the contract is updated, the defect still applies, and anyone can still mint new bOSMO at about 0.039 OSMO each.” No later post; last_posted 2026-10-15T17:02Z. |
| Governance | Proposal **1049** passed (withdraw Margined positions, burn recovered OSMO); no newer bOSMO-related proposal in the latest 30. SubDAO proposal **212** executed the 776k redemption; no pending bOSMO redemption in its latest 60 proposals. |
| Fix commit | `376a7fce0346f32d200a7521d3fd4378c2a64d85` (2024-10-14) changes both `bond` and `submit_batch` to use `query_all_delegations`; deployed 3.0.15 predates it. |

**Race/liveness:** batch 126 is ripe now; an attacker can join it and auto-submit in one `unbond` tx (scenario A) or submit it first and attack batch 127 (scenario B). The 14-day unbond period is the exposure window: the admin (single key, fix pending) can migrate to new code, and governance/SubDAO can redeem the 359.9k bOSMO first. After the attacker's `submit_batch`, `amount_unclaimed` is fixed; a simple code migration that preserves batch state would not stop the payout, but a migration/denom change that wipes/reinterprets state could.

---

## 7. Verdict, categories, confidence

| Category | Amount | Notes |
|---|---:|---|
| **E-U (contract attack)** | **18,386.17 OSMO** (A) / **18,465.43 OSMO** (B) | Hard ceiling `N0 = 18,893.31 OSMO`. $965/$969 at live $0.0524936; $1,055/$1,060 at $0.057396. |
| **E-U (DEX buy-below-redeem)** | ~9.86 OSMO (~$0.5) | Custom pool only; not material. |
| **H-O** | batch 126 owners 427.88 OSMO; batch 125 owners 1,521.23 OSMO; batch 124 SubDAO 1,299,687.48 OSMO | Already queued/owner-specific; not attacker-reachable. |
| **P** | SubDAO's 359,940.35 bOSMO can redeem via governance (up to ~331,969 bOSMO, capturing `N0`); admin can migrate/pause; owner can change denom/fee | Governance/admin only. |
| **S** | ~45,233.51 OSMO bank surplus | No permissionless path; overflow path rejected (overflow checks). Likely legacy/protocol residual. |

**E-U max net USD:**
- **At live DefiLlama $0.0524936: $965.16 (A) / $969.32 (B); ceiling $991.78.** → **just below $1k.**
- At stated $0.057396: $1,055.29 / $1,059.84; ceiling $1,084.40. → just above $1k.
- At CoinGecko $0.051936: $954.8 / $959.0.

**Confidence:** HIGH that the bug is live, permissionless, and exactly 1.5× (two exact on-chain validations, wasm hash matches, raw state sets match). MEDIUM on the realised USD: depends on the bond landing on `135p8` (else ~$496–$542), the batch-126 race (A vs B differ by ~$4), the admin not migrating/pausing during 14 days, and the OSMO price at payout. LOW on any claim materially above ~$1.1k: the `U ≤ N` constraint hard-caps net at `N0 = 18,893.31 OSMO`.

**What would close it:** admin migration to a fixed code_id (376a7fce or later); owner `pause_validator(135p8)`; SubDAO/governance redeeming the remaining 359.9k bOSMO first; any other batch draining the 18.89k delegations; admin denom change/state wipe before withdrawal. **What would increase it:** a new OSMO deposit into the contract that gets delegated (e.g., `ReturnDenom`/compensation funds), raising `N0`; an OSMO price rally before payout.

---

## 8. Commands (read-only, public endpoints; no keys)

```bash
A=osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv
# contract info / code hash / one instance
curl -s https://osmosis-rest.publicnode.com/cosmwasm/wasm/v1/contract/$A
curl -s https://osmosis-rest.publicnode.com/cosmwasm/wasm/v1/code/741
curl -s https://osmosis-rest.publicnode.com/cosmwasm/wasm/v1/code/741/contracts
# smart queries (base64 the JSON)
for q in state config pending_batch; do
  b=$(printf '{"%s":{}}' "$q" | base64 -w0)
  curl -s https://osmosis-rest.publicnode.com/cosmwasm/wasm/v1/contract/$A/smart/$b; echo
done
# raw state (hex keys, base64 values; paginate with pagination.key)
curl -s "https://osmosis-rest.publicnode.com/cosmwasm/wasm/v1/contract/$A/state"
# balances / supply / delegations / unbonding
curl -s https://osmosis-rest.publicnode.com/cosmos/bank/v1beta1/balances/$A
curl -s 'https://osmosis-rest.publicnode.com/cosmos/bank/v1beta1/supply/by_denom?denom=factory/'$A'/boneOsmo'
curl -s https://osmosis-rest.publicnode.com/cosmos/staking/v1beta1/delegations/$A
curl -s https://osmosis-rest.publicnode.com/cosmos/staking/v1beta1/delegators/$A/unbonding_delegations
# validator status and SDK behavior
curl -s https://osmosis-rest.publicnode.com/cosmos/staking/v1beta1/validators/osmovaloper135p8cjwa3hnnnksjxchda0a6339z9zm7cudyxn
curl -s https://osmosis-rest.publicnode.com/cosmos/staking/v1beta1/validators/osmovaloper1u2wsa88eh738mk35a3cncgu7lc6cqf74jdl50x
# community pool / prices / gov / forum
curl -s https://osmosis-rest.publicnode.com/cosmos/distribution/v1beta1/community_pool
curl -s https://coins.llama.fi/prices/current/coingecko:osmosis
curl -s 'https://api.coingecko.com/api/v3/simple/price?ids=osmosis&vs_currencies=usd'
curl -s 'https://osmosis-rest.publicnode.com/cosmos/gov/v1/proposals?pagination.limit=30&pagination.reverse=true'
curl -s https://forum.osmosis.zone/t/4161.json
# historical state (archival gRPC; x-cosmos-block-height)
grpcurl -plaintext -rpc-header 'x-cosmos-block-height: 72610033' \
  -d '{"delegator_addr":"'$A'"}' osmosis-grpc.polkachu.com:12590 \
  cosmos.staking.v1beta1.Query/DelegatorDelegations
# exact math
python3 analysis/exploit_math.py
```

No keyed RPC URLs or secrets were used or written.

---

## 9. Files (all in `analysis/`)

| File | Contents |
|---|---|
| `exploit_math.py` / `exploit_math_output.json` | Exact integer reproduction, two historical validations, A/B optima, USD |
| `onchain_validation.json` | Mint + batch-125 exact-match evidence |
| `historical_delegations.json` | Delegations at heights 72,237,939 / 72,568,454 / 72,593,027 / 72,610,033 / 72,830,341 |
| `contract_info.json`, `state.json`, `config.json`, `pending_batch.json` | Fresh snapshot 72,830,341 |
| `raw_state_all.json` | 189 raw models (hex keys / b64 values) incl. the two validator sets and cw2 `3.0.15` |
| `previous_batches_all.json` | 37 batches (2…125), amounts/shares/times |
| `delegations.json`, `unbonding.json`, `bank_balances.json`, `supply.json`, `rewards.json` | Staking/bank state |
| `validators_status.json` | 135p8 jailed/UNBONDED; u2wsa UNBONDING |
| `code741.json`, `code741.wasm` | Deployed wasm + code_info; SHA-256 matches data_hash `3A06364B…` |
| `pool_balances.json`, `pools_with_bosmo.json` | 9 pools + custom/CL balances |
| `community_pool.json`, `gov_proposals.json`, `subdao_props.json`, `forum_4161.json` | P-path / liveness context |
| `osmo_price.json`, `cg_price.json`, `cg_bosmo.json` | Price snapshots |
| `sim_bosmo.py`, `sim_results.json` | Prior local sim (left untouched); its post-126 case is corrected in §3.5 |
