#!/usr/bin/env python3
"""Fetch a Solana program's on-chain ELF (and programdata metadata) via JSON-RPC.

Read-only: only getAccountInfo / getSlot. Never signs anything.
Redacts nothing secret (no keyed URL is written; endpoint comes from env).
"""
import base64, json, os, sys, urllib.request

_B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58encode(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = _B58[r] + out
    for c in b:
        if c == 0:
            out = "1" + out
        else:
            break
    return out.encode()

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]

def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())

def rpc_any(method, params):
    last = None
    for u in ENDPOINTS:
        try:
            return rpc(u, method, params)
        except Exception as e:  # noqa
            last = e
    raise last

def b64(x):
    return base64.b64decode(x)

def fetch(prog_id, outdir):
    os.makedirs(outdir, exist_ok=True)
    res = rpc_any("getAccountInfo", [prog_id, {"encoding": "base64"}])
    v = res.get("result", {}).get("value")
    if v is None:
        print(json.dumps({"program": prog_id, "error": "no account"}))
        return
    slot = rpc_any("getSlot", [{"commitment": "finalized"}]).get("result")
    prog_owner = v["owner"]
    prog_lamports = v["lamports"]
    meta = {"program": prog_id, "slot": slot, "owner": prog_owner,
            "lamports": prog_lamports, "executable": v["executable"]}
    if not v["executable"]:
        meta["note"] = "not executable"
        print(json.dumps(meta)); return
    # program account data = 4-byte state enum + programdata address
    pdata = b64(v["data"][0])
    state = int.from_bytes(pdata[:4], "little")
    meta["loader_state"] = state
    if state == 2:  # UpgradeableLoaderState::Program
        pd_addr = b58encode(pdata[4:36]).decode()
    else:
        pd_addr = None
    meta["programdata"] = pd_addr
    if pd_addr:
        r2 = rpc_any("getAccountInfo", [pd_addr, {"encoding": "base64"}])
        v2 = r2.get("result", {}).get("value")
        if v2:
            d2 = b64(v2["data"][0])
            meta["programdata_owner"] = v2["owner"]
            meta["programdata_lamports"] = v2["lamports"]
            # layout: u32 state + u64 slot + Option<Pubkey> (1 + 32) + ELF
            last_slot = int.from_bytes(d2[4:12], "little")
            has_auth = d2[12]
            meta["last_deploy_slot"] = last_slot
            meta["upgrade_authority"] = b58encode(d2[13:45]).decode() if has_auth else None
            elf = d2[45:]
            meta["elf_len"] = len(elf)
            with open(os.path.join(outdir, prog_id + ".so"), "wb") as f:
                f.write(elf)
    print(json.dumps(meta))

if __name__ == "__main__":
    prog = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "."
    fetch(prog, outdir)
