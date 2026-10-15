# lockers_audit — artifact map

Read-only Radix mainnet work (public Gateway). No tx ever signed/submitted. Nothing outside
this folder was modified.

## Deliverables
- `FINDINGS.md` — full write-up (verdict table, gates, preview receipts, negatives, caveats)
- `findings.json` — machine-readable verdicts (E-U / H-O / P / S), totals, key facts, negatives

## JustLock (`jl_*`)
| File | Purpose |
|---|---|
| `jl_scan.py` | component state + 423 lock vaults + 423 receipt NFT data + holders |
| `jl_vault_refetch.py` | vault contents (fungible + NFT vault) |
| `jl_summary.py` | per-lock table, per-resource aggregation, resource metadata |
| `jl_value.py` / `jl_valuation*.json` | H-O vs S USD split (Astrolescent prices × DefiLlama XRD) |
| `jl_preview.py`, `jl_preview2.py` | holder discovery + negatives N1/N2/N3/N4 (preview only) |
| `jl_semantics.py`, `jl_semantics_previews.json`, `jl_preview_A_raw.json` | lock→unlock success, None/future/foreign panics |
| `jl_pool_prices.py` | DEX-pool implied prices for unpriced locks (IN/MEOWTA/BLUES/SPED) |
| `jl_receipt_owner_map.json` | (partial) holder↔receipt mapping attempt |

## RlyFun (`rlyfun_*`)
| File | Purpose |
|---|---|
| `rlyfun_sell_probe.py`, `rlyfun_sell_probes.json` | S1 legit sell / S2-S3 foreign-token sell attempts / S4 proof type |
| `rlyfun_filled_probe.py`, `rlyfun_filled_and_misc_probes.json` | F1 set_curve_filled / F2 buy_from_pool / F3 foreign buy / F4 round-trip |
| `rlyfun_claim_fee_probe.py`, `rlyfun_launch_then_claim_fee_preview.json` | launch→fresh dev badge→claim_fee E-U attempt (rejected: owner badge required) |
| `rlyfun_claim_fee_owner_raw.json` | control: owner-badge claim moves 633,433.34 XRD (P) |
| `rlyfun_method_argcounts.json` | blueprint function arg counts |

## RadLock (`radlock_*`)
| File | Purpose |
|---|---|
| `radlock_components.py`, `radlock_holder_components_full.json` | 986 component-holder scan (no RadLock in archived resource holders) |
| `radlock_verify.py`, `radlock_components_state.json`, `radlock_resources_state.json` | live components recovered from app.radlock.io bundle config + verified |
| `radlock_component_summary.json`, `radlock_valuation.json` | states + locked value (426 Locked-Resource NFTs) |
| `radlock_locks_*.json`, `radlock_locked_nft_*.json` | per-lock vaults + NFT data (status/unlock time/amount) |
| `radlock_evidence.py`, `radlock_preview_evidence.json` | preview evidence: fee-vault getter (10,500 XRD), Unauthorized role failures, withdraw field types |
| `radlock_logic_pkg.json`, `radlock_v2_package_details.json` | live package interfaces |

## Shared
- `astro_tokens.json` — token price snapshot (Astrolescent)
- `dcks_holders.json`, `coke_holders.json` — pricing/liquidity checks
- `rlyfun_package_details_new.json` — RlyFun package interface dump
