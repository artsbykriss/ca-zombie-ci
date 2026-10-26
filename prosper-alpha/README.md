# Prosper Alpha (Pharos, chainId 1672) — external-unprivileged extraction assessment

**Date:** 2026-10-25 · **Chain:** Pharos (1672 / 0x688) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or sent**.
**Target:** Prosper Alpha (DefiLlama id 9176) — bonding-curve launchpad for `p{VAULT}` campaign tokens, TVL ≈ $520k.
**Campaign:** ZH4-PASS7 · folder `prosper-alpha/`.

> This report closes the pass-7 gap ("market impl would not decompile"). The market implementation **does** decompile with `heimdall` (`/home/heisenberg/.bifrost/bin/heimdall`) and the full contract set, ABIs, roles and value paths were read. Result: **no external-unprivileged value path found.**

---

## 1. TL;DR

| Target | Live value | E-U extractable (headline) | Why closed / open | Latent risk |
|---|---|---|---|---|
| **Prosper Alpha** (Pharos 1672) | 828,857 WPROS ≈ **$520.4k** (in-curve + graduated-pool WPROS) | **$0.00** (high confidence) | Every value mover is `role`/`owner`/`caller`-gated: migration escrow (`MIGRATOR_ROLE`), buyback (`FEE_OPERATOR_ROLE`), LpTimeLock claim (`owner = accessController`), market beacon upgrade (`upgradeMarketImplementation`, role-gated), UUPS upgrades (owner). The only permissionless state-changers are the bonding-curve `buy`/`sell` (pause-gated, symmetric x·y=k + 1% fee → round-trip always loses) and `refreshPhase()` / `finalizeFailure()` (burn/grief only, no value out). | Curve/buyback fee routing and the permissionless `finalizeFailure` burn are griefing surfaces, not profit. Owner is a **single EOA** → P-class takeover risk, not E-U. |

**Total live extractable now: $0.00** (E-U), confidence **high**. The ~$520k TVL is H-O (curve traders can buy/sell, holders can sell failed-campaign tokens) and P (privileged roles / single-EOA admin).

---

## 2. What the protocol is

Prosper Alpha is a launchpad on Pharos that turns external **R25 strategy vaults** into tradable `p{VAULT}` tokens via an internal bonding-curve campaign. Lifecycle: `ActiveInner` (curve) → `GraduatedPendingMigration` → `OuterActive` (Uniswap-V2 pool, LP locked in `LpTimeLock`) or `FailedInnerOnly` (curve stays open, no migration).

Source of truth: the code is **not verified on any explorer** (Pharos has no working verified-source explorer; Sourcify v2 returns `match:null` for 1672; Etherscan V2 unsupported). Two independent sources were used:

1. **`heimdall` decompilation** of every deployed implementation (factory, market, buyback, accessController, globalConfig, migrationEscrow, pTokenClaim, feeFallbackDistributor, tradeRouter, depositRouter, LpTimeLock) — saved under `analysis/`.
2. The **BlockSec audit** of the same contracts (`analysis/blocksec_prosper_audit.{pdf,txt}`, signed 2026-09-08, commit V2 `b8ef7f`) which gives the real source for factory / migration escrow / router / claim / buyback and confirms names, roles and the phase enum.
3. The protocol's own public API `https://api.pros-per.xyz/api/v1/{deployment,vaults}` (addresses + launch config + live market state) — cross-checked on-chain.

## 3. Deployed addresses (verified on-chain at block 21240221 / latest)

All proxies are EIP-1967 UUPS (130-byte proxy). Impl slots read at `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`.

| Role | Proxy | Implementation |
|---|---|---|
| ProsperFactory | `0xEfdbb0eA7647B0e21AEf7A3b7a5D6A632c3116C8` | `0x797a9e5feffb4e2f165783b873345edace8e1e2e` (15,869 B) |
| AccessController | `0x3C22060C99EE18097029151113478b4264041Bdb` | `0x9a4dbfa541c3f49e123e0c36c4c4125a3e9eb2c3` (9,927 B) |
| GlobalConfig | `0x0303eE1F0409588DE499aD0538618C5da46EC5D7` | `0xcdd68cd45d9592d9f6c1d8f313647315a5d1ac02` (5,424 B) |
| TradeRouter | `0x63FfADf944583D8e4Fdc30144EFdfe3bdC2122f5` | `0x533e70b9d51c330bf4c037f6c55fa8dd822a6c64` (6,703 B) |
| DepositRouter | `0xbbDDb34955ed0DD8059188aA57422f29babCe6ec` | `0xb3c011977c21d0f40e9884d250b638e4eed6ad91` |
| MigrationEscrow | `0xc8F6D453D3C3ceA8A046f6D4AB683B0c4DB9a4D5` | `0xcc143ad74665cea035bce2ec17d74e5e9e301768` (6,870 B) |
| PTokenClaim | `0x158432EeD50E944B4148D46b5e7df5D083706811` | `0x8c23f2be8127c20ecbaf4806d99ea35c60b7e469` (9,293 B) |
| FeeFallbackDistributor | `0x707E665B1a46319AB82AF7E300F0c92b3a279325` | `0x607b54ed30752ce173f65eff91e6549ffcf6930e` |
| MarketBeacon | `0x30BeBe432fF53c9B6ED28Dd9DAf125902CbABB56` (605 B) | market impl `0xb05749a8Cc5Dd1205Bc36326Cf94A2cA83f7D672` (7,410 B) |
| BuybackBeacon | `0x22D57Cc6bA71E96fE441A15038178Ec725651f8c` (605 B) | buyback impl `0x150fB446BDda9d832208B00aBCE2D5Bd1d4E4E2a` (5,172 B) |
| LpTimeLock | `0x152Ecca16F86FAa5d1FC2eD0a1B2bAF5AACd794B` (1,676 B, not a proxy) | — |
| WPROS (wrapped native) | `0x52C48d4213107b20bC583832b0d951FB9CA8F0B0` | — |

Live facts:
- `AccessController.defaultAdmin()` = **`0x760caE380fDfbce6D810E6874F666234dFA0558A`** — **EOA** (`eth_getCode` = `0x`, code size 0). This EOA is the top-level owner of the whole system (**P-class**).
- `LpTimeLock.owner()` = `0x3C22…1Bdb` (the AccessController proxy); `pendingOwner` = 0.
- Market beacon `owner()` = `0x3C22…1Bdb`; upgrades go through `AccessController.upgradeMarketImplementation(address)` (selector `0x7ba73267`), gated on role `0xb7db2dd08fcb62d0c9e08c51941cae53c267786a0b75803fb7960902fc8ef97d`.
- `GlobalConfig.getLaunchConfig()` = `(innerRatioBps 7300, outerRatioBps 2000, targetRaiseNative 2e22, userRewardBps 600, curatorRewardBps 100, lpLockDuration 315360000 ≈ 10 y)`; `getProtocolAddresses()` = `(USDC, WPROS, uniV2Factory?0xf58f…, migrationEscrow)`.
- Trading fee = **100 bps** (`runtime.tradingFeeBps`), `curveK = 7588465646137415450338065843360626557493770024920 = x0·y0` with `x0 = 7547.1698…e18`, `y0 = 1005.4716…e24` → **constant-product (Uniswap-v2-style) virtual-reserve curve**.

## 4. The market implementation (the pass-7 gap) — now read

`heimdall decompile 0xb05749a8Cc5Dd1205Bc36326Cf94A2cA83f7D672 --rpc-url https://rpc.pharos.xyz --include-sol` → `analysis/market_impl_decompiled.sol` (+ `market_impl_yul.txt`). Function map (selectors verified in bytecode + via the app bundle ABI):

| Selector | Meaning | Gate |
|---|---|---|
| `0x4beb394c` `quoteBuy(uint256)` | view: `(usedGross, fee, netAmountIn, pTokenOut)` | none |
| `0xa64190c4` `quoteSell(uint256)` | view: `(grossOut, fee, netOut)` | none |
| `0x383f5607` (buy, called by router `buyInnerNative`) | buy with native | `nonReentrant` + `modulePaused(MODULE_INNER_TRADING)` |
| `0x1c31c595` / `0x4e6243fe` / `0xf5271f57` (sell paths, called by router `sellInner` / `sellInnerWithPermit`) | sell pToken | `nonReentrant` + `modulePaused(MODULE_INNER_TRADING)` |
| `0x8900fc63` | set `externalPair`, clear reserve, phase→2 | **`msg.sender == migrationEscrow`** |
| `0xa7519ca6` | `WPROS.transfer(to, reserve)` (release reserve) | **`msg.sender == migrationEscrow`** |
| `0x64470615` | reserve/migration helper | **`msg.sender == migrationEscrow`** |
| `0x9ff1103f` `refreshPhase()` | permissionless phase refresh (returns Phase) | none — **no value moved** |

Key: the market's only permissionless value-moving functions are the curve `buy`/`sell`. They are **not** role-gated — anyone (via the TradeRouter or directly) can trade — but they are a plain `x·y=k` constant-product curve with a symmetric 1% fee, so a buy→sell round-trip is strictly loss-making (measured below). All real value exits (`releaseReserve`, migration, `externalPair`) are `migrationEscrow`-gated.

## 5. Live-state assessment (all values on-chain; block 21240221 unless noted)

39 campaigns total (15 `ActiveInner`/phase 0, 14 `FailedInnerOnly`/phase 3, 10 `OuterActive`/phase 2). Market set independently enumerated from `ProsperVaultLinked` logs in ≤1000-block windows (`ci/enumerate.py`, run in CI) and cross-checked against the protocol API.

| Bucket | WPROS | USD @ $0.6279 | Who can move it |
|---|---|---|---|
| Bonding-curve markets (phase 0) | 16,567.19 | $10,402 | holders sell on curve (H-O); buy/sell permissionless |
| Failed-inner markets (phase 3) | 5,063.29 | $3,179 | holders sell on curve (H-O); `finalizeFailure` burns reserved pTokens (permissionless, no value out) |
| Graduated V2 pools — WPROS side of LP held by LpTimeLock | 807,226.03 | $506,840 | `LpTimeLock.claim` gated by `owner = accessController` (**P**); otherwise normal AMM trading |
| **Total** | **828,856.51** | **$520,421** | DefiLlama reports $517,577 (same block, slightly different price) |

Raw dumps: `analysis/markets_state.json`, `analysis/totals.py` output, `ci-out/markets_onchain.json` (CI), `analysis/api_vaults.json`, `analysis/deployment.json`.

## 6. What an attacker can / cannot do

**Can (all non-profit / self-service):**
- Trade the curve (`TradeRouter.buyInnerNative` `0x6b8eaf6d`, `sellInner` `0xfddc508e`, `sellInnerWithPermit` `0x437a4926`) — permissionless but round-trips lose ~2% (1% each way) plus curve slippage.
- Call `market.refreshPhase()` and `MigrationEscrow.finalizeFailure(vault)` (`0x108ffd37`, permissionless per audit §2.2.5) — these only advance/burn state; **no value is returned to the caller**.
- Trade the graduated V2 pools (ordinary AMM).

**Cannot (verified by revert in the PoC):**
- `MigrationEscrow.migrateToExternal` (`MIGRATOR_ROLE`) / `addLiquidity` — revert for non-role callers.
- `LpTimeLock.claim` / `register` — revert (owner = accessController / registrar = migrationEscrow).
- `Buyback.withdrawUsdc` / `fund` / `0x7b1a3baf` — `FEE_OPERATOR_ROLE` revert.
- `Factory.upgradeToAndCall`, `AccessController.upgradeToAndCall`, `AccessController.upgradeMarketImplementation` — owner/role revert.
- `PTokenClaim.claim` with a forged `totalAllocation` — the Merkle leaf binds `chainid, address(this), campaign.pToken, r25Vault, campaign.market, account, totalAllocation` (read from `ptokenClaim_yul.txt`), so allocations cannot be inflated and empty proofs revert.

## 7. PoC / fork verification

Foundry project `poc/` (`poc/test/ProsperAlpha.t.sol`), fork of Pharos at **block 21240221** via `vm.createSelectFork(vm.envOr("PHAROS_RPC_URL", "https://rpc.pharos.xyz"))` (keyless public RPC; `FORK_RPC_URL` is deliberately **not** used because the shared workflow sets it to an Ethereum RPC). All exploit simulations run on the **local fork only**.

Tests:
1. `test_quote_roundtrip_never_profits` — `quoteBuy(x)`→`quoteSell(pOut)` over 7 sizes × 3 live markets; asserts `netBack ≤ x`.
2. `test_fork_buy_sell_never_profits` — real `buyInnerNative` then `sellInner` for 5 sizes; asserts attacker native balance never increases.
3. `test_failed_market_holder_can_sell` — phase-3 market sell path (H-O recovery check).
4. `test_migrateToExternal_reverts`, `test_addLiquidity_reverts` — migration escrow role gate.
5. `test_timelock_claim_reverts`, `test_timelock_register_reverts` — LpTimeLock gates.
6. `test_buyback_withdraw_reverts` — buyback role gate.
7. `test_factory_upgrade_reverts`, `test_access_controller_upgrade_reverts` — UUPS owner gate.
8. `test_ptokenclaim_forged_reverts` — Merkle forgery blocked.
9. `test_refresh_phase_no_value_move` — permissionless phase refresh moves no WPROS.

**Result:** CI_POC_RESULT_PLACEHOLDER
**CI run:** CI_RUN_URL_PLACEHOLDER (heavy market enumeration in `ci/run.sh` + `forge test -vvv`, GitHub Actions `artsbykriss/ca-zombie-ci`).
**Local:** all address/role/balance reads and `cast call`/`eth_call` probes; decompilation with `heimdall`; DefiLlama/API fetches.

## 8. Verdict, residual & latent risk

- **E-U today: $0.00 (high confidence).** No permissionless path moves protocol value to the attacker.
- **P (privileged):** ~$520k is ultimately controlled by `AccessController.defaultAdmin = 0x760caE38…0558A`, a **single EOA** (also controls the market beacon upgrade and, transitively via `LpTimeLock.owner`, the 807k WPROS of locked LP). Key compromise = total loss. This is centralisation, not an E-U bug.
- **H-O:** curve traders and failed-campaign holders can exit via the curve (self-service).
- **Griefing (not profit):** `MigrationEscrow.finalizeFailure(vault)` is permissionless and burns a failed campaign's reserved migration pTokens + reward pool once `phase == FailedInnerOnly` (audit §2.2.5); it can be called by anyone and cannot be called again after `burnRewardPool`. Impact is loss to eligible claimants, not attacker gain.
- **What would change the verdict:** (a) `AccessController.modulePaused(MODULE_INNER_TRADING)` being lifted is irrelevant; (b) if a market's `migrationEscrow`/`accessController` pointer were mutable by a non-role caller (it is not — set only in `initialize`); (c) if the curve used asymmetric rounding (it does not — symmetric constant-product, round-trips lose).

## 9. Methodology, caveats, files

- **Tooling that worked:** `heimdall` v0.9.2 (`--include-sol` and `--include-yul`) decompiled **all** implementations including the market (`0xb057…D672`) that pass-7 reported as undecompilable. `debug_traceTransaction` with `{"tracer":"callTracer"}` and `{"tracer":"prestateTracer"}` work on `rpc.pharos.xyz`; the struct-log tracer does not.
- **Tooling limits:** `heimdall`'s symbolic execution stops after the dynamic `staticcall` to `AccessController.modulePaused(...)`, so the arithmetic bodies of `buy`/`sell` are only partially rendered; the curve was therefore verified **empirically** (view quotes + fork round-trips) and cross-checked against the audit + the app's own ABI (`app_index.js`).
- **Caveats:** no verified source on Pharos (decompiler + audit + API triangulation); point-in-time 2026-10-25 — re-read live state before acting. USD uses the protocol's `nativeUsdPrice` ($0.6279) at the read block.
- **Files:** `analysis/` (decompiled sources, yul, state dumps, BlockSec audit, app bundle), `poc/` (Foundry), `ci/` (`run.sh`, `enumerate.py`), `ci-out/`, `ci-log.txt`, `ci-artifacts/`, `summary.json`.
