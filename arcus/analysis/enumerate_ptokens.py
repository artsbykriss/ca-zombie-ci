#!/usr/bin/env python3
"""Enumerate all Arcus pTokens via public RPC (read-only). Rebuild after folder loss."""
import json, sys, urllib.request

RPC = "https://rpc.mainnet.chain.robinhood.com"
FACTORY = "0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB"
USDG = "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168"

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 arcus-analysis/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        d = json.load(r)
    if "error" in d: raise RuntimeError(d["error"])
    return d["result"]

def call(to, data):
    try:
        return rpc("eth_call", [{"to": to, "data": data}, "latest"])
    except Exception:
        return None

def u(h): return int(h, 16) if h else None
def s(h):
    if not h: return None
    b = bytes.fromhex(h[2:]); ln = int.from_bytes(b[32:64], "big"); return b[64:64+ln].decode()
def addr(h):
    if not h: return None
    return "0x" + h[2:][24:]

pad_u = lambda x: f"{x:064x}"
pad_a = lambda a: "0"*24 + a.lower().replace("0x","")

n = 0; tokens = []
while n < 40:
    r = call(FACTORY, "0xb806d460" + pad_u(n))
    if not r: break
    tokens.append(addr(r)); n += 1

block = int(rpc("eth_blockNumber", []), 16)
out = {"chainId": 4663, "factory": FACTORY, "asset": USDG, "assetSymbol": "USDG",
       "assetDecimals": 6, "snapshotBlock": block, "pTokens": []}

total_nav = 0; total_supply = 0
for i, t in enumerate(tokens):
    rec = {"index": i, "address": t}
    rec["name"] = s(call(t, "0x06fdde03"))
    rec["symbol"] = s(call(t, "0x95d89b41"))
    rec["decimals"] = u(call(t, "0x313ce567"))
    rec["asset"] = addr(call(t, "0x38d52e0f"))
    ta = u(call(t, "0x01e1d114")); rec["totalAssets"] = ta
    tsx = u(call(t, "0x18160ddd")); rec["totalSupply"] = tsx
    rec["depositFeeBps"] = u(call(t, "0xab879827"))
    p = call(t, "0x60da3e83"); rec["depositsPaused"] = bool(u(p)) if p else None
    rec["requestTtl"] = u(call(t, "0x3aa9c131"))
    rec["managerOf"] = addr(call(FACTORY, "0x7f41826b" + pad_a(t)))
    bal = call(USDG, "0x70a08231" + pad_a(t)); rec["usdgBalanceHeldByToken"] = u(bal)
    rec["convertToShares_1e6"] = u(call(t, "0xc6e6f592" + pad_u(10**6)))
    rec["convertToAssets_1e18"] = u(call(t, "0x07a2d13a" + pad_u(10**18)))
    rec["convertToShares_1"] = u(call(t, "0xc6e6f592" + pad_u(1)))
    dead = "0x000000000000000000000000000000000000dEaD"
    rec["maxDeposit_dead"] = u(call(t, "0x402d267d" + pad_a(dead)))
    rec["maxMint_dead"] = u(call(t, "0xc63d75b6" + pad_a(dead)))
    rec["maxRedeem_dead"] = u(call(t, "0xd905777e" + pad_a(dead)))
    rec["factoryTokenLimit_1f5f81f5"] = u(call(FACTORY, "0x1f5f81f5" + pad_a(t)))
    if ta and tsx:
        rec["impliedPriceAssetsPer1e18Shares"] = ta * 10**18 / tsx
        rec["pricePerShare_usdg"] = (ta / 1e6) / (tsx / 1e18)
    else:
        rec["impliedPriceAssetsPer1e18Shares"] = None
        rec["pricePerShare_usdg"] = None
    if ta: total_nav += ta
    if tsx: total_supply += tsx
    out["pTokens"].append(rec)

out["totalNAV_usdgRaw"] = total_nav
out["totalNAV_usd"] = total_nav / 1e6
out["totalSupplyShares"] = total_supply / 1e18
out["nonEmptyTokens"] = sum(1 for t in out["pTokens"] if t["totalAssets"])
out["notes"] = {
    "formula": "convertToShares(a)=a*(TS+vs)*1000/(TA_stored+1); convertToAssets(s)=s*(TA_stored+1)/((TS+vs)*1000); TA_stored=pToken ns 0xd9fd..2a00+0x0a = TA*1000; vs=ns+0x07 (pTEST=1e9, all others=1e7)",
    "deposit_gate": "per-account remaining deposit quota at pToken ns +0x12[account] (maxDeposit returns it); deposit reverts 0x6565c4ec(amount,quota) if amount>quota; factory allowlist isAllowed(token,account)=map5[token][account]||map6[account]",
    "nav_source": "totalAssets is stored NAV (not balanceOf(this)); updated via privileged paths",
}
json.dump(out, open("/home/heisenberg/CA/arcus/analysis/child-ptoken-inventory.json", "w"), indent=1)
print(f"tokens={len(tokens)} totalNAV_usd={out['totalNAV_usd']:.6f} block={block}")
