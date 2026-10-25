#!/usr/bin/env bash
# Heavy job for the bucket-v2 finding (GitHub Actions, public repo).
# Read-only Sui GraphQL only. Results -> ci-out/ (uploaded).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
export OUTDIR="$PWD/ci-out"
export SUI_GRAPHQL="${SUI_GRAPHQL:-https://graphql.mainnet.sui.io/graphql}"
export FAMILY_FILTER="bucket"
echo "### env"; python3 --version; echo "endpoint: $SUI_GRAPHQL"
echo "### 1. Bucket V2 package version matrix"
python3 poc/version_matrix.py || echo "version_matrix failed"
echo "### 2. differential callability probes"
python3 poc/import_probes.py || echo "import_probes failed"
echo "### function-body diff across versions"
python3 poc/fn_body_diff.py || echo "fn_body_diff failed"

echo "### struct-layout stability (exploitability gate)"
python3 poc/struct_diff.py || echo "struct_diff failed"

echo "### 3. live state snapshot"
python3 poc/live_state.py || echo "live_state failed"
echo "### done"; ls -la ci-out
