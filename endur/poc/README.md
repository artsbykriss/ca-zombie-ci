# Endur — PoC approach (Starknet)

Starknet has no Foundry/anvil fork harness, so the PoC is a **live, read-only call harness**
rather than a Solidity fork test. It is exactly equivalent in force for this target:

1. **Gate tests** — for every value-moving / config entry point, issue `starknet_call` with an
   arbitrary (zero) caller and record the revert. An unprivileged attacker cannot invoke them.
   Evidence: `ci-out/endur-checks.json` → `gate_reverts`.
   - `vault.send_to_withdraw_queue`, `vault.set_config`, `vault.upgrade` → `Caller does not have role`
   - `vault.before_unstake` → `invalid validator`
   - `queue.request_withdrawal` → `Only LST can call`
   - `queue.claim_withdrawal` → `Too early to claim` / `ERC721: invalid token ID`
2. **Share-math roundtrip** — `convert_to_shares` then `convert_to_assets` for 1 STRK and
   1,000 STRK; assert the result is **≤** input (no value created). Observed: −1 / −2 wei.
3. **Backing reconciliation** — sum `get_validator_token_info` staked amounts across the
   registry's validators and assert it covers `total_assets`.

The harness runs on GitHub Actions (`../ci/run.sh`) and writes `../ci-out/endur-checks.json`.

`starknet_simulateTransactions` is supported by the public RPC and was available if a
state-changing simulation were needed, but every candidate path was already closed by a static
gate, so no simulation was required.

No transaction is ever signed or broadcast. All calls are `starknet_call` (view context).
