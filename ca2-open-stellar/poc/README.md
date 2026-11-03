# PoC note — no EVM contracts

This finding is a Stellar/Soroban share vault, so there is no Foundry project here.

The executable PoC is:
- `analysis/stellar_checks.py` — read-only live-state reads and `simulateTransaction`
  record-mode probes for every privileged and value-moving entry point (no signing,
  no submission), and
- `ci/run.sh` — reproduces the pinned upstream release build (Rust 1.95.0,
  wasm32v1-none, Stellar CLI 25.1.0) and compares the SHA-256 with the on-chain WASM.

Outputs land in `ci-out/`.
