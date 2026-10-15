# iota-residual — TokenLabs vIOTA (IOTA L1) + Deepr Finance (IOTA EVM)

**Tier-3 deep dive (zombie-hunt II, L2-19 + L2-20) · 2026-10-15 · chains: IOTA Rebased (MoveVM) + IOTA EVM (8822)**
*Status: read-only; no transaction was signed or sent on any network. All PoC/simulation is chain-native read
(JSON-RPC, `iotax_*` event queries, GraphQL indexer) plus local bytecode disassembly; heavy/reproducible checks run in CI.*

---

## 1. TL;DR

| target | live value | unprivileged extractable (E-U) | why closed / open | latent risk |
|---|---|---|---|---|
| **TokenLabs vIOTA** (IOTA L1) | 3,597,964.22 IOTA staked = **$162.6k** (+255.6k IOTA rewards; pooled $174.2k) | **$0 direct** — one conditional path: reward-timing (JIT) ≈ **$24.6/day at 1×TVL capital**, ceiling ≈ **$51/day** (~$18.6k/yr) | full bytecode audit of **both** package versions (v1 + live v2) + framework semantics + 50-day event history: share math floors both ways, no donation path, no ratio manipulation, `rebalance`/`publish_ratio` cannot pay a caller, validator injection fixed in v2 | single EOA holds `OwnerCap`+`OperatorCap`+`UpgradeCap` (ratio inflation ≤1 %/12 h → ~$1.6k/call; arbitrary upgrade). 100 % of TVL in one validator vault; a deactivated validator would brick `stake_pool` |
| **Deepr Finance** (IOTA EVM) | cash **$141.6k** (supplier claims $177.1k) + ~$13.3k DEEPR in reward contracts | **$0** (theoretical dust liquidation bonus **$0.20**) | verified sources of every component: upstream-faithful Compound V2 cToken/Comptroller, owner-only Supra oracle adapter, standard MasterChef RewardPool (one benign quirk disproven), Gnosis-Safe admin, OFT mint endpoint-gated | admin Safe can upgrade the Comptroller implementation → drain market cash; pauseGuardian can pause markets; RewardPool owner can withdraw unemitted DEEPR ($3,970) |

**Total live unprivileged-extractable now: $0** (high confidence). Best-case conditional: TokenLabs
reward-timing, **≈$24.6/day** with capital = 1× TVL (≈$9.0k/yr), **≈$51/day** ceiling with unbounded capital.
No principal or mispricing path was found on either protocol.

## 2. Target 1 — TokenLabs vIOTA (IOTA L1)

Full dossier: `analysis/tokenlabs/DOSSIER.md`. Code: v1 `0xe4abf8b6…`, **live v2 `0x6ab984df…`** (upgrade
2026-02-21); pool `0xb435fa61…`; `cert::Metadata` `0xb45b32d8…` (vIOTA supply). All five modules of both versions
were disassembled with `iota move disassemble` and reviewed.

**Mechanism / state (checkpoint 204,090,375, epoch 528).** `total_staked` 3,597,964,219,313,557 (= Σ 17 vaults
exactly) · `total_rewards` 255,612,938,399,482 · `collected_rewards` 0 · `pending` 0 · `paused` false ·
vIOTA supply 3,590,070,089,452,751 · **1 vIOTA = 1.073398864561 IOTA** (verified to 11 dp against real
StakedEvents) · `validator_cap_base` 4 M IOTA · 17 validators (100/25×3/8×9/5×4), **all TVL in one vault**,
0 bad validators · daily 09:00 UTC `update_rewards`+`collect_fee_new` cron, fee 0.99 % ≈ 11.27 IOTA/day.

**Attack paths (all quantified in the dossier).** A1–A8, A10, A12–A13 closed (round-trip rounding favours the
pool; no donation path into `pending`; `ratio` is derived from live state with a solvency abort; `rebalance`
today reverts — no bad validators — and cannot pay a caller; `publish_ratio` is event-only and has never been
called; v2 removed the v1 permissionless-validator path and added per-validator total caps). **A11 (open,
conditional):** rewards are credited in one daily instant while accruing continuously, so an attacker staked
across the 09:00 UTC cron captures a full day's accrual with minutes of exposure — `P = X/(T+X)·R·(1−0.0099)`
with `R ≈ 1,138.6 IOTA/day` measured from 50 days of `FeeCollectedEvent`s. **A9 (privileged):** the single EOA
`0x5555…b54ae7c` can raise `total_rewards` by ≤1 %/12 h and unstake at the inflated ratio (~$1.6k/call), and
holds the `UpgradeCap`.

## 3. Target 2 — Deepr Finance (IOTA EVM)

Full dossier: `analysis/deepr/DOSSIER.md`. Unitroller `0xee0712…` → Comptroller `0x4B13e770…`; shared cToken
delegate `0x9d2Cc610…`; markets dWETH `0x0f571c5f…`, dWIOTA `0x26081758…`, dUSDC.e `0xf96adbfc…`, dDeepr
`0x5041af7b…` (deprecated, paused, 0 shares); oracle `0x580bef00…` (`SupraPriceOracleAdapter`); RewardPool
`0x18041c94…`; DEEPR `0x4Eb8E034…`; admin = **Gnosis Safe** `0x84456E99…`.

**State (block 13,020,635).** cash: 34.7098 WETH ($82.1k) + 876,552.30 IOTA ($39.7k) + 19,768.67 USDC ($19.8k)
= **$141,606**; borrows $35,800; reserves $330; supplier claims $177,075. DEEPR ($0.00006877): Comptroller holds
65.96 M ($4,536) for lender rewards; RewardPool holds 62.69 M staked + 7.00 M locked + 57.73 M unemitted. All
contracts verified; the deployed `CToken.sol` was diffed against upstream `compound-finance/compound-protocol`
and matches line-for-line (timestamp-based interest only). 184 borrowers scanned: the largest ($11.1k debt) is
healthy; 28 dust positions are underwater with a **total shortfall of $0.87** and total debt $4.94 → max
liquidation bonus **$0.20**, below gas.

**One quirk, disproven:** `RewardPool.withdrawRequestAndHarvest()` zeroes `rewardDebt` (typo-style formula) but
also zeroes `stakedAmount` in the same call and blocks re-deposits until the 7-day request completes, so no
double-claim is possible; a *correct* debt would instead make later `harvest()` calls revert.

## 4. PoC / verification

* **TokenLabs**: bytecode disassembly v1/v2 with a full v1→v2 diff (`np_diff.txt`, `vs_diff.txt`); framework
  semantics quoted from `iotaledger/iota` source; live ratio independently reproduced from real event outcomes;
  vault sum == `total_staked`; `bad_validators == []`. Unprivileged callability is proven by production history
  (many distinct unprivileged senders stake/unstake daily; last unstake paid 3,498.10 IOTA in the same tx).
* **Deepr**: verified-source review + upstream diff; live market/borrower state; selector inventories of the
  deployed delegate and Comptroller (`selector_scan.txt`); oracle/Supra feed read at block time; CI runs
  `ci/verify_live.py` (both chains, keyless RPCs) and a Foundry IOTA-EVM fork smoke test.
* **CI (public repo `artsbykriss/ca-zombie-ci`)**: two validated runs —
  https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38707924869 (first validation) and
  https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38712671531 (final; live-state JSON artifact +
  Foundry IOTA-EVM fork smoke test, 1/1 PASS, block 13,020,xxx).

## 5. Verdict and residual risk

| category | TokenLabs | Deepr | total |
|---|---|---|---|
| E-U direct | $0 | $0 | **$0** |
| E-U conditional | ≈$24.6/day (1×TVL capital); ≈$51/day ceiling | $0.20 dust (not worth gas) | ≈$24.6/day |
| H-O (self-service) | 3,853,577 IOTA pooled ≈ $174.2k (instant, uncapped) | $141.6k cash now; $177.1k claims; $13.3k DEEPR claims | ≈$329k |
| P (privileged) | ratio inflation ≤1 %/12 h + full upgrade authority (one EOA) | Comptroller upgrade → $141.6k; reserves $330; RewardPool rewards $3,970 (Gnosis Safe) | ≈$146k |
| S (stuck) | none | 2 DEEPR (~$0.0001) in the deprecated market | ~$0 |

**Blockers / what would change the verdict:** (TokenLabs) any future package upgrade re-opens the audit — v2's
`validator_cap_base` delta is unaudited; the operator's reward feed is an off-chain number; a deactivated
validator in the set would DoS `stake_pool`. (Deepr) any Comptroller implementation change; a Supra feed
compromise; thin DEEPR pricing. Neither protocol has an unprivileged path to principal today.

## 6. Methodology & sources

Keyless public endpoints only: `https://api.mainnet.iota.cafe` (Sui-style JSON-RPC + `iotax_*`),
`https://graphql.mainnet.iota.cafe`, `https://rpc.ankr.com/iota_evm`, `https://8822.rpc.thirdweb.com`,
`https://explorer.evm.iota.org` (Blockscout verified sources), `iotaledger/iota` framework source, MoveBit audit
(2026-01-14, v1 scope), DefiLlama/CoinGecko prices (IOTA $0.0452 on 2026-10-15; Deepr markets priced with the
protocol's own Supra feed: WETH $2,366.43 / IOTA $0.0453 / USDC $0.99982). No keys, no secrets, no writes to
any chain.

**Caveats.** (1) Deepr's Comptroller source was reviewed as published verified source, not byte-for-byte
recompiled against the deployment; (2) the TokenLabs JIT figure depends on the operator keeping the daily cron
and on attacker timing; (3) the v2 TokenLabs delta is unaudited by a third party; (4) IOTA price moved from the
corpus's $0.0603 to ~$0.0452, so corpus USD figures are overstated ~25 %.

## 7. Files index

`README.md` · `summary.json` · `analysis/tokenlabs/` (DOSSIER.md, FINDINGS.md, disasm{,_v2}/, bytecode{,_v2}/,
pkg_abi*.txt, np_diff.txt, vs_diff.txt, framework/, framework_lead/, live/, events/, audit PDF + excerpts) ·
`analysis/deepr/` (DOSSIER.md, market_state.json, deep_state_*.txt, borrowers_health.json, src/deepr/,
src/full/, src/*.json, selector_scan.txt, scripts) · `ci/` (run.sh, verify_live.py) · `ci-out/live_state.json` ·
`poc/` (Foundry project: IOTA-EVM fork smoke test) · `ci-log.txt`, `ci-artifacts/`.
