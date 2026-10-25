#!/usr/bin/env python3
"""READ-ONLY. Enumerate Unichain ImmutableProxy contracts, extract immutable impl,
read reward-token balances. Public keyless RPC only (no secrets). Writes JSON to this folder."""
import json, os, re, sys
import urllib.request

RPC = os.environ.get("UNICHAIN_RPC", "https://mainnet.unichain.org")
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "enum", "ci-out", "search_ImmutableProxy.json")
VAULT_IMPL = "0x3fd339e58769a56d08dcd2683f9012e881287476"
TOKENS = {
    "USDC_unichain": "0x078D782b760474a361dDA0AF3839290b0EF57AD6",
    "TOK2": "0x9151434b16b9763660705744891fA906F660EcC5",
}

def rpc_batch(calls):
    body = json.dumps([{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research"})
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.loads(r.read())
    res = [None]*len(calls)
    if isinstance(out, dict):
        raise RuntimeError("RPC error: " + json.dumps(out)[:300])
    for o in out:
        if isinstance(o, dict):
            res[o["id"]] = o.get("result")
    return res

def main():
    addrs = [it["address"]["hash"] for it in json.load(open(SRC))]
    out = []
    # batch 40 at a time
    for i in range(0, len(addrs), 5):
        chunk = addrs[i:i+5]
        codes = rpc_batch([("eth_getCode", [a, "latest"]) for a in chunk])
        impls = []
        for c in codes:
            m = re.search(r"7f([0-9a-fA-F]{64})5af4", c or "")
            impls.append("0x"+m.group(1)[24:].lower() if m else None)
        bcalls = []
        for a in chunk:
            for t in TOKENS.values():
                data = "0x70a08231" + "0"*24 + a[2:].lower()
                bcalls.append(("eth_call", [{"to":t,"data":data}, "latest"]))
        bals = rpc_batch(bcalls)
        k = 0
        for j, a in enumerate(chunk):
            row = {"addr": a, "impl": impls[j]}
            for name in TOKENS:
                v = bals[k]; k += 1
                row[name] = int(v, 16) if v and v != "0x" else 0
            out.append(row)
        print(f"scanned {i+len(chunk)}/{len(addrs)}", file=sys.stderr)
    json.dump(out, open(os.path.join(HERE, "vault_scan.json"), "w"), indent=1)
    vaults = [r for r in out if r["impl"] == VAULT_IMPL]
    funded = [r for r in vaults if r["USDC_unichain"] > 0 or r["TOK2"] > 0]
    print("total proxies", len(out))
    print("vault-impl proxies", len(vaults))
    print("funded vaults", len(funded))
    print("sum USDC_unichain", sum(r["USDC_unichain"] for r in funded)/1e6)
    print("sum TOK2", sum(r["TOK2"] for r in funded))
    json.dump(funded, open(os.path.join(HERE, "funded_vaults.json"), "w"), indent=1)
    for r in funded[:40]:
        print(r["addr"], r["USDC_unichain"]/1e6, r["TOK2"])

if __name__ == "__main__":
    main()
