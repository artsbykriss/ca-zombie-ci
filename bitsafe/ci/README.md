# `ci/` — heavy job

`ci/run.sh` runs on GitHub Actions (public repo `artsbykriss/ca-zombie-ci`) via
`bash /home/heisenberg/CA/ci/ci-run.sh bitsafe`. It performs the one heavy,
enumeration-style task for this target:

1. `python3 analysis/verify_derivation.py` — re-derives all 728 deposit addresses
   from the published xpub + deposit ids and asserts 728/728 match (pure Python,
   no pip dependencies).
2. `python3 analysis/scan.py` — ~1,000+ read-only Esplora calls (one per address
   plus spend history) to sum the reserve and decode every spend witness.

Both are read-only and use **keyless public endpoints** only
(`mempool.space`, `blockstream.info`, `api.mainnet.bitsafe.finance`,
`coins.llama.fi`). No secrets are read or written. Results land in `../ci-out/`.

Locally (light) work only: a `SCAN_LIMIT=<n>` env var lets `analysis/scan.py`
run against a small prefix of addresses for smoke tests.
