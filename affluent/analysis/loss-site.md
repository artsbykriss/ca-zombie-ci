# Affluent / Factorial Finance (TON) — loss-site isolation

**Incident:** DefiLlama/SlowMist — TON, 2026‑10‑15 (SlowMist 2026‑10‑14), class *"Token & Share Accounting"*, technique **"Unbacked Mint"**, amount **$1,053,000**.
**Scope of this pass:** read‑only, public anonymous APIs only (`tonapi.io/v2`, `toncenter.com/api/v2`, `api.llama.fi`). Window pulled: 2026‑10‑12 → 2026‑10‑19, extended back to 2026‑09‑30 once the pattern was found.

---

## 1. Bottom line

The loss is **not** in a single pool contract and **not** in the BasicPool's *event stream* (see §5 — the prior "BasicPool had zero events" claim was a **tonapi pagination artifact**; BasicPool was active and *was* one of the drained pools).

The loss site is the **Affluent/Factorial lending‑vault share accounting** — the two share‑token masters:

| role | address (friendly) | raw | share token |
|---|---|---|---|
| TON Lending Vault (affTONl master) | `EQADQ6JcK0NMuNM5uwCc9bjcn2RTvcxYIZjNlhIhywUrfBN` | `0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad` | **affTONl** |
| USDT Lending Vault (affUSDTl master) | `EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW` | `0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9` | **affUSDTl** |

Both contracts are simultaneously `affluent_lending_vault` **and** `jetton_master`. The exploit is executed by **burning the vault share tokens** (`affTONl` / `affUSDTl`), which makes the vault pay out underlying **TON** / **USDT** to the burner — at a share price **far above fair value** (~0.202 TON paid per `affTONl` share vs a fair ~0.017 TON/share), and with the burner wallets **still holding large residual share balances afterwards** — the hallmark of unbacked / mis‑accounted share issuance. The underlying assets are physically pulled from the **pools** (BasicPool, AdvancedPool, LendingVaultPool, StormUsdtPool, EthenaPool, StormAdvancedPool).

Two distinct external wallets run the identical pattern:

| wallet | friendly | type | sessions | drained |
|---|---|---|---|---|
| **A** | `EQA04__gOPOZvYeI0nBS233hWOKYWFyUBwtRecztUwyXobCz` | `wallet_v4r2` | 2026‑09‑30, 2026‑10‑12 | **631,865 TON** (burned 4,179,348 affTONl) |
| **B** | `EQAkM7tiVXJGaB0CTZ3Cc2MPi3vgPLfwx8fLmoVUKRTCwuCw` | `wallet_v5r1` | 2026‑10‑16 | **150,041 TON + 13,824.94 USDT** |

**Aggregate ≈ 781,907 TON + 13,825 USDT ≈ $1.14 M** (blended spot TON), which **matches the reported $1,053,000** within ~8 % (see §4). This is the best reconstruction of the recorded incident.

---

## 2. Best single candidate — exact txs (2026‑10‑16, wallet B)

### Tx 1 — USDT drain (affUSDTl burn) — 13,824.93 USDT
- **event_id / tx hash:** `08b1751a89637f7c14fa4232fca3ceb93f0ce54548c2d473f4fdb04b0a7e7df1`
- **timestamp:** 2026‑10‑16 **20:46:02 UTC**  ·  **lt:** `110416241000008`
- **burn:** `10,000,000,000` affUSDTl (raw `10000000000000000`, dec 6) by `EQAkM7ti…`
- **payouts (USD₮ → EQAkM7ti…):**
  | pool | USDT |
  |---|---|
  | BasicPool `EQCrEHHG…` | 3,029.464053 |
  | StormUsdtPool `EQAYJdU9…` | 3,399.080963 |
  | EthenaPool `EQA9iTdg…` | 7,196.389802 |
  | AdvancedPool `EQBCXQp2…` | 100.000000 |
  | StormAdvancedPool `EQCOA3gN…` | 100.000000 |
  | **total** | **13,824.934818 USDT** |

### Tx 2 — TON drain (affTONl burn) — 150,041.29 TON  ← **largest single tx in the whole window**
- **event_id / tx hash:** `ba3fc8ad72185639820e639316d3a8b2521cb07be96eb8522d29f6c168aa846a`
- **timestamp:** 2026‑10‑16 **20:48:23 UTC**  ·  **lt:** `110416595000020`
- **burn:** `10,000,000` affTONl (raw `10000000000000000`, dec 9) by `EQAkM7ti…`
- **payouts (AffluentTON jetton **and** TON → EQAkM7ti…):**
  | pool | AffluentTON | TON |
  |---|---|---|
  | BasicPool `EQCrEHHG…` | 126,352.405236642 | 126,352.425236642 |
  | AdvancedPool `EQBCXQp2…` | 19,600.085812907 | 19,600.105812907 |
  | LendingVaultPool `EQBQMDjW…` | 4,088.741431166 | 4,088.761431166 |
  | **total** | **150,041.232480715** | **150,041.292480715 TON** |

Immediately after, wallet B dumped everything: USDT → `0:5987d0a9…` and `0:1b589dd8…` (in 1,000‑USDT chunks and larger lumps), TON ⇄ USDT via DEX (`JettonSwap` / `pTON`), plus 10,000–20,000 TON transfers out. Wallet B's residual balance is 55.9 TON.

---

## 3. Additional sessions (same mechanism, wallet A)

| date | forwarded amount | event_id (TON forward) |
|---|---|---|
| 2026‑09‑30 05:24:29 | **504,826.86 TON** | `4b75b5801aa7a5a2f945282df5a0c2f6970494d59e0bfd957fe14307ffc3a15b` |
| 2026‑10‑12 10:25:29 | **126,686.16 TON** | `75a656d94e818a359aaaad42c4a1eb24b52d71032011583da444bcfb70986aa2` |

Both forwarded to `0:2830bdd386afd8f449147b5d99d26c817ae40c88853aa424f8d53374f50f3307` (`wallet_v5r1`). Wallet A ran a tight loop burning **exactly 80,000 affTONl per iteration** for ~16,195 TON (≈0.2024 TON/share), until the vault emptied (tail iterations paid ≈0 TON). Wallet A's activity exists on **only** 2026‑09‑30 and 2026‑10‑12 — i.e. it is a purpose‑built drainer, not a normal user.

---

## 4. USD valuation & DefiLlama cross-check

Spot TON (llama coins): 2026‑09‑30 $1.4844 · 2026‑10‑12 $1.3613 · 2026‑10‑16 $1.3562.

| session | amount | USD |
|---|---|---|
| 2026‑09‑30 | 505,056.73 TON | $749,688 |
| 2026‑10‑12 | 126,808.75 TON | $172,619 |
| 2026‑10‑16 | 150,041.27 TON + 13,824.94 USDT | $217,312 |
| **total** | **781,906.75 TON + 13,824.94 USDT** | **≈ $1,139,619** |

DefiLlama TVL for `affluent` (category Lending, TON):
`2026‑10‑12 2,015,501 → 10‑13 1,715,568 (−$299,933)` and `10‑16 1,741,485 → 10‑17 1,509,099 (−$232,386)`.
The 10‑16→17 drop of $232k matches the 10‑16 drain (computed $217k, remainder = other small flows / snapshot price). The 10‑12→13 drop of $300k is larger than wallet A's 10‑12 TON ($173k) alone — consistent with the same accounting loss also hitting the USDT pools on 10‑12, or additional same‑mechanism withdrawals.

---

## 5. Corrections to prior assumptions

- **BasicPool `EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx` was NOT event‑free.** It has **165 in‑window events** (10‑12 → 10‑18) and is one of the largest victims (126,352 TON + 3,029 USDT paid out on 10‑16). The earlier "zero events" result came from tonapi's **broken `next_from` cursor** (it re‑serves page 1). The correct pagination parameter is **`before_lt`**; all data here was re‑pulled with `before_lt` and de‑duplicated by `event_id`.
- There are **no `JettonMint` actions** on any queried contract. The "unbacked" share creation is not surfaced as a `JettonMint`; it manifests as **share balances credited into freshly‑deployed jetton wallets** (e.g. wallet B's `affUSDTl` wallet `0:c5d31415…` was deployed 20:36:39 on 10‑16 and immediately held 10^10 affUSDTl) and as **vault payouts far above fair share value**.
- The **AffluentTON** master `EQDIKEz2…` reports a custom/broken `total_supply` (`1e9` raw = 1.0 token) with 840 holders — its `get_jetton_data` returns a non‑standard layout. No anomalous supply change or mint was observed there around Oct 14–16; **the AffluentTON master is not the loss site.**

---

## 6. Cleared — NOT the loss site

No anomalous drain / unbacked mint in the window; only normal user deposit/withdraw/redeem flows:

- MultiplyVault V1: **GoldMultiply** `EQBowXTt…`, **EthenaVault** `EQD3F7Ex…`
- MultiplyVaultV2: **TON‑Multiply‑1** `EQDtxQqk…`, **USDT‑Multiply‑1** `EQBzSIti…`, **Ethena‑Multiply‑1** `EQDXmtbt…`, **Sentora‑Affluent** `EQBjpfG5…`, **Sentora‑Wallet** `EQD5O4qz…` (119 ordinary `affSENTORAent` burn→USDT redemptions, share price ≈1.02, no anomaly)
- Pools with only normal flow: **TradoorAdvancedPool** `EQCNgBmH…`, **StormTonPool** `EQA3m4H3…`
- **AffluentBatch** `EQA2zgb‑…` (0 events), **Affluent‑USDT** `EQAc65Jg…` (no activity)
- **AffluentTON / FactorialTON jetton master** `EQDIKEz2…` (no mint/transfer anomaly)
- Note: **BasicPool / AdvancedPool / LendingVaultPool / StormUsdtPool / EthenaPool / StormAdvancedPool** are *victim* pools (funds pulled through them) — the root cause is the lending‑vault share accounting that authorised the payouts, not the pools themselves.

---

## 7. Confidence

- **High:** the 2026‑10‑16 20:46/20:48 drains (tables in §2) are a genuine exploit — two batched txs in one external wallet emptying six pools simultaneously, then laundering to CEX/DEX. Tx hashes and amounts are exact.
- **Medium‑high:** the loss site is the **lending‑vault share accounting** (`affTONl` / `affUSDTl` masters), matching the "Token & Share Accounting / Unbacked Mint" classification.
- **Medium:** that this *aggregates* to the recorded $1.05 M. The 3 sessions sum to ≈$1.14 M; the incident date (10‑14/15) sits between the 10‑12 and 10‑16 sessions, so it is plausible the figure was booked when the loss was recognised. **I cannot point to one single $1.05 M transaction** — the loss is cumulative across ≥3 sessions (09‑30, 10‑12, 10‑16) and likely also includes USDT‑side dilution. A gradual share‑accounting dilution is therefore plausible, with the 10‑16 tx pair being the largest discrete cash‑out.

## 8. Raw dumps (all in this directory)

`raw_events_all.json` (all contracts, window, de‑duped) · `analyze_out.txt` · `drain_event_details.json` · `drain_tx_details.json` · `drain_dest_events.json` · `attacker_jetton_wallets.json` · `loop_34e3ffe0_events.json` · `jetton_info.json` · `addr_resolution.json` · `downstream_addrs.json` · `reconciliation.json` · scripts `fetch_events.py`, `analyze_events.py`, `deep_dive.py`, `event_detail.py`, `evidence.py`, `final_evidence.py`, `supply_and_scan.py`, `trace_shares.py`, `trace_wallets.py`, `mint_hunt.py`, `check_1012.py`, `quantify_loop.py`, `reconcile.py`, `final_check.py`.
