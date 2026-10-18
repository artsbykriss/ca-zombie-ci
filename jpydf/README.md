# JPYdf — CollateralVault / dToken (USDC + wstETH branches)

**Date:** 2026-10-18 · **Chain:** Ethereum · **Status:** read-only; fork PoCs only; no mainnet transactions signed or sent.

**Scope:** the two live `CollateralVault` ERC-1967 proxies — USDC `0x087Ebaf3F1b094b2046912a5E5F0BaD78dF3eAa7` (impl `0x878da559d17458d84fd7a42804ccaea53c2f10b5`) and wstETH `0x6042755eCCa71A1Be9C7091441ca5bEaA6b520e4` — their `DToken`s, the Aave-v3 and Morpho-v2 push strategies, and the `receiveFromStrategy` / `backstopDeposit` / `claim` accounting at block **26,217,683**.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Live external-unprivileged extractable now | **$0** (high confidence) |
| Why closed | `receiveFromStrategy` is `NotRegisteredStrategy` for every non-strategy caller; `claim` pays `request.owner`; dToken is minted/burned 1:1 by the vault; the backstop is a one-way reserve excluded from `bufferBalance`; a donation raises the buffer but cannot be redeemed by the donor; the strategy valuations are real (Aave aToken + Morpho shares) and cover liabilities. |
| TVL | **$844,153.9** (USDC branch $604,794.46 + wstETH 79.7289 × $3,002.16 = $239,359.4) |
| Holder-only recoverable (H-O) | $0 stranded. All dToken holders can redeem 1:1; no pending requests (`nextRequestId = 1`, `pendingWithdrawals = 0`). |
| Privileged (P) | **$844,153.9** — UUPS `GOV_ROLE` upgrade authority, including one plain EOA `0xa3d046f3…1722`. A GOV upgrade can replace the implementation and drain. This is governance risk, not E-U. |
| Stuck (S) | $0 now. Latent: a venue loss that pushes `backingRatio < 1` makes `_requireConfirmedFullyBacked` revert all deposits/redeems/claims until a WRITEOFF_ROLE recovery/writeoff. |

**Headline: the `receiveFromStrategy`/backstop lead is falsified — the accounting is 1:1 and the entrypoint is strategy-gated. External unprivileged extraction is $0.**

---

## 2. Mechanism in exact terms

`CollateralVault` is an upgradeable (UUPS) custody vault per collateral asset. It mints `DToken` 1:1 (decimals-adjusted) for deposits, serves redemptions from a liquid buffer, queues the remainder as a 3-day delayed claim, and pushes buffer excess into whitelisted strategies.

1. **Deposit / redeem.** `deposit(amount)` transfers the underlying, measures the actual receipt, and mints `convertToDToken(received)` dToken. `redeem(dTokenAmount, receiver)` checks full backing, burns the dToken, pays `min(buffer, needed)` immediately, and queues the remainder as a `WithdrawRequest` owned by `receiver`. `claim(requestId)` is permissionless but pays `request.owner`; it requires full backing and sufficient buffer.
2. **Liabilities.** `actualLiabilities = convertToUnderlying(dToken.totalSupply) + pendingWithdrawals`. There is no share price and no first-depositor math: dToken is 1:1 with the underlying, so donation/first-depositor attacks do not apply.
3. **Strategies (push model).** Only the vault can `deposit` into a strategy; only a vault role can call `sendToVault`/`sendProfitToVault`; the strategy pushes principal back through `Vault.receiveFromStrategy(declaredAmount)`. The vault measures its own balance delta and reduces/invalidate its valuation cache. A non-registered caller reverts before any transfer.
4. **Valuation.** `totalUnderlying = rawBalance + Σ min(strategy.estimatedTotalUnderlying, principal)`; `backingRatio` is 1.0 when assets ≥ liabilities. User flows use **live** strategy values via `_requireConfirmedFullyBacked`, not the cache.
5. **Backstop.** `backstopDeposit` is permissionless, mints nothing, and increments `_backstopReserve`. `bufferBalance = rawBalance − reserve`, so the backstop is not spendable by redeem/claim/allocate; only `GOV_ROLE` can `releaseBackstopToBuffer`.
6. **Strategies in the USDC branch.** Aave-v3 (`0xf91acaa3…7c63`) and Morpho-v2 (`0x7be8e8e3…1946`), each 50% weight, cap $254,882.275201. Both track **own** scaled shares / shares to ignore third-party donations; Aave uses `_ownScaledBalance` capped by the live aToken scaled balance, Morpho uses `_ownShares` capped by the live share balance.

---

## 3. Live-state assessment (block 26,217,683)

### 3.1 USDC branch

| Field | Value |
|---|---|
| Vault | `0x087Ebaf3F1b094b2046912a5E5F0BaD78dF3eAa7` |
| Implementation | `0x878da559d17458d84fd7a42804ccaea53c2f10b5` (UUPS) |
| Underlying | USDC `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| dToken | `0x01DD27D3422df99a56C60945E561243a8027262c` (`dUSDC`, 18 dp) |
| Treasury | `0x739b9e6beb4c278dfc327523880fdbafe4bd129d` |
| `bufferBalance` | **120,958.892449 USDC** |
| `backstopBalance` | **1.000000 USDC** |
| `totalUnderlying` | **604,795.462241 USDC** |
| `actualLiabilities` | **604,794.462241 USDC** |
| `backingRatio` | **1.000000000000000000** |
| `pendingWithdrawals` / `nextRequestId` | 0 / 1 (no queued claims) |
| Pauses | deposit/redeem/claim/allocation all false |
| `withdrawDelay` | 259,200 s (3 days) |
| Buffer config | 2,000 bps target, 63,720.568801 floor |
| Allocator | `maxMove = 191,160.506371`, cooldown 1,800 s, last 1,792,203,071 |

### 3.2 wstETH branch

| Field | Value |
|---|---|
| Vault | `0x6042755eCCa71A1Be9C7091441ca5bEaA6b520e4` |
| dToken | `0xb1f83c8e22f8644858c99675260c642403fae85c` (`dwstETH`, 18 dp) |
| Underlying | wstETH `0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0` |
| `bufferBalance` | **79.728909592771306519 wstETH** |
| `backstopBalance` | 0 |
| `totalUnderlying` = `actualLiabilities` | **79.728909592771306519 wstETH** |
| `backingRatio` | 1.0 |
| Strategies | **0** |
| `allocateMaxMove` | 0 (allocation disabled) |
| Pending | 0 / `nextRequestId = 1` |

### 3.3 Strategies (USDC branch)

| Strategy | Principal | `estimatedTotalUnderlying` | Live venue check |
|---|---|---|---|
| Aave-v3 `0xf91acaa3…7c63` | 241,917.784896 | **241,966.747711** | aToken `0x98c23e9d…6f5c` balance 241,966.667997; scaled 203,321.936097; underlying USDC |
| Morpho-v2 `0x7be8e8e3…1946` | 241,917.784896 | **241,971.942665** | Morpho vault `0x8c106eed…a3d0` shares 232,816.857146e18; vault `totalAssets` 124,570,586.307385; `totalSupply` 119,857,464.662e18; pps 1.039322 |

Live sum: 120,958.892449 + 1.000000 + 241,966.747711 + 241,971.942665 = **604,898.582825 USDC** ≥ liabilities 604,794.462241. The conservative `totalUnderlying` uses `min(est, principal)` and reports 604,795.462241 — still fully backed.

### 3.4 Roles / upgradeability

| Role | Holder |
|---|---|
| `GOV_ROLE` | `0xa3d046f3c3bdf081f190f6196c94755497891722` (**plain EOA**, code size 0) and `0xf27de84f11e089b838769edfcff9872bc45c84fe` (7,454-byte contract) |
| `GUARDIAN_ROLE` | `0xc89592b35278b6bbba2b710acd463e7a3c8d0eb0` (EIP-7702 smart EOA, 171-byte designator) |
| `WRITEOFF_ROLE` | `0xa8331cfa52bc67a468d6126b4a18419c6d830b4e` (EIP-7702) |
| `ALLOCATOR` / `WITHDRAWER` / `HARVESTER` / `TREASURY_TRANSFER` | `0x34b8edd6e6b8032ccdb930722486edd2ac9134b5` (EIP-7702) |
| Strategy `owner` | `0xc89592b3…0eb0` (EIP-7702) |
| Strategy `upgrader` | `0xf27de84f…84fe` |

`GOV_ROLE` can call `upgradeToAndCall`; the strategy `upgrader` can upgrade both strategy implementations. **One plain EOA is in GOV.** This is the $844k P risk.

---

## 4. What an attacker can and cannot do

### Cannot
| Claim | Live result | Evidence |
|---|---|---|
| `receiveFromStrategy(declaredAmount)` is unprivileged | Reverts `NotRegisteredStrategy()` for any EOA/contract not in `strategies[]` | `CollateralVault.sol:428-430`; PoC test |
| `claim(requestId)` lets a caller steal a request | Pays `request.owner`; `claimed` is set before transfer; unknown id reverts `RequestNotFound()` | `:338-364`; PoC test |
| First-depositor / donation share inflation | dToken minted 1:1 from measured receipt; no shares | PoC round-trip and donation tests |
| Backstop can be redeemed | `bufferBalance = raw − reserve`; only GOV can release | PoC: buffer unchanged after `backstopDeposit(100e6)` |
| Donation can be captured by a depositor | Donation raises `bufferBalance` and `totalUnderlying` but not liabilities; a depositor receives only their 1:1 claim | PoC: 1,000 USDC donated, depositor round-trips 1,000, donation remains |
| Strategy valuation is inflated by donated aTokens/shares | Strategies use `_ownScaledBalance` / `_ownShares` capped by live balances | Source review + live values |
| `forceDeallocateMorphoV2` is permissionless | `onlyRole(WRITEOFF_ROLE)` | `CollateralVault.sol:733-740` |
| Pause/claim grief | `pause*` are GUARDIAN; `unpause*` GOV | roles |

### Can (only privileged)
- `GOV_ROLE` can upgrade the vault (UUPS) and change `underlying`, `treasury`, buffer/allocation config, or add a malicious strategy. This can drain the $844k. It is **P**, not E-U.
- `WRITEOFF_ROLE` can write off strategy principal and force-deallocate Morpho; this can reduce backing but not pay the caller.
- Strategy `owner` can `emergencyWithdraw` idle underlying (destination fixed to the vault) and sweep non-position reward tokens (destination = vault treasury). It cannot send underlying elsewhere.

### Latent (conditional)
- **Venue loss → freeze, not theft.** If Aave/Morpho suffers a loss such that `totalUnderlying < actualLiabilities`, `_requireConfirmedFullyBacked` reverts `deposit`, `redeem` and `claim` until a recovery/writeoff. This is **S** for holders, not an E-U bank run. The backstop (1 USDC) is far too small to repair a material loss.
- **Aave liquidity:** `_doWithdraw` caps at the reserve's liquid underlying; an illiquid Aave reserve can delay withdrawals (the vault queues after 3 days).
- **Morpho liquidity:** `_doWithdraw` fail-softs to 0 after 8 half-size attempts; a liquidity-short market can delay withdrawals; `forceDeallocate` is the GOV/WRITEOFF recovery.

---

## 5. PoC / fork verification

Project: `poc/` (Foundry 1.8.5, solc 0.8.24, pinned fork block **26,217,683**).

| Test | Result | What it proves |
|---|---|---|
| `test_live_backing_and_pauses` | PASS | `backingRatio = 1e18`; totalUnderlying 604,795.462241 ≥ liabilities 604,794.462241; no pauses |
| `test_deposit_redeem_roundtrip_1to1` | PASS | 1,000 USDC → 1,000e18 dUSDC → 1,000 USDC; no queue, no fee |
| `test_receive_from_strategy_is_not_permissionless` | PASS | reverts `NotRegisteredStrategy()` |
| `test_claim_unknown_request_reverts` | PASS | reverts `RequestNotFound()` |
| `test_backstop_is_excluded_from_buffer` | PASS | +100 USDC backstop; buffer unchanged |
| `test_donation_is_not_extractable` | PASS | 1,000 USDC donation stays in buffer; depositor gets only their 1,000 back |
| `test_strategy_values_cover_liabilities` | PASS | Aave 241,966.75 + Morpho 241,971.94 + buffer 120,958.89 + backstop 1 ≥ liabilities |
| `test_wsteth_branch_is_idle_and_1to1` | PASS | 0 strategies; totalUnderlying == liabilities |

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39105855691 — **8/8 passed**, artifact `result-jpydf` (`ci-out/jpydf_live_state.txt`).

---

## 6. Verdict and residual risk

**E-U now: $0 (high confidence).** The specific lead — public `receiveFromStrategy(declaredAmount)` / `claim(requestId)` accounting — is **false**: `receiveFromStrategy` is gated to the two registered strategies, `claim` pays the stored owner, and the dToken is a 1:1 claim with no share price. The backstop is a one-way donation reserve, not a redeemable pool.

**Residual / latent:**
1. **P — $844k UUPS risk.** One plain EOA holds `GOV_ROLE`. An upgrade can drain both branches. Key hygiene / multisig migration is the mitigation. Not E-U.
2. **S — venue-loss freeze.** A material Aave/Morpho loss makes `backingRatio < 1` and freezes all user flows until a writeoff; the 1 USDC backstop is not a repair fund. Monitor strategy `estimatedTotalUnderlying` vs `principal` and the venue's bad-debt events.
3. **Liquidity delay.** Aave/Morpho liquidity shortages can turn immediate redemptions into 3-day queued claims; no principal loss by itself.
4. **`siUSD`/`iUSD` and `ysyBOLD` are not part of this vault**; they are Flex market collateral, covered in the Flex report.

**Re-arm:** watch `Upgraded` / `RoleGranted` on both vaults, `principal()` vs `estimatedTotalUnderlying()` on both strategies, and `backingRatio()`; a drop below 1e18 is an S-trigger, not an E-U.

---

## 7. Methodology, sources, caveats, files

- Read verified sources: `CollateralVault` (1,319 lines, 76 functions), `DToken`, `AaveV3Strategy`, `MorphoV2Strategy`, `BaseStrategy`, plus OpenZeppelin UUPS/AccessControl.
- Read live state at block 26,217,683: both vaults, both dTokens, both strategies, aToken and Morpho vault.
- Enumerated `RoleGranted` and `Upgraded` logs for both proxies. Confirmed the implementation is `0x878d…` and the roles above.
- Fork-tested all eight claims; no mainnet transaction was signed or sent.
- **Caveats:** point-in-time state; the vault is upgradeable, so the code hash can change. Strategy valuations are venue-reported (Aave normalized income / Morpho `convertToAssets`); a venue accounting failure that does not change those views would not be detected until a writeoff. USD marks: USDC $1.00, wstETH $3,002.16 (DefiLlama, 2026-10-18).

**Files:** `analysis/jpydf_live_state.json`, `analysis/jpydf_dtoken_state.json`, `analysis/jpydf_strategies.json`, `analysis/src/` (verified sources), `poc/test/JPYdfFork.t.sol`, `ci-out/jpydf_live_state.txt`, `ci-log.txt`, `ci-artifacts/`.
