# CaviarNine LSU Pool (Radix) — L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Radix (mainnet) · **Status:** read-only; no transactions; all "attacks" below are
Gateway **preview simulations** (`/transaction/preview`), never signed or submitted · **Scope:** external unprivileged
attacker (no roles, no keys, no whitelist, no legacy positions), fresh capital only.

Target: `component_rdx1cppy08xgra5tv5melsjtj79c0ngvrlmzl8hhs7vwtzknp9xxs63mfp` (blueprint **LsuPool v1.0.0**,
package `package_rdx1pkfrtmv980h85c9nvhxa7c9y0z4vxzt25c3gdzywz5l52g5t0hdeey`). The component is the CaviarNine
"LSU Pool": a liquidity pool that holds LSU tokens (Radix native liquid-staking units, one resource per validator),
issues the LSULP liquidity token, and lets users add/remove liquidity and swap between LSUs. CaviarNine has
announced it is **sunsetting** ("remove your remaining assets"), but the pool is live, funded and fully operable.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why open/closed | Latent risk |
|---|---|---|---|
| CaviarNine LSU Pool — **stale-valuation sandwich** (deposit at stale pool valuation → call the **public** price-refresh → redeem at refreshed valuation) | **max ≈ 156,719 XRD ≈ $47.60** (needs capital ≫ pool TVL; ~$23.8 with capital = pool TVL). **Demonstrated end-to-end: +1,495.7 XRD ≈ $0.454 net on $389 capital in one atomic transaction** | **OPEN**: `update_multiple_validator_prices` is PUBLIC; `dex_valuation_xrd` lags true value by 0.131% at the snapshot; deposit mints LP at the stale (low) valuation and redeem pays at the refreshed (high) valuation; no roles/whitelist needed | Recurs as rewards accrue (~32K XRD ≈ $9.7/day of new gap if nobody refreshes); grows if keepers stop; the pool is being wound down and price-refresh activity is sparse |
| Same pool — reserve vaults (141,678 XRD ≈ $43.04) | **$0** unprivileged | `take_from_reserve_vaults` is OWNER-only (admin badge) | P-only; 3 owner badges exist, holders not enumerable via the public Gateway |
| Same pool — LSULP redemption (holders) | **$0** attacker / **~$36.3K holder-recoverable** (H-O) | `remove_liquidity` is public and pays LP holders their pro-rata share | Normal self-service exit |

**Total live extractable by an external unprivileged attacker now: ≈ $47.60 maximum (stale-gap bound C = 156,718.84 XRD), high confidence in the bound; demonstrated net extraction $0.4543 with $389 capital. Recurring flow ≈ $9.7/day while the gap is left unrefreshed.**

---

## 2. The mechanism in exact terms

The pool stores `dex_valuation_xrd` (on-chain field) = Σ over its 82 LSU vaults of `vault.amount × cached_price[resource]`.
Prices come from each native validator's `get_redemption_value(1 LSU)` and are only refreshed lazily:

* every `add_liquidity` / `remove_liquidity` / `swap` refreshes **5** validators (`NUMBER_VALIDATOR_PRICES_TO_UPDATE = 5`), and
* **`update_multiple_validator_prices(number)` is PUBLIC** — any address can refresh up to all 82 validators in one call
  (`enable_method_auth!` in `lsu_pool/src/lsu_pool.rs`; deployed blueprint interface confirms it is a public method).

Because Radix LSU redemption values only increase (staking rewards accrue into each validator's stake vault at epoch
boundaries), a stale `dex_valuation_xrd` is systematically **lower** than the true value:

```
C = Σ vault.amount × (fresh_price − cached_price) = true value − recorded value
```

An attacker can capture C·D/(V+D) of it, where D = the value deposited and V = recorded valuation, with the exact
sequence (all in one atomic transaction):

1. `validator.stake(XRD)` → receive LSU of an active validator (fresh capital, no legacy position);
2. `add_liquidity(LSU bucket, None)` → LP minted = `D / V_stale × supply` — **over-minted** because V is stale-low;
3. `update_multiple_validator_prices(200)` → the PUBLIC refresh adds the whole gap C to `dex_valuation_xrd`;
4. `remove_liquidity(LP, LSU, Some(credit_proof))` → payout = `share × V_new / price` = D + C·D/(V+D) − fees.

Deployed code reference (public repo `caviarnine/caviarnine-scrypto`, `lsu_pool/src/lsu_pool.rs`):
`add_liquidity` L1020-1127 (mint formula L1059-1067), `remove_liquidity` L1152-1275 (payout L1189-1199),
`get_validator_price_lsu_xrd_and_update_valuation` L785-808, `update_multiple_validator_prices` L816-845.

**Deployed-vs-source note:** the deployed blueprint's function set (37 methods), state layout (vaults / reserve_vaults /
prices_lsu_xrd / lsu_to_validator / dex_valuation_xrd / …), events and the observed behaviour of `add_liquidity`,
`remove_liquidity` payout and the refresh all match the public repo. One small deviation was observed on-chain in the
credit-discount fee path: the deployed code uses `taxable = (payout − credit)/(1 − liquidity_fee)` and does **not**
deduct the 5 bps liquidity fee from the user's payout (simulation shows protocol+reserve = 0.12203554045365727 each on
taxable 1,220.3554045365727, user receives payout − 0.24407108090731454). This does not affect the extraction math
(fees are ~1 XRD per 1.5K XRD of profit). On-chain bytecode source is not verified through the Gateway, so this
deviation is reported as an observation, not as ground truth of the repo.

---

## 3. Live state (all read at explicit state versions)

| Item | Value | Source |
|---|---|---|
| Component | `component_rdx1cppy08xgra5tv5melsjtj79c0ngvrlmzl8hhs7vwtzknp9xxs63mfp` — `LsuPool` v1.0.0, no pause field, owner = badge `resource_rdx1nglan7djf0stpdm5pf3hzctlha366l3s5xllu9z04z6puctdg200m4` (NFT supply 3) | `state/entity/details` @ sv 563,204,896 |
| Recorded valuation `dex_valuation_xrd` | **119,627,574.224120164155823961 XRD** | component state |
| True (fresh) valuation | **119,784,293.063 XRD** = Σ 82 main-vault balances × fresh validator redemption values | `vault_level.json` + `fresh_prices.json` (contract getter) |
| **Stale gap C** | **156,718.84 XRD (0.1308%)**; independently measured by preview refresh delta **+156,700.78 XRD** (two `update_multiple_validator_prices(200)` calls, atomic) | `key_findings.json` |
| Reserve vaults (excluded from V, owner-only) | 141,678.09 XRD fresh value | `vault_level.json` |
| LSULP supply | 97,447,941.266766377338962701 | resource details |
| Credit receipt NFTs | 2,034 | resource details |
| Fees | protocol 0.0001 · liquidity 0.0005 · reserve 0.0001 | component state |
| Validators | counter 82, pointer 22, max_before_fee 200 | component state |
| Token validator | `component_rdx1cz7h8j68esue87jmq4fqpnx5403jujadewlqcn5cqxew80fwd5fgd`, `require_active = true` (gates deposits only; removals of any vaulted LSU always work) | preview getter |
| XRD price | $0.0003037594 (DefiLlama `coingecko:radix`, 2026-10-14) → pool ≈ $36.4K, C ≈ **$47.60**, reserve ≈ $43.04 | coins.llama.fi |
| Package owner | package-owner NFT `resource_rdx1nf…pkgwnr`, `updater: None` (upgrades need that NFT) | package details |
| Refresh verification | off-chain `stake_xrd_vault/lsu_supply` = contract `get_validator_price_lsu_xrd` for **all 82** resources (0 mismatches); Σ main-vault × cached price = recorded `dex_valuation_xrd` to 1e-13 | `pull_state.py` |

Roles check (`role_assignments`): only role `user` exists and it is `AllowAll`; all privileged methods
(`set_*`, `take_from_reserve_vaults`) are owner-badge-gated at the blueprint level. `add_liquidity`/`swap` are
`restrict_to [user]` = everyone; **`remove_liquidity`, `update_multiple_validator_prices`,
`get_validator_price_lsu_xrd_and_update_valuation`, `deposit_reserve_fee`, `merge_credit` are PUBLIC.**

---

## 4. What an attacker can/cannot do

**CAN (proven, unprivileged):**

* Single atomic transaction, fresh capital only: `stake → add_liquidity → update_multiple_validator_prices(200) → remove_liquidity(credit proof) → deposit`.
* Demonstrated in preview on live mainnet state with a real funding account
  (`account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk`, used **only** as a simulated funding source):
  * capital 1,280,000 XRD (~$389) → staked 1,039,848.24392617324544 LSU2;
  * `add_liquidity` minted **1,042,547.077123847752105726 LSULP** (mint formula verified exactly);
  * public refresh added **+141,913.905 XRD** to the valuation during the tx (plus what the internal 5-price refreshes had already booked);
  * `remove_liquidity` burned all LP, paid out **1,041,067.989153007549858248 LSU2** (vault withdrawal), user received
    **1,041,067.745081926642543708 LSU2** (protocol 0.12203554045365727 + reserve 0.12203554045365727 deducted);
  * **net LSU delta +1,219.501155753 LSU2 ≈ +1,501.13 XRD gross ≈ +1,495.75 XRD net of the 5.384 XRD tx fee ≈ $0.4543.**
  * status `Succeeded`, 88,758,429 cost units, atomic; `analysis/sandwich_preview.json`.
* Scaling (formula, high confidence): profit = C·D/(V+D). At D = V ≈ $36.4K → ≈ $23.8; at D = 10V ≈ $43.3;
  as D→∞ → **C ≈ $47.60**. Capital can be raised freely (stake fresh XRD); the deposit is returned as LSU.
* Recurring: every day the gap is left unrefreshed adds ≈ 0.027% of V ≈ 32K XRD ≈ $9.7 of new extractable value.

**CANNOT (verified negatives):**

* No free withdrawal path: `take_from_reserve_vaults` (141,678 XRD reserve) is owner-only; fee-vault withdrawals are role-gated.
* `swap()` prices both legs fresh and charges fees — no value leak.
* No way to inflate `dex_valuation_xrd`: the refresh writes the validator's true `get_redemption_value`; a call for a
  resource without a vault changes nothing; a resource with a vault but no cached price panics (griefing only).
* Credit receipts cannot be forged or inflated (data updates are `global_caller(component)` only; `merge_credit`
  only sums owned receipts and empties the second one).
* No negative stale gaps exist (all 82 cached ≤ fresh), so the reverse (redeem-heavy) sandwich is not profitable.
* Flood-penalty bypass: new LSU resources can be added via `swap` without the `num³` fee that `add_liquidity` charges
  above 200 validators — griefing only, costs swap fees, adds no extractable value.
* The pool has no pause; nothing is bricked (no S-category funds found).

---

## 5. Simulation / PoC evidence

No Foundry here (Radix is non-EVM). The chain-native equivalent of `eth_call` is the Gateway **preview** endpoint; all
PoCs are preview simulations against live mainnet state, never submitted.

| Artifact | What it proves |
|---|---|
| `analysis/sandwich_preview.json` | Full atomic sandwich receipt (events: Stake, AddLiquidity, RemoveLiquidity, ValuationChange, deposits) with exact amounts |
| `analysis/key_findings.json` | All live-state numbers, C, prices, formula, simulation summary |
| `analysis/pool_state_snapshot.json` (rebuilt by `pull_state.py` → `vault_level.json`, `main_vault_balances.json`, `fresh_prices.json`, `cached_prices.json`, `lsu_info.json`, `validator_info.json`) | 82 vaults + cached vs fresh prices; C derivation; off-chain/on-chain price cross-check |
| `analysis/snapshot_pool.py`, `analysis/pull_state.py`, `analysis/sandwich_preview.py`, `analysis/bech32m.py`, `analysis/extract_addrs.py` | Reproducible read-only scripts (public endpoints only) |
| `ci/verify_live.py` + `ci/run.sh` | CI re-run: re-measures the gap and re-runs the sandwich simulation; results in `ci-out/` |

Key numbers from the successful simulation (`sandwich_preview.json`):

```
status                       Succeeded (atomic)
execution cost units         88,758,429
tx fee (exec+fin+storage)    4.43792145 + 0.54632495 + 0.40016173628 = 5.38440814 XRD
capital                      1,280,000 XRD
deposited LSU                1,039,848.24392617324544
LP minted / burned           1,042,547.077123847752105726 / 1,042,547.077123847752105726
payout from vault            1,041,067.989153007549858248 LSU
user received                1,041,067.745081926642543708 LSU
net profit                   +1,219.501155753397103708 LSU ≈ +1,495.75 XRD ≈ $0.4543
```

CI runs (public repo `artsbykriss/ca-zombie-ci`, branch `caviarnine-lsu-pool`): recorded in `summary.json`
(`poc.ci_run_urls`) and `ci-log.txt`.

---

## 6. Verdict and residual/latent risk

* **E-U (external unprivileged):** max **$47.60** (stale-gap bound; ≈$23.8 with pool-sized capital), demonstrated
  **$0.4543 net** with $389 capital; **confidence: high** in the mechanism and the bound (verified end-to-end,
  exact amounts, atomic, public method), medium-high on the practical maximum (it assumes an attacker willing to
  deploy ≫10× TVL capital before keepers/other LPs refresh the gap).
* **H-O:** LSULP holders' redeemable share ≈ $36.3K recorded / $36.4K fresh (normal public redemption).
* **P:** reserve vaults $43.04 (owner badge; 3 badges exist, holders unknown); protocol fees in the external fee-vault
  component; package upgrade rights (package-owner NFT).
* **S:** none found.
* **Residual/latent:** the gap re-accumulates with every epoch (~$9.7/day) as long as nobody calls the public refresh;
  the wind-down makes systematic refreshing less likely. If CaviarNine (or anyone) refreshes all 82 validators before
  a deposit, the sandwich yields ≈ 0 (only fees). Watch items: a keeper appearing; the owner raising fees (≤100 bps
  caps) or taking reserves; package upgrade (owner-only).
* **Blockers for the attacker:** none structural. Deposits are gated by the pool's token validator
  (`require_active = true`) so the LSU must belong to an active validator; capital is the only scaling constraint.

---

## 7. Methodology, sources, caveats

* All reads via the public Radix Gateway `https://mainnet.radixdlt.com` (`state/entity/details`,
  `transaction/preview`, `stream/transactions`). No keys, no transactions, no secrets in this folder.
* Source of truth for logic: `github.com/caviarnine/caviarnine-scrypto` → `lsu_pool/src/lsu_pool.rs` (+
  `lsu_token_validator`), cross-checked against the deployed blueprint interface (37 functions, state schema, events)
  and behaviourally verified in simulation.
* USD at DefiLlama `coingecko:radix` $0.0003037594191718614 (2026-10-14). XRD is low-priced; all USD numbers move with it.
* C is point-in-time (state version 563,204,896 / sim epoch 349494); it changes with pool activity and epoch rewards.
* The Gateway `stream/transactions` `affected_global_entities` filter returned unrelated transactions in testing —
  it was not relied upon for any claim here.
* The funding account used in the simulation is a real, unrelated live account used as a simulated balance source
  (`assume_all_signature_proofs`, preview only). No signatures were produced, nothing was submitted.
* Caveat on deployed code: exact deployed bytecode source not independently verified; one fee-formula deviation from
  the public repo is documented in §2.

**Files:** `README.md` · `summary.json` · `analysis/` (raw state, scripts, `key_findings.json`, `sandwich_preview.json`)
· `ci/` (verify job) · `ci-out/` (CI results) · `ci-log.txt`, `ci-artifacts/` (downloaded after each CI run).
