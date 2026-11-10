# Every path to external unprivileged profit — enumerated

Legend: **E-U** external unprivileged, **H-O** holder-only/self-service, **P** privileged,
**S** stuck. "Live" = Scroll block 35,666,678 / Ethereum block 26,380,929.

## Target 1 — USX.Capital (Scroll)

| # | Path | Gate / live value | Capital / cost | Verdict |
|---:|---|---|---|---|
| 1 | `TreasuryDiamond.setAdmin` / `setGovernance` | `onlyAdmin` / `onlyGovernance` = 3-of-4 Safe `0xE0B4…`; attacker reverts `NotAdmin`/`NotGovernance` | none | **P** |
| 2 | `TreasuryDiamond.addFacet` / `removeFacet` / `replaceFacet` | `onlyGovernance` 3-of-4 Safe | none | **P** |
| 3 | `TreasuryDiamond.transferUSDCtoAssetManager` / `transferUSDCFromAssetManager` / `transferUSDCForWithdrawal` | `onlyAllocator` = 2-of-3 Safe `0xFF8c…`; attacker reverts `NotAllocator` | none | **P** |
| 4 | `AssetManager.withdraw` / `deposit` | `onlyTreasury` (the treasury proxy); attacker reverts `NotTreasury` | none | **P** |
| 5 | `AssetManager.updateWeight` / `grantRole` | `DEFAULT_ADMIN_ROLE` / `GOVERNANCE_ROLE` on the AM; held by the treasury/Safes | none | **P** |
| 6 | Strategy Safe `0x340F…` (holds 383,892.26 USDC) | Gnosis Safe **3-of-4**; no on-chain unprivileged spend | none | **P** |
| 7 | `USX.deposit` (mint 1:1) | `onlyWhitelisted`; `whitelistedUsers(attacker)=false`; `whitelistUser` `onlyAdmin` 3-of-4 Safe | none | **H-O / P** |
| 8 | `USX.requestUSDC` (burn → USDC queue) | `onlyWhitelisted`; same gate | none | **H-O** |
| 9 | `USX.claimUSDC` | public but pays only `outstandingWithdrawalRequests[msg.sender]`; fresh EOA = 0. The 300k USDC escrow is a liability to whitelisted redeemers | none | **H-O** |
| 10 | `USX.mintUSX` / `burnUSX` | `onlyTreasury`; callers are the reporter/allocator Safes | none | **P** |
| 11 | `PrivateGatewayScroll.transferUSDC` | Public. Pulls the caller's USDC, requires `usdcReceiver == expectedUSDCReceiver` (117-byte admin value), deposits to the L1 gateway and messages the Cloak gateway. No branch returns USDC/USX to the caller. Gateway balance 0 | caller's own USDC; gas | **no profit** (one-way deposit) |
| 12 | `PrivateGatewayScroll.transferToken` | Public. Allowlisted router only (`0x1231…` LI.FI), approval limited to `swapAmount` and zeroed; USDC delta is fully deposited. No skim; gateway 0 | caller's token/ETH; gas + DEX slippage | **no profit** |
| 13 | `PrivateGatewayScroll.withdrawTokens` | `DEFAULT_ADMIN_ROLE` — **0 members**; even the admin cannot call it | none | **S** (no admin) |
| 14 | Zellic 3.1 dual-receiver (old gateway `0x54A5…`, impl `0x902D…`) | Pre-fix code has no `expectedUSDCReceiver`; live USDC balance = **0**, nonce 30; no fuel | none | **no fuel** |
| 15 | Zellic 3.5 `withdrawUSX(actualReceiver)` on Cloak | `onlyRole(WITHDRAW_USX_ROLE)` + `nonReentrant`; `confirmDeposit` only messenger/counterpart; no user function supplies `actualReceiver`. Cloak RPC token-gated (not public) | requires the WITHDRAW_USX_ROLE multisig / backend compromise | **P / trust** |
| 16 | `PrivateGatewayCloak.rebalance` | `onlyRole(REBALANCE_ROLE)` | none | **P** |
| 17 | `PrivateGatewayCloak.withdrawTokens` | `DEFAULT_ADMIN_ROLE` | none | **P** |
| 18 | `USXRebalancer.rebalanceBySwapping` (Zellic 3.2) | No live rebalancer found in the 95 deployer creations; source has router allowlist + `usxAmount >= amountUSDC*1e12` + `expectedUSXReceiver` binding. Even unpermissioned, the output cannot be sent to an attacker-chosen receiver | none | **not deployed / fixed** |
| 19 | sUSX `deposit`/`withdraw` | ERC-4626; 15-day withdrawal period, 0.05% fee; `notifyRewards` onlyTreasury; `totalAssets` subtracts undistributed rewards and pending withdrawals. Round trip ≤ deposit | 15-day lockup + fee | **H-O** |
| 20 | USX/sUSX donation | A direct token donation raises the share price for all holders; the donor loses the donated value. No positive E-U | donation | **no profit** |
| 21 | Flash loan | No live contract holds unprivileged USDC inventory: gateway 0, treasury/AM/strategy behind `onlyAllocator`/`onlyTreasury`/Safes, USX escrow self-scoped. A flash loan cannot change `msg.sender` or Safe thresholds | n/a | **no path** |

**USX.Capital E-U: $0.00.** The only live value is P-class (Safes) or H-O (whitelisted USX
redeemers). The 29,246.34 USDC accounting gap reduces backing; it is not extractable.

## Target 2 — Mezzanine (Ethereum)

| # | Path | Gate / live value | Capital / cost | Verdict |
|---:|---|---|---|---|
| 1 | `NavOracleAutomation.submitNav` | `restricted` role 6 = EOA `0x816d…`; attacker reverts `AccessManagedUnauthorized`; `_readFreshAnswer` now reverts `OraclesNotInSync` if the two feed timestamps differ | none | **P** |
| 2 | `NavOracleAutomation.rejectPendingNav` | role 0 admin Safe `0x0b61…` | none | **P** |
| 3 | `NavOracleAutomation.performUpkeep` | role 10 (`0xFAf5…`, `0x011b…` automation contracts) | none | **P** |
| 4 | `NavOracleAutomation.setOracles` / `setVetoPeriod` / `setMaxAnswerStaleness` | role 0 admin Safe | none | **P** |
| 5 | `LossManager.applyLoss` | `onlyNavOracle`; `maxLossPerTxUSDC=1e12`; attacker reverts `NotNavOracle` | none | **P** |
| 6 | `IssuanceVault.distributeYield` | `onlyNavOracle` | none | **P** |
| 7 | `IssuanceVault.rebalance` | `restricted` role 7 | none | **P** |
| 8 | `IssuanceVault.setTrancheConfig` / `setFeeRates` / `setBuffer` / `setEpochConfig` / `registerTranche` / `setLossManager` / `setNavOracle` | role 0 admin Safe | none | **P** |
| 9 | `IssuanceVault.advanceEpoch` | `onlyLossManager` | none | **P** |
| 10 | `IssuanceVault.withdraw` | `onlyMZUSD`; called by MZUSD redemption | none | **P / H-O** |
| 11 | `Tranche.deposit` / `mint` | Public ERC-4626 over MZUSD; deposit limits disabled; `_decimalsOffset=3` and 1,000 dead shares harden the first-depositor attack | MZUSD capital | **entry, no profit** |
| 12 | `Tranche.requestWithdrawal` | Public; direct mode disabled → umbrella shares are held 1–2 epochs; `unstakeYieldReductionBps=5000` on positive yield after the snapshot | MZUSD, 1–2 epoch lockup | **no free profit** |
| 13 | `Tranche.finalizeEpoch` | `restricted` role 9 (`0x0630…`, `0x8e07…`) | none | **P** |
| 14 | `Tranche.claim` | Public but self-scoped: pays only `userSharesByEpoch[user][epoch]`; anyone can call for `user`, funds always go to `user` | none | **H-O** |
| 15 | `Tranche.notifyYield` / `burnMZUSD` | `onlyVault` / `onlyLossManager` | none | **P** |
| 16 | MZUSD `deposit` / `requestWithdrawal` | `AllowlistStub` returns `true` for everyone, so effectively open; deposit 1:1, withdrawal 1 bp fee + global cap 1e12 (no cap in practice), vault liquidity 307,999 wYLDS | 1 bp + gas | **no profit** (1:1) |
| 17 | MZUSD `mint` | `onlyVault` (`IssuanceVault`) | none | **P** |
| 18 | MZUSD `burn` | `restricted`; granted to tranches | none | **P** |
| 19 | **H-1 desync exploit** | **Fixed live**: `OraclesNotInSync` check + role-6-only `submitNav`. Fork proof: a 1-second timestamp mismatch reverts. Counterfactually, a desynced report would let a depositor between feed updates mint unbacked yield ≈ their deposit; the live check blocks it | n/a | **CLOSED** |
| 20 | **M-1 disabled-tranche loss** | Live both tranches enabled → inactive. Fork proof: disabling the Junior makes it burn 100,000 MZUSD on a 100,000 USDC loss. A fresh depositor in the enabled tranche can avoid a loss (wealth transfer from the disabled tranche's holders) but cannot withdraw more than deposited | none beyond capital | **not E-U profit** |
| 21 | **Yield sniping** | A depositor who enters after a NAV report is pending and before the 24h veto shares in the *already backed* yield. Live pending delta 562.34 USDC; capture bounded by that delta, not by capital. $1M deployed captures ~$120/report (~$6.2k/yr, <0.7%/yr) | MZUSD capital locked 1–2 epochs; gas | **sub-$10k, capital-heavy** |
| 22 | First-depositor / donation attack | `_decimalsOffset=3`, 1,000 dead shares; the `Tranche.totalAssets()` is balance-based, so a donation raises the share price for all holders; the donor loses the donation. No positive E-U | donation | **no profit** |
| 23 | Flash loan | H-1 would require a deposit between two feed updates and holding through the 24h veto + epoch; the tranche withdrawal is 1–2 epochs (6.95 days each) and MZUSD redemption is 1:1. No atomic/flash path | n/a | **no path** |
| 24 | MZUSD/wYLDS bank-run | MZUSD supply 5.485M vs identifiable wYLDS backing 307,999.88 + Reservoir 0.966 — but the protocol TVL ($5.18M) sits in strategy custody. A bank run is an H-O solvency risk, not an attacker profit; redeemers get 1:1 until liquidity runs out | n/a | **H-O / S** |

**Mezzanine E-U: $0.00.** H-1 is fixed live; M-1 is a latent fairness bug with no positive
extraction; the only residual is a bounded yield-sniping stream far below $10k.

## Cross-target economics

- **No DEX/CEX acquisition is required for either target**: there is no live unprivileged path to
  acquire a claim at a discount and redeem at par. USX mint/redeem is whitelisted and 1:1; MZUSD
  mint/redeem is 1:1 with a 1 bp fee.
- **No flash-loan path**: both targets' value is behind `msg.sender` role checks (Safe-controlled)
  or time-locked tranche withdrawals; a flash loan cannot satisfy either.
- **Net after costs**: for every candidate, the net is ≤ $0 after gas; the only positive residual
  (Mezzanine yield sniping) is ~$120/report at $1M capital, below the $10k bar.
