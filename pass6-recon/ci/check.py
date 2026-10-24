#!/usr/bin/env python3
"""ZH4-PASS6 residual reconciliation — CI validation (read-only, public RPCs only).

1. validates summary.json counts against analysis/rows.json
2. re-reads the OPEN-list live funds at public RPCs (eth_getBalance / eth_call balanceOf)
3. scans the folder for keyed-RPC-URL / secret patterns (must be 0)
Writes ci-out/validation.json and ci-out/live_checks.json. No secrets used.
"""
import json, os, re, sys, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

RPCS = {
  "ethereum": "https://eth.drpc.org",
  "base": "https://mainnet.base.org",
  "bsc": "https://bsc-rpc.publicnode.com",
  "unichain": "https://mainnet.unichain.org",
  "ink": "https://rpc-gel.inkonchain.com",
  "ronin": "https://api.roninchain.com/rpc",
}
TOKENS = {
  "ethereum": {"USDT":"0xdAC17F958D2ee523a2206206994597C13D831ec7","USDC":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","WETH":"0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"},
  "bsc": {"USDT":"0x55d398326f99059fF775485246999027B3197955","USDW":"0xe5eBE2AE0a036C955bfF58291826C50F7d670D43"},
  "base": {},
}

def rpc(url, method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"zh4-recon"})
    with urllib.request.urlopen(req, timeout=25) as r:
        return json.load(r).get("result")

def native(chain, addr):
    r = rpc(RPCS[chain], "eth_getBalance", [addr, "latest"])
    return int(r,16) if r else None

def balance_of(chain, token, holder):
    data = "0x70a08231" + "0"*24 + holder[2:].lower()
    r = rpc(RPCS[chain], "eth_call", [{"to":token,"data":data}, "latest"])
    return int(r,16) if r else None

# (label, chain, address, [(token_symbol, decimals)]) — native always included
CHECKS = [
  ("ETH whitelist-router 0x278d858f", "ethereum", "0x278d858f05b94576c1e6f73285886876ff6ef8d2", [("USDT",6),("USDC",6),("WETH",18)]),
  ("BSC whitelist-router sibling 0xa9010523", "bsc", "0xa90105231a00a4d8047347be65b3f134b3706250", [("USDT",18)]),
  ("BSC 0x6aba0315 proxy", "bsc", "0x6aba0315493b7e6989041c91181337b662fb1b90", [("USDT",18)]),
  ("Base Prodigy.Fi V2 PositionManager", "base", "0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7", []),
  ("Base Tapir DepegPool", "base", "0x195F79D6174b9ffC115fC5E82dC724F613D658C6", []),
  ("BSC Wager Predict SpotEngine", "bsc", "0x76b91e83f2A12dc52E33f856eeA300E5B3A62c0c", [("USDW",6)]),
  ("Base Nullmask pool", "base", "0xd64EF1417EB047ed0b54736a5a41F01178C391c6", []),
  ("Unichain ImmutableProxy clone", "unichain", "0x966107c49c98d49fD4Fb5CaBec1F326Cfd7Dcb60", []),
  ("Ink ChimeraQuoteHook404", "ink", "0xD723B53D1A651D8BfD6b4C8876D51b68E26128CC", []),
  ("Ronin BondingCurveManager", "ronin", "0xCF6Aa3d88431D73C76b9650e64a995a5edDb5f54", []),
  ("Base Doppler XDP Staking", "base", "0x27ad92D4500964a061b9e5Ae836bfB5d9Dbe3e9E", []),
]

def main():
    res = {"ok": True, "checks": [], "errors": []}
    # 1. counts vs rows.json
    rows = json.load(open(os.path.join(ROOT,"analysis","rows.json")))
    summ = json.load(open(os.path.join(ROOT,"summary.json")))
    mism = [k for k,v in rows["counts"].items() if summ.get("counts",{}).get(k) != v]
    res["count_reconciliation"] = {"rows_counts":rows["counts"], "mismatches":mism}
    if mism:
        res["ok"] = False; res["errors"].append(f"count mismatch: {mism}")

    # 2. live re-reads
    live = {"blocks": {}, "reads": {}}
    for chain in RPCS:
        try:
            live["blocks"][chain] = int(rpc(RPCS[chain],"eth_blockNumber",[]),16)
        except Exception as e:
            live["blocks"][chain] = None
    for label, chain, addr, toks in CHECKS:
        rec = {"chain":chain,"address":addr,"native_wei":None,"tokens":{}}
        try:
            rec["native_wei"] = native(chain, addr)
        except Exception as e:
            rec["native_err"] = str(e); res["ok"]=False
        for sym,dec in toks:
            try:
                rec["tokens"][sym] = balance_of(chain, TOKENS[chain][sym], addr)
            except Exception as e:
                rec["tokens"][sym] = "err:"+str(e)
        live["reads"][label] = rec
    json.dump(live, open(os.path.join(OUT,"live_checks.json"),"w"), indent=2)

    # 3. secret / keyed-URL scan
    pat = re.compile(r"(https?://[^\s\"']*(api[-_]?key|apikey|alchemy\.com/v2|infura\.io/v3|drpc\.org/[A-Za-z0-9]{16,})|0x[a-fA-F0-9]{64})")
    hits = []
    for dirpath,_,files in os.walk(ROOT):
        if "ci-artifacts" in dirpath or ".git" in dirpath: continue
        for fn in files:
            if fn.endswith((".pyc",)): continue
            p = os.path.join(dirpath,fn)
            try: txt = open(p, errors="ignore").read()
            except Exception: continue
            for m in pat.finditer(txt):
                # a 0x{64} could be a storage slot constant; only flag keyed URLs
                if m.group(1): hits.append(f"{os.path.relpath(p,ROOT)}: {m.group(1)[:40]}...")
    res["secret_scan"] = {"keyed_url_hits": len(hits), "hits": hits[:10]}
    if hits:
        res["ok"] = False; res["errors"].append(f"{len(hits)} keyed-URL hits")

    res["checks"] = [{"label":l,"native_wei":live["reads"][l]["native_wei"]} for l,_,_,_ in CHECKS]
    json.dump(res, open(os.path.join(OUT,"validation.json"),"w"), indent=2)
    print(json.dumps(res, indent=2))
    return 0 if res["ok"] else 1

if __name__ == "__main__":
    sys.exit(main())
