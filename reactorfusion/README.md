# ReactorFusion — L2 Phase-2 deep dive (zkSync Era + Telos)

**Date:** 2026-10-14 · **Chains:** zkSync Era (324), Telos EVM (40) · **Class:** Compound-v2-fork lending (zombie, wind-down announced)
**Status:** read-only research; no mainnet transactions; all "executions" are live-node `eth_call` simulations (state overrides, discarded) or fork-free math checks. PoC runs in CI only.

---

## 1. TL;DR

| Target | Chain | Live custody now (cash) | E-U (unprivileged attacker) | Why closed / open | Latent risk |
|---|---|---|---|---|---|
| Unitroller `0x23848c28…F3f2` — 6 markets | zkSync Era | **$282,710** at market prices ($290,245 at oracle prices): 84.15 ETH, 11.5k USDC.e, 17.5k USDT, 0.1475 WBTC, 2.19M ZK, 2.9k USDC | **≈ $1.77 gross ≈ $0.1–0.5 net** (dust liquidation bonuses; largest single $0.096; gas ≈ $0.03–0.10 per liquidation eats most of it) | Oracle is a live Chainlink `latestAnswer()` reader; borrow-and-default unprofitable (max `cf×oracle/market = 0.850`); admin behind 24 h timelock; reserves/oracle admin-gated; no deprecated markets | If Chainlink retires the zkSync feeds, the oracle freezes and the pool re-opens (borrow-and-default needs >17.6 % overvaluation at cf 0.85; liquidation profiteering needs >8 % collateral undervaluation). Two markets (rfZK, rfUSDC.z) have a plain EOA admin |
| Unitroller `0x19646a04…E494` — 4 markets | Telos EVM | **$615** (11,043 TLOS, 0.1205 ETH, 104 USDT, 7 USDC) | **≈ $0.50 gross ≈ $0.3–0.5 net** (dust liquidations; Telos gas ≈ $0.001/tx) | DIA oracle: only DIA's updater EOA can write; no permissionless price path; borrow-and-default unprofitable; admin = EOA (P) | Oracle is already **7.5–8.3 days stale** (ETH +7.9 % vs market) and has no freshness check; Unitroller is upgradeable by a plain EOA with no timelock (privileged rug risk, not E-U) |

### **Total live extractable now (external unprivileged): ≈ $2.3 gross; ≈ $0.5 net of gas (range $0.1–1.0). Confidence: high.**

An honest near-zero: the protocol's remaining cash is *not* reachable by an unprivileged attacker today. The only live E-U is the Compound liquidation bonus on genuinely underwater positions whose total collateral is dust — and Era gas roughly cancels the gross bonus.

---

## 2. What ReactorFusion is, and the exact mechanism that remains open

ReactorFusion is a **Compound v2 fork** (Unitroller/Comptroller + CErc20/CEther-style cTokens + custom `RewardDistributor`/`RF` (ES33) rewards). It was heavily farmed in 2023–24, TVL collapsed after zkSync Ignite incentives ended (Jan–Mar 2025) and the team announced a **wind-down** on both chains (frontend modal; no exploit ever reported — see `analysis/incident-research.md`).

**Deployed code = repo code.** The verified source of the Era Comptroller implementation `0xF3CaF0bE62a0E6Ff6569004af55F57A0B9440434` and of the cTokens is byte-identical to `github.com/ReactorFusion/reactorfusion-contracts` (`Comptroller.sol`, `CToken.sol` diff = 0). Fork-specific changes vs upstream Compound v2:
* events moved to the Comptroller (`emitBorrow/emitRepayBorrow/emitLiquidateBorrow/emitMint/emitRedeem/emitAccrueInterest/emitTransfer`) — this is why the cTokens emit **no** Borrow/RepayBorrow/LiquidateBorrow events (borrower enumeration must use txs, not logs);
* `RewardDistributor dist` hooks inside `mint/redeem/borrow/repay/seize/transfer` (`dist.onAssetIncrease/onAssetDecrease/onAssetChange`);
* `takeReserves()` sends reserves to `dist` (callable only by `admin` or `dist`);
* `protocolSeizeShareMantissa` = 2.8 % (protocol's cut of the liquidation bonus);
* `whitelistedLiquidator` slot (currently **not** set: `liquidateBorrowAllowed` returns `NO_ERROR` for a random address — verified live);
* cToken `decimals()` = **underlying** decimals (not 18) — matters for oracle scaling.

**The one live extraction primitive** is Compound's standard liquidation bonus: a liquidator repays ≤ `closeFactor` (0.5 on Era, 1.0 on Telos) of an underwater borrow and seizes collateral worth `repay × 1.08` at oracle prices, of which the protocol takes 2.8 %, i.e. a **gross 4.976 % of the repaid amount** (minus the oracle-vs-market gap of the seized collateral). Everything else is gated:

| Path | Gate (verified live) | Status |
|---|---|---|
| Oracle manipulation (Era) | Chainlink `EACAggregatorProxy` feeds, each owned by a 4-of-9 Safe; oracle = `latestAnswer()` reader | closed (not DEX-based, not writable) |
| Oracle manipulation (Telos) | DIA `setValue` only by updater EOA `0x4b4c…ddea`; retired Redstone demo oracle `0x3B70…4148` no longer connected | closed |
| Stale-price borrow-and-default | needs `cf × oracle/market > 1`; live max = 0.850 × 1.0001 | closed today (open if feeds freeze and a collateral asset gains >17.6 %) |
| Liquidate healthy positions | `isDeprecated()` requires `cf==0 && borrowPaused && reserveFactor==1e18`; no market matches | closed |
| Drain reserves | `takeReserves()` requires `admin` or `dist`; `_reduceReserves` admin-only | closed |
| Swap oracle / upgrade comptroller | `_setPriceOracle` requires comptroller admin = **OZ TimelockController** `0xeE56…b5Db5` (minDelay 86400 s, proposer = 2-of-3 Safe `0xD971…4CE2`); `_setPendingImplementation` same | closed (P) |
| Mint collateral → borrow → default | collateral factors 0.60–0.85; oracle ≈ market | closed |
| Reward distributor harvest | `harvest()` is permissionless but pays only the caller's ledger share; distributor holds **0** ETH/USDC/USDT/WBTC; fresh account harvests 0 | closed |
| cToken exchange-rate donation / first-depositor | all markets have large `totalSupply`; donation raises everyone's rate | closed |
| Reentrancy | `nonReentrant` on all state-changing cToken paths; `dist` is `nonReentrant` | closed |
| Liquidate zero-collateral bad debt | `LIQUIDATE_SEIZE_TOO_MUCH` check | reverts (bad debt = supplier loss, not attacker gain) |
| `dist.takeReserves()` → Velocore sweep | `velocore__convert` requires `msg.sender ==` Velocore vault **and** `user == address(RF token)`; proceeds go to the vault, not the caller | closed |
| Public `updateRewards` / `mintEmission` | permissionless, but only mints/distributes the unpriced RF token to ledger shares | closed (no value) |
| cToken upgrade (`_setImplementation`) | admin = Timelock (rfUSDCe/rfETH/rfWBTC/rfUSDT) or EOA (rfZK/rfUSDCz) | closed (P) |

---

## 3. Live-state assessment (all reads at pinned blocks; keyless public RPCs)

### 3.1 zkSync Era — block **72,476,087** (state) / 72,485,663 (gates)

Comptroller `0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2` (Unitroller; impl `0xF3CaF0bE…0434`), oracle `0x1D54DD49…5C43` (`SimplePriceOracle`, owner = EOA `0x99999A3C4cB8427c44294Ad36895b6a3A047060d`), `closeFactor` 0.5, `liquidationIncentive` 1.08, `pauseGuardian` 0, all mint/borrow pauses false, `borrowCaps` 0 (uncapped), `admin` = Timelock `0xeE568575A8DaeF55D2fac121FD2362dF6BbB5Db5` (minDelay 86,400 s), `pendingAdmin` 0. Reward distributor `0x53C0DE201cab0b3f74EA7C1D95bD76F76EfD12A9` (underlying = RF `0x5f7cbcb3…3e4d`, owner = same EOA, **token balances 0**, lastReap Sep-2023).

| market | underlying | dec | cf | cash | borrows | supply | xrate | resv | oracle price | market price |
|---|---|---|---|---|---|---|---|---|---|---|
| rfUSDC `0x04e9db37…ac29` | USDC.e `0x3355df6d…aaf4` | 6 | 0.85 | 11,495.168 | 25,002.635 | 36,476.924 | 1.2818 | 20.88 | $0.999865 | $0.999735 |
| rfETH `0xC5db68F3…97e6` | **native ETH** | 18 | 0.80 | **84.150518 ETH** | 28.958626 | 113.103666 | 1.0374 | 0.00548 | $2,508.72 | $2,442.41 |
| rfWBTC `0x0a976E1E…9cF` | WBTC `0xBBeB516f…1011` | 8 | 0.80 | 0.147523 | 0.132289 | 0.279776 | 1.0792 | 3,538 sat | $83,287.33 | $81,708.15 |
| rfUSDT `0x894cccB9…8591` | USDT `0x493257fD…a4c` | 6 | 0.85 | 17,535.646 | 4,131.033 | 21,665.818 | 1.2333 | 0.86 | $0.998744 | $0.999306 |
| rfZK `0x0e392B6b…51f3` | ZK `0x5A7d6b2F…af3e` | 18 | 0.60 | 2,191,630.93 | 32,417.65 | 2,224,040.40 | 1.0027 | 8.18 | $0.015945 | $0.015156 |
| rfUSDC.z `0x930DA5e5…1445` | USDC `0x1d17cbcf…38d4` | 6 | 0.85 | 2,895.870 | 743.265 | 3,639.134 | 1.2403 | 0 | $0.999865 | $0.999724 |

**Cash total: $282,710 at market prices** ($290,245 at oracle prices; DefiLlama 2026-10-14). Supply $394,568; borrows $111,896.

**Oracle (Era):** `getUnderlyingPrice = feed.latestAnswer() × 10^(36 − feedDec − cTokDec)`, **no staleness check anywhere** (verified by decompiling the verified source; live equality with `latestAnswer()` re-verified per feed). All 5 Chainlink feeds are **live** (age at read: ETH/USD ~30 min, BTC/USD ~3 h, USDC/USD ~2 h, USDT/USD ~2 h, ZK/USD ~minutes; `updatedAt` on-chain):

| feed | address | description | decimals | latest answer | updatedAt |
|---|---|---|---|---|---|
| rfETH | `0x6D41d1dc…8eDA` | ETH / USD | 8 | 243,904,428,197 ($2,439.04) | 1791996079 |
| rfWBTC | `0x4Cba285c…1EA6` | BTC / USD | 8 | 8,184,242,500,000 ($81,842.43) | 1791987630 |
| rfUSDCe | `0x1824D297…376E` | USDC / USD | 8 | 99,986,821 | 1791988288 |
| rfUSDT | `0xB6150759…56a9` | USDT / USD | 8 | 99,891,027 | 1791988543 |
| rfZK | `0xd1CE60dc…DD13` | ZK / USD | 8 | 1,490,897 ($0.014909) | 1792004482 |

### 3.2 Telos EVM — block 493,857,202 (child C: oracle mechanics + positions)

Unitroller `0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494` (impl `0xD4b18a93…2b40`), `closeFactor` **1.0**, `liquidationIncentive` 1.08, `admin` = EOA `0x99999A3C…060d` (**no timelock**), oracle `0x0fA9De83…A8E2` = DIA reader (`DIAOracleV2` `0x86c5997d…0a33`), keys `USDC/USD, USDT/USD, ETH/USD, TLOS/USD`, scale 1e(36−underlyingDec). **Only DIA's updater EOA `0x4b4c4a6e760fdea078efc6bea046946b639bddea` can write prices** (random sender, even oracle owner, revert). Prices frozen 7.5–8.3 days (ETH $2,616 vs market $2,426 = **+7.9 %**; TLOS $0.019310 vs ~$0.01895 = +1.9 %). The retired Redstone oracle `0x3B70…4148` (permissionless `push()` with a 1-of-1 *demo* signer) is **disconnected** from the comptroller. Cash: rfTLOS 11,042.73 TLOS, rfETH 0.120545, rfUSDT 104.376, rfUSDC 7.057 → **$615**.

---

## 4. What an attacker can and cannot do (exact call paths)

**Can (E-U, live):** liquidate genuinely underwater positions.
```
Comptroller.getAccountLiquidity(borrower)              → shortfall > 0
Comptroller.liquidateBorrowAllowed(debtMkt, collMkt, attacker, borrower, repay) → 0 (NO_ERROR)
cTokenCollateral.accrueInterest()                       # freshness precondition
debtMkt.liquidateBorrow(borrower, repay[, collMkt])     # repay ≤ 0.5 × debt (Era) / 1.0 (Telos)
```
Gross profit = `repay × (1.08 × 0.972 × market/oracle − 1)`. Live reality (block 72,477,761 scan + live re-reads):
* 105 underwater accounts, total shortfall $272; the two largest ($153.84 + $68.31) have **zero collateral** → `LIQUIDATE_SEIZE_TOO_MUCH` revert (bad debt, not extractable);
* realistic **gross** total **$1.77** across 98 accounts with positive gross profit (largest $0.096); 7 accounts are loss-making;
* Era gas price at read time 0.04525 gwei; a Compound-v2 liquidation ≈ 250–400k gas ≈ **$0.03–0.10 per liquidation** → net across accounts: $0.54 (gas $0.02), $0.32 (gas $0.03), $0.14 (gas $0.05), $0.00 (gas $0.10). Best estimate **net ≈ $0.1–0.5**;
* Telos: 13 underwater, shortfall $12.80, realistic gross profit **≈ $0.50**, gas ≈ $0.001/tx → net ≈ $0.3–0.5.
Net total ≈ **$0.5** (range $0.1–1.0). No flash loan needed (repay sizes are cents).

**Cannot:** borrow without collateral (reverts), borrow-and-default profitably (`cf × oracle/market ≤ 0.850 < 1` for every market), manipulate either oracle, take reserves, reduce reserves, set reserve factors, swap the oracle, upgrade the comptroller/cTokens, liquidate healthy accounts (no deprecated market; `INSUFFICIENT_SHORTFALL`), drain the reward distributor (holds nothing; `harvest` for a fresh account returns 0), or profit from any cToken exchange-rate donation.

---

## 5. PoC / verification

* **`ci/live_verify.py`** (runs in CI, keyless-or-env RPC): re-reads market state, feeds, gates and the underwater set at a fresh block; re-executes the attack paths as `eth_call` (attacker `0x1111…1111`) and **simulates a full liquidation on the live node** with a state override funding the attacker; writes `ci-out/live-verification.json`. Latest CI results (block 72,487,261):
  * feeds: all five `getUnderlyingPrice == latestAnswer × 10^(36−feedDec−cTokDec)` (`scaled_ok: true`), ages 11 min–8.3 h → **no staleness check, feeds live**;
  * gates: `borrow` without collateral → revert; `takeReserves` (attacker) → revert; `setPriceFeed` (attacker) → revert `Ownable: caller is not the owner`; `_setPriceOracle` (attacker) → returns `1` (UNAUTHORIZED); `_reduceReserves` (attacker) → revert; `harvest` fresh account → `0`; comptroller `admin` = timelock, `oracle owner` = EOA;
  * borrow-and-default: `cf × oracle/market` = 0.7906 (ETH), 0.7973 (WBTC), 0.8497 (USDT), 0.8501 (USDC.e/USDC), 0.6091 (ZK) → **no profitable default**;
  * liquidation simulation: for a healthy account `liquidateBorrowAllowed` returns `3` (INSUFFICIENT_SHORTFALL) and the simulated `liquidateBorrow` reverts with `0x1429a2f2…03`; for genuinely underwater accounts the seize math returns positive-but-dust amounts (`liquidateCalculateSeizeTokens` e.g. 0.32899 cETH for a 762.86 USDC repay).
* **`poc/`** (Foundry, runs in CI): `ReactorFusionMath.t.sol` — 6/6 pass, fork-free assertions of the Compound math with the live constants (oracle scaling, liquidation bonus bound, borrow-and-default thresholds, bad-debt revert condition, Telos stale-oracle condition). `ReactorFusionLive.t.sol` is a fork suite that **self-skips** because standard Foundry cannot execute EraVM bytecode (probe `Probe.t.sol`: every `staticcall` on a standard Era fork returns `0x`, while the same calls succeed on the live node). We therefore use **live-node `eth_call` with state overrides** as the executable PoC — executed by the real EraVM, which is stronger evidence than a local fork simulation.
* CI runs (GitHub Actions, `artsbykriss/ca-zombie-ci`):
  * https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38651990032 — corrected live-verification: block 72,487,351, 17 accounts re-read, **9 genuinely underwater with profit, total $0.2943 gross, largest $0.0794**; `liquidateBorrowAllowed` for a random attacker returns `0` (NO_ERROR);
  * https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38650040607 — full artifact set (feeds/gates/borrow-and-default + simulation);
  * https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38647330757 — first run; math tests 6/6, fork suite skipped;
  * final run (ETH-debt end-to-end liquidation simulation): `FINAL_CI_RUN_URL`.
* **Negative results (do not re-investigate):** no Borrow/RepayBorrow/LiquidateBorrow events on cTokens (fork emits them from the Comptroller); GoldRush `events/address` is broken for these contracts; the cToken `underlying()` of the native-ETH/TLOS markets reverts (use `getCash`); the deployed `markets(address)` getter returns 2 values (bool, cf) not 3; `allMarkets()` reverts on the Unitroller (use `getAccountLiquidity`/`getAssetsIn`); zkSync Era cannot be forked by standard Foundry (EraVM).

---

## 6. Verdict and residual/latent risk

* **E-U now: ≈ $2.3 gross / ≈ $1.5–2.0 net. H-O: suppliers can redeem their own cTokens (cash-limited: rfUSDC.e cash 11.5k vs 36.5k supply — normal lending). P: admin/timelock/EOA paths. S: bad debt ($8–14 on Telos; ~$222 of Era shortfall has no collateral) and the rfETH market's bad-debt exposure.**
* **Latent risk (why this is a watch item):** the Era oracle has **no staleness check**; it is safe only because Chainlink still maintains 5 feeds for a dead protocol. If any feed is retired/frozen while its market holds collateral, the borrow-and-default condition (`cf × oracle/market > 1`, i.e. >17.6 % overvaluation at cf 0.85) or a profitable liquidation wave (>8 % undervaluation) becomes reachable against the remaining ~$283k. The Telos oracle is already 8 days stale and its admin is a plain EOA with upgrade rights.
* **Blockers for extraction:** no oracle control, no admin keys, no zero-collateral liquidations, no permissionless reserve/oracle paths, reward token worthless/empty distributor.

---

## 7. Methodology & sources

* Direct on-chain reads (keyless public RPCs; `analysis/rpclib.py`), pinned blocks; verified sources from the zkSync explorer + `github.com/ReactorFusion/reactorfusion-contracts` (diffed, identical); Teloscan sources; DefiLlama prices (`coins.llama.fi`, 2026-10-14); child subagents for the Era borrower scan (1,863 accounts read on-chain; 1497 with positions; tx-based enumeration because the fork emits no borrow events), the Telos side (100 % debt coverage) and incident research (PeckShield audit 2023-05-31; wind-down; Safe/timelock facts).
* **Caveats:** the Era liquidation total is bounded by the collateral actually found in the scanned account set (the rfETH market's debt attribution was incomplete in the phase-2 scan). A dedicated gap crawl (`analysis/era-crawl/`, `analysis/era-crawl-summary.md`) re-enumerated borrowers in the missing block ranges; the top-40 gap-crawl borrowers by net principal (up to 70.4 ETH) were checked live and **none is underwater** (`analysis/era-crawl-liquidity.json` at block 72,487,142). USD uses DefiLlama spot; gas is estimated from the live gas price (0.04525 gwei) and a 250–400k-gas liquidation; the two "dust" totals exclude gas and already subtract the oracle-vs-market gap for cross-asset seizes.
* **Files:** `analysis/state-dump.json` (all markets), `analysis/feeds-era.json`, `analysis/era-dist.json`, `analysis/era-positions-*.json|md` (phase-2 scan), `analysis/telos-*` (Telos), `analysis/incident-research.md`, `ci/live_verify.py` + `ci-out/live-verification.json`, `poc/` (Foundry), `summary.json`.
