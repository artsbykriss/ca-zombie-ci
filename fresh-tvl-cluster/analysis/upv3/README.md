# Z3-H17 · up v3 (Robinhood Chain, chain id 4663) — Slipstream v2 fork-drift deep dive

**Date:** 2026-10-16 · **Chain:** Robinhood Chain (4663) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** CLFactory `0x1ac9dB4a2608ba45D6127B1737949b51Bb54B7F3` (1,923 pools) · CLPool impl `0x11725976BF1F38c4aB78d1F480bc5883d70D9dc3` · NonfungiblePositionManager `0x07F44c47743A2f36414A82b9F558ECFCf0EEdCEf` · Voter `0x7F749fDD351C1Ceed82d76d7699CB631Eb8332a7` (cap-mode generation) · veUP `0x5d321dE36F0bf98D92b291280514F3878582B7B6` · CLGaugeFactory `0x6Bdf3B9A782c28D6259356d0Cb7Ae22Ab1368863` · gauge impl `0xb6eEC6dCeEFA7063b130211e1d5e7E15ADCfcCad` · DynamicSwapFeeModule `0xa8Bdc945bE050E451C97f935d7c0D6B0087cF94c` · CustomUnstakedFeeModule `0xbb7A7015fD9744dF83d688D5C71C9efE613b976d` · FactoryRegistry `0xbBb4FbD1e6Dbb39CAF24D724132876cAC1a53C8E`
**Method:** verified-source fetch (Etherscan V2 chainid 4663), bytecode-identity compile-checks against the upstream repos, full live enumeration (1,923 pools, 91 gauges), 9 fork tests on live state, and reconciliation with the published Shieldify security review of "Up" (acknowledged M-01/M-02/M-03).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| CLPool core (mint / burn / collect / swap / flash / stake / collectFees) | **$0** | deployed code **byte-identical** (metadata-stripped) to `aerodrome-finance/slipstream` main `CLPool.sol`; every value-moving path is `msg.sender`-scoped or `onlyGauge`/`onlyNftManager`/`onlyGaugeFactory`; fork-proven: foreign `collect(…,owner)` reverts `NNFT`, flash without repayment reverts `F0`, flash with exact repayment leaves the attacker with **0** and the pool with exactly the 1% fee | none found |
| NonfungiblePositionManager (positions) | **$0** | deployed source == upstream `NonfungiblePositionManager.sol` (diff empty); `collect`/`decreaseLiquidity`/`burn` gated by `isAuthorizedForToken`; fork-proven foreign `collect` reverts | `refundETH()`/`sweepToken()` are permissionless (canonical UniV3 behavior) → only ETH/token **parks** are claimable; NPM ETH balance = 0 today → **E-U-conditional monitor** |
| CLGauge (91 gauges, 870,817 UP ≈ $241.9k held) | **$0** | deployed gauge is the pre-penalty Slipstream CLGauge generation (unverified impl; ~8-byte dependency delta vs 2024-04-30 commit, same selector set/strings); `withdraw`/`getReward` require `_stakes[msg.sender]`, `deposit` requires NFT ownership — fork-proven all three revert `NA` for a fresh caller | none while the gauge impl stays; gauge impl is upgrade-free (clone master) |
| DynamicSwapFeeModule / CustomUnstakedFeeModule | **$0** | byte-identical to upstream (fee module = immutable factory); all setters `onlySwapFeeManager` / `onlyUnstakedFeeManager` = Safe `0x0eEA…DFd8` | fee settings are P-class; caps ≤10% swap / ≤50% unstaked enforced |
| Voter (cap-mode generation, unverified) | **$0 direct** | matches the Shieldify-audited `up-contracts` lineage (`capMode/queueCapMode/settleExpiredEpochs/expiredIndexFloor`). `initialize` re-call reverts; claim paths are owner/approved-gated in the audited code | **M-01 (ack.)**: permissionless `poke()` zeroes a decayed-lock veNFT's current-epoch checkpoints → grief/redistribution, no caller payout. **M-03 (ack.)**: front-run window if governance queues a cap-mode flip (none pending today: `capMode==pendingCapMode==2 Enforced`). **M-02 (ack.)**: privileged invalidate → fail-open caps |
| Factory / Registry (owner = Safe `0x0eEA…DFd8`, 2-of-4) | **$0** | all admin setters owner/manager-gated; `setGaugeAndPositionManager` only callable by the registry-linked gauge factory; `createPool` permissionless but atomically initializes | P-class: fee managers, tick-spacing fees, swap hooks |

**Total live E-U extractable now: $0.00 — confidence high** (fork-proven negatives + byte-identity of the core; the only acknowledged unprivileged class is M-01 griefing whose *caller* gains no direct payout).
TVL sits where it should: **$4,693,965 priced across 1,923 pools (LP principal, H-O)** vs DefiLlama $4.72M — top pools: WETH/UP $1.06M · UP/STONKBROKER $589k · WETH/YARD $320k · USDG/NET $292k · WETH/USDG $215k.
Main state reads at `eth_blockNumber = 89,759,182`; fork tests at header block 26,202,692 (the chain's Foundry header space differs from `eth_blockNumber`; both cited).

## 2. The mechanism, in exact terms (what is actually deployed)

up v3 is **Aerodrome Slipstream v2** (`aerodrome-finance/slipstream`, Dromos Labs) deployed on Robinhood Chain in July 2026, with the **2026 "cap-mode" Voter** from the audited `up-contracts` repo and a slightly older (2024-generation) CLGauge/gauge-factory pair:

1. **Core is canonical.** CLPool impl byte-identical to `slipstream` main `contracts/core/CLPool.sol` (compiled, metadata stripped: 24,226 == 24,226 bytes, `equal=True`); factory getters match the repo ABI minus `legacyCLFactory` (removed upstream-of-deployment) and `enableTickSpacing(100, 1_000)` replacing upstream's `(100,500)`.
   - `mint` pulls payment via `uniswapV3MintCallback(msg.sender)` + balance check `M0/M1`; `collect(recipient, …, owner)` (6-arg) is `onlyNftManager`; the 5-arg `collect` uses `owner = msg.sender`; `burn` (3-arg) uses `owner = msg.sender`, (4-arg) is `onlyNftManager`; `stake`/`collectFees`/`syncReward`/`updateRewardsGrowthGlobal` are `onlyGauge`; `setGaugeAndPositionManager` is `onlyGaugeFactory` (registry `factoriesToPoolFactory(factory).gaugeFactory`) and one-shot (`require(gauge == 0)`); `swap`/`flash` callbacks target `msg.sender` with before/after balance enforcement (`IIA`, `F0/F1`).
   - `collectFees()` pays the gauge (msg.sender) `gaugeFees − 1 wei`, zeroing to 1 wei (both the deployed/Etherscan variant and the repo variant are semantically identical; the deployed binary matches the repo compile).
2. **Periphery is canonical.** NPM source == upstream repo source; supports staked positions (ownerOf == gauge path); hashes/immutables are the deployment's.
3. **Fee modules are canonical.** Deployed `swapFeeModule` == `DynamicSwapFeeModule` (byte-identical modulo the immutable factory); its `getFee` is a pure view of `dynamicFeeConfig`/oracle-observations with caps (base ≤3%, cap ≤5%, discount ≤50%); every setter is `onlySwapFeeManager`. Deployed `unstakedFeeModule` == `CustomUnstakedFeeModule` (≤50%, setter `onlyUnstakedFeeManager`). Both managers are the protocol Safe.
4. **Gauge pair is the 2024 generation.** Gauge factory byte-identical to slipstream commit `f6a694b6d9` (2024-04-30) modulo the immutable voter; `createGauge` is `require(msg.sender == voter)`; `setNonfungiblePositionManager` was owner-once (now `nft != 0` → closed). Gauge impl = that generation's CLGauge (same 34-function dispatch table; lacks `depositTimestamp/minter/rewardsByEpoch` i.e. pre-penalty; ~8-byte dependency-level delta) — semantics: `withdraw`/`getReward(uint256)` require `_stakes[msg.sender].contains(tokenId)`, `deposit` requires `nft.ownerOf == msg.sender` + pool match + `voter.isAlive`, `getReward(address)` is voter-only.
5. **Voter = audited cap-mode generation.** Etherscan-unverified, but its exact function surface (83 selectors) matches the Shieldify-reviewed `up-contracts` `Voter.sol`/`GaugeCapController.sol` (see §6). Live: `capMode = 2 (Enforced)`, `pendingCapMode = 2`, `activeCapEpoch = 1,792,022,400`, `liveAccountedReserve = epochReserve = 1.371e25 UP` (the voter holds the emission reserve it burns per enforced epoch), `totalWeight = 4.316e25`, `gaugeCapController = 0x5739B0FcF359DF7a386C0fDD27464Dd15eE1687D`, `governor = epochGovernor = emergencyCouncil = Safe 0x0eEA30aB…`.

## 3. Live-state assessment (2026-10-16)

- **Factory** `0x1ac9dB4a…`: `owner()` = Safe `0x0eEA30aBa3f07abFA20E4b544F55e0f917d9DFd8` (345-byte Safe proxy; 2-of-4 per prior screening), `allPoolsLength() = 1,923`, `poolImplementation() = 0x11725976…`, `voter() = 0x7F749fDD…`, `factoryRegistry() = 0xbBb4FbD1…`, `swapFeeManager() == unstakedFeeManager() == Safe`, `swapFeeModule() = 0xa8Bdc9…`, `unstakedFeeModule() = 0xbb7A70…`, `defaultUnstakedFee() = 100,000` (10%).
- **Pool set:** 1,923 pools, 1,295 with liquidity > 0, 91 with a gauge, 76 with `stakedLiquidity > 0`. Priced TVL **$4,693,965**; 1,673 pool-legs hold unpriced memecoins (dust-scale; DefiLlama's $4.72M ≈ our priced total, so unpriced value is small). Full ranking: `analysis/upv3/upv3_rank.json`, pool state: `upv3_pool_state.json`.
- **NPM** `0x07F44c47…`: `owner() = Safe`, `symbol() = "UP-POS"`, ETH balance = 0; positions exist (tokenId 1 exists; owner `0x85Fb…651` in the fork read). No token parks observed in the NPM's own balance paths used by tests.
- **Gauges:** 91 live; **870,817 UP (≈$241.9k)** of pending emissions held across them (84 nonzero), e.g. pool-0 gauge `0x34e626Ec…` holds 101,237.9e18 UP with `rewardRate = 1.860e17/s`, `periodFinish = 1,792,627,200`.
- **Voter fee pots (FeeVotingReward contracts, `gaugeToFees(gauge)`):** **$167,190.96** in priced tokens across 145 nonzero legs (largest single: 4.9457 WETH ≈ $12.0k in the WETH/UP gauge's fee pot) + 8 unpriced memecoin legs of 2.948e18 each. These pots are veUP-voter income, claimed via owner/approved-gated paths.
- **Registry** `0xbBb4FbD1…`: `owner() = Safe`, `isPoolFactoryApproved(upv3 factory) = true`, `factoriesToPoolFactory(factory) = (0xD1817021…, 0x6Bdf3B9A…)`.
- **veUP** `0x5d321dE3…`: `totalSupply/bTotalSupply` scale ~4.3e25 weight; UP `totalSupply = 5.171e26`, voter holds 1.371e25 (2.65%).

## 4. What an attacker can / cannot do (exact paths)

**Cannot (all fork-proven negatives, 0x-ethereum 2026-10-16):**
- `gauge.withdraw(1)` / `gauge.getReward(1)` / `gauge.deposit(1)` as `0xA11CE` → revert `NA` (T2).
- `NPM.collect({tokenId: 1, recipient: attacker, …})` with someone else's position → revert (T3; `isAuthorizedForToken`).
- `pool.collect(recipient, tl, tu, a0, a1, owner)` (6-arg) as a non-NFT-manager → revert `NNFT` (T4).
- `pool.flash(recipient, a0, a1, "")` without repayment → revert `F0` (T5).
- `voter.initialize([], attacker)` → revert (T7).
- Extract anything from another pool's principal: pool positions are keyed by owner; the NPM path is `onlyNftManager`; there is **no skim**; direct token transfers into a pool are stuck (S).

**Can (all zero-gain):**
- Pay the flash fee and do a same-tx round trip: exact-fee repayment ⇒ pool balance **+1e13 CASHCAT = the 1% fee** and attacker delta 0 (T6).
- `voter.poke(tokenId)` for **any** tokenId after the epoch's vote window: fork-proven on a live zero-weight veNFT (id 16). Per the Shieldify review (M-01), a zero-weight token takes the `_reset` branch, overwriting current-epoch Reward checkpoints → the victim's unclaimed current-epoch fees/bribes are redistributed pro-rata to the *other* depositors of that Reward contract. The **caller receives nothing directly**; monetisation requires the attacker to also be a depositor in that Reward (veUP stake), in which case their gain = their share × victim's forfeited share.
- `npm.refundETH()` / `sweepToken()` are permissionless (canonical), but the NPM holds 0 ETH and no parked tokens; this re-arms only via force-send/mis-route → monitor.

## 5. PoC / fork verification

- Project: `poc/` (Foundry, solc 0.8.26); file `poc/test/UpV3.t.sol` (`UpV3H17Test is ForkHelper`), 9 tests, **9/9 PASS** locally against live state (fork RPC `rpc.mainnet.chain.robinhood.com`, header block 26,202,692).
- Key numbers: gauge/NPM/pool unauthorized calls → `NA` / revert / `NNFT`; flash no-repay → `F0`; flash repay → pool `+10,000,000,000,000` (1% of 1e15 CASHCAT), attacker +0; `capMode = 2`, `pendingCapMode = 2`; M-01 probe: first zero-weight live veNFT = id **16**, `poke(16)` by a fresh address → **success** (permissionless), feeVotingReward `0xcf17e363…`; NPM ETH = 0.
- Note: the parent's `poc/src/ForkHelper.sol` currently does not compile with the vendored forge-std (re-declares `VM_ADDRESS`, already defined in `lib/forge-std/src/Base.sol`). Local verification used an identical-semantics patched copy in a scratch project; the delivered test imports `ForkHelper` as specified. The parent must remove/rename that constant before CI.

## 6. Third-party review reconciliation (Shieldify, `Up-Security-Review.md`)

The published review of **Up** (`prompter-byte/up-contracts` @`1e5ebbce`, `up-slipstream` @`647f5990`) reports 3 Medium + 3 Low + 4 Info, all acknowledged except I-04 (fixed). E-U relevance:
- **M-01** permissionless `poke()` zeroing decayed-lock veNFT checkpoints — live trigger fork-proven (id 16); caller gains nothing directly (griefing/redistribution).
- **M-03** enforced-mode cap bypass via permissionless `updateFor` — **precondition not live**: a queued mode switch must be pending; today `pendingCapMode == capMode == 2 (Enforced)`, `pendingCapModeEpoch = 0`. Re-arms on any `queueCapMode` governance action.
- **M-02** invalidating a locked report → fail-open uncapped emissions — requires the privileged invalidator (governor/emergencyCouncil = Safe). P-class.
- **L-02** `expiredIndexFloor` strands emission shares — in `Enforced` mode the reserve is still burned (accounting inconsistency, no fund loss); in Disabled/ObserveOnly modes it would strand UP inside the Voter (S-class). Currently Enforced.
- **I-01** no upper bound on emission multiplier (P).

## 7. Verdict and residual/latent risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** Core, periphery, fee modules and gauge generation are byte-identical to audited upstreams; every value path is scoped; fork-proven negatives.
- **E-U-conditional:** (a) the old `poke()` grief/redistribute path (M-01, acknowledged; value = victim's current-epoch Reward share, redistributed pro-rata; attacker needs an existing veUP stake to monetise); (b) `updateFor` cap-mode bypass if/when governance queues a mode change (M-03). Monitor: `pendingCapMode != capMode` and `poke()` calls on zero-weight tokens.
- **H-O:** LP principal **$4.69M** + gauge-held emissions **$241.9k** (self-service withdraw/claim).
- **P:** voter fee pots **$167.2k** (veUP voters), factory/registry/gauge-admin setters, Safe 2-of-4 and module hooks.
- **S:** donor transfers into pools (no skim); sub-unit dust; NPM parks (0 today).
- Caveats: Etherscan sources for factory/NPM/pool are *SimilarMatch* (superseded by byte-identity checks); Voter/gauge-impl unverified on-explorer; voter source taken from the audited repo + live selector/semantics match, not byte-verified; prices are point-in-time DefiLlama; the chain's header block space differs from `eth_blockNumber` (both cited).

## 8. Methodology & sources

Read-only throughout: `cast call/code/storage`, Etherscan V2 (`chainid=4663`), keyless public RPCs, DefiLlama price API, GitHub upstream repos (`aerodrome-finance/slipstream`, `dromos-labs/metadex-*`, `prompter-byte` refs via audit), `solc-select` 0.7.6 + forge compile checks. Fork tests on live state, 9/9 pass. No keys, no keyed URLs, no transactions.

**Files:** `README.md` · `summary.json` · `analysis/upv3/bytecode-verification.md` · `upv3_pool_list.json` · `upv3_pool_state.json` · `upv3_details_flat.json` · `upv3_prices.json` · `upv3_rank.json` · `upv3_gauge_emissions.json` · `upv3_gauge_bal_out.json` · `upv3_gaugetofees_out.json` · `upv3_feepot_bal_out.json` · `upv3_fee_pots_summary.json` · `voter_selectors.txt` · `gaugeFactory_selectors.txt` · `gauge_selectors_named.json` · `factory.json`/`poolimpl.json`/`npm.json`/`swapfeemod.json`/`unstakedfeemod.json`/`registry.json` + unpacked sources (`factory-src/`, `poolimpl-src/`, `npm-src/`, `unstakedfeemod-src/`, `gauge0-src/`) · `poc/test/UpV3.t.sol`.
