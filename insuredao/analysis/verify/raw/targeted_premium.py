#!/usr/bin/env python3
"""Targeted reads: rewardPerCredit + per-(pool,index) pendingPremium + slot occupancy."""
import json, urllib.request
from eth_utils import keccak
from eth_abi import encode

RPC = "https://ethereum-rpc.publicnode.com"

def _post(url, payload):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 readonly"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())

def batch(calls):
    payload = []
    for i, (to, sig, args) in enumerate(calls):
        sel = "0x" + keccak(text=sig)[:4].hex()
        types = []
        for t in sig[sig.index("(")+1:-1].split(","):
            t = t.strip()
            if t:
                types.append("uint256" if (t.startswith("uint") or t.startswith("int")) else t)
        enc = encode(types, list(args)) if types else b""
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call",
                        "params": [{"to": to, "data": sel + enc.hex()}, "latest"]})
    resp = _post(RPC, payload)
    out = {}
    for d in resp:
        out[d["id"]] = d.get("result") if "error" not in d else None
    return [out.get(i) for i in range(len(calls))]

ZERO = "0x" + "0"*40
POOLS = {
 "0x8c4943100bec96e3381a544da82b91713a4bc062": ["0xdaea5b1b6b12ac4c4f51ab12649e96ab3ab98c3a"],
 "0x641be011738c65aac8ff3f5d4e6dedbbd7411f47": ["0xdaea5b1b6b12ac4c4f51ab12649e96ab3ab98c3a","0x7e08dab409ad1bcebc5be5674cb2c0f3540a4d3d"],
 "0xbdb009e6c9dd3f77d6a7f507a4f817133677257c": ["0xdaea5b1b6b12ac4c4f51ab12649e96ab3ab98c3a","0xd5f1ab3c61ef3a6a6f1aa6141256aa008d2fb5a1"],
 "0x58803187e676b180ed12b4f7d79b94ca011f4b8e": ["0x7e08dab409ad1bcebc5be5674cb2c0f3540a4d3d"],
}
calls = []
for p, ixs in POOLS.items():
    calls.append((p, "rewardPerCredit()", ()))
    calls.append((p, "totalCredit()", ()))
    calls.append((p, "attributionDebt()", ()))
    for ix in ixs:
        calls.append((p, "pendingPremium(address)", (ix,)))
        calls.append((p, "indices(address)", (ix,)))
res = batch(calls)
i = 0
out = {}
for p, ixs in POOLS.items():
    rpc = int(res[i], 16); tc = int(res[i+1], 16); ad = int(res[i+2], 16); i += 3
    print(f"\npool {p}\n  rewardPerCredit={rpc} totalCredit={tc} attributionDebt={ad}")
    for ix in ixs:
        pp = int(res[i], 16); i += 1
        b = res[i][2:]; i += 1
        credit = int(b[0:64], 16); rd = int(b[64:128], 16); idxn = int(b[128:192], 16); exist = int(b[192:256], 16)
        calc = (credit * rpc) // 10**6 - rd
        print(f"  index {ix}: pending={pp} credit={credit} rewardDebt={rd} slot={idxn} exist={exist} calc={calc}")

# also check every pool's indexList occupancy for eviction candidates (all 29 markets)
d = json.load(open("/home/heisenberg/CA/insuredao/analysis/verify/raw/state.json"))
print("\n=== all pools: slots with indexList entry ===")
for m, x in d["marketDetail"].items():
    if x["kind"] != "pool":
        continue
    for k, ix in enumerate(x["indexList"]):
        if ix and ix != ZERO:
            print(f"{m} slot{k} -> {ix}")
    if all((not ix) or ix == ZERO for ix in x["indexList"]):
        print(f"{m} (no index slots used)")
