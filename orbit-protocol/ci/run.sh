#!/usr/bin/env bash
# Orbit Protocol (Blast) L2 Phase-2 — heavy data collection + fork PoC prep.
# Runs on GitHub Actions. Read-only against mainnet. No secrets written to files.
set -uo pipefail
cd "$(dirname "$0")/.."          # -> orbit-protocol/
mkdir -p ci-out

echo "== probe Blast RPCs =="
PICK=""
for u in "https://81457.rpc.thirdweb.com" "https://blast-rpc.publicnode.com" "https://blast.drpc.org" "https://rpc.blast.io"; do
  r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
  case "$r" in *result*) PICK="$u"; echo "picked $u -> $r"; break;; esac
done
if [ -z "$PICK" ]; then echo "WARNING: no Blast RPC reachable"; else
  echo "BLAST_RPC_URL=$PICK" >> "$GITHUB_ENV"
  echo "$PICK" > ci-out/blast_rpc.txt
fi

echo "== fetch Pyth VAA (ETH/USD) from Hermes =="
VAA=$(curl -s -m 25 "https://hermes.pyth.network/v2/updates/price/latest?ids%5B%5D=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace&encoding=hex" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['binary']['data'][0])" 2>/dev/null)
if [ -n "$VAA" ]; then
  echo "PYTH_VAA_ETH=$VAA" >> "$GITHUB_ENV"
  echo "got ETH/USD VAA (len ${#VAA})"
else
  echo "WARNING: no VAA from Hermes"
fi

export CI_OUT="$PWD/ci-out"
export LOG_DIR="$PWD/ci-out/logs"
export BLAST_RPC_URL="${PICK:-}"
mkdir -p "$LOG_DIR"
cp -n analysis/logs/*_Borrow.json "$LOG_DIR/" 2>/dev/null || true

cd analysis

fetch_vaa() {  # $1 = feed id, $2 = env name
  V=$(curl -s -m 25 "https://hermes.pyth.network/v2/updates/price/latest?ids%5B%5D=$1&encoding=hex" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['binary']['data'][0])" 2>/dev/null)
  if [ -n "$V" ]; then echo "$2=$V" >> "$GITHUB_ENV"; echo "got $2 (len ${#V})"; else echo "WARNING: no VAA for $2"; fi
}
fetch_vaa 0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a PYTH_VAA_USDC
fetch_vaa 0x9ee4e7c60b940440a261eb54b6d8149c23b580ed7da3139f7f08f4ea29dad395 PYTH_VAA_WEETH
fetch_vaa 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43 PYTH_VAA_BTC

echo "== gates_probe =="
timeout 1500 python3 gates_probe.py || echo "gates_probe failed/timeout"

echo "== fetch_core =="
timeout 1500 python3 fetch_core.py || echo "fetch_core failed/timeout"

echo "== oracle_probe =="
timeout 1500 python3 oracle_probe.py || echo "oracle_probe failed/timeout"


echo "== fetch_logs_borrow (target markets) =="
timeout 1800 python3 fetch_logs_borrow.py || echo "fetch_logs_borrow failed/timeout"

echo "== candidates =="
timeout 300 python3 candidates.py || echo "candidates failed"

echo "== positions2 (account liquidity at true prices) =="
timeout 2400 python3 positions2.py || echo "positions2 failed/timeout"

echo "== blast yield (claimable) =="
timeout 900 python3 blast_yield.py || echo "blast_yield failed/timeout"

echo "== done; ci-out: =="
ls -la "$CI_OUT" | head -30
