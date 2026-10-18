# Alchemix V3 (MYT) — share math, adapters and liquidation surface

**Date:** 2026-10-18 · **Chains:** Ethereum, Optimism, Arbitrum, Base · **Status:** read-only; all exploit checks are fork-only; no mainnet transaction was signed or sent.

**Scope.** The residual-recon OPEN #4 lead (`$40.6M` DefiLlama): fresh **Morpho VaultV2 / Mix-Yield-Token (MYT)** vaults created through the permissionless `createVaultV2` factory (Apr 2026), plus the Alchemix-specific layer around them — 17 strategy adapters, 7 Alchemist CDP markets, 7 Transmuters, allocators, curator and fee vaults.

---

## 1. TL;DR

| Target | Live value (18-Oct-2026) | E-U now | Why closed / open | Latent risk |
|---|---|---|---|---|
| **MYT vault share math** (7 vaults, 4 chains) | **$39,861,279** totalAssets | **$0** | `VaultV2.accrueInterestView` caps *all* unrecognised gains (donations, penalty assets, strategy revaluation) at `maxRate` = **10%/yr** and realises losses instantly; virtual shares/asset = `1e12` for USDC vaults and `1` for 18-dec vaults; all 7 vaults are seeded (share price 1.003–1.024). A 5M USDC donation to the live mixUSDC vault was recognised as **64,771 USDC after 30 days (1.30%)**, not 5M; a fresh permissionlessly-created vault has `maxRate=0`, so a 1M USDC donation is recognised as **0** and the next depositor loses **0**. | A future vault left empty/unseeded **and** given a high `maxRate` by its allocator; or a strategy whose `realAssets()` can be driven down >5.3% (see §6) |
| **Alchemist CDP liquidation** (7 markets) | $24.5M debt / $39.3M MYT collateral | **$0** | 0 of 2,104 ETH positions and 0 of 68 Base positions have CR < 1.0526 (liquidation lower bound); worst ETH CR 1.1111, worst Base CR 1.11147. `liquidate(1202)` reverts on a fork. Liquidator fee is only **1.5% of the equity surplus** (≈0.079% of debt at the threshold). | A >5.3% MYT NAV drawdown (strategy loss / oracle failure) would open a standard keeper fee of ≤~$19k across all markets, not a protocol bug |
| **Transmuter / alAsset redemption** | 4.55M alUSD + 6,424 alETH + L2 | **$0** | `badDebtRatio` = **0.90** on every market (synthetics are 90% of the Transmuter's locked+held backing), so no haircut branch is active; `claimRedemption` is NFT-owner only and pays pro-rata. The 4.2% alUSD market discount is a **market arbitrage** (term ~5 months), not protocol extraction. | A future bad-debt event (`badDebtRatio>1`) plus the documented redemption-loss-avoidance paths (#58112/#58628 in the Nov-2025 Immunefi competition) |
| **Permissionless `forceDeallocate` / penalties** | 2% penalty on active adapters | **$0** | `forceDeallocate` on another holder's shares requires their share allowance (fork: reverts); `forceDeallocatePenalty` is **2e16 (2%)** on every funded adapter, so self-force-deallocation is loss-making. The documented "delayed yield/penalty dilution" (0xSimao M-5) is yield-only and capped by `maxRate`. | A large third-party `forceDeallocate` event + a well-capitalised back-runner; profit ≈ a share of the 2% penalty, not principal |
| **Governance / curator / allocator** | same $39.86M | n/a — **P** | Vault owner/curator/allocator and the Alchemist proxy admin are the v3 admin Safe (`0xF56D…293D` on ETH and per-chain Safes). `adapterRegistry = 0`, all timelocks are **0**, so a compromised curator+allocator pair (or the proxy admin) can add a malicious adapter and allocate the vault into it. | This is a trust assumption, not an unprivileged bug; it is the reason the P category is the full TVL |

**Total live extractable by an external unprivileged attacker: $0** (confidence **high** for principal; the only open forks are conditional and bounded at ≈$19k of keeper fees).

---

## 2. What "Alchemix V3" actually is (verified, not inferred)

- **MYT vaults are Morpho `VaultV2` contracts** (`lib/vault-v2/src/VaultV2.sol`, `pragma 0.8.28`, deployed through `VaultV2Factory.createVaultV2(owner, asset, salt)`). The factory source is verified on Etherscan; the 0.8.28 code includes the post-audit donation fix (explicit `accrueInterestView` + `maxRate`, 1 virtual asset, decimal offset).
- **The custom layer is the adapters + Alchemist + Transmuter**: 17 verified `MYTStrategy` adapters (Aave, ERC-4626/Fluid, Tokemak Auto, StakeDAO, wstETH, Ether.fi, sfrxETH, InfiniFi siUSD), all owned by the chain admin Safe; `AlchemistAllocator` is the vault's allocator (`onlyAdmin/operators`); `AlchemistCurator` is the vault's curator (`onlyAdmin/onlyOperator`).
- **Factory corrections.** ETH factory `0xdd56B00302e91C4c2B8246156BDEAa1cEDC58984` created exactly the two ETH vaults. Arb and OP factory `0x8c7C0C380bA4eE38461eb5a6b82e5d930EC11Ca2` is recognised by both chains' `isVaultV2()` for the four documented L2 vaults. Base factory `0x2584E8b0616b3E750492c9629a3b27679C410cb9` (the same address as the ETH/OP/Arb **Transmuter** — same deployer nonce, different chain) returns `isVaultV2(0xb8Be…) = true`. The r1 note "factory has no owner" is correct for the factory; it does not mean the vaults are ownerless — each vault has an owner/curator/allocator.

---

## 3. Live state (all reads at the block shown; USD at DefiLlama 18-Oct-2026 06:xx UTC)

### 3.1 The seven MYT vaults

| Chain | Vault | Asset | totalAssets | Share price (asset per 1e18 shares) | Adapters | Block |
|---|---|---|---|---|---|---|
| Ethereum | `0x29bcfeD246ce37319d94eBa107db90C453D4c43D` (mixWETH) | WETH | 10,865.0098 WETH | 1.007128 | 7 | 26,217,525 |
| Ethereum | `0x9B44efCa3e2a707B63Dc00CE79d646E5E5D24bA5` (mixUSDC) | USDC | 7,857,019.63 USDC | 1.023848 | 4 | 26,217,525 |
| Optimism | `0x91b8657aea26Caa8A0E9D6DD4E24727Ccf32F822` (mixWETH) | WETH | 1,010.8843 WETH | 1.006302 | 3 | 158,352,287 |
| Optimism | `0xAf510a560744880410f0f65e3341A020FBC2cA41` (mixUSDC) | USDC | 697,998.54 USDC | 1.012932 | 1 | 158,352,287 |
| Arbitrum | `0xfe8F223F3d81462F55bf8609897B8cEcfA4B195C` (mixWETH) | WETH | 112.2388 WETH | 1.010570 | 2 | 515,890,385 |
| Arbitrum | `0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651` (mixUSDC) | USDC | 36,265.16 USDC | 1.017524 | 3 | 515,890,385 |
| Base | `0xb8BeFE5a6941ca4022a52042075ff269C3C67467` (mixUSDC / alUSDb backing) | USDC | 2,387,031.90 USDC | 1.002987 | 4 | 52,757,007 |

**Total ≈ $39,861,279** (WETH $2,409.54; USDC $0.99974; prices `coins.llama.fi`, timestamp 1,792,304,398).

For every vault, `Σ adapter.realAssets() + idle = totalAssets` **exactly** (diff 0) — verified in `analysis/vault_reconciliation.json`. No accounting hole is visible today.

Roles: `owner` = v3 admin Safe `0xF56D…293D` (ETH) / `0x3Dda…181D` (OP) / `0xeE1A…484b` (Arb) / `0x24E9…c401` (Base); `curator` = `AlchemistCurator` (`0x7d61…02A4` ETH); `liquidityAdapter` = a 2%-penalty `ERC4626Strategy` (USDC) with `adapterRegistry = 0` and all gates `0`. All `maxRate = 3,170,979,198` (10%/yr); `timelock(addAdapter) = 0`; no abdications.

### 3.2 Alchemist markets

| Market | Debt | MYT collateral (shares → underlying) | Global CR | Position NFTs | CR < 1.0526? |
|---|---|---|---|---|---|
| ETH alUSD | 4,554,266.19 alUSD | 7,479,236.54 → 7,657,566 USDC | 1.682 | 1,244 | **0 / 948 with debt** |
| ETH alETH | 6,426.22 alETH | 10,664.17 → 10,740.3 ETH | 1.672 | 860 | 0 / 579 |
| OP alUSD | 534,441.41 alUSD | 666,650.97 → 675,275 USDC | 1.264 | 1,950 | aggregate only (RPC limit); no aggregate shortfall |
| OP alETH | 678.16 alETH | 997.01 → 1,003.3 ETH | 1.479 | 914 | aggregate only (RPC limit); no aggregate shortfall |
| Arb alUSD | 26,152.36 alUSD | 32,584.68 → 33,155.6 USDC | 1.268 | 1,454 | aggregate only (RPC limit); no aggregate shortfall |
| Arb alETH | 62.61 alETH | 110.73 → 111.9 ETH | 1.787 | 411 | aggregate only (RPC limit); no aggregate shortfall |
| Base alUSDb | 2,120,142.75 alUSDb | 2,378,564.27 → 2,385,661 USDC | 1.125 | 75 | **0 / 68** (worst 1.11147) |

Liquidation parameters on every market: `minimumCollateralization = 1.1111e18`, `collateralizationLowerBound = 1.0526e18`, `liquidationTargetCollateralization = 1.1111e18`, `liquidatorFee = 150` (1.5% of surplus), `protocolFee = 25` (0.25% of earmarked repayments), `repaymentFee = 0`, `depositsPaused = false`, `loansPaused = false`. Both fee vaults report `totalDeposits() = 0` — there is no protocol pot to drain on the liquidation path.

### 3.3 Transmuter backing

`badDebtRatio` = `totalSyntheticsIssued × 10^underlyingDecimals / (getTotalLockedUnderlyingValue + transmuterMYTvalue)`:

| Market | badDebtRatio | Meaning |
|---|---|---|
| ETH alUSD | 0.899529 | 10.05% over-collateralised |
| ETH alETH | 0.899754 | 10.03% |
| OP alUSD | 0.899977 | 10.00% |
| OP alETH | 0.900745 | 9.92% |
| Arb alUSD | 0.908611 | 9.14% |
| Arb alETH | 0.900095 | 9.99% |
| Base alUSDb | 0.900010 | 10.00% |

No market enters the `badDebtRatio > 1e18` haircut branch. The Transmuter holds only 0.14–2,921 MYT shares (dust to $3k), so redemption payouts come from the Alchemist's earmarked collateral as designed.

---

## 4. The share-math mechanism, exactly

`VaultV2.accrueInterestView()` (deployed source, `lib/vault-v2/src/VaultV2.sol:653-682`):

```solidity
realAssets = asset.balanceOf(vault) + Σ adapter.realAssets();
maxTotalAssets = _totalAssets + (_totalAssets * elapsed * maxRate) / 1e18;
newTotalAssets = min(realAssets, maxTotalAssets);          // gains capped
interest = newTotalAssets - _totalAssets;                   // losses realised instantly
```

- **Donations / penalties / strategy gains** raise `realAssets`, but `newTotalAssets` cannot exceed the `maxRate` envelope. Losses are not capped.
- **Share conversion** uses `(totalSupply + virtualShares) / (newTotalAssets + 1)`, with `virtualShares = 10^(18-decimals)` (1e12 for USDC, 1 for WETH). Deposits round shares down; withdrawals round shares up — both in the vault's favour.
- **One accrual per transaction** is enforced by `transient firstTotalAssets`; the second interaction in a tx returns the stored `_totalAssets`. That blocks intra-tx donate→deposit→redeem round trips.
- **Fresh vaults** start with `maxRate = 0`; only the allocator can raise it (10%/yr here). A permissionless `createVaultV2` vault is therefore *not* inflation-attackable by default.

The only way to make the classic first-depositor attack pay is to (a) control the vault's `maxRate`, (b) have an empty/unseeded vault, and (c) find a victim who deposits after the donation has been recognised. (a)–(c) are not true of any live vault.

---

## 5. What an unprivileged attacker can and cannot do (call paths)

| Path | Auth | Live result |
|---|---|---|
| `deposit(assets, onBehalf)` / `mint` | none | Works; routes assets to the liquidity adapter. Round-trip 100,000 USDC → **99,999 USDC** (1 USDC cost, no profit). |
| `redeem(shares, receiver, onBehalf)` | share owner/allowance | Works; pulls from idle then the liquidity adapter. |
| Donate USDC/WETH to a vault | none | `totalAssets()` capped at `maxRate`; 5M USDC donation recognised as **64,771 USDC after 30 days** (1.30%), **0** in the same block. |
| `forceDeallocate(adapter, data, assets, onBehalf)` | **none**, but penalty shares are taken from `onBehalf` via `withdraw()` and therefore need `allowance[onBehalf][msg.sender]` unless `onBehalf == msg.sender` | On another holder: **reverts** (fork test). On yourself: works, costs the 2% penalty. `ActionType.swap` is rejected on this path (`ForceDeallocateSwapNotAllowed`). |
| `allocate` / `deallocate` | `isAllocator` / `isSentinel` | Reverts for a random caller (`Unauthorized`). |
| `setMaxRate`, `setLiquidityAdapterAndData` | `isAllocator` | Reverts. |
| `submit`/timelocked curator setters | `curator` (AlchemistCurator, onlyOperator/Admin) | Reverts. |
| `liquidate(accountId)` / `batchLiquidate` | none | Only works below CR 1.0526. Every live ETH/Base position is healthy; `liquidate(1202)` reverts `LiquidationError`. |
| `selfLiquidate` | position NFT owner, healthy account | Self-service only. |
| `poke(tokenId)` | none | State sync only; no transfer. |
| `Transmuter.createRedemption` / `claimRedemption` / `pokeMatured` | none / NFT owner / none | Redemption requires transferring alAsset; claim is owner-only; `pokeMatured` only frees the deposit cap. |
| `Alchemist.redeem` | `onlyTransmuter` | Reverts for a random caller. |
| `Alchemist.deposit` to an existing `tokenId` | none (donation) | Adds collateral to someone else's position — a donation, not a theft. |

**Adapters.** Every state-changing adapter function is `onlyVault` or `onlyOwner` (all owners = chain admin Safe). `rescueTokens` cannot touch the protected receipt token/asset. No adapter exposes a permissionless sweep.

---

## 6. Fork PoC — what was proven

Project: `poc/` (Foundry, vendored forge-std). Fork: Ethereum block **26,217,600**; RPC supplied by CI (`FORK_RPC_URL`, public endpoint — not written to disk).

| Test | Assertion | Result |
|---|---|---|
| `test_A_donation_rate_capped_live_usdc` | 5,000,000 USDC donation to live mixUSDC cannot push `totalAssets` above the `maxRate` envelope; after 30 days only the envelope is recognised | **PASS** — 64,771 USDC recognised (1.30% of donation) |
| `test_B_fresh_vault_donation_blocked_by_zero_max_rate` | Permissionless fresh `VaultV2`: attacker deposits 1 USDC, donates 1,000,000 USDC, victim deposits 1,000,000 USDC; attacker redeems ≤1 USDC, victim ≥999,999 USDC | **PASS** — attacker 1 USDC, victim 1,000,000 USDC |
| `test_C_force_deallocate_without_allowance_reverts` | `forceDeallocate` on a holder with no share allowance reverts | **PASS** |
| `test_D_deposit_redeem_roundtrip_no_profit` | 100,000 USDC deposit → immediate redeem ≤ deposit | **PASS** — 99,999 USDC |
| `test_E_liquidate_healthy_position_reverts` | Worst ETH position (id 1202, CR 1.1111) is not liquidatable | **PASS** — revert |
| `test_F_live_vaults_seeded_and_reconciled` | Both ETH vaults are seeded (`totalAssets>0`, `totalSupply>0`, price > 1.0) | **PASS** — mixUSDC 1.023847; mixWETH 1.007139 |

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39104618340 — `6 passed, 0 failed` (4.03 s). Log: `ci-log.txt`.

Additional pure-math checks: `Σ realAssets + idle == totalAssets` for all 7 vaults (diff 0); `badDebtRatio < 1` on all 7 Transmuters; fee vaults empty; 0/2,104 ETH and 0/68 Base positions below 1.0526.

---

## 7. Closed leads / negative results (do not re-investigate)

1. **"First-depositor / donation inflation" on live vaults — closed.** All live vaults are seeded and `maxRate` is 10%/yr; losses are instant, gains are rate-limited. The only "profit" from a donation is the *pending* yield that was already accrued but not yet recognised; the donor pays far more than that gap.
2. **Immunefi #58435 "systemic accounting bug" — fixed in deployed code.** The report targets the Nov-2025 `MYTStrategy.deallocate()` (`newAllocation = abi.decode(data,(uint256)) - amountDeallocated`, returning the requested amount). The deployed 2026 adapter instead computes `totalValueBefore/After` and returns `change = (totalValueAfter - assets) - oldAllocation`, with `require(totalValueAfter >= assets)`. The vault pulls `assets` only after the adapter has approved them; any shortfall reverts in `_ensureIdleBalance`. The reported "returns requested, not received" bug is not present.
3. **Allocation-accounting underflow (#57930/#58452) — closed structurally.** `newAllocation = totalValueAfter - assets ≥ 0` because of the `require(totalValueAfter >= assets)`; `change ≥ -oldAllocation`, so `SafeCast.toUint256` cannot underflow.
4. **`forceDeallocate` access-control bypass (Kai, Medium) — accepted/documented, priced.** Penalty is 2% on every funded adapter; no allowance = no effect on another holder. It is a griefing/yield-dilution surface, not principal theft.
5. **Liquidation-fee theft / cross-account repayment fees (the dozens of Nov-2025 "SC-Critical" reports) — not live on these markets.** `repaymentFee = 0`; fee vaults are empty; `_maxRepaymentFeeInYield` and `_subCollateralBalance` cap fees to the account's own remaining collateral; no account is below the lower bound.
6. **Transmuter first-redeemer / donation — closed.** `claimRedemption` is NFT-owner only; `yieldTokenBalance` is read fresh each claim; `badDebtRatio` is 0.90 (no haircut); the 5M-donation style boost is not available because the Transmuter holds only dust MYT.
7. **alUSD / alETH market discount (4.2% / 2.8%) — a market arbitrage, not E-U.** It is a holder/buyer term trade against the Transmuter's 1:1 redemption (≈10% annualised for alUSD at the 5-month term), and the prior residual row already parked it. It does not move protocol funds to an unprivileged attacker beyond the protocol's own peg promise.

---

## 8. Verdict, residual and re-arm conditions

**Verdict: E-U $0** (high confidence for principal). The fresh-deployment lead does not survive contact with the deployed code: the Morpho V2 `maxRate` design closes donation/inflation, the Alchemist has no liquidatable positions and caps liquidation fees to the account's own surplus, and the Transmuter is over-collateralised with no active haircut. The only live unprivileged value is the standard keeper fee if a position becomes unhealthy, and the documented yield-dilution around `forceDeallocate`/`maxRate` — both conditional and ≤~$19k in the extreme.

**P (governance trust): $39,861,279.** The vault owner/curator/allocator (admin Safe + `AlchemistCurator` + `AlchemistAllocator`) and the Alchemist proxy admin can add an arbitrary adapter (`adapterRegistry = 0`), set `maxRate`, set the liquidity adapter and (for the Alchemist) upgrade the implementation. All timelocks are 0. This is a trust assumption, not an unprivileged bug, but it is the full TVL.

**H-O: $0** (nothing is stuck; every MYT/alAsset holder can exit via the vault/Transmuter at NAV).
**S: $0** identified.

**Re-arm conditions (watch):**
- A new `CreateVaultV2` vault with non-trivial TVL that is **empty/unseeded** *and* has `maxRate` raised (≥ the donation/price gap) — re-run the inflation test.
- Any adapter whose `realAssets()` is a spot/AMM price (not a vault `previewRedeem`/protocol NAV) and whose share of the vault exceeds ~5% — a downward manipulation could open liquidations; an upward one is still rate-capped.
- A MYT NAV drawdown >5.3% (strategy loss, oracle failure, Curve/Fluid/Tokemak incident) → keeper liquidations; monitor `getCDP` CR distribution.
- A `forceDeallocate` event >$500k on a 2%-penalty adapter → back-run/dilution monitor.
- Any change to `maxRate` (allocator), `forceDeallocatePenalty`, `adapterRegistry`, or a timelock increase/abdication.
- Alchemist proxy upgrade (`0xd5f26c90…` implementation) or `setMinimumCollateralization` / `setLiquidatorFee` changes.

---

## 9. Methodology, sources, caveats

- **Sources of truth:** verified Etherscan V2 sources for `VaultV2Factory` (incl. `VaultV2.sol`), `AlchemistV3` impl `0xd5f26c90…`, `Transmuter`, `AlchemistAllocator`, `AlchemistCurator`, `AlchemistTokenVault`, `AlchemistRouter`, `AlchemistV3Position`, and 17 adapter classes; Alchemix docs (`docs.alchemix.fi/dev/contracts/*`, `dev/myt/*`); DefiLlama protocol/yields APIs for the vault list and prices; Morpho VaultV2 audits (ChainSecurity, Cantina, 0xSimao, Kai) and the Alchemix Immunefi competition index for known/fixed findings.
- **Live reads:** JSON-RPC `eth_call` batches at the explicit blocks above (`analysis/*.json`); public RPCs for ETH/OP/Arb/Base; no keyed URLs are stored in this folder.
- **Fork PoC:** Foundry 1.8.5 on a public Ethereum fork at block 26,217,600; only local fork state was mutated; nothing was broadcast.
- **Caveats:** (i) The `forceDeallocate`/`maxRate` yield-dilution is real but is a *yield* transfer, not principal, and we did not find a live event large enough to be material; (ii) the Alchemist earmark/redemption system is complex and the Nov-2025 audit competition produced many findings that were fixed in this deployment — we verified the specific deployed code paths we rely on, not a full re-audit; (iii) OP/Arb position scans are point-in-time and the RPCs are rate-limited (files record any gaps); (iv) prices are 18-Oct-2026 DefiLlama snapshots and move.
- **Not tested:** a full economic simulation of the `_earmark`/`_survivalAccumulator` system under adversarial redemption timing; a malicious-adapter scenario (P-only); cross-chain bridge/xERC20 surface (out of scope of the MYT share-math lead).

---

## 10. Files

| File | Contents |
|---|---|
| `analysis/myt_vaults_all.json` | Live state of all 7 MYT vaults (block, assets, supply, roles, maxRate, adapters) |
| `analysis/myt_adapters_all.json` | Adapter addresses, owners, kill switches, realAssets |
| `analysis/vault_reconciliation.json` | `Σ realAssets + idle − totalAssets` per vault (all 0) |
| `analysis/alchemist_state_eth.json`, `alchemist_state_l2.json` | Alchemist parameters/totals for all 7 markets |
| `analysis/positions_eth.json`, `health_*.json` | Every position's `getCDP` and computed CR |
| `analysis/baddebt.json` | Transmuter `badDebtRatio` per market |
| `analysis/valuation.json` | USD valuation and prices |
| `analysis/src_*` | Verified sources used (VaultV2, AlchemistV3, Transmuter, allocator, curator, router, NFT, 17 adapters) |
| `poc/test/AlchemixV3ShareMath.t.sol` | 6 fork tests (all pass) |
| `ci-log.txt`, `ci-artifacts/` | CI run log/artifacts |
| `summary.json` | Machine-readable verdict |
