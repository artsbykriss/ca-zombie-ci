# ApeX Omni (zkLink X custody) — ZH4 pass3-recon OPEN #10

**Date:** 2026-10-23 · **Chains:** Ethereum, BNB Chain, Arbitrum, Base, Mantle
**Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or sent**; no secrets in this folder.

**Verdict:** external-unprivileged extractable = **$0** (high confidence). The ~$30.28M ApeX Omni
custody sits in zkLink X `ZkLink`/`ZkLinkPeriphery` contracts; every value-moving entry point is
either permissionless-but-not-profitable or gated by `onlyValidator` / `onlyGovernor` / `requireMaster`
with SNARK-verified state transitions. The only material risk is **privileged** (P): the governor
Gnosis Safe (threshold 4) can upgrade the implementation with **0 s** notice.

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent / residual risk |
|---|---|---|---|
| ApeX Omni custody (5 chains) | **$0** | Withdrawals require `onlyValidator` + a SNARK-verified block; no ungated value-out path | **P**: `UPGRADE_NOTICE_PERIOD = 0` — governor Safe (4-of-N) can swap the impl and move $30.28M instantly (L2BEAT CRITICAL) |

**Total live extractable now: $0** (confidence: **high**).
**Total custody at risk from the privileged upgrade key: $30,282,912** (P category).

## 2. What it is / the mechanism in exact terms

ApeX Omni is a hybrid orderbook perp DEX: matching is off-chain, settlement is on **zkLink X**
(an application-specific zk-rollup). DefiLlama's `apex-omni` TVL (`registries/sumTokens.js` →
`"apex-omni"`) sums a token list held by **one owner per chain** — the zkLink contract ApeX deploys
on each L1 (ApeX's own force-withdrawal docs list exactly these addresses). The custody contract is
a Matter Labs `Proxy` whose implementation is `ZkLink` and whose fallback delegatecalls
`ZkLinkPeriphery` (a "split contract"). Withdrawal processing happens in
`executeCompressedBlocks` (slaver chains) / `executeBlocks` (master chain), both `onlyValidator`;
the block must have been committed by a validator and its state proven (master chain verifies
`verifyAggregatedBlockProof`; slavers receive the sync hash from a governor-set SyncService).

## 3. Live-state assessment (2026-10-23, keyless public RPCs)

| Chain | custody proxy | block | impl `getTarget()` | master (gatekeeper) | governor (Safe) | exodus | notice (s) | custody USD |
|---|---|---|---:|---|---|---:|---:|---:|
| Ethereum | `0x35D173cdfE4d484BC5985fDa55FABad5892c7B82` | 26,253,751 | `0xa9b4ab2e…` | `0xfbd68679…` | `0xf9f8794a…` (thr 4) | false | **0** | $17,326,489 |
| BNB | `0xb8d9f005654b7b127b34dae8f973ba729ca3a2d9` | 129,279,796 | `0x3ec0ad30…` | `0x81dee5b8…` | `0xba3852ea…` | false | **0** | $2,857,235 |
| Arbitrum | `0x3169844a120c0f517b4eb4a750c08d8518c8466a` | 517,465,859 | `0x23871561…` | `0x2e8ad143…` | `0xba3852ea…` | false | **0** | $5,680,282 |
| Base | `0xee7981c4642de8d19aed11da3bac59277dfd59d7` | 52,975,103 | `0xd923b647…` | `0x72343e8e…` | `0xba3852ea…` | false | **0** | $3,215,053 |
| Mantle | `0x3c7c0ebfcd5786ef48df5ed127cddeb806db976c` | 102,304,622 | `0x067c7126…` | `0x2b9ba259…` | `0xba3852ea…` | false | **0** | $1,203,854 |
| **Total** | | | | | | | | **$30,282,912** |

Per-token balances, prices and exact block numbers: `analysis/live-state-2026-10-23.json`.
Ethereum alone holds 10,095,379 USDT + 2,897,803 USDC + 1,541.5 ETH + 3.70 WBTC + 4.12 cbBTC.
Arbitrum is the zkLink **master chain** (`CHAIN_ID == MASTER_CHAIN_ID == 9`,
`totalBlocksProven == totalBlocksExecuted == totalBlocksSynchronized == 211,104`).

## 4. What an attacker can / cannot do (exact call paths)

**Cannot (proven by fork test, 14/14 PASS):**
* `executeCompressedBlocks(...)` / `commitCompressedBlocks(...)` as a non-validator → revert `"4"`.
* `upgradeTarget(...)` / `transferMastership(...)` as a non-master → revert `"1c"`.
* `initialize(bytes)` on the proxy → revert `"ini11"` (proxy intercepts re-init).
* `changeGovernor` / `setValidator` / `setGateway` / `addToken` as a non-governor → revert `"3"`.
* `withdrawPendingBalance(attacker, tokenId, n)` with 0 pending balance → arithmetic underflow revert.
* `acceptERC20(...)` without paying the receiver first → `safeTransferFrom` revert.

**Can (but yields nothing):**
* `withdrawPendingBalance(victim, tokenId, amount)` — permissionless, but the payout goes to
  **victim** and only victim's pending balance is debited → forced-withdrawal griefing, no theft.
* `acceptETH` / `acceptERC20` — permissionless acceptor role, but the caller must pay the receiver
  up-front; net = the fast-withdraw fee only.
* `proveBlocks(...)` (Arbitrum master) — permissionless but requires a valid SNARK proof and does not
  itself move funds.
* `activateExodusMode()` — permissionless but only flips when a priority request is >14 days expired
  (verified: attacker call left `exodusMode == false`).

**Privileged (P) — not available to an unprivileged attacker:**
* Upgrade: `UpgradeGatekeeper.startUpgrade` → (`noticePeriod = 0`) → `finishUpgrade` →
  `Proxy.upgradeTarget`. Callable only by the gatekeeper's master = the networkGovernor Gnosis Safe
  (threshold 4). A single Safe transaction set can replace the implementation and move all $30.28M.

## 5. PoC / fork verification

* `poc/test/ApexOmniZkLink.t.sol` — 14 tests, **14/14 PASS** on an Ethereum fork
  (`vm.createSelectFork(FORK_RPC_URL)`), read-only `eth_call`s.
* Key assertions: non-validator/non-master/non-governor calls revert with the exact deployed reason
  strings; permissionless withdrawal paths cannot redirect funds to the caller.
* `ci/run.sh` — re-reads live custody balances + roles across all 5 chains (keyless RPCs) and prices
  them via DefiLlama → `ci-out/apex-omni-live.json`.
* CI run URL(s): see `ci-log.txt` / the orchestrator summary (GitHub Actions on
  `artsbykriss/ca-zombie-ci`, branch `apex-omni`).

## 6. Verdict & residual risk

* **E-U = $0 (high).** No unprivileged value path exists; the withdrawal primitive is
  validator-gated and SNARK-bound. Apex has no known loss-of-funds incident since 2022.
* **H-O = $0** (users can always self-withdraw via `withdrawPendingBalance`/force-exit).
* **P = $30,282,912.** The upgrade path has **0 s** delay; the trust anchor is a governor Safe
  (threshold 4). This is the documented L2BEAT "CRITICAL" zkLink upgrade risk.
* **S = $0.**
* Blockers to a stronger claim: the SNARK verifier/circuit soundness and the Safe signer set were
  not (and cannot be) adversarially tested; both are outside unprivileged reach.

## 7. Methodology & sources; caveats

* DefiLlama `registries/sumTokens.js` `"apex-omni"` (owner addresses + token list); ApeX Omni
  force-withdrawal docs (address↔chainId table matches on-chain `CHAIN_ID`); L2BEAT zkLink rating.
* Etherscan V2 verified source: `ZkLink`, `ZkLinkPeriphery`, `ZkLinkAcceptor`, `Proxy`,
  `UpgradeGatekeeper` (Ethereum + Arbitrum).
* Live reads: keyless public RPCs (`ethereum/bsc/arbitrum-one/base.publicnode.com`, `rpc.mantle.xyz`).
* **Caveats:** (1) The DefiLlama attribution assumes the whole zkLink-X instance balance is ApeX
  Omni's; ApeX docs confirm these are ApeX-deployed contracts, so the attribution is sound, but if a
  third party also deposits into the same zkLink-X instance the ApeX-specific share could be lower.
  (2) USD values use DefiLlama spot prices at capture time. (3) The master-chain (Arbitrum) contract
  runs a slightly older zkLink version (`commitBlocks`/`executeBlocks`, `proveBlocks`) — audited too,
  same gating.
* **Not a false positive:** the 2026-09-28 NEAR Intents $3.8M "Omni infrastructure" incident is a
  different protocol (NEAR's own Omni), unrelated to ApeX Omni.

## 8. Files

```
apex-omni/
├── README.md                       this file
├── summary.json                    machine-readable verdict
├── analysis/live-state-2026-10-23.json   per-chain balances, prices, roles, blocks
├── analysis/roles-and-auth.md            deployed code + access-control audit
├── poc/{foundry.toml,src/IZkLink.sol,test/ApexOmniZkLink.t.sol,lib/forge-std}
├── ci/run.sh                       live re-capture job (keyless)
├── ci-out/                         CI artifacts (apex-omni-live.json)
└── ci-log.txt                      CI log
```
