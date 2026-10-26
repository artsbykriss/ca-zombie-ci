#!/usr/bin/env bash
# Heavy job for the SudoGovernor PoC. Runs the Foundry suite and captures the
# full output (with console logs) into ci-out/ so it is uploaded as an artifact.
# READ-ONLY: the suite only forks mainnet; no transaction is ever sent.
set -uo pipefail

mkdir -p ci-out
cd poc || exit 1

echo "[ci] forge version: $(forge --version | head -1)"
forge test -vvv 2>&1 | tee ../ci-out/forge-test.log
rc=${PIPESTATUS[0]}

# Extract the key numbers for a compact machine-readable artifact.
{
  echo "{"
  echo "  \"suite_exit_code\": ${rc},"
  echo "  \"generated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"note\": \"see forge-test.log for full console output\""
  echo "}"
} > ../ci-out/poc-summary.json

echo "[ci] forge test exit code: ${rc}"
exit ${rc}
