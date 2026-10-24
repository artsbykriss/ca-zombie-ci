# SMARDEX USDN — code-path analysis notes (read-only)

All reads keyless public RPC. Analysis block **26,255,433** (2026-10-23); fresh re-check block **26,265,216** (2026-10-24).

> **Re-check 2026-10-24 (block 26,265,216):** `getBalanceVault()` = 269.898 wstETH, `getBalanceLong()` = 182.598 wstETH (total 452.496); `getTotalLongPositions()` = **28** (was 29); `lastPrice` = $2,984.59; highest populated tick 77,900 with liq price $2,779.45 → **6.87 % buffer** (tick 77,800 = 7.80 %). No tick liquidatable; verdict unchanged.

## 1. Deployment / upgrade state (pinned)

| Item | Value |
|---|---|
| USDN token | `0xde17a000BA631c5d7c2Bd9FB692EFeA52D90DEE2` |
| UsdnProtocol ERC1967 proxy | `0x656cB8C6d154Aad29d8771384089be5B5141f01a` |
| Impl (EIP-1967 slot) | `0x271df5517a4daacb7cab988aa64d23debda4c498` (24,381 runtime bytes; keccak `0x550fdbee51fc08861c8a8925201726f7b36a24efac725cf022c5d08866cc93c9`) |
| EIP-1967 admin slot | `0x00…00` (UUPS; upgrades gated by roles) |
| `Upgraded` events ever | **1** (block 21,671,554 = initial deploy) → **never upgraded since Jan-2025** |
| Oracle middleware | `0xc1459fcfe23d5db9ddb04935ab7a426bd398eab0` (`WstEthOracleMiddleware`, Pyth + Chainlink) |
| LiquidationRewardsManager | `0x9514d3496f46572e8461da381b200812d5db202c` |
| Rebalancer (Dip Accumulator) | `0xaebcc85a5594e687f6b302405e6e92d616826e03` |
| UsdnProtocolFallback | `0xd4e615ab327324e9f2bb492c42d47ee8213959c0` |
| Protocol wstETH balance | **453.641 wstETH** ≈ $1.357M @ wstETH $2,992.16 (DefiLlama) |
| Protocol ETH balance | 0 |

**Deployed source == repo commit `f9171be7feed778213a8c5d4e4dfce674ba16b4d`** (2025-01-21,
"feat: mainnet deployment (#853)"). Verified by diffing the Etherscan-verified sources of the impl,
middleware, and LiquidationRewardsManager against that git commit — all key files byte-identical
(`analysis/deployed-src/**`). Compiler solc 0.8.26, optimizer 20000 runs, evm cancun.

The repo HEAD (`0e682244`, 2026-03-26) contains **post-deployment security fixes that were never
applied to this proxy** (e.g. `ec65255 fix(oracle-middleware): revert when the Pyth confidence is
higher than the price (#918)`). See §6.

## 2. Live protocol parameters (read at block 26,253,852)

| Param | Value | Param | Value |
|---|---|---|---|
| tickSpacing | 100 | liquidationPenalty | 200 bps (2%) |
| minLeverage | 1.1 | maxLeverage | 25 |
| safetyMarginBps | 200 (2%) | liquidationIteration | 1 |
| positionFeeBps | 2 (0.02%) | vaultFeeBps | 4 (0.04%) |
| protocolFeeBps | 3000 (of funding) | securityDepositValue | 0.15 ETH |
| middleware validationDelay | 24 s | lowLatencyDelay | 1200 s (20 min) |
| lowLatencyValidatorDeadline | 900 s | onChainValidatorDeadline | 3900 s |
| minLongPosition | 0.65 wstETH | pythRecentPriceDelay | **45 s** |
| confRatioBps | 2000 (20%) | usdnPrice(now) | 1.00004 |
| balanceVault | 266.221 wstETH | balanceLong | 187.264 wstETH |
| totalExpo | 453.955 | lastPrice | $3,025.86 (wstETH) |

LiquidationRewardsManager params: `gasUsedPerTick=53,097`, `otherGasUsed=469,549`,
`rebaseGasUsed=13,767`, `rebalancerGasUsed=279,349`, `baseFeeOffset=2 gwei`, `gasMultiplier=1.05`,
`positionBonusMultiplier=200 bps`, `fixedReward=0.001 ETH`, **`maxReward=0.5 ETH`**.

## 3. Who can call `liquidate`, and what the liquidator gets

`liquidate(bytes)` (`UsdnProtocolActionsUtilsLibrary.liquidate`) is **fully permissionless**
(no role, no owner). It:
1. reads a price via `_getOraclePrice(Liquidation, 0, "", data)` → middleware
   `parseAndValidatePrice` → `_getLowLatencyPrice(data, 0, None, 0)`;
2. `_applyPnlAndFundingAndLiquidate(neutralPrice, ts, MAX_LIQUIDATION_ITERATION=10, Liquidation, data)`
   → `Core._applyPnlAndFunding` then `Long._liquidatePositions`.

**The liquidator receives only `LiquidationRewardsManager.getLiquidationRewards(...)` (paid in
wstETH from `_balanceVault`), never the position collateral.** The remaining collateral
(`_tickValue`) is credited to the vault (`_updateStateAfterLiquidation`). Reward =
`fixedReward + gasPrice·gasUsed·1.05 + wstETH-bonus`, **hard-capped at `maxReward = 0.5 ETH`**
(`getLiquidationRewards`), and additionally clamped to `s._balanceVault`.

The bonus term is `Σ totalExpo·(tickPrice−currentPrice)/currentPrice · 0.02`, so it scales with the
book's total exposure and the depth of the drop — it is not per-position.

## 4. Is any position liquidatable now? (storage enumeration)

Enumerated **all** live long positions directly from proxy storage (main-storage base
`0xd143a936…9700`; `_tickBitmap` S+43, `_tickVersion` S+38, `_longPositions` S+39, `_tickData` S+40,
`_highestPopulatedTick` S+41, `_totalLongPositions` S+42). Found **29 positions in 24 populated
ticks** — matches `getTotalLongPositions()==29`.

A tick `T` is liquidated iff `effectivePriceForTick(T) >= currentPrice` (equivalently
`T >= getTickAtPrice(unadjustPrice)`). The **weakest** position is the highest tick, **77900**:

| tick | idx | owner | collateral | position value | liq price | buffer |
|---|---|---|---|---|---|---|
| **77900** | 0 | 0x5ee14c42…4882 | 3.076 wstETH | 1.624 wstETH | **$2,779.53** | **8.14 %** |
| 77600 | 0 | 0x5ee14c42…4882 | 2.250 | 1.450 | $2,697.39 | 10.86 % |
| 77000 | 1/2 | 0x8eb3f4d4…/0x5ee14c42… | 4.000/1.605 | 3.563/1.435 | $2,540.31 | 16.05 % |
| … | | | | | | |
| 64300 | 0 | 0x806bE925…FF31 | 12.582 | 11.593 | $713.45 | 76.42 % |

`liquidate` at the current price liquidates **0 ticks** (PoC `test_liquidate_atCurrentPrice_liquidatesNothing`).
The weakest position needs an **8.14 % price drop** to become liquidatable. Full table:
`analysis/position_values.json`.

## 5. Oracle gating (can the price be manipulated?)

`WstEthOracleMiddleware` (Pyth ETH/USD + Chainlink ETH/USD fallback) returns
`wstETH = ethPrice · stEthPerToken / 1e18`.

* **Liquidation** → `_getLowLatencyPrice(data, 0, None, 0)` → `PythOracle._getPythPrice(data, 0, 0)` →
  `pyth.parsePriceFeedUpdates(data, [ethFeed], block.timestamp − 45, block.timestamp)`. The data must
  be a **valid Wormhole-signed Pyth VAA**, so the attacker cannot forge a price; they may only replay
  any *real* Pyth update published in the last **45 s**. `liquidate("")` reverts
  (`test_liquidate_requiresPythData`, `test_oracle_liquidationRequiresLowLatency`).
* `PythOracle` rejects `price <= 0` and positive `expo`; `_formatPythPrice` normalises to 18 dp.
* The confidence interval is applied for validate actions (`confRatioBps=2000`), but the deployed
  version's `_adjustPythPrice` clamps to `price=1` instead of reverting when `conf·0.2 ≥ price`
  (fixed upstream in `ec65255`, **not deployed**). For the ETH/USD Pyth feed `conf` is ~0.01–0.1 % of
  price, so `conf·0.2 ≥ price` would need `conf ≥ 5×price` — unreachable in practice.
* Net: a would-be liquidator can only push the price by the amount ETH actually moved inside a 45 s
  window; there is no spot-manipulable AMM feed.

## 6. Post-deployment fixes not present on the live proxy

| commit | topic | deployed? |
|---|---|---|
| `ec65255` | oracle-middleware: revert when Pyth conf > price | **no** (benign for ETH/USD, see §5) |
| `2d34a8d` | sdex burn ratio → uint64 | no (cosmetic) |
| `f30d98a` | bound setters on deployment | no (governance) |

The reverted commits `eff8b6d` ("revert: max leverage scenario's liqPrice fix") and `f26db82`
("revert: _triggerRebalancer fixes") are **included** in the deployed commit — the live code is the
reverted (less aggressive liquidation check) version. Acknowledged audit issue **M-27
("Liquidatable Positions Can Be Opened")** corresponds to that max-leverage branch; the team rated it
low risk and it only ever creates *bad debt* (protocol loss), not attacker profit.

## 7. Non-liquidation permissionless paths

* `validateActionablePendingActions` / `_executePendingActionOrRevert`: anyone may validate an
  actionable pending action and collect its **0.15 ETH security deposit** — by design. Requires a
  user to leave an action unvalidated past `lowLatencyValidatorDeadline` (900 s) or the on-chain
  deadline (85 min). The pending-action queue is **empty** at read time (`_pendingActionsQueue`
  begin==end==5469) → no live target.
* `UsdnProtocolFallback.burnSdex()` is permissionless and pays the caller 1 % of the protocol's SDEX;
  SDEX is not the custody asset.
* `refundSecurityDeposit(validator)` is permissionless but only refunds a *stale* action's deposit to
  the original validator.
* **Every** setter, pause/unpause, `removeBlockedPendingAction*` (which takes a caller-supplied `to`),
  and `upgradeToAndCall` is `onlyRole(...)` (`SET_EXTERNAL_ROLE`, `CRITICAL_FUNCTIONS_ROLE`,
  `SET_PROTOCOL_PARAMS_ROLE`, `SET_OPTIONS_ROLE`, `SET_USDN_PARAMS_ROLE`, `PAUSER_ROLE`,
  `UNPAUSER_ROLE`). `defaultAdmin()`/`owner()` = `0x1E3e1128F6bC2264a19D7a065982696d356879c5`.
* Deposit / withdrawal round-trip: `_validateDepositWithAction` always mints against
  `max(vaultBalance@init, vaultBalance@validate-if-price-fell)`; `_validateWithdrawalWithAction` pays
  `min(withdrawal.balanceVault, current vaultAssetAvailable)`. Both are protocol-conservative, so no
  stale-price over-mint / over-redeem. PoC round-trip is a **loss**.

## 8. Fork PoC results (8/8 pass)

See `poc/test/UsdnLiquidation.t.sol`. Measured on a mainnet fork:

| test | result |
|---|---|
| `test_bookHealthy_noLiquidatableTick` | weakest liq $2,779.53, buffer **814 bps**, 29 positions |
| `test_liquidate_atCurrentPrice_liquidatesNothing` | **0 ticks** liquidated |
| `test_liquidate_requiresPythData` | reverts (Pyth mandatory) |
| `test_oracle_liquidationRequiresLowLatency` | liq needs Pyth; deposit has Chainlink fallback |
| `test_liquidationReward_isCapped` | max-case reward = **0.499999… ETH** (= `maxReward`) |
| `test_forcedCrash_liquidatorReward` | 0.5 % below weakest liq → 1 tick, reward **0.002434 wstETH ≈ 0.00304 ETH (~$7)** |
| `test_fullBookCrash_totalLiquidatorReward` | −80 % crash → 18 ticks, total reward **1.0000 ETH** (2 × 0.5 cap) |
| `test_depositWithdraw_roundTrip_notProfitable` | 5.0 → 4.9992 wstETH (**−0.0008 wstETH**) |

## 9. Negative results (do not re-investigate)

* No position is within 8 % of liquidation; the protocol price is at par (`usdnPrice=1.00004`).
* `liquidate` gives the caller **no collateral**, only a ≤0.5 ETH reward; there is no way to make a
  healthy position liquidatable without a real ≥8.14 % Pyth-signed price move inside 45 s.
* No permissionless value-moving entry point beyond the capped liquidation reward, the 0.15 ETH
  security-deposit incentive, and `burnSdex` (1 % of SDEX).
* The deployed oracle-confidence clamp (price→1) is unreachable for the ETH/USD feed.
