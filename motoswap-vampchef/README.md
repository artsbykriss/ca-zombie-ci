# Motoswap / VampChef — Wave B1 deep-dive

**Date:** 2026-10-18 · **Chain:** Ethereum mainnet · **Status:** read-only; no transactions signed or sent; no keyed RPC URLs or secrets in this folder.
**Targets:** `VampChef` proxy `0x51e648f08a9a08A724591938d9cbc483C809aCA4` (impl `0xb85ddf555bf933adfd6d6b3c3500197d9523c214`), `MotoStaking` proxy `0xCE88F2C6B49EfBb92555eE5475311f0e250C2528` (impl `0xb2b1a53d5dc5b5f655d4f4ede4f4517c2a5521f6`, unverified), `MOTO` `0xBd965230588EAA536dE6aA45E8ebbc01638535e0`, and the 20-pair Motoswap UniV2-style AMM.

## TL;DR

| Item | Live value | Why |
|---|---:|---|
| **E-U (external unprivileged)** | **$0** | VampChef: stake/append/harvest/withdraw/emergencyWithdraw do not grant retroactive rewards; `depositFor` cannot top up an existing position; `recoverUndistributedRewards` is owner-only. MotoStaking: stake/append set `rewardDebt` correctly; `claimReward` is owner-only, `claimTokenSelf` reverts `OnlySelf`; principal vests (available = 0 immediately). 20/20 AMM pairs have zero skim surplus. |
| **H-O (holder-only)** | **$4,296.00** | Accrued unclaimed rewards: 1.522828 WETH + 30.528902 USDC + 1.067049 USDT + 1.075731M MOTO (MotoStaking) + 3.537030M MOTO (VampChef outstanding). |
| **P (privileged)** | **$1,396.37** | VampChef owner can sweep 10.986360M undistributed MOTO after the 30-day harvest grace (2026-10-29). |
| **S (stuck)** | **$0** | 99.8% of MOTO is accounted as positions + unstake tickets + rewards; users can exit. |

**Headline: an external unprivileged attacker can extract $0 live. Confidence: high.** User principal is 1,568.46M MOTO (998.84M staked in MotoStaking + 569.62M in VampChef) plus LP tokens; at the thin $0.0001271 MOTO market price that is ~$199k nominal, but exit liquidity is far smaller and it is not attacker-extractable.

## 1. Contracts and roles

| Contract | Address | Code / proxy | Owner / authority |
|---|---|---|---|
| VampChef proxy | `0x51e648f08a9a08A724591938d9cbc483C809aCA4` | ERC-1967; impl `0xb85ddf55…c214` (verified `VampChef`, solc 0.8.26) | `owner()` = `0x94386Bf0482106AA08b121a5828904023dE9EFbC` (EOA, code 0); `upgradesRenounced()` = false |
| MotoStaking proxy | `0xCE88F2C6B49EfBb92555eE5475311f0e250C2528` | ERC-1967; impl `0xb2b1a53d…21f6` (unverified, 21,288 bytes) | `owner()` = `0x94386Bf…`; `upgradeAuthority()` = `0x8a76eD44F01AdcC304e22012693Be86FAC6C2Fa3` (contract, 7,959 bytes; `getMinDelay()` = 0); `upgradesRenounced()` = false |
| MOTO | `0xBd965230588EAA536dE6aA45E8ebbc01638535e0` | 10B fixed supply, 18 dp | no owner/mint |
| VampChef reward token | MOTO | — | rewardBudget 300,000,000 MOTO, emission 2026-09-15 → 2026-09-29 |
| Motoswap factory | `0x81c9cbc47d700da1777abd831d8da3f526dfae24` | UUPS; 20 pairs | `feeToSetter()` = `0x94386Bf…`; `feeTo()` = 0; `swapFeeBps()` = 30 |
| Motoswap pair 0 | `0x302C53B6176F750e5547D775645dc8778524fCc1` | MOTO/WETH; 66.766283M MOTO + 3.571853 WETH; LP supply 15,328.01 | beacon upgradeable by factory owner |

Both proxies are UUPS and the same EOA is the owner. This is a **P-class** concentration (it can upgrade VampChef and the AMM pair beacon; MotoStaking's upgrade is behind `0x8a76…`). It is not an unprivileged path.

## 2. VampChef — accounting and live state

Verified source: `analysis/src_chef_VampChef.sol` (from Etherscan, `VampChef`, solc 0.8.26). Key code:

- `_deposit`: settles pending, then `netShares = balanceAfter - balanceBefore`, `user.amount += netShares`, `pool.lpSupply += netShares`; if the LP token is MOTO, also `totalStakedRewardToken += netShares`; finally `user.rewardDebt = user.amount * accRewardPerShare / ACC_PRECISION`.
- `withdraw`: requires `_amount > 0` and `user.amount >= _amount`; settles pending before shrinking `lpSupply`; recomputes `rewardDebt`.
- `emergencyWithdraw`: calls `updatePool` **before** shrinking `lpSupply`, records `forfeitedReward`, zeroes the position, returns principal.
- `depositFor`: a stranger may only seed a **zero** position (`userInfo[_pid][_user].amount == 0`), and zero-amount calls from non-self return silently; cannot top up an existing position.
- `_safeRewardTransfer`: pays 50% liquid and 50% to the vesting escrow; reverts if `_amount > availableReward()`; `availableReward = MOTO.balanceOf(this) - totalStakedRewardToken`.
- `recoverUndistributedRewards`: `onlyOwner`; only after `emissionEnd + HARVEST_GRACE`; bounded by `availableReward - (totalCredited - totalHarvested - forfeitedReward)`.

Live reads at Ethereum block **26,217,759**:

| Call | Value |
|---|---|
| `poolLength()` | **60** |
| MOTO pool pid | **1** (`poolInfo(1).lpToken = MOTO`, `allocPoint = 0`, `lpSupply = 569,620,424.511779337789789732`) |
| `rewardBudget()` | 300,000,000 MOTO |
| `emissionStart()` / `emissionEnd()` | 1,789,415,087 / 1,790,624,687 (ended 2026-09-29) |
| `totalStakedRewardToken()` | 569,620,424.511779337789789732 MOTO |
| `totalCredited()` | 289,013,640.381895332390360189 MOTO |
| `totalHarvested()` | 285,476,610.056944695923774867 MOTO |
| outstanding staker claim | **3,537,030.324950636466585322 MOTO** |
| `availableReward()` | 14,523,389.943055304076225133 MOTO |
| `recoverableReward()` | **10,986,359.618104667609639811 MOTO** (owner-only, opens 2026-10-29) |
| MOTO balance of chef | 584,143,814.454834641866014865 MOTO |

The MOTO balance is exactly the 569.620M staked principal + 14.523M available reward (+ dust), so `availableReward` cannot be used to pay principal. No accounting shortfall.

### VampChef tests (fork, pinned block 26,217,377)

`poc/test/Moto.t.sol::test_vampChef_publicPaths`:

- a non-staker `harvest(1)` succeeds but pays **0**;
- a non-staker `emergencyWithdraw(1)` returns **0** and moves no MOTO;
- `withdraw(1, 1)` from a non-staker reverts (`InsufficientStaked`);
- `recoverUndistributedRewards(attacker, 1)` from a non-staker reverts (`OwnableUnauthorizedAccount`).

No public path pays a caller who did not stake.

## 3. MotoStaking — accounting and live state

The implementation is unverified, but the function surface, docs (`docs.motoswap.org/dev/reference/contracts-full-inventory`) and live reads are consistent. Key mechanics:

- `positions[user] = { amount, original, durationOption, start, boostBps, duration, availableFloor }`; effective stake = `amount * (10,000 + boostBps) / 10,000`.
- Reward accounting is index-based: `accRewardPerEffShare[token]` (ACC = 1e30), `userRewardDebt[user][token]`, `claimableStored[user][token]`, `pendingClaims[token]`, `rewardOwed[token]`.
- `stake` snapshots the current accumulator; `appendStake` adds principal; `requestUnstake` moves vested principal into a 30-day linear drip ticket and stops it earning.
- `claimReward(account, token)` is **onlyOwner** on-chain (reverts `OwnableUnauthorizedAccount` for a random caller); `claimTokenSelf(account, token)` reverts `OnlySelf`; `claim(address)` is self-only; `claimAsMoto` reverts because `feeRouter()` is the `0x…dEaD` placeholder.

Live reads at block 26,217,759:

| Call | Value |
|---|---|
| `totalEffectiveStake()` | 5,458,651,233.697609719841011135 (effective units) |
| MOTO balance | 1,003,203,174.336639930648793637 MOTO |
| sum of all 537 staker `positions.amount` (events enumeration) | 998,838,638.718479062948062917 MOTO |
| sum of all 537 `claimableUnstaked` tickets | 1,139,518.118012228794210262 MOTO |
| accounted total | 999,978,156.836491291742273179 MOTO (+ 1.075M rewardOwed + dust) |
| `rewardOwed(WETH)` | 1.522828068366930908 WETH |
| `rewardOwed(USDC)` | 30.528902 USDC |
| `rewardOwed(USDT)` | 1.067049 USDT |
| `rewardOwed(MOTO)` | 1,075,731.363397715353857153 MOTO |
| `pendingClaims(WETH)` | 0.028918748277410263 WETH |
| `pendingClaims(USDC)` | 0.589871 USDC |
| `pendingClaims(USDT)` | 403 wei |
| `pendingClaims(MOTO)` | 14,191.899111285326303251 MOTO |

The enumerated positions + tickets account for 999.978M of the 1,003.203M balance; the remaining 3.2M is the 1.076M `rewardOwed` plus ~2.15M (0.2%) unenumerated dust. There is no evidence of a large unaccounted surplus. The earlier concern “1.003B balance vs 545.8M effective stake” was a unit misread: `totalEffectiveStake` is **5.458B** (boosts up to 8x), not 545.8M.

### MotoStaking tests (fork, pinned block 26,217,377)

`poc/test/Moto.t.sol`:

1. `test_stakeDebt_init`: fresh attacker, `pendingReward(WETH)=0`, `stake(1,000 MOTO, option 0)` → pending still **0**; `appendStake(1,000,000 MOTO)` → pending still **0**; `claim(WETH)` pays **0**. No retroactive rewards.
2. `test_appendStake_noRetroactive`: pending before == pending after append == 0.
3. `test_claimPaths_selfOnly`: `claimReward(victim, WETH)` and `claimTokenSelf(victim, WETH)` both revert.
4. `test_requestUnstake_drip`: `available(attacker)` immediately after stake = **0** (principal vests over the 3-month lock; no instant exit).
5. `test_rewardTokenSupplySurplus`: balance/effective/rewardOwed live values (see table).

## 4. Motoswap AMM (context for the $55.6k DL figure)

- `MotoSwapFactory 0x81c9…`: 20 pairs, `swapFeeBps = 30`, `feeTo = 0`, `swapAllowed(router) = true`, `swapAllowed(FeeRouter) = true`.
- All 20 pairs: `balanceOf(pair) == getReserves()` for both tokens → **skim surplus 0** (`analysis/motoswap_pairs.json`).
- MOTO/WETH pair `0x302C…`: 66.766283M MOTO + 3.571853 WETH, LP supply 15,328.012877.
- Known-side value (WETH/USDC/USDT/MOTO at market): **~$36,950**; DefiLlama reports $57,545 because it values the unknown moto.fun tokens too. No E-U path; LP withdrawals are user-owned.

## 5. What an attacker can / cannot do

**Can:** stake MOTO (option 0–3, 3/6/12/24 months), append, request unstake, claim own rewards, harvest/withdraw/emergencyWithdraw in VampChef, swap in the AMM, provide liquidity.

**Cannot:** obtain retroactive rewards from a new stake/append; claim another user’s MotoStaking rewards (`claimReward` owner-only, `claimTokenSelf` OnlySelf); top up another user’s VampChef position; withdraw another user’s LP; sweep `recoverUndistributedRewards`; upgrade the proxies.

**Cost:** staking requires MOTO capital and a 3–24 month lock (available = 0 immediately), so even a hypothetical reward-capture path is capital- and time-gated. No positive net path was found.

## 6. Verdict

| Category | USD | Confidence | Basis |
|---|---:|---|---|
| **E-U** | **0** | **high** | 6/6 fork tests pass; no retroactive rewards; claim paths self/owner-only; no skim surplus; no public sweep |
| E-U-conditional | 0 | high | would require a bug in the unverified MotoStaking impl not covered by the tested selectors; none found |
| H-O | 4,296.00 | high | accrued rewards: 1.522828 WETH + 30.528902 USDC + 1.067049 USDT + 1.075731M MOTO + 3.537030M MOTO VampChef outstanding |
| P | 1,396.37 | high | VampChef owner can sweep 10.986360M undistributed MOTO after 2026-10-29; owner/upgradeAuthority can also upgrade (not counted) |
| S | 0 | high | 99.8% of MOTO accounted; users can exit |

**Residual / latent risk:** (a) both proxies are upgradeable; the VampChef owner is a single EOA and can upgrade or sweep after the grace; MotoStaking's upgrade is behind a 7,959-byte authority contract with `getMinDelay() = 0` (no observed delay); (b) MOTO exit liquidity is thin — the largest Motoswap MOTO/WETH pair holds 3.57 WETH, so the 1.568B MOTO principal is not realizable at the quoted price; (c) the MotoStaking impl is unverified, so a selector outside the tested surface could differ; (d) `claimAsMoto` is not live and the MOTO pool has `allocPoint = 0` (single-sided MOTO stakers earn no new MOTO), which is a design choice, not a leak.

## 7. Methodology / sources / files

- Live reads: Ethereum public RPC at block 26,217,759 (2026-10-18); EIP-1967 slots for both proxies; Etherscan V2 source for VampChef; Blockscout logs for staker enumeration; Motoswap factory/pair reads.
- Fork tests: Foundry 1.8.5, `poc/test/Moto.t.sol`, `vm.createSelectFork` pinned at 26,217,377; 6/6 pass. CI: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39106223350** (success; Foundry 6/6 + live-fact validation).
- Staker enumeration: `analysis/enumerate_stakers.py` (537 accounts from `Staked`/`Appended`/`UnstakeRequested` events; `positions` + `claimableUnstaked` sums).
- Prices: CoinGecko/DefiLlama at 2026-10-18 (MOTO $0.0001271, WETH $2,415.33, USDC $0.99975, USDT $0.99909).
- Files: `analysis/src_chef_VampChef.sol`, `vampchef_abi.json`, `motostaking_impl_code.hex`, `heimdall_motostaking/`, `stakers_positions.json`, `motoswap_pairs.json`, `poc/test/Moto.t.sol`, `poc/lib/forge-std`.
- Caveats: MOTO price is thin/illiquid; the H-O USD excludes the 1.568B MOTO principal and LP tokens (nominal only); the unverified MotoStaking impl is covered by behaviour, not source.
- Nothing here is an instruction to transact.
