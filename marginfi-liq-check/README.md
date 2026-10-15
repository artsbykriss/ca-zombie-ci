# marginfi v2 (C2-37) — liquidation realisability re-check (adversarial, tx-level)

**Date:** 2026-10-15 · **Chain:** Solana mainnet-beta · **Program:** `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA`
**Status:** read-only; all "execution" evidence is live RPC `simulateTransaction` (`sigVerify:false`, nothing ever signed/broadcast) or **LiteSVM** in-process sandbox with cloned mainnet state. No mainnet transaction was sent.

**Question (principal):** the prior audit flagged 4,982 marginfi accounts as "underwater" by off-chain price math
($528,138 deficit, $24,499 liquidation-fee bound) but classified E-U $0 after liquidation attempts returned
err **6068 "Account is healthy"**. How is 4,982 underwater accounts not a profit?

**Answer: realizable E-U = $0.00 (high confidence).** The 4,982-account set was a **modeling error in the
efficiency-mode (emode) weight rule**. Re-derived with the program's own oracle prices and its exact emode
algorithm, and verified by executing the deployed program (1,058 program-side health pulses + 22 LiteSVM
liquidation transactions): every large "underwater" account is **healthy per the program's risk engine**
(e.g. the prior #1: **+$67,166 maintenance health**), and every genuinely-liquidatable account is either
**pure bad debt with no collateral to seize** or dust. The best executable liquidation across the top-22
program-verified liquidatable accounts seized **$0.000000049** (4.9e-8 USD) of collateral — net ≈ $0.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why | Evidence |
|---|---|---|---|
| Prior "underwater" set (4,982 accts, $528k off-chain deficit) | **$0.00** | off-chain model mis-applied emode; program returns 6068 for the big accounts | program health logs (live sim + LiteSVM) |
| Prior #1 `3s76VTGrDJz…` (−$105,441 off-chain) | **$0.00** | program maintenance health **+$67,166**; phase-LST collateral counts at **0.999** weight via the SOL bank's emode entry (tag 1572) | LiteSVM pulse health cache + `pre_liquidation_health` log; liquidation → **6068** |
| Prior #2/#3 `Bry1WUdXtDN…` / `2EakAHfoHpG…` | **$0.00** | program health **+$31,388** / **+$566,617** | live pulse |
| Program-verified liquidatable (572 pulsed accounts, $35,576 deficit) | **$0.00** | 282 have zero collateral; the rest are dust | `lending_account_pulse_health` (`liq_err=0`) |
| Top-22 by deficit (LiteSVM liquidation tx each) | **$0.00** | 21 fail: 6072 WorseHealthPostLiquidation ×9, 6065 OverliquidationAttempt ×7, 6009 RiskEngineInitRejected ×5; 1 succeeds and seizes **$4.9e-8** | `ci-out/batch_results.json` |
| Legacy-bank accounts (236/401 banks are 1864-byte v1 layout) | **$0.00** | deployed program **panics** (`account_loader.rs:169`) loading them → cannot be health-checked or liquidated | live sim `ProgramFailedToComplete`; anchor v1.0.2 source |
| Theoretical liquidation-fee bound (whole program-verified set) | **≤ $0.68** | 2.5% × seizable ≈ $27.31 (max seizure bounded by each account's deficit) | see §6 |

**Headline: realizable E-U = $0.00. Confidence: high.** The prior $24,499 "fee bound" is moot — it was
computed on accounts the program refuses to liquidate (6068).

---

## 2. The mechanism, exactly

### 2.1 What the program does on liquidation

`lending_account_liquidate` (disc `d6a997d5fba756db`, confirmed against the official `mrgn-0.1.12-rc2`
release IDL and the deployed ELF, last upgrade slot 456,093,551, sha256
`37022ba42d9a2129de3e3002f899a63a3e5c3fe905566e77ba9d77c0be130aa1`):

1. **Pre-check** `check_pre_liquidation_condition_and_get_account_health` — liquidatee maintenance health
   with live oracle prices; `health > 0` → **6068 HealthyAccount** (refuses; logs the health).
2. Asset price = Pyth real-time price **− min(2.12×conf, 5%×price)** (low bias); liability price = price
   **+ the same interval** (high bias).
3. Liquidator repays `q_ll = q_a·p_a·(1−f_l)/p_l`; receives `q_a` collateral; `f_l = 2.5%` liquidator fee +
   `f_i = 2.5%` insurance fee (bank fields 0 → `DEFAULT_LIQUIDATION_FEE`).
4. **Post-check**: post health must be ≤ 0 (else 6071) and > pre health (else 6072). ⇒ the maximum single
   liquidation is bounded by the account's **deficit**, not its collateral.

### 2.2 Why the off-chain flags were wrong — the emode rule

Program rule (`type-crate/src/types/emode.rs` + `bank.rs::get_asset_weight`):

* Reconciled emode config = **intersection of the LIABILITY banks' emode tables only** (min weight per tag,
  tag must exist in every liability bank).
* Asset weight = `max(bank.asset_weight_maint, reconciled[asset_bank.emode_tag])`.
* The asset banks' own emode tables are **never** intersected in.

The prior model intersected **all** banks (assets included) → lower weights → phantom deficits. For the prior
#1 account: SOL bank (liability, emode tag 501) grants **tag 1572 → 0.999**; the phase-LST bank carries tag
1572 → collateral counts at **0.999**, not 0.80/0.85:

```
program: assets 10,010.99 × $125.78 × 0.999 = $1,262,161
         liabs  10,265.50 × $105.39 × 1.10  = $1,194,800
         health = +$67,361  →  6068            (LiteSVM pulse, this repo)
```

### 2.3 The two hard blockers for the residual genuinely-underwater accounts

* **No collateral.** Top program-verified liquidatable: `CSGVhMXAYcVhZqk9WEcp9V9Vp6wNsipuCVCJk96zmQJR`
  −$21,034 with a zero asset balance; `26RqVouE3…` −$4,478; … A liquidation needs a positive liquidatee asset
  balance; with none the tx fails (6065/balance-not-found). Uncollectible bad debt ≠ profit.
* **Legacy banks panic the program.** 236 of 401 banks are 1864-byte v1 layout; the deployed `Bank` struct is
  3904 B, so anchor `AccountLoader::load` panics at `account_loader.rs:169`
  (`bytemuck::from_bytes(&data[8..3912])`). Accounts holding them can't be health-checked or liquidated
  (live sim: `ProgramFailedToComplete`, 2.8k CU). 255 of the pulsed accounts hit this.

---

## 3. Live-state assessment (slot 457,293,766 · 2026-10-15 ~17:10 UTC)

| Item | Value |
|---|---|
| Program | `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA` (upgradeable, owner `BPFLoaderUpgradeab1e…`) |
| Deployed ELF | sha256 `37022ba4…130aa1`, last upgrade slot 456,093,551 (release `mrgn-0.1.12-rc2`, 2026-10-10) |
| Group | `4qp6Fx6tnZkY5Wropq9wUYgtFxXKwE6viZxFHg3rdAG8` (165 banks) + 9 smaller groups |
| Banks | 401: 165 current-size (3912 B), **236 legacy-size (1864 B)** |
| MarginfiAccounts scanned | 165,715 (full balance-region dump) |
| Accounts with borrows | 57,685 |
| Liquidation fees | `liquidation_liquidator_fee = 0` (→ default 2.5%) + insurance 2.5% |
| Legacy banks with positions | 12 lending + 6 borrowing positions (frozen by the panic) |

---

## 4. Re-derivation with the program's own oracle prices

`analysis/program_health.py` implements the deployed risk engine exactly (liability-side emode intersection,
asset-tag lookup, Pyth low/high bias, PythLST = Pyth × stake-pool rate, PythMSOL = Pyth × Marinade rate,
PTPyth = Pyth × Exponent rate, Fixed) and prices every bank from the **oracle accounts the program reads**
(snapshot slot 457,293,766).

| Set | Accounts | Total deficit |
|---|---|---|
| Off-chain v1 model (prior audit, wrong emode) | 4,982 | $528,138 |
| **Program-exact model (this re-check)** | **6,482** | **$36,399** |
| …with any weighted collateral (> $0.01) | 427 | $31.76 |
| …pure bad debt (zero weighted collateral) | 6,055 | $36,367 |

**Program-side verification** — `lending_account_pulse_health` is permissionless and writes the program's
own health cache; simulated live for 1,317 accounts (all v1 top-60, all v2 top-50, all 427 with-collateral,
120 random, 693 unsupported-bank):

| Program verdict | Accounts |
|---|---|
| Healthy (6068) | 55 |
| **Liquidatable (`liq_err=0`)** | **572** (total deficit $35,576) |
| Program panic (legacy banks) | 255 |
| Other | 4 |
| (no cache returned / tx-size) | rest |

**Model validation vs program (576 paired accounts):** median |delta| **$0.003**, worst $6.05 (0.14% of that
account's deficit; price drift between snapshots). The model reproduces the program's verdicts.

---

## 5. LiteSVM tx-level PoC (cloned mainnet state)

`poc/` — Rust harness on `litesvm` 0.18, loading the **exact deployed program ELF** + SPL Token program and
cloned mainnet accounts (banks, oracles, group, liquidatee, vaults). The harness fabricates an attacker
marginfi account (own key, 8 SOL deposit as capital) and executes real instructions (1.4M CU budget like real
liquidators). **4/4 tests pass** (`cargo test --release`, also run in CI).

| Test | Case | Result (exact) |
|---|---|---|
| T1 | prior #1 `3s76VTGrDJz…` (off-chain −$105k) | pulse → maint health **+$67,166**, `liq_err=6068`; liquidation → **Custom(6068)**, program log `pre_liquidation_health: 66787.6 (1257532.3 − 1190744.7)` |
| T2 | bad debt `26RqVouE3…` (program −$4,478) | pulse → `liq_err=0`, health −$4,459; liquidation → **6065 OverliquidationAttempt** (nothing to seize) |
| T3 | `2LzUSRsY…` (program −$38.7) | pulse → `liq_err=0`; liquidation → **6009 RiskEngineInitRejected** at the liquidator-side gate |
| T4 | **top-22 program-liquidatable accounts**, one liquidation tx each | **1 success, 21 failures**: 6072×9, 6065×7, 6009×5 |

**The one successful liquidation (T4, `9aMY2Xeq4T7WsLXWB5yCbn7NYFZ1g4SAhnuq5A3WNxFi`, health −$19.00):**

```
seized:  49 base units of WEN (5 dec) = 0.00049 WEN ≈ $0.000000049
repaid:  0.04781898 USDT base units    = 4.78e-8 USDT
health:  -19.00170657249496 → -19.00170652361746  (improved by $4.9e-8)
liquidator fee = 2.5% × $4.9e-8 ≈ $1.2e-9
```

That is the best executable path found across the entire program-verified liquidatable set: **net ≈ $0**.

---

## 6. Net profit per account + theoretical fee bound

```
V_max = min(collateral_value, deficit / (lwm_liab×(1−f_l) − awm_asset))   (post-health ≤ 0 rule)
fee   = 0.025 × V_max
```

* **Pure-debt accounts (282 of the verified set):** `V_max = 0` → net **$0**; the tx fails outright.
* **With-collateral accounts (290):** total unweighted collateral ≈ **$16,068**, but each account's deficit is
  $0.00–$4.79, so `V_max` is cents. Total seizable ≈ **$27.31** → liquidator fee bound ≈ **$0.68**.
* Prior $24,499 bound: **moot** (accounts behind it return 6068).

## 7. Verdict and residual risk

* **Realizable E-U now: $0.00 (high).** No unprivileged liquidation profit exists; the 4,982-account "underwater"
  set was an emode modeling artifact.
* **Latent (unchanged, P-class):** single-EOA upgrade authority → whole $37.98M custody.
* **New observation (S-class, out of E-U scope):** the deployed program panics on legacy-sized banks; ~18
  positions in those banks are frozen until banks are migrated/resized. Worth a separate look.

## 8. Methodology, sources, files

* Program-side evidence: live `simulateTransaction` (`sigVerify:false`) — read-only, nothing broadcast.
* LiteSVM: `poc/` (program ELF + SPL Token + cloned accounts + Rust harness; `ci-out/` artifacts).
* Sources: deployed ProgramData dump; `mrgnlabs/marginfi-v2` @ `mrgn-0.1.12-rc2` (source + release IDL);
  anchor v1.0.2 `account_loader.rs`; Jupiter price/route API for realizable-price checks.
* Files: `analysis/` (model, scans, pulse oracle, validation, PoC-state fetchers), `poc/`, `ci-out/`,
  `summary.json`.
* CI: see `summary.json.poc.ci_run_urls` (harness is also reproducible locally with `cd poc && cargo test --release`).
