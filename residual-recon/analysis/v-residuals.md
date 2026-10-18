# Residual leads inside wave2/v*.md (beyond each file’s main target)

| File | Residual lead | Disposition |
|---|---|---|
| v15-7702module | Beacon-proxy module `0x535023ed` — 481 live delegators, 173.70 ETH (~$423.9k) + tokens | **CLOSED-LANE (not E-U)** — all real fund movers gate `msg.sender == address(this)`; wave-1 eth_call success was the empty fallback. Tripwire on beacon upgrade. |
| v26/v32 SparkDEX | ~150 older V4 pools with unverified plugin impl `0x893388ba` | **CLOSED-LANE** — v32 byte-diff/fork: legacy set ≈$48.8k, $0 E-U; no residual ≥$1k. |
| v27 Rujira | Off-hash FIN pair (code 194, $4.1k) | **CLOSED-LANE** — below bar; pre-v2.2.2 ancestry but no exploit recipe. |
| v19 SyncSwap | Excess-attribution primitive (`deposit(token,to)` can claim unattributed balance) | **CLOSED-LANE** — live excess only in worthless spam tokens; native excess not claimable; 2.2M+ USDC flow swept block-by-block. |
| v29 Exponent/Tessera | Vault `initialize_vault` permissionless + ADV-31 default-mint TokenEntry; Tessera swap rounding/pool↔quote binding | **LOW / not fully closed** — demonstrated theft from existing vaults $0; scam-vector only (victim must deposit into attacker-made vault). |
| v12 Decibel | Stale DPV-share price (600s) as collateral | **LOW / watch** — live exposure 38.2k shares (~$41.1k); max realistic $10–12k on >10% NAV crash inside refresh window; not E-U today. |
| v9 Crystal | `slot0` router scratchpad | **CLOSED-LANE** — slot0=0 for all 31 assets; function never used; no 2-tx deposit pattern. |
| v36 Haedal | vault_incentive forwarding; cetus_clmm loss path; keeper ratchet | **CLOSED-LANE** — P/keeper-gated; no live funds at direct risk; residual edges for a future pass. |
| v34 SundaeSwap | 3 of 14 validators lack public source (governance/treasury/fee_constraint) | **CLOSED-LANE / LOW residual** — cannot violate pool-level invariants; no observed flaw. |
| v4/v4b RealT | Yam offer exit / incumbent relationship | **CLOSED-README (ZH4-07)** — whitelist + ~$0 exit; true unprivileged net $0. |
| v2 BeraFarm | post-incident unverified impls | **FINDING (ZH4-06)** — monitor only. |
| v13 Faiyah | pool deficits / 2027 pot | **FINDING (ZH4-05)** — H-O first-mover; not E-U. |

All other v*.md residual notes are P-class, H-O, or below-bar; the main target verdicts are already in the README Tier/CLOSED lists.