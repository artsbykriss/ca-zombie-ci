# SMARDEX USDN (Ethereum) — permissionless liquidation / validation math, residual value

**Date:** 2026-10-23 (re-verified 2026-10-24) · **Chain:** Ethereum (chainId 1) · **Mode:** read-only; PoC fork-verified only;
**no mainnet transactions signed or sent** · **Analysis block:** 26,255,433 · **Fresh re-check block:** 26,265,216

**Target:** `UsdnProtocol` proxy `0x656cB8C6d154Aad29d8771384089be5B5141f01a`
(impl `0x271df5517a4daacb7cab988aa64d23debda4c498`), a delta-neutral synthetic-dollar protocol
holding **453.64 wstETH ≈ $1.357M**. Source: `github.com/SmarDex-Ecosystem/usdn-contracts` @
`f9171be` (byte-identical to the Etherscan-verified deployed code).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **SMARDEX USDN** — `liquidate`, `validateOpen/Close`, `initiate/validateWithdrawal` | **$0** (high confidence) | No tick is liquidatable — the weakest of 28 positions is **6.87 %** below the current price (re-check 2026-10-24; was 8.14 % on 2026-10-23). `liquidate` pays the caller only a **≤0.5 ETH reward** (never the collateral) and requires a **fresh, Wormhole-signed Pyth price ≤45 s old** — unfakeable. All setters / `removeBlockedPendingAction` / upgrades are role-gated. | The **≤0.5 ETH-per-call** liquidation reward is by-design extractable *if* a real ≥6.87 % wstETH price move happens inside 45 s. Measured whole-book ceiling ≈ **1.0 ETH** for an −80 % crash (hard-bounded at ~1–1.5 ETH, ~$2.4–3.6k). The undeployed oracle-confidence fix (`ec65255`) is benign for the ETH/USD feed. |

**Total live extractable now: $0.00** (confidence: **high**). Nothing in the permissionless
liquidation / validation / vault path can be turned into profit without a genuine price crash, and
even then the payoff is the protocol's intended, hard-capped liquidation reward — not a bug.

---

## 2. The mechanism, in exact terms

The USDN protocol keeps a book of leveraged wstETH longs (`_longPositions` keyed by tick) against a
vault. Five entry points are **permissionless by design**:
`liquidate(bytes)`, `validateOpenPosition`, `validateClosePosition`, `initiateWithdrawal` /
`validateWithdrawal`. The lead hypothesis was that a wrong liquidation price / penalty / oracle-age
check would let an unprivileged attacker self-liquidate profitably or redeem at a wrong ratio.

**Deployed code references** (`analysis/deployed-src/impl`):

* `UsdnProtocolActionsUtilsLibrary.liquidate` (line 45) → `Long._applyPnlAndFundingAndLiquidate` →
  `Long._liquidatePositions` (line 804). Liquidator reward is paid **only** by
  `Long._sendRewardsToLiquidator` (line 511) via `LiquidationRewardsManager.getLiquidationRewards`;
  the liquidated tick's remaining collateral goes to `s._balanceVault` (line 939-940). **The caller
  never receives the position's collateral.**
* `LiquidationRewardsManager.getLiquidationRewards` hard-caps `totalRewardETH` at
  `maxReward = 0.5 ether`; `_sendRewardsToLiquidator` additionally clamps to `s._balanceVault`.
* Tick liquidation condition (`Long._liquidatePositions` lines 831-847): a tick is liquidated iff
  `tick >= getTickAtPrice(unadjustPrice(currentPrice))`, i.e. iff its funding-adjusted effective
  price ≥ the current price. `Utils._getEffectivePriceForTick`, `_getLiquidationPrice`,
  `_getLeverage`, `_calcPositionTotalExpo` were read in full — the sign/rounding algebra is
  consistent (a higher price ⇒ lower leverage; liq price always `startPrice·(1−1/L)`).
* Oracle: `WstEthOracleMiddleware` → `OracleMiddleware.parseAndValidatePrice` →
  `_getLowLatencyPrice(data, 0, None, 0)` → `PythOracle._getPythPrice(data, 0, 0)` →
  `pyth.parsePriceFeedUpdates(data, [ethFeedId], block.timestamp−45, block.timestamp)`. Only real,
  signed Pyth updates from the last **45 s** are accepted; `price <= 0` and positive `expo` revert.
* Vault round-trip: `_validateDepositWithAction` (line 744) mints against the **higher** of the
  initiation / validation vault balance; `_validateWithdrawalWithAction` (line 960) pays the
  **lower** of the initiation value and the current available balance — both protocol-conservative.

---

## 3. Live-state assessment (block 26,255,433)

| Address | Code | Role | Live value |
|---|---|---|---|
| `0x656cB8C6…f01a` (proxy) | 354 B proxy; EIP-1967 impl slot = `0x271df551…c498`; admin slot 0 | USDN protocol | **453.641 wstETH** ($1,357,433 @ $2,992.16); 0 ETH |
| `0x271df551…c498` (impl) | 24,381 B, keccak `0x550fdbee…93c9` | implementation | — |
| `0xde17a000…DEE2` (USDN) | ERC-20 rebasing, `divisor=8.06e17`, `totalSupply=805,742.5` | synthetic dollar | — |
| `0xc1459fcf…eab0` | verified | oracle middleware (Pyth + Chainlink) | — |
| `0x9514d349…202c` | verified | liquidation rewards (cap 0.5 ETH) | — |
| `0xaebcc85a…6e03` | verified | rebalancer (holds tick-73000 position, 49.78 wstETH) | — |
| `0xd4e615ab…59c0` | verified | fallback (all setters role-gated) | — |

* **Never upgraded:** exactly one `Upgraded` event (block 21,671,554, the initial deploy).
* `getTotalLongPositions()` = **28** (was 29 on 2026-10-23; one position closed); enumerated independently from storage (24 populated ticks,
  `_highestPopulatedTick` = 77,900) — full table in `analysis/position_values.json`.
* Weakest position (tick 77,900, owner `0x5ee14c42…4882`): at the analysis block liq price **$2,779.53** vs current
  **$3,025.86** → **8.14 % buffer**; fresh re-check 2026-10-24 (block 26,265,216): lastPrice **$2,984.59**,
  liq **$2,779.45** → **6.87 % buffer** (still not liquidatable; next tick 77,800 = 7.80 %).
* Roles: `defaultAdmin()` = `owner()` = `0x1E3e1128F6bC2264a19D7a065982696d356879c5`. Every setter,
  `removeBlockedPendingAction*` (caller-supplied `to`), pause/unpause and `upgradeToAndCall` is
  `onlyRole(...)`.
* Pending-action queue is **empty** (`_pendingActionsQueue` begin == end == 5469).

---

## 4. What an attacker can / cannot do

**Can:**
* Call `liquidate(data)` — but only with a valid Pyth VAA from the last 45 s, and it liquidates
  **nothing** at the current price. If a real crash put a tick underwater, the caller would receive
  `min(reward, 0.5 ETH, vaultBalance)` in wstETH — measured **~0.003 ETH (~$7)** for a single-tick
  liquidate, and **1.0 ETH** for a full 18-tick, −80 % crash (2 calls × the 0.5 ETH cap).
* Collect a **0.15 ETH security deposit** by validating someone else's *actionable* pending action
  (`validateActionablePendingActions`) — by design; needs a victim to leave an action unvalidated
  for >900 s / 85 min, and the queue is currently empty.
* `burnSdex()` — permissionless, pays the caller 1 % of the protocol's SDEX (not the custody asset).

**Cannot:**
* Liquidate a solvent position: requires an ≥6.87 % real, Pyth-signed price drop within 45 s.
* Forge / manipulate the oracle price: the Pyth update is Wormhole-signed; the only on-chain
  alternative (Chainlink) is used for *initiate* actions, not liquidations.
* Take the collateral of a liquidated position, redeem USDN above par, or over-mint on deposit.
* Reach any setter, pause, `removeBlockedPendingAction`, or upgrade path without a role.

---

## 5. PoC / fork verification

`poc/` — Foundry, vendored `lib/forge-std`, no linked libraries; forks mainnet via
`vm.createSelectFork(FORK_RPC_URL | RPC_URL | https://ethereum-rpc.publicnode.com)` and calls the
**deployed proxy**. Pyth is mocked *only* to measure protocol behaviour under a chosen price (the
mock cannot exist on-chain). **9 / 9 tests pass.**

| # | Test | Key measured number |
|---|---|---|
| 1 | `test_bookHealthy_noLiquidatableTick` | weakest liq $2,779.53; **buffer 814 bps**; 29 positions |
| 2 | `test_liquidate_requiresPythData` | `liquidate("")` reverts |
| 3 | `test_liquidate_atCurrentPrice_liquidatesNothing` | **0 ticks** liquidated |
| 4 | `test_liquidationReward_isCapped` | max-case reward **0.499999 ETH** (= `maxReward`) |
| 5 | `test_forcedCrash_liquidatorReward` | 1 tick → **0.002434 wstETH ≈ 0.00304 ETH (~$7)** |
| 6 | `test_fullBookCrash_totalLiquidatorReward` | 18 ticks (−80 %) → **1.0000 ETH** total |
| 7 | `test_oracle_liquidationRequiresLowLatency` | liq needs Pyth; deposit falls back to Chainlink |
| 8 | `test_depositWithdraw_roundTrip_notProfitable` | 5.0000 → 4.9992 wstETH (**−0.0008**) |
| 9 | `test_openPosition_noFreeValue` | open 1 wstETH long → collateral 1.0, position value 0.9986 wstETH (**no free leverage**) |

**CI:** `ci/ci-run.sh smardex-usdn` → GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`.
The run URL is recorded in `ci-log.txt`, in `summary.json` (`poc.ci_run_urls`), and below.

<!-- CI_RUN_URL -->
**CI run (9/9 PASS):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39960310248
(`Suite result: ok. 9 passed; 0 failed` — full log in `ci-log.txt`). Earlier identical run: 39959981957.

---

## 6. Verdict & residual / latent risk

**Verdict: E-U = $0.00 (high confidence).** No live unprivileged fund-drain exists on the SMARDEX
USDN liquidation / validation / vault surface. The book is healthy (nearest liquidation 8.14 % away),
the oracle is a signed low-latency feed with a 45 s freshness window, the liquidator is paid only a
hard-capped reward, and every privileged function is role-gated.

**Residual / latent risk (monitor only):**
* The **0.5 ETH-per-call** liquidation reward (Issue_02 in the Bailsec report, acknowledged): measured
  **1.0 ETH** for an 18-tick, −80 % crash (2 calls × the 0.5 ETH cap), hard-bounded at ~1–1.5 ETH
  (~$2.4–3.6k) for a whole-book crash. Not a bug; it is the incentive.
* **M-27 (Guardian, acknowledged): "Liquidatable Positions Can Be Opened"** in the max-leverage
  re-validation branch — creates *protocol* bad debt, not attacker profit.
* The **undeployed** oracle-confidence fix `ec65255` (price→1 clamp instead of revert) — unreachable
  for ETH/USD (`conf` would need to exceed 5× the price), but worth re-checking if the middleware is
  ever repointed to a thin feed.
* The **empty** pending-action queue could later expose the 0.15 ETH security-deposit incentive.

---

## 7. Methodology & sources

* Read the **exact deployed source** (Etherscan V2 verified standard-json, `analysis/deployed-src/`)
  for the impl, middleware, rewards manager and fallback; diffed against
  `github.com/SmarDex-Ecosystem/usdn-contracts` @ `f9171be` — byte-identical.
* Enumerated live positions **from proxy storage** (`analysis/enumerate_positions.py`), cross-checked
  against `getTotalLongPositions()==29`, then priced each via `getEffectivePriceForTick` /
  `getPositionValue` (`analysis/position_values.py`).
* Read every permissionless code path in full: `UsdnProtocolActionsLongLibrary`,
  `UsdnProtocolActionsUtilsLibrary`, `UsdnProtocolLongLibrary`, `UsdnProtocolCoreLibrary`,
  `UsdnProtocolVaultLibrary`, `UsdnProtocolUtilsLibrary`, `CommonOracleMiddleware`/`OracleMiddleware`,
  `PythOracle`, `ChainlinkOracle`, `LiquidationRewardsManager`, `UsdnProtocolFallback`.
* Fork PoC on Ethereum mainnet (`poc/`), 8/8 tests.
* Cross-checked audit reports (Guardian 2024-12-18, Bailsec) and the protocol's acknowledged-issues
  list (`docs.smardex.io/.../audits`); DefiLlama for prices.

**Caveats / limitations**
* The PoC mocks the Pyth contract to *measure* protocol behaviour under a chosen price; the mock
  cannot exist on-chain, so the "forced crash" tests quantify the **reward ceiling**, not a feasible
  attack.
* Position enumeration reads `_tickBitmap`/`_longPositions` directly (documented layout) rather than
  only events; the count matches the on-chain getter, which validates the layout.
* USD figures use DefiLlama wstETH $2,992.16 / ETH $2,400.25 at 2026-10-23; the protocol's own
  `lastPrice` for wstETH was $3,025.86.
* No mainnet state was modified; all writes are on ephemeral forks.
* The vendored `lib/forge-std` retains its upstream *public* default RPC placeholders in
  `src/StdChains.sol`; these are forge-std defaults, not campaign secrets. No keyed RPC URL, API key or
  private key of this campaign is present anywhere in this folder.

## 8. Files index

```
smardex-usdn/
├── README.md                     this file
├── summary.json                  machine-readable summary
├── analysis/
│   ├── NOTES.md                  detailed code-path analysis
│   ├── read_state.sh             live-parameter reader (keyless RPC)
│   ├── enumerate_positions.py    storage enumeration of long positions
│   ├── positions.json            raw enumeration output
│   ├── position_values.py        liq-price / value / buffer per position
│   ├── position_values.json      full 29-position table
│   ├── deployed-src/             Etherscan-verified deployed source (impl/middleware/liqrewards/fallback)
│   └── etherscan/                raw Etherscan source+ABI JSON
└── poc/                          Foundry project (8/8 tests pass)
    ├── foundry.toml
    ├── src/Interfaces.sol
    └── test/UsdnLiquidation.t.sol
```
