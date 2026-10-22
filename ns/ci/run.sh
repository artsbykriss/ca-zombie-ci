#!/usr/bin/env bash
# Light live-state dump for the BTCX/NS/DMD Tier-3 deep-dive.
# Runs in CI (has BSC_RPC_URL). NEVER prints the RPC URL or any secret.
# Writes derived values only to ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
RPC="${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}"
export RPC
python3 - <<'PY' > ci-out/live-state.json
import json, os, urllib.request, time

RPC = os.environ["RPC"]
def call(m, p):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    last = None
    for _ in range(6):
        try:
            r = urllib.request.Request(RPC, data=b, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            return json.loads(urllib.request.urlopen(r, timeout=40).read())
        except Exception as e:
            last = e; time.sleep(2)
    raise last

def hc(to, data, frm=None):
    o = {"to": to, "data": data}
    if frm: o["from"] = frm
    try:
        return call("eth_call", [o, "latest"]).get("result")
    except Exception as e:
        return "ERR"

def num(x):
    return int(x, 16) if isinstance(x, str) and x.startswith("0x") else x

bn = int(call("eth_blockNumber", [])["result"], 16)
ATT = "0x00000000000000000000000000000000DeaDBeef"
T = {"BTCX": "0xb1939843fb9220719d13076dceefb0aeaef06666",
     "NS": "0x33f1c4fbb7e4e040f4f4e6bc492e4fedf750fd41",
     "DMD": "0x939df4a5a5022037bb33102c6489e774e063b160"}
P = {"BTCX": "0x3cc292bb0011951f3151eb998816c31680a2ce87",
     "NS": "0xf1a5896d91c1e2372b159455ad013b2d17c0bb0b",
     "DMD": "0x29f9148a8518e327e8677ba21c3fa3a55dd1e6bc"}
out = {"block": bn, "attacker": ATT, "targets": {}}
for k in T:
    d = {}
    res = hc(P[k], "0x0902f1ac")
    if res and res != "ERR":
        d["reserve0"] = int(res[2:66], 16)
        d["reserve1"] = int(res[66:130], 16)
    d["pair_token_balance"] = num(hc(T[k], "0x70a08231" + "0" * 24 + P[k][2:]))
    d["totalSupply"] = num(hc(T[k], "0x18160ddd"))
    out["targets"][k] = d

# gate probes from a random EOA
def probe(to, data):
    r = call("eth_call", [{"from": ATT, "to": to, "data": data}, "latest"])
    if "result" in r:
        return {"result": "ok", "value": r["result"][:74]}
    return {"revert": r.get("error", {}).get("data", r.get("error", {}))}

out["gates"] = {
    "NS.burnNsFromPair(500)": probe(T["NS"], "0x29150a1e" + hex(500)[2:].rjust(64, "0")),
    "DMD.burnFromMainPair()": probe(T["DMD"], "0xa9292e84"),
}
print(json.dumps(out, indent=1))
PY
echo "wrote ci-out/live-state.json"
