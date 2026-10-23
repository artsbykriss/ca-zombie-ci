#!/usr/bin/env bash
# ApeX Omni (zkLink custody) — live read-only state capture.
# Keyless public RPCs only. No secrets. Writes ci-out/apex-omni-live.json.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[apex-omni] start $(date -u +%FT%TZ)"

python3 - <<'PY'
import json, urllib.request, time

def rpc(url, method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 (research)"})
    for _ in range(3):
        try:
            return json.load(urllib.request.urlopen(req, timeout=30)).get("result")
        except Exception:
            time.sleep(2)
    return None

def call(url, to, data):
    return rpc(url, "eth_call", [{"to":to,"data":data}, "latest"])

def addr(x):
    return "0x"+x[-40:] if x and len(x) >= 42 else x

# chain -> (rpc, custody proxy, [(sym, token, decimals)])
CHAINS = {
 "ethereum": ("https://ethereum-rpc.publicnode.com", "0x35D173cdfE4d484BC5985fDa55FABad5892c7B82", [
    ("USDC","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",6),
    ("USDT","0xdAC17F958D2ee523a2206206994597C13D831ec7",6),
    ("WBTC","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",8),
    ("USDe","0x4c9EDD5852cd905f086C759E8383e09bff1E68B3",18),
    ("WETH","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",18),
    ("cbBTC","0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",8)]),
 "bsc": ("https://bsc-rpc.publicnode.com", "0xb8d9f005654b7b127b34dae8f973ba729ca3a2d9", [
    ("USDT","0x55d398326f99059fF775485246999027B3197955",18),
    ("USDC","0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",18),
    ("USD1","0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d",18)]),
 "arbitrum": ("https://arbitrum-one-rpc.publicnode.com", "0x3169844a120c0f517b4eb4a750c08d8518c8466a", [
    ("USDT","0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",6),
    ("USDC","0xaf88d065e77c8cC2239327C5EDb3A432268e5831",6),
    ("WETH","0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",18)]),
 "base": ("https://base-rpc.publicnode.com", "0xee7981c4642de8d19aed11da3bac59277dfd59d7", [
    ("USDT","0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",6),
    ("USDC","0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",6),
    ("WETH","0x4200000000000000000000000000000000000006",18),
    ("cbBTC","0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",8)]),
 "mantle": ("https://rpc.mantle.xyz", "0x3c7c0ebfcd5786ef48df5ed127cddeb806db976c", [
    ("USDT","0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE",6),
    ("USDC","0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9",6),
    ("mETH","0xcDA86A272531e8640cD7F1a92c01839911B90bb0",18),
    ("cmETH","0xE6829d9a7eE3040e1276Fa75293Bde931859e8fA",18),
    ("FBTC","0xC96dE26018A54D51c097160568752c4E3BD6C364",8),
    ("WETH","0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111",18)]),
}

SIG = {"master":"0x5a99719e","target":"0xf00e6a2a","governor":"0xf39349ef","exodusMode":"0x264c0912",
       "getNoticePeriod":"0x2a3174f4","chainId":"0x85e1f4d0","masterChainId":"0x64494fdf",
       "totalBlocksExecuted":"0xf2235487","totalBlocksProven":"0x647b5923","periphery":"0x77aace1a"}

def bal20(url, token, owner, dec):
    r = call(url, token, "0x70a08231"+"0"*24+owner[2:].lower())
    if not r or r == "0x":
        return 0.0
    return int(r,16)/10**dec

out = {"generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "chains": {}}
for cname,(url,owner,tokens) in CHAINS.items():
    d = {"custody_proxy": owner}
    d["block"] = int(rpc(url,"eth_blockNumber",[]), 16)
    d["code_bytes"] = len(rpc(url,"eth_getCode",[owner,"latest"]))//2
    d["native"] = int(rpc(url,"eth_getBalance",[owner,"latest"]),16)/1e18
    for n,s in SIG.items():
        r = call(url, owner, s)
        d[n] = addr(r) if n in ("master","target","governor","periphery") else (int(r,16) if r and r!="0x" else r)
    for who in ("master","governor"):
        a = d.get(who)
        if isinstance(a,str) and a.startswith("0x"):
            d[who+"_code_bytes"] = len(rpc(url,"eth_getCode",[a,"latest"]))//2
    d["tokens"] = {}
    for sym,t,dec in tokens:
        d["tokens"][sym] = {"addr": t, "amount": bal20(url,t,owner,dec)}
    out["chains"][cname] = d
    print(f"[apex-omni] {cname} block={d['block']} code={d['code_bytes']} native={round(d['native'],4)} tokens={ {k:round(v['amount'],4) for k,v in d['tokens'].items()} }")

# USD pricing
ids = []
for cname,d in out["chains"].items():
    for sym,t in d["tokens"].items():
        ids.append(f"{cname}:{t['addr']}")
    ids.append(f"{cname}:0x0000000000000000000000000000000000000000")
try:
    req = urllib.request.Request("https://coins.llama.fi/prices/current/"+",".join(ids),
                                 headers={"User-Agent":"Mozilla/5.0 (research)"})
    prices = json.load(urllib.request.urlopen(req, timeout=30)).get("coins", {})
except Exception as e:
    prices = {}
    print("[apex-omni] price fetch failed:", e)

total = 0.0
for cname,d in out["chains"].items():
    subtotal = 0.0
    for sym,t in d["tokens"].items():
        key = f"{cname}:{t['addr'].lower()}"
        p = None
        for k,v in prices.items():
            if k.lower() == key:
                p = v.get("price"); break
        t["usd_price"] = p
        t["usd"] = round(t["amount"]*p, 2) if p else None
        if t["usd"]: subtotal += t["usd"]
    # native
    nat = None
    for k,v in prices.items():
        if k.lower() in (f"{cname}:0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", f"{cname}:0x0000000000000000000000000000000000000000"):
            nat = v.get("price"); break
    d["native_usd_price"] = nat
    d["native_usd"] = round(d["native"]*nat,2) if nat else None
    d["subtotal_usd"] = round(subtotal + (d["native_usd"] or 0), 2)
    total += d["subtotal_usd"]
    print(f"[apex-omni] {cname} subtotal_usd={d['subtotal_usd']}")

out["total_custody_usd"] = round(total,2)
json.dump(out, open("ci-out/apex-omni-live.json","w"), indent=1)
print(f"[apex-omni] TOTAL custody USD ~ ${out['total_custody_usd']:,.2f}")
PY

echo "[apex-omni] done $(date -u +%FT%TZ)"
