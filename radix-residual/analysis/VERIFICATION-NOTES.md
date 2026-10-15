# Independent verification notes (parent agent)

Parent's own spot-checks of the child-subagent findings (all read-only previews, never submitted), 2026-10-15:

| # | Claim | Parent re-check | Result |
|---|---|---|---|
| 1 | Weft zero-capital flash liquidation works | Re-ran `28_preview_flashliq.py` at 12:03Z (state 563,384,952) | Succeeded; repaid 2.550022 XRD, seized 2.626523 XRD, fee 0.015759 XRD, **net +0.0587415 XRD** — matches child |
| 2 | Weft #1015 45-hUSDC liquidation nets positive | Re-ran `29_preview_liq1015.py` at 12:03Z | Succeeded; seized **111,472.14 XRD**, fee 2,675.33 XRD, **net +108,796.81 XRD** (profit +$4.19) |
| 3 | Top CDPs underwater | `get_cdp` preview for #1015/#517/#100/#1029 at 12:03Z | liq_ltv **1.1373 / 1.0696 / 1.0591 / 1.1704** |
| 4 | hUSDC supply 1,092.79 | Gateway entity details at state 563,384,935 | total_supply **1,092.793964** |
| 5 | Weft drift mechanism | `get_cdp` + `get_price` at 12:18Z (state 563,386,642) | liq_ltv 1.0751/1.0110/1.0011 with **unchanged debt/collateral**; hUSDC oracle 2211.70 → **2090.73 XRD** → cap $101.5 → $96.2 |
| 6 | JustLock gates | Preview: `withdraw` on locker | Failed `BlueprintPayloadDoesNotExist` (no such entry point); child's negatives (foreign bucket panic, empty-bucket no-op) consistent |
| 7 | RadLock v2 recovery + gates | Gateway entity details + `radlock_evidence.py` re-run | Components live (`RadlockService` 1.0.0 @ proxy pkg `package_rdx1p53g7…`, logic pkg `package_rdx1p4pz6ws…`); `get_xrd_fee_vault` = **10,500 XRD**; `withdraw_flat_xrd_fees`/`withdraw_liquidity_fees` → `Unauthorized(admin_auth resource_rdx1th5shlln…)`; `method_call` → `Unauthorized(storage_access_auth)` |
| 8 | RlyFun fee vault + gate | `check_fee_vault` preview + re-ran `rlyfun_claim_fee_probe.py` | Vault = **633,433.343807393 XRD**; fresh-dev `claim_fee` → `Invalid proof: Expected ResourceAddress(9aedd185…) but got (9a23a51a…)` |
| 9 | Ociswap round-trips lose 2×fee | Fresh 10-XRD round-trip on BasicPool DFP2/XRD | Succeeded; account net **−0.199 XRD** |
| 10 | DefiPlaza round-trips lose fees | Fresh 10-XRD round-trip via PlazaDex | Succeeded; **−0.188 XRD** |
| 11 | Ociswap flash take-only blocked | Preview `flash_loan` + deposit without repay | Failed `NonFungibleResourceManagerError(DropNonEmptyBucket)` |
| 12 | CI reproducibility | `ci/run.sh` on GitHub runner ×2 | **13/13 PASS** both (runs 38732758186 @563,385,804; 38733399198 @563,386,042) |

CI job: `ci/verify_live.py` (checks W1–W4, L1–L3, D1–D3; results in `ci-out/results.json`, runner artifact
`result-radix-residual`). All checks use the public Gateway only; no secrets.

Redaction note: three third-party API dumps (`ociswap_pools_scanned.json`, `astro_tokens.json`,
`radlock_docs.html`) contained public CDN image URLs with third-party signed `token=` query params (not our
secrets). Values were redacted to `token=REDACTED` before the final CI run; the branch is clean.
