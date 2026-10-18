# ZOMBIE-HUNT IV · Wave B2 — Exotic/Legacy cluster (Tier-3 group 6)

**Date:** 2026-10-18 · **Mode:** read-only research; no transaction signed or sent on any network · **Chains:** Ethereum, Base, Mezo, Arbitrum, TRON (+ desk-lead reads on Ethereum/Arbitrum) · **Scope:** ZH4 Tier-3 rows 1–3, 25, 28, 30 + the four unresolved desk leads.

This folder is the **index**. Each target has its own protocol-named folder with a `README.md`, `summary.json`, `analysis/` and, where applicable, `ci-out/`.

## Headline

| Metric | Result |
|---|---|
| **Live E-U (external unprivileged) across the cluster** | **$0** |
| E-U-conditional | ≈$1.8k (THEO relayer-key compromise; capped by pool USDC) |
| P (privileged/key/governance exposure, not extractable) | **≈$252.3M** across the located targets (USDD immediate $41.23M; 3F $39.74M; Zama $131.01M; TxFlow $31.51M; Kamui $2.87M; Mezo $5.68M; Aragon $0.29M; THEO $1.8k) |
| S (stuck/bricked) | **≈$240k** — Aragon DAP's 100 ETH vault with a 0-supply governance token |
| Realized historical losses referenced | THEO ~$1.76M (Oct 12); MakerDAO keeper ~$538k (Oct 6) |
| Targets fully checked | 10 (6 named rows + 4 desk leads) |

**None of the seven named Tier-3 targets is an externally extractable live bug today.** The cluster's value is in the corrections: the largest Aragon vault is *stuck*, not capturable; the THEO "residual $40.5k" is only ~$1.8k of real USDC; the Mezo Voter is P-only at every value edge; the Maker family is empty; USDD is at par with the arb closed at the margin; and the four desk leads resolve to custody/curator/validator designs with no unprivileged release.

## Per-target table

| Target | Folder | Live funds checked | E-U | E-U-cond | P | S | Verdict | Conf. |
|---|---|---|---:|---:|---:|---:|---|---|
| **USDD (TRON V2 PSM/CDP)** | [`usdd/`](usdd/) | $1.317B supply; PSM 41.23M USDT | **$0** | $0 | $41.23M immediate ($1.23B theoretical) | $0 proven | PSM 0-fee at par (0.99999978); round trip −$99.79/$1M; no public mint | high (0.82) |
| **Aragon-legacy DAO class** | [`aragon-legacy/`](aragon-legacy/) | 2,306 Voting apps / 208.23 ETH funded | **$0** | $0 | ≈$286k | **≈$240k** | no open-vote + liquid-token + funded vault; 100 ETH DAP stuck; ANT gated by 2-of-3 | high |
| **MakerDAO legacy keeper family** | [`maker-keepers/`](maker-keepers/) | 43 Flippers / 6,737 bids | **$0** | $0 | $0 | $0 | 8 expired lots ($4.97k) pay the recorded guy; 5 sibling impls all $0 | high (0.95) |
| **Mezo Swap Voter/gauges** | [`mezo-voter/`](mezo-voter/) | $5.68M pool TVL | **$0** | $0 | $5.68M | $0 | 58 selectors; every value path veNFT/governance gated; Voter holds $37 | high |
| **Euler v2 / EVK vault web** | [`euler-v2/`](euler-v2/) | $303M claim; enumerated vaults | see folder | — | — | — | enumeration + anomaly flags (child report) | — |
| **THEO / Autheo (Base)** | [`theo-autheo/`](theo-autheo/) | $167.4M supply; ~$1.8k pool USDC | **$0** | ≈$1.8k | ≈$1.8k | $0 | single unrotated relayer EOA is the mint root; pool exit ~$1.8k | high / med |
| **3F** (desk lead) | [`3f/`](3f/) | $39.74M | **$0** | $0 | $39.74M | $0 | 1:1 WrappedAsset, role-gated transfers, 2-of-3 Safe; Morpho layer parked | medium |
| **Zama** (desk lead) | [`zama/`](zama/) | $131.01M (+$179.29M staking) | **$0** | $0 | $131.01M | $0 | 26 confidential wrappers, FHE ACL/KMS; verifier layer parked | low |
| **TxFlow** (desk lead) | [`txflow/`](txflow/) | $31.51M USDC | **$0** | $0 | $31.51M | $0 | Bridge2: >2/3 validator sigs + finalizer + dispute window | high |
| **Kamui** (desk lead) | [`kamui/`](kamui/) | $2.87M USDC | **$0** | $0 | $2.87M | $0 | 3 curated Lagoon vaults; user queues/curator | medium |

P and H-O are **not additive** across protocols — they describe who holds the authority/claim, not separate pools of money. E-U is the only additive extraction number.

## Named-row findings in one line each

1. **USDD (row 30, "uncharted")** — mapped the full DSS graph and PSM (`PSM-USDT-A`). `tin=tout=0`, both directions enabled, USDT join holds **41,232,487.38 USDT**. The on-chain USDD/USDT price is **0.99999978** (V3 fee 1 bp): buy-and-redeem is **−$99.79 per $1M**, mint-and-sell **−$100.22**. The visible ~17 bp "discount" is mostly USDT/USD (protocol oracle 0.99873). P-side: PauseProxy is a ward; `Vat.suck` simulated; **GovActionsProxy owner is a single EOA** (`TSF2rq…`, 119.96M TRX). Structural risks: PSM covers 3.13% of supply; 819.8M Vat debt unattributed; old→new exchange unfunded. Full report: [`usdd/README.md`](usdd/README.md).

2. **Aragon (row 28)** — enumerated **16,824 `NewAppProxy` events → 2,306 Voting apps / 2,210 DAOs** (event scan, not a DAO list). `voteTime==0` in **zero** apps (minimum 120 s), so the literal TOP one-tx class does not exist in the current client set. 318 apps allow open `newVote`; **only 1 of 317 governance tokens has any price** (PNK), and its DAO has no fund app. The 33 funded DAOs hold 208.23 ETH: the **100 ETH DAP vault is stuck** (token supply 0; mint role circular), and the rest use private tokens with no venue. The one liquid-token funded DAO (ANT, $5.3k) gates create-vote behind a 2-of-3 Gnosis. Full report: [`aragon-legacy/README.md`](aragon-legacy/README.md).

3. **MakerDAO keepers (row 2)** — complete family sweep: **43 Flippers, 6,737 bids**, 8 expired undealt lots (1.816 ETH + 4,910 KNC = **$4.97k**) — all `deal()`-able but payable to the recorded `guy`, not the caller. Five sibling implementations/copies all contain the ungated `0x8804d1de` drain and all hold **$0**. `vat.can(victim, attackerModule)=1` persists, but the victim has no Vat credit. Full report: [`maker-keepers/README.md`](maker-keepers/README.md).

4. **Mezo Voter (row 3)** — recovered **58 selectors** from the 17,226-byte impl `0xa62060d5…`; every value path is gated (`NotApprovedOrOwner` / `NotGovernor` / `NotEmergencyCouncil` / `NotSplitter`), `initialize` is done. `distribute` is permissionless but pays gauges; `claimRewards` is a no-op without a veNFT. Voter balance: 13,431 MEZO ≈ $37. Full report: [`mezo-voter/README.md`](mezo-voter/README.md).

5. **THEO (row 1)** — the mint root is an **immutable single-EOA `TrustedRelayerIsm`**; the relayer (`0xeF305Ec5…`) was **not rotated**, last tx = final exploit mint (nonce 377, Oct 12 18:54 UTC). No unprivileged `process()` path. The GT "$40.5k pool residual" is overstated: the pool holds **1,821.93 USDC** + 1.87M THEO; realizable USDC ≈ **$1.8k**. No sibling route found (registry empty; no `IsmSet` in the deployment window). Full report: [`theo-autheo/README.md`](theo-autheo/README.md).

6. **Desk leads (row 6 of the task)** — all four located:
   - **3F** `WrapperAssetFactory 0x54f862fa…e82e`, 9 wrappers, **$39,744,441.90** in JAAA/USCC/AA_FalconXUSDC/mGLO; 1:1 mint/burn, role-gated transfers, 2-of-3 Safe owner. [`3f/`](3f/)
   - **Zama** registry `0xeb5015fF…bBA0`, **26 valid pairs**, TVL **$131,010,324.66** + staking $179.29M; FHE ACL/KMS gated. [`zama/`](zama/)
   - **TxFlow** **Bridge2 `0xcDE3F99b…4565`** on Arbitrum, **31,513,855.53 USDC**; >2/3 validator signatures + finalizer + dispute window. [`txflow/`](txflow/)
   - **Kamui** 3 Lagoon vaults (`0xcDA323c2…a344`, `0xA5AE4052…deE6`, `0x9E0DB8F4…3Aab`), **$2,868,521.42**; user queues/curator. [`kamui/`](kamui/)

## Method (what makes the $0 believable)

- **Enumerate by events/factories, not lists.** Aragon: full `NewAppProxy` log scan; Maker: 78 ilks → 43 Flippers via `Cat.ilks` + FlipperFab graphs; THEO: message decode from the relayer's `process()` calldata; 3F: factory `Deployed` logs; Zama: on-chain registry; TxFlow/Kamui: DefiLlama curator/adapter sources + on-chain reads.
- **Read the gate, not just the code.** Every "closed" verdict cites the exact live revert or the exact balance: `APP_AUTH_FAILED`, `NotApprovedOrOwner`, `NotGovernor`, `NotSplitter`, `trustedRelayer()` = EOA, `vat.gem=0`, `totalSupply=0`.
- **Price the exit.** RealT-style: a seize without a sell is not extraction. THEO's $40.5k headline was re-priced to ~$1.8k of USDC; Aragon tokens with no DEX were not counted as E-U even where the vote path is open.
- **Read-only.** Every read is an `eth_call`/`eth_getLogs`/Tron constant call at a recorded block. No `cast send`, no key use, no mainnet transaction.

## CI

- Umbrella read-only verifier: `exotic-legacy-cluster/ci/verify.py` (25 checks across ETH/Base/Mezo/Arbitrum/TRON), run by `ci/run.sh`. CI URL: _filled after the run_ (see `ci-log.txt` / `ci-artifacts/`).
- The verifier re-checks the decisive fact of each target: DAP supply 0, SHARE agent balances + `canForward`, ANT `newVote` gate, Maker `vat.gem=0`/`can=1`/FLIP 3190 lot, 3F/Zama/Kamui balances, THEO ISM relayer + nonce + pool USDC, Mezo codehash + `claimBribes` gate, TxFlow balance/pause, USDD PSM `tin/tout/sellEnabled`.

## Limitations

- **Point-in-time.** All reads 2026-10-18; blocks per report (ETH 26,217,382–26,217,925; Base 52,756,147; Mezo 12,589,198; TRON 87,211,072; Arbitrum 515,884,685).
- **Unverified bytecode.** USDD core contracts, Mezo Voter impl, THEO token impl are bytecode-only; selector maps/behavior probes are used, not source. Where source was available (3F WrappedAsset, TxFlow Bridge2, Aragon apps) it was read.
- **Aragon enumeration** covers Kernel-installed apps (the `NewAppProxy` event); non-Kernel/`AppProxyPinned` DAOs without that event would be missed. This is the largest residual gap.
- **THEO sibling routes** could not be exhaustively enumerated (RPC range limits); the registry and deployment-window scan are the evidence.
- **Desk leads** are parked at address/balance resolution + a mechanism read; they are not full audits (especially Zama's FHE verifier and 3F's Morpho oracle layer).
- No transactions were signed or sent; nothing here is an instruction to transact.

## Folder map

```
usdd/                 USDD 2.0 PSM/CDP map + redeem-arb probe
aragon-legacy/        full Aragon Voting-app census + capture test
maker-keepers/        full Flipper + sibling-keeper sweep
mezo-voter/           Voter impl selector map + auth probes
euler-v2/             EVK vault enumeration + anomaly flags
theo-autheo/          Hyperlane warp-route trust root + relayer
3f/  zama/  txflow/  kamui/   located desk leads
exotic-legacy-cluster/  this index + umbrella CI verifier
```
