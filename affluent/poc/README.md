# PoC — Affluent (TON) unbacked-mint path, local TVM emulation

**Read-only.** No transaction is signed or sent. No private keys, no keyed RPC URLs.
All PoCs emulate messages against **live account state fetched from TON lite servers**
using the native TON transaction emulator (`tonpy`, public PyPI).

There is **no Foundry project** here: TON is not EVM, so `poc/foundry.toml` is
intentionally absent (the CI workflow skips `forge test`). The heavy job runs
`ci/run.sh` instead.

## Files
- `../ci/ton_emu.py` — self-contained harness (pool + vaults + positive control). Writes `ci-out/ton_emu_results.json`.
- `ton_emu.py` — copy of the harness (same as `../ci/ton_emu.py`).
- `emu_local.py` — early variant: forged notify on BasicPool, storage-hash diff.
- `emu_payload.py` — forged notify with the **real incident forward payload** and honest `src`.
- `emu_realctl.py` — **positive control**: replays real BasicPool inbound messages to prove the harness detects storage writes.
- `getmethods.py` — get-method reader (tonapi).

## The test
A "credit" (unbacked mint) requires the target contract to **write its storage**.
Each run emulates one inbound internal message against the live account and compares
the account's `data` (storage) cell hash before vs after.

- Forged `jetton_notify` (`op=0x7362d09c`) from an arbitrary wallet → **storage unchanged**
  (amounts 0 / 1e12 / 1e18; with and without the real forward payload; sender = attacker,
  a vault, or even the pool's own asset jetton wallet).
- Forged `provide_aggregated_data` (`0xb0c69ffe`) deposit/withdraw on the vaults → **storage unchanged**.
- Positive control: **13 / 16 real BasicPool inbound messages DO change storage** → the harness works.

## Run
```
pip install "tonpy==0.0.0.1.4rc0"
TON_EMU_OUT=./ci-out python3 ton_emu.py
```

## Decisive chain (`ton_chain.py`)
1. Forge the exact 2026-10-16 exploit `jetton_notify` body to the verified **BasicPool** from an arbitrary wallet
   → pool **accepts** it and relays `0xa1b21e8b` to the affUSDTl LendingVault.
2. Feed that relay to the vault → **vault storage changes (unbacked share mint)**.
3. Feed the same body to the vault from an arbitrary sender → **rejected** (pool is the necessary trusted hop).

Result (live, 2026-10-22): `step1_pool_relayed_0xa1b21e8b=True`, `step2_vault_storage_changed_from_pool=True`,
`step3_vault_storage_changed_from_attacker=False`.
