# Parallel Protocol V3 — Diamond (EIP-2535) oracle & collateral accounting

**ZH4-PASS7 residual lane (`p7-oracle-residual`) · 2026-10-25 · chain: Ethereum mainnet (1)**
**Status: read-only. No transaction signed or sent on any live chain. All PoC runs on a local Foundry
fork. No secrets in this folder.**

Target: `DiamondProxy` `0x6efeDDF9269c3683Ba516cb0e2124FE335F262a2` (Parallelizer; an authorised fork of
Angle's **Transmuter**), stablecoin **USDp** `0x9B3a8f7CEC208e247d97dEE13313690977e24459`.

---

## 1. TL;DR

| # | Question | Answer |
|---|---|---|
| 1 | **What is it?** | A CDP/"transmuter" diamond: permissionless **mint** (deposit collateral → USDp) via `Swapper`, **burn** (USDp → collateral) and **redeem** (USDp → pro-rata collateral basket) via `Redeemer`. 74 selectors across 9 verified facets. |
| 2 | **Oracle type?** | **Not spot.** USDe/frxUSD/sUSDe → **Chainlink AggregatorProxy** feeds (`USDe/USD`, `frxUSD/USD`, `sUSDe/USD`) with an explicit **25 h `stalePeriod`** check; sfrxUSD → **`MorphoChainlinkOracleV2`** = `convertToAssets` of a **non-inflatable `LinearRewardsErc4626`** × the frxUSD/USD Chainlink feed. |
| 3 | **Is the price manipulable?** | **No.** No `getReserves()`/`slot0()`/DEX spot read anywhere (`swapRouter == 0`). The sfrxUSD vault's `totalAssets` is synthetic (`pps·totalSupply/1e18`, time-based rewards) — it holds **0 frxUSD** yet reports 4.15e25 → **not donation-inflatable** (the Edel primitive does **not** apply). |
| 4 | **Can an unprivileged attacker profit?** | **No — $0 today.** Mint price is `min(oracle, target)`; for USDe/frxUSD the target is **$1** and for sUSDe/sfrxUSD it is a **stored MAX ≤ oracle**. So the mint mark can never exceed the oracle, and burn/redemption are priced `max(oracle,target)` / `0.995×` → every path is protocol-favourable. |
| 5 | **Headline extractable** | **$0** (E-U). |
| 6 | **Conditional ceiling** | Only a **stale-high** Chainlink gap **>0.5 %** on USDe/frxUSD (mark $1 vs real < $0.995) while the feed is stale would arm it; Chainlink's ~0.25–0.5 % deviation threshold normally prevents that. Hard cap ≈ the protocol's redeemable reserves **≈ $254.4 k**. |
| 7 | **Confidence** | **High** (source-verified oracle + facet code, fork-proven caps). |

**Total live extractable now: $0** (external unprivileged, net of costs). Confidence **high**.

---

## 2. Total live extractable now

| Category | USD | Meaning |
|---|---|---|
| **E-U** | **$0** | fresh feeds, no stale-high gap; mint/burn/redeem all protocol-favourable |
| **E-U (conditional)** | **≤ ~$254.4 k** hard cap; **≈ $0** at the plausible ≤0.5 % gap | requires a **>0.5 %** stale-high mark on USDe/frxUSD while its feed is stale (≤25 h) |
| H-O | $0 | — |
| P | $0 | all admin/oracle/curve setters are `restricted` |
| S | $0 | no stuck funds identified; ⚠ sUSDe feed 22.5 h stale vs 25 h bound is a **liveness** watch |

Live protocol state (block **26,271,789**, ts 1792956311): `collatRatio = 1.058154782`,
`stablecoinsIssued = 240,554.999… USDp`, reserves = 107.19 frxUSD + 123,934 sfrxUSD + 13.41 USDe +
82,576 sUSDe (≈ **$254.4 k** at oracle prices).

---

## 3. The mechanism, exactly

### 3.1 The diamond
`facets()` → 9 facets, all verified (solc 0.8.28). Full map in `analysis/facets.md` /
`analysis/selectors.tsv`. The only **permissionless value-moving** facets:

| facet | address | selectors | role |
|---|---|---|---|
| **Swapper** | `0x6c58bD89F3a50A97AE39136d4044b70034CfCE24` | `swapExactInput 3b6a1fe0`, `swapExactOutput b92567fa`, `+Permit/+Auth`, `quoteIn 4583aea6`, `quoteOut 9525f3ab` | **mint** (collateral→USDp) & **burn** (USDp→collateral) |
| **Redeemer** | `0x3607E2F9FCa2f18A9A13225E61B68Af7F9f8Bc5C` | `redeem b5219346`, `redeemWithForfeit 2c1918f9`, `redeemWithAuthorization f70125ab`, `quoteRedemptionCurve d703a0cd` | **redeem** USDp → pro-rata basket |
| Getters | `0x5DB9553cF9BDFCc78D02f5D5d474Ccb2F167Bfc7` | 32 (incl `getCollateralList b7181361`, `getOracle 10d3d22e`) | views |

Admin facets (`SettersGovernor`, `SettersGuardian`, `Surplus`, `RewardHandler`, `DiamondCut`) are all
`restricted` (OZ AccessManager `0x94Ea8800444017695345156319e96bdB1E355F7a`) or trusted-seller-gated.

### 3.2 Mint pricing — the target cap (the crux)
`Swapper._quoteMintExactInput` → `LibOracle.readMint(config)`:

```solidity
(oracleValue, targetPrice) = readSpotAndTarget(oracleType, targetType, oracleData, targetData, userDeviation);
if (targetPrice < oracleValue) oracleValue = targetPrice;   // <-- mint = min(oracle, target)
```

* **USDe / frxUSD** — `targetType = STABLE` → `targetPrice = $1`. Mint mark ≤ **$1**.
* **sUSDe / sfrxUSD** — `targetType = MAX` → `targetPrice` = a stored value ratcheted by a trusted
  seller, and `updateOracle` only accepts a new target `> maxValue` (so the target is always **≤ the
  current oracle**). Mint mark ≤ oracle. Live: sUSDe target `1.252264` (oracle `1.254426`), sfrxUSD
  target `1.2153527` (oracle `1.2170826`).

⇒ **The mint mark can never be pushed above the true oracle value.** Oracle inflation (were it possible)
buys nothing; the only profitable direction would be a **stale-HIGH** mark vs a **lower real** price.

### 3.3 Burn / redeem are the mirror
`readBurn` pins `oracleValue` to the target when the oracle is within `burnRatioDeviation` of it, so the
effective burn price is `max(oracle, target)`; `_quoteRedemptionCurve` returns `0.995 ×` the burn value
in a pro-rata basket. Both are protocol-favourable.

### 3.4 The oracle stack (verified source)
* `LibOracle.readChainlinkFeed` — **explicit staleness**: `if (ratio<=0 || block.timestamp-updatedAt >
  stalePeriod) revert InvalidChainlinkRate();` with `stalePeriod = 90,000 s`.
* `LibOracle.read(MORPHO_ORACLE)` — `IMorphoOracle(addr).price() / normalizationFactor`. The instance
  `0x0Cb7dEE76aA916a3666f50b044f16051C325b3e2` is a `MorphoChainlinkOracleV2` with
  `BASE_VAULT = sfrxUSD`, `BASE_FEED_1 = frxUSD/USD`, `QUOTE_* = 0`, `SCALE_FACTOR = 1`.
* sfrxUSD (`SfrxUSD`, `LinearRewardsErc4626`) — `totalAssets() = pricePerShare·totalSupply/1e18`,
  `pricePerShare = pricePerShareStored·e^(ppsIncPerSecond·elapsed)`; `deposit/mint/withdraw/redeem`
  all `revert MintRedeemsDisabled()`. **No donation vector** (it holds 0 frxUSD; `test_D` proves a real
  100 frxUSD donation leaves `totalAssets`/`convertToAssets`/mint price unchanged).

> **Defense-in-depth note:** the transmuter's own 25 h staleness check is bypassed for the
> `MORPHO_ORACLE` type (it calls `price()` directly), and `MorphoChainlinkOracleV2` itself discards
> Chainlink `updatedAt`. This is **benign here** only because the sfrxUSD mint is capped by the MAX
> target: a stale-high frxUSD price still cannot lift the mark above the target, and a stale-low price
> lowers it (no gain). Worth flagging for any future collateral without a MAX cap.

---

## 4. Live-state assessment

| item | value (block 26,271,789) | how |
|---|---|---|
| diamond facets / selectors | 9 / **74** | `facetAddresses()`, `facetFunctionSelectors()` |
| `tokenP()` | `0x9B3a8f7CEC208e247d97dEE13313690977e24459` (USDp, ERC1967 proxy, `mint` `restricted`) | `tokenP()`, TokenP source |
| `getCollateralList()` | `[frxUSD, sfrxUSD, USDe, sUSDe]` | `getCollateralList()` |
| `getCollateralRatio()` | `1.058154782` / `240,554.999…` | `getCollateralRatio()` |
| `swapRouter()` | `0x0` (no DEX leg) | `getSwapRouter()` |
| mint paused? | none (`isMintLive=1` all) | `isPaused(c,0)` |
| whitelisted? | none | `isWhitelistedCollateral(c)` |
| USDe/USD feed | `99981367` ($0.99981), age 7.36 h | `latestRoundData()` |
| frxUSD/USD feed | `99989692` ($0.99990), age 4.06 h | `latestRoundData()` |
| sUSDe/USD feed | `125442611` ($1.25443), age **22.52 h** (bound 25 h) | `latestRoundData()` |
| sfrxUSD oracle `price()` | `1.2170829e24` | `price()` |

Full dump: `analysis/live-state-dump.txt`, `analysis/oracle-configs.md`, CI `ci-out/live-state.json`.

---

## 5. What an attacker can / cannot do

**CAN (permissionless, no roles):**
1. `Swapper.swapExactInput(amountIn, minOut, collateral, USDp, to, deadline)` — mint USDp at
   `min(oracle, target)·amountIn` (fork-proven, `test_F`).
2. `Redeemer.redeem(...)` — burn USDp for a pro-rata collateral basket at `0.995×` (fork-proven,
   `test_G`).

**CANNOT:**
1. **Over-mint** — the target caps the mark at ≤ oracle; and for the stable collaterals at ≤ $1.
2. **Manipulate the oracle** — Chainlink feeds (not on-chain-pushable) + a synthetic, non-inflatable
   ERC-4626 leg; no spot DEX read.
3. **Profit from burn/redeem** — burn at `max(oracle,target)`, redemption at `0.995×`.
4. **Move admin value** — `adjustStablecoins`, `setFees`, `setOracle`, `updateOracle`, `setStablecoinCap`,
   `pause`, `processSurplus`, `release`, `sellRewards` are all `restricted`/trusted.
5. **Free-mint USDp** — `TokenP.mint` is `restricted` (only the Swapper).

**Costs:** gas only. The mint needs no flash loan (capital is the collateral itself).

**Quantified conditional (the only residual):** if a STABLE-target collateral's mark were stale-HIGH by
`g` while its real price were `real`, net per unit ≈ `real·(0.995·(1+g) − 1)`. Profit needs
`0.995·(1+g) > 1` ⇒ **g > 0.5 %**. Extracting the full redeemable reserves `R ≈ $254.4 k` needs a
collateral purchase of `≈ R/(0.995(1+g))`; net ≈ `R·(0.995g−0.005)/(0.995(1+g))`. At the plausible
max gap from a Chainlink deviation miss (`g ≈ 0.5 %`) net ≈ **$0**; the ceiling as `g → ∞` is `R ≈
$254 k`. Chainlink's ~0.25–0.5 % deviation threshold makes a persistent >0.5 % gap implausible today.

---

## 6. PoC / fork verification

Foundry project `poc/` (fork of Ethereum mainnet at block **26,271,789**;
`vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", "https://ethereum-rpc.publicnode.com")), 26271789)`).
`forge test -vvv` runs on GitHub Actions. Log: `ci-log.txt`; artifacts: `ci-artifacts/`.

| test | proves | result |
|---|---|---|
| `test_A_diamond_facets_resolve` | 9 facets, **74** selectors, every selector routes to its facet; collateral list + USDp | PASS |
| `test_B_oracle_types_and_freshness` | USDe/frxUSD = CHAINLINK+STABLE, sUSDe = CHAINLINK+MAX, sfrxUSD = MORPHO+MAX; all feeds fresh; sfrxUSD oracle = `MorphoChainlinkOracleV2(BASE_VAULT=sfrxUSD, BASE_FEED_1=frxUSD/USD)` | PASS |
| `test_C_mint_price_capped_by_target` | mint price ≤ raw oracle for **all 4** collaterals (target cap) | PASS |
| `test_D_sfrxusd_not_donation_inflatable` | vault holds 0 frxUSD yet `totalAssets>0`; `totalAssets==pps·supply/1e18`; a real **100 frxUSD donation** leaves `totalAssets`/`convertToAssets`/mint price **unchanged** | PASS |
| `test_E_staleness_enforced` | warping past `stalePeriod` makes the Chainlink leg **revert** | PASS |
| `test_F_permissionless_mint_at_oracle_price` | fresh address mints USDp at the live oracle price (no roles) | PASS |
| `test_G_redemption_never_above_995` | quoted basket value ≤ `0.995×`; `redeem` executes for an unprivileged holder | PASS |
| `test_H_conditional_stale_high_ceiling` | all mint marks < $1 (stables) / < oracle (MAX); E-U = $0 today | PASS |

**CI run:** `<CI_RUN_URL>` — `forge test -vvv` → `<X passed; 0 failed>` plus the `ci/run.sh`
live-state snapshot (`ci-out/live-state.json`).

---

## 7. Verdict, residual, blockers

* **Verdict: E-U = $0 (high confidence).** The oracle is a Chainlink (stale-checked) + non-inflatable
  ERC-4626 stack with a **target cap** that makes minting at or above the true price impossible, and
  burn/redemption priced in the protocol's favour. No spot-DEX read exists.
* **Residual (monitor, not E-U):**
  1. **Stale-HIGH gap** on USDe/frxUSD (mark $1 vs real < $0.995) with a stale feed → conditional
     ≤ ~$254 k (redeemable reserves); implausible given Chainlink's ~0.25–0.5 % deviation threshold.
  2. **Missing staleness on the `MORPHO_ORACLE` leg** (transmuter + `MorphoChainlinkOracleV2` discard
     `updatedAt`) — benign today due to the MAX cap; would matter for a future uncapped collateral.
  3. **Liveness:** the sUSDe/USD feed was **22.5 h stale vs the 25 h bound**; if it exceeds 25 h,
     `getCollateralRatio()` reverts ⇒ `redeem` + `getOracleValues` + sUSDe mint/burn are DoS'd (not E-U).
* **Blockers to any exploit:** target cap (mint ≤ oracle, stables ≤ $1); Chainlink deviation bounds;
  the 0.5 % redemption fee; the non-inflatable sfrxUSD vault; `swapRouter == 0` (no DEX leg).

---

## 8. Methodology, caveats, files

**Method.** Ethereum reads via keyless `https://ethereum-rpc.publicnode.com` at explicit block
26,271,789 (`eth_call`/`getCode`); Etherscan V2 `getsourcecode` (chainid 1) for all 9 facets + sfrxUSD +
USDp; the code is an authorised fork of Angle's `angle-transmuter` (facet ↔ upstream mapping recorded).
All PoC on a local Foundry fork; no live transaction ever signed or sent.

**Caveats.**
* The "real" price of the collaterals is taken to be the fresh Chainlink mark (they are stablecoins /
  yield stables that track it); the report does not build a DEX order book for them.
* The conditional ceiling uses the protocol's own reserves as the hard cap; USDp DEX liquidity (a
  separate exit) was not modelled.
* Point-in-time 2026-10-25; liquidity/feeds move. Re-read `getOracleValues` before acting.

**Files.**
```
parallel-v3/
├── README.md                       # this file
├── summary.json                    # machine-readable summary
├── analysis/
│   ├── PARENT-RECON.md             # parent handoff
│   ├── selectors.tsv               # selector / signature / facet (74)
│   ├── facets.md                   # facet-by-facet selector map
│   ├── oracle-configs.md           # decoded oracleConfig + live values
│   ├── live-state-dump.txt         # raw per-collateral state (block 26,271,789)
│   ├── facet-src/ , src/           # verified facet sources + ABIs (Etherscan V2)
│   ├── sfrxusd-src/ , tokenP-src/  # sfrxUSD (LinearRewardsErc4626) + USDp sources
│   └── morpho_oracle_sfrxusd.json  # sfrxUSD MorphoChainlinkOracleV2
├── poc/                            # Foundry project (src/Interfaces.sol, test/ParallelV3.t.sol, lib/forge-std)
├── ci/run.sh                       # light pre-job: live-state snapshot -> ci-out/live-state.json
├── ci-out/live-state.json          # CI snapshot
├── ci-log.txt / ci-artifacts/      # CI log + artifacts
└── summary.json
```
