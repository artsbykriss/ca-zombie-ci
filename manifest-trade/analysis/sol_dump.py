#!/usr/bin/env python3
"""Dump Solana program accounts / ELF for a program id. Keyless public RPC only."""
import json, sys, base64, hashlib, urllib.request

RPC = sys.argv[1] if len(sys.argv) > 1 else "https://api.mainnet-beta.solana.com"

def rpc(method, params):
    req = urllib.request.Request(
        RPC,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "zh4-research/1.0"},
    )
    return json.load(urllib.request.urlopen(req, timeout=60))

def acc(pubkey, encoding="base64"):
    r = rpc("getAccountInfo", [pubkey, {"encoding": encoding, "commitment": "confirmed"}])
    return r.get("result", {}).get("value")

if __name__ == "__main__":
    prog = sys.argv[1] if len(sys.argv) > 1 else "MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms"
    a = acc(prog)
    print("program account:", json.dumps({k: a[k] for k in ("lamports", "owner", "executable", "space")}, indent=1))
    data = base64.b64decode(a["data"][0])
    print("data len", len(data), "first bytes", data[:8].hex())
    # BPFLoaderUpgradeable Program state: tag u32 =2, programdata addr [32], last_deploy_slot u64
    tag = int.from_bytes(data[:4], "little")
    print("tag", tag)
    if tag == 2:
        pd = data[4:36]
        import base58
        print("programdata:", base58.b58encode(pd).decode())
        print("last_deploy_slot:", int.from_bytes(data[36:44], "little"))
