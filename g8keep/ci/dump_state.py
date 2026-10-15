#!/usr/bin/env python3
"""Enumerate g8keep factory LP holdings on Base at the latest block; verify lock state and value.
Writes ci-out/state.json. No secrets used/printed (RPC taken from BASE_RPC_URL env)."""
import json, os, sys, time, urllib.request

RPC = os.environ.get("BASE_RPC_URL") or "https://mainnet.base.org"
FALLBACKS = ["https://base.drpc.org", "https://mainnet.base.org", "https://base-rpc.publicnode.com"]

FACTORY = "0x3c0b43867cd04fedfd6a95497e5ea7e3aff8ccae"
WETH = "0x4200000000000000000000000000000000000006"
LOCK_SLOT = 6

def _post(url, payload, timeout=30):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
        headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

ENDPOINTS = [RPC] + [u for u in FALLBACKS if u != RPC]

def rpc(method, params):
    last = None
    for url in ENDPOINTS:
        try:
            d = _post(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "result" in d:
                return d["result"]
            last = str(d.get("error"))[:150]
        except Exception as e:
            last = str(e)[:150]
    raise RuntimeError(f"{method} failed: {last}")

def batch(calls, chunk=25):
    out = []
    for s in range(0, len(calls), chunk):
        part = calls[s:s+chunk]
        payload = [{"jsonrpc": "2.0", "id": j, "method": m, "params": p} for j, (m, p) in enumerate(part)]
        done = False
        for url in ENDPOINTS:
            try:
                d = _post(url, payload)
                if isinstance(d, list) and all("result" in x for x in d):
                    out.extend(x["result"] for x in d)
                    done = True
                    break
            except Exception:
                pass
        if not done:
            for m, p in part:
                out.append(rpc(m, p))
    return out

def pad(addr): return addr[2:].rjust(64, "0")
SEL = {
    "token0": "0dfe1681",
    "token1": "d21220a7",
    "getReserves": "0902f1ac",
    "totalSupply": "18160ddd",
    "balanceOf(address)": "70a08231",
    "owner()": "8da5cb5b",
    "WETH()": "ad5c4648",
    "g8keepFeeWallet()": "a68aa5c7",
    "penaltyReceiver()": "e1b7fd42",
    "g8keepTokenVesting()": "9446e118",
    "g8keepFee()": "4232c712",
    "g8keepInitialLiquidityFee()": "4de75cbd",
}

# keccak256(abi.encode(pair, slot)) requires keccak; implement minimal keccak-256 in pure python
def keccak256(data: bytes) -> bytes:
    # Keccak-256 (original padding 0x01), compact implementation
    RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
          0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
          0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
          0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
          0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
          0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
    R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
    def rol(x, n): return ((x << n) | (x >> (64 - n))) & 0xFFFFFFFFFFFFFFFF
    def f(A):
        for rnd in range(24):
            C = [A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4] for x in range(5)]
            D = [C[(x-1) % 5] ^ rol(C[(x+1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    A[x][y] ^= D[x]
            B = [[0]*5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2*x+3*y) % 5] = rol(A[x][y], R[x][y])
            for x in range(5):
                for y in range(5):
                    A[x][y] = B[x][y] ^ ((~B[(x+1) % 5][y]) & B[(x+2) % 5][y])
            A[0][0] ^= RC[rnd]
        return A
    rate = 136
    msg = bytearray(data)
    msg.append(0x01)
    while len(msg) % rate != 0:
        msg.append(0x00)
    msg[-1] ^= 0x80
    A = [[0]*5 for _ in range(5)]
    for off in range(0, len(msg), rate):
        block = msg[off:off+rate]
        for i in range(rate // 8):
            lane = int.from_bytes(block[i*8:(i+1)*8], "little")
            A[i % 5][i // 5] ^= lane
        A = f(A)
    out = bytearray()
    for i in range(4):
        out += A[i % 5][i // 5].to_bytes(8, "little")
    return bytes(out)

def pad(addr): return addr[2:].rjust(64, "0")

def main():
    bn = int(rpc("eth_blockNumber", []), 16)
    print(f"block {bn}")

    # factory roles
    roles = {}
    for name in ["owner()", "WETH()", "g8keepFeeWallet()", "penaltyReceiver()", "g8keepTokenVesting()", "g8keepFee()", "g8keepInitialLiquidityFee()"]:
        try:
            r = rpc("eth_call", [{"to": FACTORY, "data": "0x" + SEL[name]}, "latest"])
            roles[name] = r
        except Exception as e:
            roles[name] = f"ERR {e}"
    print("roles:", {k: (v[-40:] if isinstance(v, str) and len(v) > 42 else v) for k, v in roles.items()})

    # pair list from analysis file (UNI-V2 tokens held by the factory)
    data = json.load(open("analysis/factory_balances_goldrush.json"))
    pairs = [x[0] for x in data["items"] if x[1] == "UNI-V2"]
    print(f"pairs to check: {len(pairs)}")

    calls = []
    for p in pairs:
        calls.append(("eth_call", [{"to": p, "data": "0x" + SEL["token0"]}, "latest"]))
        calls.append(("eth_call", [{"to": p, "data": "0x" + SEL["token1"]}, "latest"]))
        calls.append(("eth_call", [{"to": p, "data": "0x" + SEL["getReserves"]}, "latest"]))
        calls.append(("eth_call", [{"to": p, "data": "0x" + SEL["totalSupply"]}, "latest"]))
        calls.append(("eth_call", [{"to": p, "data": "0x" + SEL["balanceOf(address)"] + pad(FACTORY)}, "latest"]))
        key = "0x" + keccak256(bytes.fromhex(pad(p)) + bytes.fromhex(hex(LOCK_SLOT)[2:].rjust(64, "0"))).hex()
        calls.append(("eth_getStorageAt", [FACTORY, key, "latest"]))
        calls.append(("eth_call", [{"to": WETH, "data": "0x" + SEL["balanceOf(address)"] + pad(p)}, "latest"]))
    res = batch(calls, chunk=25)
    print("pair calls done:", len(res))

    rows = []
    for i, p in enumerate(pairs):
        r = res[i*7:(i+1)*7]
        t0 = "0x" + r[0][-40:]
        t1 = "0x" + r[1][-40:]
        rr = r[2][2:]
        res0 = int(rr[0:64], 16); res1 = int(rr[64:128], 16)
        ts = int(r[3], 16); fb = int(r[4], 16)
        locked = int(r[5], 16)
        weth_actual = int(r[6], 16)
        share = fb / ts if ts else 0
        rows.append({
            "pair": p, "token0": t0, "token1": t1, "weth_reserve": res0, "token_reserve": res1,
            "lp_totalSupply": ts, "factory_lp": fb, "share": share, "locked": locked,
            "pair_weth_actual": weth_actual, "weth_excess": max(0, weth_actual - res0),
            "weth_attributable": res0 * share,
        })
        # per-pair token-side excess
        try:
            tb = int(rpc("eth_call", [{"to": t1, "data": "0x" + SEL["balanceOf(address)"] + pad(p)}, "latest"]), 16)
            rows[-1]["token_excess"] = max(0, tb - res1)
        except Exception as e:
            rows[-1]["token_excess"] = None

    rows.sort(key=lambda x: -x["weth_attributable"])
    tot = sum(x["weth_attributable"] for x in rows)
    n_locked = sum(1 for x in rows if x["locked"] == 1)
    excess = [x for x in rows if x["weth_excess"] or x.get("token_excess")]
    summary = {
        "block": bn, "pairs": len(rows), "pairs_locked": n_locked,
        "total_weth_attributable_wei": str(int(tot)),
        "total_weth_attributable_eth": tot / 1e18,
        "pairs_with_excess": len(excess),
        "roles": roles,
    }
    print(json.dumps({k: v for k, v in summary.items() if k != "roles"}, indent=1))
    print("top 10 pairs:")
    for x in rows[:10]:
        print(f"  {x['pair']} weth={x['weth_attributable']/1e18:.6f} share={x['share']:.6f} locked={x['locked']}")
    if excess:
        print("EXCESS (skim-able):")
        for x in excess:
            print(" ", x["pair"], "weth_excess_wei", x["weth_excess"], "token_excess_wei", x.get("token_excess"))
    out = {"summary": summary, "pairs": rows}
    json.dump(out, open("ci-out/state.json", "w"), indent=1)
    print("wrote ci-out/state.json")

if __name__ == "__main__":
    main()
