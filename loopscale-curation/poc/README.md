# Loopscale Curation PoC (Solana, read-only)

No Foundry/EVM project: the target is a Solana BPF program, so the PoC is a read-only
JSON-RPC harness.

- `../analysis/loopscale_probe.py` — live vault enumeration, curator-role extraction, gating
  simulation matrix (`simulateTransaction {sigVerify:false, replaceRecentBlockhash:true}`).
- `../analysis/exponent_gating.py`, `../analysis/exponent_ixscan.py` — instruction-tag recovery
  and per-tag neutral-signer replay.
- CI runs `../ci/run.sh`; results land in `../ci-out/`.

    cd .. && OUT=ci-out/loopscale_results.json python3 analysis/loopscale_probe.py

Read-only; no transaction signed or sent.
