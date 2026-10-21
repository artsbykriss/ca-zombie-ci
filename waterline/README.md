# Waterline Reservoir (Ethereum) — the HF 1.0057 position is a mark-to-model artifact; live E-U **$0.00**

**Date:** 2026-10-21 · **Chain:** Ethereum · **Block:** 26,241,741 (ts 1,792,594,931)
**Status:** read-only; PoC fork-verified only; no mainnet transactions signed or sent.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent / conditional |
|---|---|---|---|
| **Waterline Reservoir USDC** (`0xBEeFF0…6210`) + Agua collateral market (`0x167f1d…9ec8`) | **$0.00** | The collateral oracle is a pure, immutable `convertToAssets()` of a **monotone rate accumulator** — it has no write-down path. The $5.10M borrower's HF is **1.00638** and **improving** (collateral 10.01% APY vs borrow 9.22%). Even if forced below 1.0, the 2.617% liquidation bonus is smaller than the 5% instant-exit fee, and the 5-day queue is unfunded ($30.00 USDC on-chain). | **$133.6k** liquidation bonus only if HF crosses **and** the Agua vault is funded / early fee <2.62% (both admin-controlled). **$11.52M** Agua NAV is admin-custodied and **$13.08M** Reservoir is curator-controlled — P/S, not E-U. |

**Total live extractable now: $0.00 — confidence: high.**

The pass-3 lead's premise ("a 0.57% NAV write-down liquidates $5.1M") is **not implementable on-chain**: no function can lower `cumulativeRateFactor`, the oracle has no setter, and the vault's share price is independent of its token balance. The real risk is custodial: the Agua admin EOA has withdrawn **$28.38M gross** (52 `AdminWithdraw` events, last **$218,500 at block 26,241,779**) and the vault contract itself holds **$30.00**.

---

## 2. Total live extractable now

| Category | USD | Basis |
|---|---:|---|
| **E-U (external unprivileged)** | **$0.00** | No oracle write path; no profitable liquidation; no discounted agua venue |
| E-U conditional | $133,643 | 2.617% × $5.107M repaid, only under admin-controlled preconditions (below) |
| H-O (holder-recoverable) | $13,077,199.94 | Reservoir VaultV2 depositor claims (self-service `withdraw`, subject to adapter liquidity) |
| P (privileged) | $11,524,507.06 | Agua `adminWithdraw`/`setRate` (ADMIN_ROLE EOA `0x086e…`) over the off-vault NAV; Reservoir owner/curator allocation over $13.08M. Overlaps S — not additive |
| S (stuck/bricked) | $11,524,507.06 | Agua NAV not redeemable: $11,524,537.06 synthetic − $30.00 on-chain |

---

## 3. The mechanism, in exact terms

### 3.1 The market

The Reservoir VaultV2 `0xBEeFF047C03714965a54b671A37C18beF6b96210` has one adapter (`0x5e7c120c8b1d3bD1EeB2C757dEF0E0F74272c6f0`, `MorphoMarketV1AdapterV2`) pointing at Morpho Blue `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb`, with two markets. The one at issue:

| Field | Value |
|---|---|
| Market id | `0x167f1d100200e7b7348a82f81e556f4f6c0271d79532073e57630ad9781a9ec8` |
| Loan | USDC `0xA0b8…eB48` |
| Collateral | Agua `0xa98b4A70E17e55045CDE4972B95Bc2E8CEC22a0F` (`aguaUSDCgc`) |
| Oracle | `0x47c1699bcef8944DA8B6a687c0FC22dD49b143A3` (`MorphoChainlinkOracleV2`, immutable) |
| IRM / LLTV | `0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC` / **91.5%** |
| Supply / borrow | $5,683,174.90 / $5,195,190.65 → **$487,984.25 borrowable** |
| Utilisation | 91.41% → borrow APY **9.2182%** |

### 3.2 The oracle is monotone — there is no write-down

`MorphoChainlinkOracleV2.price()` calls `VaultLib.getAssets(BASE_VAULT, sample)`, which is `BASE_VAULT.convertToAssets(sample)`. The deployed immutables are `BASE_VAULT = 0xa98b4A70…`, `BASE_FEED_1 = BASE_FEED_2 = QUOTE_FEED_1 = QUOTE_FEED_2 = 0`, `SCALE_FACTOR = 1e16`. There is **no owner, no setter, no update function** — the oracle is a pure function of the Agua vault.

The Agua vault (`OpportunityOVault`, verified, non-proxy) computes:

```
totalAssets = totalSupply * _getCurrentRateFactor() / RAY
_getCurrentRateFactor() = cumulativeRateFactor * e^(currentRate * dt)
```

- `cumulativeRateFactor` is only ever **multiplied** by a growth factor ≥ 1 (`agua.sol:536`). There is no assignment that decreases it.
- `setRate(newRate)` (ADMIN_ROLE) first accrues to now, then changes only the **future** `currentRate`. It cannot lower the level.
- `_lzReceive` state syncs can also only set `currentRate` (future growth), never the accumulator.
- Deposits, `redeemEarly`, and donations do not change `convertToAssets()`: the price is independent of `totalSupply` and of the token balance.
- `adminWithdraw` moves tokens but does **not** change `totalAssets` (which is synthetic), so it cannot move the oracle either.

Consequence: the collateral price can only go **up**. Over 30 days the fork measured `1.03397132 → 1.04210296` (+0.785%). The "0.57% write-down" that would liquidate the $5.10M borrower has **no on-chain trigger**.

### 3.3 The near-threshold position

Borrower `0x81A4470b461a6b205871298A32d761A1D66649c9` (EOA):

| Metric | Value |
|---|---:|
| Borrow shares | 5,060.411401756593232 |
| Debt | **$5,103,656.09** |
| Agua collateral | 5,428,944.749195943588 shares |
| Collateral value | **$5,613,373.17** |
| LTV / LLTV | 90.9196% / 91.5% |
| **HF** | **1.0063837296** |
| Buffer to liquidation | **0.6343%** |
| Liquidation incentive (LIF) | 1.026167 → **$133,549** on full debt |

The borrower also holds **880,431.319081096991983909 agua** ($910,258.60) **outside** the Morpho collateral. Adding it would lift HF above 1.1 immediately; the position is self-curable and not distressed.

At the current rates the position is **improving**: collateral accrues 10.0072% APY, debt 9.2182%, net +0.79%/yr. The buffer is thin but the sign is positive. If the Agua admin set the rate to 0, the buffer would be crossed in ~25.1 days at the current borrow rate; if an attacker pushed utilisation to 100%, the borrow APY would be ~28.1% and the buffer would cross in ~12.8 days — but the borrower's 880k spare agua cures it, and the attacker would need ~$533k of agua collateral minted at par into the unfunded vault.

---

## 4. Live-state assessment (all at block 26,241,741)

### 4.1 Contracts and roles

| Contract | Address | Type | Key facts |
|---|---|---|---|
| Reservoir VaultV2 | `0xBEeFF047C03714965a54b671A37C18beF6b96210` | verified, non-proxy | `totalAssets` $13,077,199.94; `totalSupply` 12,693,010.5346; PPS 1.030267; owner `0x5c48Cffd…` (15,661-byte contract); curator `0xC5fA35a7…` (345-byte contract) |
| Adapter | `0x5e7c120c8b1d3bD1EeB2C757dEF0E0F74272c6f0` | verified, non-proxy | `realAssets` $13,077,199.94; 2 markets |
| Agua vault | `0xa98b4A70E17e55045CDE4972B95Bc2E8CEC22a0F` | verified, non-proxy | `totalAssets` $11,524,537.06; `totalSupply` 11,145,896.2053; `cap` $12.5M; **USDC balance $30.00** |
| Oracle | `0x47c1699bcef8944DA8B6a687c0FC22dD49b143A3` | verified, non-proxy | `price` 1.03397132e24; all feeds zero; `SCALE_FACTOR` 1e16 |
| Morpho Blue | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | canonical | market `0x167f1d…9ec8` |

**Agua roles:** `DEFAULT_ADMIN_ROLE` = `0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69` (49-byte contract). `ADMIN_ROLE` = that contract **and `0x086eb9c2b14dd657ae77d07df9115a2f946ce327` (plain EOA, code size 0)**. The EOA can call `setRate` and `adminWithdraw(token, amount, receiver)` with **no timelock and no cap**.

### 4.2 The custody reality

`AdminWithdraw(address indexed token, address indexed receiver, uint256 amount)` logs on the Agua vault:

- **52 events, all USDC, all to the ADMIN EOA `0x086eb9c2…`**
- **Gross $28,375,717.34** between block 25,352,995 (2026-06-19) and block **26,241,779 (2026-10-21 15:09:47 UTC)**
- The last withdrawal was **$218,500** — 38 blocks after the fork block
- The vault contract itself holds **$30.00**; the admin EOA holds **$0.001552** (the funds were moved further; destination not traced in this pass)

So the "request-only vault" is a **custodial IOU**: the NAV is an admin-managed rate, the real USDC is off-contract, and the only on-chain exit liquidity is $30. This is the source of the S/H-O risk — but it is not an unprivileged attacker's lever.

### 4.3 Exit costs

| Path | Result |
|---|---|
| `redeemEarly(shares, receiver, 0)` | 5% fee (`earlyRedemptionFee = 500`); atomic net on a 2.617% bonus = **−2.514%** |
| `requestRedemption(shares)` → 5-day lockup (`432000 s`) → `completeRedemption` | fee-free, but pays from the vault's USDC balance ($30.00); reverts for any material size |
| `redeem` / `withdraw` | revert ("Use redemption request system") |
| `maxRedeem` / `maxWithdraw` | return 0 by design |
| DEX liquidity for `aguaUSDCgc` | **none found** (DexScreener `pairs: null`; DefiLlama price exists but no pairs) |

---

## 5. What an unprivileged attacker can and cannot do

### Cannot

1. **Write the oracle down.** No setter; `price()` = `convertToAssets()`; the accumulator is monotone. `setRate` is ADMIN_ROLE and only affects future growth.
2. **Move the price with donations or share operations.** `convertToAssets` is `shares * factor / RAY`, independent of `totalSupply` and the token balance. Deposit/redeem are price-neutral.
3. **Liquidate the whale now.** `liquidate(marketParams, borrower, 0, borrowShares, "")` reverts `HEALTHY_POSITION` at HF 1.00638 (fork PoC).
4. **Profit even if the whale is liquidated.** The 2.617% LIF is less than the 5% instant-exit fee; the fee-free queue is unfunded; there is no DEX for the seized agua. The PoC's best case (−1% mark) repays $5,107,265, seizes 5,119,917 agua ($5,240,908 at the shocked mark, +$133,643), and **both** `redeemEarly` and `completeRedemption` revert.
5. **Borrow against cheap agua.** To get agua you must deposit USDC into the vault at par (1.03397); borrowing 91.5% of it is a net loss, and the deposit is withdrawable by the admin EOA.

### Can (but not profitably)

- **Grief the whale by pushing utilisation to 100%**: borrow the remaining $487,984 of USDC against ~$533k of agua collateral minted at par. Borrow APY rises to ~28.1%; the whale's HF would cross in ~12.8 days. Cost: ~$533k of capital deposited into a vault with $30 on-chain and a 5% exit fee; the whale holds 880k spare agua and can cure in one transaction. Negative EV.
- **Redeem the vault's $30**: any holder can `redeemEarly` up to the $30 balance. That is the entire live unprivileged liquidity.

---

## 6. Fork PoC / verification

**Project:** `waterline/poc` (Foundry 1.8.5, solc 0.8.24), fork of Ethereum mainnet at block **26,241,741**.
**CI:** [run 39628160020](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39628160020) — **5/5 PASS**.

| Test | Result |
|---|---|
| `test_live_hf_and_oracle` | HF `1.006383729614517368`; debt `$5,103,656`; collateral `$5,613,373`; LTV 9,091 bps; oracle `1.03397132e24`; Reservoir `$13,077,199.94` |
| `test_liquidation_reverts_while_healthy` | reverts at the live HF |
| `test_hypothetical_writedown_liquidation_exit_blocked` | −1% mock → HF `0.9963198923`; repay `$5,107,265`; seize `5,119,917.108291 agua`; seized value `$5,240,908`; bonus `$133,643`; `redeemEarly` **reverts**, `completeRedemption` **reverts** (vault $30.00) |
| `test_oracle_monotone` | +30 days: `1.03397132 → 1.04210296` (strictly increasing) |
| `test_vault_unfunded_and_privileged_paths` | Agua USDC `$30.00`; `totalAssets` `$11,524,537`; `setRate` and `adminWithdraw` revert for a non-admin |

Gas: 0.20–0.93M per path; no flash loan needed because the path is not profitable.

---

## 7. Verdict and residual risk

**E-U = $0.00 (high confidence).** The finding as written ("a 0.57% NAV write-down liquidates $5.1M") is not a live path: the oracle cannot be written down, the borrower is improving, and the liquidation bonus cannot be realized. The only live unprivileged cash is the vault's $30.

**Residual / latent:**

- **P — Agua ADMIN EOA `0x086eb9c2…`:** can `setRate` and `adminWithdraw` any token; has moved **$28.38M gross**, last **$218,500 at block 26,241,779**. The $11.52M NAV is off-contract and unverifiable on-chain. A key compromise or a decision to stop honoring redemptions makes the collateral worthless while the oracle keeps marking 1.034.
- **P — Reservoir owner/curator:** owner `0x5c48…`/curator `0xC5fA…` control the $13.08M allocation (add/remove adapters, caps, fees). The VaultV2 is non-proxy; no upgrade risk.
- **S — Agua redemption:** $11,524,507 of NAV has no on-chain liquidity; the 5-day queue pays from $30.00.
- **Monitor:** `cumulativeRateFactor`/`currentRate` on Agua; borrower HF (only falls if the rate is cut or utilisation spikes); `AdminWithdraw` events; any DEX listing of `aguaUSDCgc` (a discount would re-arm the borrow-and-default path).

---

## 8. Methodology, sources, caveats

**Reads:** `eth_call` at block 26,241,741 via an archive RPC; Etherscan V2 verified sources for `VaultV2`, `MorphoMarketV1AdapterV2`, `OpportunityOVault`, `MorphoChainlinkOracleV2`, `AdaptiveCurveIrm`, `WildcatMarket`; `getLogs` for 52 `AdminWithdraw` events; DefiLlama/DexScreener for `aguaUSDCgc`.

**Caveats:**
- The Agua vault's true solvency is off-chain: `totalAssets` is synthetic and the contract holds $30.00. The $28.38M gross withdrawal figure is not the current off-vault balance (deposits/withdrawals recycle); no attempt was made to trace the admin EOA's downstream transfers beyond the last hop.
- The PoC's −1% mark is a `vm.mockCall`, used only to prove the liquidation and exit mechanics; it is **not** a reachable on-chain state.
- The borrow APY is computed from `rateAtTarget` + the AdaptiveCurveIRM formula (util 91.41%, C=4), cross-checked against `borrowRateView` inputs; it is an instantaneous estimate and adapts over time.
- USD values use $1.00 for USDC; ETH not used in this target.

**Files:** `waterline/analysis/state.json` (machine-readable live state), `waterline/poc/test/Waterline.t.sol`, `waterline/ci-log.txt`.

*Prepared 2026-10-21 · ZH4 pass-3 · Waterline / Agua · read-only, fork-only.*
