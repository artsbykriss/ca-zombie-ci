#!/usr/bin/env python3
"""CI live-state dump for Gambit Vault (BSC). Keyless; reads only.

Writes ci-out/gambit-live-state.json. Never prints or stores an RPC URL with a key.
"""
import json, os, urllib.request

RPC = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
BLOCK = int(os.environ.get("PIN_BLOCK", "131443197"))
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT, exist_ok=True)

VAULT = "0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B"
USDG = "0x85E76cbf4893c1fbcB34dCF1239A91CE2A4CF5a7"
TOKENS = {
    "USDT": "0x55d398326f99059fF775485246999027B3197955",
    "USDC": "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
    "BUSD": "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",
    "WBNB": "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
    "BTCB": "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",
    "ETH": "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
}
PAIRS = {
    "USDG/WBNB": "0x66B59a36008Ba346DeAc6969A2e752EE0f865710",
    "USDG/BUSD": "0x7Fea0c6022D81EE17146324E4F55f6A02E138Dab",
    "USDG/GMT": "0xa41e57459f09a126F358E118b693789d088eA8A0",
    "USDG/AUTO": "0x0523FD5C53ea5419B4DAF656BC1b157dDFE3ce50",
}
MIGRATORS = ["0xDEF2af818514c1Ca1A9bBe2a4D45E28f260063f9", "0x0472F402EA8E301D7595545884Ad4C420E9865d6"]


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, body, {"Content-Type": "application/json", "User-Agent": "ca-research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        d = json.load(r)
    if "error" in d:
        raise RuntimeError(d["error"])
    return d["result"]


def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, hex(BLOCK)])


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def enc_u256(n):
    return hex(n)[2:].rjust(64, "0")


def sel(sig):
    # selectors are fixed in the report; avoid an extra keccak dependency
    return {
        "balanceOf(address)": "0x70a08231",
        "totalSupply()": "0x18160ddd",
        "poolAmounts(address)": "0x52f55eed",
        "feeReserves(address)": "0x1ce9cb8f",
        "getMaxPrice(address)": "0xe124e6d2",
        "getRedemptionAmount(address,uint256)": "0x2c668ec1",
        "whitelistedTokens(address)": "0xdaf9c210",
        "getReserves()": "0x0902f1ac",
        "token0()": "0x0dfe1681",
        "isMintingEnabled()": "0x55c7ba14",
    }[sig]


def u(r):
    return int(r, 16) if r and r != "0x" else 0


def addr(r):
    return "0x" + r[-40:] if r and r != "0x" else None


out = {"chain": "bsc", "block": BLOCK, "vault": VAULT, "usdg": USDG, "tokens": {}, "pairs": {}, "migrators": {}}

supply = u(call(USDG, sel("totalSupply()")))
out["usdg_total_supply"] = str(supply)
pool_usd = 0
face = 0
for sym, tok in TOKENS.items():
    d = {}
    d["balance"] = str(u(call(tok, sel("balanceOf(address)") + enc_addr(VAULT))))
    d["poolAmount"] = str(u(call(VAULT, sel("poolAmounts(address)") + enc_addr(tok))))
    d["feeReserves"] = str(u(call(VAULT, sel("feeReserves(address)") + enc_addr(tok))))
    price = u(call(VAULT, sel("getMaxPrice(address)") + enc_addr(tok)))
    d["price_1e30"] = str(price)
    d["redemption_1000e18"] = str(u(call(VAULT, sel("getRedemptionAmount(address,uint256)") + enc_addr(tok) + enc_u256(10**21))))
    d["whitelisted"] = bool(u(call(VAULT, sel("whitelistedTokens(address)") + enc_addr(tok))))
    dec = 18  # all six Gambit tokens are 18-decimals
    usd = int(d["poolAmount"]) * price // (10**30) if price else 0
    d["pool_value_usd_1e18"] = str(int(usd))
    pool_usd += usd
    if sym in ("USDT", "USDC", "BUSD"):
        face += int(d["poolAmount"])
    out["tokens"][sym] = d

out["pool_value_usd_1e18"] = str(pool_usd)
out["backing_per_usdg_1e18"] = str(pool_usd * 10**18 // supply if supply else 0)
out["at_face_capacity_1e18"] = str(face)
out["is_minting_enabled"] = bool(u(call(VAULT, sel("isMintingEnabled()"))))

for name, p in PAIRS.items():
    try:
        r = call(p, sel("getReserves()"))
        w = [r[2 + i * 64:2 + (i + 1) * 64] for i in range(3)]
        t0 = addr(call(p, sel("token0()")))
        out["pairs"][name] = {
            "pair": p, "token0": t0,
            "reserve0": str(u("0x" + w[0])), "reserve1": str(u("0x" + w[1])),
        }
    except Exception as e:
        out["pairs"][name] = {"pair": p, "error": str(e)}

for i, m in enumerate(MIGRATORS):
    out["migrators"][m] = {
        "usdg": str(u(call(USDG, sel("balanceOf(address)") + enc_addr(m)))),
        "whitelisted_usdg": bool(u(call(m, "0xdaf9c210" + enc_addr(USDG)))),
    }

# Optional: full holder list via Ankr advanced API (key read from env, never written).
ankr = os.environ.get("ANKR_API_KEY")
if ankr:
    try:
        holders = []
        token = None
        for _ in range(10):
            p = {"blockchain": "bsc", "contractAddress": USDG, "pageSize": 1000}
            if token:
                p["pageToken"] = token
            body = json.dumps({"jsonrpc": "2.0", "method": "ankr_getTokenHolders", "params": p, "id": 1}).encode()
            req = urllib.request.Request("https://rpc.ankr.com/multichain/" + ankr, body, {"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as r:
                res = json.load(r).get("result") or {}
            holders += res.get("holders", [])
            token = res.get("nextPageToken")
            if not token or not res.get("holders"):
                break
        out["holders_count"] = len(holders)
        out["holders_top"] = [
            {"address": h["holderAddress"], "balance": h["balance"]} for h in holders[:25]
        ]
        mig_sum = sum(int(out["migrators"][m]["usdg"]) for m in MIGRATORS)
        out["float_usdg"] = str(supply - mig_sum)
    except Exception as e:
        out["holders_error"] = str(e)

json.dump(out, open(os.path.join(OUT, "gambit-live-state.json"), "w"), indent=1)
print(json.dumps({k: out[k] for k in ("block", "usdg_total_supply", "pool_value_usd_1e18", "backing_per_usdg_1e18", "at_face_capacity_1e18")}, indent=1))
