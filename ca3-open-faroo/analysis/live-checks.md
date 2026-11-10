# Faroo stPROS — live-state evidence

Read-only `eth_call` / `eth_getCode` / `eth_getStorageAt` on Pharos (chain id 1672).
No transaction was signed or broadcast. No keys used.

## Block anchors

| Read | Block |
|---|---:|
| Initial topology / balances | 22,610,812 |
| Final probe suite (`ci/run.sh`) | 22,613,377 |

## Proxies and implementations (EIP-1967 slot `0x3608…2bbc`)

| Contract | Proxy | Runtime | Impl | Impl size | Runtime keccak | Repo record |
|---|---|---:|---|---:|---|---|
| stPROS | `0x6b0A44c64190279f7034b77c13a566E914FE5Ec4` | 2,739 B | `0xfD59860894E01773e9780B0d1DFAE4cA2B56708D` | 16,445 B | `0xca97539e…47e218` | **match** |
| BridgeVault | `0xF1dF1CB080256f48e8702c24149136E4A6dec25E` | 2,739 B | `0xa7d36cB9dA47bA5123F9070FbA4bb5239C58387e` | 7,169 B | `0x1d9038d2…c5a043` | **match** |
| SlpDistributor | `0xf772B375f93650F798Bf724cE7A9a45c9e7a579F` | 2,739 B | `0x05A224A9cdD84CfCa21866aE50Fa0cD663e3752f` | 5,772 B | `0xfa824dff…cf577a` | **match** |
| RewardsVault | `0xd0C44d3079e97fF285dd7A3e4E0246320a9487e5` | 2,739 B | `0xe6985303e0c917bda24c4566bb2f9af99916c531` | 4,882 B | `0x08c89ff6…8c50eb` | source in repo, bytecode not recorded |
| SLP #1 | `0xEC1d6163e05B3F5D0FB8F354881F6c8B793ad612` | 2,739 B | `0xc3d088842dcf02c13699f936bb83dfbbc6f721ab` | 10,022 B | `0x48686658…fc0aa3` | source in repo, bytecode not recorded |
| SLP #2 | `0xc53D2c9DD1e488E23Ff77E219Ca68d8138F90C2C` | 2,739 B | `0xd15e3eb96409ff2c5be569d132a4520e324a1124` | 10,022 B | `0x48686658…fc0aa3` | byte-identical to SLP #1 |

Proxy admin for stPROS / Oracle / BridgeVault / SlpDistributor: `0x4238ea4adfa2bd6a5fc9b5e245dc1900cf0258aa`
(2,632 B; `owner()` = `0xC30dB0543412c6881A543390d2c21FbBFf42805b`).
Admin for RewardsVault / SLP #1 / SLP #2: `0x480eb384681777bf21e72b8c8538987c2801b4b7`.

`0xC30dB0543412c6881A543390d2c21FbBFf42805b` is a contract (6,550 B) exposing
`getMinDelay() = 86400` and TimelockController role selectors → **24-hour OZ TimelockController**.
Guardian (pause-only): `0xa046988889871c6c7aBc69e63ccCf9AdB3E57ef5`.

The staking precompile `0x4100000000000000000000000000000000000000` is a 268-B
delegating stub; its EIP-1967 slot points at `0x9c6791f6dc5ba11a3919d72b496ed059e4f81cf4`
(49,816 B), the Pharos staking implementation.

## Live accounting (block 22,613,377)

| Quantity | Value |
|---|---:|
| `stPROS.totalAssets()` / Oracle `poolInfo(WPROS).tokenAmount` | **5,119,038.227419285 PROS** |
| `stPROS.totalSupply()` / Oracle `poolInfo(WPROS).vTokenAmount` | **5,077,168.065214 stPROS** |
| `convertToAssets(1e18)` | **1.008246755212287229** |
| staked principal (sum of `getDelegator` over 25 registered pools, 20 non-zero) | 5,062,185.797111863 PROS |
| SLP #1 `totalUnbonded()` (pending undelegation) | 56,632.43030741786 PROS |
| SlpDistributor native float | 220.000000 PROS |
| **principal + unbonding + float** | **5,119,038.227419281 PROS** (reconciles to T within 4e-9) |
| BridgeVault native / `getBalance(WPROS)` | 1,153.829143869170837546 PROS |
| BridgeVault WPROS ERC-20 balance | 0 |
| `stPROS.queuedWithdrawal()` | 1,247,604.019831042693382433 PROS |
| `stPROS.completedWithdrawal()` | 1,246,450.190687173522544887 PROS |
| `stPROS.getTotalBalance()` | 1,247,604.019831042693382433 PROS |
| queue surplus (`getTotalBalance - queuedWithdrawal`) | **0 wei** |

So the oracle NAV is fully backed: current stake + pending unbonding + distributor float
equals T exactly. The redemption reserve equals the outstanding queue exactly; there is no
unprivileged surplus to claim.

## Roles / gates

| Contract | Gate | Live value |
|---|---|---|
| stPROS | `owner()` | Timelock `0xC30d…` |
| stPROS | `paused()` | false |
| Oracle | `owner()` / `slp()` (reporter) | Timelock / RewardsVault `0xd0C4…` |
| Oracle | `maxAprPpm` / `maxUpdateAmount` / `updateInterval` / `commissionRatePpm` | 500,000 (50%) / 80,000 PROS / 12,600 s / 100,000 (10%) |
| Oracle | `vTokenAddresses(stPROS)` / `tokenToVToken(WPROS)` | true / stPROS |
| BridgeVault | `vTokenAddressCount` / `vTokenByAsset(WPROS)` | 1 / stPROS |
| BridgeVault | `paused()` | false |
| SlpDistributor | `keeper()` | `0x8736e68f37C1156e09445ac2D395A139e58fCAb4` |
| SlpDistributor | `getSlps()` | SLP #1, SLP #2, BridgeVault |
| RewardsVault | `notifyOracle()` | `WHITELIST_ROLE` only |
| SLP #1/#2 | bond / unbond / claim / claimReward / transferBack | `WHITELIST_ROLE` only |
| Staking `0x4100…` | `claimReward(poolId)` / `claimStake(poolId)` | keyed by `msg.sender`; fresh EOA → "No rewards to claim" / "No withdrawable stake" |
| Staking `0x4100…` | `withdrawStake(poolId,amount)` | "Caller is not the validator owner" |

## Fresh-EOA probes (25/25 PASS, see `ci-out/faroo-probes.txt`)

| Probe | Result |
|---|---|
| `BridgeVault.withdrawToken` / `withdrawTokenWrapped` | revert `NotVTokenContract(0x1111…)` |
| `BridgeVault.emergencyWithdraw` | revert `OwnableUnauthorizedAccount` |
| `Oracle.update` | revert selector `0xf5631094` (`NotSlp`) |
| `Oracle.onMint` | revert selector `0x1942eea2` (`NotVToken`) |
| `Oracle.setTokenAmount` | revert `OwnableUnauthorizedAccount` |
| `SlpDistributor.distribute` | revert `NotKeeper` |
| `RewardsVault.notifyOracle` | revert `AccessControlUnauthorizedAccount` |
| `SLP1.bond` / `claim` / `transferBack` | revert `AccessControlUnauthorizedAccount` |
| `Staking.claimReward` / `claimStake` | "No rewards to claim" / "No withdrawable stake" |
| `stPROS.withdrawComplete(fresh)` / `withdrawComplete()` | return **0** |
| `BridgeVault.unwrapWrapped()` | succeeds; caller balance unchanged, vault WPROS balance 0 |

## Selected decoded constants

- `bridge.getBalance(WPROS)` returns the **native** balance (because `token == weth`), not the
  WPROS ERC-20 balance. `unwrapWrapped()` converts donated WPROS to native; it pays the caller
  nothing.
- `withdrawComplete(address receiver)` iterates `withdrawals[msg.sender]` only. `receiver` can be
  arbitrary, but the records are the caller's own. The stored `w.receiver` wins when set at redeem.
- `getTotalBalance() = bridgeVault.getBalance(asset) + completedWithdrawal`. Both terms are
  cumulative-since-genesis, matching the cumulative `queued` offset of each withdrawal record.
  This reconciles to zero surplus today.
