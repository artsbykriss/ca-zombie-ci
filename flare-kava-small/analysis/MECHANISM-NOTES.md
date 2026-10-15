# L2-05 EXFI/SFIN governance staking — mechanism notes & evidence index

All reads are Songbird (chain 19) via keyless `https://songbird-api.flare.network/ext/C/rpc`.
Blocks: 135,442,983 → 135,447,100 (2026-10-15).

## Contracts

| Name | Address | Notes |
|---|---|---|
| EnosysGovernanceStakeManagerExfi | `0xc4D89F8f593F215f3636793E3353A36C196Cf87A` | TransparentUpgradeableProxy; impl `0xB0E4D5baB93B0a7a6A99b7AFCfb50501d8B19772` (unverified); admin `0xEE8Cc71c23556B17e23218CDa507350C36879677`; owner EOA `0x28591A8d1a899Ca78a6b517E70c9ed327a26b42c` |
| EnosysGovernanceStakeManagerSfin | `0xA83E90337e2711b1c84df0AD7428403dBd0ce730` | same impl bytecode (`0xB0E4D5ba…`) |
| FarmingPool (EXFI→SFIN, expired) | `0xb78ebd4b13a2202068618bf98f952c0271159107` | verified source `FarmingPoolProxy` → `0x2Aa2a34fA51C34d56BAA26aa92B4E877A0446fF0`; `periodFinish=1735905600` (2025-01-03) |
| APYCloud notifier | `0xb8d1c66a815ef8735603cff7997ccc1ba24d8c1b` | the only address allowed to call `updateRewardAmountByToken` (read via raw selector `0xa5032f3c`) |
| apyCloudVault | `0xD971EFb6B3dC0E7FC11b3C7FCc5E15d45b410b27` | holds 0 tokens today; `triggerDistribution(bool)` permissionless but epoch-rate-limited ("NewEpochNotStarted") |
| Reward tokens (8) | WSGB `0x02f0…B9ED`, EXFI `0xC348…6e21`, SFIN `0x0D94…eA1B`, exXDC `0xC54D…670c`, FXRP `0xF9a8…027d`, exETH `0x36B8…5c94`, exUSDT `0x1a7b…03D0`, USDX `0x4A77…3d2B` | decimals 18 except FXRP/exUSDT/USDX = 6 (scaling `10^(18-dec)` in payouts) |

## Core semantics (verified)

- `DURATION = 86400`, `ZERO_EPOCH_START = 1759406400` (2025-10-02 12:00 UTC), `epoch = (block.timestamp - ZERO)/86400 + 1`.
- `epochInterval(e)` = [first stake/withdraw block, last stake/withdraw block] in epoch e.
- `epochSnapshotBlock(e)` = a block inside that interval with **no interaction at it** (e377: `135,308,151`; e376: `135,239,270`; e375: `135,146,390`). Stored at the next epoch's first interaction.
- `balanceOfEpoch(user,e) = getBalanceAt(user, epochSnapshotBlock(e))` — checkpoint binary search (block,balance), veCRV-style.
- `epochRewardRate(e,token) = amount(e,token) × 1e18 / totalSupplyByEpoch(e)` computed at registration.
- `unclaimed(user,token) = Σ_e balanceOfEpoch(user,e) × epochRewardRate(e,token) / 1e18 / 10^(18-decimals(token))`.
- Live check: `getAllUnclaimedRewards` == the formula for 3 stakers + fresh address, all 8 tokens (`ci/run.sh`, `FORMULA_IDENTITY PASS`).
- Storage slots (brute-forced against live values): **159 = epochSnapshotBlock**, **164 = totalSupplyByEpoch** (`keccak256(abi.encode(key, slot))`), 158 = epoch interval start.

## Adversarial results (all closed)

| Attack idea | Evidence |
|---|---|
| Retro-claim for pre-stake epochs | fresh `balanceOfEpoch(e)=0` for e ∈ {0,1,10,100,200,300,376}; `getAllUnclaimedRewards=0`; claim reverts `No any rewards` |
| Hint corruption (`stakeWithHint`/`withdrawWithHint`) | oversized hint → `Balance hint is larger than expected value`; undersized accepted, search self-corrects; checkpoints sorted; past epochs 0 (local bytecode test L3) |
| Reward forgery | `updateRewardAmountByToken` → `Not allowed reward notifier` for all but `0xb8d1c66a…` |
| Governor forgery | `addVoting`/`updateVoting` → `Not a governor` |
| Owner takeover / mint reward tokens | `Ownable: caller is not the owner` |
| Pending-fee theft | `withdrawReturnedFees(bool)` → `No pending fees` (fees only created by governor `addVoting`) |
| Epoch-total manipulation | `updateTotalSupplyByEpochIfNeeded(e)` is idempotent (returns stored value exactly for e=370–376); current/next epoch rejected |
| Double claim | second claim → `At least one epoch has not passed`; payout equals formula exactly |
| Over-withdraw / principal theft | `withdraw(balance+1)` reverts; 1:1 transfer; manager balance ≥ totalSupply |
| Flash-stake at snapshot | snapshot is a past, non-interaction block → momentary balances cannot be counted; must hold across an unknown mid-epoch block |
| FarmingPool third-party withdraw | `withdrawFor`/`withdrawAndGetRewardFor` → `StaticPool: Not allowed caller` (onlyAllowedCaller); `rescue*` owner-only |

## Residual economics

- Per-epoch reward flow: **2,189.23 EXFI ($22.22) + 61.05 WSGB ($0.05)** + dust (epoch 376 registration, blocks 135,370,353).
- Unclaimed pools: 87,479 EXFI ($888) in the EXFI manager; 313,828 EXFI ($3,185) + 134,074 WSGB ($116) in the SFIN manager.
- Principal: 16,176,444 EXFI ($164,188) + 5,945.18 SFIN ($487,623) — H-O only.

## Evidence files

- `stake_manager_abi.json` — full recovered ABI (80 functions) from the gov.enosys.global bundle (`govjs/`).
- `sel_A.txt` — bytecode selector scan of the impl (83 selectors; 4 extra vs frontend ABI, incl. the notifier getter `0xa5032f3c` and `updateTotalSupplyByEpochIfNeeded`).
- `impl_hex.txt` / `../poc/exfi_impl_bytecode.hex` — deployed runtime bytecode used in the local PoC.
- `farmingpool_src.sol`, `fp_impl_src.sol` — verified FarmingPool source.
- `*_logs.json` — RewardPaid / UpdateRewardAmountByToken / StoreStoreSnapshotBlockBlock / Staked / Withdrawn logs used for the epoch/snapshot analysis.
- `enosys_refs/` — Enosys address tables (Songbird/Coston) from the flare-builders-toolkit.
- `/tmp/opencode/decomp_exfi/govstake-decompiled.sol` — heimdall decompilation (regenerable; not committed).
