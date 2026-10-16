# CI results — Z3-C1 UNCX Vesting V2 deep-dive

Run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38826471606 (conclusion: **success**)
Workflow: `poc.yml` on branch `uncx-vesting` of `artsbykriss/ca-zombie-ci` (public)
Command: `forge test -vvv` in `uncx-vesting/poc`

Result: **11 passed, 0 failed, 0 skipped** (12.24 s)

```
[PASS] test_A1_liveContainmentParams()            (gas: 68709)
[PASS] test_A2_freshAttackerCreationBlocked()     (gas: 472096)
[PASS] test_A3_allIncidentSchedulesDrained()      (gas: 2677697)
[PASS] test_A4_cancelledSchedulesCannotBeReManipulated() (gas: 425052)
[PASS] test_A5_noFeeExemptionsRemain()            (gas: 11329)
[PASS] test_A6_residualPoolsForHolders()          (gas: 50756)
[PASS] test_B1_replayRealExploitTx()              (gas: 10864490)
[PASS] test_C1_secondaryFullRecipe()              (gas: 2778153)
[PASS] test_C2_airdropSingleFlatFee()             (gas: 2565398)
[PASS] test_C2_secondaryEconomicsDead()           (gas: 49581)
[PASS] test_C3_secondaryAddressIsLiveCode()       (gas: 20844)
```

Key outputs (from the run log, `../ci-log.txt`):
- Historical replay (fork at block 26,191,744) reproduces the real attack's exact post-state:
  EDGEN balance `32,941,964,644` wei, `totalShares[EDGEN] = 17,572,899`, `nextVestingId = 5069`.
- Secondary 14.4 KB deployment (live code): full recipe profit **56,862,375,487,197,786,112,020,902**
  tokens on a simulated 57.34M-token victim pool (pool left `32,909,024,364` wei).
- Airdrop single-flat-fee variant: profit **7,222,730,346,054,289,891,786,066** tokens.
- Real secondary pool: `4,735,964` USDC (6dp) vs `100 ETH` flat fee → not viable.

No secrets: the CI repo is public; only public chain data, verified sources and keyless RPC URLs are committed.
