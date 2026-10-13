# Geist Finance (Fantom) — zombie deep-dive (L2 Phase 2)

**Date:** 2026-10-13 · **Chain:** Fantom Opera (chainId 250) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**

Geist Finance is an Aave V2 fork on Fantom (deployed Aug 2021). It was put into
repay/withdraw-only mode in July 2023 after the Multichain bridge collapse (its reserve assets are
Multichain-bridged tokens), and formally wound down (`deadFrom 2023-10-18`). The pool is still live:
all 9 reserves are **frozen** (deposit/borrow blocked; withdraw/repay/liquidate open), the pool is
**not paused**, and the price oracle is **frozen** (Chainlink feeds dead, Band feeds stale since
2024-12-03) so every interaction is priced at the stored `lastGoodPrice` values from ~2024.

The aToken contracts still custody the reserves' cash (the original depositors' money), which the
Phase-1 triage counted at ~$124k using only LINK/CRV/MIM at canonical prices. On-chain, the whole
cash stack is ~$18.0M at the *frozen oracle* prices, but the reserve assets are **unbacked
Multichain tokens** whose live local DEX prices are 1.5–150× below the oracle: the same cash is
worth ≈ **$110–131k** when actually sold into the live Fantom DEX pools (SpookySwap + SpiritSwap,
measured on a fork: 1.91M WFTM).

---

## 1. TL;DR

| Surface | Live value | Extractable by fresh unprivileged attacker? | Why |
|---|---|---|---|
| **GEIST staking `0x49c93a95…` (treasury aToken rewards)** | stream ≈ $1.4k/week (at DEX prices) | **YES — E-U ≈ $603 first week, ≈ $260/week recurring** | buy GEIST on the DEX, stake (unlocked), `getReward()`, redeem + sell the aTokens, unstake; PoC-verified net +8,813.8 WFTM in one week |
| LendingPool `0x9FAD24f5…d068` — aToken cash (all 9 reserves) | ≈ $110–131k realisable (DEX) / $18.0M at frozen oracle | **No (liquidation path is $0)** | all 881 underwater borrowers with collateral are unprofitable to liquidate; cash belongs to aToken holders (H-O) |
| WFTM market (aWFTM 8.25B nominal) | **$0** | No — **S (stuck)**: cash = 0, withdrawal reverts | the market was drained; aWFTM is unbacked |
| Cash behind *underwater* borrowers' collateral | ≈ $15k realisable | No — **S (stuck)** | borrowers cannot withdraw (HF≈0) and nobody will liquidate them at a loss |
| Admin surfaces (freeze/pause/oracle/configurator) | — | No (P) | 3-of-5 Gnosis Safe `0xC03253FF…` + 2-day Timelock |

**Total live extractable now (E-U): ≈ $603 for the first weekly cycle, ≈ $260/week recurring** —
the staking-reward farm (buy GEIST → stake → claim the treasury's aToken rewards → redeem + sell →
unstake). The **liquidation path is $0** (all 881 underwater borrowers with collateral are
unprofitable to liquidate — see §6).
**H-O:** ≈ $115k of aToken cash is withdrawable by holders (first-come-first-served; several markets under-backed).
**S:** ≈ $15k of cash locked behind underwater positions + the whole WFTM market (8.25B nominal aWFTM, zero cash).

---

## 2. The protocol today, in exact terms

* **LendingPool proxy** `0x9FAD24f572045c7869117160A571B2e50b10d068` (impl `0x3104ad2aadb6fe9df166948a5e3a547004862f90`,
  EIP-1967 impl slot verified; admin slot = 0 → immutable). Source = stock Aave V2 (master) with one
  change: `_executeBorrow` prices with `IPriceOracleGetter.updateAssetPrice()` instead of
  `getAssetPrice()` (Geist's pull oracle). All user functions carry `whenNotPaused`; `paused() == false`.
* **LendingPoolAddressesProvider** `0x6c793c628Fe2b480c5e6FB7957dDa4b9291F9c9b`
  (getLendingPool / getPriceOracle / getPoolAdmin / getEmergencyAdmin / getLendingPoolConfigurator
  all read live). Pool admin = emergency admin = `0xC03253FFc57bC863c6F593bDCe394B533DF6a182`
  (contract, 170 bytes). Owner = `0x7FB9a7cBc6689C1C79e37BF8f852adA44b10EfFC` (contract, 5,922 bytes).
* **PriceOracle (AaveOracle)** `0xC466e3FeE82C6bdc2E17f2eaF2c6F1E91AD10FD3` → per-asset
  `PriceFeed` (Liquity-style Chainlink-primary/Band-fallback). **Every feed returns
  `fetchPrice() == lastGoodPrice()` and `status() == 1` (usingBandChainlinkUntrusted)**: the
  Chainlink aggregators revert on `latestRoundData()`, and the Band `StdReference` base updates are
  frozen at 2024-12-03 (`getReferenceData` returns e.g. LINK 24.06 with `lastUpdatedBase=1733242882`),
  so `_fetchPrice` falls through to the stored `lastGoodPrice`. `updatePrice()` is permissionless but
  a **no-op** (PoC-verified for all 9 assets). Last `PriceFeedStatusChanged` events (all to status 1):
  LINK block 122,920,984 (2026-08-16), MIM 117,917,983 (2025-11-14), BTC 120,508,218 (2026-02-23),
  WFTM 123,596,615 (2026-10-08) — the feeds are still *touched* by pool interactions, but the price
  values no longer move. Effective prices are the stored values below.
* **All 9 reserves are frozen** (`isFrozen=1`, `isActive=1`) → no deposits, no borrows;
  withdraw / repay / liquidationCall remain open. This is the "repay & withdraw only" wind-down state.

### Reserve state (block 123,677,183; direct RPC, public Fantom endpoint)

| # | sym | underlying | aToken | cash (underlying) | aToken supply (nominal) | variable debt (nominal) | oracle $ | live DEX $ |
|---|-----|-----------|--------|------------------|------------------------|------------------------|----------|-----------|
| 0 | DAI | 0x8D11eC38…bf3E | 0x07E6332d…DCFB | 632,692.86 | 914,308.12 | 281,688.80 | 0.99990 | 0.0129 |
| 1 | ETH | 0x74b23882…C76d | 0x25C130B2…A22f | 488.3336 | 497.3236 | 9.0088 | 2,519.05 | 26.3 |
| 2 | WFTM | 0x21be370D…4C83 | 0x39B3bd37…430a | **0** | 8,317,308,997.58 | 13,562,361,534.03 | 0.10746 | 0.0684 |
| 3 | BTC | 0x321162Cd…5b11 | 0x38aCa548…10A3 | 113.4801 | 113.8367 | 0.3566 | 68,615.04 | 1,066 |
| 4 | fUSDT | 0x049d6802…3C7A | 0x940F41f0…F6B5 | 7,634,561.11 | 7,951,693.08 | 317,136.43 | 0.99950 | 0.0567 |
| 5 | USDC | 0x04068DA6…5B75 | 0xe578C856…0b26 | 469,779.98 | 1,509,165.47 | 1,039,528.95 | 0.99992 | 0.117 |
| 6 | CRV | 0x1E4F97b9…C68b | 0x690754A1…8A98 | 107,517.02 | 107,867,898.39 | 128,719,113.57 | 0.35400 | 0.00427 |
| 7 | MIM | 0x82f0B8B4…829c1 | 0xc664Fc7b…3bBe | 173,780.29 | 1,493,215.95 | 1,562,951.79 | 0.99866 | 0.0426 |
| 8 | LINK | 0xb3654dc3…FBdC8 | 0xBeCF2926…F73B | 6,119.6206 | 6,616.1620 | 496.7385 | 8.72233 | 0.215 |

* Cash is held by the **aToken contracts** (Aave V2 design) — verified with direct
  `underlying.balanceOf(aToken)` reads for all nine.
* `liquidityIndex` (LI) vs `variableBorrowIndex` (VBI) show three years of unpayable debt:
  WFTM LI 30.88 / VBI 6,708.19, CRV LI 47.34 / VBI 7,565.65, MIM LI 3.29 / VBI 14.55 (all others ~1.02–1.2).
  The WFTM and CRV books are ~$0-realisable bad debt; the aToken claims there are 0–0.1% backed.

### Why the oracle price ≠ market price

The reserve assets are the **Multichain (Anyswap)-bridged tokens** (that is what killed the protocol:
"oracles misreporting Multichain token values", July 2023). Chainlink/Band feeds died with the
protocol, so the frozen `lastGoodPrice` still values them at ~2024 levels. Live local DEX prices
(SpookySwap **and** SpiritSwap show identical ratios → genuinely arbitraged market):

| asset | oracle $ | live DEX $ | oracle/market |
|---|---|---|---|
| DAI | 0.99990 | 0.0129 | 77× |
| ETH | 2,519.05 | 26.3 | 96× |
| WFTM | 0.10746 | 0.0684 | 1.6× |
| BTC | 68,615 | 1,066 | 64× |
| fUSDT | 0.99950 | 0.0567 | 18× |
| USDC | 0.99992 | 0.117 | 8.5× |
| CRV | 0.35400 | 0.00427 | 83× |
| MIM | 0.99866 | 0.0426 | 23× |
| LINK | 8.72233 | 0.215 | 41× |

DefiLlama's `fantom:LINK` price ($12.88) is an exact copy of `ethereum:LINK` (ratio 1.0000 for 90
days) — a bridged-token parity assumption, not a Fantom market price. The Fantom pools price
anyLINK at $0.215 (Spooky) / $0.215 (Spirit). The **backed** USDC on Fantom (native
`0x28a92dde…`) trades at $1.00 in its WFTM pool, while the Multichain USDC in Geist's reserve
(`0x04068DA6…`) trades at $0.117 — confirming the discount is asset-specific, not a chain-wide artifact.

**Why these tokens are (still) unbacked.** Multichain collapsed in July 2023 (~$200–210M across
chains, ~$120M from the Fantom bridge alone; CEO arrested, MPC keys compromised). No swap,
re-backing or redemption program for the Fantom anyTokens has ever existed; the only recovery path
is the Multichain liquidation (KPMG Singapore liquidators appointed 2025-05-09; **63,289,029 USDC**
frozen in three addresses; US Chapter 15 recognition 2025-12-08; no claims portal or distribution as
of the last public update 2026-01-02). No bridge or aggregator accepts these tokens for redemption —
they can only be *sold* on Fantom DEXes, which is exactly the market above. Geist itself never
re-opened (announced 2023-07-14) because its Chainlink-based oracles priced the bridged tokens at
canonical values — the same mismatch that persists today (see `analysis/child-research-multichain.md`).

### Realisable value of the cash (fork-measured)

Selling the entire aToken cash of each reserve through the live UniswapV2 routers (SpookySwap and
SpiritSwap, real pools, `getAmountsOut` on the full cash amount):

| asset | WFTM out (Spooky) | WFTM out (Spirit) | total |
|---|---|---|---|
| DAI | 61,197 | 517 | 61,714 |
| ETH | 110,669 | 20,387 | 131,056 |
| BTC | 293,657 | 25,430 | 319,087 |
| fUSDT | 392,637 | 33,981 | 426,618 |
| USDC | 552,652 | 293,290 | 845,942 |
| CRV | 5,036 | 5,109 | 10,145 |
| MIM | 43,948 | 48,587 | 92,535 |
| LINK | 14,817 | 7,833 | 22,650 |
| **total** | **1,474,613** | **435,134** | **1,909,747** |

≈ 1.91M WFTM ≈ **$130.6k** at FTM $0.0684 (CoinGecko; $108.7k at DefiLlama's $0.0569). This is the
upper bound for "dump all the cash at once" (it consumes both pools' WFTM sides); it is not the
attacker's profit — the attacker must first *own* the aTokens (H-O) or *seize* them via liquidation
(E-U, §6). If any bridge or off-ramp still honoured these tokens at canonical prices the value would
be far higher — none was found (the Multichain bridge is dead; native-asset bridges do not accept
these tokens).

---

## 3. Live-state assessment (roles, gates, custody)

* `paused() == false`; every reserve `isActive=1, isFrozen=1` (repay/withdraw/liquidate-only).
* Pool admin = emergency admin = `0xC03253FFc57bC863c6F593bDCe394B533DF6a182` — a **Gnosis Safe
  proxy** (`masterCopy()` `0x87EB227FE974e9E1d3Bc4Da562e0Bd3C348c2B34`, **threshold 3 of 5** owners:
  `0xC3b18578…743E`, `0x902a3179…AEF4`, `0x52512DfB…5A69`, `0x229A94Ee…A156`, `0x71a15Ac1…98B5`).
  `setPause(bool)` is `onlyLendingPoolConfigurator` → configurator proxy `0xb7C10e50…6AA8`.
* Oracle owner = `0x7FB9a7cBc6689C1C79e37BF8f852adA44b10EfFC` — a **Timelock** (`admin()`
  `0xfba9C0286ffec12fE4d6bdEB10dC67905EBD7A63`, `delay() = 172800s` (2 days), MINIMUM_DELAY 2 days,
  GRACE_PERIOD 14 days). `setAssetSources` is `onlyOwner` → 2-day timelock behind the multisig.
* Treasury addresses (`RESERVE_TREASURY_ADDRESS()` on each aToken):
  * DAI/ETH/CRV/MIM/LINK → **the GEIST staking contract** `0x49c93a95dbcc9A6A4D8f77E59c038ce5020e82f8`
  * WFTM → `0x0F595677AfC5F4A99Cfa1dDB4a00B8f54Cfda506`
  * BTC/fUSDT/USDC → `0xfB6485AE36b3027eF109f271aD4C3ECFD651cF30`
* Treasury aToken balances (protocol fees already minted inline by `ReserveLogic._mintToTreasury` on
  every state update — there is no pending `mintToTreasury` queue):
  staking contract holds aLINK 228.5575, aCRV 105,754,391.19(nom), aMIM 1,175,144.41(nom),
  aDAI 269,124.64, aETH 31.19986; the WFTM treasury holds aWFTM 8,246,777,537.35(nom); the
  stablecoin treasury holds aBTC 0.00159310, afUSDT 4,319.10, aUSDC 85,566.46.
* **Staking rewards = those aTokens.** `MultiFeeDistribution.rewardTokens` = [GEIST, aDAI, aETH,
  aWFTM, aBTC, afUSDT, aUSDC, aCRV, aMIM, aLINK]; rewards are streamed pro-rata to all stakers
  (`totalSupply` = 386.56M GEIST staked, `lockedSupply` = 245.88M). The deployed contract exposes
  **`getReward()` (selector `0x3d18b912`, no arguments)** — the `getReward(address[])` variant in the
  GitHub source is *not* the deployed ABI. A fresh staker (bought GEIST) **can** claim: PoC
  `test_staking_farm_roundtrip` received aCRV 2.99M nominal, aMIM 6,513, aDAI 14.6, aETH 0.000026,
  aLINK 0.0063 after one week and netted **+8,813.8 WFTM** after selling everything and unstaking.
  The 8 successful `RewardPaid` claims in the last 1M blocks (all at block 123,673,374) confirm the
  mechanism is live.
* No aToken allowances to third parties were found that matter; aTokens are not transferable claims
  on others' cash without owning them.

---

## 4. What an attacker can / cannot do

**Cannot (all PoC-verified on a fork):**
1. Withdraw or redeem aToken cash without holding aTokens (`test_fresh_attacker_cannot_withdraw`,
   `test_fresh_attacker_cannot_redeem_aTokens` → revert).
2. Move the oracle: `updatePrice()` is permissionless but returns `lastGoodPrice` for every feed
   (Chainlink dead, Band frozen) → prices are immutable (`test_oracle_cannot_be_refreshed_by_attacker`).
3. Use admin paths: `setPause`, `setReserveFreeze`, `setAssetSources`, `recoverERC20` are all
   owner/configurator-gated (P).
4. Redeem unbacked markets: the WFTM market has zero cash → any aWFTM withdrawal reverts
   (`test_wftm_market_is_unbacked`).
5. Farm the staking contract: rewards are pro-rata and effectively finished.

**Can (E-U, PoC-verified):**
* **Farm the staking rewards.** `MultiFeeDistribution 0x49c93a95…` streams the treasury's aTokens to
  GEIST stakers. GEIST is buyable on the live DEX; staking is permissionless and unlocked
  (`withdraw()` any time); the deployed contract's `getReward()` (selector `0x3d18b912`) claims all
  reward tokens. One week with 86.5M GEIST staked yields aTokens worth **+8,813.8 WFTM net**
  (PoC `test_staking_farm_roundtrip`), of which ~$344 is a one-time drain of the entire aCRV cash
  and ~$260/week is the recurring aMIM/aDAI/aETH/aLINK interest stream.
* Any aToken holder (incl. the attacker once they hold aTokens) can `redeem`/`withdraw` 1:1 up to
  cash (H-O) — demonstrated with the staking contract's aLINK (`test_holder_can_withdraw_its_aTokens`).

**Can, but not profitably (liquidation path, quantified):**
* `liquidationCall(collateral, debt, user, debtToCover, receiveAToken)` works for the 881 underwater
  positions, but every (debt, collateral) pair is unprofitable at live DEX prices: either the
  collateral is *more* over-valued by the frozen oracle than the debt (e.g. repay WFTM r=1.6× to
  seize BTC r=64×), or the collateral is WFTM whose aToken has zero cash. Full screen:
  `analysis/screen_full.py` → **0 pairs with > $1 estimated profit**.

---

## 5. PoC / fork verification

Foundry project in `poc/` (vendored forge-std). All tests run against a live Fantom fork; nothing is
sent to mainnet.

| Test | Result | What it proves |
|---|---|---|
| `test_live_state` | PASS* | 9 reserves, all frozen, cash/supply/debt per reserve |
| `test_oracle_is_frozen` | PASS | `fetchPrice()==lastGoodPrice()` for all 9 feeds, `status=1` |
| `test_oracle_cannot_be_refreshed_by_attacker` | PASS | permissionless `updatePrice()` cannot move any price |
| `test_fresh_attacker_cannot_withdraw` / `..._redeem_aTokens` | PASS | no free withdrawal path |
| `test_holder_can_withdraw_its_aTokens` | PASS | H-O: staking contract redeems 228.56 aLINK → 228.56 LINK |
| `test_wftm_market_is_unbacked` | PASS | S: aWFTM cash 0 → withdraw reverts |
| `test_realizable_cash_via_spooky` / `..._via_spirit` | PASS | cash → 1,474,613 + 435,134 WFTM via the live pools |
| `test_liquidate_worst_borrowers` | PASS* | liquidation attempts over the worst live borrowers: no profitable pair (matches the off-chain screen) |
| `test_targeted_liquidation_ladder` | PASS | the standout USDC-collateral position (997,708 aUSDC) has only dust LINK debt → seizure capped at dust; net P&L deeply negative for every ladder step |
| `test_staking_farm_roundtrip` | PASS | **E-U: buy GEIST → stake → `getReward()` → redeem/sell aTokens → unstake = +8,813.8 WFTM net in one week** |
| `test_existing_staker_claim` / `test_fresh_eoa_claim_reverts` | PASS | `getReward(address[])` (GitHub-source ABI) reverts; the deployed no-arg `getReward()` (0x3d18b912) is the live path |

\* CI failures in the first run were public-RPC HTTP 429 rate limits (not logic); the tests were
re-run locally on a quieter endpoint and pass.

CI runs (GitHub `artsbykriss/ca-zombie-ci`, GitLab fallback while GitHub was billing-locked):
* Full borrower scan + tests: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38467704657
  (14/16 tests passed; 2 failures were public-RPC HTTP 429s — re-run below)
* Final re-run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38481917347
* GitLab fallback pipeline (scan): https://gitlab.com/group18185918/geist-finance-ci/-/pipelines/2943999650
* First GitHub attempt (broken `FANTOM_RPC_URL` secret): https://github.com/kingmariano/ca-zombie-ci/actions/runs/38448429445

---

## 6. Verdict, residual/latent risk

### E-U — external unprivileged attacker: ≈ **$600 for a 1-week cycle** (~$260/week recurring) — confidence **medium-high**

**Path: farm the staking rewards with bought GEIST.** The Geist staking contract
(`MultiFeeDistribution 0x49c93a95…`) streams the protocol treasury's **aTokens** (aLINK, aCRV, aMIM,
aDAI, aETH, aWFTM) to GEIST stakers, and GEIST is freely buyable on the live DEX for ~$0.000012
(GEIST/WFTM pool: 375.7M GEIST / 66.7k WFTM). PoC (`poc/test/GeistStakingFarm.t.sol`,
fork-verified, 1/1 PASS):

1. buy **86.5M GEIST for 20,000 WFTM** (~$1,368) on SpookySwap;
2. `stake(amount, false)` (unlocked — withdrawable any time);
3. one week later `getReward()` → receives aTokens: **aCRV 2,987,227 nominal, aMIM 6,513,
   aDAI 14.57, aETH 0.000026, aLINK 0.00626, aWFTM 20,139 nominal**;
4. redeem them (`pool.withdraw`, capped by cash) and sell on Spooky+Spirit →
   **8,875.3 WFTM** (the aCRV redemption drains the *entire* 107,517 CRV cash — 98% of the aCRV
   supply sits in the staking contract, so any reward claim of that size is first-come-first-served
   and takes it all);
5. `withdraw()` the stake and sell the GEIST back → 19,938.5 WFTM (round-trip loss 61.5 WFTM).

**Net: +8,813.8 WFTM ≈ $603** (at FTM $0.0684) for one week, of which ≈ $344 is the one-time CRV
cash drain and ≈ $260/week is the recurring aMIM/aDAI/aETH/aLINK interest stream (the CRV cash does
not replenish). Capital is recoverable, so the only real cost is the GEIST round-trip slippage.
Scaling: buying ~200M GEIST (~$5.2k of WFTM, draining the pool) would give a ~34% share of the
stream. The path is *permissionless*, needs no legacy position, and works today
(`getReward()` is the live no-arg selector `0x3d18b912`; the array variant in the GitHub source is
not the deployed ABI).

### E-U — liquidation path: **$0** — confidence **high**

All 881 live borrowers with HF < 1 and non-zero collateral (from the full scan of 2,421 live
debtors) were screened against the live DEX prices (`analysis/screen_full.py`): the best
liquidation pair for each is either (a) collateral that is *more* over-valued by the frozen oracle
than the debt (e.g. repay WFTM r=1.6× to seize BTC r=64×), or (b) WFTM collateral whose aToken has
**zero cash** (seizure reverts / is worthless). The largest positions by realisable collateral
(USDC 997,708; fUSDT 9,293; BTC 17.6) all carry WFTM debt. **No pair yields > $1 of estimated
profit**; the observed best-PF pairs are dust-sized. The pooled realisable collateral across all
underwater positions is ≈ $101k, but none of it is reachable at a profit.

### H-O — aToken holders: ≈ **$115k** (DEX-realisable), first-come-first-served

Per-reserve split of aToken claims (full scan) vs cash: DAI 876.5k claims vs 632.7k cash; ETH 402.2
vs 488.3; BTC 86.6 vs 113.5; fUSDT 7.93M vs 7.63M; USDC 401.3k vs 469.8k; CRV 108.1M vs 107.5k;
MIM 1.49M vs 173.8k; LINK 6.56k vs 6.12k. Withdrawable holders can realise ≈ **$115k** when the
cash is dumped into the live pools (USDC $49k, fUSDT $29k, BTC $17k, ETH $7k, MIM $6k, DAI $4k,
LINK $1.5k, CRV $0.7k). Holders of aCRV (0.1% backed), aMIM (11.6%), aUSDC (31%) and aWFTM (0%)
cannot all be made whole.

### S — stuck: ≈ **$15k** + the whole WFTM market

The cash behind *underwater* borrowers' collateral is unreachable by anyone: those borrowers cannot
withdraw (HF≈0) and no rational liquidator will repay their (unprofitable) debt. That locks
≈ $8.4k of USDC, ≈ $5.2k of BTC and ≈ $1.6k of ETH of the cash. The WFTM market (8.25B nominal
aWFTM) has zero cash and is permanently unbacked.

### P — privileged: admin surface only

Freeze/unfreeze, pause, oracle sources and treasury sweeps sit behind a **3-of-5 Gnosis Safe**
(`0xC03253FF…`) and a **2-day Timelock** (`0x7FB9a7cB…`). Nothing of value is rescue-able only by
them.

**Residual/latent risk:** if Chainlink/Band ever resume (or the owner swaps oracle sources after the
timelock), the frozen prices move and the liquidation matrix changes; if the Multichain liquidation
(KPMG, Chapter 15 recognised 2025-12-08) distributes recovered assets, the anyToken DEX prices
re-rate and the whole cash stack is worth more. The staking-reward stream keeps accruing as long as
the markets accrue interest, so the ~$260/week farm yield persists until the aToken cash runs out.

---

## 7. Methodology, caveats, files

* Live state read directly from public Fantom RPCs (`rpc2/rpc3.fantom.network`,
  `rpcapi.fantom.network`, all keyless) with raw JSON-RPC (`analysis/read_state.py`,
  `analysis/scan_borrowers.py`); the CI `FANTOM_RPC_URL` secret was non-functional, so scans and
  tests fell back to the public endpoints (redacted-key discipline kept: no keys/URLs are written
  anywhere in this folder).
* Borrower universe: every address that ever received a variable-debt token in
  `[17,500,000, 65,236,380]` (the last `Borrow` event on the pool is block 65,236,379, 2023-07-06 —
  all live debt predates the freeze), checked for live balances via Multicall3 and priced with
  `getUserAccountData`. 16,039 candidates → **2,421 live debtors → 905 with HF<1 → 881 with HF<1 and
  collateral**.
* Prices: DefiLlama coins API (canonical vs chain-specific), CoinGecko FTM, and direct on-chain pool
  ratios on SpookySwap (factory `0x152eE697…`) and SpiritSwap (factory `0xEF45d134…`); realisable
  values measured with the live routers (`0xF491e7B6…`, `0x16327E3F…`).
* **Blockers / limitations:** (1) the frozen oracle is the only price source the protocol uses —
  everything above is at those prices; (2) local DEX prices are the only realisable market for the
  unbacked tokens — a Multichain liquidation distribution could re-rate them; (3) the 4 CI test
  failures in the first run were public-RPC HTTP 429s, not logic — all tests pass when re-run;
  (4) gas on Fantom is negligible and ignored; (5) the staking-farm yield shrinks as the aToken cash
  is consumed and depends on GEIST's DEX liquidity (pool holds 66.7k WFTM / 375.7M GEIST).

Files: `analysis/read_state.py` (reserve/oracle state) · `analysis/scan_borrowers.py` (borrower
scan) · `analysis/screen_full.py` (liquidation screen over all 881) · `analysis/locked_split.py`
(H-O/S split) · `analysis/liq_matrix.py` (profitability matrix) · `analysis/live-state.json` (raw
dump) · `poc/` (Foundry: 5 test files) · `ci/` (GitHub + GitLab CI scripts) · `ci-out/` (scan
results, artifacts) · `ci-log.txt` · `summary.json`.
