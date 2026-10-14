#!/usr/bin/env bash
# Eklipse Finance (Kaia) fork-PoC runner — heavy job for GitHub Actions.
# READ-ONLY against mainnet: forks only, no real transactions.
# Results -> ci-out/ci-test.log (+ artifact upload by the workflow).
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
mkdir -p ci-out
LOG="$ROOT/ci-out/ci-test.log"
: > "$LOG"

KEYED=""
[ -n "${DRPC_API_KEY:-}" ] && KEYED="https://lb.drpc.org/ogrpc?network=kaia&dkey=$DRPC_API_KEY"

# Probe candidates: does eth_blockNumber work, and does a state read by block HASH work?
# (Foundry forks read state by block hash unless --fork-state-by-number is used.)
python3 - "$KEYED" "https://public-en.node.kaia.io" "https://kaia.drpc.org" "https://klaytn.drpc.org" "https://rpc.ankr.com/kaia" <<'PY' 2>&1 | tee -a "$LOG"
import json, subprocess, sys
def rpc(url, method, params):
    p = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params})
    try:
        out = subprocess.run(["curl","-s","-m","15","-X","POST","-H","Content-Type: application/json",
                              "--data-binary",p,url], capture_output=True, text=True, timeout=25).stdout
        d = json.loads(out)
        return d.get("result"), d.get("error")
    except Exception as e:
        return None, str(e)[:80]
for url in sys.argv[1:]:
    if not url: continue
    red = url.split("dkey=")[0] + ("dkey=REDACTED" if "dkey=" in url else "")
    blk, err = rpc(url, "eth_getBlockByNumber", ["latest", False])
    if not blk or not isinstance(blk, dict):
        print(f"probe {red}: NO-BLOCK {str(err)[:60]}")
        continue
    h = blk.get("hash")
    st, err2 = rpc(url, "eth_getStorageAt", ["0x0000000000000000000000000000000000000000", "0x0", h])
    tag = "HASH-OK" if st is not None else f"HASH-FAIL({str(err2)[:40]})"
    print(f"probe {red}: block={int(blk['number'],16)} {tag}")
PY

pick_byhash() {
  for u in "$@"; do
    [ -z "$u" ] && continue
    r=$(curl -s -m 15 -X POST -H 'Content-Type: application/json' \
          --data '{"jsonrpc":"2.0","id":1,"method":"eth_getBlockByNumber","params":["latest",false]}' "$u" 2>/dev/null)
    h=$(printf '%s' "$r" | python3 -c "import json,sys;print(json.load(sys.stdin).get('result',{}).get('hash',''))" 2>/dev/null)
    [ -z "$h" ] && continue
    r2=$(curl -s -m 15 -X POST -H 'Content-Type: application/json' \
          --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getStorageAt\",\"params\":[\"0x0000000000000000000000000000000000000000\",\"0x0\",\"$h\"]}" "$u" 2>/dev/null)
    case "$r2" in *result*) echo "$u"; return 0;; esac
  done
  return 1
}

BYHASH=$(pick_byhash "https://public-en.node.kaia.io" "https://rpc.ankr.com/kaia" "https://kaia.drpc.org" "https://klaytn.drpc.org" "$KEYED" || true)

cd "$ROOT/poc"
forge build >>"$LOG" 2>&1
STATUS=1
if [ -n "$BYHASH" ]; then
  echo "[eklipse] using by-hash capable RPC: $(echo "$BYHASH" | sed 's/dkey=.*/dkey=REDACTED/')" | tee -a "$LOG"
  # hand the chosen RPC to the workflow's plain `forge test` step (kept in /tmp, never in the repo/artifacts)
  printf '%s' "$BYHASH" > /tmp/kaia-rpc.txt
  chmod 600 /tmp/kaia-rpc.txt
  for attempt in 1 2 3; do
    echo "[eklipse] forge test (by-hash) attempt $attempt" >>"$LOG"
    if forge test -vv --rpc-url "$BYHASH" >>"$LOG" 2>&1; then STATUS=0; break; fi
    sleep 20
  done
fi
if [ $STATUS -ne 0 ]; then
  for attempt in 1 2 3; do
    for u in "$KEYED" "https://kaia.drpc.org" "https://klaytn.drpc.org"; do
      [ -z "$u" ] && continue
      echo "[eklipse] forge test (by-number) attempt $attempt via $(echo "$u" | sed 's/dkey=.*/dkey=REDACTED/')" >>"$LOG"
      if forge test -vv --rpc-url "$u" --fork-state-by-number >>"$LOG" 2>&1; then STATUS=0; break 2; fi
      sleep 15
    done
  done
fi
echo "exit_status=$STATUS" >>"$LOG"
tail -100 "$LOG"
exit 0
