#!/usr/bin/env bash
# C2-09 / CWA-2026-006 weaponization heavy job (GitHub Actions).
# Builds the exact wasmvm v1.5.5 / Wasmer 4.2.2 harness (vuln) + wasmvm 3.0.8 /
# Wasmer 7.4.2 (fixed control), generates the nested holder/trigger CosmWasm pair,
# and runs the directed-control-transfer campaign (measurement + deep-drift sweep).
# All evidence -> ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "=== [1/3] environment + engine identity ==="
go version
python3 --version
objdump --version | head -1
curl -s --max-time 20 https://api.mainnet.archway.io/cosmos/base/tendermint/v1beta1/node_info > ci-out/node_info_raw.json || true
python3 - <<'EOF' > ci-out/version_hash_check.txt 2>&1
import json, urllib.request
def get(u):
    try:
        with urllib.request.urlopen(u, timeout=30) as r: return r.read().decode()
    except Exception as e: return "ERR "+str(e)
node = get("https://api.mainnet.archway.io/cosmos/base/tendermint/v1beta1/node_info")
sumline = get("https://sum.golang.org/lookup/github.com/!cosm!wasm/wasmvm@v1.5.5")
print("NODE BUILD DEPS (wasmvm):")
try:
    d=json.loads(node)
    for x in d["application_version"]["build_deps"]:
        if "wasm" in x["path"].lower():
            print(" ", x["path"], x["version"], x.get("sum"))
except Exception as e:
    print("parse err", e)
print("\nSUM.GOLANG.ORG wasmvm v1.5.5:")
print(sumline)
EOF
cat ci-out/version_hash_check.txt

echo "=== [2/3] engine source check (buggy adjust_stack in 4.2.2; removed in 7.x) ==="
{
  echo "--- wasmer-compiler-singlepass 4.2.2 release_locations_value (deployed) ---"
  curl -s --max-time 40 https://raw.githubusercontent.com/wasmerio/wasmer/v4.2.2/lib/compiler-singlepass/src/codegen.rs \
    | sed -n '363,416p'
  echo "--- v7.4.2: grep release_locations_value (expect: removed) ---"
  curl -s --max-time 40 https://raw.githubusercontent.com/wasmerio/wasmer/v7.4.2/lib/compiler-singlepass/src/codegen.rs \
    | grep -c 'release_locations_value' || true
} > ci-out/engine_source_check.txt 2>&1
tail -5 ci-out/engine_source_check.txt

echo "=== [3/3] directed-control-transfer campaign ==="
bash harness/campaign_wpn.sh 2>&1 | tee ci-out/campaign_wpn.log

echo "=== outputs ==="
find ci-out -type f | sort | head -60
exit 0
