# Sophon Farm — reward-math audit + live-state fork assessment

**Date:** 2026-10-18
**Chains:** Sophon (50104 / 0xc3b8), Ethereum (1)
**Status:** READ-ONLY. No transaction was signed or sent. All probes are `eth_call` / `eth_estimateGas` / archive reads. The Foundry suite is a local **logic model**, not a zkEVM fork (Foundry/revm cannot execute zkSync-era bytecode; `eth_getCode` for the farm starts `0x00010000…`, and the explorer reports `isEvmLike: false`).

---

## 1. TL;DR

| Target | Live unprivileged extractable | Why closed / open | Latent risk |
|---|---:|---|---|
| Sophon L2 farm `0x5753…97bb` (25 pools) | **$0** | No reward token exists. LP deposits are 1:1 accounted; `withdraw` is hard-bounded by the caller's `depositAmount`; the only permissionless state-changing calls (`massUpdatePools`, `claimMultiple`) move no tokens / credit only the merkle leaf user. Deposits are disabled (farm ended). | Stale value weights if the owner ever re-enables emissions via upgrade; zero-amount pool dilution; `_emergencyRescue` added in the current implementation (P). |
| Sophon merkle claim `0xa24F…CEa0` | **$0** | `MerkleProof.verify` on `(user,pid,amount,boost,deposit,rewardSettled,rewardDebt)`; `hasClaimed[user][pid]` set before the external call; `claimMultiple` forces the receiver to the leaf user. `unclaim` is `ADMIN_ROLE`. | Admin can set a new root and/or replay `unclaim` (P). |
| Ethereum L1 farm `0xeff8…e064` (15 pools) | **$0** | All pools bridged (`isBridged=true` except empty ZENT); LP balances are 0; withdrawal window closed for everyone except `PENDLE_EXCEPTION`; no rescue function. | None material; 372.32 PEPE + 100 BEAM dust stuck. |

**Total live extractable by an external unprivileged attacker: $0** (confidence **high**).

The ~$2.80M is **user-owned** and **owner-custodial**, not attacker-extractable:
- **H-O** ≈ **$2,801,340** (L2 withdrawable deposits minus the PEPE hole, plus Pendle's L1 PEPE),
- **P** ≈ **$2,801,393** (the 2-of-6 owner Safe can sweep every L2 LP token with the new `_emergencyRescue`, or upgrade the implementation; the 3-of-7 merkle-admin Safe can mint claims via a new root),
- **S** ≈ **$86.50** (PEPE pool is 22,304,710.35 PEPE = $86.21 short of its credited liabilities; ~$0.29 of L1 dust).

P and H-O overlap: the same L2 assets are either withdrawn by their credited owners or swept by the owner. They are not additive.

---

## 2. Contracts, source verification, and authority

All reads below are at **Sophon block 29,675,399** (latest 29,675,405) and **Ethereum block 26,217,691**, unless noted.

### 2.1 Sophon L2

| Role | Address | Code / source | Notes |
|---|---|---|---|
| Farm proxy | `0x5753fBeC29De6E2b56F73f7d7786e9f0d34897bb` | `contracts/proxies/SophonFarmingProxy.sol:SophonFarmingProxy`, zksolc v1.5.6, solc 0.8.26 | Custom `Proxy2Step` (not EIP-1967). Storage: slot0 `owner`, slot1 `pendingOwner`, slot2 `pendingImplementation`, slot3 `implementation`. |
| Farm implementation | `0xbd0AAfC995dAB4DC868323BEc81B189De2556012` | `contracts/farm/SophonFarmingL2.sol:SophonFarmingL2`, zksolc v1.5.7, solc 0.8.26 | Verified on the Sophon explorer. Constructor args `(MERKLE, priceFeeds)` = `(0xa24F…CEa0, 0x2eDf…Dd48)`. |
| Owner | `0xa3b1f968b608642dD16d7Fd31bEc0B2c915908dB` | **Safe v1.4.1, threshold 2 of 6** | Owners: `0x3b6036d4…2d89`, `0x45Bd9b1B…53f8`, `0x4BBBaCCb…c336`, `0x1b3CfD17…2FDe`, `0x891F19Cd…A845`, `0x1B5a420D…F96c`. |
| `pendingOwner` / `pendingImplementation` | `0x0` / `0x0` | — | No in-flight ownership or upgrade change. |
| MERKLE (immutable) | `0xa24F69fAA295426Bca2Cf610bf992CDc992CeEa0` | UUPS proxy; impl `0xe710a2d4a89b98b7a910f99cec85aea02ed96949` = `contracts/airdrop/MerkleAirdrop.sol:MerkleAirdrop`, zksolc v1.5.7 | Initialized with `SF_L2 = 0x5753…97bb`. |
| MERKLE admin | `0x902767c9e11188C985eB3494ee469E53f1b6de53` | **Safe v1.4.1, threshold 3 of 7** | Holds `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` (final state from `RoleGranted`/`RoleRevoked` logs). Same Safe owns `PriceFeeds`. |
| Price feeds | `0x2eDf18b640A705F16947A7B95Fc338fde340Dd48` | custom proxy; impl `0x199691D230e2ba604F0387De890eC5Ea6Be15f91` = `contracts/farm/PriceFeeds.sol:PriceFeeds`, zksolc v1.5.6 | Owner = `0x902767…de53` (same 3-of-7 Safe). Oracle = Stork. |
| LP admin | `0x4cb9ac68A2151f14E8242a984b1F1faDb36EBF60` | **EOA** (0 bytes code) | `lpAdmin`; no role in the farm or merkle contract now. `submitLP` is dead (see §5.7). |
| Upgrade history | 9 `ReplaceImplementation` events | latest at block **29,115,213** → `0xbd0a…6012` | The current implementation added `_emergencyRescue` and `_extHeldLPs(receiver)` (see §6). |

Explorer source endpoints used (keyless):
- `https://api-explorer.sophon.xyz/api?module=contract&action=getsourcecode&address=<addr>`
- `https://api-explorer.sophon.xyz/api?module=contract&action=getabi&address=<addr>`
- `https://api-explorer.sophon.xyz/docs-json` (OpenAPI; confirms the Etherscan-style endpoints)

The explorer `/api` is **not** the zkSync block-explorer API; it is a NestJS Etherscan-compatible facade at `api-explorer.sophon.xyz`. Etherscan V2 does **not** support chain 50104 (`Missing or unsupported chainid`), and the local `$ETHERSCANV2_API_KEY` returned `Invalid API Key` for chain 1, so **Sourcify v2 was used for the Ethereum sources**:
`https://sourcify.dev/server/v2/contract/1/<addr>?fields=sources,metadata`.

### 2.2 Ethereum L1

| Role | Address | Code / source | Notes |
|---|---|---|---|
| L1 farm proxy | `0xeff8e65ac06d7fe70842a4d54959e8692d6ae064` | `SophonFarmingProxy.sol`, Sourcify full match | Same custom `Proxy2Step` layout; `implementation()` = `0x6191…5F31`. |
| L1 implementation | `0x61916427307520bE86F7cB53306a443b30e35F31` | `contracts/farm/SophonFarming.sol:SophonFarming`, solc 0.8.26 | Season-1 farm: `allocPoint`, boost purchases, `bridgePool`. |
| Owner | `0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD` | **Safe v1.4.1, threshold 3 of 5** | Owners: `0x45Bd…53f8`, `0x1B5a…F96c`, `0x83E1…Cad5`, `0x1b3C…2FDe`, `0x3454…055c`. |
| `endBlock` / `endBlockForWithdrawals` | `21,440,000` / `21,489,990` | — | Both passed at Ethereum block 26,217,691. `isFarmingEnded=true`, `isWithdrawPeriodEnded=true`. |
| `poolLength` | 15 | — | `isBridged[pid]=true` for 14/15; pid 5 (ZENT) has 0 amount and no l2Farm. |

### 2.3 Trust summary

- Farm owner: **2-of-6 Safe**.
- Merkle admin + price-feed owner: **3-of-7 Safe**.
- L1 owner: **3-of-5 Safe**.
- The two Sophon Safes share three owners (`0x3b60…`, `0x4BBB…`, `0x891F…`), so the same small signer group controls both privileged paths. Thresholds are 2/6 and 3/7, not 1/1 EOAs.
- `PriceFeeds` is upgradeable by the same 3-of-7 Safe; `MerkleAirdrop` is UUPS-upgradeable by its `ADMIN_ROLE` (same Safe).

---

## 3. Live state at block 29,675,399 (balances at 29,675,272)

No `Deposit`, `Withdraw`, or `PoolUpdated` event was emitted after block **29,675,272** (verified with `eth_getLogs` for each topic over `29,675,273..latest`), so the balance snapshot at 29,675,272 is the state at 29,675,399. The explorer balance dump is `evidence/farm-address.json`.

`poolLength = 25`. `pointsPerBlock = 1e19`, `endBlock = 14,476,600`, `endBlockForWithdrawals = 46,012,600`, `boosterMultiplier = 5e18`, `totalAllocPoint = 0` (unused on L2), `totalValue = 13,440,291,919,490,392,418,772,600` (= sum of all `poolValue.lastValue`), `isFarmingEnded = true`, `isWithdrawPeriodEnded = false`.

| pid | Pool | LP token | `pool.amount` (incl. boost) | `depositAmount` (liability) | Farm `balanceOf` (asset) | Asset − liability | Asset USD |
|---:|---|---|---:|---:|---:|---:|---:|
| 0 | sDAI | `0xeCcbb936…439B` | 928,313.517977893068335608 | 220.885445889044273263 | 220.885445889044273263 | 0 | $261.15 |
| 1 | wstETH | `0x60D02F18…078B` | 42.551481871652596527 | 13.921621210593511482 | 13.921621210593511482 | 0 | $41,904.76 |
| 2 | weETH | `0x5E9Fc50b…8F8D` | 130.285190305751338730 | 5.087162606644514900 | 5.087162606644514900 | 0 | $13,586.99 |
| 3 | BEAM | `0x7A94dFb5…0880` | 987,128,303.148865482561029267 | 160,521,592.346014775244024767 | 160,521,592.346014775244024767 | 0 | $460,481.76 |
| 4 | BEAM/ETH UNI-V2 | `0xfF600D73…D994` | 79,975.991820304757275630 | 758.137188098974749435 | 758.137188098974749435 | 0 | n/p |
| 5 | ZENT | `0x0` | 0 | 0 | — | — | $0 |
| 6 | Staked Zentry | `0x351ca00C…ac19C` | 449,415,397.712754942193540234 | 84,490,004.243161014422650784 | 84,490,004.243161014422650784 | 0 | n/p |
| 7 | USDC | `0x9Aa0F723…Db4F` | 490,366.718703 | 9,212.052773 | 9,212.052773 | 0 | $9,212.05 |
| 8 | stAethir | `0x42E5bFdC…Ef997` | 453,465,777.703195383084873287 | 407,915,308.040617045464392287 | 407,915,308.040617045464392287 | 0 | $2,228,437.87 |
| 9 | PEPE | `0x06432e41…dd8A` | 7,209,046,461.467060361093259895 | 2,734,206,348.092541326236759895 | 2,711,901,637.743620170306992171 | **−22,304,710.348921155929767724** | $10,481.54 |
| 10 | wBTC | `0xF1f9E08a…960E` | 5.31688989 | 0.03781649 | 0.03781649 | 0 | $3,083.22 |
| 11 | Azuro | `0x841bE23f…3811` | 9,884,670.012916081056831270 | 3,576,302.426400671179851170 | 3,576,302.426400671179851170 | 0 | n/p |
| 12 | USDT | `0x6386dA73…7169` | 314,315.717469 | 24,654.293994 | 24,654.293994 | 0 | $24,654.29 |
| 13 | stAVAIL | `0xB2253e3D…2A3e` | 6,071,105.895199920325607741 | 1,834,445.506899800075862741 | 1,834,445.506899800075862741 | 0 | n/p |
| 14 | OPN | `0xA96aD8EC…4295` | 293,999,094.763902229579153980 | 20,366,635.284453827734153980 | 20,366,635.284453827734153980 | 0 | n/p |
| 15 | ETH | `0x72af9F16…567D` | 3.853938276287493803 | 3.853938276287493803 | 3.853938276287493803 | 0 | $9,289.58 |
| 16 | ETHUSDC_LP | `0x353B35a3…d4A7` | 0.000009717293901543 | 0.000009717293901543 | 0.000009717293901543 | 0 | n/p |
| 17 | ETHUSDT_LP | `0x51d4C0A6…B3F4` | 0.000001032797748881 | 0.000001032797748881 | 0.000001032797748881 | 0 | n/p |
| 18 | ATHETH_LP | `0x131bCf81…2Ee6` | 0.534130105624010297 | 0.534130105624010297 | 0.534130105624010297 | 0 | n/p |
| 19 | OPNETH_LP | `0x4C0819fD…739D` | 0.038361651092660000 | 0.038361651092660000 | 0.038361651092660000 | 0 | n/p |
| 20 | BEAMETH_LP | `0x0110EB76…036B` | 0.002525104118468820 | 0.002525104118468820 | 0.002525104118468820 | 0 | n/p |
| 21 | USDCUSDT_LP | `0x61a87fa6…5935` | 4,097.278040103316680839 | 4,097.278040103316680839 | 4,097.278040103316680839 | 0 | n/p |
| 22 | MUPETH_LP | `0xBeF8358a…2727` | 2,663.705138658500369859 | 2,663.705138658500369859 | 2,663.705138658500369859 | 0 | n/p |
| 23 | SUSNUSD | `0xb87DbE27…5004` | 8.308086764165070884 | 8.308086764165070884 | 8.308086764165070884 | 0 | n/p |
| 24 | USNUSD | `0xC1AA99c3…6d36` | 25.126979068033821041 | 25.126979068033821041 | 25.126979068033821041 | 0 | n/p |

`pool.amount` includes migrated **boost** amounts (from the L1 `increaseBoost` purchases) and can be much larger than `depositAmount`; only `depositAmount` is withdrawable. That is why, for example, sDAI shows 928,313.5 `pool.amount` but only 220.885 sDAI of assets/liabilities. Boost amounts earn points but are not backed by withdrawable tokens.

Priced assets (DL-implied prices, USDC/USDT at $1): **$2,801,393.22**. Priced liabilities: **$2,801,479.43**. The $86.21 gap is exactly the PEPE shortfall. DefiLlama reports **$2,769,518.37** on Sophon and **$33.34** on Ethereum at 2026-10-18; the difference is that DL excludes USDC/USDT and some unpriced LP dust. Both are consistent with the on-chain balances.

`getPoolInfo()` per pool additionally returns `accPointsPerShare` and `totalRewards` (points only; no token). Full raw dump: `evidence/poolinfo-pinned.json`, `evidence/live-state-table.json`.

### 3.1 Price-feed state

`priceFeeds.getPrice(lpToken)` returns **0 for all 25 pools** at block 29,675,399 (Stork quotes are stale; `PriceFeeds.getStorkPrice` returns 0 when `block.timestamp > timestamp + staleSeconds`, and returns 0 for an unset feed). This does **not** revert; `massUpdatePools()` succeeds from an unprivileged sender (`eth_call` from `0x…dEaD` returns `0x`), and withdrawals work.

The stored `poolValue[pid].lastValue` values are frozen at each pool's **last live price update**; they are now stale because `getPrice` returns 0. `totalValue` = sum of those `lastValue`s = 13,440,291,919,490,392,418,772,600, which matches exactly. Because `endBlock = 14,476,600` and `_getBlockMultiplier` caps at `endBlock`, the post-end staleness has **zero effect on emitted points**. As a timing check, `PoolUpdated` events in the sampled 14.0M–14.48M window still carried non-zero prices at block 14,479,884 (just after `endBlock`) for pids 0/7/8/12, so the sampled feeds were live through the end of emissions; the stored weights are from later live updates (post-end) and went stale only afterwards.

`PoolUpdated` sample (block 14,479,884):

| pid | `currentValue` | `newPrice` |
|---:|---:|---:|
| 0 sDAI | 3,745,538,920,949,926,343,812,338 | 1.194834456158e18 |
| 7 USDC | 593,623,946,215,000,000,000,000 | 0.999949949999e18 |
| 8 stAethir | 16,454,415,801,183,578,715,102,218 | 0.028297658399e18 |
| 12 USDT | 530,540,418,648,000,000,000,000 | 1.000199999999e18 |

The sampled feeds (pids 0/7/8/12, the largest pools) were live through the end of emissions; we found no evidence of staleness during the live period. The stored weights are from later post-end updates and are now stale, but emissions were already zero.

---

## 4. The mechanism in exact terms (source refs)

Source files (extracted from the verified standard-json) are in `evidence/`:

- `src_contracts__farm__SophonFarmingL2.sol` — the live implementation.
- `src_contracts__farm__SophonFarmingState.sol` — storage layout.
- `src_contracts__airdrop__MerkleAirdrop.sol` — claim logic.
- `src_contracts__farm__PriceFeeds.sol` — Stork price adapter.
- `l1_contracts__farm__SophonFarming.sol` — Ethereum Season-1 farm.
- `impl-5c45.sol`, `impl-6642.sol`, `impl-df5e.sol` — prior L2 implementations (upgrade diff).

### 4.1 There is no reward token

`SophonFarmingL2` has **no reward-token address, no `harvest`/`claim`/`compound`, and no token transfer other than LP withdrawals** (full ABI in `evidence/impl-abi.json`). Rewards are points (`accPointsPerShare`, `rewardSettled`, `rewardDebt`, `totalRewards`); they are never redeemed on-chain by this contract. The only ERC20 movements are:

1. `deposit` → `lpToken.safeTransferFrom(user, farm, amount)` (disabled by `isFarmingEnded`),
2. `withdraw` → `lpToken.safeTransfer(user, amount)` (bounded by `user.depositAmount`),
3. `_extHeldLPs` / `_emergencyRescue` (owner only),
4. `submitLP` (lpAdmin/owner; dead — see §5.7).

Therefore the farm's on-chain "reward reserve" is **0 tokens**. The only value in the contract is the users' LP deposits.

### 4.2 Pool accounting (1:1, no shares)

`_deposit` (`SophonFarmingL2.sol:590-628`) adds the exact transferred `_depositAmount` to `user.depositAmount`, `pool.depositAmount`, `user.amount`, and `pool.amount`. `withdraw` (`:646-691`) bounds `_withdrawAmount` by `user.depositAmount` and subtracts it from both the user and pool counters before transferring. There is no share mint/burn, no `balanceOf`-derived supply, and no donation-sensitive exchange rate. The invariant `user.amount >= user.depositAmount` is preserved by every path:

- deposit: both += amount;
- `updateUserInfo`: `require(claim.amount == claim.boostAmount + claim.depositAmount)`; `amount += claim.amount`, `depositAmount += claim.depositAmount`, `boostAmount >= 0` ⇒ amount increment ≥ deposit increment;
- withdraw: both -= w, w ≤ depositAmount;
- `transferPoints`: does not touch `amount`/`depositAmount`.

This is the core reason an attacker cannot withdraw more than they are credited with.

### 4.3 `updatePool` / `massUpdatePools` / `_settlePool`

`_updatePool` (`:525-566`):

```
values[0] = pool.lastRewardBlock;
if (block < values[0]) return;                 // pool not started
values[1] = pv.lastValue;                      // <-- set BEFORE same-block check
if (block == values[0]) return;                // already updated this block
values[2] = pool.amount;
if (values[2] == 0) return;                    // <-- stale values[1] survives
values[3] = priceFeeds.getPrice(pool.lpToken);
if (values[3] == 0) return;                    // <-- stale values[1] survives
newValue = values[2] * values[3] / 1e18 * pv.emissionsMultiplier / 1e18;
pv.lastValue = newValue; values[1] = newValue;
```

`massUpdatePools` (`:480-522`) sums `values[1]` over all pools into `totalNewValue` and writes `totalValue = totalNewValue`; then, for pools with `block > values[0]`, `values[2] != 0`, `values[1] != 0`:

```
blockMultiplier = (min(block, endBlock) - lastRewardBlock) * 1e18  (0 if ended)
pointReward    = blockMultiplier * pointsPerBlock * values[1] / totalNewValue
pool.totalRewards += pointReward / 1e18
pool.accPointsPerShare += pointReward / values[2]
pool.lastRewardBlock = block
```

`_settlePool` (`:442-465`) mirrors this for views, using `totalValue` and `pv.lastValue`, and `_pendingPoints` (`:408-417`) returns `user.amount * acc / 1e18 + rewardSettled - rewardDebt`.

**Units:** `accPointsPerShare` is 1e18-scaled per share; user points are `amount * acc / 1e18` (unscaled); `pool.totalRewards` accumulates `pointReward / 1e18` and is not in the same unit as user points (informational inconsistency, not security).

### 4.4 `updateUserInfo` — the migration / claim path (`:178-203`)

```
if (msg.sender != MERKLE) revert OnlyMerkle();
require(claim.amount == claim.boostAmount + claim.depositAmount);
massUpdatePools();
user.amount += claim.amount;
user.rewardSettled = user.amount * acc / 1e18 + user.rewardSettled - user.rewardDebt;
user.rewardSettled += claim.rewardSettled;
user.boostAmount += claim.boostAmount;
user.depositAmount += claim.depositAmount;
user.rewardDebt = user.amount * acc / 1e18;
```

This is the only path that creates new `user.depositAmount` without a token transfer. It is gated to the immutable `MERKLE` contract. `MerkleAirdrop._claim` (`MerkleAirdrop.sol:111-124`) verifies

```
keccak256(abi.encodePacked(user, pid, amount, boostAmount, depositAmount, rewardSettled, rewardDebt))
```

against `merkleRoot`, sets `hasClaimed[user][pid] = true` **before** the external call, and calls `SF_L2.updateUserInfo(...)`. All fields are fixed-size, so `abi.encodePacked` is unambiguous. `claimMultiple` (`:98-109`) is permissionless but forces the receiver to the leaf `_user`; it cannot redirect a claim. `claim` (`:83-86`) requires `msg.sender == _user`. `unclaim` (`:36-38`) is `ADMIN_ROLE`.

**Retroactive credit:** because `user.amount` is increased *before* the settled-points calculation, a claim of `C` credits `C * accPointsPerShare / 1e18` for the entire L2 index, in addition to the `claim.rewardSettled` from the leaf. The code comment says this is intentional ("backdated rewards on claimed amounts"). It inflates points for migration claimants; it does not create tokens. The model test `test_migrationBackdatedCredit` demonstrates the formula (100e18 claim + 5e18 leaf ⇒ 105e18 settled at acc=1e18).

---

## 5. Closed attack paths (with evidence)

### 5.1 Withdraw more than your own deposit — CLOSED

`withdraw` checks `_withdrawAmount <= user.depositAmount` (`:661-665`) and subtracts before transferring (`:676-688`). A real depositor with `depositAmount = 1.1e16` sDAI:

```
cast call farm "withdraw(uint256,uint256)" 0 1 --from 0xc09e64cc126be6ed023ea144e379dc32802d1a68  -> 0x (success)
cast call farm "withdraw(uint256,uint256)" 0 max --from 0xc09e… -> 0x (success)
cast call farm "withdraw(uint256,uint256)" 0 11000000000000001 --from 0xc09e… -> revert WithdrawTooHigh(11000000000000000)
```

From `0x…dEaD` (no deposit): `withdraw(0,1)` → `WithdrawTooHigh(0)`; `withdraw(0,max)` → `0x` but moves 0 tokens (the `max` sentinel resolves to 0 after the zero check).

### 5.2 Create `depositAmount` without a merkle proof — CLOSED

The only writer of `user.depositAmount` is `_deposit` (requires a token transfer, and is disabled) and `updateUserInfo` (requires `msg.sender == MERKLE`). Probe: `updateUserInfo(dead,0,(0,0,0,0,0))` from `0x…dEaD` → `OnlyMerkle`. The MERKLE contract's `claim`/`claimMultiple` require a valid proof; `claimMultiple` from `0x…dEaD` with a bogus proof → `InvalidMerkleProof`.

### 5.3 Double-claim / replay — CLOSED unprivileged

`hasClaimed[user][pid]` is set before `updateUserInfo`; a second claim reverts `AlreadyClaimed`. `unclaim` is `ADMIN_ROLE` (P, §6). The leaf binds the user and pid, so a proof cannot be reused for another user or pid.

### 5.4 Reward-debt underflow / brick — CLOSED

`accPointsPerShare` only increases. After every settle, `rewardSettled - rewardDebt` is ≥ 0 at the then-current acc; `transferPoints` can reduce `rewardSettled` below `rewardDebt`, but the next settle uses a **higher** acc (`amount*acc_new + settled - amount*acc_old ≥ 0`). There is no path that decreases acc. Solidity 0.8 checked arithmetic reverts rather than wrapping. `withdraw` was simulated successfully for a real depositor, so the live accounting is not bricked; `deposit` is intentionally disabled after `endBlock`.

### 5.5 Share inflation / donation / first depositor — CLOSED

No shares; `pool.amount` is an internal counter incremented by the exact transferred amount, never read from `balanceOf`. Sending LP tokens directly to the farm increases `balanceOf` but not `pool.amount`, so it only adds a buffer for withdrawers; it cannot inflate anyone's points or withdrawal. There is no first-depositor exchange-rate math.

### 5.6 Flash deposit / one-block amplification — CLOSED

`deposit` calls `massUpdatePools()` **before** adding the new amount to `pool.amount`, so the new deposit earns nothing for the deposit block. A same-block `withdraw` calls `massUpdatePools()` again; `_updatePool` returns at `block == lastRewardBlock` and the second loop skips, so the flash position earns **zero** points. Across a block boundary, a deposit earns one block of points proportional to its share; points are not tokens and there is no token payout. Deposits are currently disabled (`isFarmingEnded`).

Model test `test_sameBlockSecondMassUpdateNoDoubleAccrual` (6/6 PASS) shows exactly one block of emission and no same-block double accrual.

### 5.7 `submitLP` / residual approvals — CLOSED

`submitLP` (`:139-176`) is `lpAdmin || owner`; `lpAdmin` is the deployer EOA `0x4cb9ac68…`. It calls the SyncSwap router `0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295` with arbitrary calldata, then requires `lpAmountA != 0 && lpAmountA <= heldProceeds[pidA]` and the same for B. **All `heldProceeds[0..24]` are 0**, and **all LP-token allowances from the farm to the router are 0** (read for all 24 tokens). The function therefore reverts even for `lpAdmin`; no residual approval can move tokens. Probe from `0x…dEaD`: `submitLP(0,0,0x)` → `unauthorized`.

### 5.8 Harvest-on-behalf / public `updatePool` — CLOSED

There is no `harvest`, `claim`, or `compound` in the farm ABI. `updatePool` is **internal** on L2 (`_updatePool`); only `massUpdatePools` is public, and it moves no tokens. The L1 farm has a public `updatePool(pid)` but it only updates point accounting; it cannot transfer tokens. The prior lane's "unguarded updatePool/compound" flag does not match this deployed code (no `compound` in any of the four verified L2 implementations).

### 5.9 Boost stale index — CLOSED in the live period

On L2, `_boostAmount` is ignored and `getMaxAdditionalBoost` returns 0 (`:590-599`, `:637-639`); no new boost can be created. Migrated boost amounts are included in `pool.amount` and earn points, but they are not withdrawable (`withdraw` is bounded by `depositAmount`). The L1 boost logic is bounded by `depositAmount` and holds the proceeds (`heldProceeds`); all L1 `heldProceeds` are 0 and all pools are bridged. The sampled price feeds were live through `endBlock` (§3.1), so the value-weighted emission index was not stale during the sampled live period.

### 5.10 Price-feed manipulation — CLOSED unprivileged

Prices come from Stork via `PriceFeeds.getPrice` (`PriceFeeds.sol:20-28`), not from a DEX spot pool. An unprivileged attacker cannot write `storkData` (owner-only `setStorkFeedsData`). All current quotes are stale (return 0), which freezes the value weights but does not revert or pay anything (emissions ended). The feed owner can change feeds (P, §6).

### 5.11 `massUpdatePools` griefing — CLOSED

`massUpdatePools` is permissionless and O(25) with 25 external `staticcall`s (gas estimate ~1,590,780 at block 29,675,399). Calling it repeatedly costs the caller gas and cannot block withdrawals (each `withdraw` calls it again; it succeeds because `getPrice` returns 0 rather than reverting). It moves no tokens.

---

## 6. Privileged paths (P) — the real risk

### 6.1 Farm owner can sweep every LP token: `_emergencyRescue`

The **current** implementation (`0xbd0a…6012`, added at upgrade block **29,115,213**) contains:

```solidity
function _emergencyRescue(address[] memory tokens, address receiver) external onlyOwner {
    for (uint256 i; i < tokens.length; i++) {
        IERC20 token = IERC20(tokens[i]);
        uint256 balance = token.balanceOf(address(this));
        if (balance != 0) IERC20(token).safeTransfer(receiver, balance);
    }
}
```

Simulation from the owner Safe (read-only `eth_call`):

```
cast call farm "_emergencyRescue(address[],address)" \
  "[0xeCcbb936…439B,0x9Aa0F723…Db4F,0x42E5bFdC…Ef997]" 0xa3b1…08dB \
  --from 0xa3b1…08dB   -> 0x (success)
```

The owner can pass all 24 LP tokens in one call and receive **$2,801,393.22** of assets. The prior implementation (`0x5c45…`) only had `_burnHeldLPs`, which burned `heldProceedLPs` (all zero); the latest upgrade **added arbitrary-receiver sweeping of user deposits**. This is a material change in the trust model.

### 6.2 Farm owner can replace the implementation

`replaceImplementation(address)` from the owner Safe → `0x` (success). Then the new implementation calls `becomeImplementation(proxy)` (requires `msg.sender == proxy.owner()`) → `acceptImplementation()`. The owner can install arbitrary code, including code that bypasses `withdraw` bounds or transfers all LP tokens. `pendingImplementation = 0` now, but the owner can start the two-step upgrade at any time.

### 6.3 Merkle admin can mint claims and drain

The `MerkleAirdrop` `ADMIN_ROLE`/`DEFAULT_ADMIN_ROLE` holder is the 3-of-7 Safe `0x902767…de53`. Simulations from that Safe:

```
setMerkleRoot(0x1111…1111)  -> 0x (success)
grantRole(ADMIN_ROLE, self) -> 0x (success)
```

With a crafted root (e.g., a single-leaf tree for an attacker address with a huge `depositAmount`), the admin can call `claim(_user, _customReceiver, pid, userInfo, proof)` (the admin variant allows an arbitrary receiver) → `updateUserInfo` credits `depositAmount` → `withdraw` pays LP tokens. This drains the same **$2,801,393.22**. The admin can also `unclaim(user,pid)` and replay an existing valid leaf, double-crediting a colluding user with the **existing** root (no root change needed).

### 6.4 PriceFeeds owner

Same 3-of-7 Safe. It can call `setStorkFeedsData` (which calls `farm.massUpdatePools()`) to change feed hashes/staleness, manipulate value weights if emissions are ever restarted, or set a feed type that reverts `getPrice` and freezes `massUpdatePools`/withdrawals. No current token theft (emissions ended), but a DoS/weight-manipulation lever.

### 6.5 L1 owner

3-of-5 Safe `0x3b18…9fcD`. The L1 implementation has no arbitrary-token rescue; it can `setL2Farm`, `setBridge`, `revertFailedBridge` (claim a failed bridge deposit), and `setEndBlock` (only before farming ended). All pools are bridged and L1 balances are ~0, so the L1 owner cannot sweep the 8.55M PEPE held for `PENDLE_EXCEPTION` (no rescue function). L1 P is therefore ~$0; the $33 is H-O for Pendle SY users.

**P quantification:** $2,801,393.22 (L2 assets), reachable by either the 2-of-6 farm owner or the 3-of-7 merkle/price-feed admin. Confidence high (contract-level authority simulated; the only assumption is that the Safe signers act).

---

## 7. H-O and S

### 7.1 H-O (user self-service)

- All 25 L2 pools' credited `depositAmount` is withdrawable until `endBlockForWithdrawals = 46,012,600` (**not yet ended**; current 29,675,399). A real depositor simulation succeeds (§5.1).
- 23 of the 24 pools with a non-zero LP token match `balanceOf(farm) == depositAmount` exactly; the single exception is PEPE (pid 9).
- L1: `PENDLE_EXCEPTION` (`0x065347C1…5246`) is the Sourcify-verified `PendleSophonFarmingSY` contract; its source calls `ISophonFarming(sophonFarming).withdraw(pid, amountSharesToRedeem)` in `_redeem`. It is the only address allowed to withdraw after the L1 withdrawal window; its 8,554,323.492929778385368410 PEPE is present in the L1 farm, and `withdraw(9, amount)` from that address simulates successfully. ~$33.06 H-O for Pendle SY users.

### 7.2 S (stuck / unrecoverable)

- **L2 PEPE shortfall:** farm PEPE balance 2,711,901,637.743620170306992171 vs `depositAmount` 2,734,206,348.092541326236759895 = **22,304,710.348921155929767724 PEPE** missing. At the DL-implied $3.865016498e-6/PEPE = **$86.21**. The last PEPE withdrawers cannot be repaid in full. This is the only material unrecoverable amount.
- **L1 dust:** 372.32 PEPE ($0.0014) above Pendle's claim and 100 BEAM ($0.29) left in the L1 farm after the BEAM pool was bridged. Withdrawals are closed, both pools are marked bridged, and there is no rescue function. **$0.29**.
- **L2 ZENT pool (pid 5):** `lpToken = 0`, amount 0, no value.
- No ETH or stray tokens: farm ETH balance 0; explorer balance list contains only the 24 pool LP tokens; `MerkleAirdrop` ETH and token balances 0.

**S total ≈ $86.50.**

---

## 8. PoC / model tests

`poc-src/` is a self-contained Foundry project (`forge test` runs locally; no RPC, no fork, no keys):

```
poc-src/src/RewardMathModel.sol   — line-for-line port of _updatePool/massUpdatePools/
                                    _settlePool/deposit/withdraw/updateUserInfo
poc-src/test/RewardMath.t.sol     — 6 tests
```

Result: **6 passed, 0 failed** (Solc 0.8.26, local run 2026-10-18).

| Test | Proves |
|---|---|
| `test_sameBlockSecondMassUpdateNoDoubleAccrual` | A second `massUpdatePools` in the same block rebuilds `totalValue` from `lastValue` and skips accrual; exactly one block of emission. No same-block double-mint. |
| `test_staleZeroAmountPoolDilutesActivePool` | A pool that withdraws to zero keeps `values[1] = pv.lastValue` and dilutes the active pool by 33% in the model (500e18 stale vs 1000e18 active). Latent bug, not triggered now (no zero-amount pool with non-zero lastValue). |
| `test_migrationBackdatedCredit` | `updateUserInfo` credits `claim.amount * acc / 1e18` retroactively, plus the leaf `rewardSettled` (100e18 + 5e18 at acc=1e18). Matches the deployed formula and the source comment. |
| `test_withdrawBoundedAndMaxNoop` | `withdraw` reverts above `depositAmount`; `max` with `depositAmount=0` is a zero-value no-op; no over-withdrawal. |
| `test_depositAfterFarmEndReverts` | `deposit` reverts after `endBlock`; the pre-check token transfer is unwound. |
| `test_updateUserInfoOnlyMerkle` | A non-MERKLE caller reverts `OnlyMerkle`. |

**Important caveat:** this is a **logic model**, not a fork of the deployed zkEVM bytecode. Foundry/revm cannot execute Sophon's zkEVM contracts. The live-state conclusions rely on `eth_call` against the deployed contract (which does execute) and on the verified source.

No Foundry fork test is possible for this chain with the local toolchain; the parent's CI would hit the same zkEVM limitation. The model tests are the correct substitute for the math, and the `eth_call` probes are the live proof.

---

## 9. Quantification

### 9.1 Reward token / reserve

| Item | Amount |
|---|---:|
| Reward token held by the farm | **0** (no reward token exists in the ABI; ETH balance 0; only LP tokens) |
| Accrued point liabilities | `pool.totalRewards` per pool (points, non-transferable, no on-chain redemption) |
| LP assets (priced) | **$2,801,393.22** |
| LP liabilities (priced `depositAmount`) | **$2,801,479.43** |
| Shortfall | **$86.21** (PEPE only) |

### 9.2 Maximum unprivileged extraction

| Scenario | Max extractable | Why |
|---|---:|---|
| New depositor, one block | **$0** | Deposits disabled (`isFarmingEnded`); even if enabled, no reward token and same-block points = 0. |
| New depositor, one reward period | **$0** | Points only; no on-chain redemption. |
| Flash loan / donation | **$0** | No share math; donations do not change `pool.amount`; flash deposit earns 0 for the block. |
| Claim path | **$0** | Requires a valid merkle leaf for the caller; credits only the leaf user. |
| Withdraw path | **$0** | Bounded by own `depositAmount`; no way to create it. |

Gas: `massUpdatePools` ≈ **1,590,780**; `withdraw(0,1)` ≈ **1,724,157** (including `massUpdatePools`) — `eth_estimateGas` at block 29,675,399 from a funded EOA. There is no revenue to net against it.

### 9.3 Category table

| Category | USD | Basis |
|---|---:|---|
| **E-U** | **0.00** | No unprivileged token-moving path. |
| **H-O** | **2,801,340.07** | L2 assets minus PEPE shortfall ($2,801,307.01) + L1 Pendle PEPE ($33.06). |
| **P** | **2,801,393.22** | Farm owner sweep / upgrade; merkle admin new root / `unclaim` replay. Overlaps H-O; not additive. |
| **S** | **86.50** | L2 PEPE shortfall $86.21 + L1 dust $0.29. |

Reconciliation: **H-O + S = $2,801,426.57 = total L1+L2 assets** ($2,801,393.22 L2 + $33.35 L1). P is the same L2 assets viewed through the owner's custody, so it is not additive.

---

## 10. Verdict and confidence

**Verdict: the farm is a standard (custom) points farm with correct 1:1 LP accounting. There is no unprivileged reward-math exploit and no reward token to drain. Live E-U = $0 (high confidence).**

What would change the verdict:
- A new implementation upgrade that adds a reward token, `compound`, or a public `updatePool` that transfers value (the owner can do this; P).
- A merkle root/claim change that lets a caller redirect a claim (currently the receiver is forced to the leaf user in the permissionless path).
- A price-feed update that restarts emissions with the stale `poolValue.lastValue` weights (latent; see §3.1/§8).
- Discovery of a valid merkle leaf for an address the attacker controls with a larger `depositAmount` than the tokens backing it (that would be a user-specific claim, not a general exploit).

**The material finding is P, not E-U:** the latest implementation added `_emergencyRescue`, so the 2-of-6 owner Safe can sweep all **$2.80M** of user LP deposits in one transaction; the 3-of-7 merkle admin Safe can mint a claim via a new root (or replay `unclaim`) and drain the same assets. This is a custody/centralization risk, not an external attack.

**S:** the PEPE pool is 22.30M PEPE ($86.21) short of its credited liabilities; the last PEPE withdrawers cannot be made whole. L1 dust is ~$0.29.

---

## 11. Methodology, sources, caveats

### Sources of truth
- Sophon explorer API (verified sources + balances): `https://api-explorer.sophon.xyz/address/<addr>`, `/api?module=contract&action=getsourcecode`, `/docs-json`.
- Sourcify v2 for Ethereum: `https://sourcify.dev/server/v2/contract/1/<addr>?fields=sources,metadata`.
- Live RPC: `https://rpc.sophon.xyz` (chain 50104), `https://ethereum-rpc.publicnode.com` (chain 1).
- DefiLlama: `https://api.llama.fi/protocol/sophon-farm` (TVL and token USD values).
- Local `cast` 1.8.5, `forge` 1.8.5.

### Caveats
- The farm is a zkEVM contract; Foundry cannot fork-execute it. The math tests are a source-level model. The live claims use `eth_call`/`eth_estimateGas` against the deployed contract, which does execute on the node.
- The verified source is authoritative for the implementation at `0xbd0a…6012`; the proxy's `implementation()` and the upgrade history were read on-chain. A future upgrade could change everything.
- The USD table uses DL-implied prices; DL's own TVL is $2,769,518 on Sophon + $33.34 on Ethereum (it excludes USDC/USDT and unpriced LP dust). The difference does not affect the verdict.
- The PEPE shortfall's exact provenance (which migration claim was unbacked) was not reconstructed; the on-chain asset-vs-liability gap is direct and sufficient for S.
- The L1 `PENDLE_EXCEPTION` is the Sourcify-verified `PendleSophonFarmingSY` contract, whose `_redeem` calls the farm's `withdraw`; the $33.06 is therefore H-O for Pendle SY users (subject to Pendle's own redemption liquidity).
- No key was written to any file. Etherscan V2 was rejected for chain 50104 and the local key was invalid for chain 1; Sourcify was used instead. All RPC URLs in this folder are keyless.

### File index (`evidence/`)
- `SophonFarmingProxy.sol`, `src_contracts__farm__SophonFarmingL2.sol`, `src_contracts__farm__SophonFarmingState.sol`, `src_contracts__airdrop__MerkleAirdrop.sol`, `src_contracts__farm__PriceFeeds.sol` — verified sources.
- `l1_contracts__farm__SophonFarming.sol` — L1 source.
- `impl-5c45.sol`, `impl-6642.sol`, `impl-df5e.sol` — prior L2 implementations.
- `poolinfo-pinned.json`, `pools_parsed.json`, `farm-address.json`, `live-state-table.json` — pool state and balances.
- `impl-abi.json`, `merkle-impl-abi.json`, `openapi.json` — ABIs and explorer API.
- `proxy-upgrades.json`, `role-granted.json`, `role-revoked.json`, `root-updated.json`, `merkle-logs.json`, `pu2-*.json` — authority and history.
- `llama-sophon-farm.json` — DL TVL.
- `poc-src/` — Foundry model (6/6 PASS).
- `summary.json` (in the parent folder) — machine-readable summary.
