# Radix DEX audit — Ociswap + DefiPlaza (zombie-hunt II, Tier-3 residual value)

**Scope:** determine rigorously whether an **external unprivileged attacker** (no roles, no keys, no whitelist,
fresh capital, flash loans allowed) can extract live value from the Ociswap and DefiPlaza DEXes on Radix
mainnet **right now**. Prior campaign label *"standard Scrypto; no exposure"* was treated as a hypothesis and
attacked adversarially.

**Method:** full live enumeration → on-chain interface extraction from blueprint schemas → source review of the
published contracts → **adversarial Radix Gateway PREVIEW simulations** of every candidate extraction path
(each path built as a realistic transaction manifest and executed in simulation only).

**Headline: no extractable path found. E-U = $0 on both protocols.**
Total live TVL in scope: **$81,467** (Ociswap $44,928 + DefiPlaza $36,540), all of it *not* reachable by an
outsider through any tested path. Confidence: **high** (many paths proven safe by exact value-conservation
receipts), with the residual unknowns listed at the end.

**Hard rules honoured:** read-only on mainnet; **nothing signed or submitted**; previews only
(`use_free_credit` + `assume_all_signature_proofs`); no keys/secrets written anywhere; writes confined to
`analysis/dex_audit/`.

---

## 0. Environment / evidence base

| Item | Value |
|---|---|
| Ledger state version | 563,377,525 (epoch 349,685, 2026-10-15T11:17Z) |
| Gateway | https://mainnet.radixdlt.com (public, read-only) |
| Simulation funding account | `account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk` (real account used purely as a simulation funding source) |
| XRD price | $0.00045198 (`coins.llama.fi` → coingecko:radix) |
| Ociswap TVL | $44,927.75 over **578 live pools** (1,847 enumerated; 4 blueprints) |
| DefiPlaza TVL | $36,539.61 over **149 live pairs** (156 enumerated; 6 DEX instances) |

---

## 1. Ociswap — per-path verdicts

Deployed blueprint families (all enumerated from on-chain package schemas):

| Blueprint | Package | Live TVL | Public methods (abridged) |
|---|---|---|---|
| `BasicPool` (legacy line) | `package_rdx1p5l6…n0lzx` | $17,670 | swap, add_liquidity, remove_liquidity, price_sqrt, liquidity_pool, set_liquidity_pool_meta**(restricted)** |
| `Pool` (repo v2.1.0) | `package_rdx1phyk…dqksqq` | $2,717 | swap, add/remove_liquidity, flash_loan/repay_loan, sync_registry, hook, getters |
| `FlexPool` | `package_rdx1pkzx…pcglwe` | $2,622 | same as Pool (pre-rename build) |
| `PrecisionPool` (v3-style) | `package_rdx1pkl8…fmcmc` | $21,919 | swap, add/remove_liquidity(_shape), claim_fees, flash_loan/repay_loan, sync_registry, getters |
| `Registry` | `package_rdx1phgu…zefcfe` | — | `sync` (public), `update_config`/`withdraw_protocol_fees` **(OWNER)** |

| # | Path tested | Gate / live value | Verdict | USD | Confidence | Exact evidence |
|---|---|---|---|---|---|---|
| O1 | **Flash loan, no repayment** (drain the pool) | Public method; *would* expose $3,984 (OCI/XRD) + every v2 pool | **no-exposure** | $0 | very high | `receipts/fl_precision_oci_takeonly.json`, `fl_poolv2_fusd_takeonly.json`, `fl_flexpool_astrl_takeonly.json` → **Failed**, `NonFungibleResourceManagerError(DropNonEmptyBucket)`. The transient RUID "loan terms" NFT cannot be dropped unspent → engine-enforced repayment. Take+repay path works (fee 0.9%). |
| O2 | Flash loan on legacy `BasicPool` | method absent | **no-exposure** | $0 | very high | `receipts/probe_legacy_basicpool_flash_loan.json` → `AuthError(NoMethodMapping(… BasicPool …))` |
| O3 | **Swap rounding / micro round-trips** | fee 0.1–1% + floor-rounded output | **no-exposure** | $0 | high | Both directions, 5 pools: 10 XRD RT → BasicPool DFP2/XRD **−0.199**, BasicPool EARLY/XRD **−0.199**, Pool v2.1.0 fUSD/XRD **−0.0599**, PrecisionPool REDDICKS/XRD **−0.199**, PrecisionPool OCI/XRD **−0.0599**; token-first RT → 1 DFP2 **−0.0199**, 1 OCI **−0.005991** (all exactly 2×fee). Code: `input_amount_net` ceil, `output_amount` floor, imbalanced math adds `ATTO`/`POW_ERROR_MARGIN` against the trader; PrecisionPool `new_price` subtracts one divisibility unit. |
| O4 | **add→remove liquidity round trip** (donation/share-inflation) | native `TwoResourcePool` contribute/redeem; v3 add/remove math | **no-exposure** | $0 | high | BasicPool: deposit 1 + 1.5 → add → remove → **account net delta 0.0** (`basic_dfp2_addremove_1_1.5.json`). PrecisionPool full-range and narrow-range: 20 OCI + 5 XRD → add → remove → **net 0.0 both tokens** (`pp_oci_addremove_fullrange.json`, `…_narrow.json`). Dust add reverts (`LargerContributionRequiredToMeetRatio`). |
| O5 | **Fresh-position fee theft** (`claim_fees`) | position checkpoints initialised at mint | **no-exposure** | $0 | high | `pp_oci_add_claim_fees.json` → `ClaimFeesEvent` **x_amount = 0, y_amount = 0**. Code: `add_liquidity_internal` computes checkpoints via `value_in_range()` after tick insert; `update_or_insert_tick` initialises `x_fee_outside` = 0 above price / = `x_lp_fee` at-or-below (correct v3 semantics); crossing uses `update_outside_values` (feeGlobal − feeOutside). |
| O6 | **Hook abuse** (malicious/stale hook taking up to 10% of output) | hook registry empty | **no-exposure** | $0 | very high (complete) | `hooks` metadata is a **locked empty array** on every examined Pool/PrecisionPool. **Complete sweep: all 578 live pools ($44,927.83 TVL) → 0 pools with hooks** (`ociswap_hooks_sweep.json`, `hooks_full.log`). Hooks can only be registered by the pool creator at instantiation. |
| O7 | Registry admin (`update_config`, `withdraw_protocol_fees`) | OWNER badge `resource_rdx1thrpc7…prm4nh` | **P (privileged)** | $0 (not outsider) | very high | `registry_update_config.json`, `registry_withdraw_protocol_fees.json` → `AuthError(Unauthorized … Require(Resource(resource_rdx1thrpc7…)))` |
| O8 | `set_liquidity_pool_meta` metadata tamper | blueprint role | **no-exposure** | $0 | very high | `legacy_bp_set_liquidity_pool_meta.json`, `v2pool_set_liquidity_pool_meta.json` → `AuthError(Unauthorized … RoleKey("blueprint"))` |
| O9 | `sync_registry` as a money pump | public, but net-zero for caller | **no-exposure** | $0 | very high | `v2pool_sync_registry.json` → Succeeded, **account deltas {}**; it pushes pool protocol-fee vaults to the (owner-only) registry. |
| O10 | **Direct drainage of the underlying native `TwoResourcePool`** (bypassing the DEX wrapper) | `pool_manager_role` = DEX global-caller badge | **no-exposure** | $0 | very high | `native_protected_deposit_ociswap_basic_dfp2.json` / `…_defiplaza_xrd_dfp2.json` → `AuthError(Unauthorized … RoleKey("pool_manager_role") …)`; every examined native pool's owner role is a Protected NF-badge rule held by the wrapper component. |

---

## 2. DefiPlaza — per-path verdicts

Deployed code: `PlazaDex` + `PlazaPair`.
Two package builds are live: **`package_rdx1p4lnurh…`** (main DEX `component_rdx1cqy7sq3…`, 135 pairs — the
pair build is *older*, without the view functions) and **`package_rdx1p4dhfl7…`** (5 smaller DEX instances,
21 pairs — newer build with `get_state/get_pools/get_tokens`).
`PlazaPair` auth template is **AllowAll** → its methods (`swap`, `quote`, `add_liquidity`,
`remove_liquidity`) are callable by anyone, including directly (bypassing `PlazaDex`).
`PlazaDex` owner badge: `resource_rdx1nfmknrk53gqqqrg45u4rut0kw72697xfj7nsw4tw9y8kthlmj4qd2j`.

| # | Path tested | Gate / live value | Verdict | USD | Confidence | Exact evidence |
|---|---|---|---|---|---|---|
| D1 | **Swap round trips / curve-state manipulation** | fee 0.4–1% + away-from-zero rounding | **no-exposure** | $0 | high | XRD→DFP2→XRD same-tx: 10 XRD **−0.19144**, 100 **−1.91531**, 1000 **−19.24502** (≈1.92% ≈ 2×0.96%). Direct `PlazaPair.swap` **identical** (−0.19144) → no routing-layer advantage. 2-hop XRD→ASTRL→XRD **−0.30759** (3.07%). |
| D2 | **add→remove LP, non-shortage side** | native `TwoResourcePool` | **no-exposure** | $0 | high | 100 XRD → 3.960967 LP → redeem **99.999999999999999982 XRD**, account **net 0.0** (`dp_addremove_lp_xrd_100_0f4ju8.json`). |
| D3 | **add→remove LP, shortage side (audit H01 area)** | co-liquidity required | **no-exposure** | $0 | high | live pair in `QuoteShortage`: 100 DFP2 + 60 XRD → LP → redeem → **net 0.0** (`dp_add_DFP2_shortage.json`). Omitting co-liquidity reverts: `PanicMessage("In shortage: requires counter liquidity. @ src/pair.rs:290:60")` (`dp_add_DFP2_shortage_no_coliq.json`). |
| D4 | `PlazaDex` admin (`withdraw_owned_liquidity`, `set_min_dfp2`, `blacklist`) | OWNER badge | **P (privileged)** | $0 (not outsider) | very high | `dp_dex_withdraw_owned_liquidity.json`, `dp_dex_set_min_dfp2.json`, `dp_dex_blacklist.json` → `AuthError(Unauthorized … Require(Resource(resource_rdx1nfmknrk…)))` |
| D5 | Swap royalty as a revenue lever | royalty charged **to** the trader (USD 0.05/swap on PlazaPair) | **no-exposure** | $0 | high | Deployed `royalty_config`: PlazaPair swap = USD 0.05, PlazaDex = disabled. Only increases attacker cost. |
| D6 | Source-version drift (main DEX pair = older build) | — | **S (residual unknown)** | $0 | medium | `TypeCheckError(BlueprintPayloadDoesNotExist … Function("get_state"))` on main-DEX pairs; panic string differs from repo HEAD → deployed main pair ≠ audit-final code. Mitigated by direct live testing of exactly the risky path (D3 → net 0.0). |

---

## 3. Why nothing pays out (structural)

* Both protocols expose only: **swap** (fee + rounding biased to the pool), **add/remove liquidity**
  (native `TwoResourcePool` contribute/redeem, or v3-style math with ceil-in / floor-out),
  **flash loans** (engine-enforced repayment + fee), **fee claims** (position-scoped checkpoints),
  **view getters**, and **role-gated admin**.
* No public method transfers value to `Runtime::caller()` without an equal-or-greater input.
* Fees/tributes that *do* exist (Ociswap registry protocol fees; DefiPlaza DEX-owned LP) are reachable only
  through OWNER-badge methods, verified to revert for an unprivileged caller.
* Native Radix `TwoResourcePool` semantics make LP round-trips exactly value-conserving (measured net 0.0),
  and both AMMs' custom math rounds against the trader at every step.

## 4. Residual risks / caveats (not E-U)

1. **S1 — PrecisionPool tick-fill griefing (medium-value, non-profitable):** `update_or_insert_tick` asserts
   `tick.total_liquidity <= max_liquidity_per_tick`. An attacker with capital can fill a tick at a chosen bound,
   temporarily blocking other LPs from adding at that tick; capital is recoverable and the attacker gains
   nothing. Not tested further (no value transfer).
2. **S2 — DefiPlaza main DEX runs an older, un-diffable PlazaPair build** (audit commits are not public). The
   H01-class "token loss on add_liquidity during shortage" cannot be excluded by source review alone, but the
   live shortage path was tested end-to-end and conserved value exactly. Also note the older build lacks the
   audit's view-function additions, i.e. it is pre-`34b3c74`.
3. **S3 — Legacy Ociswap `BasicPool` source is not in the public repos found.** Interface and behaviour were
   verified on-chain instead (4-field state, no flash loan, no hooks, native-pool liquidity).
4. **S4 — Hook surface (complete check):** all 578 live Ociswap pools ($44,927.83 TVL) were swept
   individually — **0 pools have registered hooks** anywhere in the DEX.
5. **S5 — No cross-transaction timing tests.** Previews execute at the current clock, so the DefiPlaza
   decay-factor TWAP (multi-minute manipulation) and multi-block strategies could not be simulated. Within a
   single transaction, manipulation is not profitable (D1).
6. **Valuation:** USD numbers are the protocols' own API valuations cross-checked against on-chain vaults for
   the largest pools; long-tail memecoin legs may be illiquid (treat as upper bound).

## 5. Artefacts in `analysis/dex_audit/`

| File | Content |
|---|---|
| `findings.json` | machine-readable findings incl. per-path verdicts, negatives, caveats |
| `enumerate_live.py` / `enumerate_defiplaza.py` | full enumeration (Ociswap 1,847 pools; DefiPlaza 156 pairs) |
| `ociswap_pools_live.json` / `defiplaza_pairs_live.json` | live pools/pairs with TVL |
| `fetch_top_entities.py`, `fetch_balances_pkgs.py`, `extract_deployed_ifaces.py`, `fetch_full_metadata.py`, `dump_states.py`, `dp_recon.py` | on-chain state/interface/balance extraction (authoritative deployed schemas) |
| `ociswap_deployed_ifaces.json`, `ociswap_top_balances.json`, `dp_top_pairs.json`, `dp_pair_to_lps_all.json` | raw dumps |
| `preview_lib.py` | preview harness (long timeout, receipt parsing: status, error, fee, per-entity deltas) |
| `test_roundtrips.py`, `test_flashloan.py`, `test_addremove.py`, `test_lp_roundtrips.py`, `test_defiplaza.py`, `test_dp_shortage.py`, `test_gates.py` | adversarial test suites |
| `receipts/*.json` | **raw preview receipts** (the evidence for every verdict; previews only, never submitted) |
| `roundtrip_results.json`, `flashloan_results.json`, `addremove_results.json`, `lp_results.json`, `defiplaza_results.json`, `dp_shortage_results.json`, `gate_results.json`, `totals.json` | summarised results |
| `hooks_sweep.py` / `ociswap_hooks_sweep.json` | hook-registry sweep over live pools |
| `src_defiplaza/` | DefiPlaza contract source (OmegaSyndicate/RadixPlaza @ e6f9f6b) used for review |
| `../src/ociswap_*` | Ociswap sources (pre-existing clone) used for review |
