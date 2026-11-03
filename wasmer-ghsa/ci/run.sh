#!/usr/bin/env bash
# Heavy job for the wasmer-ghsa folder. Runs on GitHub Actions (public CI repo).
#   1) code-level evidence for the 7.4.2 / 7.5.0 / main question
#   2) independent compiler reproduction of the implicit-else native-stack drift
#   3) read-only Juno contract-held value re-measurement (public LCD GETs, no keys)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out

echo "########## environment ##########"
date -u +%FT%TZ
uname -a
nproc
if command -v rustup >/dev/null 2>&1; then
  rustup update stable --no-self-update -q >/dev/null 2>&1 || true
  rustup default stable >/dev/null 2>&1 || true
fi
rustc --version 2>/dev/null || echo "rustc: not preinstalled"
cargo --version 2>/dev/null || true
python3 --version

echo
echo "########## 1. code evidence ##########"
bash ci/code-evidence.sh 2>&1 | tee ci-out/codegen-evidence.txt

echo
echo "########## 2. singlepass drift reproduction ##########"
bash ci/sp-drift.sh 2>&1 | tee ci-out/sp-drift-results.txt

echo
echo "########## 3. juno contract-held value ##########"
python3 analysis/juno_value.py --out ci-out/juno-contract-value.json 2>&1 | tee ci-out/juno-value.log

echo
echo "########## summary ##########"
grep -E '^VERSION=' ci-out/sp-drift-results.txt || true
python3 - <<'PY'
import json, os
p = "ci-out/juno-contract-value.json"
if os.path.exists(p):
    d = json.load(open(p))
    print("juno:", d["contract_ujuno"], "ujuno =", d["contract_juno"], "JUNO;",
          "price", d["juno_price_usd"], "=> $", d["contract_usd_juno_only"], "; block", d["block_height"])
else:
    print("juno: NO RESULT")
PY
