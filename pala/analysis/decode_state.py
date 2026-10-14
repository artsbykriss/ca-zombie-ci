#!/usr/bin/env python3
"""Decode viewer token list + farm lists + farm balances. Read-only."""
import json, urllib.request, subprocess, sys

RPC = "https://klaytn.drpc.org"
V = "0x2B16648ddD1559fc86e0c0617213Ab5dd2Ea01B9"

def call(data, to=V, tries=5):
    body = json.dumps({"jsonrpc": "2.0", "method": "eth_call", "params": [{"to": to, "data": data}, "latest"], "id": 1}).encode()
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as r:
                d = json.loads(r.read().decode())
            if "result" in d:
                return d["result"]
        except Exception:
            pass
    raise RuntimeError("rpc fail")

def word(x):
    return hex(x)[2:].rjust(64, "0")

def decode_token_list():
    h = call("0x273cbaa0")[2:]
    off = int(h[0:64], 16) * 2
    n = int(h[off:off+64], 16)
    toks = []
    for i in range(n):
        o = off + 64 + i * 64
        toks.append("0x" + h[o+24:o+64])
    return toks

def decode_farm(farm):
    d = subprocess.run(["cast", "calldata", "farmInfos(address)", farm], capture_output=True, text=True).stdout.strip()
    h = call(d)[2:]
    list_off = int(h[0:64], 16) * 2
    cfg_off = 64 * 2
    cfg = {}
    names = ["attenTotalAllocPoint", "attenFarmStartBlock", "attenFarmEndBlock", "attenPerBlock",
             "attenBonusMultiplier", "palaTotalAllocPoint", "palaFarmStartBlock", "palaPerBlock", "palaBonusMultiplier"]
    for i, nm in enumerate(names):
        cfg[nm] = int(h[cfg_off+i*64:cfg_off+(i+1)*64], 16)
    n = int(h[list_off:list_off+64], 16)
    rows = []
    for i in range(n):
        o = list_off + 64 + i * 5 * 64
        rows.append({"pool": "0x" + h[o+24:o+64], "totalLP": int(h[o+64:o+128], 16),
                     "allocPoint": int(h[o+128:o+192], 16), "lastRewardBlock": int(h[o+192:o+256], 16),
                     "accRewardPerShare": int(h[o+256:o+320], 16)})
    return {"farm": farm, "n": n, "pools": rows, "config": cfg}

def balance_of(token, owner):
    return int(call("0x70a08231" + word(int(owner, 16)), to=token), 16)

if __name__ == "__main__":
    out = {}
    toks = decode_token_list()
    out["token_list"] = toks
    print(f"token_list: {len(toks)} tokens")
    farms = ["0x883726a307d420286086679f7851d8378bb16771", "0xcfc140e8e3b1b05f9acb4a42249b7abb8c27576c"]
    out["farms"] = []
    for f in farms:
        fd = decode_farm(f)
        fd["balances"] = {}
        for row in fd["pools"]:
            p = row["pool"]
            try:
                fd["balances"][p] = {"farm_bal": balance_of(p, f)}
            except Exception as e:
                fd["balances"][p] = {"error": str(e)}
        out["farms"].append(fd)
        print(f"farm {f}: {fd['n']} pools, cfg palaTotalAllocPoint={fd['config']['palaTotalAllocPoint']} attenTotalAllocPoint={fd['config']['attenTotalAllocPoint']}")
    json.dump(out, open("/home/heisenberg/CA/pala/analysis/viewer_state.json", "w"), indent=1)
    print("saved viewer_state.json")
