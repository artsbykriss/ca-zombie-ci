#!/usr/bin/env python3
"""childA pass 3: correct balances token.balanceOf(fd); feeCollector balances; nothing else."""
import json, urllib.request, time

RPC = "https://rpc.scroll.io"; UA = "Mozilla/5.0"
FEE_COLLECTOR = "0xAAA2A49958a443Dc9d19FdDEe873B5D1d6e84A2f"
TOKENS = {
    "WETH": "0x5300000000000000000000000000000000000004",
    "USDC": "0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4",
    "USDT": "0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df",
    "NURI": "0xAAAE8378809bb8815c08D3C59Eb0c7D1529aD769",
}
_id = [50000]
def call(to, data):
    _id[0] += 1
    return {"jsonrpc":"2.0","id":_id[0],"method":"eth_call","params":[{"to":to,"data":data},"latest"]}
def pad(a):
    a = a[2:] if a.startswith("0x") else a
    return a.rjust(64, "0")
def rpc_batch(calls):
    res = {}
    for i in range(0, len(calls), 5):
        chunk = calls[i:i+5]
        body = json.dumps(chunk).encode()
        req = urllib.request.Request(RPC, data=body, headers={"User-Agent": UA, "Content-Type": "application/json"})
        for a in range(4):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    out = json.loads(r.read().decode()); break
            except Exception:
                if a == 3: raise
                time.sleep(2*(a+1))
        by = {x["id"]: x for x in out}
        for c in chunk:
            x = by.get(c["id"], {})
            res[c["id"]] = x.get("result") if "result" in x else {"error": x.get("error")}
    return res

raw = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))
block = raw["block"]
calls = []; idx = {}
for fd in raw["fds"]:
    for tn, ta in TOKENS.items():
        c = call(ta, "0x70a08231" + pad(fd)); calls.append(c); idx[c["id"]] = ("fd", fd, tn)
for tn, ta in TOKENS.items():
    c = call(ta, "0x70a08231" + pad(FEE_COLLECTOR)); calls.append(c); idx[c["id"]] = ("fc", FEE_COLLECTOR, tn)
res = rpc_batch(calls)
errs = []
for cid, (kind, a, tn) in idx.items():
    r = res[cid]
    if isinstance(r, dict):
        errs.append((kind, a, tn, r)); continue
    val = int(r, 16) if r and r != "0x" else 0
    if kind == "fd":
        raw["fds"][a]["balances"] = raw["fds"][a].get("balances") or {}
        raw["fds"][a]["balances"][tn] = val
    else:
        raw["misc"]["feeCollector"].setdefault("balances", {})[tn] = val
raw["misc"]["balance_errors"] = [str(e) for e in errs]
json.dump(raw, open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json", "w"), indent=1)

tot = {"WETH":0,"USDC":0,"USDT":0,"NURI":0}
for fd, v in raw["fds"].items():
    for k, x in v["balances"].items():
        if x: tot[k] += x
print("errors:", errs)
print("TOTALS:", {k: (v/10**(18 if k in ("WETH","NURI") else 6)) for k, v in tot.items()})
print("FEE_COLLECTOR:", {k: (v/10**(18 if k in ("WETH","NURI") else 6)) for k, v in raw["misc"]["feeCollector"]["balances"].items()})
print("--- FDs with any of the 4 tokens > 0:")
for fd, v in raw["fds"].items():
    nz = {k: x for k, x in v["balances"].items() if x}
    if nz:
        print(fd, {k: round(x/10**(18 if k in ("WETH","NURI") else 6), 8) for k, x in nz.items()})
