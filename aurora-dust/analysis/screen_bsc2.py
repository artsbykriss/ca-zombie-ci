#!/usr/bin/env python3
"""Token metadata + price for L2-27 residual tokens; deeper state checks."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

DEC_SEL = sel("decimals()")
SYM_SEL = sel("symbol()")
TS_SEL = sel("totalSupply()")
PAUSED_SEL = sel("paused()")
SLOT0_SEL = sel("slot0()")
GR_SEL = sel("getReserves()")

TOKENS = {
    "FIST": ("bsc", "0xc9882dEF23bc42D53895b8361D0b1EDC7570Bc6A"),
    "BTX": ("bsc", "0xAa242a47F4cC074E59cbC7D65309B1F21202AaA3"),
    "DHC": ("bsc", "0x743F15f4d2481774d970f286f0EbAD9C3Daed6E9"),
    "UP": ("bsc", "0x36F20660b9947929Ab3edd8727B5Af60260333A7"),
    "GDC": ("bsc", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822"),
    "MSN": ("bsc", "0xd8b3ef86afce18edba91fed481abe22f173597c1"),
    "USDT_bsc": ("bsc", "0x55d398326f99059fF775485246999027B3197955"),
}

def get_decimals(chain, addr):
    r = rpc(chain, "eth_call", [{"to": addr, "data": DEC_SEL}, "latest"])
    try: return int(r, 16)
    except Exception: return None

def get_symbol(chain, addr):
    r = rpc(chain, "eth_call", [{"to": addr, "data": SYM_SEL}, "latest"])
    if isinstance(r, str) and len(r) >= 130:
        try:
            b = bytes.fromhex(r[2:])
            return b[64:].rstrip(b"\x00").decode(errors="replace") if len(b) > 64 else b.rstrip(b"\x00").decode(errors="replace")
        except Exception: return r[:20]
    return r

def llama_prices(coins):
    ids = [f"{c[0]}:{c[1]}" for c in coins]
    url = "https://coins.llama.fi/prices/current/" + ",".join(ids)
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "research"}), timeout=30) as r:
        return json.load(r)

if __name__ == "__main__":
    meta = {}
    for name, (chain, addr) in TOKENS.items():
        d = get_decimals(chain, addr)
        s = get_symbol(chain, addr)
        meta[name] = {"addr": addr, "decimals": d, "symbol": s}
        print(f"{name:10s} dec={d} sym={s}")
    # prices
    try:
        pr = llama_prices([(v[0], v[1]) for v in TOKENS.values()])
        for name, (chain, addr) in TOKENS.items():
            key = f"{chain}:{addr}"
            p = (pr.get("coins") or {}).get(key, {})
            meta[name]["price_usd"] = p.get("price")
            print(f"{name:10s} price=${p.get('price')}")
    except Exception as e:
        print("price ERR", e)
    json.dump(meta, open("/home/heisenberg/CA/aurora-dust/analysis/l2-27-token-meta.json", "w"), indent=1)

    # deeper state: pausers + pairs
    checks = [
        ("BeatXswap vest1 paused", "bsc", "0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D", PAUSED_SEL),
        ("BeatXswap vest2 paused", "bsc", "0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F", PAUSED_SEL),
        ("BeatXswap pool slot0", "bsc", "0xA5Db84d7BCcb799fb31bd3c417D04d5bC29Da96D", SLOT0_SEL),
        ("GDC pair getReserves", "bsc", "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c", GR_SEL),
        ("GDC totalSupply", "bsc", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822", TS_SEL),
        ("LPBonus code", "bsc", "0x52272524a22f941f5489c1233732797314bb054b", None),
        ("DHC impl code", "bsc", "0x5abb3fe2a02e5d4320862944cd3a0b8f6af28ce1", None),
        ("Unifi mgr code", "bsc", "0x5D8aA15505aFEc01Bab0dE21F9377673B5246EAE", None),
    ]
    for label, chain, addr, s in checks:
        if s is None:
            r = rpc(chain, "eth_getCode", [addr, "latest"])
            print(f"{label:26s} codelen={len(r)//2-1 if isinstance(r,str) else r}")
        else:
            r = rpc(chain, "eth_call", [{"to": addr, "data": s}, "latest"])
            print(f"{label:26s} -> {r}")
