#!/usr/bin/env bash
# ZH4-PASS3 Rujira FIN — CI job.
#   1. read-only THORChain/FIN state re-check (no secrets, no transactions)
#   2. local PoC: cw-multi-test against rujira-fin v2.2.2 (commit 3114257, code_id 196)
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "===== [1/2] read-only state re-check ====="
python3 analysis/collect_rujira.py 2>&1 | tee ci-out/state-console.txt || echo "state collector failed"
[ -f analysis/state-live.json ] && cp analysis/state-live.json ci-out/rujira-state.json

echo "===== [1b] live re-check snapshot (halt votes / code ids / upgrade) ====="
python3 analysis/live_recheck.py 2>&1 | tee ci-out/live-recheck-console.txt || echo "live recheck failed"

echo "===== [1c] post-unhalt wasm activity scan (upgrade height -> now) ====="
NOW=$(python3 -c "import json,urllib.request;print(json.load(urllib.request.urlopen('https://gateway.liquify.com/chain/thorchain_api/thorchain/block',timeout=30))['header']['height'])" 2>/dev/null || echo 28378065)
echo "[ci] scanning 28366100 .. $NOW"
python3 analysis/scan_postunhalt.py 28366100 "$NOW" 16 2>&1 | tee ci-out/postunhalt-console.txt || echo "post-unhalt scan failed"

echo "===== [1d] verify the v3.21.0 base-layer fix (source, read-only) ====="
{
  for f in x/thorchain/memo/memo_exec.go x/thorchain/handler_wasm_exec.go x/thorchain/types/msg_wasm_exec.go; do
    enc=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$f")
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "https://gitlab.com/api/v4/projects/thorchain%2Fthornode/repository/files/$enc/raw?ref=v3.21.0")
    echo "$f @ v3.21.0 -> HTTP $code (404 = deleted in the live release line)"
  done
  echo -n "memo.go v3.21.0 lines matching '\"x\"' or 'TxExec': "
  curl -s --max-time 30 "https://gitlab.com/api/v4/projects/thorchain%2Fthornode/repository/files/x%2Fthorchain%2Fmemo%2Fmemo.go/raw?ref=v3.21.0" | grep -c '"x"\|TxExec'
  echo -n "ante.go v3.21.0 lines matching 'TxSignedBy': "
  curl -s --max-time 30 "https://gitlab.com/api/v4/projects/thorchain%2Fthornode/repository/files/x%2Fthorchain%2Fante.go/raw?ref=v3.21.0" | grep -c 'TxSignedBy'
  echo "expected: all three files 404; memo.go 0; ante.go >0  => the incident's ExecMemo path is gone, the TxSignedBy guard is present"
} 2>&1 | tee ci-out/fix-verify.txt

echo "===== [2/2] local PoC (rujira-fin v2.2.2) ====="
if ! command -v cargo >/dev/null 2>&1; then
  echo "[ci] installing rust 1.81.0"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain 1.81.0 --profile minimal >/dev/null 2>&1
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
fi
rustc --version || true

cd poc/rujira
{
  echo "rujira-fin Cargo.toml:"; grep -m1 '^version' contracts/rujira-fin/Cargo.toml
  echo "upstream commit 3114257 (fin v2.2.2); deployed code_id 196"
  echo "sha256 rujira_fin.wasm = 5cc7e1368aee0e5a7877502ca6a090ca7aa4dfb10caf3453aadcd035e1f2e071"
  echo "---- cargo test ----"
} | tee ../../ci-out/fin-poc.log

cargo test -p rujira-fin exploit_poc -- --nocapture --test-threads=1 2>&1 | tee -a ../../ci-out/fin-poc.log
STATUS=${PIPESTATUS[0]}
echo "cargo test exit=$STATUS" | tee -a ../../ci-out/fin-poc.log
exit "$STATUS"
