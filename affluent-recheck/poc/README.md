# PoC — Affluent (TON) redeem-leg probe (TVM emulation, no Foundry)

Foundry/EVM cannot execute TVM, so the PoC is a **read-only TVM emulation harness**, not a
Foundry project. It executes the live vault code/data with crafted burn messages via
`POST https://tonapi.io/v2/traces/emulate`; nothing is signed or broadcast.

## What it proves

- The CA2 mint primitive is real: `0x7362d09c` → pool → `0xa1b21e8b` → vault mints
  `0x178d4519` with `from=""`.
- The **redeem leg is empty**: every burn (1 raw … 1e16, both vaults) returns a
  `0x178d4519` mint-back of the same amount (refund) and **no** `0x0f8a7ea5` /
  `0xb2a4c51b` / `0xcb03bfaf` asset payout.

## Run

```bash
# from the folder root
python3 analysis/recheck.py          # live: NAV + 10 burn emulations -> ci-out/
python3 analysis/verify_saved.py     # offline: verify saved traces -> ci-out/verify_saved.json
```

Requires `pytoniq-core` and `requests` (`pip install pytoniq-core requests`). Public keyless
endpoints only (`toncenter.com/api/v3`, `tonapi.io/v2`, `coins.llama.fi`). No API keys, no
`.env`, no keyed RPC URLs.

## Evidence

- `ci-out/trace_affUSDTl_*.json`, `ci-out/trace_affTONl_*.json` — 10 fresh emulations, all
  refund-only.
- `analysis/emul/hist_oct16_trace.json` — the one historical payout (13,824,934,818 raw USD,
  plus 5,697,376,531,863,130 shares refunded).
- `analysis/emul/recheck_att_5e15.json` — the exact 2026-10-16 attacker wallet burning its
  remaining 5.697e15 shares: refund only.
- `analysis/vault_snapshot.json` — NAV arithmetic and pool positions.

## Why there is no `foundry.toml`

The target is TON/TVM. A Foundry project would not exercise the vault code. The CI job
(`ci/run.sh`) runs this harness instead; the workflow skips `forge test` when no
`foundry.toml` is present.
