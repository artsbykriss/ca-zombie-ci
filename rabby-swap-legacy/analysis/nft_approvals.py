#!/usr/bin/env python3
"""Supplementary scan: ERC-721/1155 ApprovalForAll events naming a legacy Rabby
Swap router as the operator. The arbitrary-call bug would let an attacker use an
NFT operator approval too, so we census it separately.

Read-only. RPC URLs come from env vars only.
"""
import json, os, sys, urllib.request

APPROVAL_FOR_ALL = "0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31"
SEL_IS_APPROVED_FOR_ALL = "e985e9c5"


def rpc(url, method, params, timeout=120):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def rpc_batch(url, calls):
    body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
                       for i, (m, p) in enumerate(calls)]).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"})
    data = json.load(urllib.request.urlopen(req, timeout=180))
    out = [None] * len(calls)
    for item in data:
        if "result" in item:
            out[item["id"]] = item["result"]
    return out


def pad(a):
    return "0x" + a.lower().replace("0x", "").rjust(64, "0")


def scan(chain):
    name, router = chain["name"], chain["router"]
    rpcs = [os.environ.get(e, "") for e in chain.get("rpc_env", [])] + chain.get("rpc_default", [])
    logs = None
    for url in rpcs:
        if not url:
            continue
        try:
            r = rpc(url, "eth_getLogs", [{"fromBlock": "0x0", "toBlock": "latest",
                                          "topics": [APPROVAL_FOR_ALL, None, pad(router)]}])
            if "result" in r:
                logs = r["result"]
                break
        except Exception:
            continue
    if logs is None:
        return {"chain": name, "error": "no rpc"}
    pairs = {}
    for l in logs:
        owner = "0x" + l["topics"][1][-40:]
        coll = l["address"].lower()
        blk = int(l["blockNumber"], 16)
        key = (coll, owner)
        if key not in pairs or blk >= pairs[key]:
            pairs[key] = blk
    keys = sorted(pairs)
    live = []
    for i in range(0, len(keys), 20):
        chunk = keys[i:i + 20]
        calls = [("eth_call", [{"to": c, "data": "0x" + SEL_IS_APPROVED_FOR_ALL + pad(o)[2:] + pad(router)[2:]}, "latest"])
                 for (c, o) in chunk]
        res = rpc_batch(url, calls)
        for j, (c, o) in enumerate(chunk):
            if res[j] and int(res[j], 16) == 1:
                live.append({"collection": c, "owner": o, "lastApprovalBlock": pairs[(c, o)]})
    return {"chain": name, "approval_for_all_logs": len(logs), "unique_pairs": len(pairs), "live": live}


if __name__ == "__main__":
    cfg = json.load(open(sys.argv[1]))
    outdir = sys.argv[2] if len(sys.argv) > 2 else "ci-out/raw"
    os.makedirs(outdir, exist_ok=True)
    all_res = []
    for c in cfg:
        try:
            res = scan(c)
        except Exception as e:
            res = {"chain": c["name"], "error": str(e)}
        all_res.append(res)
        print(f"[nft {c['name']}] {json.dumps(res)[:300]}", flush=True)
    json.dump(all_res, open(os.path.join(outdir, "nft_approvals_all.json"), "w"), indent=1)
