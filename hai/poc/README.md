# Foundry PoC status

`HaiGovernance.t.sol` contains a fork test for the two executions proven in
`ci/verify_state.py`. It is kept for reproducibility but is **not run in CI**:
Foundry 1.8.5's `op-revm` panics on OP Mainnet post-Isthmus blocks with
`Missing operator fee scalar for isthmus L1 Block` before any test code runs.
`foundry.toml` is therefore disabled (`.disabled`).

The equivalent, working proof uses `eth_call` with a code override
(`ci/verify_state.py`, `ci/harness_code.txt`):
1. hardening proposal executes permissionlessly -> 5% / 20k / 432,000s;
2. the exact attacker Safe payload, sent as the Timelock (Safe owner), delegates
   327,643.981253588267391953 KITE to 0x1472934131f7af94f3cf2542b6121a44d236cf39.
