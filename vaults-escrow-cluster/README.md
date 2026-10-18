# ZOMBIE-HUNT IV — Wave B2, group 5: vaults / escrow / order cluster

**Date:** 2026-10-18 · **Mode:** read-only; fork/sandbox verification only; **no mainnet transactions,
no signing, no secrets**. Per-target folders are at the workspace root; this folder is the index +
the combined EVM Foundry project/CI.

## Verdict table

| # | Target | Chain(s) | DL claim | Real on-chain value | **E-U** | Confidence | Verdict |
|---|---|---|---:|---:|---:|---|---|
| 13 | [**cVault Finance**](../cvault/README.md) | Ethereum | $6.33M | $6.33M notional, **$213.6k H-O** | **$0** | High | rLP holds 99.97% of the DELTA/WETH SLP with no unwrap; rebase hard-reverts; ERC95 wrappers 1:1 backed; CoreVault CORE rewards are holder-owned |
| 14 | [**OTSea**](../otsea/README.md) | ETH, Base, Blast | $582k | **≈$7k escrow** | **$0** | High | order state machine party-bound; DL sums the ETH *ask* of open sell orders, not escrow |
| 29a | [**Jupiter Offerbook**](../jupiter-offerbook/README.md) | Solana | $1.29M | $1.34M | **$0** | High (tested) / Medium overall | every withdraw/cancel/fill/claim path bound to owner/creator/lender; 9/9 probes blocked |
| 29b | [**PiggyBank**](../piggybank/README.md) | Solana | $1.71M | $1.74M managed | **$0** | High | 0.943/0.951 NAV is real; deposit/redeem share one denominator; same-epoch round trip loses 1 raw unit |
| 29c | [**TONCO V2**](../tonco-v2/README.md) | TON | $2.50M | $2.41M | **$0** | High | PAY_TO exit 111; live-pool re-init exit 82; fake notify reaches only a sender-derived pool |
| 29d | [**Extended**](../extended-starknet/README.md) | Starknet | $115.4M perps / $2.74M spot | $115.46M treasury | **$0** | Medium | live class is `0x2009d`, not the docs' `0x055ca`; operator/signature gated; DL Spot overlaps Perps |

**Total live unprivileged extraction across the six deployments: $0.00.**
(All six are negative results; none is a proof of absence. Residual/conditional paths are listed per
target; the only sizeable latent risks are privileged.)

## What changed in the campaign's picture

1. **OTSea's $582k is a DefiLlama adapter bug, not an escrow balance.** `projects/otsea/index.js` does
   `api.add(nullAddress, totalOutput - outputTransacted)` for open **sell** orders — that is the ETH the
   seller is *asking*, which no one has deposited. Ask sums: 187.60 ETH ($451.8k) on Ethereum +
   49.75 ETH ($119.8k) on Base = the reported $582k. Actual contract balances: 0.000989 ETH and
   0.00000877 ETH; the real token escrow is ~$0.7k + ~$6.3k, and most of it has no pool depth.
2. **cVault's $6.33M is a permanently locked SLP.** 82,630 of 82,651 DELTA/WETH SLP sits in rLP; the
   implementation has no redeem path, `rebase()` reverts, and migration is multisig-only. The WETH leg
   (~$3.06M) is only recoverable through a proxy upgrade by EOA `0x5A16…5436`; the DELTA leg has no
   exit. Only $213.6k (coreDAI + cBTC + CoreVault unclaimed CORE) is genuinely holder-owned.
3. **Extended's "Spot $2.74M" is not additive to Perps.** Both are claims on the same
   $115.46M treasury; the on-chain spot-eligible subset (USDT/ETH/WBTC) is $5.29M.
4. **Jupiter Offerbook / PiggyBank / TONCO V2 look genuinely closed** at the tested depth: the
   Offerbook's 9 value paths are party-bound; PiggyBank's NAV anomaly is a real loss rather than a
   mispricing; TONCO's payout and re-init messages are sender-authenticated.

## Category totals (non-additive — P overlaps H-O custody)

| Category | USD | Notes |
|---|---:|---|
| **E-U** | **$0** | headline |
| H-O | ≈$3,296,854 | cVault $213,614 + OTSea $7,020 + Offerbook $1,340,591 + PiggyBank $1,735,629 |
| P | ≈$124.0M | privileged/upgrade/operator control of the same assets (incl. Extended treasury $115.46M) |
| S | ≈$3.12M | locked DELTA leg (~$3.06M) + PiggyBank unclaimed redemptions $58,310 (Extended DL overlap is a data-quality note, not stuck funds) |

## PoC / CI

Combined Foundry project (EVM targets only): [`poc/`](poc/) — `CVaultFork.t.sol` (6 tests) and
`OTSeaFork.t.sol` (4 tests). Non-EVM targets used `@ton/sandbox` TVM emulation and Solana
`simulateTransaction`; no Foundry equivalent applies.

* CI run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39109321420**
* Result: see `ci-log.txt` / `ci-artifacts/` after the run (test count recorded in `summary.json`).

## Folder map

```
cvault/              README, summary.json, analysis/ (impl sources + state dump), poc/ pointer
otsea/               README, summary.json, analysis/ (order scans/prices), poc/ pointer
jupiter-offerbook/   README, summary.json, analysis/evidence/ (IDL, state, simulations)
piggybank/           README, summary.json, analysis/evidence/ (layouts, NAV, simulations)
tonco-v2/            README, summary.json, analysis/ (state, TVL, sandbox tests)
extended-starknet/   README, summary.json, analysis/ (class diff, entrypoints, treasury)
vaults-escrow-cluster/
  README.md          this index
  summary.json       aggregate
  poc/               combined Foundry project used by CI
  ci-out/, ci-log.txt, ci-artifacts/
  analysis/          shared Solana tooling + original combined findings documents
```

## Caveats

* DL numbers are as of 2026-10-16..18; per-target READMEs state the exact block/slot and price source.
* cVault/DFV and the Extended Core are upgradeable; PiggyBank and Offerbook are upgradeable by a
  single key / Squads multisig. Those are P risks, not E-U.
* Memecoin escrow and collateral are marked at spot; realizable value is lower and was not added to
  the headline.
