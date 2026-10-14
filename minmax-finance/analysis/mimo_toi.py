#!/usr/bin/env python3
"""Analyze Mimo pairs touching MinMax-relevant tokens; resolve symbols/decimals."""
import sys, json, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"

def rpc(method, params, retries=1):
    for i in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.3)
    return {}

def call_ok(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def dec_str(h):
    if not h or h == "0x": return None
    w = words(h); b = h[2:]
    if len(b) >= 128:
        off = w[0]; ln = int(b[off*2:off*2+64], 16)
        raw = bytes.fromhex(b[(off+32)*2:(off+32+ln)*2])
        try: return raw.decode()
        except Exception: return raw.hex()
    return None

TOI = {
 "0xacee9b11cd4b3f57e58880277ac72c8c41abe4e4":"ioBUSD",
 "0x3b2bf2b523f54c4e454f08aa286d03115aff326c":"ioUSDC",
 "0x6fbcdc1169b5130c59e72e51ed68a84841c98cd1":"ioUSDT",
 "0x1cbad85aa66ff3c12dc84c5881886eeb29c1bb9b":"ioDAI",
 "0x84abcb2832be606341a50128aeb1db43aa017449":"BUSD-bsc",
 "0x037346e5a5722957ac2cab6ceb8c74fc18cea91d":"USDC_b",
 "0x42c9255d5e522e83b16ea11a3ba04c2d3afca079":"USDT_b",
 "0x3cdb7c48e70b854ed2fa392e21687501d84b3afc":"USDT-matic",
 "0x62a9d987cbf4c45a550deed5b57b200d7a319632":"DAI-matic",
 "0xc04da3a99d17135857bb937d2fbb321d3b6c6a81":"USDC-matic",
 "0xec690cdd448e3cbb51ed135df72301c3265a8f80":"XIM",
 "0xa00744882684c3e4747faefd68d283ea44099d03":"WIOTX",
 "0x97e6c48867fdc391a8dfe9d169ecd005d1d90283":"BNB-bsc",
}
TOI = {k.lower(): v for k, v in TOI.items()}

if __name__ == "__main__":
    infos = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "mimo_pair_infos.json"))
    hits = [r for r in infos if (r["t0"] or "").lower() in TOI or (r["t1"] or "").lower() in TOI]
    print("pairs involving our tokens:", len(hits), flush=True)
    need = set()
    for r in hits:
        need.add((r["t0"] or "").lower()); need.add((r["t1"] or "").lower())
    def meta(t):
        return {"addr": t, "sym": dec_str(call_ok(t, "0x95d89b41")), "dec": (words(call_ok(t, "0x313ce567")) or [None])[0]}
    with ThreadPoolExecutor(max_workers=16) as ex:
        metas = list(ex.map(meta, sorted(need)))
    m = {x["addr"]: x for x in metas}
    out = {"hits": hits, "meta": m}
    json.dump(out, open("mimo_toi_pairs.json", "w"), indent=1)
    for x in metas:
        print(f"  {x['addr']} {str(x['sym']):14s} dec={x['dec']}", flush=True)
    print("", flush=True)
    for r in hits:
        t0 = (r["t0"] or "").lower(); t1 = (r["t1"] or "").lower()
        s0 = m.get(t0, {}).get("sym") or TOI.get(t0); s1 = m.get(t1, {}).get("sym") or TOI.get(t1)
        d0 = m.get(t0, {}).get("dec"); d1 = m.get(t1, {}).get("dec")
        a0 = r["r0"] / 10**d0 if (r["r0"] is not None and d0) else None
        a1 = r["r1"] / 10**d1 if (r["r1"] is not None and d1) else None
        print(f"{r['pair']}  {str(s0):12s}/{str(s1):12s}  {a0:>18.4f} / {a1:>18.4f}", flush=True)
    print("done", flush=True)
