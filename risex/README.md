# RISEx (RISE) — perps engine reachability & collateral containment

**Date:** 2026-10-21 · **Chain:** RISE mainnet (chainId 4153) · **Pinned block:** 24,990,257
**Status:** read-only; fork-verified only; **no mainnet transaction signed or sent**. All state reads are `eth_call`/`eth_getCode`; the one write-path probe ran on a local Anvil fork (chainId 4153 fork, standard test key) and on GitHub Actions.

---

## 1. TL;DR

| Target | Live value (block 24,990,257) | Unprivileged extractable | Why closed | Latent risk |
|---|---|---|---|---|
| **RISEx CollateralManager** `0x2C03…F818` | **$20,886,150.34** (20,895,931.492064 USDC.e) | **$0** | Only `deposit` / `withdraw` / Permit2 selectors are public. `deposit` is a pull-payment from `msg.sender` (`ERC20: transfer amount exceeds allowance` for an unfunded caller). `withdraw` is keyed on `msg.sender` (fresh caller → `AccountNotRegistered`), may name any `receiver` but only for the caller’s own funds, and is capped by the caller’s balance/withdrawable (`InsufficientBalance`, `InsufficientSupply`). | A bug in the unverified CM impl around margin/equity valuation; Permit2 fork nonce semantics (unused in recent history) |
| **RISEx PerpsManager (engine)** `0x53f1…d852` | 46 markets, 23,712 registered accounts, $20.9M collateral behind it | **$0** | **Every engine write selector is AccessManager-gated** behind roles 9/10/11/14 (placeOrder 14, liquidate 9, crossTakeover 10, executeADL 11). Funding settlement (28 selectors), oracle syncs (46), order book (64) and account registry (8) have **zero** public selectors. A *registered* trading account is still rejected (`AccessManagedUnauthorized`). | Compromise/leak of a role-9/10/11/14 key; indirect mark/funding manipulation through the official session-key order gateway |
| **RISEx LP vault (xlpUSD)** `0xBCf7…D40c` | **$4,999,179.45** (5,001,520.609168 USDC.e; NAV 1.236192) | **$0** | Yearn V3 vault; `availableDepositLimit(non-whitelisted)=0`, so a fresh attacker cannot mint shares to farm the NAV. | Management key; strategy-level NAV (marks open-position equity) |

**Total live extractable by an external unprivileged attacker now: $0.00 (high confidence for the direct surface).**
Value that remains holder-withdrawable (H-O): **$25,885,329.80**. Privileged/role-compromise surface (P): the same $25.89M.

---

## 2. What was actually tested (and what the code is)

RISEx is a perps DEX whose contracts are proxies to **unverified** implementations:

| Role | Proxy | Impl (unverified) | Size |
|---|---|---|---|
| CollateralManager (CM) | `0x2C03C7d7e2974C6599b6B108879109281ef3F818` | `0x893fc1ce864e5a5c0c9fb23c18bc6486dab8b93f` | 38,233 B |
| PerpsManager (PM, engine) | `0x53f10fAcFC8965750494E6965F5d6dA39B41d852` | `0xac3919b01bf61b5da143d61dab472df0a430804b` | 168,804 B |
| OrdersManager (OM, book) | `0xE03C1D5081eb2d0E6bFd62A949C5b12eFa44F2cD` | `0x9b9b37d6abf78774403e2db7ae2975819c488e7e` | 94,713 B |
| AccountRegistry | `0x1238991Cac4E65902C08213e79909A9c813Eebc3` | `0x531a0c7687cbaf02383b21443619487eb18b91e5` | — |
| Oracle | `0x8fC4D0Cf74cdF595254cB763d4C05D38Df0e9503` | `0xe275c453d8d84177ebe637022d16593d483b5a39` | — |
| FundingRate | `0x069eDF2C2A3c93b54640Ae142B9f5375fe4A207a` | `0x52b80e88b67ebc7f1c67652b200aec63bf9b314e` | — |
| Authorization (session keys) | `0x0D919DAA3f12AE715744Eb648c00066c5DBd66f0` | `0xcccb0483342d77abc4337f3e12514ec8e78b3e28` | — |
| FeeManager | `0x11541dc387b9C307043ea732127DF92b80bab52b` | `0x379a6321f5e3659930c5096d209a6bce0f8acfbd` | — |
| AccessManager | `0x1BEe39C01907E3018b7ec2021Cf73F70541b36cC` | (OZ-style, custom `canCall`) | — |

The implementation ABI/semantics were recovered by (a) heimdall decompilation of the impls (`analysis/dc_perps/`, `analysis/decompiled.sol/`, `analysis/dc_orders/`, `analysis/dc_authz/`) and (b) the **verified** adapter/connector/composer source, which vendors the exchange’s own `risex-contracts-0.2.0` interfaces (`analysis/files_0x72dA24/…/IPerpsManager.sol`, `IPerpsRiskManagement.sol`, `IFundingRate.sol`, `IRISExOracle.sol`). Every claim below is backed by a live call, not by the decompiler.

### 2.1 The access model (this is the crux)

The AccessManager is **not** stock OZ semantics: `hasRole(0, random) = false`, while `getTargetFunctionRole(CM, deposit) = uint64.max` marks a public bypass. Enumerating every dispatcher selector of every target and calling `canCall(random, target, selector)` yields exactly:

| Target | Selectors scanned | Callable by a random EOA |
|---|---|---|
| PerpsManager | 82 | `backfillLeverage(uint16,uint32[])` (`0x494f787b`) only |
| CollateralManager | 53 | `deposit`, `withdraw`, `permitTransferFrom`, `permitWitnessTransferFrom` |
| OrdersManager | 64 | **none** |
| Oracle | 46 | **none** (no `syncMarkPriceEMA` / `syncOracleData` / `syncIndexBlockEMA`) |
| FundingRate | 28 | **none** (no `settleFundingRate` / `snapshotPremiumIndex`) |
| AccountRegistry | 8 | **none** |
| Authorization | 37 | **none** |
| FeeManager | 60 | `registerBuilderCode(address)` only (contract holds 0 USDC) |

Engine role map (`getTargetFunctionRole`): `placeOrder` **role 14**, `liquidate` **role 9**, `crossTakeover` **role 10**, `executeADL` **role 11**. Roles 9–14 are held by operational EOAs/contracts, not by users: the only observed PM traffic at the head is one risk bot EOA `0x339c0cBD…6F7C` (roles 9) calling `resolveCrossAccountRisk` / `resolveIsolatedPositionRisk`, plus two one-off liquidators. The RISE retail flow is a **session-key + relayer** model: the `Authorization` contract (`PERMIT_SINGLE`, `REGISTER_SIGNER`, `VERIFY_WITNESS`) lets users sign orders off-chain, and a role-14 relayer settles them on-chain.

`backfillLeverage` is the single public engine selector. On an Anvil fork it executed successfully from a random EOA but produced **zero storage writes** (`debug_traceTransaction` prestate diff empty) and did not change `getLeverage(2, user)` (2.5e19 before and after) — it is a migration/no-op helper for the fields it was probed with, not a lever.

### 2.2 Collateral path (the only value-moving public surface)

`deposit(address account, address token, uint256 amount)`:
- credits `account`, but pulls `amount` from `msg.sender` via ERC-20 `transferFrom`; an unfunded fresh caller reverts `ERC20: transfer amount exceeds allowance`. There is no free credit and no third-party debit.

`withdraw(address receiver, address token, uint256 amount)`:
- account identity is `msg.sender`; a fresh caller reverts `AccountNotRegistered(0x…BEEF)` even when naming a registered account as receiver;
- a registered account can direct its **own** withdrawal to any `receiver` (verified: adapter → `0xdead`, CM balance −1, receiver +1);
- over-withdrawal reverts `InsufficientSupply(token, totalLedger, amount)` and `InsufficientBalance(account, token, withdrawable, amount)`. Tested on a real user holding 25,764.11 USDC.e: `withdraw(30,000e6)` reverted; `withdraw(25,000e6)` reverted against the margin-adjusted withdrawable (16,031.56 at that instant).

So the “withdraw is self-bound” observation from pass 3 is confirmed and tightened: **receiver is free, account is not**.

### 2.3 Why the engine surface is not reachable

- `placeOrder` / `liquidate` / `crossTakeover` / `isolatedTakeover` / `executeADL` / `updateLeverage` / `updateMarginMode` / `migrateAccount` all revert `AccessManagedUnauthorized(<caller>)` for a **registered** account (`0x3D56…5FdC`, userId 22411) — not just for a fresh EOA.
- `settleFundingRate`, `snapshotPremiumIndex`, `snapshotAndSettleFunding`, `syncMarkPriceEMA`, `syncIndexBlockEMA`, `syncOracleData` are **not public**, so the funding/oracle clock cannot be poked by an attacker.
- The mark oracle is Lighter-style: impact price over 500 USDC × max leverage, time-EMA (τ configured per market), premium capped by `maxPremiumBps`, median/index from Stork with deviation thresholds and per-market/per-token EMAs (`IRISExOracle`). Even a trader who can trade through the official gateway would have to sustain a capped premium across the EMA window against the index to move mark, then monetise against real OI.
- Liquidation/ADL payouts (`creditLiquidationFee`, `transferTradingFees`) are engine-only.

---

## 3. Live-state assessment (address → fact → block)

All at block **24,990,257** unless stated.

| Item | Value |
|---|---|
| CM USDC.e balance | `20,895,931.492064` (6 dp) = **$20,886,150.34** @ $0.9995319 |
| xlpUSD vault `totalAssets` | `5,001,520.609168` = **$4,999,179.45**; supply 4,045,908.147587; `pricePerShare` 1.236192 |
| MM strategy | `totalAssets` 3,567,749.481076; adapter account equity 3,571,011.62 (WAD); withdrawable 2,842,133.43 |
| Liquidation strategy | `totalAssets` 336,851.803912 |
| RWA MM strategy | `totalAssets` 1,275,354.1317 |
| Registered accounts | 23,712 |
| Markets | 46; market 2 = ETH/USDC, maxLeverage 25, maintenance 3.75%, stepSize 0.001 ETH, stepPrice 0.01 USDC |
| Pause state | CM `isEmergencyPaused=false`; `pausedFunction(deposit)=false`, `pausedFunction(withdraw)=false` |
| Vault deposit gate | `availableDepositLimit(0x…dEaD)=0`; `whitelistedDepositor(0x…dEaD)=false` |
| FeeManager USDC | 0 |

Value composition: the $20.9M in the CM is user/MM collateral (self-withdrawable); the $5.0M vault is idle USDC inside the Yearn vault (not double-counted with the CM).

---

## 4. What an attacker can / cannot do

**Can (all $0 or self-funded):**
1. Deposit their own USDC.e into any account (gift), cost = gas.
2. Withdraw their own collateral to any receiver, subject to margin.
3. Call `backfillLeverage` (no state change observed), `registerBuilderCode` (fee manager empty).
4. Submit orders through the official session-key/relayer flow if they fund an account — normal trading, not extraction.

**Cannot:**
1. Debit another account (`withdraw` is `msg.sender`-keyed).
2. Withdraw more than their balance/withdrawable (`InsufficientBalance` / `InsufficientSupply`).
3. Place/cancel orders, liquidate, take over, ADL, change leverage/margin mode, migrate an account, settle funding, or sync the oracle without a role.
4. Mint xlpUSD shares without being whitelisted (`availableDepositLimit=0`).
5. Pull user tokens through the CM’s Permit2 selectors without a user-signed permit — deposit uses plain `transferFrom`; `nonces(adapter)=0` and no permit call appears in recent CM history.

Costs: a would-be path would be gas-only on RISE (sub-cent), so any positive delta would be profitable; the constraint is the gate, not the cost.

---

## 5. PoC / fork verification

`poc/test/RISExGate.t.sol` (Foundry, fork of RISE at block 24,990,257):

| # | Test | Expectation |
|---|---|---|
| 1 | `test_engine_selectors_are_not_public` | roles 14/9/10/11; `canCall=false` for random **and** registered users |
| 2 | `test_engine_calls_revert_for_unprivileged` | `placeOrder`, `liquidate`, `executeADL` revert `AccessManagedUnauthorized` |
| 3 | `test_backfillLeverage_is_public_but_noop` | public call succeeds; leverage unchanged |
| 4 | `test_deposit_requires_caller_funds` | unfunded `deposit` reverts on allowance |
| 5 | `test_withdraw_from_foreign_account_reverts` | `AccountNotRegistered(attacker)` |
| 6 | `test_withdraw_own_funds_to_any_receiver` | own funds can go to an arbitrary receiver |
| 7 | `test_withdraw_cannot_exceed_balance` | `InsufficientSupply` |
| 8 | `test_live_holdings` | CM/vault balances pinned; adapter equity > $3.5M |

Run: `bash ci/ci-run.sh risex` → GitHub Actions `artsbykriss/ca-zombie-ci` run
**https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39626338506**
(results copied to `ci-log.txt` / `ci-artifacts/`; pass count in the table below once the run completes).

Anvil-fork trace evidence for `backfillLeverage` (local fork, chainId 4153): tx `0x23be620aa2eafbc5fbff8717917817a3e72491a321e4945f2abb892adf6fdf4f` — `prestateTracer` diff empty, `getLeverage(2, 0x7444…)` 12e18 before and after.

**PoC result: __/8 PASS** (fill from `ci-log.txt`).

---

## 6. Verdict & residual risk

**Verdict: $0 E-U.** The $20.9M collateral layer is clean at the public boundary and the entire perps engine (order entry, funding, oracle, liquidation, ADL, margin) is access-manager-gated behind operator roles; a fresh or merely registered account cannot reach any of it. The pass-3 “unverified engine” lead is now *characterised*, not merely unverified: the gate is the AccessManager, and it holds on live state.

Residual/latent:
- **P:** compromise or leak of a role-9/10/11/14 key (or a role-0 grant) re-opens the full engine, including liquidation/ADL at operator-chosen prices. Role 0 membership was not enumerated (no public grant path found).
- **Conditional E-U (unproven, bounded):** a funded trader using the official session-key/relayer flow could try to bias the impact-price EMA and harvest funding/PnL. The mark is EMA-smoothed, premium-capped, index-anchored (Stork + deviation + peg checks) and funding is clamped; no order-book-depth model was built, so this is a *monitor*, not a finding.
- **Unverified CM internals:** `getAccountEquity` mixes collateral, projected realised PnL and funding; a valuation bug could misprice withdrawable margin. Public calls behaved correctly on the sampled accounts (equity 45,403 vs balance 25,764 for an in-profit user; withdrawable 16,258), but no full audit of the 38 KB impl was possible from bytecode.
- **Permit2 fork:** `permitTransferFrom` / `permitWitnessTransferFrom` are inherited public selectors. No recent usage and `nonces(adapter)=0`; nonce/replay semantics were not independently proven. A user who signs a permit is exposed to the standard Permit2 assumptions, not to an attacker-chosen transfer.

**Blockers:** engine source is not published/verified (0G-style SPA explorer, no Sourcify match); decompiler output for 168 KB PM is lossy, so engine *internals* (exact margin/funding math) are characterised only at the gate and via the vendor interfaces, not line-by-line.

---

## 7. Methodology & files

- **State:** `cast call`/`eth_getCode`/`eth_getStorageAt` at block 24,990,257 (RISE public RPC); EIP-1967 slots; 23,712 accounts; 46 markets.
- **Access:** selector extraction from dispatcher bytecode (`63xxxxxxxx14`), then `AccessManager.canCall(random|registered, target, selector)` for 82+53+64+46+28+8+37+60 selectors; `getTargetFunctionRole`; `hasRole`.
- **Code:** heimdall decompilation of CM/PM/OM/AccountRegistry/Authorization impls; verified adapter/connector/composer source and the vendored `risex-contracts-0.2.0` interfaces.
- **Fork:** Anvil (RISE fork, chain 4153) for the one public write probe; Foundry PoC in CI for reproducibility.
- **Price:** `coins.llama.fi` USDC $0.9995319114 (2026-10-21).

Files: `analysis/live_state.json`, `analysis/selectors.txt`, `analysis/auth_scan.json`, `analysis/public_selectors.json`, `analysis/dc_perps/`, `analysis/decompiled.sol/`, `analysis/dc_orders/`, `analysis/dc_authz/`, `analysis/files_0x72dA24/` (vendor interfaces), `analysis/files_0x3C63b0/` (strategy source), `poc/`, `ci-log.txt`.

**Caveats:** point-in-time; the RISE public RPC caps `eth_getLogs` at 5k blocks, so historical enumeration relied on Blockscout v2; the engine is upgradeable (proxy admin `0x937132…72b1`), so the gate is only as durable as the AccessManager configuration; no mainnet interaction of any kind was performed.
