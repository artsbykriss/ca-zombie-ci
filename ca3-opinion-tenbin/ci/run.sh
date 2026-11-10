#!/usr/bin/env bash
# Light state snapshot for the CI artifact (heavy work is `forge test`).
set -uo pipefail
mkdir -p ci-out
python3 - <<'PY'
import json, os, subprocess, time
def rpc(url, method, params=None):
    if not url:
        return None
    payload = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params or []})
    try:
        out = subprocess.run(["curl","-s","--max-time","20","-X","POST","-H","Content-Type: application/json",
                              "--data",payload,url], capture_output=True, text=True).stdout
        return json.loads(out).get("result")
    except Exception:
        return None

bsc = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
eth = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
snap = {
  "ts": int(time.time()),
  "bsc_block": rpc(bsc, "eth_blockNumber"),
  "eth_block": rpc(eth, "eth_blockNumber"),
  "note": "read-only snapshot; forge tests run separately by the workflow",
}
json.dump(snap, open("ci-out/live-state.json","w"), indent=1)
print(json.dumps(snap, indent=1))
PY
