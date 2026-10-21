# Hyperbeat (HyperEVM) — ether.fi-lineage withdraw manager, share/queue accounting

**Date:** 2026-10-21 · **Chain:** HyperEVM (999), block **49,145,310** · **TVL:** 155,682.42 HYPE ≈ **$12,689,673.77** (HYPE $81.51, CoinGecko 2026-10-21)
**Status:** read-only; Foundry fork tests only (no transactions signed or sent). No secrets in this folder.

---

## 1. TL;DR

| Surface | Live extractable (unprivileged) | Why closed | Residual |
|---|---|---|---|
| `WithdrawManager` queue / claims | **$0** | `finalizeWithdrawals` is `PROTOCOL_ADMIN`-only; `claimWithdrawal` pays `entry.user` (fixed at request time) and sets `claimed=true` before the transfer; a double claim reverts. The manager holds **exactly** the 217 finalized-but-unclaimed liabilities (1,621.905798325016362542 HYPE), so there is no surplus and no shortfall. | none found |
| Instant withdrawal | **$0** | roundtrip 100 HYPE → 99.6999… HYPE (30 bps fee); the fee and the rate-limit bucket are debited before the payout | griefing the global rate-limit bucket (cost 30 bps) |
| Stale-ratio (JIT) yield capture | **$0 net** | The stored `exchangeRatio` is **5.68e-5 (0.0057 %)** below live NAV/share right now (≈1 day un-poked). That is **8.84 HYPE ≈ $720.52** of yield for the *whole* holder base. Instant exit costs 30 bps; the queue path locks capital 3–7 days. Break-even needs ~**51 days** of accrual. | if ratio updates become infrequent (>51 days), a flash-loan JIT becomes profitable |
| Critical 2025 audit finding (finalization DoS) | fixed | pull-pattern: HYPE is sent to the manager, not to each user; a reverting `receive()` can no longer block the queue (fork test) | none |

**Total live extractable now: $0 (E-U).** Confidence: **high**.

---

## 2. Deployed system (all reads at block 49,145,310)

| Contract | Proxy | Implementation | Notes |
|---|---|---|---|
| WithdrawManager | `0x9d0B0877b9f2204CF414Ca7862E4f03506822538` | `0xd7e4B8aC588591a75e3B977ebd19563DDB629353` | UUPS, EIP-1967 slot verified |
| StakingCore | `0xCeaD893b162D38e714D82d06a7fe0b0dc3c38E0b` | `0xB829b6f905eadc9d9E08a1f54F190d83C7A6F370` | UUPS |
| beHYPE | `0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9` | `0x91F5D2531cbC9Db03887589536F6DD28f432e978` | UUPS, 18 dp, "hyperbeat x ether.fi HYPE" |
| RoleRegistry | `0x90102473a816A01A9fB0809F2289438B2e294F76` | `0x96a7b5e92f21ff7adfac333453eb10b96ea8acca` | owner/upgrader = `0xA24aF73E…2DE4` (OZ TimelockController, `getMinDelay()` = **1800 s**) |

Live parameters: `instantWithdrawalFeeInBps` **30**, `lowWatermarkInBpsOfTvl` **100**, `exchangeRateGuard` **true**,
`acceptablAprInBps` **500**, `minWithdrawalAmount` 0.1 HYPE, `maxWithdrawalAmount` 100,000 HYPE,
`paused` **false**, `hypeRequestedForWithdraw` **632.481469192585276309 HYPE**, `lastFinalizedIndex` **5590**,
pending queue **13**.

`PROTOCOL_ADMIN` = `0xb700d555…33Ef`, `0xe15f1788…f758`; `PROTOCOL_GUARDIAN` = `0x2fC76670…1e7C`;
`protocolTreasury` = `0xc4bdD45F…bbf3`.

---

## 3. Source identity and the ether.fi lineage (mandate item)

The deployed implementation sources were pulled from Etherscan V2 (chain 999) and diffed against the upstream
reference repo `etherfi-protocol/beHYPE` @ `06ee135` (2026-03-29):

```
diff src/WithdrawManager.sol   -> (empty)
diff src/StakingCore.sol       -> (empty)
diff src/BeHYPE.sol            -> (empty)
diff src/RoleRegistry.sol      -> (empty)
```

**The deployed code is byte-identical to the upstream audited reference.** The repo ships four audit reports
(`audit/Certora EtherFi BeHYPE Audit.pdf`, `NM_0628-FINAL_HYPERBEAT.pdf`, `EtherFi_-_Bundle_9.pdf`,
`beHYPE-oft-contracts.pdf`), so DefiLlama's `audits=0` label is a data gap, not an absence.

**Lineage risk assessment.** ether.fi Liquid was exploited on 2026-09-11 for 15.45 ETH (~$43,260) via
"Arbitrary External Call" in its **legacy `AtomicQueue`** (a solver/fulfiller contract that forwards
user-supplied `callData`). The beHYPE codebase has **no `AtomicQueue`, no solver, no arbitrary-target call**:
a grep for `.call`/`execute`/`sweep`/`rescue` over `src/` yields only (i) `claimWithdrawal`'s
`payable(entry.user).call{value:…}` where `entry.user` was fixed by the depositor, (ii)
`StakingCore.sendFromWithdrawManager`'s `payable(to).call`, where `to` is only ever `msg.sender` (requested by the
withdrawer) or the manager itself, and (iii) the hard-coded HyperCore L1 contract. **The exploited component is
not part of this codebase.**

---

## 4. Accounting analysis (share / withdraw / queue)

### 4.1 NAV and the stored ratio

`getTotalProtocolHype()` = HyperCore `delegated` + `undelegated` + `totalPendingWithdrawal` + spot `HYPE` balance
+ `address(stakingCore).balance`. Live decomposition:

| Bucket | HYPE |
|---|---|
| delegated | 147,759.98986656 |
| undelegated | 93.29457606 |
| totalPendingWithdrawal | 996.68380321 |
| HyperCore spot (token 150) | 185.02354439 |
| EVM balance of StakingCore | 6,647.424679493166186119 |
| **NAV** | **155,682.416469713166186119** |

beHYPE supply = **152,174.254757123986133928** → NAV/share = **1.023053582343401925**.
Stored `exchangeRatio` = **1.022995496666924603** → the ratio is **5.68e-5 (0.0057 %)** **below** NAV/share.
That gap is one un-poked accrual period; it is the only economic asymmetry in the system and it is quantified in §6.

### 4.2 Queue is exactly funded

- Queued (pending, ids 5591–5603): **13 entries, 632.481469192585276309 HYPE** of claims.
- Finalized (ids ≤ 5590) but not yet claimed: **217 entries** (from `WithdrawalQueued`/`WithdrawalClaimed` logs).
- Sum of those 217 `hypeAmount` = **1,621.9057983250163 HYPE**; the manager's ETH balance at the fork block =
  **1,621.905798325016362542 HYPE**. **Exact to the wei.**
- Largest single unclaimed claim: id 2707, `0xc4bdD45F…bbf3` (the treasury), 1,156.690616997664083801 HYPE.

Because `entry.hypeAmount` is fixed at request time and the HYPE is moved to the manager at finalization, the
manager is a pure pass-through escrow: no surplus to capture, no shortfall to socialise.

### 4.3 Finalize / claim invariants

| Check | Code | Verified |
|---|---|---|
| finalize is admin-only | `WithdrawManager.sol:159-162` | fork test: attacker call reverts (`0xea8e4eb5` = NotAuthorized) |
| finalize is monotonic | `index <= lastFinalizedIndex` reverts | — |
| no double claim | `entry.claimed = true` before the external call (**CEI**) + `AlreadyClaimed` | fork test: 2nd claim reverts (`0x9f692c7e`) |
| claim pays the recorded user | `payable(entry.user).call{value: entry.hypeAmount}` | fork test: attacker claims the treasury's id → treasury +1,156.69 HYPE, attacker +0 |
| burn only by the manager | `BeHYPE.burn` requires `msg.sender == withdrawManager` | source |
| mint only by the core | `BeHYPE.mint` requires `msg.sender == stakingCore` | source |
| instant path burns exactly what it pays | `burn(afterFee)` then `sendFromWithdrawManager(BeHYPEToHYPE(afterFee))` | fork test: 100 → 99.6999… |

### 4.4 The 2025 CRITICAL (queue bricking) is fixed

Nethermind **NM-0628 §6.1 [Critical]** documented that `finalizeWithdrawals` used to *push* HYPE to each user inside
the loop, so a contract with a reverting `receive()` could freeze the queue forever. The deployed code implements
the recommended pull pattern: `finalizeWithdrawals` burns + moves HYPE **to the manager**, and users pull with
`claimWithdrawal`. Fork test `test_revertingReceiverCannotBlockQueue` deploys exactly that attacker, queues
0.1 HYPE from it, and confirms the admin's finalize **succeeds** and `lastFinalizedIndex` advances; only the
attacker's own claim reverts.

---

## 5. What an attacker can and cannot do

| Action | Precondition | Outcome |
|---|---|---|
| `finalizeWithdrawals` | PROTOCOL_ADMIN | reverts (tested) |
| `claimWithdrawal(id)` of another user | id ≤ lastFinalizedIndex, unclaimed | pays **that user**; attacker gains 0 (tested) |
| re-claim / reenter | — | `AlreadyClaimed`; `nonReentrant` (tested) |
| inflate shares with a fee-on-transfer deposit | — | `stake()` is native HYPE (`msg.value`), no ERC-20 path |
| manipulate NAV by donation | — | donation raises NAV for all holders proportionally; `stake()` uses the stored ratio, so a donor recovers only their share |
| JIT the ratio update | capital + mempool access | see §6 — net negative at current cadence |
| drain `StakingCore` | `sendFromWithdrawManager` requires `msg.sender == withdrawManager`; `withdrawFromStaking`/`depositToHyperCore` are admin | no path |

---

## 6. The only live asymmetry: stale `exchangeRatio` (JIT yield capture)

`updateExchangeRatio()` is admin-only, requires ≥5 blocks since the last HyperCore operation, and is guarded to
≤500 bps APR change. Observed cadence: one call every **~86,600 s (~24 h)** (`ExchangeRatioUpdated` logs, 13 events).
Per-call accrual measured from two consecutive events: **0.0058 % (0.58 bp)**.

Fork test `test_staleRatioGap` at block 49,145,310:

```
ratio       = 1.022995496666924603
NAV/supply  = 1.023053582343401925
gap         = 0.0057 % (5.68e-5)
```

Economics:
- Gross yield that the next poke will distribute = `gap × NAV` = **8.84 HYPE ≈ $720.52**, shared across **all**
  152,174 beHYPE. An attacker who adds capital `D` just before the poke captures `D/(TVL+D)` of it.
- **Instant exit** costs 30 bps → a 0.0057 % gain is 52× too small. Break-even requires **~51 days** of un-poked
  accrual (`test_jitBreakEvenFarAboveLiveAccrual`).
- **Queue exit** costs no fee but locks the capital for the 3–7 day finalization window to capture 0.0057 %
  (≈0.3 % annualised on the locked amount) — below the risk-free HYPE staking rate.

Verdict: not an unprivileged extraction at today's parameters. It becomes one if the ratio is left un-poked for
more than ~51 days while ≥$12M of flash liquidity is available.

---

## 7. Fork PoC — 8/8 PASS

`poc/test/Hyperbeat.t.sol`, `forge test -vv`, HyperEVM fork at block **49,145,310**
(`HYPEREVM_RPC` env override, default keyless `https://rpc.hyperliquid.xyz/evm`):

| # | Test | Result |
|---|---|---|
| 1 | `test_staleRatioGap` — quantifies ratio vs NAV/share | PASS (gap 5.68e-5) |
| 2 | `test_queueFullyBacked` — manager balance == liability, treasury claim live | PASS |
| 3 | `test_attackerCannotFinalize` — NotAuthorized | PASS |
| 4 | `test_claimOtherUserPaysThem` — attacker gains 0 | PASS |
| 5 | `test_doubleClaimReverts` — AlreadyClaimed | PASS |
| 6 | `test_revertingReceiverCannotBlockQueue` — old CRITICAL fixed | PASS |
| 7 | `test_instantWithdrawalRoundtrip` — 100 in → 99.6999 out | PASS |
| 8 | `test_jitBreakEvenFarAboveLiveAccrual` — 51-day break-even | PASS |

HyperCore read precompiles are native and absent from the forked EVM state; the two `L1Read` getters
(`delegatorSummary`, `spotBalance`) are mocked with the **exact values read at the same block**, so
`getTotalProtocolHype()` returns the on-chain value `155682416469713166186119` wei (asserted in the test).

CI: run via `bash ci/ci-run.sh hyperbeat` (log in `ci-log.txt`, run URL in the summary).

---

## 8. Verdict

**$0 extractable by an external unprivileged attacker. Confidence: high.**

- The queue is a pass-through escrow that is exactly funded; claims are beneficiary-bound and double-claim-proof.
- The single Critical finding against this code (queue bricking) is fixed in the deployed build and proven fixed.
- The ether.fi Liquid `/AtomicQueue` exploit class does not exist in this codebase; deployed source == audited upstream.
- The only live asymmetry (stale ratio, 0.0057 %) is worth **$720.52** to the *entire* holder base and is
  dominated by the 30 bps instant fee and the 3–7 day queue lock.

**Residual / latent:**
- **P:** two admin EOAs can finalize at will; the owner/upgrader is a TimelockController with **`getMinDelay()` = 1800 s (30 min)**,
  not the 3 days stated in the repo README — a privileged risk over the full $12.69M.
- **Monitor:** `ExchangeRatioUpdated` cadence. If >~51 days pass without a poke, the JIT flash-loan route becomes
  net-positive (gross ceiling = the un-poked yield, currently $720.52, scaling linearly with delay).
- HyperCore-side risk (validator/delegation, the 996.68 HYPE in `totalPendingWithdrawal`) is operational, not E-U.

---

## 9. Method, caveats, files

Read-only: `eth_call`/`eth_getStorageAt`/`eth_getLogs` via Etherscan V2 (chain 999) and the keyless
`https://rpc.hyperliquid.xyz/evm`; Foundry fork at a pinned block. Price: CoinGecko HYPE $81.51 (2026-10-21).
No keyed URL or secret is stored in this folder.

Caveats: (1) HyperEVM read precompiles are mocked in the fork with the exact same-block values (documented above);
(2) the event-derived liability reconciliation covers all 5,603 queue entries and 5,373 claims from genesis;
(3) `getTotalProtocolHype` depends on the HyperCore `totalPendingWithdrawal` bucket, which is counted as an asset
and could in principle be delayed by HyperCore finality (operational, not attacker-controlled).

Files: `analysis/es_sources.py`, `analysis/src_wm_impl/`, `analysis/src_stakingcore/`, `analysis/src_behype_impl/`,
`analysis/src_roleregistry/`, `analysis/wm_events.py`, `analysis/wm_events.json`, `poc/`, `ci-log.txt`, `ci-artifacts/`.
