#!/usr/bin/env bash
# ci/run.sh — heavy/networked job for the Archer Exchange finding.
# Runs the read-only Solana substitution battery against keyless public RPC.
# No secrets, no keys, no transactions: simulateTransaction only.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out

echo "== python =="; python3 -V
python3 -m pip install --quiet --disable-pip-version-check solders 2>&1 | tail -2 || true

echo "== archer substitution battery =="
python3 poc/archer_poc.py 2>&1 | tee ci-out/archer_stdout.txt
rc=${PIPESTATUS[0]}

echo "== summary =="
python3 - <<'PY' || true
import json
d = json.load(open("ci-out/archer_results.json"))
print(f'markets={d["markets"]} books={d["maker_books"]} '
      f'vault=${d["vault_value_usd"]:,.2f} free_ceiling=${d["free_balance_ceiling_usd"]:,.2f}')
for r in d["substitutions"]:
    print(f'  {r["label"]:44s} {r["result"]}')
PY
exit $rc
