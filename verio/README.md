# Verio vIP (Story) — `excessUnstake` / `pendingUnstake` ledger and WithdrawalPool surplus

**Date:** 2026-10-21 (UTC) · **Chain:** Story mainnet (chainId 1514) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction was signed or broadcast**.
**Target:** Verio vIP — StakePool `0xf6701A6A20639f0E765bA7FF66FD4f49815F1a27`, WithdrawalPool `0x2a7935E926C65Ef2671D5807760e2421adf992d8`, vIP `0x5267F7eE069CEB3D8F1c760c215569b79d0685aD`, Delegator `0xB47Aedf533cc3c1651a8Af2312Fe55e317006821`.
**Fork block for all state below:** **23,624,317** (public RPC `https://mainnet.storyrpc.io`; it does not serve archive state, so reads are "latest at the fork block", taken in one batch by `poc/test/Verio.t.sol`).

---

## 1. TL;DR

| Question | Answer | Confidence |
|---|---|---|
| Does the pass-3 hypothesis (WP `handleBalance()` returns surplus IP to the StakePool → `excessUnstake` counted twice with `address(this).balance`) hold? | **No. Disproven.** `handleBalance()` sends the true surplus to the **WithdrawalPool InsurancePool** (`0x22dF…Ebc4`), never to the StakePool. It explicitly reserves `stakePool.getUnstaked()` (E) before computing the surplus. | **High** (source + fork trace + exact balance deltas) |
| Is unbonded principal ever credited to the StakePool balance? | **No.** The Delegator sets the Story staking precompile's withdrawal address to `selector.withdrawalPool()` (the WP). Settlement mints IP to the WP, not the SP. | High (verified Delegator source line 886 + fork path) |
| Is `excessUnstake` live? | **No — E = 0** at block 23,624,317. Even if created, it is a WP-held reserve, not a double count. | High |
| Can a fresh unprivileged attacker extract anything from this ledger? | **No. $0 E-U.** | High |
| Is there any other live extraction path in the target? | No code-level E-U path found. A capital-gated, one-shot JIT reward-dilution effect exists (gross ≤ ~$3.0k, net of normal staking yield ≤ ~$0.2k); see §6. | Medium |
| Privileged risk | The **EOA owner** (`0x0f01…5e16`, codesize 0) can replace the 300-second timelock admin with itself, retarget the ComponentSelector, and point the precompile's withdrawal address at an arbitrary contract → full-drain capability over the delegated principal. Fork-proven authorization; CL settlement inferred. | Medium-high |

### Total live extractable now

| Category | IP | USD @ $0.15295 | Confidence |
|---|---|---|---|
| **E-U** (external unprivileged) | **0** | **$0** | **High** |
| E-U-conditional (JIT reward dilution, gross one-shot bound) | 0 net counted (≤19,773 IP gross) | **$0** counted (≤ $3,024 gross, ≤ ~$182 excess over normal staking) | Medium |
| **H-O** (user-owned recoverable) | 6,665.841927501986166900 | **$1,019.54** | High |
| **P** (owner/timelock) | 15,561,260.564831816 | **$2,380,094.80** | Medium-high (auth proven) |
| **S** (stuck/bricked) | 0 | **$0** | High |

IP price: **$0.15295**, implied by DefiLlama `api.llama.fi/protocol/verio` latest point (timestamp 1792592663: TVL $2,369,454.98 / 15,491,283.906 IP). Pass-3's $0.1468 is within 5%.

---

## 2. The mechanism in exact terms

### 2.1 Verified StakePool ledger (source: impl `0x3dbe57a6…2698`, verified)

`StakePool._getTotalStake()` (lines 329–333):

```solidity
return _selector().delegator().getGlobalDistributionTotal()   // D
     + stakePoolState.excessUnstake                           // E
     - stakePoolState.pendingUnstake;                         // P
```

`_calculateIPWithdrawal(v)` (lines 300–318) uses `A = totalStake + address(this).balance` (B) and returns
`A − ceil(A·(S−v)/S)`, i.e. rounds the withdrawal **down** in favour of the pool.
`_calculateVIPMint(a)` (lines 283–292) uses `S·(A)/(A−a)` and rounds the mint **down**.

`_unstake` (lines 220–265) does, in order:
1. `ipToWithdraw = _calculateIPWithdrawal(vIPAmount − burnFee)`;
2. `pendingUnstake += ipToWithdraw`;
3. consume `excessUnstake` against `pendingUnstake` (E first, then P);
4. if `pendingUnstake >= delegationSize` → `delegator.handleUnstake(P)`, set `P = 0`, `E += excess`;
5. burn the vIP, `withdrawalPool.addWithdrawal(user, ipToWithdraw, unbondingPeriod)`, then `withdrawalPool.handleBalance()`.

`getTotalPendingWithdrawals()` is **never** read by the StakePool — grep of the verified source shows it only in the interface. The WP's Pw is therefore irrelevant to share pricing; pass-3's comparison of Pw (6,663.7) vs P (1,457.2) compared two different ledgers.

### 2.2 Where the IP actually goes (verified Delegator)

`Delegator._setWithdrawalAddress()` (lines 882–887):

```solidity
ipTokenStaking.setWithdrawalAddress{value: fee}(
    address(_selector().withdrawalPool())   // = 0x2a79…92d8
);
```

So the Story staking precompile sends **all unbonded principal and rewards to the WithdrawalPool**, never to the StakePool. The only IP inflows to the StakePool are: user `stake{value}`, `rewardPool.claimRewards()` (called by `_restake()`), and permissionless donations (`fund()` / `receive()`). None of these is the pending-withdrawal IP.

### 2.3 What `handleBalance()` actually does (unverified WP impl, settled dynamically)

The WP impl `0x8512Eed984234e197F8b32ef8f589E6eEb8Bc9e2` is unverified. Heimdall v0.9.2 recovers the ABI (`analysis/wp-impl-abi.json`, `analysis/wp-decompiled.sol`), but the decompilation is lossy, so the semantics were settled on an anvil fork with a call tracer.

`handleBalance()` (selector `0x5600231a`, gated `OnlyAdminOrStakePool`) performs this exact sequence:

```
stakePool()                                  (selector 0xf8ea4756)
insurancePoolByComponent(this)               (selector 0x3e323df2)
insurancePool.remainingCapacity()            (selector 0x14a6bf0f = 25,000 IP cap − balance)
stakePool()                                  (again)
stakePool.getUnstaked()                      (selector 0x6c21157a = E)
insurancePool.fund{value: X}()               (selector 0xb60d4288)
```

with `X = min( max(address(this).balance − totalPendingWithdrawals − E, 0), capacity )`.
The WP retains `Pw + E + (surplus − X)`; the StakePool balance is **unchanged**.

Fork proof (block 23,623,495, WP donor 0xf39F…2266, SP impersonated):

| Test | WP balance before | Pw | E | X sent to insurance | WP after |
|---|---|---|---|---|---|
| donate 20,000, E=0 | 20,000 | 6,665.841927501986166900 | 0 | **13,334.158072498014** | 6,665.841927501986166900 |
| donate 10,000, E=1,000 (storage-injected) | 10,000 | 6,665.8419 | 1,000 | **2,334.158072498014** | 7,665.841927501986166900 |
| donate 100,000, E=0, capacity 11,402.26 | 106,665.8419 | 6,665.8419 | 0 | **11,402.257973846352** (cap) | 95,263.58385365563 |

(Each row is a separate fork run or a fresh donation on the prior state; the "before" column is the actual WP balance at the start of that run. In row 3 the WP still held the Pw from row 1, hence 106,665.84.)

Trace (callTracer, abridged; full text in `analysis/handleBalance-trace.txt`):

```
CALL 0xf6701a6a -> 0x2a7935e9 0x5600231a
 DELEGATECALL 0x2a7935e9 -> 0x8512eed9 0x5600231a
  STATICCALL 0x2a7935e9 -> 0x20cb9dcb 0xf8ea4756 -> 0xf6701a6a
  STATICCALL 0x2a7935e9 -> 0x20cb9dcb 0x3e323df2(WP) -> 0x22df4ef4
  STATICCALL 0x2a7935e9 -> 0x22df4ef4 0x14a6bf0f -> 24,736.416046344366
  STATICCALL 0x2a7935e9 -> 0xf6701a6a 0x6c21157a -> 0
  CALL       0x2a7935e9 -> 0x22df4ef4 0xb60d4288 value 13,334.158072498014
```

**There is no value-bearing call to the StakePool.** The insurance pool is a separate proxy (`0x22dF…Ebc4`, impl `0xCB5E…5713`, 25,000 IP cap, `claim()` onlyWithdrawalPool).

### 2.4 The corrected invariant

Let D = active delegated IP, U = IP in the Delegator's unstake queue / precompile in-flight, B = SP liquid balance, E = excessUnstake, P = pendingUnstake, Pw = WP outstanding claims, W = WP balance, I = WP insurance balance.

The system is consistent at every step:

| Event | D | E | P | B | W | Pw | NAV = D+E−P+B |
|---|---|---|---|---|---|---|---|
| user stakes X | — | — | — | +X | — | — | +X |
| user unstakes v, claim c | — | — | +c | — | — | +c | −c |
| `handleUnstake` dequeues c+e | −(c+e) | +e | −c | — | — | — | 0 |
| precompile settles c+e → WP | — | — | — | — | +c+e | — | 0 |
| `handleBalance` sweeps surplus s | — | — | — | — | −s | — | −s (insurance funding) |
| E consumed by new claim c′ | — | −c′ | 0 | — | — | +c′ | 0 |

E is a real WP-held reserve, not an SP balance item. A double count would require the same IP to be both E (in TS) and B (in the SP) — and that requires a value transfer from the WP to the SP, which does not exist in the deployed code.

### 2.5 Pass-3's other premise ("handleUnstake over-unstakes a whole 2,048-IP chunk") is also inaccurate

`Delegator._calculateInstantUnstakeAmount()` (lines 465–496) allows **partial** unstaking of a flexible delegation whenever the remainder stays ≥ the precompile `minStakeAmount()` = **1,024 IP**. A whole delegation is only taken when the remainder would fall below 1,024 IP, or when a **bonded** queue entry is dequeued (whole entry). On the live fork, a 3,000 IP stake → full unstake produced `excessUnstake = 0` and a partial flexible unstake, not a 2,048-IP over-unstake. E is therefore rare and bounded; when it does occur, it is reserved by the WP.

---

## 3. Live-state assessment (block 23,624,317)

### 3.1 Addresses, code, roles

| Role | Address | Code / verified | Notes |
|---|---|---|---|
| StakePool proxy | `0xf6701A6A20639f0E765bA7FF66FD4f49815F1a27` | 130 B proxy, impl `0x3dbe57a6…2698` verified (StakePool, 19.4 KB) | EIP-1967 admin slot 0; no UUPS selectors → immutable |
| vIP proxy | `0x5267F7eE069CEB3D8F1c760c215569b79d0685aD` | impl `0xA322C273…8288` unverified, 14.6 KB | mint/burn gated (see §4) |
| WithdrawalPool proxy | `0x2a7935E926C65Ef2671D5807760e2421adf992d8` | impl `0x8512eed9…c9e2` unverified, 14.8 KB | v2.0.0; decompiled `analysis/wp-decompiled.sol` |
| Delegator proxy | `0xB47Aedf533cc3c1651a8Af2312Fe55e317006821` | impl `0x3A938977…3252` verified (41.8 KB) | immutable |
| ComponentSelector | `0x20Cb9DCb6FC306c31325bdA6221AA5e067B9Da51` | impl `0xe174935b…c8c` verified | all setters `onlyAdmin` |
| RewardPool | `0x3bDcB577C21a36f66816bE3D5d8C311419EC3975` | impl `0x6034fb27…bb6a` unverified | 83,613.99 IP; 16% fee to treasury; `claimRewards()` onlyStakePool |
| WP InsurancePool | `0x22dF4eF4Ebe13755Dcb719945596F94A72C8Ebc4` | impl `0xCB5E…5713` unverified | 263.58 IP; 25,000 IP cap; `claim()` onlyWithdrawalPool |
| Delegator InsurancePool | `0x01075765071baC590168C55B40D46DAFbf8BD1bA` | 130 B proxy | 98 IP; pays the 1 IP precompile fee |
| Treasury | `0x08721C44915969aeB1f04817C92B0F8EA62d5096` | EOA | receives 16% RP fee and burn-fee vIP |
| Admin | `0xc64129116e6906686a39e7a6Be633a5A3EF5B7B8` | verified **TimelockController** | `getMinDelay()` = **300 s** |
| Owner | `0x0f0172E30795958dA86f068F80A1743Df1955e16` | **EOA (codesize 0)** | owner of SP, WP, vIP, Delegator, Selector, RewardPool and both insurance pools |

`paused()` = false on SP, WP, RP, Delegator, Selector.

### 3.2 Balances and ledger (exact)

| Call (all at block 23,624,317) | Value |
|---|---|
| `stakePool.getTotalStake()` | 15,474,068.229533032746969505 IP |
| `stakePool.getUnstaked()` (E) | **0** |
| `stakePool.getPendingUnstake()` (P) | 1,469.357216360810924995 IP |
| `delegator.getGlobalDistributionTotal()` (D) | 15,475,537.586749393557894500 IP |
| `stakePool.getStakePoolAmount()` / `address(SP).balance` | 1,845.402511830810000000 IP |
| NAV = TS + B | 15,475,913.632044863556969505 IP |
| `vIP.totalSupply()` / `getTotalSupply()` | 13,675,004.869990373338040218 vIP (equal) |
| rate | **1.131693464037191087 IP/vIP** |
| `withdrawalPool.getTotalWithdrawalPool()` | **0** |
| `withdrawalPool.getTotalPendingWithdrawals()` | **6,665.841927501986166900 IP** |
| WP InsurancePool balance | 263.583953655634299353 IP |
| WP InsurancePool remaining capacity (0x14a6bf0f) | 24,736.416046344365700647 IP |
| RewardPool balance | 83,613.991616934000000000 IP |
| Delegator unstake queue | 2,316.341756343325680771 IP (validator `0x033923af…ff60`, flexible; `nextUnstake` 1,757,794,721 is in the past) |
| Delegator native balance | 0 |

Ledger identity is exact: `15,474,068.229533032746969505 = 15,475,537.586749393557894500 + 0 − 1,469.357216360810924995`.

### 3.3 Parameters

`delegationSize` = 2,048 IP · `unbondingPeriod` = 1,382,400 s (16 days) · `minStake` = 0.001 IP · precompile `minStakeAmount()` = 1,024 IP · precompile `fee()` = 1 IP · `mintFeeBps` = 0 (disabled) · `burnFeeBps` = **10 (0.1%)**, enabled · `maxStake` = 20,480 IP · `maxStakeIterations` = 20.

### 3.4 WP queue composition (event reconciliation)

939 `WithdrawalAdded` events (1,570,955.7704669673 IP) − 743 `WithdrawalClaimed` events (1,564,289.9285394654 IP) = **6,665.841927501987 IP**, matching `getTotalPendingWithdrawals()` to display precision (< 1e-12 IP). The per-recipient ledger is consistent (an early apparent 400,696 IP mismatch was a case-sensitive address join in the analysis script, not a contract anomaly). **114** recipients currently have a non-zero reconstructed balance; the largest five:

| Recipient | Outstanding IP | USD |
|---|---|---|
| `0xedfc6299b8d9d261a8364b6f7bf88cdeb78cc912` | 1,508.5108315993004 | $230.73 |
| `0x1cbc5c23c073117eca2662f57c4e2b4b50bc6d7d` | 1,470.137751742961 | $224.86 |
| `0xd3aaa5197f4cbdf9969e72feb07cb67f2a89ab1f` | 884.2948917745155 | $135.25 |
| `0xc960517dee7a3fc8b1f28481fd82756023d3470d` | 578.6441254147516 | $88.50 |
| `0x37a054353c6f43b3de9d6d19be2117dc0e5c0f2c` | 438.6828393413363 | $67.10 |

Approximately 706.03 IP of the outstanding claims are already past their `unbondedTimestamp` (upper-bound FIFO estimate); the WP holds 0 and the insurance pool 263.58, so ~442 IP of currently-due claims are temporarily unfunded until the overdue Delegator queue (2,316.34 IP) is processed and unbonds. This is a liquidity delay, not a loss: D = 15.47M IP backs the claims.

The WP is a genuine queue, not a share pool: claims are fixed IP amounts with an absolute `unbondedTimestamp = add time + 1,382,400 s`.

---

## 4. What an attacker can / cannot do

### 4.1 Permissionless surface (all non-extractive)

| Call | Auth | Effect | Profit |
|---|---|---|---|
| `SP.stake(bool)` | none | mints vIP at `_calculateVIPMint`, then `_restake()` (claims RP rewards to SP), then delegates in 2,048+ chunks | none; roundtrip loses the 0.1% burn fee |
| `SP.unstake(v)` | vIP holder | burns vIP, records a WP claim, consumes E/P, may call `handleUnstake` | none; −0.1% fee + rounding |
| `SP.evaluateStakePool()` / `SP.restake()` | none | delegates B / claims RP rewards | reward goes pro-rata to all vIP holders |
| `Delegator.handleUnstakeQueue()` | none | submits the queued precompile unstake (1 IP fee from the Delegator's insurance) | none |
| `WP.withdraw()` | own claims | pays `withdrawalsByRecipient[msg.sender]` after `unbondedTimestamp`; pulls from the insurance pool if short | own funds only |
| `SP.fund()`, `WP.fund()`, `InsurancePool.fund()` | none | donations | −100% to the donor (see §4.3) |
| vIP `transfer` | holder | standard ERC20 | none |

### 4.2 Gated (exact revert data)

| Call | Revert | Decoded |
|---|---|---|
| `WP.addWithdrawal(attacker,1,1)` | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |
| `WP.handleBalance()` | `0xf36646ed` + `0xc641…b7b8` + `0xf670…1a27` | `OnlyAdminOrStakePool(admin, stakePool)` |
| `WP.withdraw()` (no claims) | `0x1e205007` | `NoWithdrawalsToProcess()` |
| `vIP.mint(attacker,1e18)` | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |
| `vIP.burn(victim,1e18)` | `0x1d856626` + `0xf670…1a27` + victim | `OnlyStakePoolOrHolder(stakePool, holder)` |
| `WPInsurancePool.claim(1)` | `0x143abd98` + `0x2a79…92d8` | `OnlyWithdrawalPool(withdrawalPool)` |
| `RewardPool.claimRewards()` | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |
| `Delegator.handleUnstake(x)` | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |

### 4.3 Attack-path analysis

**(a) Fresh attacker stakes just before a surplus return, redeems after — can they capture a double-counted amount?**
No. There is no double count to capture: `handleBalance()` never credits the SP, and it reserves E. If the attacker joins before a settlement, their vIP is minted at the pre-settlement NAV; the settlement adds `c + e` to the WP, of which `c` is the existing claim liability and `e` is the E reserve already counted in TS. The SP balance and TS do not move, so the attacker's redemption value is unchanged. The only NAV change at settlement is zero (see the invariant table).

**(b) Can an attacker trigger `handleUnstake` to create E, then exploit?**
`Delegator.handleUnstake` is `onlyStakePool`; only `SP.unstake` can call it. An attacker who holds vIP can create E only by unstaking enough to exhaust the flexible pool or to take a whole bonded entry. E is then held by the WP as a reserve (`handleBalance` reserves it), and the SP's TS includes E while the WP holds the IP — one count, in two places that are both tracked. There is no profit: E is a wash (`D −= c+e`, `E += e`). To force the bonded path, the attacker would need to unstake >14.17M IP (~92% of supply, ~$2.1M), and the result is still a wash minus the 0.1% fee.

*Per-event bound under the false hypothesis (for completeness):* a flexible delegation can over-unstake at most `min(delegation remainder, minStakeAmount) − 1` = 1,023.999… IP (**$156.62**); a bonded entry can over-unstake up to a whole queue entry. The premise that the 2,048-IP `delegationSize` is the over-unstake unit is wrong (partial flexible unstakes are allowed); in any case the amount is not extractable because it is not double counted. Total over the false hypothesis would be bounded by the number of whole-delegation events, not by the pool TVL.

**(c) Rounding / inflation / first-depositor / donation?**
- `calculateVIPMint(1 IP)` → 0.883631506037518992 vIP; `calculateIPWithdrawal` → 0.999999999999999998 IP (−2 wei). The real `unstake()` applies the 0.1% burn fee, so a roundtrip loses ~0.1%.
- Supply is 13.67M vIP, rate 1.1317 — first-depositor inflation is long dead.
- `fund()` donation: a donation D raises the redemption value of a fixed vIP amount by `v/S_effective × D`. The donor's own gain is only its share f·D; with f < 1, the donor loses (1−f)·D. Fork test: donating 10,000 IP raises the redemption value of 1,000 vIP by only **0.731261165540414144 IP**. Not profitable.
- `_calculateVIPMint` floors; `_calculateIPWithdrawal` ceils the post-withdrawal assets, so both round in the pool's favour.

**(d) Can the WP surplus be claimed by a fresh address?**
No. `handleBalance()` is `OnlyAdminOrStakePool`; the surplus goes to the insurance pool, whose `claim()` is `OnlyWithdrawalPool`. A fresh address can only call `WP.withdraw()` against its own recorded claims. The insurance pool's 263.58 IP is only reachable through the WP when a claim is short, and it pays the claimant's fixed amount, not the caller.

**(e) Can the attacker make the WP pay a claim twice?**
`withdraw()` zeroes the caller's `withdrawalsByRecipient` array before paying (decompiled `withdraw()` shows the array length zeroed and `totalPendingWithdrawals` decremented) and uses `transfer` (2,300 gas). Reentrancy is not available; a double claim is not.

### 4.4 Costs

Story gas price at the fork block: **100,000,023 wei (0.1 gwei)**. Measured on the fork: `stake` 186,958 gas, `unstake` 528,514 gas, full test 950,017 gas → a roundtrip costs ~0.0000715 IP ≈ **$0.000011**. Gas is economically irrelevant; the 0.1% burn fee is the binding cost.

### 4.5 Economic bound **even if** the hypothesis were true

This is a second, independent reason the finding is not material, and it does not depend on the mechanism being disproven:

- Per flexible over-unstake event, `E ≤ min(delegation remainder, 1,024) − 1 = 1,023.999… IP = $156.62`. A bonded event can over-unstake a whole queue entry, but the live bonded queues total only 1.3M IP and are not all mature.
- To capture `f·E`, the attacker must hold fraction f of the 13,675,004.87 vIP supply at settlement. Acquiring f of the supply at NAV costs `f × $2,367,041`; exiting costs the 0.1% burn fee, `0.001 × f × $2,367,041`.
- For f = 1 (buy the entire supply, $2.37M), the exit fee alone is **$2,367**, versus a capture of at most **$156.62** from a flexible event. Even a hypothetical whole-bonded-entry E would need to exceed 0.1% of the capital deployed to break even.
- The break-even condition is `E > 0.001 × NAV = $2,367` (the f factor cancels); for any E in the observed range (≤ ~$300 per the pass-3 estimate) this is never satisfied at the current TVL.

So even under the pass-3 hypothesis, the maximum extractable would be **negative** for any attacker who has to acquire vIP at NAV. This is why the finding is closed on economics as well as on mechanism.

---

## 5. PoC / fork verification

**Project:** `poc/` (Foundry, solc 0.8.24, vendored `lib/forge-std`). **Fork:** `vm.createSelectFork(vm.envOr("STORY_RPC_URL", "https://mainnet.storyrpc.io"))` — no key, no archive requirement; the test logs the fork block.

**CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39628623564 — **8/8 tests PASS** at fork block **23,624,468** (2026-10-21T15:46Z). Full log: `ci-log.txt`.

| Test | What it proves |
|---|---|
| `test_ledgerIdentity` | `getTotalStake() == D + E − P` exactly; E = 0; WP balance 0; supply/getTotalSupply equal; rate 1.131693464 |
| `test_handleBalance_goesToInsurancePool_notStakePool` | surplus 5,000 IP → insurance pool +5,000; WP retains `Pw + E`; **SP balance delta 0** |
| `test_handleBalance_reservesExcessUnstake` | with E = 1,000 (storage-injected at the ERC-7201 slot + 9), surplus = 2,000 − E; WP retains `Pw + E`; SP delta 0 |
| `test_realUnstake_noStakePoolCredit` | real `stake(3,000 IP)` → 2,650.894518112556978690 vIP → `unstake` → claim 3,010.606404260803272114 IP (CI block 23,624,468; 3,010.602472426093000343 at local block 23,624,317); E after = 0; simulate settlement → SP balance and TS deltas **0** |
| `test_gating` | all eight gated calls above revert; vIP mint/burn, addWithdrawal, handleBalance, withdraw, insurance claim, reward claim |
| `test_roundtripAndFees` | 1 IP → 0.883631506037518992 vIP → 0.999999999999999998 IP; burnFee 10 bps enabled; mintFee 0 |
| `test_donationUnprofitable` | 10,000 IP donation raises 1,000-vIP redemption by only 0.731261165540414144 IP |
| `test_P_ownerCanBypassTimelock` | EOA owner replaces the timelock admin, retargets `withdrawalPool` and `stakePool`, and calls `Delegator.setWithdrawalAddress()` successfully |

Key numbers (fork block 23,624,468): `stake(3000 IP)` gas 186,958; `unstake` gas 528,514; claim 3,010.606404260803272114 IP; E = 0; SP balance/TS unchanged after the simulated 16-day settlement.

**What the PoC does NOT prove:** the Story consensus-layer unbonding settlement (the 16-day CL withdrawal is off-EVM). The EVM-side authorization and the precompile `setWithdrawalAddress` call are proven; the final mint to the configured withdrawal address is inferred from the precompile interface.

---

## 6. Verdict and residual / latent risk

**Verdict: the pass-3 hypothesis is false. Live E-U from this ledger is $0, high confidence.**

The exact reason is structural, not a matter of current state:
1. `handleBalance()`'s only value-bearing external call is `insurancePool.fund()`; it never calls the StakePool. The destination is the WP InsurancePool (`0x22dF…Ebc4`), a separate contract whose balance is not in the StakePool's `address(this).balance`.
2. `handleBalance()` explicitly subtracts `stakePool.getUnstaked()` (E) before computing the surplus; the WP retains E as a real reserve.
3. The Delegator's precompile withdrawal address is the WP, so unbonded principal never enters the StakePool.
4. `excessUnstake` is 0 live and, even when created, is a wash (`D −= c+e`, `E += e`), not a double count.

**Residual / latent risks (none E-U today):**
- **P-class owner drain (serious):** the owner EOA can bypass the 300 s timelock via `setAdmin` and point the precompile's withdrawal address at an arbitrary contract. This is a $2.38M privileged capability, not an unprivileged path. If the owner key is a team multisig/hardware wallet, the practical risk is lower; the on-chain fact is a single EOA.
- **JIT reward dilution (economic, small):** `stake()` calls `_restake()`, which sweeps the RewardPool's accumulated balance (83,613.99 IP, 16% fee) into the SP pro-rata. A new staker can capture a share. Gross one-shot bound: **19,773 IP ≈ $3,024** at X ≈ 17.49M IP ($2.68M) with a 16-day lock; net of the normal staking yield over the same 16 days the excess is **≤ ~1,192 IP ≈ $182** (and negative for X > ~8M IP). Not counted as E-U.
- **Temporary withdrawal liquidity:** 6,665.84 IP of claims are outstanding against a WP balance of 0; the Delegator queue has 2,316.34 IP (overdue, permissionlessly processable) and P = 1,469.36 IP remains in active delegation. The precompile in-flight amount is not EVM-readable. Claims are paid in order; no permanent loss is evident (H-O, $1,019.54).
- **Full-exit DoS quirk:** if a holder of ~100% of vIP unstakes everything, `ipToWithdraw` includes the SP balance B and can exceed D, making `delegator.handleUnstake(P)` revert (`UnstakeAmountExceedsTotal`). This is a liveness edge for the last holder, not a profit path; a slightly smaller unstake avoids it.
- **Donation trap:** WP donations above `Pw + E + insurance capacity` stay in the WP with no sweep function; they are lost to the donor. Not exploitable.

**Blockers to a higher E-U number:** none of the value in the system is reachable without either (a) holding vIP and accepting the 0.1% fee and 16-day unbonding, (b) the owner key, or (c) a code path that does not exist. The WP/insurance/RP contracts are unverified, so a hidden admin function cannot be excluded by source alone; however, the fork traces and the ABI recovery show no such function on the value paths, and all proxies are immutable.

---

## 7. Methodology & sources

- **State:** `cast call` / `cast balance` / `cast storage` against `https://mainnet.storyrpc.io`, plus a local anvil fork (`anvil --fork-url … --chain-id 1514`). All reads at block 23,624,317 (fork test) or the fork experiments at 23,623,495; values in §3 are from the fork test log at 23,624,317.
- **Source:** datanetscan Blockscout v2 `/api/v2/smart-contracts/<addr>` for StakePool impl (verified), Delegator impl (verified), ComponentSelector impl (verified), proxies (verified), TimelockController (verified). Raw JSON in `analysis/`.
- **Unverified code:** WithdrawalPool impl `0x8512…c9e2`, vIP impl `0xA322…8288`, RewardPool impl `0x6034…bb6a`, insurance impls. Heimdall v0.9.2 decompile + ABI recovery (`analysis/wp-decompiled.sol`, `analysis/wp-impl-abi.json`), plus call-tracer experiments to settle semantics.
- **Events:** datanetscan `/api/v2/addresses/<addr>/logs` for the WP (1,793 logs: 939 added, 743 claimed, 101 funded) and the SP.
- **Price:** DefiLlama `api.llama.fi/protocol/verio` (TVL $2,369,454.98 / 15,491,283.906 IP = $0.15295), timestamp 1792592663.
- **CI:** `bash /home/heisenberg/CA/ci/ci-run.sh verio` → run 39628623564, 8/8 PASS.

### Caveats

1. The public Story RPC does not serve historical state; the "pinned" block is the fork block, and all values in §3 are from the fork test's single batch at 23,624,317. Live values drift by a few IP per hour (claims/rewards).
2. The WP, vIP, RewardPool and insurance implementations are unverified. The decompiler is lossy; the `handleBalance` destination and the E reservation are established by the call trace and exact balance deltas, not by the decompiled text. If a hidden path exists outside these traces, it was not found — confidence is high, not absolute.
3. The P-class owner drain's final CL settlement is inferred from the precompile interface, not executed end-to-end (off-EVM).
4. The JIT reward-dilution number assumes the RewardPool balance at the fork block and a 5% APR opportunity cost; it is an economic bound, not a code exploit.
5. No mempool/front-running analysis was performed; the paths above are state-based.

### Files

```
verio/
├── README.md                     this file
├── summary.json                  machine-readable summary
├── analysis/
│   ├── live-state.md             pinned state table (block 23,624,317)
│   ├── handleBalance-trace.txt   fork call trace + balance deltas
│   ├── gating-and-roles.md       revert selectors, owner/timelock path
│   ├── wp-decompiled.sol         heimdall decompile (lossy) + ABI
│   ├── wp-impl-abi.json          recovered WP ABI
│   ├── wp-events.json            parsed WithdrawalAdded/Claimed events
│   ├── wp-logs.json              parsed WP logs
│   ├── src/                      verified sources (StakePool, Delegator, Selector, proxies)
│   └── *.json                    raw Blockscout responses / bytecode
├── poc/
│   ├── foundry.toml
│   ├── src/Interfaces.sol
│   ├── test/Verio.t.sol          8 tests, all PASS
│   └── lib/forge-std             vendored
├── ci-log.txt                    CI run log (8/8 PASS)
├── ci-out/ · ci-artifacts/       (empty; no custom heavy job)
└── ci/                           (none; workflow runs forge test directly)
```
