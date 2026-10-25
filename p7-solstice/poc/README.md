# PoC — Solana, non-EVM

There is **no Foundry project** here: the target (Solstice YieldVault on Solana) is a Solana BPF
program, not EVM, so `forge test` is not applicable.

The PoC is a **read-only `simulateTransaction` harness** under `../analysis/`:

- `../analysis/sim.py` — builds **unsigned** legacy transactions (shortvec sig-count + zero signature
  placeholders + compiled message) and submits them with
  `{"sigVerify": false, "replaceRecentBlockhash": true}`; reads post-simulation account state via the
  `accounts` config. **No transaction is signed or sent.**
- `../analysis/probe_*.py` — the probe matrix (unlock, double-unlock, lock, round-trip, withdraw,
  substitution, `transfer_in_yield` gate, dust, cooldown branches).
- `../ci/run.sh` + `../ci/collect.py` — the same probes re-run on GitHub Actions; results in
  `../ci-out/`.

Rerun locally (light RPC reads only):

```bash
cd p7-solstice
export SOLANA_RPC="https://api.mainnet-beta.solana.com"
python3 -u analysis/probe_unlock.py all
python3 -u analysis/probe2.py
```
