# Virtue (IOTA L1) — zombie-hunt II Tier-3 re-audit (L2-01)

**Date:** 2026-10-15 · **Chain:** IOTA Rebased L1 (Move VM, `iota_*` JSON-RPC) · **Status:** read-only; no transactions sent; all exploit checks executed via `iota_devInspectTransactionBlock` (non-committing) and state reads at checkpoint **204,100,983**.

**Scope of this re-audit:** H2-06 covered Virtue in a cluster but its IOTA child stalled mid-run; the dynamic-field walk had failed, and a latent critical (an oracle-operator position holding 4.94M VUSD against 1 IOTA) was never followed up. This folder re-verifies everything from scratch, completes the object walk, reconstructs the incident that H2-06 flagged as "latent", and tests today's live attack surface with chain-native read-only simulation.

---

## 1. TL;DR

| Target | Live extractable (unprivileged, today) | Why closed / open | Latent risk |
|---|---|---|---|
| Virtue CDP (4 vaults, ~$1.83M collateral) | **$0.00** | **Admin-frozen since 2026-08-29**: `vusd::remove_version` emptied the CDP module-version set → every `request::debtor_request` aborts `err_invalid_module_version` (no borrow/repay/deposit/withdraw for anyone). | Re-enable (P, single EOA `0x34adddfe…`) unlocks $1.83M to position owners. |
| Virtue oracle (aggregater/collector/rules) | **$0.00** | Fake-price path closed: Switchboard rule weight removed after the Aug-28 exploit; Pyth rule has feed-id + freshness checks; `aggregater::new`/`set_rule_weight` require `ListingCap`; `PriceResult` creatable only by `aggregater::aggregate` (Friend). | If the admin re-adds a weak rule, the Aug-28 recipe re-arms. |
| Stability Pool ($189.5k VUSD) | **$0.00** | Deposits permissionless; withdrawals/claims are position-scoped (fresh address → `err_account_not_found`; non-depositor claim returns 0). | none found |
| Recovery module (`0x732ce638…`) | **$0.00** | `recovery::mint` requires `&AdminCap`. | P-only minting (used 2026-10-01 to repay SP depositors) |
| **Latent position (4.94M VUSD vs 1 IOTA)** | **$0.00 attacker-profit** | The position is real (`0x381d5b5f…`): 1.027 IOTA collateral, 4,942,737.62 VUSD debt. **Correction to H2-06:** it was *not* minted "on the stale feed" — it was minted by **forging the oracle price to $10,000,000/IOTA** via self-registered Switchboard oracles. Liquidating it yields ~$0.05 of collateral against 4.94M VUSD of debt ⇒ unprofitable for any attacker; it is protocol bad debt (S). | Write-off/recovery is admin work (P) |

**Total live extractable by an external unprivileged attacker now: $0.00 — confidence: HIGH** (every candidate path was executed to its abort via dev-inspect against live state, or is admin-gated by a verified object owner).

---

## 2. The incident that created the latent position (fully reconstructed)

H2-06 recorded: *"oracle-operator position minted 4.94M VUSD against 1 IOTA (health check passed on the stale feed)"*. That description is **incorrect in mechanism**. On-chain reconstruction (all digests verified):

1. `2026-08-28 21:48 UTC` — address `0x381d5b5fa3ae0ba5b3d0ce3421a43d48397cf6eb2a87e624d56dec5e68e7c7e9` (its **first ever transaction**) calls Switchboard's permissionless `oracle_init_action::run` (package `0x8650249d…`) and **creates its own Switchboard oracles** (`OracleCreated` events, attacker-supplied keys, `mr_enclave` all zeros).
2. `21:53 UTC` — tx `CaAD9SRJjuvEbNiHQcgT176kg4F8jKUTM1EneeYsd3Gd` (48 commands) submits **14 fake oracle results** (`aggregator_submit_result_action::run`, value `1e25` ⇒ **$10,000,000 per IOTA**) and then runs the standard Virtue borrow flow with the resulting price:
   `collector::new` → `switchboard_rule::feed` → `aggregater::aggregate` → `IOTA>` event `result: 10000000000000000` → `vault::update_position<IOTA>` with `option::some(PriceResult)`.
   **Result: 4,942,703.66 VUSD minted against 1.027 IOTA collateral** (health check passed because the caller-supplied price said $10M).
3. The attacker dumped **455,000 VUSD** into the two AMM pools (`0xb768e68c…` IOTA/VUSD and `0x9b5c57e9…` CERT/VUSD) for **366,442.34 IOTA + 2,196,543.50 CERT ≈ $131.6k** (current prices), deposited/withdrew through the SP, and still holds **4,146,017.57 VUSD** (unsellable — both pools' VUSD sides were drained to ~1,136 VUSD total).
4. `2026-08-29 03:29 UTC` — the deployer **removed the CDP module version** (`vusd::remove_version`, tx `2qt1Kn3X9LNhXxBw29otbcY83H9B787DtAdLBHKFrE1J`) ⇒ protocol-wide freeze.
5. `2026-10-01` — the deployer registered the new **recovery** module and minted 113,406.35 VUSD to **46 SP depositors** (`RecoveryMint` events), restoring the Stability Pool to 189,497.63 VUSD.

Root cause: Virtue's `switchboard_rule` trusted a Switchboard aggregator (`0x7c16ffda…`) whose oracle set was not access-controlled — a **permissionless fake-oracle registration** into the same queue the aggregator reads. Virtue's own gates (feed-id check, freshness check, ListingCap-gated rule weights) are present in the current code.

---

## 3. Live-state assessment (checkpoint 204,100,983, 2026-10-15)

### Packages (all live, immutable)
| Component | Address | Version |
|---|---|---|
| Framework | `0x7400af41…083b` | v1 |
| VUSD Treasury | `0xd3b63e60…904f` | v1 |
| Oracle | `0x7eebbee9…c2cf` | v1 |
| CDP (orig) → current | `0x34fa327e…dd22` → `0xcdeeb40c…86ba1` | v2 |
| Stability Pool (orig) → current | `0xc7ab9b93…d83b` → `0xe50fa492…929b` | v2 |
| Recovery (new) | `0x732ce638…c952` | v1 |

### The four vaults (complete dynamic-field walk — 79 positions; see `analysis/vault_positions.csv`)
| Vault | Object | Positions | Collateral | VUSD borrowed | MCR |
|---|---|---|---|---|---|
| Vault\<IOTA\> | `0xaf306be8…48d5` | 17 | 2,410.07 IOTA | 4,942,752.46 | 110% |
| Vault\<CERT swirl\> | `0xc9cb4946…e259` | 56 | 8,950,007.81 CERT | 140,610.97 | 110% |
| Vault\<IBTC\> | `0xcc094d9e…c5c9` | 4 | 14.955 IBTC | 726.49 | 110% |
| Vault\<CERT 0xe4ab\> | `0x53b6405d…dd26` | 2 | 3,000,003.91 CERT | 65.22 | 110% |

### Stability Pool
- `0x6101272394511caf38ce5a6d120d3b4d009b6efabae8faac43aa9ac938cec558`, `vusd_balance = 189,497.63 VUSD`; **192 positions whose balances sum exactly to the on-chain balance** (`analysis/sp_positions.csv`). `liquidator = 0x0`, fee 2%, rebate 0.5%.

### VUSD
- `total_supply = 5,197,561.500789`; CDP module supply 5,084,155.15; recovery module supply 113,406.35. Treasury beneficiary `0x231b8f89…164a`.

### Roles / authority (all verified object owners)
- **AdminCap** `0x38a7b38d…c3f5`, **ListingCap** `0xab69414b…a3d7`, **5× UpgradeCaps**, **Publisher** — all owned by the single address `0x34adddfebf80ab25d8a842fe2ab152f96bc70c2d645c60b8eb6d765175cb6dbe`.
- Deployer `0xf67d0193…5a12` published everything and executed the freeze + recovery.

---

## 4. What an attacker can / cannot do today (exact call paths, all dev-inspected)

**Cannot (all executed to abort against live state — see §5):**
- **Fake-price borrow** (`switchboard_rule::feed` + `aggregate`): the Switchboard rule is no longer weighted in the IOTA aggregator → `aggregater::err_total_weight_not_enough`. Re-adding it requires `ListingCap` (`set_rule_weight(&mut agg, &ListingCap, w)`), held by `0x34adddfe…`.
- **Create a private aggregator**: `aggregater::new(&mut ListingCap, u64, &mut TxContext)` — ListingCap-gated.
- **Pyth price substitution**: `pyth_rule::feed<IOTA>` with a different asset's PriceInfoObject aborts `err_invalid_price_info_object` (feed-id check); with the correct object it aborts `pyth::check_price_is_fresh` (on-chain price stale since 2026-08-25).
- **Forge a `PriceResult` directly**: `result::new` is a Friend of `aggregater` only.
- **Any CDP operation** (borrow/repay/deposit/withdraw collateral): `request::debtor_request` aborts `vusd::err_invalid_module_version` — the Treasury's `module_versions_map` for `…::witness::VirtueCDP` is **empty** (admin freeze).
- **Drain the Stability Pool**: `withdraw` from a non-depositor aborts `err_account_not_found`; `claim` from a non-depositor returns a 0-value coin; deposit is permissionless but yields only pro-rata claims.
- **Recovery mint**: `recovery::mint(&mut Treasury, &mut StabilityPool, &Clock, &AdminCap, Address, u64, &mut TxContext)` — AdminCap-gated.

**Can (but no extraction):**
- Deposit VUSD into the SP (permissionless; deposits are position-scoped and pro-rata).
- Read all state (`get_positions`, `get_position_data`, dynamic fields).
- *If* the Pyth price were refreshed by anyone with a Pyth API key (Hermes now requires one; free) *and* the admin re-enabled the CDP: borrow/liquidate at the **real** price. At real prices (IOTA $0.0453, BTC $81,211) every position is over-collateralized except the 4.94M-VUSD bad-debt position, whose liquidation yields 1.027 IOTA ≈ $0.05 — **no attacker profit**.

---

## 5. PoC / verification (read-only, chain-native)

`iota_devInspectTransactionBlock` executes the exact PTBs against live state without committing (no gas, no tx). The suite is in `ci/dev_inspect_tests.mjs` (+ copies in `analysis/`), run by `ci/run.sh`:

- **8/8 dev-inspect checks PASS** (P1 stale-abort, P2 wrong-feed-abort, P3 weight-abort, F1 CDP-frozen-abort, W1 depositor-withdraw-ok, W2 non-depositor-abort, W3 non-depositor-claim-zero, F3 permissionless-deposit).
- **24/24 live-state checks PASS** (`ci/verify_state.py` → `ci-out/state_check.json`): packages, vaults, the latent position (debt `4942737620436`, coll `1027000000`), SP balance, Treasury version sets (CDP empty / recovery v1), VUSD supply, aggregator weights, attacker VUSD balance.

CI: run via `bash /home/heisenberg/CA/ci/ci-run.sh virtue` → see `ci-log.txt` and `ci-out/` artifacts (URL recorded below).

---

## 6. Verdict & residual risk

- **E-U (external unprivileged extractable today): $0.00 — HIGH confidence.**
- **H-O (self-service, now): 189,497.63 VUSD** in the Stability Pool (withdraw proven for a depositor). Face value ≈ $189.5k; realizable value is limited because VUSD's DEX liquidity was drained in the incident (~1,136 VUSD left in the two pools).
- **S (stuck): ≈ $1,827,097** of vault collateral (2,410.07 IOTA + 8.95M CERT + 14.955 IBTC + 3.0M CERT_b at current prices), frozen by the admin's module-version removal. It becomes H-O for the position owners only if the admin re-registers the CDP module version (**P-conditional**).
- **P (privileged):** the single EOA `0x34adddfe…` holds AdminCap + ListingCap + all UpgradeCaps — it can re-enable the CDP (unlocking the $1.83M), mint via recovery, change the Treasury beneficiary, or upgrade any package. No P value is counted separately (the collateral is already in S).
- **Latent position (quantified separately):** `0x381d5b5f…` holds **1.027 IOTA collateral vs 4,942,737.62 VUSD debt** (≈ $0.05 vs $4.94M). Not attacker-extractable: minting is closed, the CDP is frozen, and even a fully refreshed + unfrozen system would not make its liquidation profitable. It is **$4.94M of protocol bad debt**; the attacker still holds 4,146,017.57 unbacked VUSD and extracted ≈ $131.6k of real assets on 2026-08-28 (already gone).

**Residual/latent risk:** (1) re-enabling the CDP without fixing the bad debt leaves the protocol insolvent and re-arms liquidation bots (no external profit, but SP loss); (2) re-adding a weak oracle rule would re-arm the Aug-28 recipe — the current code's feed-id/freshness checks and ListingCap gating are the correct mitigations; (3) single-EOA admin is a centralization/key risk for the $1.83M frozen collateral.

**Blockers documented:** admin freeze (module versions), stale Pyth feed (2026-08-25), Hermes API-key requirement for price refresh, drained VUSD liquidity, ListingCap gating.

---

## 7. Methodology, caveats, files

**Methodology:** all addresses taken from Virtue's docs + iota-registry and re-verified on-chain; object/position walk via `iotax_getDynamicFields` + `iota_multiGetObjects`; incident reconstruction from `iota_getTransactionBlock` (inputs, commands, events, object/balance changes); path testing via `iota_devInspectTransactionBlock` (read-only); prices from DefiLlama (IOTA $0.045306, BTC $81,211) and on-chain oracle events for CERT ratios. No keyed RPC URLs or secrets were used or stored (public endpoint only).

**Caveats:** (a) CERT/CERT_b USD values are estimates (IOTA × on-chain pool rate; last oracle ratios); (b) IBTC is valued at BTC/USD per its Pyth feed (bridge-backing not independently verified); (c) dev-inspect reflects state at the recorded checkpoint; (d) the exact Switchboard-side validation gap (oracle-set membership) was inferred from the attacker's successful self-registration, not from Switchboard source.

**Files:** `README.md`, `summary.json`, `analysis/SUMMARY.md`, `analysis/vault_positions.csv`, `analysis/sp_positions.csv`, `analysis/raw/*.json` (full dumps), `analysis/dev_inspect_*.mjs`, `ci/` (run.sh, verify_state.py, dev_inspect_tests.mjs), `ci-out/` (CI artifacts), `ci-log.txt`.
