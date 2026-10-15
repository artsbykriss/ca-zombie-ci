# Radix residual cluster (L2-16 + L2-17) — Weft V2 / lockers (JustLock, RadLock, RlyFun) + Ociswap / DefiPlaza

**Date:** 2026-10-15 · **Chain:** Radix mainnet · **Status:** read-only; no transactions; all "attacks" are Gateway
**preview simulations** (`/transaction/preview`, `use_free_credit` + `assume_all_signature_proofs`), never signed or
submitted · **Scope:** external unprivileged attacker (no roles/keys/whitelist/insider positions), fresh capital only.

Prior campaign labels tested adversarially: L2-16 *"$13–56k; components not recovered"* and L2-17
*"standard Scrypto; no exposure"*. Components were recovered for **all six targets** (incl. RadLock v2 from the live
app bundle and the Radix Gateway `extensions/resource-holders` API). Everything below is re-verified on-chain at
explicit state versions and, for the headline, re-run end-to-end by an independent CI job on a fresh runner
(13/13 checks, latest run
[38733912782](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38733912782)).

**Reference state:** state_version 563,384,952–563,385,804 · epoch 349,694–349,696 · XRD = **$0.00045195**
(DefiLlama `coingecko:radix`, 2026-10-15). USD moves with XRD.

---

## 1. TL;DR

| Target (chain) | Live extractable by an unprivileged attacker (E-U) | Why open / closed | Latent risk / note |
|---|---|---|---|
| **Weft V2** lending market (Radix) | **≈ $101.5 practical cap at the 11:45–12:11Z snapshot (≈$96 at the 12:18Z re-check; moves with the hUSDC oracle) / ≈ $119.5 theoretical** — permissionless **liquidation-bonus capture** on 126 underwater CDPs. Verified live: **+108,796.81 XRD net for 45 hUSDC repaid (+$4.19 profit)**; **zero-capital flash-loan path +0.0587 XRD**. **Bug-based E-U = $0** | OPEN as a *designed mechanism*: `liquidate` is AllowAll; 126/901 live CDPs have `liq_ltv > 1` (market distressed; Borrow disabled). Practical cap = **1,092.79 hUSDC × hUSDC-oracle × 0.09312 × XRD-USD** (the repay asset for the big three; supply spread over 473 holders, largest 45.55) | Recurring but **price-dependent**: hUSDC oracle fell 2211.70→2090.73 XRD (−5.5%) in 15 min, cutting the cap from $101.5→$96 while debt/collateral were unchanged. Watch `liq_ltv` and the oracle. No protocol bug found |
| **JustLock** locker (Radix) | **$0** | `unlock` requires presenting the caller's LockReceipt NFT; used receipts go to an unwithdrawable vault; receipt `minter_updater`/`burner` = DenyAll (no forgery). All negatives preview-proven | H-O ≈ $65.8k nominal (173 time-locks, liquidity-bound); **S ≈ $121.6k nominal in 30 "forever" locks** (`unlockable_at = None` → panic) |
| **RadLock** (Radix) | **$0** | v2 recovered: `withdraw` needs two caller-owned proofs (lock receipt + user badge); proxies gated by `storage_access_auth`/`admin_auth` badges (verified `Unauthorized`) | H-O ≈ $115.6k nominal (316 live locks); P = 10,500 XRD fee vault ($4.75) + admin badge (supply 1) |
| **RlyFun** (Radix) | **$0** | Curves reject foreign tokens (`InvalidDropAccess`); buy→sell round-trip −1.89%; the big pot (633,433 XRD fee vault) is gated to the **pump-owner badge** — a freshly minted dev badge is rejected (`Invalid proof`) | Curve reserves 1,219,862 XRD ≈ $551 are AMM liquidity (not claimable); P = 633,433 XRD ($286) + 14,280 EARLY |
| **Ociswap** (Radix) | **$0** | 578 live pools, $44,928 TVL: swap round-trips lose exactly 2×fee (−0.199 XRD on 10 XRD); add→remove = net 0.0; flash-loan take-only **engine-blocked** (`DropNonEmptyBucket`); **0/578 pools have hooks**; registry/fee paths owner-badge-gated | Admin/registry P (owner badge); no S found |
| **DefiPlaza** (Radix) | **$0** | 149 live pairs, $36,540 TVL: round-trips −1.88%…−3.07%; add→remove net 0.0 incl. the shortage path (audit H01 area); admin paths `AuthError`; native `TwoResourcePool`s gated by the wrapper badge | Admin P (owner badge `resource_rdx1nfmknrk…`); main DEX runs an older un-diffable PlazaPair build (mitigated by live value-conservation test) |

## 2. Total live extractable now

**E-U: ≈ $101.5 practical cap at the verification snapshot (≈ $96 at the 12:18Z re-check; ≈ $119.5 theoretical
bonus pool net of the protocol's cut, before acquisition cost) — 100% from Weft V2 liquidation bonuses; every
other target $0.**
Confidence: **high** on the mechanism and the per-call numbers (independently re-run; 13/13 CI checks three times),
**medium** on the practical maximum (it assumes acquiring up to the full 1,092.79 hUSDC supply at ≈ oracle price;
the supply is spread over 473 holders, so realistic capture is a fraction — any partial repayment is profitable
proportionally). Practical cap formula: `1,092.79 × hUSDC_oracle_XRD × 0.09312 × XRD_USD` — at 12:18Z this is
1,092.79 × 2090.73 × 0.09312 × $0.00045195 = **$96.2** (hUSDC oracle drift is the dominant variable).

Split (nominal USD): **H-O ≈ $181.4k** (JustLock $65.8k + RadLock $115.6k; illiquid memecoins, realistically a
fraction) · **P ≈ $291** (RlyFun 633,433 XRD + RadLock 10,500 XRD + Ociswap/DefiPlaza/Weft admin; unquantified
registry fees) · **S ≈ $172.2k nominal** (JustLock forever-locks $121.6k + Weft bad debt $50.6k of 111.87M XRD-valued
loans vs 5.15M XRD seizable).

---

## 3. The mechanisms in exact terms

### 3.1 Weft V2 — liquidation-bonus capture (the only non-zero E-U)

Weft V2 is a CDP lending market (`LendingMarket` + `LendingPool`) that is **distressed**: Borrow service is disabled
(`The service is not active: (Borrow)`), deposits are frozen for xUSDC/xwBTC/xETH, and 126 of 901 live CDPs are
underwater. `liquidate` is open to any caller (`can_liquidate` = AllowAll) and pays the caller the liquidation bonus
(b = 12% for config-7 collateral, 3–10% others) minus the protocol's 20% cut of that bonus:

```
net per unit repaid = repay × (1+b) × (1 − 0.2b) − repay          (b = bonus rate)
# hUSDC debt vs XRD collateral (b = 0.12, oracle 2211.7021 XRD/hUSDC):
#   1 hUSDC repaid → seize 2477.1064 XRD; protocol fee 0.2×b×seize = 59.4506 XRD;
#   net 2417.6558 XRD; bonus kept 205.95 XRD ≈ $0.0931 (preview-verified: 45 hUSDC → net 108,796.81 XRD)
```

Verified previews (never submitted):
* **Zero-capital, atomic:** flash 10 XRD from the Weft pool → `liquidate #447` (2.550022 XRD repaid, 2.626523 XRD
  seized, 0.015759 XRD protocol fee) → repay flash 10.002 XRD → **net +0.0587415 XRD** to a fresh account.
* **#1015:** withdraw 45 hUSDC (simulated holder) → `liquidate #1015` → **seize 111,472.14 XRD, fee 2,675.33 XRD,
  net +108,796.81 XRD**; debt −45.0 exactly; repeatable (close factor 50%/call). **Profit = repay × oracle ×
  0.09312** = 9,268 XRD ≈ **+$4.19** at the 12:03Z oracle ($45 of hUSDC valued at oracle). Re-run 13 min later
  (hUSDC oracle 2211.70 → 2090.73 XRD): net +102,843.76 XRD → profit 8,761 XRD ≈ +$3.96 — the profit moves with
  the hUSDC/XRD oracle, the 9.3% ROI in hUSDC terms is invariant.
* **Drift check (12:18Z):** #1015/#517/#100 liq_ltv = 1.0751/1.0110/1.0011 with debt & collateral amounts
  **unchanged** — the change is the hUSDC oracle price, not liquidations. The cap is therefore
  `supply × oracle × 0.09312 × XRD_USD` and can shrink or grow within minutes.

Gate that bounds it: the three dominant CDPs are **hUSDC-debt**; total hUSDC supply = **1,092.793964** (state
563,384,935). All other 123 underwater CDPs have dust/NFT collateral (NFT liquidation is bricked by an empty
`nft_liquidation_fees` vault). The oracle is badge-gated and fresh (no manipulation path); the stale `price_cache`
is unused by health/liquidation math.

### 3.2 Lockers

* **JustLock** (`Locker 1.0.0`, source `github.com/just-lock/locker`): only `lock`/`unlock`; `unlock(receipts)` asserts
  the bucket resource == the receipt manager and `unlockable_at.is_some() && now >= unlockable_at`, then pays the
  vault; used receipts are `put` into a vault with **no withdrawal method**; receipt resource updaters/burner are
  DenyAll (423 minted, 0 burned). Live panic line numbers match the cloned source (`src/lib.rs:200:13`, `:216:17`).
* **RadLock** (v1 package in the brief is **dead**; live = proxy `package_rdx1p53g7…` + logic `package_rdx1p4pz6ws…`):
  recovered components `component_rdx1cptszkemad…` (RadlockService), `component_rdx1crn49lcmzyu…` /
  `component_rdx1cqvjerqdt5…` (TokenLockService proxy/logic), `component_rdx1cp7vsz98w06…` (TokenVestService). Every
  value-moving entry point tested returns a hard `Unauthorized` naming its badge (`admin_auth` = fungible supply 1;
  `storage_access_auth` = supply 4 held by the services); `withdraw` signature requires two caller-owned proofs.
* **RlyFun** (`EarlyCurves`/`EarlyPump`, `package_rdx1p56v9lj…`): 1,166 curves; buys/sells reject foreign resources at
  the vault (`InvalidDropAccess`); round-trip −1.89%; `claim_fee` on the 633,433.34-XRD pump fee vault requires the
  pump-owner badge — a fresh dev badge panics `Invalid proof: Expected ResourceAddress(9aedd185…) but got (9a23a51a…)`.

### 3.3 Ociswap / DefiPlaza

Both expose only fee-charging swap, native-pool-backed add/remove liquidity, engine-enforced flash loans, and
role-gated admin. All tested round-trips are value-conserving or negative for the caller (ceil-in/floor-out,
ATTO/POW_ERROR_MARGIN rounding against the trader); Ociswap hooks registry is empty on all 578 live pools;
DefiPlaza's audited H01 shortage path conserves value live (net 0.0).

---

## 4. Live-state assessment (addresses, roles, balances — all re-read on-chain)

| Target | Addresses (key) | Live value / roles at verification |
|---|---|---|
| Weft V2 | Pool `component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn`; Market `component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w`; KVS `internal_keyvaluestore_rdx1kzjr763…`; hUSDC `resource_rdx1thxj9m87sn5cc9…`; CDP NFT `resource_rdx1nt22yfv…` | Market roles can_borrow/liquidate/refinance/create_cdp/flash_borrow = **AllowAll**; oracle/admin badge-gated; 901 live CDPs, **126 with liq_ltv > 1**; hUSDC supply 1,092.793964; top CDPs #1015/#517/#100/#1029 liq_ltv 1.1373/1.0696/1.0591/1.1692 |
| JustLock | Locker `component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl`; receipt `resource_rdx1nfajj55…` | 100 fungible resources + 80 NFTs held; 423 receipts (173 time-locks, 30 forever-locks); owner badge metadata-only |
| RadLock | Service `component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs` (+2 services, logic v4 `component_rdx1cqvjerqdt5…`); `Locked Resource` NFT supply 426 (316 locked) | `get_xrd_fee_vault()` = **10,500 XRD**; admin withdrawal rejected (fresh caller) |
| RlyFun | Pump `component_rdx1cz78ld4409v7l8nawmeqr6wj4f5nvmpzdaulwpdqg3hps56mmgzzmy`; KVS `internal_keyvaluestore_rdx1krtyftm…`; 1,166 EarlyCurves | `check_fee_vault()` = **633,433.343807393 XRD**; curves hold 1,219,862 XRD |
| Ociswap | BasicPool `component_rdx1cpj25l4f8v2n4xl2auhwsagwmt5mmxsavxttmkpl90cr2qnyejqcmt` (+3 blueprint families); Registry | 578 live pools, **$44,928 TVL**; 0/578 hooks; registry `update_config`/`withdraw_protocol_fees` → owner badge |
| DefiPlaza | DEX `component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68`; owner badge `resource_rdx1nfmknrk53gqqqrg45u4rut0kw72697xfj7nsw4tw9y8kthlmj4qd2j` | 149 live pairs, **$36,540 TVL**; admin methods `AuthError` |

## 5. What an attacker can / cannot do

**CAN (verified):** liquidate Weft CDPs #1015/#517/#100/#1029 (and 122 smaller ones) permissionlessly, netting the
bonus − 20% protocol cut; run the zero-capital flash-loan variant; repay any amount ≤ 50% of a CDP's debt per call.
Costs: ~1.3–2.5 XRD gas/tx; acquiring hUSDC is the only material cost.

**CANNOT (all preview-proven):** withdraw/liquidate Weft positions without the Wefty NFT proof; manipulate the
badge-gated oracle; liquidate NFT-collateral positions (empty protocol-fee vault); unlock foreign JustLock receipts
or bypass the time gate; withdraw RadLock locks/fee vaults (two-owned-proof / badge gates); sell junk into RlyFun
curves or claim the pump fee vault with a fresh dev badge; drain Ociswap/DefiPlaza via swaps, LP round-trips,
flash-loan take-only, hooks, or native-pool bypasses.

## 6. PoC / verification

No Foundry (Radix is non-EVM): the chain-native equivalent of `eth_call` is Gateway **preview**; every claim above
has a raw receipt. Evidence: `analysis/weft_audit/preview_flashliq.json`, `preview_liq1015.json`,
`weft_cdp_health_raw.json`; `analysis/lockers_audit/radlock_preview_evidence.json`,
`rlyfun_launch_then_claim_fee_preview.json`, `jl_preview_negatives.json`; `analysis/dex_audit/receipts/*.json`.

**CI (independent re-runs on a fresh GitHub runner):** `ci/run.sh` → `ci/verify_live.py` —
**13/13 checks PASS** three times: runs
[38732758186](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38732758186) (state 563,385,804; net
+108,797.46 XRD), [38733399198](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38733399198) and the
final-state run [38733912782](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38733912782) (state
563,386,868; net +102,843.76 XRD — the hUSDC-oracle drift visible between runs) (`ci-log.txt`,
`ci-artifacts/result-radix-residual/ci-out/results.json`). The job re-verified: hUSDC supply; the four CDPs'
liq_ltv > 1; the zero-capital flash liquidation Succeeded; the 45-hUSDC #1015 liquidation Succeeded; JustLock live
+ no `withdraw`; RadLock fee vault 10,500 XRD + admin gate rejected; RlyFun fee vault + fresh-dev `claim_fee`
rejected; Ociswap round-trip −0.199 XRD; DefiPlaza round-trip −0.188 XRD; Ociswap flash take-only
`DropNonEmptyBucket`.

## 7. Verdict, residual/latent risk, blockers

* **E-U:** ≈$119.5 theoretical / **≈$101.5 practical** (Weft liquidations only). This is a *designed* mechanism in a
  distressed market — **not a protocol bug**; no bug-based extraction path was found on any target. All other
  targets: **$0 E-U, high confidence**.
* **Residual/latent:** Weft — more CDPs become liquidatable as prices move (XRD-denominated collateral vs hUSDC
  debt); the bonus pool recurs; watch `liq_ltv` drift and hUSDC availability. JustLock/RadLock — illiquid memecoin
  positions could regain value (H-O only). RlyFun/DefiPlaza/Ociswap — admin-only surfaces.
* **Blockers:** Weft — hUSDC supply 1,092.79 spread over 473 holders; NFT-collateral liquidations bricked; Borrow
  disabled; deposits frozen. RadLock — admin badge supply 1 at the team account. DEX — owner badges.

## 8. Methodology, sources, caveats

* Public Radix Gateway only (`https://mainnet.radixdlt.com`): `state/entity/details`, KVS reads, the
  `extensions/resource-holders/page` API (used to recover RadLock v2 + holders), `transaction/preview` (never
  submitted). No keys, no secrets, no keyed URLs in this folder.
* Sources: `github.com/just-lock/locker`; `github.com/ociswap/{pool,precision-pool,registry,pools-common,scrypto-math}`;
  DefiPlaza sources (OmegaSyndicate/RadixPlaza) + Pessimistic audit; live frontend bundles (rly.fun, app.radlock.io);
  DefiLlama adapters + prices; `CalamariRadix/gateway-ez-mode` package registry (RadLock v1 package anchor).
* Caveats: Weft practical cap depends on hUSDC sourcing; JustLock/RadLock H-O values are nominal (thin liquidity;
  DCKS/Beer memecoins); the main DefiPlaza pair build predates the public audit repo (mitigated by live tests);
  Ociswap legacy BasicPool source not public (behaviourally verified); USD moves with XRD; state is point-in-time.

**Files:** `README.md` · `summary.json` · `analysis/` (raw state, scripts, receipts; subfolders `weft_audit/`,
`lockers_audit/`, `dex_audit/`) · `ci/` (verify job) · `ci-out/` (CI results) · `ci-log.txt` · `ci-artifacts/`.
