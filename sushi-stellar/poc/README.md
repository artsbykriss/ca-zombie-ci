# poc/ — why there is no Foundry/Rust exploit harness here

Soroban (Stellar) is **not EVM** and has **no local fork / anvil equivalent**. There is therefore no
Foundry PoC for this finding. The read-only, execution-faithful substitute used instead is:

- **`simulateTransaction`** against mainnet state via the keyless Soroban RPC
  `https://mainnet.sorobanrpc.com`. This executes the *real deployed contract logic* on the *real
  ledger state* and returns (a) the result, (b) diagnostic events, and (c) the **required
  authorization entries** — i.e. exactly *who must sign*. It does **not** apply state, does **not**
  sign, and does **not** broadcast.

This is sufficient to answer the question "can an unprivileged attacker call this and get value
out?" without ever sending a transaction:

- if a call's required auth targets the attacker's own account (or nothing), it is unprivileged;
- if it targets a contract (the factory, the PositionManager, the FlashExecutor) or the owner/admin
  account, an external caller cannot produce it.

All probes live in `../analysis/probe_auth.py`, `../analysis/probe_router.py` and the self-contained
CI job `../ci/verify.py` (run by `../ci/run.sh`). See `../README.md` §5 for the full result table.

**No transaction was signed or sent at any point.**
