#!/usr/bin/env bash
# Custom CI job for geist-finance: enumerate all current borrowers + health factors.
# Heavy RPC work; runs on the GitHub runner (FANTOM_RPC_URL secret is non-functional,
# so the script falls back to keyless public endpoints).
set -uo pipefail
cd "$(dirname "$0")/.."   # geist-finance/
mkdir -p ci-out
# make the later `forge test` step resilient to public-RPC rate limiting
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "FOUNDRY_FORK_RETRIES=12" >> "$GITHUB_ENV"
  echo "FOUNDRY_FORK_RETRY_BACKOFF=3000" >> "$GITHUB_ENV"
  # the FANTOM_RPC_URL secret is non-functional; use the dRPC key for the fork tests
  # (value is masked in logs by GitHub; never written to any repo file)
  if [ -n "${DRPC_API_KEY:-}" ]; then
    echo "FANTOM_RPC_URL=https://lb.drpc.org/ogrpc?network=fantom&dkey=${DRPC_API_KEY}" >> "$GITHUB_ENV"
    echo "[ci] fork RPC set from DRPC_API_KEY (masked)"
  fi
fi
if [ -s ci-out/borrowers.json ] && grep -q '"borrowers"' ci-out/borrowers.json; then
  echo "[ci] borrower scan results already present, skipping rescan"
else
  echo "[ci] geist-finance borrower scan starting $(date -u +%FT%TZ)"
  python3 analysis/scan_borrowers.py > ci-out/scan-stdout.txt 2> ci-out/scan-stderr.txt
  echo "[ci] scan exit=$?"
fi
ls -la ci-out/ || true
tail -c 2000 ci-out/scan-stderr.txt 2>/dev/null || true
