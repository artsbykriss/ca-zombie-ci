# Horizon Protocol (BSC) — L2 Phase-2 deep-dive (zombie-hunt II)

**Date:** 2026-10-15 · **Chain:** BSC (56) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Target:** Horizon Protocol — Synthetix v2 fork with multi-collateral "zAssets" (zUSD, zBNB, zBTC, …) on BSC.
**Triage row:** `l2-triage-a` — LIVE-FUNDED, $23,041 (WBNB 25.16 + BUSD 2.9k + PHB/HZN legs), DefiLlama frozen 2026-01-28.

---

## 1. TL;DR

| Target | Live extractable by a **fresh unprivileged attacker** | Why open / closed | Latent risk |
|---|---|---|---|
| `Synthetix.mint()` (HZN inflation; must call the **target** 0x0110bcBEB) | **$0.0556 per call** (200 HZN minter reward, measured swap-out), ≤1 call/week; net of gas (317,850 gas @ 0.05 gwei) ≈ **$0.044** | **OPEN** — system/issuance/exchange all *not* suspended; `isMintable()=true`, `mintableSupply()=382,482 HZN` | ~$2.3/yr; grows only if HZN price rises |
| Mint-triggered LP-staking distribution (50,000 HZN/mint) | **$0 for a fresh attacker** | Rewards are pro-rata to *staked* LP; existing stakers hold 30,734/36,760 LP (83.6%); adding matching LP ($18.8k) costs ~$47+ in swap fees vs $6.96 reward → negative EV | Existing stakers capture it (H-O) |
| `exchange()` synth↔synth at oracle (live, fee ~0.32%) | **$0** | No exit market for any zAsset (no DEX pair for any of the 26 synths on Pancake V2/V3, ApeSwap, BiSwap, MDEX, BabySwap, BakerySwap; DexScreener: none). zUSD itself only trades at $0.578 in one dead pair | Would become an arb if any synth market appears |
| zUSD/BUSD pair (2,901 BUSD + 5,020 zUSD) | **$0** | BUSD side only reachable by selling zUSD into it; zUSD cannot be minted (issuance blocked by invalid HZN oracle) and buying it on the same pair is circular | — |
| Liquidations (`flagAccountForLiquidation`, `liquidateDelinquentAccount`) | **$0** | HZN rate invalid (stale 102 d) → `Rate invalid` revert; also no flagged accounts | If HZN feed resumes → flagReward 100 HZN / liquidateReward 200 HZN |
| Shorts liquidation (`CollateralShort.liquidate`) | **$0** | `CollateralManagerState.totalLoans()==0` — no shorts exist | — |
| `RewardsDistribution.distributeRewards` | **$0** | `authority == Synthetix` → `Caller is not authorised` | Reachable only via `mint()` |
| `FeePool.claimFees`, `Synthetix.claimFees` | **$0** | `A zasset or HZN rate is invalid` (HZN stale) **and** no debt shares for a fresh account | 1.73 M HZN rewards for stakers if HZN rate returns |
| `SynthRedeemer.redeem` | **$0** | `redemptions[synth]==0` for all 26 synths; contract zUSD balance 0 | — |
| `Depot`, bridge, `LiquidatorRewards`, escrows, staking `getReward` | **$0** | Depot empty (0 deposits); bridge resolver cache broken (`Missing address: Issuer`); LiquidatorRewards needs debt shares (non-transferable); escrow `vest()` is self-only; all staking reward periods ended | Holder-only value below |

### Total live extractable now: **$0.0556 per weekly call** (200 HZN, net ≈ $0.044 after measured gas) — confidence **high**.

---

## 2. The mechanism in exact terms

Horizon Protocol is a Synthetix-v2 fork. The HZN token address `0xc0eff7749b125444953ef89682201fb8c6a917cd` is a
`ProxyERC20` whose `target()` is the **Synthetix system contract** `0x0110bcbeb89a43ec47e62d1980e29e0683745ffc`
(verified source "Synthetix", v0.5.16). The whole system hangs off its `AddressResolver`
(`resolver()` → ReadProxy `0x263a8220…` → `AddressResolver` `0xF505bfdB…`), from which 34 modules + 26 zAsset synths
were enumerated on-chain (see `analysis/resolver-enum.json`, `analysis/synth-enum.json`).

**Live payout:** `Synthetix.mint()` (`0x1249c65a`) has only the `issuanceActive` gate:

```solidity
function mint() external issuanceActive returns (bool) {          // anyone can call
    uint supplyToMint = _supplySchedule.mintableSupply();          // 382,482.095 HZN today
    require(supplyToMint > 0, "No supply is mintable");
    _supplySchedule.recordMintEvent(supplyToMint);
    uint minterReward = _supplySchedule.minterReward();            // 200 HZN
    uint amountToDistribute = supplyToMint.sub(minterReward);
    … tokenState.setBalanceOf(_rewardsDistribution, +amountToDistribute);
    _rewardsDistribution.distributeRewards(amountToDistribute);    // 50k HZN → LP staking, rest → FeePool/escrow
    tokenState.setBalanceOf(msg.sender, balanceOf(msg.sender).add(minterReward)); // ← pays the caller
    totalSupply = totalSupply.add(supplyToMint);
}
```

All three suspension flags are **false** (verified by calling `systemSuspension()/issuanceSuspension()/exchangeSuspension()`
and `requireSystemActive()/requireIssuanceActive()/requireExchangeActive()` — the latter three do not revert).
`SupplySchedule.isMintable() == true` (`lastMintEvent` 1,790,035,200; `weekCounter` 271; `minterReward` 200e18;
`mintableSupply()` 382,482.095333848763042906 HZN). After a mint, the schedule sets the next `lastMintEvent` on a fixed
weekly grid (INFLATION_START_DATE + weeks×1w + 1d buffer), so the next call is possible ~4.7 days later — i.e. **≈1 call/week**.

The 382,482 HZN minted per call is split: 200 to the caller; 50,000 (`0xa968163f0a57b400000`) to the HZN-BNB LP staking
`0x84838d0a…` via `notifyRewardAmount`; the remainder (332,282) to `RewardEscrowV2` `0x41b9784e…` and
`FeePool.setRewardsToDistribute`. The 50k LP-staking leg is captured pro-rata by whoever is *already* staked
(30,734.58 of 36,760.38 LP = 83.6% is staked by legacy stakers), so a fresh attacker cannot take it economically.

**Everything else is gated:**
* `issueSynths`/`issueMaxSynths`/`burnSynths*`/`claimFees` → `_requireRatesNotInvalid` fails because
  **HZN's oracle rate is stale/invalid** (`rateForCurrency("HZN")=0.000226127960682332`, `lastRateUpdateTimes=1783151104`,
  age ≈ 102 days > `rateStalePeriod` 90,000 s ⇒ `rateIsInvalid("HZN") == true`). Empirically: `issueMaxSynths()` and
  `burnSynths(1)` revert; `claimFees()` reverts "A zasset or HZN rate is invalid".
* Liquidations: `Liquidator.flagAccountForLiquidation` has `rateNotInvalid("HZN")` ⇒ revert `Rate invalid or not a synth`;
  `liquidateDelinquentAccount` reverts `Not open for liquidation`. (Rewards if it ever reopened: flagReward 100 HZN,
  liquidateReward 200 HZN, liquidationRatio 0.625, penalty 0.6.)
* Shorts: `CollateralShort` (`0x8af9d787…`) has 0 loans (`CollateralManagerState.totalLoans()==0`), so its permissionless
  `liquidate()` has no target.
* `SynthRedeemer` (`0x05af42bf…`): `redemptions[synth] == 0` for all 26 synths and its zUSD balance is 0 — no deprecated
  synth to redeem.
* `Depot` (`0x9b957b4a…`): `totalSellableDeposits == 0`, queue empty.
* `RewardsDistribution` (`0xceb49761…`): `distributeRewards` requires `msg.sender == authority` (= Synthetix) ⇒ revert.
* `LiquidatorRewards` (`0x05178294…`, holds 37.79 M HZN): `getReward(account)` escrows to *that account*; a fresh account
  has 0 debt shares and `earned()==0`. Debt shares (`SynthetixDebtShare`, 15,955.87 shares) are mintable only by the Issuer
  and non-transferable (`transfer()` returns false; `transferFrom` only by `authorizedBrokers`, all checked = 0).
* `RewardEscrowV2.vest()`/`SynthetixEscrow.vest()` are `msg.sender`-only; `mergeAccount` needs a nomination + zero debt.
* `SynthetixBridgeToOptimism` is broken at the resolver-cache level (`deposit(0)` → `Missing address: Issuer`,
  `forwardTokensToEscrow` → `Missing address: SynthetixBridgeEscrow`), and its escrow holds 0 HZN anyway.

---

## 3. Live-state assessment (all reads at blocks 127,661,950 – 127,685,324; PoC pinned 127,685,324)

**Architecture (resolver-enum.json, 34 names):** Synthetix 0x0110bcBEB, SynthetixState 0xf71eccf3,
SynthetixEscrow 0x073c0c42, BridgeToOptimism 0x4ceb5c49, BridgeEscrow 0x53f6de83, ExchangeRates 0x95a49608,
Exchanger 0x867e8a6f, ExchangeState 0xf1f5f738, Issuer 0x28410521, FeePool 0xb80f834f, FeePoolState 0x030f5773,
FeePoolEternalStorage 0x691d8959, SystemSettings 0x39989d41, SystemStatus 0x344b0854, SupplySchedule 0x45151b3b,
RewardEscrow 0x0c5db257, RewardEscrowV2 0x41b9784e, RewardEscrowV2Frozen 0xe21e39c3, RewardsDistribution 0xceb49761,
Liquidator 0x2a7b78b7, LiquidatorRewards 0x05178294, Liquidations 0x5bcdb400, DebtCache 0x730a8bcf, Depot 0x9b957b4a,
DappMaintenance 0x6376e713, CollateralManager 0xa7833a8e, CollateralManagerState 0xc7938c1f, CollateralUtil 0xade751b2,
SynthRedeemer 0x05af42bf, SynthUtil 0x02a73e55, FlexibleStorage 0xde644619, DelegateApprovals 0x9657a0fd,
EscrowChecker 0x2b17798c, ProxyERC20 0xc0eff774. Extra (resolver names probed): SynthetixDebtShare 0xf76c3784,
CollateralShort 0x8af9d787, WrapperFactory 0xa038172d, VirtualSynthMastercopy 0xcb09c97a, RewardEscrowV2Storage 0x3cc1109f.
Owner of every module: `0x81752bC7D54a45bdB9005223d61D2CBd33d04857` (EOA, P).

**Token balances of all system contracts** (`analysis/balances.json`, 707 direct `balanceOf` calls):
| Contract | Balance | USD (BNB $729.98, HZN $0.0002785) | Category |
|---|---|---|---|
| 0x84838d0a HZN-BNB LP staking | 2,104,009.57 HZN | $585.90 | H-O (legacy stakers) |
| 0x67d5a94f HZN staking | 194,711.58 HZN | $54.23 | H-O |
| 0xa1771dcf PHB staking | 10,937.53 HZN + 12,890.31 PHB | $3.05 + $167 | H-O |
| 0x5646aa2f zUSD-BUSD LP staking | 9,803.96 HZN | $2.73 | H-O |
| 0x41b9784e RewardEscrowV2 | 55,781,087.62 HZN | $15,533 | H-O (user vesting + FeePool rewards) |
| 0x05178294 LiquidatorRewards | 37,788,090.96 HZN | $10,523 | H-O (debt-share holders only) |
| 0xc0eff774 HZN proxy itself | 500 BUSD + 51,873.9 CAKE + 800 HZN | $723.6 | **S (stuck — no rescue path)** |
| 0x6a6677a9 staking-owner EOA | 175,000 HZN + 0.0631 BNB | $48.8 | P (EOA) |
| 0xdc9a574b HZN-BNB pair | 25.1551 WBNB + 65,942,549.8 HZN | $18,358 + $18,365 | LP-owned (83.6% staked in dead farm) |
| 0xc3bf4e0e zUSD-BUSD pair | 2,901.26 BUSD + 5,020.91 zUSD | $2,901 + $2,902 notional | LP-owned |
| FeePool / Depot / bridge escrow / old escrows / all other modules | **0** | $0 | — |

**Exchange/rate state:** all 26 synth rates live (Chainlink BSC feeds, ages 7 min – 5.3 h) and valid; zUSD fixed at 1e18;
HZN stale/invalid. `SystemSettings.rateStalePeriod = 90,000 s`. Exchange fee measured **0.32%**
(100 zUSD → 0.1369515 zBNB vs 0.1373931 no-fee).

**LP pair prices:** HZN = 3.8147e-7 WBNB ≈ **$0.0002785** (cross-checked against WBNB/USDT $729.98 and zBNB oracle $727.84);
zUSD/BUSD pair implies **$0.5778/zUSD**; HZN-BNB LP supply 36,760.38, of which 30,734.58 (83.6%) staked.

---

## 4. What a fresh unprivileged attacker can / cannot do

**Can (the only live path):**
1. Call `Synthetix.mint()` **directly on the target `0x0110bcBEB`** — no roles, no whitelist, zero legacy position.
   (Note: `mint()` credits `msg.sender`, so calling via the `ProxyERC20` 0xc0eff774 credits the *proxy address* instead —
   that is why 800 HZN is sitting stuck at the proxy today. The correct call is on the target.)
2. Receive `minterReward = 200 HZN` immediately (`tokenState` credited to `msg.sender`), minting 382,482.095 HZN of new supply.
3. Sell the 200 HZN on the HZN-BNB Pancake V2 pair for ~0.0000763 WBNB (~$0.0557) — price impact negligible
   (200 vs 65.9 M HZN reserve).
4. Repeat at most once per ~week (supply schedule). Gas at 0.05 gwei ≈ 700 k ⇒ ~$0.025 ⇒ **net ≈ +$0.03/call**.

**Cannot (all empirically verified via `eth_call` simulations from fresh EOAs — see `analysis/revert-proofs.json`):**
`issueSynths`/`issueMaxSynths` (rate invalid), `burnSynths` (rate invalid), `claimFees` (rate invalid),
`liquidateDelinquentAccount` (not open for liquidation), `flagAccountForLiquidation` (HZN rate invalid),
`SynthRedeemer.redeem` (nothing deprecated), `RewardsDistribution.distributeRewards` (authority only),
`CollateralShort.liquidate` (no loans), `Depot.exchangeEtherForSynths` (empty queue — succeeds, returns 0),
staking `getReward()` (pays 0 to fresh accounts), `SynthetixBridgeToOptimism.deposit` (broken resolver cache),
`LiquidatorRewards.getReward` (0 for fresh accounts).
**Cannot** extract the LP pairs: 25.16 WBNB + 2,901 BUSD are AMM liquidity owned by LPs; the only way to take BUSD out of
the zUSD/BUSD pair is to sell zUSD into it, and zUSD cannot be minted (issuance blocked) nor acquired below the pair's own
price (circular). **Cannot** farm the mint distribution: existing stakers hold 83.6% of the LP; a matching $18.8k LP
position would cost ≈$47 in round-trip swap fees to farm ≈$6.96.

---

## 5. PoC / fork verification

`poc/` — Foundry project. CI forks at the latest block (public RPCs prune old state); local reads were pinned at
BSC block **127,685,324** (timestamp 1,792,021,702) and re-verified at 127,738,226.
Tests (`poc/test/HorizonLive.t.sol`, 11 tests):
1. `test_mint_live_extraction` — fresh EOA, 0 HZN before; `mint()` **on the target** succeeds; asserts exactly 200e18 HZN received; logs gas.
2. `test_mint_via_proxy_pays_proxy` — calling `mint()` via the ProxyERC20 credits the proxy (reward stuck), not the caller.
3. `test_mint_reward_sellable_for_wbnb` — sells the 200 HZN on PancakeSwap V2; asserts WBNB (ERC20) out > 0.
4. `test_issuance_blocked` — `issueMaxSynths`, `burnSynths`, `claimFees` all revert (logged reasons).
5. `test_liquidations_blocked` — `flagAccountForLiquidation`, `liquidateDelinquentAccount` revert.
6. `test_synth_redeemer_dead` — `redeem(zUSD)` reverts.
7. `test_distribution_authority_only` — `distributeRewards(1e18)` reverts "Caller is not authorised".
8. `test_no_short_loans` — `CollateralManagerState.totalLoans() == 0`.
9. `test_fresh_staker_zero_rewards` — `earned(fresh)==0`; `getReward()` pays 0.
10. `test_exchange_works_but_no_exit_market` — exchange zUSD→zBNB succeeds; `getPair(zBNB, WBNB/BUSD/USDT/BTCB)==0`.
11. `test_mint_distribution_context` — logs the LP staking rewardRate/periodFinish change caused by the mint.

CI: `bash ci/ci-run.sh horizon-protocol` → GitHub Actions `artsbykriss/ca-zombie-ci` (`poc.yml`).
Results: **see `ci-log.txt` / `ci-artifacts/`** (run URL recorded there and in `summary.json`).

---

## 6. Verdict, residual & latent risk

* **E-U (fresh unprivileged): $0.0557/week** (200 HZN minter reward; net ≈ $0.03 after gas) — confidence **high**.
  This is the *only* permissionless function on BSC that pays a caller today.
* **H-O (legacy holders/stakers):** ~$16.5k of HZN-denominated claims (escrow vesting $15.5k + LiquidatorRewards $10.5k +
  staking rewards $0.65k; HZN price $0.000278, exit liquidity ≈ 25 WBNB — realizable value is far lower) plus 12,890 PHB
  ($167) and ~$31k notional of LP tokens (realizable ≈ the 21 WBNB side ≈ $15.3k).
* **P (owner EOA 0x81752bC7 / 0x6a6677a9):** all admin functions + 175,000 HZN.
* **S (stuck):** 500 BUSD + 51,873.9 CAKE + 800 HZN at the HZN proxy address (no rescue function); zUSD-BUSD pair's zUSD
  side (LP-owned, unredeemable).
* **Latent risks (not live now):**
  1. If the HZN Chainlink feed resumes (or the owner pushes a fresh HZN rate), the following become live:
     staker `claimFees` (1.73 M HZN rewards + 332 k HZN/mint inflow), liquidations (100/200 HZN rewards), and issuance.
     Given HZN's ~$0.0003 price, even then the extractable amount stays in the tens of dollars.
  2. `mint()` will keep paying 200 HZN/week to anyone while the schedule allows (post-week-234 terminal inflation
     ~2.5%/yr of supply). If HZN ever gains value/liquidity, this becomes a real (if small) weekly extraction.
  3. The `exchange()` surface is live with accurate oracles; if any zAsset market appears (or the old zUSD/BUSD pair is
     used as an exit), a zUSD discount-arb (up to ≈$286 from the pair's BUSD side) would open.

**Blockers that close the big paths:** invalid HZN rate (issue/burn/claim/liquidate), zero short loans, empty Depot,
no deprecated synths, non-transferable debt shares, self-only escrow vesting, broken bridge resolver cache.

---

## 7. Methodology & sources

* All state read on-chain via public BSC RPCs (`bsc-dataseed*.defibit.io`, `*.ninicoin.io`, publicnode, blastapi) —
  no keyed endpoints in any file. Every claim has an address + block + call in `analysis/`.
* Verified sources pulled from Etherscan V2 (`chainid=56`) into `analysis/sources/` (52 contracts).
* Decompiled/ABI cross-checks for the modules not covered by the resolver (`SynthetixDebtShare`, `CollateralShort`,
  `WrapperFactory`, `VirtualSynthMastercopy`, `RewardEscrowV2Storage`).
* Empirical closure: `eth_call` simulations from fresh EOAs (`analysis/revert-proofs.json`) + Foundry fork PoC (CI).
* DEX-market sweep for all 26 synths: Pancake V2/V3, ApeSwap, BiSwap, MDEX, BabySwap, BakerySwap + DexScreener
  (`analysis/child-dex/`, `analysis/synth-pairs.json`).

**Caveats & limitations**
* USD figures use on-chain market prices at the pinned block (BNB $729.98 from WBNB/USDT; HZN $0.0002785 from the
  HZN-BNB pair; zBNB oracle $727.84). HZN-denominated balances are *notional*: selling them into the 25-WBNB pool
  would crash the price, so realizable H-O value is much lower.
* `mint()` gas is estimated (~700 k); the PoC logs the exact figure in CI.
* One market-sweep caveat: synths may have additional legacy proxy addresses (zUSD has two: 0x7f11125a registered and
  0xf0186490 in the pair). The sweep covers the registered addresses + symbol search + the known alt proxy.
* The protocol's own subgraph and website are dead; the DefiLlama $233k "frozen" figure is not reproducible on-chain
  (its collateral leg came from a dead subgraph; the Synthetix contract holds 0 HZN collateral).

**Files index:** `README.md`, `summary.json`, `analysis/` (rpc helpers, resolver/synth/state/balance dumps, revert proofs,
sources/abis, child-dex market sweep), `poc/` (Foundry), `ci/` (CI verify job), `ci-out/`, `ci-log.txt`, `ci-artifacts/`.
