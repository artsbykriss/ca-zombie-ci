# Affluent (TON) — C-1 reconciliation: the mint is real, the **redeem is empty**

**Date:** 2026-11-03 · **Chain:** TON mainnet · **Status:** read-only; TVM emulation only; **no broadcast, no signatures, no mainnet transactions**.
**Folder:** `affluent-recheck/` (continuation of the killed CA2 C-1 run; prior partial work in `analysis/` preserved).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| Affluent **affUSDTl** lending vault `0:06b6…f1cb9` | **$0.00** | Permissionless unbacked **share mint is live**, but every burn (1 raw … 3e16, including the exact 2026-10-16 attacker wallet) **refunds the shares** (`0x178d4519`, `from=""`) and emits **no** asset payout. Vault idle `balance` = **1 raw**. | If idle balance is ever re-funded / the redeem path restored: up to the vault NAV **$19,810.62** |
| Affluent **affTONl** lending vault `0:0343…c14ad` | **$0.00** | Same: 12/12 burns refund; `balance` = **0**; NAV sits in whitelisted-pool supply positions. Mint re-run today from a **fresh** sender still mints 1e16 shares — the mint is live; the redeem is not. | If redeem restored: up to the vault NAV **$993,489.39** |
| 8 Affluent pools (TVL) | **$0.00** | The **$1.28M DefiLlama TVL is pool net supply** (`supplied − borrowed`), not the vaults' redeemable assets. The vaults' own claims are **$1,013,300.01** and are frozen behind the broken burn path. | Theft requires the vault redeem to work; it does not. |

## 2. Total live extractable now: **$0.00** (confidence: **high**)

- 12/12 fresh burn emulations (5 sizes × 2 vaults plus both full balances: **3e16 affUSDTl, 2e16 affTONl**) return **only** a `0x178d4519` mint-back of the same amount plus excess TON; **zero** `0x0f8a7ea5` / `0xb2a4c51b` / `0xcb03bfaf` payout messages.
- 2/2 **mint re-runs today**: a fresh sender `0:1111…` and the historical sender `0:3446…` both cause the pool to relay to the USDT vault, which mints **1e16 affUSDTl** to the beneficiary wallet `0:9c2f…` (`0x178d4519`, `from=""`). The mint primitive is live today; the redeem still refunds.
- The **exact wallet that succeeded on 2026-10-16** (`0:c5d3…`) still holds **5,697,376,531,863,130 affUSDTl**; a burn of that balance today **refunds**, with no USD₮.
- A large holder (`0:3446…`) burned **9,999,999,999,999,999 affUSDTl** on 2026-10-18 (event `66e93afd12…`) and received **0** (only 0.0683 TON gas change).
- Net cost per attempt ≈ **0.03 TON (~$0.035)** of gas; payout **0** → strictly negative.

**CA2's C-1 is a false positive for the $1.34M headline.** The unbacked mint is genuine (CA2 was right about that), but CA2 explicitly did **not** emulate the redemption leg. That leg is the finding's undoing: the redeem is capped at the vault's **idle balance**, which is **1 raw** (affUSDTl) / **0** (affTONl).

---

## 3. The bug in exact terms

### 3.1 What CA2 proved — and we re-confirm

Any ordinary wallet can send an internal message with op **`0x7362d09c`** (`transfer_notification`) directly to a live Affluent pool. The pool does not verify that the sender is the derived jetton wallet of the claimed asset; it relays **`0xa1b21e8b`** to the address in the notification's `sender` field. The vault accepts the pool (it is in the vault's whitelist) and emits **`0x178d4519`** (`jetton_internal_transfer`) with **`from = ""`** — a master-side **mint** — of the payload-specified amount to the payload-specified beneficiary. **No asset moves.**

- Pool code hash (AdvancedPool `0:425d…`): `bdd88c0f8ef5e16935d205b99670c0793a40aa64c5726ce8ce748ff334b8b031`.
- Both vaults share code hash `eb9d9891a32ec94425c09735f6ade73f4c171da0091f874d6e9d25247d583990`.
- The mint is uncapped and beneficiary-arbitrary (CA2 tests, re-verified in the saved traces: `analysis/emul/hist_oct26_mint_trace.json`).

**This part of C-1 is real and remains unpatched.** It is, by itself, worthless.

### 3.2 The missing half — why the mint cannot be cashed out

The vault is a **lending vault**: its storage (`AffluentLendingVaultStorage`) is

```
totalSupply, owner, manager, balance, cash, totalTargetWeight,
aggregatorIndex, payloadMarkerEnabled, whitelistedPools, assetConfig, gasConfig
```

`get_vault_data` (live, latest block) returns:

| Field | affUSDTl | affTONl | Meaning |
|---|---:|---:|---|
| totalSupply | 45,718,338,743,354,597 raw | 74,871,505,591,692,837 raw | share supply |
| **balance** | **1 raw** | **0** | idle asset balance used by the burn |
| **cash** | 1,000,000,000,000,000,001 | 1,000,000,000 | accounting cash (≈1 USDT / 1 TON) |
| totalTargetWeight | 10,780 | 9,520 | sum of pool weights |
| Σ whitelisted-pool `supplyAmount` | 19,840,470,254 raw = **19,840.47 USD₮** | 859,782,865,580,261 raw = **859,782.87 TON** | the vault's lending claims |
| Σ `poolCash` | 2,887,152,706 raw | 1,013,553,943,523,014 raw | pools' cash for the asset |

The burn handler (`0x7bdd97de`) parses the burn amount, checks `balance`, iterates the whitelisted pools, and either (a) sends `0xb2a4c51b` to the aggregator / `0xcb03bfaf` to the pools, or (b) falls back to a direct `0x0f8a7ea5` transfer. **On any failure it catches and re-mints the burned shares (`0x178d4519`).** With `balance` = 1 / 0, every positive burn fails that gate and is refunded. The NAV is in `supplyAmount` (pool loans), which the burn path never reaches.

That is exactly what the 10 emulations show: the vault never sends `0xb2a4c51b`, never sends `0xcb03bfaf`, never sends `0x0f8a7ea5`; it only mints the shares back.

### 3.3 What the 2026-10-16 trace actually shows (the one real payout)

`analysis/emul/hist_oct16_trace.json` (event `08b1751a…`, burn tx `6d0864bc…`):

1. Attacker `0:2433…` burns **10,000,000,000,000,000 affUSDTl**.
2. Vault → aggregator `0:39ae…` `0xb2a4c51b`; aggregator → 5 pools `0x7fe37dc6`; pools → aggregator `0x5c3d8ba8`; vault → pools `0xcb03bfaf`.
3. Five pools pay the attacker **13,824,934,818 raw USD₮ = $13,824.93** via `0x0f8a7ea5`.
4. The vault **mints back 5,697,376,531,863,130 affUSDTl** (the un-redeemed change).

So the redeem **did** work on 2026-10-16 — it paid out the vault's then-available liquidity ($13.8k), not the $1.34M TVL. The vault's idle balance was drained. Two days later, a **9.999999999e15** burn paid **0**; today, all burns pay 0.

CA2's own caveat — *"I did not emulate a full payout … inferred … not measured"* — is precisely the gap that turns C-1 from CRITICAL into **closed**.

---

## 4. Live-state assessment (read at TON masterchain seqno **103121429**, 2026-11-03)

### 4.1 Vaults

| Vault | Address | Code hash | Native TON (gas) | Asset wallet | Idle `balance` | NAV (measured) | NAV/share |
|---|---|---|---:|---|---:|---:|---:|
| affUSDTl | `0:06b609eb…f1cb9` | `eb9d9891…83990` | 22.226 TON | 500,001 raw USD₮ (0.500001) | **1 raw** | **$19,810.62** (19,840.47 USD₮) | 4.3397e-7 USD₮/token |
| affTONl | `0:0343a25c…c14ad` | `eb9d9891…83990` | 76.838 TON | — | **0** | **$993,489.39** (859,782.87 TON @ $1.1555) | 0.011483 TON/token ($0.01327) |

- The **owner** `0:acb28b15…` and **manager** `0:0e648438…` are both **`nonexist`** (undeployed, balance 0, never acted). No manager withdrawal or upgrade has been observed.
- The vaults' only user exit is the burn; it refunds. Users cannot redeem, and neither can an attacker.

### 4.2 The 8 pools — bytecode answer to CA2's caveat

| Pool (DefiLlama name) | Address | Code hash | Shares bytecode? |
|---|---|---|---|
| AdvancedPool | `0:425d0a76…be38` | `bdd88c0f…b031` | ✅ (relay proof) |
| StormUsdtPool | `0:1825d53d…d1db` | `bdd88c0f…b031` | ✅ |
| StormAdvancedPool | `0:8e03780d…c565` | `bdd88c0f…b031` | ✅ |
| StormTonPool | `0:379b81f7…c9a2` | `bdd88c0f…b031` | ✅ |
| LendingVaultPool | `0:503038d6…510a` | `bdd88c0f…b031` | ✅ |
| TradoorAdvancedPool | `0:8d801987…1f24` | `bdd88c0f…b031` | ✅ |
| EthenaPool | `0:3d893760…7fdb` | `bdd88c0f…b031` | ✅ |
| **BasicPool** | `0:ab1071c6…f08a` | **`09ae23d1…aaf0`** | ❌ different code/risk params |

**7 of 8 pools share the bytecode; BasicPool differs** (different max leverage / var ratios; it is a distinct variant). The relay primitive was proven on the shared-code AdvancedPool. The other six shared-code pools are equally exposed to the (worthless) mint; BasicPool's relay behaviour is **unverified**.

### 4.3 Collateral / borrow path

The AdvancedPool's 5 assets are TON, USD₮, tsTON, AffluentTON (`0:c828…`) and stTON (`0:cd87…`). **The vault share tokens (`0:06b6…`, `0:0343…`) are not AdvancedPool assets**, so minted shares cannot be posted there.

The **LendingVaultPool** `0:5030…` *does* list both shares (`isCollateral = -1`), but **every one of its 5 assets has `isBorrowable = 0`** (the pool's borrows are the vault's/strategy's supply, not a user borrow market), and its borrowable cash is negligible. The pools that do have borrowable USD₮/TON (AdvancedPool, Storm pools, Ethena, Tradoor) **do not list the shares**. Net: no pool simultaneously accepts the shares as collateral **and** offers a real asset to borrow → the borrow variant is **$0**.

There is no DEX market for the shares (share price ~4e-7 USD₮/token; no pair).

---

## 5. What an attacker can / cannot do

**Can (proven):**
- Send `0x7362d09c` to any shared-code pool and mint an arbitrary amount of affUSDTl/affTONl to an arbitrary wallet, for ~0.5 TON gas, with no allowlist and no capital.
- Repeat the mint without limit (supply is uncapped).

**Cannot (measured today):**
- Redeem the minted shares: the burn refunds them; the vault's idle `balance` is 1 raw / 0.
- Reach the vaults' `supplyAmount` NAV ($1,013,300.01): the burn path does not emit `0xb2a4c51b`/`0xcb03bfaf`/`0x0f8a7ea5`.
- Use shares as collateral (not a pool asset), sell them (no DEX), or govern the vault (owner/manager keys not attacker-controlled).
- Profit: gas ~0.03 TON net per burn, payout 0 → **negative**.

**Conditional escalation (not live):** if the vault's idle balance is re-funded, or the manager/aggregator restores the redeem, the same mint could be burned for up to the vault NAV. The attacker would need to mint enough to dilute existing holders; the beneficiary already holds 65.6 % of affUSDTl (3e16) and 26.7 % of affTONl (2e16), but those shares are currently worthless/stuck. **Trigger = idle balance > 0 and a working burn→pool withdrawal; neither holds today.**

---

## 6. PoC / verification

| Test | Amount (raw) | Vault | Result | Evidence |
|---|---:|---|---|---|
| Burn | 1 | affUSDTl | refund only | `ci-out/trace_affUSDTl_1.json` |
| Burn | 1e6 | affUSDTl | refund only | `ci-out/trace_affUSDTl_1000000.json` |
| Burn | 1e9 | affUSDTl | refund only | `ci-out/trace_affUSDTl_1000000000.json` |
| Burn | 1e15 | affUSDTl | refund only | `ci-out/trace_affUSDTl_1000000000000000.json` |
| Burn | 1e16 | affUSDTl | refund only | `ci-out/trace_affUSDTl_10000000000000000.json` |
| Burn | 1 / 1e6 / 1e9 / 1e15 / 1e16 | affTONl | refund only (5/5) | `ci-out/trace_affTONl_*.json` |
| Exact 2026-10-16 attacker wallet, 5.697e15 | 5.697e15 | affUSDTl | refund only | `analysis/emul/recheck_att_5e15.json` |
| **Mint re-run today — historical sender** | notify 1e18 (payload 1e16) | affUSDTl | **1e16 affUSDTl minted** to beneficiary `0:9c2f…`, `from=""` | `analysis/emul/mint_recheck_hist_sender.json` |
| **Mint re-run today — fresh sender `0:1111…`** | notify 1e18 (payload 1e16) | affUSDTl | **1e16 affUSDTl minted** to beneficiary `0:9c2f…`, `from=""` → no allowlist | `analysis/emul/mint_recheck_fresh.json` |
| Historical 2026-10-16 burn | 1e16 | affUSDTl | **13,824,934,818 raw USD₮ paid + 5.697e15 shares refunded** | `analysis/emul/hist_oct16_trace.json` |
| Large-holder 2026-10-18 burn | 9,999,999,999,999,999 | affUSDTl | **0 USD₮**, 0.0683 TON gas | event `66e93afd12…` |

**Emulation is genuine TVM execution**, not trace replay: `POST https://tonapi.io/v2/traces/emulate` runs the live code/data and returns the trace; nothing is broadcast. Every changed amount produced a different trace hash; every one refunded.

**CI:** `bash /home/heisenberg/CA/ci/ci-run.sh affluent-recheck` — **run [41646684718](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41646684718) = SUCCESS**, branch `affluent-recheck`; the log shows **10/10 burns `REFUND_ONLY`** and **2/2 mint re-runs `MINT_LIVE`** (`1e16` each), plus the offline verification passing. The CI job re-runs the 12 live emulations and the offline verification of the saved traces (`analysis/verify_saved.py`).

**PoC:** `poc/README.md` + `poc/run_redeem_probe.sh` (TVM emulation harness; no Foundry — Foundry cannot execute TVM).

---

## 7. Verdict, categories, confidence

| Category | USD | Confidence | Notes |
|---|---:|---|---|
| **E-U (external unprivileged, today)** | **$0.00** | **high** | 12/12 burns refund; exact attacker wallet refunds; large-holder 1e16 burn refunds; no payout op. |
| **E-U-conditional** | **$1,013,300.01** | medium/low | Only if the vault idle balance is re-funded **and** the burn→aggregator path is restored; attacker must mint enough to dilute existing holders. |
| **H-O (holder self-service)** | **$0.00** | high | Holders cannot burn/redeem either; the burn refunds. |
| **P (privileged)** | **$0 demonstrated** (P-conditional **$1,013,300.01**) | low | Manager/owner-gated recovery is plausible from the code, but the manager `0:0e648438…` and owner `0:acb28b15…` are `nonexist` and have never acted. Unverified; no privileged action observed. |
| **S (stuck)** | **$1,013,300.01** | medium | The observed outcome: NAV locked in pool supply positions, no user exit, no manager action. If the manager key is live, this becomes P (mutually exclusive on the same $1.013M — do not add). |

**Bottom line:** **CA2's C-1 is a false positive for the $1.34M live extraction.** The mint is real, but the redeem leg is empty: the vault's idle `balance` is 1 raw / 0 and every burn refunds. The $1.34M (DefiLlama TVL $1,282,377 today) is the **pools' net supply**, not the vaults' NAV; the vaults' own claims are **$1,013,300.01**, and even those are frozen (P/S, not E-U). The 2026-10-16 **$13,504.32** realized payout was real but was the vault's then-available liquidity; it has not been repeatable since 2026-10-18.

---

## 8. Residual / latent risk and blockers

**Latent risk (watch list):**
1. **Re-funding of the vault idle `balance`** (a real deposit, a manager withdrawal from pools, or a redemption returning cash) would re-open the burn path. Any balance > 0 makes a proportional mint→burn extraction possible again; the per-call cap is that balance, and the attacker can mint enough shares to dilute existing holders.
2. **Manager/aggregator restoration.** If the team re-enables the `0xb2a4c51b` aggregator path and the vault's `balance` is replenished, the combined NAV ($1.013M) becomes E-U again. The mint itself is unpatched.
3. **The 2026-10-16 attacker and the beneficiary still hold 5.697e15 + 3e16 affUSDTl and 3.567e15 + 2e16 affTONl** — all currently worthless/stuck. Their existence is a marker of the unpatched mint, not of live value.
4. **Collateral/borrow re-opening.** LendingVaultPool `0:5030…` already accepts both shares as collateral (`isCollateral=-1`) but has `isBorrowable=0` on all 5 assets. If any pool ever pairs share-collateral with a **borrowable** real asset (or flips `isBorrowable`), the uncapped mint becomes a borrow-against-unbacked-collateral path. Re-check the pool asset flags before any future escalation.

**Blockers that keep E-U at $0 today:**
- Vault `balance` = 1 raw (affUSDTl) / 0 (affTONl) → burn gate fails; refund.
- No `0xb2a4c51b` / `0xcb03bfaf` / `0x0f8a7ea5` in any emulation.
- NAV is in whitelisted-pool `supplyAmount`, not in the vault's idle wallet.
- Vault shares are not pool collateral; no DEX; share price ~4e-7 USD₮/token.
- Owner/manager accounts `nonexist`; no privileged recovery observed.
- DefiLlama TVL is pool net supply (`supplied − borrowed`), not vault NAV; it cannot be extracted by share holders.

---

## 9. Methodology, sources, caveats, files

**Method.** Live read-only `runGetMethod` (`get_vault_data`, `get_jetton_data`, `get_pool_data`) via toncenter v3; live `tonapi /v2/traces/emulate` (TVM execution, no broadcast); TON code disassembly (`tonpy`) of the vault and pool; DefiLlama prices/TVL; the saved 2026-10-16 trace. All addresses/amounts are at masterchain seqno **103121429** (2026-11-03); prices at Unix **1793712089** (TON $1.155512, USD₮ $0.998495). No keys, no keyed RPC URLs, no `.env` contents, no broadcasts.

**Sources.** `tonapi.io` (accounts, jettons, events, traces/emulate), `toncenter.com/api/v3` (accountStates, runGetMethod, masterchainInfo), `coins.llama.fi` (prices), `api.llama.fi` (TVL/methodology), `ton-blockchain/abis` (`affluent_lending_vault.types.tolk`, `affluent_pool.types.tolk`), `DefiLlama-Adapters/projects/factorial` (pool list, TVL method), CA2 `ca2/README.md` §C-1 and `ca2/.work/promote/affluent-ton.md`.

**Caveats.**
- The live emulation uses tonapi's hosted TVM; it is execution, not a signature/broadcast, but a host-side emulator difference cannot be fully excluded. The saved 2026-10-16 trace and the independent 2026-10-18 large-holder burn are on-chain corroboration.
- The exact reason the burn gate fails (idle `balance` vs aggregator state) is inferred from the storage layout + traces; the **economic result** (0 payout, 12/12) is measured.
- The manager/owner recovery is unverified; their accounts are `nonexist`, so P is a conditional upper bound, not a demonstrated path.
- The `supplyAmount` values are the vault's pool claims; their USD value depends on the pool's solvency and the TON price. The pools' `poolCash` covers the claims today (TON: 1,013,553 ≥ 859,783), but a bank-run/liquidity crisis could change that.
- DefiLlama TVL at the time of writing is $1,282,377 (CA2's $1,341,183 was the 2026-11-02 snapshot); the difference is price/other lenders, not the vaults' NAV.
- Snapshot prices in this report: TON **$1.155512**, USD₮ **$0.998495** (ts 1793712089). A repeat measurement minutes later at TON **$1.158156** (ts 1793713027) gives **$19,808.73 + $995,762.34 = $1,015,571.07**; the ~0.2 % difference is price, not position. `ci-out/measurement.json` is that repeat.
- The CI artifact download to `ci-artifacts/` failed from this host (Azure blob egress: `productionresultssa*.blob.core.windows.net` unreachable); the **full CI log is in `ci-log.txt`** and the run is public at the URL above. The 13-file artifact (`result-affluent-recheck.zip`) is attached to the run.

**Files.**
```
affluent-recheck/
├── README.md                     # this report
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── ton.py                    # keyless TON helpers
│   ├── emulate.py                # BOC builder + tonapi trace emulation
│   ├── recheck.py                # live NAV + 10 burn emulations (CI)
│   ├── verify_saved.py           # offline verification of saved traces
│   ├── vault_snapshot.json       # vault/pool/price snapshot at seqno 103121429
│   ├── pools_code_hashes.json    # 8 pool code hashes (7 shared + BasicPool)
│   ├── vault_usdt_data.boc / vault_ton_data.boc / vault_usdt_code.boc
│   ├── vault_usdt_disasm.fif     # vault code disassembly
│   ├── abi/                      # Affluent TL-B (lending vault, pool)
│   ├── emul/                     # all emulation traces (refunds + historical)
│   └── cache/                    # keyless HTTP cache (excluded from CI sync)
├── poc/
│   ├── README.md                 # TVM emulation PoC (no Foundry)
│   └── run_redeem_probe.sh
├── ci/run.sh                     # CI job (live emulation + offline verify)
├── ci-out/                       # measurement.json, verify_saved.json, traces
└── ci-log.txt / ci-artifacts/    # added by ci-run.sh
```

---

### Appendix A — exact burn refund bodies

For every test, the vault's response is:

```
op 0x178d4519 (jetton_internal_transfer)
  query_id 0
  amount   = <same as burn amount>
  from     = ""            <-- master-side mint = refund
  response_address = <burner>
  forward_ton_amount = 0
```

The jetton wallet then sends `0xd53276db` excess (~0.0286 TON) to the burner. No `0x0f8a7ea5` (jetton transfer), no `0xb2a4c51b` (aggregator withdraw), no `0xcb03bfaf` (pool withdraw).

### Appendix B — historical payout math

- Burn: 1e16 affUSDTl.
- Redeemed: 1e16 − 5,697,376,531,863,130 = **4,302,623,468,136,870 shares**.
- Paid: **13,824,934,818 raw USD₮** (5 transfers: 100,000,000 + 3,029,464,053 + 3,399,080,963 + 100,000,000 + 7,196,389,802).
- Implied rate: **3.213e-6 USD₮/raw share** = **$3.213 per affUSDTl token** at that moment.
- Today's rate: **4.3397e-7 USD₮/token** — ~7.4 million× lower, because supply was inflated to 45.7B tokens (beneficiary 3e16, attacker 5.697e15, others).
