# ZH4-02 follow-up — Can the Startale Earn JIT capture be atomicized with a flash loan?

**Verdict: NO — an unprivileged attacker cannot execute the JIT cycle with a flash loan.**
The binding constraint is **role gating**, not loan liquidity: both keeper functions are `onlyRole(OPERATOR_ROLE)` on the RewardRedistributor, and the EarnVault's `onYield` is `onlyYieldRedistributor`. The sole `OPERATOR_ROLE` member is the keeper EOA `0x86bE…333C`. A single-transaction flashloan → `deposit()` → `snapshotVaultTVLs()` → `distribute()` → `withdraw()` → repay **reverts at the first gated call** with `AccessControlUnauthorizedAccount(attacker, OPERATOR_ROLE)`. The real keeper calls are also separated by the `MustSnapshotInPreviousBlocks` guard (snapshot in block N, distribution in N+2 in 21/22 fresh epochs), so even a privileged keeper cannot snapshot and distribute in the same transaction.

**Confidence: high.** On-chain role reads, exact `eth_call` reverts, and a 7/7 fork suite including a real $2M Uniswap v4 flash loan.

---

## 1. Keeper-call gating — exact live evidence

Reads at block **29,599,442** (2026-10-18 ~14:26 UTC; impl and roles unchanged):

| Call | Caller | Result |
|---|---|---|
| `RewardRedistributor.snapshotVaultTVLs()` | random `0x…dEaD` | **revert** `AccessControlUnauthorizedAccount(0x…dEaD, 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929)` (selector `0xe2517d3f`) |
| `RewardRedistributor.distribute()` | random `0x…dEaD` | **same revert** |
| `EarnVault.onYield(uint256)` | random `0x…dEaD` | **revert** `NotYieldRedistributor()` (selector `0xdea199ff`) |
| `getRoleMemberCount(OPERATOR_ROLE)` | — | **1** |
| `getRoleMembers(OPERATOR_ROLE)` | — | **`[0x86bE13a26d548FA5407Ee3E5a8321B4E1019333C]`** (keeper EOA) |
| `DEFAULT_ADMIN_ROLE` | — | `[0x3C27038D9906caa5D68355B1800625EAcaCd93dA]` (SafeL2) |

The `onlyRole` modifier runs **before** `_validateSnapShotAge`, so even a stale snapshot does not change the error (we observe the AccessControl revert, not `SnapshotTooOld`).

**Timing guards (deployed source):**
- `snapshotVaultTVLs()` — `onlyRole(OPERATOR_ROLE) whenNotPaused`; **no epoch interval / rate limit**.
- `distribute()` — `whenNotPaused onlyRole(OPERATOR_ROLE) nonReentrant`, then `_validateYieldRecipient()` and `_validateSnapShotAge()`:
  - `lastSnapshotTimestamp == 0` / `lastSnapshotBlockNumber == 0` → `LastSnapshotInvalid()`;
  - `block.number - lastSnapshotBlockNumber < 1` → **`MustSnapshotInPreviousBlocks(last, now)`**;
  - `block.timestamp - lastSnapshotTimestamp > snapshotMaxAge (300 s)` → `SnapshotTooOld(...)`.
- No double-distribution guard is needed: a second `distribute()` against the same snapshot calls `claimYield()` again; if it mints 0, the function returns early. It cannot be called unprivileged anyway.
- `EarnVault.onYield()` — `onlyYieldRedistributor` (hard-coded to the RR); `withdraw()` / `deposit()` are permissionless but cannot trigger accrual.

**Fresh epoch cadence:** 22 epochs scanned; snapshot at HH:00:05–:19, distribution at HH:00:09–:27; the distribution block is **2 blocks / 4 s** after the snapshot in **21/22** epochs (one 5-block / 10 s outlier). The two calls are therefore always in **different blocks**, even for the keeper.

---

## 2. Atomicity test — a real flash loan cannot rescue the cycle

`poc/test/StartaleFlashloan.t.sol` (Soneium mainnet fork, block **29,573,086**; 7/7 PASS):

| Test | Result |
|---|---|
| `test_P5a_snapshot_is_keeper_gated` | PASS — exact `AccessControlUnauthorizedAccount` |
| `test_P5b_distribute_is_keeper_gated` | PASS — exact `AccessControlUnauthorizedAccount` |
| `test_P5c_onYield_is_rr_only` | PASS — exact `NotYieldRedistributor` |
| `test_P5_same_block_snapshot_then_distribute_reverts` | PASS — reverts `MustSnapshotInPreviousBlocks`; a next-block `distribute()` succeeds |
| `test_P6_v4_flashloan_1M_works` | PASS — $1M USDSC flash-borrowed and repaid in one tx; PoolManager balance unchanged |
| `test_P6_v4_flashloan_2M_works` | PASS — $2M same-tx flash loan; PoolManager depth $2,252,926.68 at the pinned block |
| `test_P5_atomic_flashloan_cycle_reverts_at_keeper_gate` | PASS — real v4 flash loan → `deposit($1M)` → `snapshotVaultTVLs()` **reverts**; the whole tx (loan, deposit) rolls back; PoolManager and vault state unchanged |

The atomic contract is `V4FlashBorrower` in the test file: it calls `PoolManager.unlock()`, `take(USDSC, …, amount)`, deposits into the EarnVault, then attempts the keeper sequence. The revert is at `snapshotVaultTVLs()`; `distribute()` and `withdraw()` are unreachable. The flash-loan round trip costs **87,965 gas**, i.e. **≈$0.0005** at Soneium's 2.3e6 wei/gas (no protocol fee).

This is the decisive result: **flash liquidity is available, but the atomic call path is impossible**. A flash loan cannot span the two blocks between the keeper's snapshot and distribution; it must be repaid before the transaction ends, so the deposit would have to be withdrawn before the snapshot, forfeiting the capture.

---

## 3. Actual USDSC flash-loan liquidity on Soneium

| Source | USDSC depth | Mechanism | Max same-tx | Fee |
|---|---|---|---|---|
| **Uniswap v4 PoolManager** `0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32` | **$2,252,926.68** at fork block; **$2,252,349.52** at latest | `unlock`/`take`/`sync`/`settle` (Flash Accounting) | **≈$2.25M** | **0** (gas only) |
| Uniswap v3 USDSC/USDC.e 0.01% `0x680bfCbFa2C2DBeD8B25b94cC73C15EA338F5F38` | $134,894.81 | `flash()` | ≈$135k | 0.01% |
| Uniswap v3 USDSC/USDC.e 0.30% `0x6DadCA156f510E4A87301aB9f926DC8fFB46EC73` | $125,101 | `flash()` | ≈$125k | 0.30% |
| Aave v3 Soneium | **no USDSC reserve** | `flashLoan` | 0 | — |
| Morpho Soneium | TVL ≈$30.7k total; **no USDSC market found** | `flashLoan` | 0 | — |
| Kyo / Velodrome Slipstream / Sonex | no USDSC pool > $1M; no documented flash facility relied on | — | <$1M | — |

- Aave v3 Soneium lists **WETH, USDC.e, USDT** (the market is being deprecated/frozen); USDSC is not a reserve.
- Morpho Soneium has only ~$30.7k total TVL and no observed USDSC market.
- The only **$1M+** same-transaction source is Uniswap v4. A **$2M** loan was executed on the fork; the **full $3.62M float is not flash-loanable from on-chain sources** (v4 ≈$2.25M + v3 ≈$0.26M < $3.62M), but that is moot because the keeper gate already blocks the atomic cycle.
- No standard **multi-block “flash” loan** exists trustlessly. Any substitute is a collateralized loan: the attacker must post collateral, borrow USDSC (no USDSC market found) or borrow USDC.e and swap to USDSC twice, hold through the 2-block window, and pay interest + swap fees. That is **own/collateralized capital**, not zero-upfront.

---

## 4. Minimal capital without a flash loan

- **Protocol minimum:** none — `deposit()` only rejects `amount == 0`; 1 unit (1e-6 USDSC) is accepted.
- **Gas break-even:** at ~$0.0017/epoch and a capture rate of 1.139e-5 per epoch, ~**$150** of capital covers gas. Technically, any non-zero amount captures pro-rata.
- **Practical size:** $1M earns **$92.12/day**; $3.5M earns **$322.43/day**; the full float (~$3.62M) ≈$333/day. The capital must be held across the **2-block / 4 s** keeper gap (or up to 5 blocks / 10 s in the outlier). Own USDSC or a collateralized cross-block loan is required.
- **Privileged-only atomic variant:** a compromised keeper key (or a role grant to an attacker contract) could pre-snapshot in block N-1 and then run flashloan → deposit → `distribute()` → `withdraw()` → repay atomically in block N, netting ~$11.5/$1M per epoch minus ~$0.002 gas. That is **P**, not E-U; no role compromise is observed.

---

## 5. Conclusion

| Question | Answer |
|---|---|
| **Flashloan-feasible for an unprivileged attacker?** | **NO** |
| **Binding constraint** | `snapshotVaultTVLs()` and `distribute()` are `onlyRole(OPERATOR_ROLE)`, sole member = keeper EOA; `onYield` is RR-only. The atomic cycle reverts with `AccessControlUnauthorizedAccount` before any capture. |
| **Secondary constraint** | `MustSnapshotInPreviousBlocks` forces snapshot and distribution into different blocks; the real keeper gap is 2 blocks / 4 s (21/22 epochs). |
| **Loan liquidity** | Not binding: Uniswap v4 can lend $2.25M USDSC same-tx at zero protocol fee ($1M and $2M fork-proven). |
| **Minimal capital** | No protocol minimum (1 unit); gas break-even ~$150; meaningful scale $1M–$3.62M of own/collateralized USDSC. |
| **Confidence** | **High** — live role reverts + codehash-matched source + 7/7 fork tests with a real v4 flash loan. |

**What would change the verdict:** granting `OPERATOR_ROLE` to a permissionless/public contract; making `distribute()` permissionless and removing `MustSnapshotInPreviousBlocks`; or a keeper-side public proxy that accepts an attacker-supplied deposit and distribute in one call. None exists today.

**Files:** `poc/test/StartaleFlashloan.t.sol`, `analysis/flashloan_evidence.txt`, `analysis/flashloan_poc_local.log`; main report `README.md`, `summary.json`.
