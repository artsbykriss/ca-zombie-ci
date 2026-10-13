#!/usr/bin/env python3
"""childA pass 2: fill gaps (None balances), per-role counts/members, code check, feeCollector balances."""
import json, urllib.request, sys, time, subprocess

RPC = "https://rpc.scroll.io"
UA = "Mozilla/5.0"
VOTER = "0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869"
FEE_COLLECTOR = "0xAAA2A49958a443Dc9d19FdDEe873B5D1d6e84A2f"
COMMAND_CENTER = "0xAAA11500dDdB2B67a90d1a154dfB7eaBB518EAE6"
TOKENS = {
    "WETH": "0x5300000000000000000000000000000000000004",
    "USDC": "0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4",
    "USDT": "0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df",
    "NURI": "0xAAAE8378809bb8815c08D3C59Eb0c7D1529aD769",
}
SEL = {"balanceOf": "0x70a08231", "getRoleMemberCount": "0xca15c873", "getRoleMember": "0x9010d07c"}

def keccak_hex(s):
    return subprocess.check_output(["cast", "keccak", s]).decode().strip()

_id = [10000]
def rpc_batch(calls):
    CHUNK = 5
    res = {}
    for i in range(0, len(calls), CHUNK):
        chunk = calls[i:i+CHUNK]
        body = json.dumps(chunk).encode()
        req = urllib.request.Request(RPC, data=body, headers={"User-Agent": UA, "Content-Type": "application/json"})
        out = None
        for a in range(4):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    out = json.loads(r.read().decode())
                break
            except Exception:
                if a == 3: raise
                time.sleep(2*(a+1))
        by = {x["id"]: x for x in out}
        for c in chunk:
            x = by.get(c["id"], {})
            res[c["id"]] = x.get("result") if "result" in x else {"error": x.get("error")}
    return res

def call(to, data):
    _id[0] += 1
    return {"jsonrpc":"2.0","id":_id[0],"method":"eth_call","params":[{"to":to,"data":data},"latest"]}

def pad(a):
    a = a[2:] if a.startswith("0x") else a
    return a.rjust(64, "0")[-64:]

def get_int(r): return None if isinstance(r, dict) else (int(r,16) if r and r!="0x" else 0)
def get_addr(r): return None if isinstance(r, dict) else ("0x"+r[-40:])

raw = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))
block = raw["block"]

calls = []; idx = {}
# missing FD balances
for fd, v in raw["fds"].items():
    for tn, bal in v["balances"].items():
        if bal is None:
            c = call(fd, SEL["balanceOf"]+pad(TOKENS[tn])); calls.append(c); idx[c["id"]] = ("fdbal", fd, tn)
# feeCollector balances
for tn, ta in TOKENS.items():
    c = call(FEE_COLLECTOR, SEL["balanceOf"]+pad(ta)); calls.append(c); idx[c["id"]] = ("fcbal", None, tn)
# roles
roles = {"DEFAULT_ADMIN_ROLE": "0x"+"00"*32, "OPERATOR_ROLE": keccak_hex("OPERATOR_ROLE"), "FEE_SETTER_ROLE": keccak_hex("FEE_SETTER_ROLE")}
for rn, rh in roles.items():
    c = call(COMMAND_CENTER, SEL["getRoleMemberCount"]+pad(rh)); calls.append(c); idx[c["id"]] = ("rccount", rn, None)
res = rpc_batch(calls)
out = {"block": block, "fdbal": {}, "fcbal": {}, "role_counts": {}, "role_members": {}}
for cid, (kind, a, b) in idx.items():
    if kind == "fdbal" and get_int(res[cid]) is not None:
        raw["fds"][a]["balances"][b] = get_int(res[cid])
    elif kind == "fcbal":
        out["fcbal"][b] = get_int(res[cid])
    elif kind == "rccount":
        out["role_counts"][a] = get_int(res[cid])
# members (up to count)
calls = []; idx = {}
for rn, rh in roles.items():
    n = out["role_counts"].get(rn) or 0
    for k in range(n):
        c = call(COMMAND_CENTER, SEL["getRoleMember"]+pad(rh)+pad(hex(k))); calls.append(c); idx[c["id"]] = (rn, k)
res = rpc_batch(calls)
for cid, (rn, k) in idx.items():
    v = get_addr(res[cid])
    if v and int(v,16) != 0:
        out["role_members"].setdefault(rn, []).append(v)
# code check on unique role members + zero-hash sanity
allm = sorted({m for ms in out["role_members"].values() for m in ms})
codes = {}
for m in allm:
    _id[0] += 1
    body = json.dumps({"jsonrpc":"2.0","id":_id[0],"method":"eth_getCode","params":[m, hex(block)]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"User-Agent":UA,"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        codes[m] = len(json.loads(r.read().decode()).get("result","0x"))//2 - 1
out["role_member_code_size"] = codes
# save
raw["misc"]["feeCollector"]["balances"] = out["fcbal"]
raw["misc"]["roles"] = {"counts": out["role_counts"], "members": out["role_members"], "code_size": codes, "hashes": roles}
json.dump(raw, open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json","w"), indent=1)
print(json.dumps(out, indent=1))
