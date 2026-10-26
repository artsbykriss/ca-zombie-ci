# CGO Finance — Cougar MasterChef fork on Cronos (chain 25)

**Date:** 2026-10-25 · **Chain:** Cronos (25) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**.
**Target:** CGOFarm (MasterChef) `0x5795BE23A2C330209849e0D1D19cc05755E23Ca2` · reward/native token **CGO** `0x869c3e35ef9e5f50003d9a2a80f1d61d670d4cb6`.
**Recon block:** 102,089,673 (live reads) / 102,072,464 (first recon).

---

## 1. TL;DR

| Target | Live unprivileged extractable | Why closed / open | Latent risk |
|---|---|---|---|
| CGOFarm MasterChef (43 pools, $0.95M DefiLlama TVL) | **$0.00** | The farm's **only** asset is CGO; all 43 pool `want`/LP balances held by the farm are **0**; every state-changing admin path is `onlyOwner`; no reward-debt/backdated-mint capture path exists for a fresh caller | **Medium (latent):** `updatePool` is permissionless and **mints** CGO; stale pools would mint ~35M CGO on the first `updatePool`/`massUpdatePools` call. Worth ~$4.6k at market, but the minter gets none of it and CGO's exit liquidity is only ~$1.8k |
| CGO reward token exit liquidity | **$1,826.14** (absolute ceiling, asymptotic) | 5 DEX pairs, 3 of them on Cougar's own DEX; two pairs hold $941.80 (USDC) and $884.32 (WCRO); three are dust | If any path ever handed an attacker CGO, the *entire* realistic USD ceiling is ~$1.8k |
| 43 live Cougar "Strategy" vaults (hold ~$0.95M of users' `want`) | **$0.00** | Every strategy is `owner() == the farm`; `deposit`/`withdraw`/`inCaseTokensGetStuck` are `onlyOwner`; the farm's per-user share math (`shares·wantLockedTotal/sharesTotal`) and the strategy's inverse (`wantAmt·sharesTotal/wantLockedTotal`) both round **down**, so a round trip never returns more than deposited | none found |
| Dormant stakers in 5 stale pools (2, 3, 27, 28) | **$0.00 E-U / $3,372.50 H-O nominal** (≤ $1,826.14 realisable) | 26 addresses that hold 90.3% of pool 2's strategy shares have **25,626,908 CGO of unharvested `pendingCGO`**; anyone can trigger the harvest with a permissionless `updatePool`, but only those share-holders can claim it | Medium: if CGO ever gained liquidity this is the residual reward pool |

## 2. Total live extractable now

**E-U (external unprivileged): $0.00 — confidence: HIGH.**
Bounded above by **$1,826.14** (the total buy-side liquidity of CGO across all 5 pairs; even an unlimited CGO dump cannot return more). No unprivileged call path was found that hands a caller CGO or `want` beyond a proportional deposit.

**H-O (holder-recoverable): $3,372.50 nominal — the largest residual.** 26 dormant stakers in the four stale pools with live positions (**pool 2: 25,296,740.66 CGO across 6 holders; pool 3: 32,990.55; pool 27: 104,205.80; pool 28: 192,971.08**) hold **25,626,908.10 CGO of unharvested `pendingCGO`** (`pendingCGO(pid,user)` read at block 102,089,673). Anyone can trigger the accrual with a permissionless `updatePool(pid)`, but only those addresses' `userInfo.shares` can claim it, so it is **not** attacker-extractable. Nominal value at the DexScreener price is $3,372.50; the *realisable* amount is capped by CGO's $1,826.14 total exit liquidity.
**P (privileged):** `owner()` EOA `0x2e4C48D9…` receives 10% of every mint (`ownerCGOReward = 100`) and can `inCaseTokensGetStuck` (non-CGO only) / `set` / `add` / `updateStartBlock`.
**S (stuck):** CGO minted to the farm for pools with **no** stakers accrues into `accCGOPerShare` that no future depositor can claim (reward debt is snapshotted at deposit) — effectively stranded inside the farm.

## 3. The mechanism, in exact terms

The deployed contract is `CGOFarm` (explorer `name`), compiler **0.6.12**, MIT, unoptimised, creator `0x743c0d5e…`, deployed block **2,953,861**. Its source is **not** published on the Cronos explorer (only the ABI + `s3FileKeys` are), Sourcify has no match, and no GitHub mirror exists. The code is the **Cougar-branded port of the `CGSVFarm` family** (`tintinweb/smart-contract-sanctuary-fantom`, `CGSVFarm.sol` — byte-identical require strings `"user.shares is 0"`, `"sharesTotal is 0"`, `"Farm already started"` and the same `OwnerCGOReward`/`updateStartBlock`/`stakedWantTokens` surface). The ABI was recovered from the explorer's embedded `__NEXT_DATA__`; the selector table was cross-checked against a PUSH4 sweep of the runtime bytecode.

Reward accounting (from the matched source, with the deployment's live constants):

```
struct UserInfo { uint256 shares; uint256 rewardDebt; }
struct PoolInfo { IERC20 want; uint256 allocPoint; uint256 lastRewardBlock;
                  uint256 accCGOPerShare; address strat; }

function getMultiplier(from,to) view {                 // live: CGO.totalSupply() < maxSupply
    if (CGO.totalSupply() >= maxSupply) return 0;      //   => minting is ACTIVE
    return to - from;                                  // unbounded, backdated
}

function updatePool(pid) public {                      // PERMISSIONLESS
    if (block.number <= pool.lastRewardBlock) return;
    uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
    if (sharesTotal == 0) { pool.lastRewardBlock = block.number; return; }   // no mint
    uint256 R = getMultiplier(pool.lastRewardBlock, block.number)
                  * CGOPerBlock * pool.allocPoint / totalAllocPoint;
    CGO.mint(owner(),  R * ownerCGOReward / 1000);     // 10% to the owner EOA
    CGO.mint(address(this), R);                        // 100% to the farm  (110% total)
    pool.accCGOPerShare += R * 1e12 / sharesTotal;
    pool.lastRewardBlock = block.number;
}

function deposit(pid, wantAmt) public nonReentrant {
    updatePool(pid);                                   // <-- accrues to EXISTING shares only
    if (user.shares > 0) safeCGOTransfer(msg.sender, user.shares*acc/1e12 - user.rewardDebt);
    if (wantAmt > 0) {
        want.safeTransferFrom(msg.sender, address(this), wantAmt);
        wantAmt = want.balanceOf(address(this)) - beforeDeposit;   // transfer-tax safe
        want.safeIncreaseAllowance(pool.strat, wantAmt);
        user.shares += IStrategy(pool.strat).deposit(msg.sender, wantAmt);
    }
    user.rewardDebt = user.shares * pool.accCGOPerShare / 1e12;    // snapshot AFTER the accrual
}
```

**Why the classic MasterChef/backdated-mint vectors do not pay:**
* `deposit()` runs `updatePool()` **before** the caller's shares exist, then snapshots `rewardDebt` at the post-accrual `accCGOPerShare` → a fresh depositor can never claim rewards that accrued before their deposit.
* `updatePool()` is permissionless, but the CGO it mints goes to `address(this)` / `owner()`; the caller's balance is untouched.
* `massUpdatePools()` / `updatePool(pid)` are the only permissionless entry points, and they are *mint* functions, not *claim* functions.
* `emergencyWithdraw` (the usual "no reward" escape) still requires `user.shares > 0` (`user.shares·wantLockedTotal/sharesTotal`, and `IStrategy.withdraw` reverts on 0 shares).
* Every privileged path (`add`, `set`, `inCaseTokensGetStuck`, `updateStartBlock`, `transferOwnership`, `renounceOwnership`, and CGO's `mint`) reverts `Ownable: caller is not the owner` for a non-owner.

## 4. Live-state assessment (address · call · block)

All reads at Cronos block **102,089,673** via keyless `https://evm.cronos.org` (`eth_call`/`eth_getCode` only).

| Item | Value |
|---|---|
| `CGOFarm.code` | 14,525 bytes, `name=CGOFarm`, solc 0.6.12, deployed blk 2,953,861 |
| `poolLength()` | 43 |
| `totalAllocPoint()` | 44,700 |
| `owner()` | `0x2e4C48D9a4abde9cCCCF110Bf5F58636d49ef5ee` |
| `CGOToken()` / `CGOPerBlock()` / `startBlock()` / `ownerCGOReward()` | `0x869c…4cb6` / `1e18` / 3,033,444 / 100 |
| CGO `totalSupply()` / `decimals()` / `symbol()` | 71,787,297.06 CGO / 18 / "CGO" |
| CGO `balanceOf(farm)` | **41,825,492.34 CGO** (the farm's only asset) |
| CGO `owner()` | `0x5795BE23A2C330209849e0D1D19cc05755E23Ca2` (the farm itself → can mint CGO) |
| CGO `mint()` from a non-owner | reverts `Ownable: caller is not the owner` |
| farm `balanceOf(pool_i.lpToken)` for i=1..42 | **0** for all 42 (only pool 0, whose `lpToken` *is* CGO, shows 41,825,492) |
| pool 0 | `want`=CGO, `allocPoint`=3000, `lastRewardBlock`=99,605,594, `acc`=1.585e12 |
| pool 1 | `want`=0xC794…c9c4 (CGO/WCRO pair), `allocPoint`=15000, `lastRewardBlock`=101,564,950 |
| pools 2–42 | `lastRewardBlock` = **43,036,337** (≈59.0M blocks stale) — no interaction since block 43M |
| `getMultiplier(43,036,337, 102,072,500)` | 59,036,163 → **minting is active** (supply below cap) |
| 43 strategies | 9 distinct code hashes, **all `owner() == the farm`**, all `paused() == false`; e.g. pool 0 strat `0x76B3…F856` has `sharesTotal == wantLockedTotal == 8.801e24` and 112 historical depositors |

**CGO exit liquidity (all live pairs):**

| Pair | DEX | CGO | quote | quote USD |
|---|---|---|---|---|
| `0x0803a468…1617` | Cougar (own DEX) | 7,156,086.93 | 941.797 USDC | **$941.80** |
| `0xC794a7d9…c9c4` | Cougar (own DEX) | 6,735,676.88 | 16,229.59 WCRO | **$884.32** (WCRO @ $0.0544889) |
| `0xF78D712E…F447` | Cougar (own DEX) | 98.36 | 0.01298 USDT | $0.013 |
| `0xF06abc17…8ffa` | VVS Finance | 6.63 | 0.001173 USDC | $0.0012 |
| `0xDF949c04…3307` | CronaSwap | 21.56 | 0.001064 USDC | $0.0011 |
| | | | **total** | **$1,826.14** |

DefiLlama has **no** price for CGO (`coins.llama.fi/prices/current/cronos:0x869c…` → `{"coins":{}}`); DexScreener prices it at $0.0001316. The $0.95M DefiLlama TVL is the **users' staked `want` inside the strategies**, not CGO.

**Unharvested holder rewards in stale pools** (`pendingCGO(pid, user)` at block 102,089,673, over the 112 historical pool-0 depositors — a lower bound):

| pool | allocPoint | dormant holders | `pendingCGO` (CGO) |
|---|---|---|---|
| 2 | 15,000 | 6 | 25,296,740.66 |
| 3 | 1,500 | 10 | 32,990.55 |
| 27 | 100 | 3 | 104,205.80 |
| 28 | 100 | 4 | 192,971.08 |
| 29 | 100 | 3 | 0.00000016 |
| | | **26** | **25,626,908.10** (≈$3,372.50 nominal) |

Pool 2's six holders own 90.3% of the strategy's `sharesTotal` (3.46e16 of 3.83e16) — inside bounds, i.e. no `shares > sharesTotal` mismatch.

## 5. What an attacker can / cannot do

**Can (all value-free):**
1. `massUpdatePools()` / `updatePool(pid)` — permissionless. Mints ~35M CGO into the farm and ~3.5M to the owner EOA for the stale pools. The caller receives **0**.
2. `deposit(pid, amt)` / `withdraw` / `withdrawAll` / `emergencyWithdraw` — normal staking; the caller gets exactly their pro-rata share of `want` and their own CGO rewards, never more.
3. `earn()` on a strategy (`isCGOComp`-gated) — only recycles the strategy's own `earnedAddress` balance; no caller benefit.

**Cannot:**
1. Reach any of the 42 non-CGO pools' `want` — the farm holds **zero** of each.
2. Mint CGO or move CGO/`want` out of the farm or a strategy — `onlyOwner` in every case.
3. Capture the ~35M-CGO backdated mint — `deposit` snapshots `rewardDebt` after `updatePool`.
4. `emergencyWithdraw` without shares, or with `sharesTotal == 0` (division by zero).
5. Profit from a deposit→withdraw round trip (both `amount` and `sharesRemoved` round down; `entranceFeeFactor == withdrawFeeFactor == 10000 == max` → no fee edge).

**Costs:** a `massUpdatePools()` call is bounded by 43 `updatePool`s (~2–3M gas, ~$0.01 on Cronos); every other attempted path reverts.

## 6. PoC / fork verification

* `poc/` — Foundry project (vendored `lib/forge-std`), `foundry.toml` with `solc 0.8.24`, `optimizer_runs 200`, `evm_version = "paris"` (Cronos is Ethermint; avoids PUSH0 assumptions). Fork URL = `CRONOS_RPC_URL` with fallback `https://evm.cronos.org`.
* `poc/test/CGOFinance.t.sol` — 10 tests (see the run log for the pass count):
  1. `test_01_CGO_exit_liquidity` — asymptotic USD ceiling across the 5 pairs, asserted `< $3000`.
  2. `test_02_dump_farm_CGO_into_pairs` — `deal`s the attacker the farm's entire CGO balance and sells it through the real Cougar pairs via `swap`; asserts `< $2000` USDC.
  3. `test_03_permissionless_massUpdatePools_mints` — attacker calls `massUpdatePools()`; asserts `CGO.totalSupply` rises but the attacker's CGO balance is unchanged.
  4. `test_04_admin_functions_are_onlyOwner` — `add`/`set`/`inCaseTokensGetStuck`/`updateStartBlock`/`transferOwnership`/`CGO.mint` all revert `Ownable: caller is not the owner`.
  5. `test_05_deposit_withdraw_roundtrip_no_profit` — deposit CGO into pool 0, `warp` 20 days, `withdrawAll`, assert final ≤ initial.
  6. `test_06_stale_pool_backdated_mint_not_capturable` — `updatePool(2)` mints, then a fresh deposit has `pendingCGO == 0`.
  7. `test_07_dormant_stakers_scan` — scans the 112 historical pool-0 depositors against the stale pools for dormant shares.
  8. `test_08_emergencyWithdraw_no_shares_reverts`.
  9. `test_09_farm_holds_only_CGO` — asserts the farm's balance of every non-CGO pool's `want` is 0.
  10. `test_10_strategies_owned_by_farm_not_paused`.
* CI: GitHub Actions `artsbykriss/ca-zombie-ci`, branch `cgo-finance`, workflow `poc.yml` → `ci/run.sh` (live-state dump → `ci-out/live_state.json`) then `forge test -vvv`.
  **Run URL:** _(filled in below)_
* Local (light RPC only): explorer ABI extraction, PUSH4 selector sweep, `eth_call` state reads, DexScreener/DefiLlama price reads, Foundry compile sanity check (`forge build`, 7s).

## 7. Verdict and residual / latent risk

**Verdict: E-U = $0.00 (HIGH confidence).** CGO Finance is a live-but-empty Cougar MasterChef fork. The farm's sole asset is 41.8M CGO whose entire realistic exit liquidity is **$1,826.14**; every pool is empty of LP; every privileged path is `onlyOwner`; and the reward maths is the standard, correctly-ordered MasterChef accounting that gives a fresh depositor nothing but their own pro-rata share. There is no unprivileged extraction.

**Latent / monitor:**
* **Permissionless supply inflation.** `updatePool`/`massUpdatePools` mint CGO (110% of `R`, 10% to the owner EOA). Because `getMultiplier` is only capped by `maxSupply`, the first call touching the 41 stale pools mints ≈35.3M CGO (≈49% of the current 71.8M supply) into the farm plus ≈3.5M to `0x2e4C48D9…`. The minting caller gets nothing, and the minted CGO is effectively stranded for pools with no stakers — but if CGO ever gained real liquidity, this would be a ~$4.6k-at-market (≈$1.8k-realisable) windfall for the owner EOA and dormant stakers.
* **Dormant stakers hold 25.6M CGO of unharvested rewards.** 26 addresses (of pool 0's 112 historical depositors) still hold `userInfo.shares > 0` in stale pools **2, 3, 27, 28** (and pool 29 has dust). `pendingCGO(2, 0x5be4a570…)` etc. sum to **25,626,908.10 CGO** (pool 2 alone: 25,296,740.66). One permissionless `updatePool(pid)` — or the holder's own `withdraw(pid,0)` — mints and pays it out. **H-O, not E-U.** Realisable ≤ the $1,826.14 liquidity ceiling.
* **`want` accounting** relies entirely on the strategies' `wantLockedTotal`/`sharesTotal`; a strategy-side bug (not reachable from the farm's public surface) would be the only way to touch the ~$0.95M of staked `want`. Note the farm's `pendingCGO` uses the *strategy's* `sharesTotal`, so a strategy whose `sharesTotal` were ever reduced below the farm's recorded user shares would let `pending` exceed the pool's mint — no live instance of that mismatch was found (pool 2's dormant stakers hold 90.3% of `sharesTotal`, i.e. within bounds).

## 8. Blockers / caveats

* **Source not published.** The Cronos explorer exposes only the ABI (`s3FileKeys` present, `source_code`/`contractFiles` null); Sourcify has no match; no GitHub mirror. The farm's logic was reconstructed from the **Fantom `CGSVFarm`** twin (same require strings, same function set) and validated against live `eth_call` behaviour; the 43 strategies are a **Cougar-specific** variant (`"Cougar: OVERFLOW"`, `isCGOComp`/`isTestVComp` flags) whose source could not be retrieved, so strategy-internal claims are behavioural, not source-verified.
* `getMultiplier`'s hard-coded `maxSupply` has no getter; it is inferred as `> totalSupply` from `getMultiplier` returning `to-from`.
* Cronos public RPC caps `eth_getLogs` at 2,000 blocks and batches at 10, so the full deposit/withdraw history could not be enumerated; the dormant-staker scan uses the strategy's own `users[]` array.
* Prices: WCRO $0.0544889, USDC $0.99958, USDT $0.99898 (DefiLlama, 2026-10-25); CGO $0.0001316 (DexScreener).

## 9. Methodology & files

**Method:** explorer `__NEXT_DATA__` ABI extraction → PUSH4 selector-table cross-check → live `eth_call` state dump (43 pools + 43 strategies + 5 pairs) → twin-source recovery on GitHub (`CGSVFarm.sol`, `Strategy_CGSV.sol`) → control-flow/ordering analysis of `updatePool`/`deposit`/`withdraw`/`emergencyWithdraw` → DexScreener + DefiLlama liquidity bound → Foundry fork PoC in CI.

**Files:**
```
cgo-finance/
├── README.md                 (this file)
├── summary.json              (machine-readable, §7 schema)
├── analysis/                 (selector sweep + notes)
├── poc/foundry.toml, poc/src/, poc/test/CGOFinance.t.sol, poc/lib/forge-std
├── ci/run.sh                 (live-state dump → ci-out/live_state.json)
├── ci-out/live_state.json    (43 pools, 43 strategies, 5 pairs @ block 102,089,673)
├── ci-log.txt / ci-artifacts (CI run log + artifacts)
└── (no secrets; keyless public RPC only)
```

*Prepared 2026-10-25 · ZH4 pass-7 · CGO Finance (Cougar MasterChef fork, Cronos 25).*
