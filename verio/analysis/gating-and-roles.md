# Gating and privileged paths (fork-verified, block 23,624,3xx)

All calls are `eth_call` / `anvil` fork calls. No mainnet tx.

## Unprivileged calls that revert (exact revert data)

| Call | Caller | Revert selector | Decoded |
|---|---|---|---|
| `WP.addWithdrawal(attacker,1,1)` | fresh EOA | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |
| `WP.handleBalance()` | fresh EOA | `0xf36646ed` + `0xc641…b7b8` + `0xf670…1a27` | `OnlyAdminOrStakePool(admin, stakePool)` |
| `WP.withdraw()` | fresh EOA | `0x1e205007` | `NoWithdrawalsToProcess()` |
| `vIP.mint(attacker,1e18)` | fresh EOA | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |
| `vIP.burn(victim,1e18)` | fresh EOA | `0x1d856626` + `0xf670…1a27` + victim | `OnlyStakePoolOrHolder(stakePool, holder)` |
| `WPInsurancePool.claim(1)` | fresh EOA | `0x143abd98` + `0x2a79…92d8` | `OnlyWithdrawalPool(withdrawalPool)` |
| `RewardPool.claimRewards()` | fresh EOA | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` |
| `Delegator.handleUnstake(x)` | fresh EOA | `0x8622fd9d` + `0xf670…1a27` | `OnlyStakePool(stakePool)` (source: `onlyStakePool`) |

## Permissionless surface (all non-extractive)

`stake(bool)`, `unstake(uint256)`, `evaluateStakePool()`, `restake()`,
`Delegator.handleUnstakeQueue()`, `WP.withdraw()` (own claims only),
`SP.fund()`, `WP.fund()`, `WPInsurancePool.fund()`, ERC20 `transfer`.

`stake()` charges no mint fee; `unstake()` charges a 10 bps burn fee which is
**minted to the treasury as vIP** (not deducted from the IP claim directly):

```
burnFee = vIPAmount * 10 / 10000
ipToWithdraw = _calculateIPWithdrawal(vIPAmount - burnFee)
vIP.mint(treasury, burnFee); vIP.burn(user, vIPAmount)
```

Roundtrip measured by the fork test: 1 IP → 0.883631506037518992 vIP →
0.999999999999999998 IP (view path, −2 wei). The real `unstake()` additionally
costs 0.1% (the burn fee), so a roundtrip is ~0.1% negative.

## P-class: EOA owner can bypass the 5-minute timelock

- `owner()` on StakePool, WithdrawalPool, vIP, Delegator, ComponentSelector,
  RewardPool = `0x0f0172E30795958dA86f068F80A1743Df1955e16`, **codesize 0 (EOA)**.
- `getAdmin()` on the same contracts = `0xc641…b7b8`, a verified
  **TimelockController** with `getMinDelay() = 300` seconds.
- `setAdmin(address)` on every component is `onlyOwner` (verified StakePool source
  and `VerioComponent`), so the EOA owner can replace the timelock admin with itself
  in one transaction.

Fork proof (`poc/test/Verio.t.sol::test_P_ownerCanBypassTimelock`, passes):

1. `vm.prank(OWNER); SEL.setAdmin(OWNER)` → `SEL.getAdmin() == OWNER`.
2. `SEL.setWithdrawalPool(malicious)` with a contract exposing `getVersion()` →
   `SEL.withdrawalPool() == malicious`.
3. `SEL.setStakePool(malicious2)` → `SEL.stakePool() == malicious2`.
4. `DEL.setAdmin(OWNER)` → `DEL.getAdmin() == OWNER`.
5. `DEL.setWithdrawalAddress()` succeeds (94,179 gas on the fork); because the
   Delegator reads `_selector().withdrawalPool()`, this points the Story staking
   precompile's withdrawal address at the malicious contract from step 2.

A contract registered as `stakePool` (step 3) can then call
`DEL.handleUnstake(D)` (`onlyStakePool`), and `DEL.handleUnstakeQueue()` (permissionless)
submits the precompile `unstake`; after the protocol's 16-day unbonding the IP is
minted to the malicious `withdrawalPool` address. This is a **privileged full-drain
capability over the delegated principal** (15.47M IP ≈ $2.37M), not an E-U path.
Final CL settlement cannot be simulated on an EVM fork; the authorization and the
withdrawal-address change are proven, the settlement is inferred from the precompile
interface (`setWithdrawalAddress` semantics).

The same owner can also `SP.setAdmin(owner)` and change `minStake`/`delegationSize`/
fees, or `REDELEGATE`/pause; none of that is needed for the drain above.

## Timelock roles

`PROPOSER_ROLE` = `0xb09aa5ae…9cc1`, `EXECUTOR_ROLE` = `0xd8aa0f31…9e63`,
`CANCELLER_ROLE` = `0xfd643c72…f783`, `DEFAULT_ADMIN_ROLE` = `0x00…00`.
`hasRole` holders were not enumerated (not needed for the E-U verdict); the owner
bypass makes the role set moot for the drain path.
