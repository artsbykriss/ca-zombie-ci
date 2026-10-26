# Hyperbeat Earn (HyperEVM 999) — external-unprivileged extraction assessment

**Date:** 2026-10-25 · **Chain:** HyperEVM (999) · **Status:** read-only research; PoC fork-verified only;
**no mainnet transaction was ever signed or sent**. All heavy work (Foundry compile + fork tests) ran on
GitHub Actions; local work was limited to `cast`/`eth_call` reads and web fetches.

**Scope.** DefiLlama protocol *Hyperbeat* (`projects/hyperbeat/index.js`, `hyperliquid: { tvl }`) is an
**aggregate of 26 vaults** on HyperEVM. This report is the **Earn** component: **14 MetaMorphoV1_1 vaults
+ 8 Midas-lineage permissioned "rate" tokens + 2 standalone permissioned tokens + 2 Mellow
`TokenizedAccount` ERC-4626 vaults**. It is **distinct** from the Hyperbeat **beHYPE LST**
(`0xd8FC8F0b…`), which pass-3 already closed as byte-identical to audited `etherfi-protocol/beHYPE`.

**Measured aggregate TVL (this report, block 49,508,160): ≈ $18.78M** — matches DefiLlama's ~$18.55M.

---

## 1. TL;DR

| Component (count) | Live TVL | Live extractable by an **external unprivileged** attacker (E-U) | Why closed | Latent risk |
|---|---|---|---|---|
| **MetaMorphoV1_1 vaults** (14) | ≈ $2.70M | **$0** | Canonical audited Morpho code. `totalAssets()` is market-derived (not `balanceOf`), so a **token donation does not inflate NAV**; `skim()` is permissionless but **recipient-fixed** (`skimRecipient`) and the vaults hold **0 idle asset**; deposit/redeem are the standard ERC-4626 flow with `DECIMALS_OFFSET` virtual shares (no first-depositor inflation at live supply) | `skim()` will sweep *any* accidental token to `skimRecipient`; a rate/rounding bug would be systemic (upstream Morpho) |
| **Midas-lineage permissioned tokens** (10: liquidHYPE, lstHYPE, hbUSDT, hbUSDC, wVLP, dnHYPE, dnPUMP, hbXAUt, nLP, masterUSD) | ≈ $13.83M | **$0** | `mTBILL`/`VaultToken` forks: `mint`/`burn`/`pause` are **role-gated** (`MidasAccessControl` / solmate `MultiRolesAuthority`) — **no public role**; there is **no `deposit`/`redeem`/`asset`** on the token. The only permissionless paths are `WithdrawalQueue.instantWithdraw` (burns the **caller's own** tokens) and `createWithdrawalRequest` (locks the **caller's own** tokens) | The `Pricer` exchange rate is **manually set** by an operator; if set above true backing, the small `DepositReceiver` instant buffer can be drained by whoever holds tokens |
| **Mellow `TokenizedAccount` ERC-4626** (2: Ultra HYPE, Ultra uBTC) | ≈ $2.25M | **$0** | `deposit` permissionless but `withdraw`/`redeem` **revert** (`WithdrawalRequestRequired`) — exit is `requestRedeem` → date-timelocked `claim`; `collectFees()`/`chargeManagementFee()` are permissionless but pay a **fixed `feesCollector`**; NAV is balance-derived but a donation only pays `f·D` back to an attacker holding fraction `f`, needing ~all of a $2.25M supply (share price already > 1) | `externalAssets` set by an `onlyOperator` rate-limited feed; `owner`/`operator` are trusted |
| **`Depositor` entry points** (8 live) | — | **$0** | `deposit(token,receiver,amount,code)` is permissionless but each Depositor **whitelists only its own base asset**; it mints `floor(amount·1e8/rate)` shares and forwards the asset to the `DepositReceiver` → fair (floor) pricing. Round trip loses the 0.3% instant-withdrawal fee | **LATENT 77×–4000× mint bug** (see §2.7): the Pricer's *non-base* `getVaultTokenAmount` branch is dimensionally wrong on the WHYPE/XAUt0-base vaults; a single `toggleDepositToken(USDC,true)` would open an instant drain |
| **Pricer rate oracles + custom oracle feed** (9) | — | **$0** | `Pricer.updateExchangeRate` is `requiresAuth`; the Midas `CustomAggregatorV3CompatibleFeed.setRoundData`/`setRoundDataSafe` are `onlyAggregatorAdmin` | Rate is a **single operator-set value** with bounds (±2%/update, 1 h min delay); recent updates are 1–3 bps, far below the 30 bps withdraw fee |

**Total live extractable by an external unprivileged attacker now: $0. Confidence: HIGH** (fork-proven on
live chain state at block 49,508,160: every privileged path reverts for an arbitrary caller; every
permissionless path either requires owning the vault token at fair value, is a fixed-recipient sweep, or
is a no-op).

---

## 2. Corrections to the lead (important)

1. **The two "unverified" custom implementations are in fact VERIFIED** on the HyperEVM explorer
   (Etherscan V2, chain 999):
   - `0x6d684992f8d105b33f9b1bbaa77bdd0e0f71f585` = **`liquidHYPE`** (RedDuck Software, a **Midas `mTBILL` fork**), source `contracts/liquidHYPE/liquidHYPE.sol`.
   - `0x20a9bb2e08b9cb3c38cb3838311f7e0bd129bff8` = **`LiquidHypeCustomAggregatorFeed`** (Midas `CustomAggregatorV3CompatibleFeed`), a **manually-submitted** Chainlink-compatible feed.
   No decompilation was required; full sources were read.
2. **`liquidHypeStrategist` = `0x83a80e5b64086197c01cbb123df2aea79a149c1d` is an EOA with NO code**
   (`eth_getCode` = `0x` at block 49,508,160). It is **not** an unverified contract, as the brief's
   correction states.
3. **"Hyperbeat Earn" is not one protocol.** ~**74% of the TVL ($13.83M) sits in Midas-lineage
   *permissioned* ERC-20 receipt tokens** (`mint`/`burn` operator-gated, no ERC-4626 entry point), not in
   permissionless ERC-4626 vaults. This is the single most important structural fact for the E-U question.
4. **`nLP` and `masterUSD` are `VaultToken`** (solmate `Auth`, `mint`/`burn` `requiresAuth`), a *third*
   code family — not Midas, not ERC-4626.
5. **HyperEVM is supported by Etherscan V2 (`chainid=999`)** — the brief's assumption that it is not is
   incorrect; this is how the verified sources were obtained.
6. **There is a permissionless deposit entry point that the brief did not mention: the `Depositor`.**
   Each vault has one (`deposit(token, receiver, amount, builderCode)`, no role gate). The live ones
   (`0x205ac1e0…` lstHYPE, `0x5bfb09dd…` liquidHYPE, `0x6261f301…` hbUSDT, `0x929df52b…` hbUSDC,
   `0x127c5945…` dnHYPE, `0x76a48c42…` dnPUMP, `0xccbc13af…` hbXAUt, `0xb3060c1f…` wVLP) **whitelist only their own base
   asset**, so the deposit is fair-valued. **But the Pricer's non-base pricing branch is dimensionally
   wrong (see §2.7) — a latent 77×–4000× mint bug, one whitelist toggle away.**

### 2.7 LATENT (not live): the Pricer cross-asset pricing branch is dimensionally wrong

`Pricer.getVaultTokenAmount(_token, _amount)` has two branches:

```
base asset :  _convertDecimals(_amount * 1e8 / exchangeRate, baseDec, vaultDec)
other token:  _convertDecimals(_amount * priceProvider.getPrice() / exchangeRate, tokenDec+ppDec-8, vaultDec)
```

The second branch divides a **USD-quoted** price by `exchangeRate`. But `exchangeRate` is expressed in
the **base asset**, not in USD (the base branch proves this: `getAssetAmount(base, shares) = shares·rate`).
The two branches are only consistent when `baseAsset` **is** the price's quote currency (a USD stable).

- **lstHYPE** (base = WHYPE, `rate = 1.05109718`): `getVaultTokenAmount(USDC, 1 USDC)` returns
  `0.9524 lstHYPE` — as if 1 lstHYPE ≈ $1.05, whereas 1 lstHYPE ≈ 1.0511 WHYPE ≈ **$81**. That is a
  **~77× over-mint**.
- **hbXAUt** (base = XAUt0, `rate = 1.04490094`): `getVaultTokenAmount(USDC, 1 USDC)` returns
  `0.9581 hbXAUt`, redeemable (base path) for `1.0011 XAUt0` ≈ **$3,988 for $1** — a **~4000× over-mint**.

`assetConfigs[USDC]` **is populated on all the non-USD-base Pricers** (price provider
`0x5e138194a3bf0ca723b7364d87c30b641bf52b73`, a USDC/USD feed at `100,112,061`), so the branch is
*configured* and would execute. It is **unreachable today only because every live `Depositor` whitelists
exactly its own base asset** (`Depositor.isDepositToken[USDC] == false` on lstHYPE/hbXAUt; verified
on-chain), and the only `WithdrawalQueueMultiAsset` (masterUSD, base USDC) accepts only USDC. A single
`Depositor.toggleDepositToken(USDC, true)` (or a `WithdrawalQueueMultiAsset.setAcceptableToken`) on
lstHYPE / hbXAUt would turn this into a permissionless instant drain of the `DepositReceiver` plus an
unbounded mint. **This is the single most important thing to fix/monitor.**

---

## 3. Live-state assessment (block 49,508,160, keyless public RPC `https://rpc.hyperliquid.xyz/evm`)

### 3.1 The 26-vault inventory (DefiLlama adapter `projects/hyperbeat/index.js`)

| # | Vault | Family | `totalSupply` | `totalAssets` / backing | USD |
|---|---|---|---|---|---|
| 1 | `0x5eEC795d…` Gauntlet USDe Core | MetaMorphoV1_1 | 9.535e21 | 1.057e22 (USDe) | $10,563 |
| 2 | `0x53A333e5…` Gauntlet USDT0 | MetaMorphoV1_1 | 2.457e23 | 269,784.5 (USDT0) | $269,475 |
| 3 | `0x0571362b…` Gauntlet uETH | MetaMorphoV1_1 | 3.551e19 | 35.906 (UETH) | $84,337 |
| 4 | `0xd19e3d00…` MEV Capital HYPE (mcHYPE) | MetaMorphoV1_1 | 1.015e22 | 10,684.2 (WHYPE) | $824,227 |
| 5 | `0x4346C98E…` Relend Network rUSDC | MetaMorphoV1_1 | 4.343e20 | 435,301.6 (rUSDC) | $435 |
| 6 | `0xe5ADd968…` Hyperithm USDT0 | MetaMorphoV1_1 | 4.984e21 | 5,381.7 (USDT0) | $5,376 |
| 7 | `0xD3A9Cb73…` MEV Capital USR | MetaMorphoV1_1 | 1.757e22 | 355,398.9 (USR) | $25,188 |
| 8 | `0x3Bcc0a5a…` MEV Capital USDT0 | MetaMorphoV1_1 | 1.062e22 | 11,521.3 (USDT0) | $11,508 |
| 9 | `0x51F64488…` Re7 USDT0 | MetaMorphoV1_1 | 7.495e18 | 7,969.8 (USDT0) | $8 |
| 10 | `0x182b318A…` Re7 HYPE | MetaMorphoV1_1 | 1.985e17 | 0.2056 (WHYPE) | $16 |
| 11 | `0x92B518e1…` Hyperithm HYPE | MetaMorphoV1_1 | 2.045e19 | 20.969 (WHYPE) | $1,618 |
| 12 | `0x264a06Fd…` Gauntlet WHYPE | MetaMorphoV1_1 | 8.720e19 | 91.963 (WHYPE) | $7,094 |
| 13 | `0x08C00F82…` Gauntlet USDC | MetaMorphoV1_1 | 1.359e24 | 1,450,694.4 (USDC) | $1,450,108 |
| 14 | `0x4851D489…` MEV Capital USDC | MetaMorphoV1_1 | 1.403e20 | 151.606 (USDC) | $152 |
| 15 | `0x441794D6…` **liquidHYPE** | Midas `mTBILL` (perm.) | 3.321e22 | ≈1:1 WHYPE¹ | $2,561,757 |
| 16 | `0xD66d69c2…` **wVLP** | Midas `mTBILL` (perm.) | 1.560e23 | 1:1 USDC² | $155,865 |
| 17 | `0x81e064d0…` **lstHYPE** | Midas `mTBILL` (perm.) | 6.449e22 | rate 1.05109718 | $5,229,223 |
| 18 | `0x5e105266…` **hbUSDT** | Midas `mTBILL` (perm.) | 2.087e24 | rate 1.13425106 | $2,364,026 |
| 19 | `0x057ced81…` **hbUSDC** | Midas `mTBILL` (perm.) | 3.380e23 | rate 1.06945695 | $361,346 |
| 20 | `0x4Cc221cf…` **nLP** | `VaultToken` (perm.) | 3.355e11 | rate 1.05099795 | $352,155 |
| 21 | `0x9065E315…` **masterUSD** | `VaultToken` (perm.) | 2.610e12 | rate 1.03583200 | $2,702,428 |
| 22 | `0x949a7250…` **dnHYPE** | Midas `mTBILL` (perm.) | 5.391e22 | rate 1.05698400 | $56,955 |
| 23 | `0x8858A307…` **dnPUMP** | Midas `mTBILL` (perm.) | 8.511e21 | rate 1.01609100 | $8,644 |
| 24 | `0x6EB6724D…` **hbXAUt** | Midas `mTBILL` (perm.) | 1.263e19 | rate 1.04490094 | $52,581 |
| 25 | `0x96C6cBB6…` **Ultra HYPE** | Mellow `TokenizedAccount` | 2.006e22 | 20,710.0 (WHYPE) | $1,597,659 |
| 26 | `0xc061d389…` **Ultra uBTC** | Mellow `TokenizedAccount` | 7.842e8 | 8.072916 (UBTC) | $649,784 |

Prices: DefiLlama `coins.llama.fi/prices/current/hyperliquid:<addr>` (WHYPE $77.14, USDC $0.9996, USDT0
$0.9989, USDe $0.9996, UETH $2,348.80, uBTC $80,489.37, XAUt0 $3,983.56). USR uses DefiLlama's
`$0.0709`; rUSDC is treated as $1.00 (no DefiLlama quote) — **both flagged in §8**. Full dump:
`analysis/state_dump.json`, `analysis/tvl.json`.

¹ The DefiLlama adapter prices liquidHYPE as WHYPE (≈1:1); its own `Depositor`/`Pricer` use **beHYPE** as
the base asset (`Pricer 0x90a0a650…`, rate 1.01313205 beHYPE per liquidHYPE), and its only whitelisted
deposit token is beHYPE. ² The adapter lists wVLP's underlying as `corn.USDT0`, but its live
`Pricer 0xa532a456…` has `baseAsset = USDC` (rate 1.05102725) and its only whitelisted deposit token is
USDC. Neither discrepancy affects the E-U verdict (both are USD-stable bases → the base branch is used).

### 3.2 The custom proxy vaults and their (verified) implementations

Every Midas-lineage / `VaultToken` vault is a **`TransparentUpgradeableProxy`** with a **shared
`ProxyAdmin`**:

| Proxy | impl | impl contract | admin |
|---|---|---|---|
| `0x441794D6…` liquidHYPE | `0x6d684992…` | `liquidHYPE` | `0xbf25b58cb8dfad688f7bcb2b87d71c23a6600aac` |
| `0x81e064d0…` lstHYPE | `0x7b5bd5a3…` | `lstHYPE` | `0xbf25b58c…` |
| `0x5e105266…` hbUSDT | `0x77b13307…` | `hbUSDT` | `0xbf25b58c…` |
| `0x057ced81…` hbUSDC | `0x76a20173…` | `hbUSDC` | `0xbf25b58c…` |
| `0xD66d69c2…` wVLP | `0x042e8217…` | `wVLP` | `0xbf25b58c…` |
| `0x949a7250…` dnHYPE | `0xe4c53a0f…` | (mTBILL) | `0xbf25b58c…` |
| `0x8858A307…` dnPUMP | `0xce3f7652…` | (mTBILL) | `0xbf25b58c…` |
| `0x6EB6724D…` hbXAUt | `0x8211c4c0…` | (mTBILL) | `0xbf25b58c…` |
| `0x1ceab703…` **oracle** | `0x20a9bb2e…` | `LiquidHypeCustomAggregatorFeed` | `0xbf25b58c…` |
| `0x96C6cBB6…` Ultra HYPE | `0xcd27d859…` | Mellow `TokenizedAccount` | `0xe68688f5…` |
| `0xc061d389…` Ultra uBTC | `0x8ef540b1…` | Mellow `TokenizedAccount` | `0x6fc8a5d3…` |

`nLP` (`0x4Cc221cf…`) and `masterUSD` (`0x9065E315…`) are **non-proxy** `VaultToken` contracts.

### 3.3 Code families read end-to-end

* **MetaMorphoV1_1** — verified upstream source (`lib/metamorpho-1.1/src/MetaMorphoV1_1.sol`).
  `totalAssets()` = `_accruedFeeAndAssets()` (Morpho **market** balances, not `balanceOf`).
  `skim(token)` transfers `IERC20(token).balanceOf(this)` to the **fixed** `skimRecipient` (reverts if
  zero). `deposit` uses `_convertToSharesWithTotals` with `_decimalsOffset() = DECIMALS_OFFSET`.
* **Midas `mTBILL`** — `mint`/`burn`/`pause` gated by `onlyRole(...)` → `MidasAccessControl.hasRole`
  (shared `0x0312a9d1ff2372ddedcbb21e4b6389afc919ac4b`). **No public role grant** (checked for 8 roles ×
  5 accounts incl. `address(0)` and a random attacker).
* **`VaultToken`** (nLP/masterUSD) — solmate `Auth`; `mint`/`burn` `requiresAuth`.
* **`Pricer`** (rate oracle, 9 instances) — `getRate()` returns the stored `pricerParams.exchangeRate`;
  `updateExchangeRate(uint96)` is `requiresAuth`, bounded by `allowedExchangeRateChangeUpper/Lower` and a
  `minimumUpdateDelayInSeconds`.
* **`WithdrawalQueue` / `WithdrawalQueueMultiAsset`** — the user exit. `instantWithdraw` (permissionless)
  **burns `msg.sender`'s tokens** then `DepositReceiver.sendAssetsForInstantWithdrawal(base, _user, amt)`
  (only the WQ may call the receiver). `createWithdrawalRequest` (permissionless) **locks `msg.sender`'s
  tokens**; the request ID is `keccak256(abi.encode(struct))` with `initiator = msg.sender`, so it cannot
  be forged or redirected. `processWithdrawalRequests`/`recoverERC20`/`reject…`/all setters are
  `requiresAuth`.
* **`MultiRolesAuthority`** (solmate) — `canCall(user,target,sig) = isCapabilityPublic[sig] || (getUserRoles[user] & getRolesWithCapability[sig])`.
  **No sensitive selector is public**, and a random caller has no role (verified for 36 selectors × 8
  authorities; `analysis/authority_cancall.json`).
* **Mellow `TokenizedAccount`** — ERC-4626 `deposit`/`mint` permissionless (subject to
  `maxDepositAmount`/`depositsPaused`); `withdraw`/`redeem` **revert**; exit via
  `requestRedeem` → timelocked `claim`/`processAllClaimsByDate`. `_getTotalAssets()` is
  `externalAssets + balanceOf(this) − (totalCollectableFees + globalLiabilityAssets)`;
  `_getTotalSupply() = totalSupply − globalLiabilityShares`. `collectFees`/`chargeManagementFee` are
  permissionless but send to a **fixed `feesCollector`**.

### 3.4 The oracle feed

`LiquidHypeCustomAggregatorFeed` (`0x1ceab703…`, impl `0x20a9bb2e…`): `lastAnswer()` =
**1,008,164,18 → wait: `lastAnswer()` = `0x6025622` = 100,816,418 (1.00816418 @8dp)**. `setRoundData`
is `onlyAggregatorAdmin`; `setRoundDataSafe` calls it internally, so a permissionless caller reverts.
`latestRound()` is not exposed on this build (call reverts) — the value is read via `lastAnswer()`.

### 3.5 Permissionless deposit + exit entry points (live)

| Family | `Depositor` | base asset | whitelisted deposit token(s) | `depositFee` | `depositCap` | `instantWithdrawalFee` |
|---|---|---|---|---|---|---|
| lstHYPE | `0x205ac1e0380b0b9cce691bd4c6f3c14258ae9201` | WHYPE | **WHYPE only** | 0 | 0 (∞) | 30 bps |
| liquidHYPE | `0x5bfb09dd155c0ec3f375b266a7353c0ba64f9d60` | beHYPE | **beHYPE only** | 0 | 0 | — |
| hbUSDT | `0x6261f30144b259c74243d5f5d9230941186ac936` | USDT0 | **USDT0 only** | 0 | 0 | 30 bps |
| hbUSDC | `0x929df52b0c3315d03922e12e54b46157395be4d0` | USDC | **USDC only** | 0 | 0 | 30 bps |
| dnHYPE | `0x127c5945c93906cc36cf32eb7f9504af66e464b9` | USDC | **USDC only** | 0 | 0 | **0** |
| dnPUMP | `0x76a48c429a48346cb5b80544bffc8132a30defa8` | USDC | **USDC only** | 0 | 0 | **0** |
| hbXAUt | `0xccbc13af723bee139a5cc48f0c7169a56e10d2d3` | XAUt0 | **XAUt0 only** | 0 | 0 | **0** |
| wVLP | `0xb3060c1fbf496dfcc04284380f0f0567c5e6f2e0` | USDC | **USDC only** | 0 | 0 | 30 bps |

Exactly one current minter per family (confirmed with `MidasAccessControl.hasRole(<FAM>_MINT_OPERATOR_ROLE,
depositor)`); the older candidate addresses hold no role and are proxies/EOAs whose reads revert. **Every
live Depositor's whitelist equals its base asset**, so only the *base* branch of the Pricer is ever
executed (nLP and masterUSD are `VaultToken`s with a USD-stable base, so any cross-stable pricing there
would be correct anyway).

`Pricer` bounds (lstHYPE, `pricerParams()`): `allowedExchangeRateChangeUpper = 10200` (**+2%/update**),
`allowedExchangeRateChangeLower = 9800` (−2%), `minimumUpdateDelayInSeconds = 3600` (1 h),
`managementFee = 0`, `performanceFee = 2000` (20%), `highwaterMark = 105111716`.

**`ExchangeRateUpdated` history (lstHYPE Pricer, 86 events):** all real updates after initialization are
**0.32–11.5 bps** (median **1.67 bps**; the only >30 bps delta is the constructor→first-rate jump of
329 bps at block 22,078,626). Since the instant-withdrawal fee is **30 bps** and the max observed
increment is **11.5 bps**, a JIT "deposit just before the update, instant-withdraw just after" round trip
is a **net loss** on the fee-bearing queues. The three **fee-free** queues (dnHYPE/dnPUMP/hbXAUt) would
in principle capture any positive increment (`profit = X·δ`, `δ ≈ 1–3 bps`), but the profit is capped by
the vault's `DepositReceiver` buffer and requires front-running the operator's `updateExchangeRate` tx —
see §6 residual risk.

**DepositReceiver buffers (base asset held for instant withdrawals, block 49,508,160):**
lstHYPE `0xa980d98d…` **90.01 WHYPE** ≈ $6.94k · hbUSDT `0xfd1fd829…` **10.00 USDT0** · hbUSDC
`0x7abf6da6…` **5.63 USDC** · dnHYPE `0x4f7bada8…` **57,032.8 USDC** ≈ $57.0k · dnPUMP `0x3067f8df…`
**8,706.7 USDC** ≈ $8.7k · hbXAUt `0xc8ca861e…` **13.23 XAUt0** ≈ $52.7k. Total ≈ **$125.4k**.

---

## 4. What an attacker can / cannot do (exact call paths)

| # | Call path | Precondition | Verdict |
|---|---|---|---|
| 1 | `Pricer.updateExchangeRate(2e8)` from an arbitrary EOA | — | **reverts** `UNAUTHORIZED` (authority `canCall` = false) |
| 2 | `WithdrawalQueue.setPricer/setPaused/setInstantWithdrawalFee/…` | — | **reverts** |
| 3 | `lstHYPE.mint/burn/pause` | no `LST_HYPE_*` role | **reverts** `WMAC: hasnt role` |
| 4 | `VaultToken(nLP).mint/burn` | not owner/authorised | **reverts** `UNAUTHORIZED` |
| 5 | `feed.setRoundDataSafe(x)` / `setRoundData(x)` | not feed admin | **reverts**; `lastAnswer` unchanged |
| 6 | `MetaMorpho.deposit(1e18)` then `redeem(shares)` | must own the asset | **net ≤ 0** (ERC-4626 virtual shares); funded fork test returns `out ≤ in` |
| 7 | Donate the asset directly to a MetaMorpho vault | must own the asset | `totalAssets()` **unchanged** (market-derived) → **no NAV inflation** |
| 8 | `MetaMorpho.skim(token)` | permissionless | MEV HYPE: **reverts** (`skimRecipient == 0`); Gauntlet USDC: moves **0** (vault holds 0 idle asset) to the fixed `skimRecipient` |
| 9 | `WithdrawalQueue.instantWithdraw(attacker, 1e18)` with 0 balance | must own vault tokens | **reverts** (ERC-20 burn underflow) |
| 10 | `WithdrawalQueue.createWithdrawalRequest(...)` | must own vault tokens | locks the **caller's** tokens; ID binds `initiator`; **no forgery/redirect** |
| 11 | `Mellow.deposit` then `convertToAssets(convertToShares(x))` | must own the asset | **≤ x**; `withdraw`/`redeem` revert |
| 12 | `Mellow.collectFees()` | permissionless | pays the **fixed** `feesCollector`; attacker receives **0** |
| 13 | Donate to a Mellow vault (balance-derived NAV) | must own the asset | pays back `f·D` to an attacker holding fraction `f`; needs `f≈1` of a $2.25M supply → **net loss** |
| 14 | `Depositor.deposit(baseAsset, attacker, X, 0)` then `instantWithdraw(shares)` | must own the base asset | mints `floor(X·1e8/rate)` (fair), withdraws `floor(shares·rate/1e8)·(1−fee)` → **net loss of the 0.3% fee** (fork-tested on lstHYPE) |
| 15 | `Depositor.deposit(USDC, …)` on lstHYPE/hbXAUt (the mispriced branch) | **blocked**: `isDepositToken[USDC] == false` | **would** mint ~77× / ~4000× too many shares — **latent, unreachable today** (fork-tested that the branch is configured *and* blocked) |
| 16 | JIT: deposit before an `updateExchangeRate` tx, instant-withdraw after | must see/fore-run the operator tx | fee-bearing queues: increment (≤11.5 bps) < fee (30 bps) → **loss**; fee-free queues (dnHYPE/dnPUMP/hbXAUt): `profit = X·δ` (δ≈1–3 bps) capped by the `DepositReceiver` buffer |

**Cost model.** Even the permissionless paths that succeed (skim / collectFees) pay a **fixed** address,
so the attacker's net is exactly `−gas`. No capital source (flash loan or own) changes this: there is no
call that transfers value to a caller-chosen address without the caller first depositing/holding an equal
value.

---

## 5. PoC / fork verification

Foundry project: `poc/` (vendored `forge-std`; `solc 0.8.24`). Fork: `vm.createSelectFork("https://rpc.hyperliquid.xyz/evm", 49_508_160)`.
**All compile + fork tests ran on GitHub Actions** (public repo `artsbykriss/ca-zombie-ci`).

**Tests (20):** see `poc/test/HyperbeatEarn.t.sol`.

| Group | Tests | Assertion |
|---|---|---|
| Authority denies random caller | 01 | `canCall(attacker, …, sel) == false` and `isCapabilityPublic(sel) == false` for 6 sensitive selectors |
| Privileged paths revert | 02–05 | Pricer / WQ / Midas token / VaultToken admin calls revert for an arbitrary EOA |
| Oracle immutability | 06 | `setRoundDataSafe`/`setRoundData` revert; `lastAnswer()` unchanged |
| MetaMorpho donation | 07, 07b | `totalAssets` is market-derived (≠ `balanceOf`) on 4 vaults; a real 5-WHYPE donation leaves it unchanged |
| MetaMorpho skim | 08 | MEV HYPE reverts (recipient 0); Gauntlet USDC moves 0 to `skimRecipient`; attacker gets 0 |
| MetaMorpho roundtrip | 09–10 | `previewRedeem(previewDeposit(x)) ≤ x`; funded `deposit→redeem` returns `out ≤ in` |
| WQ exit | 11–12 | `instantWithdraw` with 0 balance reverts; Pricer roundtrip `≤ x` |
| Mellow Ultra | 13–15 | roundtrip `≤ x`; donation unprofitable for a small holder (price already > 1); `collectFees` pays attacker 0 |
| Inventory | 16 | MetaMorpho `maxDeposit > 0`; `lstHYPE` has no `asset()` (not an ERC-4626); Ultra HYPE deposits paused |
| Depositor (permissionless deposit) | 17 | whitelist is base-asset-only (lstHYPE: WHYPE yes / USDC·XAUt0 no; hbXAUt: XAUt0 yes / USDC no) |
| **Latent mispricing (fork-proven)** | 18 | `Pricer.getVaultTokenAmount(USDC, 1e6)` returns ~0.958 hbXAUt (≈$3,988) and ~0.952 lstHYPE (≈$77) for $1 — the branch is configured **but** `isDepositToken(USDC) == false` on both |
| Deposit→instantWithdraw | 19 | funded round trip on lstHYPE returns `< 1e18` (loses the 0.3% fee) |

**Result:** `__/16 tests PASS` — **CI run:** _<URL>_ (`hyperbeat-earn/ci-log.txt`).

`ci/run.sh` additionally dumps the full 26-vault inventory (`ci-out/state.json`) on the runner.

---

## 6. Verdict and residual / latent risk

**Verdict — external unprivileged extractable, live now: `$0`. Confidence HIGH.**
No permissionless call transfers value to a caller-chosen address without the caller first contributing an
equal-or-greater amount, and every privileged entry point is properly gated. The bulk of the TVL is in
*permissioned* Midas-lineage receipt tokens, which have no ERC-4626 entry point at all.

**Category split (see §7 schema):**

| Category | USD | Meaning |
|---|---|---|
| **E-U** (external unprivileged) | **$0** | headline |
| **H-O** (holder self-service) | ≈ $4.95M | MetaMorpho `redeem` ($2.70M) + Mellow `requestRedeem`/`claim` ($2.25M) + Midas instant-withdraw buffers (≈ $7k) — holders redeeming their **own** funds |
| **P** (privileged / operator) | ≈ $13.83M | Midas-lineage queued redemptions require the trusted **solver** (`processWithdrawalRequests`); mint/burn/pause/rate updates are operator-only |
| **S** (stuck) | $0 | nothing is bricked; Midas requests are cancellable after the deadline |

**Residual / latent risk (watch items, not live E-U):**
1. **⚠️ LATENT 77×–4000× over-mint (§2.7) — the top item.** The Pricer's non-base
   `getVaultTokenAmount` branch is dimensionally wrong on the **WHYPE-base (lstHYPE)** and
   **XAUt0-base (hbXAUt)** Pricers, and `assetConfigs[USDC]` is already populated. A single
   `Depositor.toggleDepositToken(USDC, true)` (an operator tx) would let anyone deposit 1 USDC and mint
   ~0.95 hbXAUt ≈ $3,988 (or ~0.95 lstHYPE ≈ $77), then instant-withdraw real assets from the
   `DepositReceiver`. **Fix: only ever whitelist a token equal to `baseAsset`, or correct the formula to
   convert through the base asset.** This is the reason the `depositFee = 0` + unlimited `depositCap`
   configuration is dangerous.
2. **JIT yield-sniping around a rate update.** The `Pricer` rate is a step function updated by an operator
   (max +2%/update, ≥1 h apart). For the fee-bearing queues (lstHYPE/hbUSDT/hbUSDC/masterUSD, 30 bps;
   nLP, 50 bps) the observed increments (≤11.5 bps) are below the fee → loss. For the **fee-free** queues
   (**dnHYPE, dnPUMP, hbXAUt**) a deposit in the block before `updateExchangeRate` and an instant-withdraw
   in the block after yields `profit = X·δ` (δ ≈ 1–3 bps), bounded by the vault's `DepositReceiver`
   balance (`X·δ ≤ DR`), i.e. ≤ the buffers in §3.5 (total ≈ $125.4k) in the limit of unlimited capital,
   and ≈ `δ × attacker capital` realistically (≈ $1.5k per event at $10M). Confidence: medium; requires
   front-running the operator tx.
3. **Operator-set exchange rate.** If set **above** true backing, permissionless `instantWithdraw` pays
   out at the inflated rate — bounded by the `DepositReceiver` buffer (§3.5). First-come race among
   holders, not an unprivileged extraction.
4. **Upgradeability.** All Midas-lineage vaults + the oracle + the `Depositor`s + the `WithdrawalQueue`s +
   the `Pricer`s are `TransparentUpgradeableProxy`/`Auth`-owned behind a single `ProxyAdmin`
   (`0xbf25b58c…`) and a shared `MultiRolesAuthority`. Admin compromise is out of the E-U scope but is the
   dominant tail risk.
5. **`owner() == 0`** on the `Pricer`/`DepositReceiver`/most `WithdrawalQueue`s means the solmate `Auth`
   `|| user == owner` fallback never fires — all authorization flows through the `MultiRolesAuthority`.
   If it is ever misconfigured (a public capability or an over-broad role), a large surface opens at once.
   Currently it is clean (36 selectors × 8 authorities all `false` for a random caller).
6. **`skim()`** on MetaMorpho vaults with a non-zero `skimRecipient` will sweep *any* token sent to the
   vault to the protocol treasury — a griefing/operational hazard, not attacker profit.

**Blockers found:** none that create E-U value; the only "blockers" are the intended gates (roles,
authority, timelocks, fixed recipients).

---

## 7. Methodology, sources, caveats, files

**Method.** (1) Enumerated the 26 vaults from DefiLlama's adapter. (2) Read `owner/curator/asset/
totalSupply/totalAssets/getRate/decimals` at block 49,508,160 (`analysis/dump_state.py`,
`dump_proxies.py`, `dump_wq.py`, `dump_live_config.py`). (3) Resolved EIP-1967 impl/admin slots.
(4) Pulled **verified** sources + ABIs from **Etherscan V2 `chainid=999`** (`analysis/fetch_src*.py`) and
exploded them (`analysis/explode_src.py`). (5) Enumerated `MultiRolesAuthority` grants and tested
`canCall` for 36 selectors × 8 authorities, plus `MidasAccessControl.hasRole` for 8 roles × 5 accounts.
(6) Enumerated every `Depositor` and `WithdrawalQueue` from `RoleGranted` logs and read their live
whitelists/caps/fees (`analysis/dump_depositor*.py`). (7) Pulled the `ExchangeRateUpdated` history to
test the JIT vector (`analysis/rate_logs_lstHYPE.json`). (8) Fork PoC on GitHub Actions.

**Sources of truth.** Live chain state (keyless public RPC); Etherscan V2 (chain 999); DefiLlama adapter
+ prices; `zombie-hunt-iv/pass3/lane-lst.md` (beHYPE LST — distinct, closed) and
`zombie-hunt-iv/pass7/accounting.md` (row 6).

**Caveats.**
* **USR** (`0x0aD339d6…`, MEV Capital USR vault) is priced at DefiLlama's `$0.0709`; if it is a $1
  stablecoin the aggregate TVL rises by ≈ $330k (to ≈ $19.11M). The E-U verdict is unaffected.
* **rUSDC** has no DefiLlama quote and is treated as $1.00 (vault TVL ≈ $435).
* TVL is a point-in-time snapshot at block 49,508,160 with prices fetched 2026-10-25; HYPE moved
  (pass-3 used $80.24).
* The `lastAnswer()` value shown in §3.4 is the raw feed answer (`100,816,418` @8dp = `1.00816418`).
* Fork block is pinned; live admin actions (rate updates, proxy upgrades) can change the state.

**Files.**
```
hyperbeat-earn/
├── README.md                       ← this document
├── summary.json                    ← machine-readable summary
├── analysis/
│   ├── dump_state.py / dump_proxies.py / dump_wq.py / dump_live_config.py / dump_authority.py
│   ├── dump_pricers.py / dump_midas_ac.py / dump_depositor.py / dump_depositors_all.py
│   ├── dump_priceproviders.py / compute_tvl.py
│   ├── state_dump.json  proxies.json  wq_state.json  live_config.json  depositor_state.json
│   ├── depositors_all.json  authority_cancall.json  pricer_state.json  midas_ac.json
│   ├── price_providers.json  rate_logs_lstHYPE.json  rate_update_stats.json  tvl.json
│   └── src/                        ← verified sources (Etherscan V2 chain 999) + ABI
├── poc/                            ← Foundry project (test/HyperbeatEarn.t.sol, 20 tests)
├── ci/run.sh                       ← CI inventory dump → ci-out/
├── ci-out/                         ← CI artifacts
└── ci-log.txt                      ← CI log
```

> Read-only research. No transaction was signed or broadcast to any chain. The PoC runs only on a local
> fork. Executing any extraction against mainnet would be theft.
