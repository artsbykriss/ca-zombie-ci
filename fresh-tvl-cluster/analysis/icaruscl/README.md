# Z3-H17 · Icarus CL (RISE, chain id 4153) — old-generation Slipstream deployment deep dive

**Date:** 2026-10-16 · **Chain:** RISE (4153) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** CLFactory `0x6f7DA11c13Ba09A153dA06d376044e5859Db607B` (10 pools) · CLPool impl `0x4356B9347D963076406187ED7BE73c526F071E53` · NonfungiblePositionManager `0x195D3037cb4AF610B96EF2984b4013eE836568E1` · CLGaugeFactory `0x42ac2D74117BbCFa92142Bb4CBc045fbbb959329` · CLGauge impl `0xe418Ae485B9057f13223dD76657eac103bCbF127` · voter `0xFB3773f03EFB35198b065e455090E55eE25D3177` · owner SafeProxy `0x838fc4155Fc13B3b75030950Fd9B58DbCE874aE0`
**Method:** verified-source fetch (RISE Blockscout API), diffs vs upstream Slipstream, full live enumeration (10 pools), 7 fork tests.

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| CLPool (mint / burn / collect / swap / flash / stake / collectFees) | **$0** | deployed pool source = old-gen Aerodrome Slipstream with only cosmetic deltas (init-time gauge/nft, `tokens()` view, SLOAD cache); auth identical to upstream: 6-arg `collect`/4-arg `burn` `onlyNftManager`, `stake`/`collectFees` `onlyGauge`, 3-arg `burn`/5-arg `collect` owner = `msg.sender`, flash callback to `msg.sender` with balance enforcement. Fork-proven: 6-arg collect → `NNFT`; flash without repay → `F0`; flash with exact repay ⇒ pool gains exactly the 0.01% fee, attacker +0 | none |
| NonfungiblePositionManager `0x195D3037…` | **$0** | verified source; `collect`/`decreaseLiquidity`/`burn` all `isAuthorizedForToken`; fork-proven foreign `collect` reverts; NPM ETH balance = 0 (no `refundETH` park) | canonical `refundETH`/`sweepToken` permissionlessness → monitor for parks |
| Stake layer (CLGauge for the USDR/USDC.e pool `0xbdf33a22…`) | **$0** | verified CLGauge: `withdraw`/`getReward(uint256)` require `_stakes[msg.sender]`, `deposit` requires NFT ownership + pool match; fork-proven all revert `NA` for a fresh caller; `rewardRate = 0`, `periodFinish = 0` (no emission program running) | if emissions are ever funded, only stakers can claim (H-O) |
| Factory / voter / owner (Safe proxy) | **$0** | factory admin self-gated (owner/manager chain); owner is a 172-byte Safe proxy (contract, not EOA); `setNonfungiblePositionManager` one-shot (already set) | P: gauge factory + voter can create gauges; Safe keys are the privileged surface |
| `stakedLiquidity` share in the main pool | **$0** | 532,697,711 (≈0.0085% of pool liquidity 6.259e15) is virtual staked weight; the staked NFT is held by the gauge and only its depositor can withdraw it | none |

**Total live E-U extractable now: $0.00 — confidence high** (verified sources on all layers + fork-proven unauthorized negatives + no live emissions).
TVL is LP principal (H-O): **$8,067,346 priced across 10 pools** vs DefiLlama $8.03M — **99.4% in one pool**: `0xCBc0c0d2782f97077A6309e28B9B70Dc73a934D2` USDR/USDC.e ≈ $8,017,213 (USDR 4,014,555.47 + USDC.e 3,992,638.74). Reads at block 24,515,526; fork tests at block 24,519,377.

## 2. What is deployed, exactly

Icarus CL is an **old-generation Aerodrome Slipstream** deployment (the generation whose CLFactory carries `nft`/`gaugeFactory`/`gaugeImplementation` and whose pool takes `_gauge`/`_nft` at `initialize` instead of the `factoryRegistry`+`setGaugeAndPositionManager` design). Diffs vs `aerodrome-finance/slipstream` main for the CLPool (verified source, `analysis/icaruscl/poolimpl-src`): only (i) old-gen initialize, (ii) an extra `tokens()` view, (iii) the `getRewardGrowthInside` SLOAD cache. **No drift** in `mint`/`burn`/`collect`/`swap`/`flash`/`stake`/`collectFees` guards.
- Pool auth: 6-arg `collect`/4-arg `burn` = `onlyNftManager` (`nft` is set at pool creation = the NPM); `stake`, `collectFees`, `updateRewardsGrowthGlobal`, `syncReward` = `onlyGauge`; 3-arg `burn`/5-arg `collect` operate on `owner = msg.sender`; `flash` fee = `ceil(amount × fee()/1e6)` with before/after balance checks (`F0/F1`).
- NPM (verified): `collect`/`decreaseLiquidity`/`burn` = `isAuthorizedForToken`; `increaseLiquidity` rejects staked positions (`require(ownerOf != pool.gauge())`); has a `_userPositions` index.
- CLGauge (verified): `deposit` requires `nft.ownerOf(tokenId) == msg.sender` + pool match + `voter.isAlive(gauge)`; `withdraw`/`getReward(uint256)` require `_stakes[msg.sender].contains(tokenId)`; `getReward(address)` is voter-only; `notifyRewardAmount` is voter-only.
- Factory: `setOwner`/`setSwapFeeManager`/`setUnstakedFeeManager` self-gated; `setSwapFeeModule`/`setUnstakedFeeModule`/`setDefaultUnstakedFee` manager-gated; `setNonfungiblePositionManager` owner-once (already set → closed); `createPool` permissionless (atomic initialize).

## 3. Live-state assessment (2026-10-16)

- **Factory** `0x6f7DA11c…`: `owner() = 0x838fc4155Fc13B3b75030950Fd9B58DbCE874aE0` (Safe proxy, 172 bytes), `allPoolsLength() = 10`, `nft() = 0x195D3037cb4AF610B96EF2984b4013eE836568E1`, `gaugeFactory() = 0x42ac2D74…`, `gaugeImplementation() = 0xe418Ae48…`, `swapFeeManager() == unstakedFeeManager() == owner`, `swapFeeModule() = 0xF0FeAb2022CEc65028C3b5E376043e94694dE225`, `unstakedFeeModule() = 0xf5dA8BB687a3AE96Caa67758572bF7ce1BD5C1D8`, `defaultUnstakedFee() = 100,000`.
- **Pools (10):** one dominant **USDR/USDC.e** pool `0xCBc0c0d2…` ($8.02M; tickSpacing 1; liquidity 6.259e15; `stakedLiquidity = 532,697,711`; gauge `0xbdf33a22…`); USDR/xlpUSD $43.8k; WETH/USDR $6.2k; rest dust. Full table: `analysis/icaruscl/icarus_rank.json`.
- **Gauge (main pool):** `voter() = 0xFB3773f0…`, `pool() = 0xCBc0c0d2…`, `rewardRate() = 0`, `periodFinish() = 0`, `left() = 0` — registered but unfunded.
- **NPM:** ETH balance 0.

## 4. What an attacker can / cannot do

**Cannot (fork-proven):**
- `gauge.withdraw(1)` / `gauge.getReward(1)` / `gauge.deposit(1)` → revert `NA` (T2).
- `NPM.collect({tokenId: 1, …})` for a foreign position → revert (T3).
- `pool.collect(recipient, …, owner)` 6-arg → revert `NNFT` (T4).
- `pool.flash(…, 1000, 1000, "")` without repayment → revert `F0` (T5).
- `npm.refundETH()` → no-op, NPM ETH stays 0 (T7).

**Can (zero-gain):**
- Pay the flash fee and round-trip: exact repayment ⇒ pool **+100,000 USDR (0.01% of 1e9)** and attacker delta 0 (T6).

## 5. PoC / fork verification

`poc/test/IcarusCL.t.sol` (`IcarusCLH17Test is ForkHelper`), 7 tests, **7/7 PASS** locally (fork `https://rpc.risechain.com`, block 24,519,377). Structural: Safe-proxy owner; pool → gauge/NPM/factory links; liquidity/staked live numbers; gauge rewardRate 0.
ForkHelper note: the parent's `poc/src/ForkHelper.sol` does not compile with the vendored forge-std (duplicate `VM_ADDRESS`); local runs used an identical-semantics patched copy in a scratch project; the delivered test imports `ForkHelper` as specified.

## 6. Verdict and residual/latent risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** Verified sources at every layer; auth canonical for the generation; fork-proven negatives; no live emissions and no parked ETH.
- **E-U-conditional:** none live. Re-arm notes (all privileged): funding a gauge emission program (then only stakers can claim), registering a new NPM (owner-once closed), fee-module changes (manager-gated, fees bounded by module caps).
- **H-O:** $8.07M LP principal + any future staking rewards.
- **P:** owner Safe + gauge factory/voter (gauge creation, emission admin); fee modules.
- **S:** donation/dust in pools (no `skim`); sub-unit rounding.
- Caveats: a sibling `helios-v3` factory on RISE (`0xbF30bD85…`) was not in scope (its `allPools(uint256)` ABI did not answer; separate protocol); prices are point-in-time DefiLlama; Blockscout API was used for source fetch (Etherscan V2 does not support chainid 4153).

## 7. Methodology & sources

Read-only: `cast`, RISE public RPC `https://rpc.risechain.com`, RISE explorer Blockscout API, DefiLlama price API. Fork tests on live state, 7/7 pass. No keys, no transactions.

**Files:** `README.md` · `summary.json` · `analysis/icaruscl/bytecode-verification.md` · `icarus_pool_list.json` · `icarus_details_flat.json` · `icarus_balances_out.json` · `icarus_prices.json` · `icarus_rank.json` · `factory-src/` · `poolimpl-src/` · `npm-src/` · `gaugeimpl-src/` · `gaugefactory-src/` · `poc/test/IcarusCL.t.sol`.
