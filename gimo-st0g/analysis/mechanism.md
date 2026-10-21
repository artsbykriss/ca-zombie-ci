# Gimo st0G — exact mechanism notes (source-level)

Chain: 0G (chainId 16661). Pinned block **47,841,263** (ts 1,792,595,026, 2026-10-21 ~16:23 UTC).
All conclusions here are drawn from the **verified source**, not from the decompile.

## 1. Source recovery and bytecode identity

The 0G explorer (`chainscan.0g.ai`) is a ConfluxScan-derived SPA: `/api/v2/...` returns HTML and
Sourcify (`sourcify.dev/server/v2/contract/16661/...`) returns `match: null`. The SPA's backend is
`https://chainscan-api.0g.ai` and it *does* serve verified source:

```
GET https://chainscan-api.0g.ai/v1/contract/<address>
 -> result.sourceCode, result.abi, result.verify{name,version,optimization,runs,exactMatch}
```

| contract | address | verified name | solc | opt | runtime bytes | byte-identical after recompile? |
|---|---|---|---|---|---|---|
| StakeManager impl | `0x7a5e1b999a665f2b89e5f6eae32df9471de193c7` | StakeManager | v0.8.19+commit.7dd6d404 | 1 / 200 runs | 16,692 | **yes** (only the 5 `immutable __self` slots differ, patched with the contract address) |
| StakePool impl | `0x377db28b688e7fd84bb99a6a8f8f1084a33bb512` | StakePool | v0.8.19 | 1 / 200 | 7,378 | **yes** (same `__self` patch) |
| LsdToken | `0x7bBC63D01CA42491c3E084C941c3E86e55951404` | LsdToken | v0.8.19 | 1 / 200 | 3,270 | **yes** (0 diffs) |

Recompile = `forge build` of the explorer source blob as a single file with `solc=0.8.19`,
`optimizer=true`, `optimizer_runs=200`, default EVM version. Proof: `ci-out/source_verify.json`
and `ci-out/source_verify.log`.

Upstream lineage: this is a fork of **StaFi Protocol `evm-lsd-contracts`**
(`contracts/staking/StakeManager.sol`, BUSL-1.1). The Gimo deployment **adds** the validator
migration feature (`migrateValidatorBegin`, `adminForceUndelegate`, `adminCompleteMigration`,
`pendingMigration`) and calls `getTotalDelegated(validators)` instead of upstream `getTotalStaked()`.

## 2. Contract map (roles)

```
st0G (LsdToken, plain ERC20)          0x7bBC63D01CA42491c3E084C941c3E86e55951404
  minter = StakeManager proxy         (mint() is onlyMinter; updateMinter() is onlyMinter)
  burn/burnFrom = public ERC20Burnable

StakeManager (UUPS proxy, impl above) 0xAc06d1Df23a4Fa00981aFAC0f33A5936Bd2135aF
  owner / pendingOwner                EOA 0x3007306646AC90A647BEBc9acC029C941Db5B0Fb (no code, nonce 184)
  lsdToken, rate, eraSeconds=86400, eraOffset=20347, latestEra=400
  unbondingDuration=3 eras, rateChangeLimit=0, protocolFeeCommission=0.1e18, minStakeAmount=0.01e18

StakePool (UUPS proxy, impl above)   0x136b56554671976EF8366B01B31185F91Ae696AF
  owner = same EOA; stakeManagerAddress = StakeManager
  validator set = [0xeC856948CF28a7c36E4c0D7877d027bA0a8AF17d]  (single 0G validator)
```

## 3. Money flow

`stake(string memo)` → `stakeWithPool(bondedPools.at(0), memo)` → `stakeWithPoolReceiver`:

```solidity
uint256 lsdTokenAmount = (stakeAmount * 1e18) / rate;      // S.2849
poolInfo.bond  += stakeAmount;                            // S.2852
poolInfo.active += stakeAmount;                           // S.2853
(bool ok,) = _poolAddress.call{value: stakeAmount}("");    // 0G sits in StakePool until next newEra
ILsdToken(lsdToken).mint(_receiver, lsdTokenAmount);      // S.2861
```

`unstake(uint256 shares)` → `unstakeWithPool`:

```solidity
uint256 tokenAmount = (shares * rate) / 1e18;             // S.2871 (floor)
poolInfo.unbond += tokenAmount;
poolInfo.active -= tokenAmount;                           // S.2876
ERC20Burnable(lsdToken).burnFrom(msg.sender, shares);      // requires user -> manager allowance
unstakeAtIndex[nextUnstakeIndex++] = {era: currentEra(), pool, receiver: msg.sender, amount: tokenAmount};
```

`withdraw()` pays only records whose `era + unbondingDuration <= currentEra`, removes them from the
user's `EnumerableSet` **before** paying, then calls `IStakePool.withdrawForStaker(msg.sender, total)`
(S.2893-2919). `withdrawForStaker` is `onlyStakeManager` and pays from the pool's plain 0G balance
(`StakePool.sol:1179`).

## 4. `newEra()` — exact math

```solidity
function newEra() external {                                   // S.2922  (no args, no access control)
    uint256 _era = latestEra + 1;
    if (currentEra() < _era) revert EraNotMatch();              // at most once per era; may be late
    latestEra = _era;

    uint256 totalNewReward; uint256 newTotalActive;
    for (pool in getBondedPools()) {
        IStakePool(pool).updateValidators(validators);          // 1 gwei/validator, reservedFee
        if (poolInfo.bond > poolInfo.unbond) delegateMulti(validators, bond - unbond);
        else if (bond < unbond)              undelegateMulti(validators, unbond - bond);

        uint256 newPoolActive = IStakePool(pool).getTotalDelegated(validators)
                              + pendingMigration[pool];         // S.2959
        newTotalActive += newPoolActive;
        uint256 poolNewReward = newPoolActive > poolInfo.active
                              ? newPoolActive - poolInfo.active : 0;
        totalNewReward += poolNewReward;
        poolInfo = {era: latestEra, active: newPoolActive, bond: 0, unbond: 0};
    }
    _distributeReward(totalNewReward, rate);                    // mints 10% of reward as fee shares
    uint256 newRate = _calRate(newTotalActive, ERC20(lsdToken).totalSupply());
    _setEraRate(_era, newRate);
    emit ExecuteNewEra(_era, newRate);
}
```

`getTotalDelegated` (`StakePool.sol:1064`) = `Σ getDelegated(validator) + pendingBond`, and
`getDelegated(v) = v.getDelegation(pool).shares * v.tokens() / v.delegatorShares()`
(`StakePool.sol:1050`). `pendingBond` only holds sub-1-gwei dust; the pool's **plain 0G balance is
not counted**, so plain transfers/donations to the pool cannot move the rate (verified on fork).

`_calRate` (`S.2188`):

```solidity
if (_totalLst == 0) return 1e18;
uint256 calRate = (_totalActive * 1e18) / _totalLst;   // floor
if (calRate < 1e18 && 1e18 - calRate < 5000) calRate = 1e18;   // dust clamp near 1.0
return calRate;
```

`_setEraRate` (`S.2178`):

```solidity
if (rateChangeLimit > 0) {
    uint256 rateChange = _rate > rate ? _rate - rate : rate - _rate;
    if ((rateChange * 1e18) / rate > rateChangeLimit) revert RateChangeExceedLimit(...);
}
rate = _rate; eraRate[_era] = _rate;
```

**`rateChangeLimit` semantics:** a *relative per-era* cap in 1e18 units, enforced on |Δrate|/rate.
`MAX_RATE_CHANGE_LIMIT = 5e15` (0.5%). **The live value is 0, and 0 disables the check entirely** —
there is currently no per-era cap on how far the rate can move in a single `newEra`.

`_distributeReward` (`S.2596`): `feeShares = totalNewReward * protocolFeeCommission / rate` (st0G),
`totalProtocolFee += feeShares`, `lsdToken.mint(address(this), feeShares)`. It is minted **before**
`totalSupply()` is read for the new rate, so the fee is inside the new rate.

So the rate is exactly `(validator-delegated 0G + migration-in-transit) / st0G supply` at each era
boundary, and the only thing that can raise it is a real increase in delegated 0G (staking rewards)
or the owner-driven migration accounting.

## 5. The only value-transfer edge: last-minute stake before a rate update

Because `stake()` mints at the stored rate and `newEra()` republishes
`rate = (A + R) / (S + X/r0)` where `R` is the reward that accrued **on the pre-existing active set**,
a deposit made between two `newEra` calls gets `f = s/(S+s)` of the era reward it did not earn:

```
profit = f * (1 - protocolFeeCommission) * R        f = (X/r0) / (S + X/r0)
cost   = the 3-era unbonding lock (unstake fixes the claim in 0G at the current rate)
```

Live numbers (block 47,841,263): `R = 5,751.61 0G/era = $1,409.87/day`, NAV yield 10.84%/yr.
Measured in a fork (`test_jit_capture_of_one_era_reward`, measured counterfactual):

| | value |
|---|---|
| capital X | 19,370,546 0G (1.0× TVL) |
| attacker PnL | **2,587.91 0G** ($634.44) |
| holder loss | 2,587.83 0G (value conserved, remainder = protocol fee) |
| return per 3-era cycle | 1.34 bp → **1.63%/yr annualised** |
| honest staking over the same 3 eras | 4.01 bp → 10.84%/yr |

Return falls as capital grows (0.30%/yr at 10× TVL). The strategy is **dominated by simply staying
staked** at every size, so a rational unprivileged actor has no reason to run it. It only becomes
profitable if the reward accumulated between two updates is ≥ ~4 eras (see §6).

## 6. Keeper cadence (the condition that matters)

`ExecuteNewEra(era, rate)` logs, eras 369→400 (32 consecutive eras): `dt` between consecutive calls
**86,395–86,405 s**, and each call lands **12–17 s after its era boundary**. The keeper is a
permissionless crank that anyone can also call, so the accumulation window is one era. There is no
way for an attacker to lengthen it (no revert vector found: `undelegateMulti` always has enough
delegation because `delegated ≥ unbond − bond`, and `reservedFee` has ~9,388 eras of runway).

If the crank ever stops for N eras, the next call publishes `N × R` at once (no cap, §4), and the
JIT profit becomes `f × 0.9 × N × R`. Break-even vs honest staking is N ≈ 3.3; at N = 10 an
attacker with capital ≫ TVL captures ≈ 51,764 0G ≈ **$12.7k** per 3-day cycle.

## 7. Things that were checked and do NOT work

* **Donation to the StakePool** (`receive()` accepts plain 0G): not in `getTotalDelegated`, not in
  `pendingBond` → no rate move (fork test).
* **Donation to the validator**: would raise `tokens()/delegatorShares`, but the pool only owns
  26.43% of the validator, so a donor recovers ≤26.4% of any donation through their st0G — always a loss.
* **Round trip stake→unstake**: 1,000 0G → 738.176558919354845257 st0G → 999.999999999999999999 0G
  (**−1 wei**, both divisions floor).
* **Mint st0G out of thin air**: `mint` is `onlyMinter`, minter is the manager; `updateMinter` is
  `onlyMinter`; a stranger call reverts `CallerNotAllowed()` (0x2af07d20).
* **Double withdraw / premature withdraw / fake pool in `withdrawWithPool`**: all revert
  (`ZeroWithdrawAmount`, `AlreadyWithdrawed`); the record is removed before the payout and the payout
  address is hard-coded to `msg.sender`.
* **Steal another user's unstake record**: records are keyed by `msg.sender`; `receiver` is not used
  for payment.
* **Unstake without allowance**: `burnFrom` needs the user's approval to the manager; without it the
  whole tx reverts.

## 8. Solvency at the pin block

```
assets      = getTotalDelegated 19,370,670.5378 + pool balance 15,887.7574 = 19,386,558.2952 0G
st0G claim  = active 19,370,546.3769 0G
open claims = 17,013.9705 0G   (matured 15,816.8831 across 2,863 records; unmatured 1,197.0873)
pool liquid = 15,887.7574 0G   -> 99.55% of it is already earmarked for matured claims
```

The 1,002.05 0G difference between "assets minus st0G claim" and open claims is exactly the amount
undelegated at `newEra(400)` that is still inside the 0G validator unbonding queue. Matured claims
are fully covered; unmatured claims depend on the validator unbonding returning funds within the
3-era `unbondingDuration`. Withdrawals have been working (5,211 of 7,211 records already withdrawn).
