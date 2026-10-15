#!/usr/bin/env bash
# Best-effort heavy job for HashMix FIL (hashmix-fil).
# Runs BEFORE the forge test step. Never exits non-zero (so the forge PoC still runs).
# Writes everything to ci-out/ (uploaded as artifacts).
set -uo pipefail
mkdir -p ci-out
RPCS=("https://api.chain.love/rpc/v1" "https://rpc.ankr.com/filecoin" "https://api.node.glif.io/rpc/v1" "https://filecoin.blockscout.com/api/eth-rpc")

# ---- 0. probe a working Filecoin RPC and hand it to the forge step -------------
PICK=""
for u in "${RPCS[@]}"; do
  r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' "$u" 2>/dev/null)
  case "$r" in *0x13a*) PICK="$u"; break;; esac
done
echo "${PICK:-none}" > ci-out/fil_rpc.txt
if [ -n "$PICK" ] && [ -n "${GITHUB_ENV:-}" ]; then
  echo "FIL_RPC_URL=$PICK" >> "$GITHUB_ENV"
  echo "[ci] exported FIL_RPC_URL for forge step: $PICK"
fi

# ---- 1. resolve all HashMix selectors via openchain (from CI network) ----------
python3 - <<'PYEOF' > ci-out/selector_lookup.json 2>ci-out/selector_lookup.err || true
import json, urllib.request, time
sels = {
 "pool": ["0x258836fe","0x3e941010","0x601a0bf1","0xd2c35ce8","0x856e5bb3","0x2608f818","0xd0248fb4","0x43600c54","0xaa5af0fd","0x6752e702","0xff5a20bf","0x69ab3250"],
 "controller_v1": ["0x09448a86","0x0975e5c1","0x0ec4d916","0x0ecbcdab","0x16f0115b","0x1e65e713","0x2002b30f","0x313dd8bb","0x36e26988","0x54fd4d50","0x5a446a28","0x61bbf939","0x6af9acb3","0x6f5dee99","0x704b6c02","0x7e5bbb1e","0x805a8c02","0x818e2645","0x8e02a8b5","0x98471f1c","0xa3c4bb2a","0xa42dce80","0xaf455978","0xb65fb24c","0xbb2940e3","0xc0c53b8b","0xc415b95c","0xe5ffaab8","0xf655b8e0","0xf851a440","0xf9291906","0xfd40449d","0xfd5b6141"],
 "v2_controller_impl": ["0x2ce6dfa4"],
}
out = {}
for group, ss in sels.items():
    out[group] = {}
    for s in ss:
        try:
            url = "https://api.openchain.xyz/signature-database/v1/lookup?function=" + s
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            d = json.load(urllib.request.urlopen(req, timeout=20))
            names = [x.get("name") for x in (d.get("result", {}).get("function", {}).get(s) or [])]
            out[group][s] = names[:5]
        except Exception as e:
            out[group][s] = ["ERR " + str(e)[:80]]
        time.sleep(0.3)
print(json.dumps(out, indent=1))
PYEOF

# ---- 2. live state snapshot at a recorded block -------------------------------
python3 - <<'PYEOF' > ci-out/live_state.json 2>ci-out/live_state.err || true
import json, urllib.request, time
POOL="0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
V2POOL="0x85e77391C3dDe4fee572A79CFef7f710c7476f82"
CTRL="0xFA33F3866e7eF32F79734BCC5e011d767F8E574b"
RPCS=["https://api.chain.love/rpc/v1","https://rpc.ankr.com/filecoin","https://api.node.glif.io/rpc/v1"]
def rpc(method, params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for u in RPCS:
        try:
            req=urllib.request.Request(u,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            d=json.load(urllib.request.urlopen(req,timeout=25))
            if "result" in d: return d["result"]
            last=d
        except Exception as e: last=e
    return "ERR:"+str(last)[:100]
views={"symbol":"0x95d89b41","totalSupply":"0x18160ddd","exchangeRateStored":"0x182df0f5",
       "getCash":"0x3b1d21a2","totalBorrows":"0x47bd3718","totalReserves":"0x8f840ddd",
       "feeCollector":"0xc415b95c","controller":"0xf77c4791","underlying":"0x6f307dc3",
       "accrualBlockNumber":"0x6c540baf"}
out={"block":rpc("eth_blockNumber",[])}
for name,sel in views.items():
    out["pool_"+name]=rpc("eth_call",[{"to":POOL,"data":sel},"latest"]); time.sleep(0.3)
out["pool_balance"]=rpc("eth_getBalance",[POOL,"latest"])
out["v2_balance"]=rpc("eth_getBalance",[V2POOL,"latest"])
for name,sel in [("v2_totalBorrows","0x47bd3718"),("v2_totalReserves","0x8f840ddd"),("v2_feeCollector","0xc415b95c")]:
    out[name]=rpc("eth_call",[{"to":V2POOL,"data":sel},"latest"]); time.sleep(0.3)
out["ctrl_admin"]=rpc("eth_call",[{"to":CTRL,"data":"0xf851a440"},"latest"])
print(json.dumps(out, indent=1))
PYEOF

# ---- 3. best-effort decompilation of the controller implementation -----------
python3 - <<'PYEOF' > ci-out/decompile_notes.txt 2>&1 || true
print("Decompilation of the controller impl is done locally (panoramix) and the")
print("results are in analysis/panoramix_controller_clean.txt. CI decompile is")
print("best-effort only to keep this job short; selector resolution is above.")
PYEOF

echo "ci/run.sh done (best-effort; see ci-out/)"
exit 0
