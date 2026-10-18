No custom `ci/run.sh` job for this finding. The heavy work is the Foundry fork suite in
`poc/`, run by the shared CI workflow (`forge test -vvv`). Results are in `ci-log.txt` and
`ci-artifacts/`; the run URL is recorded in `summary.json` and the top-level README.
