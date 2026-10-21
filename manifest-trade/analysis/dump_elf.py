#!/usr/bin/env python3
"""Dump Solana upgradeable program ELF + metadata. Public keyless RPC only.
Writes <out>.so and prints sha256, len, slot, authority.
"""
import json, sys, base64, hashlib, urllib.request
import base58

RPC = "https://api.mainnet-beta.solana.com"

def rpc(method, params):
    for attempt in range(5):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "zh4-research/1.0"},
            )
            return json.load(urllib.request.urlopen(req, timeout=90))
        except Exception as e:
            print("retry", attempt, e, file=sys.stderr)

def acc(pubkey):
    r = rpc("getAccountInfo", [pubkey, {"encoding": "base64", "commitment": "confirmed"}])
    return r.get("result", {}).get("value")

prog = sys.argv[1]
out = sys.argv[2]

a = acc(prog)
pd_addr = base58.b58encode(base64.b64decode(a["data"][0])[4:36]).decode()
p = acc(pd_addr)
raw = base64.b64decode(p["data"][0])
tag = int.from_bytes(raw[:4], "little")
slot = int.from_bytes(raw[4:12], "little")
opt = raw[12]
if opt == 1:
    auth = base58.b58encode(raw[13:45]).decode()
else:
    auth = None
elf = raw[45:]
with open(out, "wb") as f:
    f.write(elf)
print(json.dumps({
    "program": prog, "programdata": pd_addr,
    "programdata_lamports": p["lamports"], "programdata_len": len(raw),
    "tag": tag, "last_deploy_slot": slot, "upgrade_authority": auth,
    "elf_len": len(elf), "elf_sha256": hashlib.sha256(elf).hexdigest(),
    "elf_md5": hashlib.md5(elf).hexdigest(),
}, indent=1))
