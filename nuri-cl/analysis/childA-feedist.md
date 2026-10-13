# childA — Nuri (Scroll) fee-distribution surface: extraction audit

**Date:** 2026-10-14 · **Chain:** Scroll mainnet · **Block:** 35364619 (ts 1791931666) · **Status:** READ-ONLY (no transactions signed/sent; all "sims" are `eth_call` with `--from`, zero state change).

Targets: Voter `0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869`, FeeDistributor impl `0x08D7616dfaC9fBBc3507701C9dC4c26cD92d0960` (verified source == local copy; beacon `0xAAA1c31Cc1d1C2da7e634130DeD0ea2043271744`, owner = Safe `0xC9d28676b7d470210a3C490B60729660eE5a7257`), FeeCollector `0xAAA2A49958a443Dc9d19FdDEe873B5D1d6e84A2f`, CommandCenter `0xAAA11500dDdB2B67a90d1a154dfB7eaBB518EAE6`.

## 1. Enumeration — all 62 gauges → 62 feeDistributors

`voter.gauges(pool)` matched the local `gauges.json` for **62/62**; `voter.feeDistributors(gauge)` returned 62 **distinct** FDs (one per gauge); 19 gauges `isAlive`. Every FD has `voter() == 0xAAAf3D9C…` (Voter proxy). 34 legacy gauges have per-pool `pairFees`; the 28 CL gauges share `pairFees = FeeCollector`. Full raw state: `childA-raw.json`, `childA-gauge-map.json`, `childA-tokenlists.json` (Scrollscan `/api/v2/addresses/<fd>/token-balances`).

Balances of the 62 FDs at block 35364619 (prices: DefiLlama 1791930180 / GeckoTerminal for NURI):

| Asset | Amount in 62 FDs | USD | Split |
|---|---|---|---|
| WETH | 0.71678556 | $1,798.01 | 31 FDs hold >0 |
| USDC | 1,370.371587 | $1,370.13 | |
| USDT | 114.897488 | $114.83 | |
| **Core WETH+USDC+USDT** | | **$3,282.96** | the task's "value pool" |
| SCR | 1,600.639831 | $38.42 | |
| wstETH+weETH+wrsETH+STONE+agETH+PufETH | 0.09558 ETH-equiv | $268.00 | |
| DAI / USDe / WBTC | 14.17 / 5.79 / 0.000584 | $68.67 | |
| NURI (9,744.36) + loreUSD (4.43) | | ~$13.2 | LORE 5,918 & ABCNURI 3,290: no DEX price |
| **TOTAL incl. everything priceable** | | **~$3,671** | |

**FeeCollector itself holds 0** of WETH/USDC/USDT/NURI; `treasuryFees = 10000` → CL protocol fees go 100 % to treasury (Safe), so no new value reaches CL FDs. FD logs in the last ~10 months are only zero-amount `NotifyReward` events emitted by `FeeCollector.collectProtocolFees` (confirmed by decoding topic `0x52977ea9…` with amount=0).

Top pots: `0x52239d60…` ($1,734: 0.3126 WETH + 950.26 USDC + 175.8 NURI + 1.21 SCR), `0xb56509dd…` ($325: 0.1236 WETH + 604.5 SCR), `0x09646c9c…` ($213), `0x5d8e5ba4…` ($171: 113.29 USDC + 0.021 WETH + 6,201.8 NURI), `0x9923fbae…` ($17: 716.9 SCR).

Dead end (checked, no value): `FeeDistributorFactory.createFeeDistributor(pairFees)` is permissionless and lets anyone deploy an FD proxy whose `voter` is an attacker-chosen contract — but the proxy is empty and unregistered in the Voter, so it can never receive fees; `initialize` also reverts for an EOA "voter" (empty `_ve()` return).

## 2. FeeDistributor.sol — every external path and its live guard

Guard mapping (source-deployed verified; exact call traces in §5):

| Function | Guard | Can value go to `msg.sender` (non-owner)? |
|---|---|---|
| `getReward(tokenId, tokens)` | `ve.isApprovedOrOwner(msg.sender, tokenId)`; `lock` | No — pays `msg.sender` only because `msg.sender` must already be the veNFT owner/approved. Attacker sim → **revert** |
| `getPeriodReward(period, tokenId, token)` | same + `require(period <= getPeriod(), "!FP")` | No — sim → revert |
| `getRewardForOwner(tokenId, tokens)` | `require(msg.sender == voter)`; pays `ve.ownerOf(tokenId)` | No — sim → revert; Voter-mediated callers pay the veNFT owner |
| `notifyRewardAmount(token, amount)` | `require(msg.sender == pairFees, "!FEES")` | No |
| `incentivize(token, amount)` | **none** — pulls tokens FROM caller | No — pure donation credited to next-period voters; sim from attacker with 0 succeeds, no credit to caller |
| `_deposit` / `_withdraw` | `require(msg.sender == voter)` | No |
| `earned/getPeriod/getRewardTokens` | views | n/a |

**Claim-accounting checks (live state):**
- `userClaimed[period][tokenId][token]` is incremented *before* the transfer and the payout is recomputed each time (`reward = supply*userVotes/votes - userClaimed`), so re-entering `getReward` + `getPeriodReward` in any order yields 0 the second time. No double-claim, no rounding in the claimant's favour (`votes[P]` is frozen once period P starts; `_deposit/_withdraw` only touch `getPeriod()+WEEK`).
- **No checkpoint/period bug matching the Oct-2024 Ramses "$90K" exploit**: that exploited variant contains `veWithdrawnTokenAmountByPeriod` and unvalidated retro periods; the deployed Nuri impl has no such variable, has `require(period <= getPeriod())`, and per-(period,tokenId,token) claim tracking. Scrollscan-verified impl source re-checked against the local file.
- **No privileged exit**: the impl has no owner, no sweep, no emergencyWithdraw — tokens can only leave via the claim functions above. (Governance can swap the beacon impl via the factory owner = Safe, but that is category P, not an unprivileged path.)
- Historical flow proves the claim path works as designed: FD `0x52239d60` took in **85.58 WETH / 251,420 USDC / 359,687 NURI / 2,000 SCR** over 61 funded buckets and retains only 0.31 WETH / 950 USDC / 175.8 NURI / 1.21 SCR — i.e. >99 % was claimed by the recorded voters. Last `ClaimRewards` event ≈ block 25.4–26.4M (≈9 months ago); no `Deposit`/`ClaimRewards` since.
- **Stranded (bricked) part (S):** `notifyRewardAmount` bumps fees to P+1 only when `votes[P]==0`, and `incentivize` never checks votes; buckets with `votes==0` can never be claimed (`_getReward` skips them). Live examples: FD `0x5d8e5ba4` 536.30 NURI ($0.43) + 0.00002 WETH stranded; FD `0x09646c9c` 17.81 USDC + 47.08 SCR stranded (~$19).
- **Burned veNFTs (S):** `VotingEscrow.withdraw()` burns the NFT; `getReward` then reverts (`ownerOf==0`). Any unclaimed reward of a withdrawn NFT is unrecoverable forever. Cannot be quantified without enumerating tokenIds (limitation).

## 3. Voter.sol — permissionless functions, guards, value destination

| Function | Guard | Value to attacker? |
|---|---|---|
| `claimIncentives` / `claimFees` | `ve.isApprovedOrOwner(msg.sender, tokenId)` | No — FD call pays the veNFT owner (= caller). Attacker sim → revert |
| `claimClGaugeRewards` | NFP owner/approved per position id; target's `getRewardForOwner` re-checks `voter`/`nfpManager` | No — GaugeV2 pays `nfpManager.ownerOf(id)`. Attacker sim with real NFP 59841 (owner `0x6dA392…`) → revert |
| `claimRewards` | none; calls caller-chosen gauge's `getReward(msg.sender, tokens)` | No — gauge pays the account's own stake |
| `distribute`, `distribute*Unchecked`, `updateFor`, `updateForRange`, `updateAll`, `updateGauge` | none (keeper) | No — moves NURI emissions into gauges. Sim → success, 0 to caller |
| `notifyRewardAmount(amount)` / `notifyRewardForGauge(s)` | none; whitelisted reward token | No — pulls base from caller (donation/emissions) |
| `poke(tokenId)` | **NONE — any tokenId** | No — re-syncs recorded votes to current `balanceOfNFT`; only shifts which period gets the weight (frozen buckets untouched). Sim → success |
| `createGauge(pool)` | real `IPairFactory.isPair`, both tokens whitelisted & not forbidden; governor bypass | No — creates gauge for a real pair; gauge owner is Voter |
| `createCLGauge(tA,tB,fee)` | pool exists + initialized, tokens whitelisted, gauge not exists; governor bypass; also calls `pool.setFeeProtocol()` (protocol config) | No |
| `recoverFees` | `msg.sender == governor` | No (→governor) |
| `stuckEmissionsRecovery` / `clawBackUnusedEmissions` | `whitelistOperator || governor` | No (→governor) |
| `whitelist/forbid/kill/revive/setXRatio/…` | operator-gated | No |

Note: `claimIncentives/claimFees` let a veNFT owner make the Voter call `getRewardForOwner(uint256,address[])` on **any** caller-supplied address with `msg.sender==Voter`. The two candidate targets (FeeDistributor, GaugeV2) both re-check `msg.sender==voter` and pay `ownerOf(tokenId)`/`nfpManager.ownerOf(id)` — no escalation, no self-payment (checked). Minor griefing only: anyone can register a reverting ERC-20 into an FD's `rewards[]` via `incentivize`, breaking naive "claim-all-rewards" UIs; per-token claims still work. No value loss.

## 4. CommandCenter — roles

External functions are **all** `onlyRole(OPERATOR_ROLE | FEE_SETTER_ROLE | DEFAULT_ADMIN_ROLE)` (fees, gauge kill/revive, whitelist, `rebase`, `multisigWithdraw`, emissions clawback). Live role holders (block 35364619): DEFAULT_ADMIN=3 (Safe `0xC9d286…` [proxy, code 171 B] + 2 EOAs), OPERATOR=2 (Safe + contract `0x8d46c6da…`, 1,260 B), FEE_SETTER=7 (4 contracts incl. `0x5a6d35e6…`/`0x6d11b9b1…`/`0x8f7248fa…`, 2 EOAs, Safe). Attacker sims: `setFeeCL` → `AccessControl: missing role 0xe6ad9a47…`; `multisigWithdraw` → missing `OPERATOR_ROLE 0x97667070…`. **No unprivileged caller can change fees or move funds.**

## 5. Exact simulations (all `eth_call`, attacker `0x…0bAd`, block 35364619)

| # | Call | Result |
|---|---|---|
| 1 | FD `0xb56509dd`.getReward(1,[WETH]) | revert (not owner/approved of veNFT 1) |
| 2 | FD.getRewardForOwner(1,[WETH]) | revert (`msg.sender != voter`) |
| 3 | FD.getPeriodReward(1753315200,1,WETH) | revert (auth) |
| 4 | Voter.claimIncentives([FD],[[WETH]],1) | revert (`!approved`) |
| 5 | Voter.claimFees([FD],[[WETH]],1) | revert |
| 6 | Voter.claimClGaugeRewards([gauge],[tokens],[[59841]]) | revert (not NFP owner) |
| 7 | FD.getReward(1,[WETH,SCR,NURI]) **from owner Safe** | success (`0x`) — rightful path open |
| 8 | Voter.poke(1) from attacker | success — no value |
| 9 | Voter.distribute(gauge) from attacker | success — no value |
| 10 | CommandCenter.setFeeCL / multisigWithdraw | AccessControl revert |
| 11 | FeeCollector.collectProtocolFees(pool `0x76c662…`) from attacker | success (`0x`) — permissionless by design; 100 % → Safe; FD credited 0; caller gets nothing |

## 6. Bottom line

- **E-U (external unprivileged attacker): $0.00 — confidence HIGH.** No function in FeeDistributor / Voter / CommandCenter sends FD value to a caller who is not the recorded veNFT owner; every claim entry point reverts for an attacker (sims 1–6); no fee/role/parameter is attacker-settable.
- **H-O (holder recoverable): ~$3,671** sits in 62 FDs as unclaimed voter rewards (core WETH/USDC/USDT = $3,282.96). Recovery is by the veNFT owners whose tokenIds were recorded in the funded buckets (`getReward`/`claimFees`); claims have been dormant ~9 months but remain open indefinitely.
- **S (bricked): first-order small but non-zero** — no-vote buckets (live samples: 536 NURI + 17.8 USDC + 47 SCR) and any rewards of burned veNFTs are permanently unrecoverable (FD has no sweep; `ownerOf==0` blocks claims).
- **P:** the FD factory beacon implementation is changeable by the Safe only — governance could add a sweep, but that is privileged.

**Blockers/caveats:** token-ID-level attribution of the unclaimed residue would need historical `Deposit` log enumeration (out of timebox); LORE/ABCNURI unpriced (no DEX feed); `earned` was verified 0 for the only tokenId we could anchor live (Safe-owned #1), so the exact per-tokenId live claimable remainder is not asserted. Files: `childA-raw.json`, `childA-gauge-map.json`, `childA-tokenlists.json`, `childA-periods.json`, `childA-history.json`, scripts `childA-*.py`.
