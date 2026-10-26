# CI for cirbtc

No custom heavy job is required. The generic CI workflow
(`artsbykriss/ca-zombie-ci` → `.github/workflows/poc.yml`) runs `forge test -vvv` from `poc/` whenever
`poc/foundry.toml` exists, which is the whole job here (a light 9-test fork suite).

Run it with:

```bash
bash /home/heisenberg/CA/ci/ci-run.sh cirbtc
```

The Ethereum fork RPC is supplied by the workflow as `FORK_RPC_URL` (public fallback
`https://ethereum-rpc.publicnode.com`). Results land in `ci-log.txt` / `ci-artifacts/`; the run URL is
recorded in `summary.json` (`poc.ci_run_urls`).
