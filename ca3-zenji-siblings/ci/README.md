# CI notes

Heavy work for this folder is the Foundry fork suite in `poc/` (16 tests, ~96 s on the runner).
The shared workflow (`.github/workflows/poc.yml` in `artsbykriss/ca-zombie-ci`) runs it directly:

    forge test -vvv      # from ca3-zenji-siblings/poc

No custom `ci/run.sh` is needed, so there is no duplicate run. Fork RPCs are read from the
environment (`BLOCKPI_RPC_URL`, `HIST_RPC`, `LIVE_RPC`, `FORK_RPC_URL`) with keyless public
fallbacks; **no key or keyed URL is stored in this folder**.

Run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42736795389  (16/16 PASS)
