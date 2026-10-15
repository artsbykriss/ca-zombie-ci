# exfi-verify — independent adversarial verification of the Enosys EXFI/SFIN staking "extractable = $0" conclusion

**Verifier:** exfi-verify subagent (independent data; does not reuse the parent's numeric claims)
**Chain:** Songbird (19) via keyless `https://songbird-api.flare.network/ext/C/rpc` — **read-only, no transactions, no keys**
**Verdict:** **CONFIRMED — external unprivileged extractable value = $0** (confidence: **high**)
**Falsification attempt:** failed — no extraction path found; every hypothesis in the brief was tested live and closed.
**Blocks:** recon 135,453,827 · identity 135,455,045–51 · probe suite 135,455,111–171 · final state 135,455,601 (2026-10-15)

Notation: `MGR` = `0xc4D89F8f593F215f3636793E3353A36C196Cf87A` (EnosysGovernanceStakeManagerExfi),
`SFIN_MGR` = `0xA83E90337e2711b1c84df0AD7428403dBd0ce730`, `FARM` = `0xb78ebd4b13a2202068618bf98f952c0271159107`,
`EXFI` = `0xC348F894d0E939FE72c467156E6d7DcbD6f16e21`, fresh caller = `0x4444…4444`, attacker = `0x6666…6666`.

---

## 0. Environment note (integrity)

Partway through this verification (≈13:59) the parent's whole finding folder `flare-kava-small/` (untracked in git, so not recoverable)
was **deleted externally** — before my probe suite had emitted results. My working folder was recreated at the assigned path and all
scripts/outputs were rebuilt; the parent's original artifacts were re-read from the CI checkout copy still present at
`/tmp/opencode/ca-zombie-ci-flare-kava-small/flare-kava-small/`. Every number in this report comes from live `eth_call` reads made
by this verifier's own scripts (blocks are recorded in each artifact). No parent numbers were trusted or copied.

**Method for observing state changes without transactions (no trace API on this RPC):** `eth_call` state overrides. The deployed
Multicall3 (`0xcA11…CA11`, verified 3808-byte runtime on Songbird) is injected as the *code* of an EOA in the call override, so
`aggregate3` runs "as" that EOA and every nested call has `msg.sender` = that EOA; writes persist inside the single `eth_call`, so
before/after state can be read in the same call. This was validated (`getChainId()` → 19; `symbol()` → "WSGB"; a storage-override
round-trip on the EXFI token). All of this is simulation only — nothing is signed or sent.

---

## 1. Task 1 — payout identity re-derived live, my own stakers, all 8 tokens

`identity.json` (blocks 135,455,045 → 135,455,051; currentEpoch=378, latestEpochForRewards=376).

| staker (my choice) | lastClaim | claim window | `getAllUnclaimedRewards` == `Σ_e balanceOfEpoch(u,e)·epochRewardRate(e,tok)/1e18/10^(18-dec)` per epoch? |
|---|---|---|---|
| `0x0B465f43…f28d4` (big, 4,405,406 EXFI staked) | 372 | e373–376 | **MATCH for all 8 tokens** |
| `0xFAA9f4d3…420D8` (active, 383,427 EXFI staked) | 375 | e376 | **MATCH for all 8 tokens** |
| `0x1C14e47b…805436` (small, lagging) | 365 | e366–376 | **MATCH for all 8 tokens** |
| fresh `0x3333…3333` | 0 | — | all zero, `canClaimRewards=false`; `balanceOfEpoch(fresh,e)=0` for e ∈ {1,50,150,300,370,375} |

Exact on-chain values (whole-token order WSGB, EXFI, SFIN, exXDC, FXRP, exETH, exUSDT, USDX):

- U1 `0x0B465f43`: `[188871439135080715189, 2353718618090540939307, 1387794038527929, 501455253982978162, 70306, 145176147583, 3637, 846]` — **identical to recomputed**.
- U2 `0xFAA9f4d3`: `[1452572895252501624, 52089367251860592792, 13842896115462, 2266802497487288, 269, 0, 61, 13]` — **identical**.
- U3 `0x1C14e47b`: `[429685975683038465, 2387764396800592343, 3174868228212, 10197481414569084, 63, 573641893, 11, 0]` — **identical**.

Rounding detail (independent extra check): computing the sum exactly and flooring once at the end (`calcC`) does **not** match the
chain for the multi-epoch accounts (deltas of +1…+5 base units per token, e.g. U1 EXFI `…307` on-chain vs `…309` exact-then-floor);
the per-epoch-truncating recomputation matches **exactly**. So the contract truncates per epoch — the truncation is dust that
*slightly under-pays* the staker; it is not attacker-extractable.

The fresh-account claim window (lastClaim=0) was sanity-sampled rather than re-enumerated (376 zero-balance epochs); the reward
arithmetic for the three real users is the substantive test.

---

## 2. Task 2 — every recovered-ABI function classified + fresh-caller evidence

Full table: **`classification.md`** (80 ABI functions + the 4 bytecode-only selectors). Summary:

| class | count | attacker can move value to self? | attacker can change another user's state? |
|---|---|---|---|
| VIEW | 50 | no | no |
| VALUE-IN — stake/stakeWithHint/stakeWithPermit/stakeToWithHint/stakeToWithPermit | 5 | no (pulls caller's tokens; `stakeTo*` credits a chosen recipient = donation only) | only a self-funded donation to a recipient (no past-epoch credit; §3d) |
| VALUE-OUT — claim/withdraw/exit/fee families | 13 | no (all caller-scoped; §3a/b, §4b) | no |
| ADMIN — owner/governor/notifier/ownership | 10 | no | no |
| INIT — `initialize`, `acceptOwnership` | 2 | no (`already initialized`; `not the new owner`) | no |
| permissionless finaliser `updateTotalSupplyByEpochIfNeeded` (bytecode extra) | 1 | no (idempotent, §3c) | no |

Live fresh-caller results for every state-changing function (`probes.json` → `S1_fresh_direct`, blocks 135,455,111–171;
`SFIN` = identical bytecode impl, same results where probed):

```
acceptOwnership()                          -> revert: Ownable2Step: caller is not the new owner
initialize(address,uint256,address[],address) -> revert: Initializable: contract is already initialized
addVoting(uint256,uint256)                 -> revert: EnosysGovernanceStakeManager: Not a governor
updateVoting(uint256,bool)                 -> revert: EnosysGovernanceStakeManager: Not a governor
updateRewardAmountByToken(address,uint256) -> revert: EnosysGovernanceStakeManager: Not allowed reward notifier
claimRewards()                             -> revert: EnosysGovernanceStakeManager: No any rewards
exit() / exitWithHint(uint256)             -> revert: EnosysGovernanceStakeManager: Amount is zero
stake(uint256) / stakeWithHint(…) / stakeToWithHint(…) -> revert: EXFI: Transfer exceeds balance
stakeWithPermit(…) / stakeToWithPermit(…)  -> revert: EXFI: invalid signature
withdraw / withdrawWithHint / withdrawAndGetReward / withdrawAndGetRewardWithHint
  / withdrawTo / withdrawToWithHint / withdrawToAndGetReward / withdrawToAndGetRewardWithHint
                                           -> revert: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance
withdrawReturnedFees(true) / withdrawReturnedFeesTo(_,true) -> revert: …: No pending fees
withdrawReturnedFees(false) / withdrawReturnedFeesTo(_,false) -> SUCCESS, ret 0x (no-op; §4b)
transferOwnership / renounceOwnership / updateApyCloudVault / updateGovernor / updateRewardTokensAdd
  / updateRewardTokensRemove / updateTotalSupplyAggregationRange -> revert: Ownable: caller is not the owner
updateTotalSupplyByEpochIfNeeded(cur-2)    -> SUCCESS, returns the stored epoch total (§3c)
updateTotalSupplyByEpochIfNeeded(cur)      -> revert: …: Cannot update total supply for the current or next epoch
```
(`owner()` = EOA `0x28591A8d1a899Ca78a6b517E70c9ed327a26b42c`, `pendingOwner()` = 0, notifier getter `0xa5032f3c` = `0xb8d1c66a…4d8c1b`.)

---

## 3. Task 3 — hypotheses attacked

### (a) `withdrawTo`-family cannot draw a victim's balance — CLOSED

*Semantics proven live* (msg.sender = VICTIM `0x0B465f43…` via the code-override technique; balances read after the call in the same `eth_call`):

| call (from VICTIM) | result | ATTACKER EXFI Δ | VICTIM stake Δ | VICTIM lastClaim |
|---|---|---|---|---|
| `withdrawTo(1e18, ATTACKER)` | success | **+1.0 EXFI** | −1e18 | 372 (unchanged) |
| `withdrawTo(1e18, VICTIM)` | success | 0 | −1e18 | 372 |
| `withdrawToAndGetReward(1e18, ATTACKER)` | success | **+2,354.718618090540939307 EXFI** (= 1 EXFI withdrawn + 2,353.718618090540939307 unclaimed) | −1e18 | **→ 376** |
| `exit()` | success | 0 | → 0 (full exit) | → 376 (VICTIM receives 4,407,759.992904018566139363 EXFI = stake+own rewards) |

So the function pays the recipient chosen by **msg.sender**, and both the withdrawal and the reward-claim are drawn from
**msg.sender's** position. The attack direction (caller ≠ victim) was then tested directly:

```
from ATTACKER:
  withdrawTo(victimBal=4,405,406.274285928025200056e18, ATTACKER)          -> revert: Cannot withdraw, exceed the balance
  withdrawTo(victimBal, VICTIM)                                            -> revert: Cannot withdraw, exceed the balance
  withdrawToAndGetReward(victimBal, ATTACKER)                              -> revert: Cannot withdraw, exceed the balance
  withdrawToWithHint(victimBal, ATTACKER, 3)                               -> revert: Cannot withdraw, exceed the balance
  withdrawToAndGetRewardWithHint(victimBal, ATTACKER, 3)                   -> revert: Cannot withdraw, exceed the balance
  exit() / exitWithHint(3)                                                 -> revert: Amount is zero
  withdrawTo(1, ATTACKER)  (0 own balance)                                 -> revert: Cannot withdraw, exceed the balance
```
**No path lets an outsider unlock or redirect another account's principal or rewards.** (A victim *voluntarily* calling
`withdrawTo(amount, anyone)` or `…AndGetReward(amount, anyone)` can send their own stake+rewards to that address — expected recipient semantics, not a vulnerability.)

### (b) `claimRewards` cannot pay more than the formula — CLOSED

msg.sender = U2 `0xFAA9f4d3…` (canClaim=true), all in one simulated call:

- before: EXFI 8,880,421,753,419,256,193,589 (8,880.42); `unclaimed = [1452572895252501624, 52089367251860592792, 13842896115462, 2266802497487288, 269, 0, 61, 13]`; lastClaim 375
- `claimRewards()` succeeds — **per-token balance deltas equal the `getAllUnclaimedRewards` array exactly, element by element** (EXFI +52,089,367,251,860,592,792 = unclaimed[EXFI]; WSGB +1,452,572,895,252,501,624 = unclaimed[WSGB]; … exETH +0 = 0; exUSDT +61; USDX +13)
- `lastClaim` 375 → 376; `getAllUnclaimedRewards` after = **all zeros**
- **second `claimRewards()` in the same call → revert `At least one epoch has not passed`** (no double pay)

Attacks on the payout magnitude:
- *Tiny fresh stake then claim:* funded-fresh simulation (state-overridden 1000 wei EXFI + max allowance; §3d): after staking,
  `getAllUnclaimedRewards(fresh)` is **all zero** and `claimRewards` reverts **`No any rewards`** — staking now cannot retro-add a past-epoch balance (snapshot blocks for e≤376 are past and immutable; a new checkpoint is written at the current block).
- *`getBalanceHint` abuse:* live hint = 3 for accounts with checkpoints, 0 for fresh. It is only a search hint: undersized hints
  self-correct (stake with hint 0 credited exactly 1000 wei, no more), and **oversized hints revert**:
  `stakeWithHint(1000, 2^64)` → `Balance hint is larger than expected value`; `withdrawWithHint(1, 2^64)` → same.
- *Manipulating `userLastRewardClaimEpoch`:* it only advances on the account's own `claimRewards`/`exit`-type calls (375→376 after the sim). No permissionless path touches it (`withdrawReturnedFees*` from a third party leaves the victim's claim epoch and fee records unchanged; §4b).

### (c) `updateTotalSupplyByEpochIfNeeded(e)` is idempotent — CLOSED

`probes.json` → `S4_epoch_totals` (direct call + read-after-write in one `eth_call`, from a fresh EOA):

| epoch | stored `totalSupplyByEpoch(e)` | call | returned | stored after call |
|---|---|---|---|---|
| 376 | 16,114,838.616271167803039511 EXFI | success | **identical value** | **unchanged** |
| 375 | 16,108,318.957584837513517702 EXFI | success | **identical value** | **unchanged** |
| 373 | 16,099,278.262199701127117477 EXFI | success | **identical value** | **unchanged** |
| 378 (current) | 0 | revert | — | — (`Cannot update total supply for the current or next epoch`) |
| 379 (next) | 0 | revert | — | — (same message) |

No write can diverge from the stored epoch total.

### (d) `stakeToWithHint` credits the recipient with the caller's tokens only — CLOSED

Funded-fresh simulation (fresh2 given 1000 wei EXFI + max allowance by storage override; verified the allowance override by
storage round-trip):

- `stakeWithHint(1000, 0)` → success; `balanceOf(fresh2)` 0→1000; EXFI 1000→0 (1:1 pull); `balanceOfEpoch(fresh2, cur-1)=0`;
  `balanceOfEpoch(fresh2, cur)=0`; `getAllUnclaimedRewards(fresh2)=0`; `claimRewards` → `No any rewards`.
- `withdrawWithHint(500, 0)` → success; final EXFI 500 (exact).
- `stakeToWithHint(1000, FRESH, 0)` → success; **FRESH `balanceOf` 0→1000** (donation), FRESH `balanceOfEpoch(cur-1)` = 0
  before and after, FRESH unclaimed all-zero. The **caller pays**, the recipient is credited, and no old-epoch balance is
  created for anyone. There is no inverse (recipient pays / caller credited) — that direction is not implemented.

### (e) Fresh account cannot receive anything — CLOSED

`probes.json` → `S3_fresh_sweep`: one simulated `eth_call` runs the **entire set** of 19 write calls as a fresh account
(claim, exit, exitWithHint, withdraw{WithHint}, withdraw{AndGetReward}{WithHint}, withdrawTo{…}×4, withdrawReturnedFees{,To}×2,
stake×3, updateTotalSupplyByEpochIfNeeded) and then reads the account's balances of all 8 reward tokens in the same call:

- All value-moving calls revert (exact reasons identical to §2) or are no-ops (`withdrawReturnedFees(false)` variants).
- **All 8 token balances of the fresh account after the full attack sweep = 0.**

---

## 4. Task 4 — FarmingPool (EXFI→SFIN, expired)

- `allowedCaller` live: `0x9EbF96373f24A8836d3899C9ff17451F802E8c72` = **true**, `0x43fc122D6dDa2c07301ee131Fa2afa8Bf5854A07` = **true**;
  every other probed address (both managers, keepers, notifier, vault) = false. Both allowed callers have **code size 0 → EOAs**
  (nobody can "invoke" them; no contract pass-through exists). The explorer `UpdateAllowedCaller` log history shows **exactly two
  events ever** (blocks 49,476,171 / 49,476,417, both `isAllowed=true`) — log copy saved as `farm_update_allowed_caller_logs.json`.
- As caller = fresh EOA: `withdrawFor(1, FRESH)`, `withdrawAndGetRewardFor(1, FRESH)`, `stakeFor(1, FRESH)` →
  `StaticPool: Not allowed caller`; `withdraw(1)` → `Cannot withdraw exceed the balance`; `exit()` → `Cannot withdraw 0`;
  `getReward()` → success but `earned=0` → no transfer; `rescue`, `rescueUnclaimedTokens`, `updateAllowedCaller`,
  `notifyRewardAmount` → `Ownable: caller is not the owner`.
- As caller = allowed EOA `0x43fc…`: `withdrawFor(1, FRESH)` / `withdrawAndGetRewardFor(1, FRESH)` →
  `Cannot withdraw exceed the balance` (proves the caller is allowed **and** that the balance checked/paid is the `user` argument,
  not the caller's); `stakeFor(1, FRESH)` succeeds because that EOA holds EXFI and approved the pool — it pulls from the **caller**
  and credits `user`; `exit()` on its own (zero) balance reverts. Verified source (`farmingpool_impl_src.sol`): `_withdraw` and
  `_getReward` transfer only to the `user` parameter; `stake`/`withdraw`/`exit`/`getReward` act on `msg.sender` only.
- **Conclusion: no allowed caller is a contract and no function pays the caller from someone else's balance → the CRITICAL
  pass-through scenario does not exist.** Best available griefing (if one of the two EOAs were compromised) is force-unstaking a
  chosen user's principal **to that same user** — no value redirect.

## 4b. Extra surfaces checked

- **apyCloudVault `0xd971efb6…410b27`** (permissionless `triggerDistribution(bool)`): all 8 token balances = **0**;
  `triggerDistribution(true)` from a fresh EOA succeeds but moves nothing (`false` reverts). Even when funded, distribution is
  pro-rata to stakers via the notifier — no attacker-directed value.
- **Returned-fees path** (`probes.json` → `S6_fees`): `totalLockedFees` = `22,016,518,705,984,920` wei (0.022 EXFI, unchanged by
  any tested call). Fresh: both fee calls are no-ops, zero token movement. Attacker calling `withdrawReturnedFeesTo(ATTACKER,false)`
  leaves U2's balances **and** U2's fee records bit-identical (attacker gets 0). U2 itself: `withdrawReturnedFees(true)` →
  `No fees to return` even though U2 carries `[0, 1,126,145,528,281,164, 0]` unprocessed fees; `(false)` succeeds with zero
  movement. The record is keyed to `msg.sender` (confirmed behaviourally), so cross-user fee withdrawal is not possible.

---

## 5. Falsification attempts that FAILED (i.e. found nothing)

1. Attacker-directed `withdrawTo`/`withdrawToAndGetReward{,WithHint}(victimBalance, ATTACKER)` — all revert (own-balance check).
2. `claimRewards` inflation via fresh stake / hint games / lastClaim manipulation — payout equals the array exactly; second claim reverts.
3. Overwriting settled `totalSupplyByEpoch` — byte-identical stored value after call.
4. `stakeToWithHint` reverse-credit / old-epoch balance creation — caller pays, recipient credited, past epochs stay 0.
5. Full fresh-account attack sweep (19 calls, all 8 tokens read after) — zero received.
6. FarmingPool third-party withdrawal via allowed callers — both are EOAs; the "For" functions pay the `user` argument.
7. Fee-record hijack via `withdrawReturnedFeesTo` — third-party calls cannot touch another account's records.
8. Re-initialization takeover — `Initializable: contract is already initialized`.
9. `updateRewardAmountByToken` (reward forgery) — `Not allowed reward notifier` (only `0xb8d1c66a…`); `addVoting`/`updateVoting` — `Not a governor`.

## 6. Residual gaps / honest limits

- **Unverified implementation.** The manager's impl (`0xB0E4D5ba…`) has no verified source; this verification is black-box live
  behaviour + recovered ABI + heimdall decompilation (which is noisy). A novel bug not reachable through any of the 80+4
  selectors cannot be excluded by this method — but every externally reachable selector was classified and exercised for gating,
  and the value-moving semantics (claim math, withdrawals, staking, fees) were probed directly.
- **No epoch rollover occurred during the session** (currentEpoch stayed 378; latestRewardEpoch 376). Cross-boundary behaviour
  (snapshot storage at the next epoch's first interaction; notifier registration) was not re-observed live; it is covered by the
  parent's bytecode-level PoC (not re-run here — see hard rules) and by the structural argument (past-block snapshots are immutable).
- **`withdrawReturnedFees(true)` was never observed to move value** (no account currently has *claimable* returned fees), so the
  positive payout branch of that path is verified only as "revert / no-op" for all reachable states; its records are keyed to
  `msg.sender` regardless.
- **`stakeWithPermit`/`stakeToWithPermit`**: only the invalid-signature revert was observed (cannot forge EIP-2612 signatures);
  a valid permit only stakes the signer's own tokens (same code path as `stakeWithHint` after permit verification).
- Trace APIs (`debug_traceCall`, `trace_call`) are unavailable on this RPC; state writes were observed via the Multicall3
  code-override technique instead of traces.
- Songbird public RPC keeps ~3 blocks of state: every read used `latest`; each artifact records its block.
- The `.git` index was not modified; deliverables were written only under `children/exfi-verify/`.

## 7. Verdict

**The parent's conclusion is CONFIRMED by independent live evidence:** an external unprivileged attacker can extract **$0** from
the Enosys EXFI/SFIN governance staking contracts and the linked FarmingPool. No retro-claim, no hint/checkpoint corruption, no
claim inflation, no cross-account withdrawal, no reward forgery, no fee theft, no third-party farm withdrawal, no re-init takeover.
All held value remains either each staker's own principal (self-service) or unclaimed epoch rewards payable only to their owners.

Confidence: **high**. Principal residual risk is the unverified implementation (monitor `0xEE8Cc71c…` proxy admin for upgrades).

## 8. Files in this folder

| file | what it proves |
|---|---|
| `VERIFY.md` | this report |
| `summary.json` | machine-readable verdict fragment |
| `identity.json` / `identity.py` | Task 1 live identity re-derivation (3 stakers + fresh, 8 tokens, blocks) |
| `probes.py` / `probes.json` | all adversarial probes (S1 gating, S2 claim/withdraw/stake-by-staker, S3 fresh sweep, S4 epoch totals, S5 farm, S6 fees) |
| `classification.md` / `classify.py` | every recovered-ABI function classified + fresh-caller result |
| `state.json` / `state.py` | final live state snapshot (block 135,455,601) |
| `lib.py` | RPC + ABI + Multicall3-override helpers |
| `run_s2.py` | re-runs section 2 (staker-context) |
| `stake_manager_abi.json` | recovered ABI copy (from the CI checkout; original tree was deleted externally) |
| `farmingpool_impl_src.sol` | verified FarmingPool implementation source |
| `farm_update_allowed_caller_logs.json` | explorer log history of `UpdateAllowedCaller` (exactly 2, both EOAs) |
