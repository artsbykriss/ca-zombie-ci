#!/usr/bin/env python3
"""CI live-state dump for the ApolloX diamond (BSC). Keyless; reads only.

Writes ci-out/apollox-live-state.json. Never prints or stores an RPC URL with a key.
"""
import json, os, urllib.request

RPC = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
BLOCK = int(os.environ.get("PIN_BLOCK", "131443197"))
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "ci-out")
os.makedirs(OUT, exist_ok=True)

DIAMOND = "0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0"
USDT = "0x55d398326f99059fF775485246999027B3197955"
SAFE = "0x60EdE4402a34762D608AD9bA7bD3797f5bFE544c"


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


def enc_addr_arr(a):
    return (32).to_bytes(32, "big").hex() + (1).to_bytes(32, "big").hex() + enc_addr(a)


def words(r):
    b = r[2:]
    return [b[i:i + 64] for i in range(0, len(b), 64)]


def u(w):
    return int(w, 16)


def a(w):
    return "0x" + w[-40:]


out = {"chain": "bsc", "block": BLOCK, "diamond": DIAMOND, "usdt": USDT}
try:
    fj = json.load(open(os.path.join(HERE, "apollox_facets.json")))
    out["facets"] = len(fj["facets"])
    out["selectors"] = sum(len(f["selectors"]) for f in fj["facets"])
    out["facet_names"] = [f["name"] for f in fj["facets"]]
except Exception as e:
    out["facets_error"] = str(e)

# USDT balance
out["usdt_balance"] = str(u(words(call(USDT, "0x70a08231" + enc_addr(DIAMOND)))[0]))

# itemValue(USDT)
w = words(call(DIAMOND, "0x34516647" + enc_addr(USDT)))
out["item_value_usdt"] = {
    "token": a(w[0]), "value": str(u(w[1])), "decimals": u(w[2]),
    "valueUsd": str(u(w[3])), "targetWeight": u(w[4]),
}
# getTotalValueUsd()
out["total_value_usd"] = str(u(words(call(DIAMOND, "0xb4c63100"))[0]))
# paused()
out["paused"] = bool(u(words(call(DIAMOND, "0x5c975abb"))[0]))

# revenues([USDT])
r = call(DIAMOND, "0x3c3598d5" + enc_addr_arr(USDT))
w = words(r)
# dynamic array of static structs: offset, length, then 3 words each
ln = u(w[1])
rev = []
for i in range(ln):
    base = 2 + i * 3
    rev.append({"token": a(w[base]), "total": str(u(w[base + 1])), "pending": str(u(w[base + 2]))})
out["revenues_usdt"] = rev

# traderAssets([USDT]) -> (uint8,address,uint256)
r = call(DIAMOND, "0x515120a8" + enc_addr_arr(USDT))
w = words(r)
ln = u(w[1])
ta = []
for i in range(ln):
    base = 2 + i * 3
    ta.append({"purpose": u(w[base]), "token": a(w[base + 1]), "value": str(u(w[base + 2]))})
out["trader_assets_usdt"] = ta

# role / Safe
out["default_admin_count"] = str(u(words(call(DIAMOND, "0xca15c873" + "0" * 64))[0]))
out["default_admin_0"] = a(words(call(DIAMOND, "0x9010d07c" + "0" * 64 + hex(0)[2:].rjust(64, "0")))[0])
try:
    out["safe_threshold"] = str(u(words(call(SAFE, "0xe75235b8"))[0]))  # getThreshold()
    r = call(SAFE, "0xa0e67e2b")  # getOwners()
    w = words(r)
    ln = u(w[1])
    out["safe_owners"] = [a(w[2 + i]) for i in range(ln)]
except Exception as e:
    out["safe_error"] = str(e)

json.dump(out, open(os.path.join(OUT, "apollox-live-state.json"), "w"), indent=1)
print(json.dumps({k: out.get(k) for k in ("facets", "selectors", "usdt_balance", "total_value_usd", "paused", "revenues_usdt", "default_admin_count", "safe_threshold")}, indent=1))
