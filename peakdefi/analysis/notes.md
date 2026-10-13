# PEAKDEFI L2 Phase-2 — evidence log

All reads on public RPCs (`ethereum-rpc.publicnode.com`, `eth.drpc.org`, `bsc-rpc.publicnode.com`),
Etherscan V2, GoldRush; state-mutating simulations on a **local anvil fork only**. No mainnet txs.

## 1. Targets & roles

| Contract | Role | Chain | Code |
|---|---|---|---|
| 0x07cDB44fA1E7eCEb638c12A3451A3Dc9CE1400e4 | Global Fund (EIP-1167 proxy) | ETH | 46 bytes → 0xa1dFf47E… |
| 0xC120C7dB0804ae3AbEB1d5f9c9C70402347B4685 | NFT Fund (EIP-1167 proxy) | ETH | 46 bytes → 0x3463C657… |
| 0xa1dFf47E3e9C4a18D341e386c6707A18686FB834 | Fund facade/impl (unverified, 10,503 B) | ETH | dispatcher + version fallback |
| 0x7CE70A3a0496575887B3732ce46Aa5b68B2c0Df7 | stored `proxyImplementation` (EIP-1167 → 0xef4eF84d…) | ETH | 46 bytes |
| 0xef4eF84dF8EFE977a8ae07293553ADb4Ff3bAc90 | module router | ETH | delegates to modules |
| 0x80bBA403EdA6Fa1D3870d0c8D9F629C1c22DA07B | deposit/withdraw module | ETH | calls USDC |
| 0x2FC2528861… | nextPhase/referral module | ETH | (revert origin for phase/referral gates) |
| 0x4D1f4532fe81d0B28dF0Fe9ef14093F37EEcc339 | "PEAKDEFI Fund Shares" (SHARE, 18 dp) | ETH | supply 84,191.674639 |
| 0x506ed0B68f8750cc07daf51F114Bb7c83A541B3f | "NFT Share" (18 dp) | ETH | supply 125,697.286174 |
| 0x4519CAb52437330802f0E56232909f954728b628 | "Reputation Token" (REP, 18 dp) | ETH | supply 377.844827; 3 holders |
| 0xd6e1b0E39D1428c9106bC348c3608ddD2F00253C | NFT REP | ETH | supply 0 |
| 0xe9428B8acaA6b9d7C3314D093975c291Ec59A009 | PeakStaking (v0.5.17, verified) | BSC | 5,925 B |
| 0x9733f49D577dA2b6705cA173382C0e3CdFff2A48 | PeakStaking | ETH | 0 PEAK, mint cap 99.999998 % used |
| 0xb5933F1A3A72Fa3a7d79d2eF04abD876e9BA0C81 | PeakReward | BSC | mint cap 99.41 % used |
| 0xF8bc0856472486C20DCeEAb81d5e5980d9Fc302e | PeakReward | ETH | mint cap 99.85 % used |
| 0x630d98424eFe0Ea27fB1b3Ab7741907DFFEaAd78 | PEAK token (TokenProxy) | ETH+BSC | 8 dp; `mint` = MINTER_ROLE |

Unverified: fund facade/impl chain, factory 0xF8d8385b…, proxy 0x9424b287…, share/control tokens.
Sources obtained for: PeakStaking/PeakReward (Etherscan), PEAK impls PEAKDEFI_V1/V2, UniswapOracle,
`IPeakDeFiFund` interface (from public `ProtectionStaking` sources at 0xead98f44 / 0xfbb07295).

## 2. Live state (ETH block 26,186,172; BSC block 127,472,371; 2026-10-13)

Global Fund: USDC 51,248.642016; totalFundsInUSDC 35,298.925965; totalCommissionLeft 13,546.478915;
peakReferralTotalCommissionLeft 2,403.237136; cycle 18, cyclePhase=true (manage, start 2026-10-08
12:35:35 UTC), phase lengths [3 d, 27 d]; owner 0xEff81b47…; proxyAdmin 0x5D386539…; nextVersion 0;
previousVersion 0xaf5A490C…; devFundingAccount 0xb9028915…; devFundingRate 1e15 (0.1 %);
isPermissioned=false; NEXT_PHASE_REWARD 1e18.

NFT Fund: USDC 58,985.681365; totalFundsInUSDC 27,705.453559; totalCommissionLeft 0;
peakReferralTotalCommissionLeft 31,280.227706; cycle 5 (manage, start 2026-10-01), lengths [5 d, 85 d];
owner 0xbC8bDC1c…; isPermissioned=true.

BSC staking: PEAK 156,799,455.22979847; USDT 1.697754505789882515; initialized=true;
mintedPeakTokens 27,499,999,999,919,103 / cap 27,500,000,000,000,000 (headroom 80,897 units =
0.000809 PEAK); peakReward 0xb5933F1A….

REP holders (all 3 managers): 0x26D57f31… 134.33 REP, 0x52524a45… 133.41 REP, 0x176c344a… 110.10 REP.

## 3. Fork experiments (anvil, fork of ETH mainnet; then Foundry CI)

### 3.1 Admin surface (eth_call from 0x1111…, then state-checked on anvil)
| call | result | state after |
|---|---|---|
| changeProxyAdmin(att) | success, empty return | proxyAdmin unchanged (0x5D386539…) |
| developerInitiateUpgrade(att) | success | nextVersion unchanged (0) |
| migrateOwnedContractsToNextVersion() | success | owner unchanged |
| transferAssetToNextVersion(USDC) | success | fund USDC unchanged |
| changeDeveloperFeeAccount(att) / Rate(123) | success | unchanged |
| listKyberToken/listCompoundToken(att) | success | isKyber/isCompound(att) = false |
| initOwner(), transferOwnership, renounceOwnership, init() | revert | — |
| nextPhase() while phase running | revert | — |
| withdrawUSDC during manage phase | revert | — |

debug_traceCall showed the chain fund → 0xa1dFf47E → 0x7CE70A3a → 0xef4eF84d for these selectors,
ending in an empty fallback (no state write).

### 3.2 Deposit / withdraw economics
* depositUSDC(1,000e6) in manage phase → 2,385.105845 shares (NAV 0.419269) — no fee.
* withdrawUSDC reverts in manage phase; after `nextPhase()` (sell phase) withdrawUSDC(100e6) burned
  243.829602 shares → NAV 0.410123 (post-transition NAV after dev-fee share mint + commission settlement).
* Round trip: 1,000 in → 900 withdrawn + 78.19 remaining NAV = 978.19 (loss ~2.2 %).
* NFT fund: fresh address deposit 1,000 USDC → 4,536.9149 NFT shares (isPermissioned=true does not block).

### 3.3 nextPhase / phase transition
* nextPhase() by unprivileged address: gas ~394 k; flips manage→sell, cycle 18→19; **caller receives no
  USDC/shares** (balance delta 0). Same for the sell→manage transition (gas ~118 k).
* Transition settlement (fork): investor funds −756.34; manager pool +396.78; referral pool +359.55.

### 3.4 Referral system
* A fresh address: `peakReferralCommissionBalanceOf` = 0, redeem reverts.
* Entitled referrers (sell phase): 0xB4238F7C… raw 449.90 → received 226.55; 0xB37AECD8… raw 499.42 →
  267.55; 0x8FE0D837… raw 98.18 → 51.35; pool debited ~2× the redeemer payout (cascade to upline).
  0xafb12c7c… redeemed cycles 3/8/10/12 → 353.06 USDC.
* NFT fund: 0xafb12c7c… raw 26,193.51 (cycle 1: 21,381.19; cycle 4: 4,812.32); redeeming cycle 1 in the
  sell phase paid **10,690.59 USDC** and debited the pool by 15,391.42.
* Sybil farm (A refers B): B deposits 2,000 and holds through one manage phase; A accrues raw 14.76,
  redeems 7.38 cash; B's NAV dilution ≈ 27.35 → pair net ≈ −20 USDC. Not profitable.

### 3.5 Manager side
* `commissionBalanceOf(m)` = (0, penalty) for all 3 managers on mainnet; `commissionOfAt(m, c)` =
  (0, penalty) for c = 1…18. `redeemCommission(false/true)` pays 0; `redeemCommissionForCycle` reverts or
  pays 0; `totalCommissionLeft` unchanged. `registerWithUSDC()` reverts (registration closed).
* Conclusion: the 13,546 USDC manager pool has no claim path (S).

### 3.6 Other
* `sellLeftoverToken(USDC, transfer-calldata)`, `withdrawTokenAdvanced(USDC, 100e6, true, calldata)`,
  `depositTokenAdvanced(...)` → all revert. No arbitrary-call escape.
* `burnDeadman(0x2dda3e98…)` → REP burned to 0x0, no payout to caller.
* BSC `stake(1 PEAK, 10 d, 0)` from a fresh address (dealt 1 PEAK) → reverts ("PeakStaking: reached cap");
  `getInterestAmount(1 PEAK, 10 d)` = 1,422,697 units >> headroom 80,897.
* PEAK token: `mint` gated by MINTER_ROLE; `burnFrom` gated; public `burn` only self-burn.

## 4. Negative results / do-not-re-investigate

* No re-init / proxy takeover: admin selectors are no-ops (verified by state diff, not just call success).
* No NAV arbitrage: deposits and withdrawals use the same NAV; transitions only subtract fees.
* No referral farming profit; no permissionless payout function (`nextPhase`, `burnDeadman`, `rankUp`
  pay the caller nothing).
* No mint farming: all four PEAK mint caps ≥99.4 % consumed (BSC staking headroom 0.000809 PEAK).
* No arbitrary calldata escape via `*Advanced` / `sellLeftover*`.
* Triage's CI probe under-reported the funds as ~$0 (it priced USDC with 18 decimals); the GoldRush
  triage figures ($51,123 / $58,842 / $9,808) are correct.

## 5. Key addresses seen in referral history (entitled parties, H-O)

Global: 0xB4238F7C5B5E117CaB8a2AF7e414c8882316D37A (raw 453.2M units), 0xafb12c7c… (14.4e9),
0xB37AECD82e5db0C215ef0F15f2524503B6e76ce8, 0x8FE0D837b94BD930D7cB49Cb8aB1f578CFf3bD1C,
0x3c35dc2d…, 0x4fc82e76…, 0x53d6592c…, 0xcbe4a3ce…, 0xee4684a2…, 0x5fe198b6…, 0x7f35ac37…
NFT: 0xafb12c7c… (raw 26.19e9), 0xf61608d1…, 0x3208ba32…, 0xb043c1a9…
