#!/usr/bin/env python3
"""Live-state dump for the Secured Finance in-block price-ratio re-check.

Read-only. RPC URL from the environment (FORK_RPC_URL / RPC_URL) with a keyless fallback.
No URL or key is ever written to disk.
"""
import json
import os
import urllib.request

RPC = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
CTRL = "0x35e9D8e0223A75E51a67aa731127C91Ea0779Fe2"
VAULT = "0xB74749b2213916b1dA3b869E41c7c57f1db69393"
TOKENS = {
    "WBTC": ("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", 8),
    "USDC": ("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", 6),
    "WETH": ("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", 18),
}
CCYS = ["WBTC", "USDC", "ETH", "JPYC"]
OUT = os.path.join(os.path.dirname(__file__), "..", "ci-out", "live-state.json")


ENDPOINTS = [RPC, "https://ethereum-rpc.publicnode.com", "https://1rpc.io/eth", "https://eth.drpc.org"]
_state = {"i": 0}


def rpc(method, params):
    last = None
    for _ in range(len(ENDPOINTS) * 2):
        url = ENDPOINTS[_state["i"] % len(ENDPOINTS)]
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.load(r)
            if "result" in out:
                return out["result"]
            last = out.get("error")
        except Exception as e:  # rotate endpoint on any transport/HTTP error
            last = e
        _state["i"] += 1
    raise RuntimeError(f"all RPC endpoints failed: {last}")


def call(to, sig, args=()):
    data = "0x" + sig + "".join((a[2:] if a.startswith("0x") else a) for a in args)
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])


def b32(s):
    return "0x" + s.encode().hex().ljust(64, "0")


def enc_uint(v):
    return hex(v)[2:].rjust(64, "0")


def sel(sig):
    # minimal keccak-free approach: use cast if present
    import subprocess
    return subprocess.run(["cast", "sig", sig], capture_output=True, text=True).stdout.strip()[2:]


def main():
    head = int(rpc("eth_blockNumber", []), 16)
    out = {"chain": "ethereum", "block": head, "controller": CTRL, "vault": VAULT, "balances": {}, "books": {}}
    impl_slot = rpc("eth_getStorageAt", [CTRL, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])
    out["controller_impl"] = "0x" + impl_slot[-40:]
    vimpl = rpc("eth_getStorageAt", [VAULT, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])
    out["vault_impl"] = "0x" + vimpl[-40:]
    for sym, (addr, dec) in TOKENS.items():
        bal = int(rpc("eth_call", [{"to": addr, "data": "0x" + sel("balanceOf(address)") + "0" * 24 + VAULT[2:].lower()}, "latest"]), 16)
        out["balances"][sym] = {"raw": bal, "amount": bal / 10**dec}
    CC = "0x7dca6b6BF30cd28ADe83e86e21e82e3F852bF2DC"  # CurrencyController (via AddressResolver 0x4488d83e...)
    out["haircut"] = {}
    for ccy in CCYS:
        try:
            out["haircut"][ccy] = int(call(CC, sel("getHaircut(bytes32)"), [b32(ccy)]) or "0x0", 16)
        except Exception:
            out["haircut"][ccy] = None
    for ccy in CCYS:
        try:
            md = int(call(CTRL, sel("getMinDebtUnitPrice(bytes32)"), [b32(ccy)]) or "0x0", 16)
        except Exception:
            md = None
        out.setdefault("min_debt_unit_price", {})[ccy] = md
        try:
            raw = call(CTRL, sel("getMaturities(bytes32)"), [b32(ccy)])
        except Exception:
            out["books"][ccy] = "no market"
            continue
        words = [raw[2 + i:2 + i + 64] for i in range(0, len(raw) - 2, 64)]
        n = int(words[1], 16) if len(words) > 1 else 0
        mats = [int(words[2 + i], 16) for i in range(n)]
        books = []
        market = None
        try:
            market = "0x" + call(CTRL, sel("getLendingMarket(bytes32)"), [b32(ccy)])[-40:]
        except Exception:
            pass
        for m in mats:
            try:
                rng = call(CTRL, sel("getOrderUnitPriceRange(bytes32,uint256)"), [b32(ccy), enc_uint(m)])
                w = [rng[2 + i:2 + i + 64] for i in range(0, len(rng) - 2, 64)]
                vals = [int(x, 16) for x in w]
                mnow = int(call(CTRL, sel("getCurrentMinDebtUnitPrice(bytes32,uint256)"), [b32(ccy), enc_uint(m)]) or "0x0", 16)
                min_borrow = vals[2]
                p = max(min_borrow, mnow)
                ready = None
                if market:
                    try:
                        obid = int(call(CTRL, sel("getOrderBookId(bytes32,uint256)"), [b32(ccy), enc_uint(m)]), 16)
                        ready = bool(int(call(market, sel("isReady(uint8)"), [enc_uint(obid)]) or "0x0", 16))
                    except Exception:
                        ready = None
                books.append({
                    "maturity": m,
                    "min_lend": vals[0], "max_lend": vals[1],
                    "min_borrow": min_borrow, "max_borrow": vals[3],
                    "reference": vals[4], "is_min_debt_reference": bool(vals[5]),
                    "min_debt_unit_price_now": mnow,
                    "effective_valuation_price": p,
                    "edge_bps_of_fv": round((1 - 1.25 * p / 10000) * 10000, 1),
                    "ready": ready,
                })
            except Exception as e:
                books.append({"maturity": m, "error": str(e)[:80]})
        out["books"][ccy] = books
    best = None
    for ccy, books in out["books"].items():
        if not isinstance(books, list):
            continue
        for b in books:
            if "edge_bps_of_fv" in b and b.get("ready", True):
                if best is None or b["edge_bps_of_fv"] > best["edge_bps_of_fv"]:
                    best = dict(b, ccy=ccy)
    out["best_tradeable"] = best
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w"), indent=2)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
