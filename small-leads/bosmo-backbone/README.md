# bOSMO / Backbone Labs — live double-count redemption on Osmosis `code_id 741`

**Status:** read-only assessment, 2026-10-19. No transactions signed or sent. All state read from
public Osmosis LCD/RPC; the deployed CosmWasm build was matched to the public v3.0.15 source.

## TL;DR

| Item | Value |
|---|---|
| Chain / contract | Osmosis · `osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv` (`bOsmo-gravedigger-1`, `code_id 741`) |
| Deployed build | `pfc-steak-hub-tf` **v3.0.15** (pre-fix; fix commit `376a7fce`, 2024-10-14) |
| Live bug | redemption double-counts the delegation to `osmovaloper135p8…` (in `VALIDATORS_ACTIVE`, absent from `VALIDATORS`) |
| Mint rate now | **0.0379425 OSMO/bOSMO** |
| Redeem rate now | **0.0569138 OSMO/bOSMO** = **1.500×** |
| E-U headline (max net) | **18,386.17 OSMO ≈ $965.16** at OSMO $0.0524936 (join batch 126); **18,465.43 OSMO ≈ $969.32** if batch 126 is submitted first; hard ceiling **18,893.31 OSMO ≈ $991.78** |
| At pass-2 price $0.057396 | $1,055.29 / $1,059.84; ceiling **$1,084.40** |
| Capital / lockup | 23,636–23,651 OSMO (~$1,241) · 14-day unbond (+3-day epoch in scenario B) |
| Confidence | **HIGH** on mechanism + liveness; **MEDIUM** on realised USD (bond-target race, OSMO price, admin migration/SubDAO redemption during the 14-day unbond) |
| Bank balance 47,660.55 OSMO | **not** attacker-reachable: prior-batch claims + ~45.2k OSMO residual/compensation (S/P) |
| Verdict | **E-U ~$0.97k**, live now; the hard ceiling is the 18.89k OSMO delegation. Closes on admin migration, owner pausing `135p8`, or the SubDAO redeeming its 359,940 bOSMO first |

## 1. Mechanism, in exact terms

`pfc-steak-hub-tf` v3.0.15 (`contracts/hub-tf/src/execute.rs`, `math.rs`) uses two different
validator sets for minting and redemption:

* **Mint (`bond`)** queries delegations to `VALIDATORS_ACTIVE` plus `VALIDATORS \ VALIDATORS_ACTIVE`
  (paused validators), i.e. the whole whitelist → `native_bonded_mint = T`.
* **Redeem (`submit_batch`)** queries `query_all_delegations()` (all delegations, `T`) **plus**
  `query_delegations(VALIDATORS_ACTIVE \ VALIDATORS)` and adds them, i.e.
  `native_bonded_redeem = T + R`.

If a validator is in `VALIDATORS_ACTIVE` but not `VALIDATORS`, its delegation `R` is counted twice
on every redemption. On this contract:

* `VALIDATORS` = `{osmovaloper1u2wsa88eh738mk35a3cncgu7lc6cqf74jdl50x}` (raw-set counter = 1)
* `VALIDATORS_ACTIVE` = `{osmovaloper135p8cjwa3hnnnksjxchda0a6339z9zm7cudyxn, osmovaloper1u2wsa…}` (counter = 2)
* `delegations` = 9,446,654,561 uOSMO each → `T = 18,893,309,122`, `R = 9,446,654,561`
* `T + R = 28,339,963,683` → `28,339.963683 / 497,945.621653 = 0.05691377 OSMO/bOSMO`, exactly 1.5× the mint rate.

The deployed cw2 version `3.0.15` is the last build before the fix commit `376a7fce`
(“use ALL delegations, instead of inactive ones”, merged 2024-10-14, released in 3.0.20). The
fix changes `compute_unbond_amount` to use `all_delegations` once, exactly removing the `+R`.

### Historical proof in live state

Batch 124 (the 2026-10-10 community-pool redemption) paid **1,299,687.479634 OSMO for
776,000.000000 bOSMO = 1.67485 OSMO/bOSMO**, while the Osmosis forum states the contract’s own
pre-incident rate was **1.1174 OSMO/bOSMO** (≈1.499×). That is the bug executing at scale.

## 2. Live state (Osmosis block 72,829,675, 2026-10-19T22:29:03Z)

| Field | Value |
|---|---|
| `code_id` / admin | 741 / `osmo1lu92zj8q6cmrptu09rp3343x9969r9qr4w9r7h` (single-sig BaseAccount, pubkey set) |
| code 741 instances | 1 (this contract only) |
| `state.total_usteak` | 497,945.621653 bOSMO |
| `state.total_native` | 18,893.309122 OSMO |
| `state.exchange_rate` | 0.037942514805695093 |
| bank `uosmo` | 47,660.549593 OSMO |
| bank bOSMO | 7,517.966316 (already queued in pending batch 126) |
| delegations | 9,446.654561 OSMO to each of the two validators |
| unbonding in flight | 1,301,208.705547 OSMO (batches 124/125; completes 2026-10-24 / 10-30) |
| pending batch 126 | 7,517.966316 bOSMO, `est_unbond_start_time` 2026-10-19T03:47:49Z (already submit-able) |
| config | `epoch_period` 259,200 s; `unbond_period` 1,209,600 s; `paused_validators` `[]`; `fee_rate` 0.1 (harvest only) |

### Liability reconciliation — why the 47.66k OSMO bank is not the E-U pot

| Bucket | OSMO |
|---|---:|
| Bank now | 47,660.549593 |
| + unbonding arriving for batches 124/125 | 1,301,208.705547 |
| − batch 124 claim (776k bOSMO community pool) | 1,299,687.479634 |
| − batch 125 claim | 1,521.225913 |
| − matured previous-batch claims (all batches, `est_unbond_end_time < now`) | 2,427.040960 |
| = unallocated bank surplus | **45,233.508633** |

The Osmosis forum (2026-10-15) says the 1,037 non-community holders are being compensated
**40,508 OSMO** from this balance after 24 Oct; the residual has no permissionless sweep path
(`CollectDust` filters out `uosmo`/`boneOsmo` and `dust_collector = null`). The redeem bug never
reads the bank — it only undelegates — so the bank is **H-O / S**, not E-U. The overflow path that
could have pushed `U > N` and let a batch claim the bank is rejected: the deployed wasm contains
`attempt to subtract with overflow`, and v3.0.15 was built with `overflow-checks = true`.

## 3. Exact attacker path and profit

Sequence (all permissionless; no whitelist, no pause):

1. `ExecuteMsg::Bond { receiver: attacker, exec_msg: None }` with `d` uOSMO. Contract mints
   `m = floor(S·d/T)` bOSMO to the attacker and delegates `d` to the smallest validator
   (`135p8…`, so `R` grows by `d`).
2. `ExecuteMsg::Unbond { receiver: attacker }` sending `m` bOSMO. This adds `m` to pending batch
   126; because its start time has passed, the same execute appends `SubmitBatch`.
3. `SubmitBatch` burns `B + m` and sets
   `U = floor((T+d + R+d)·(B+m)/(S+m))`, capped by the delegated total `T+d`.
4. Wait 14 days; call `Reconcile` (permissionless) then `WithdrawUnbonded`; receive
   `floor(U·m/(B+m))`.

Exact integer search over `d` (u128 floor math, `S0=497,945,621,653`, `N0=18,893,309,122`,
`E0=9,446,654,561`, `B0=7,517,966,316`). The bond is delegated to `135p8` (first in
`VALIDATORS_ACTIVE`, both delegations equal), so the attacker's own deposit also grows the
double-counted `E`:

| Scenario | d (OSMO) | m (bOSMO) | burn b (bOSMO) | U (OSMO) | payout (OSMO) | **net (OSMO)** |
|---|---:|---:|---:|---:|---:|---:|
| **A — join batch 126 now** | **23,636.25** | 622,948.956 | 622,948.889 | 42,529.559 | 42,022.418 | **18,386.168** |
| **B — submit 126, then batch 127** | **23,651.00** | 628,152.304 | 628,140.054 | 42,116.433 | 42,116.433 | **18,465.433** |

The burn is capped at `b ≤ N·S1/(N+E) − B0` so that `U ≤ N`; beyond that,
`compute_undelegations` would underflow and the tx would revert (overflow checks are on).
Scenario B is not 18,893 because submitting batch 126 first pays its two owners **427.875822
OSMO** out of the delegations; the post-126 state is `N=18,465.433300`, `S=490,427.655337`,
`E=9,232.716650`. The theoretical ceiling is `N0 = 18,893.31 OSMO`; a single attacker's realised
maximum is 18,465.43 (B), or 18,386.17 + ~507.14 paid to batch-126 owners (A).

**USD:** A 18,386.168 × $0.0524936 = **$965.16**; B = **$969.32**; ceiling $991.78 (DefiLlama,
2026-10-19 22:27 UTC). At the pass-2 price $0.057396: **$1,055.29 / $1,059.84**, ceiling
$1,084.40. Gas on Osmosis is <0.1 OSMO (observed 0.06–0.25 OSMO for 0.6–1.7M gas); 14-day
opportunity cost on 23.6k OSMO at 10% APR ≈ 91 OSMO (~$4.8). Net after costs ≈ **$955–$965 at
the live price**.

**The bond-target race matters:** if the attacker's bond instead lands on `u2wsa` (e.g. another
bond hits `135p8` first in the same block), `E` stays at `E0` and the maximum net falls to
`E0 = 9,446.65 OSMO` (~$496 at $0.05249). The current equality of the two delegations and the
ascending set order favour `135p8`.

**DEX surface:** the child scanned all 3,666 poolmanager pools; 9 hold bOSMO. The only
meaningful venue is the custom CW pool `osmo166yrd7…` with 1,302.97 bOSMO / 29.89 OSMO. Buying
bOSMO below redemption and redeeming yields ~**9.86 OSMO gross (~$0.52)**; mint→sell into the
pool is a loss at the current 0.02294 marginal price. The earlier mint→sell arbitrage (bot
`osmo10z5dg…`, ~40 cycles) is drained. DEX E-U is immaterial; the pot is the staked backing.

## 4. What closes it

1. **Admin migration.** The admin `osmo1lu92…` is a single-sig EOA (sequence 37, active) and can
   migrate `code_id 741` at any time; the Osmosis forum says a fixed build exists and the update is
   pending. As of block 72,830,598 there is no migration and `code_id 741` is still the only
   instance.
2. **Owner pauses `135p8`.** `pause_validator` is owner-only; removing `135p8` from
   `VALIDATORS_ACTIVE` makes `E=0` and closes the 1.5× overpay. Not done.
3. **SubDAO redeems first.** The Osmosis Liquidity SubDAO
   `osmo1rvq5cq2j35k7sqqz49e5e8zezl45fcywcawazh46qnc0g96d0d6sasqsgc` still holds
   **359,940.35 bOSMO (72.3% of supply)** — the remaining Margined-vault position after the 776k
   redemption. It is governance-gated (P), but a proposal could redeem up to ~331,969 bOSMO and
   capture the entire remaining `N0`. SubDAO proposal 212 already executed the 776k redemption;
   no new bOSMO redemption is pending in the latest 60 proposals.
4. **Any other batch drains the delegations** (the `U ≤ N` cap makes later redeemers revert or
   receive nothing).

There is no pause, whitelist, or redemption freeze in the contract. Both validators are in
`VALIDATORS_ACTIVE`: `135p8` is jailed/UNBONDED (unbonding 2026-06-10) and `u2wsa` is UNBONDING
(2026-10-28), but the SDK/keeper still accepts `MsgDelegate`/`MsgUndelegate` to them, so the
attacker's bond and 14-day unbond work.

## 5. Verdict

**E-U ≈ $965–$969 now (hard ceiling $992), HIGH confidence on the path, MEDIUM on the realised
number.** The pass-2 “$2.74k contract OSMO” overstates the attacker pot: 47.66k OSMO sits in the
bank but is prior-batch claims + ~45.2k residual/compensation, and the redeem formula cannot reach
it. The real live pot is the 18.89k OSMO still delegated; the bug lets an attacker capture up to
all of it with ~23.6k OSMO of 14-day capital. **H-O** = 40,508 OSMO compensation + 1,301.2k
batch 124/125 claims + 427.88 batch-126 payout; **P** = admin migration, owner validator pause,
SubDAO redemption; **S** ≈ 45,233.51 OSMO residual bank balance with no permissionless sweep path.

## 6. Evidence / reproducibility

* `analysis/sim_results_v2.json` — live snapshot + corrected A/B integer result (block 72,830,895).
* `analysis/exploit_math.py` / `exploit_math_output.json` — independent exact reproduction with two
  historical on-chain validations (mint `2,564,906` and batch-125 `1,521,225,913` to the unit).
* `analysis/child-verify.md` — independent child review (raw sets, historical state, bank/overflow,
  DEX pools, SubDAO, validators).
* `analysis/sim_bosmo.py` — re-runs the live read + math against `https://osmosis-rest.publicnode.com`.
* `analysis/{contract_info,config,state,pending_batch,batch_120..125,bank,delegations,unbonding,supply}.json` — raw reads.
* Source: `github.com/backbonelabsio/steak-contracts` @ `432c0b2` (v3.0.15), `contracts/hub-tf/src/{execute,math,state}.rs`; fix `376a7fce` (2024-10-14).
* Forum: `https://forum.osmosis.zone/t/bosmo-redemption-issue/4161` (2026-10-15).
* The Defiant: `bOSMO Bug Leaves Little Backing, Prompts Holder Compensation Plan` (2026-10-15/16).
* Pool enumeration: all 3,666 poolmanager pools + GAMM; 9 hold bOSMO (child §5).
