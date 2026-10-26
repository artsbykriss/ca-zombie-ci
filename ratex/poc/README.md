# RateX PoC (Solana, read-only)

There is no Foundry/EVM project here: RateX is a Solana BPF program, so the "PoC" is a
read-only JSON-RPC simulation harness rather than a fork test.

- Harness: `../analysis/ratex_probe.py` (self-contained; stdlib only) + `../analysis/soltx.py`
  (legacy-message builder) + `../analysis/solrpc.py` (keyless public RPC).
- It reads live state and runs the attacker simulation matrix with
  `simulateTransaction {sigVerify:false, replaceRecentBlockhash:true}`.
- CI runs it via `../ci/run.sh`; results land in `../ci-out/ratex_results.json`.

Run locally:

    cd .. && OUT=ci-out/ratex_results.json python3 analysis/ratex_probe.py

No transaction is signed or sent; all calls are read-only / simulation.
