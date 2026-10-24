#!/usr/bin/env python3
"""Enumerate Sushi Stellar pools + upgrades from factory events (stellar.expert, keyless). Read-only."""
import json, urllib.request, time
from stellar_sdk import xdr, Address

FACTORIES = {
    "current": "CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF",
    "legacy":  "CCRSMJDITH3VK5QOGYCVZDAKIY5GL3RCG4TCVLIAVB662IW2V5KJGZGF",
}

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "research-readonly"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def scval_to_py(val):
    t = val.type
    if t == xdr.SCValType.SCV_ADDRESS:
        return Address.from_xdr_sc_address(val.address).address
    if t == xdr.SCValType.SCV_U32:
        return val.u32.uint32
    if t == xdr.SCValType.SCV_U64:
        return val.u64.uint64
    if t == xdr.SCValType.SCV_I32:
        return val.i32.int32
    if t == xdr.SCValType.SCV_BOOL:
        return val.b
    if t == xdr.SCValType.SCV_SYMBOL:
        return val.sym.sc_symbol.decode()
    if t == xdr.SCValType.SCV_BYTES:
        return bytes(val.bytes.sc_bytes).hex()
    return str(val)

def parse_body(b64):
    v = xdr.SCVal.from_xdr(b64)
    out = {}
    if v.type == xdr.SCValType.SCV_MAP:
        for m in v.map.sc_map:
            k = m.key.sym.sc_symbol.decode() if m.key.type == xdr.SCValType.SCV_SYMBOL else str(m.key)
            out[k] = scval_to_py(m.val)
    return out

def enumerate_events(cid, label):
    url = f"https://api.stellar.expert/explorer/public/contract/{cid}/events?order=asc&limit=200"
    recs, pages = [], 0
    while url and pages < 40:
        d = fetch(url)
        batch = d["_embedded"]["records"]
        recs.extend(batch)
        pages += 1
        nxt = d["_links"].get("next", {}).get("href")
        if not batch or not nxt:
            break
        url = "https://api.stellar.expert" + nxt
        print(f"  {label} page {pages}: +{len(batch)} (total {len(recs)})", flush=True)
        time.sleep(0.2)
    return recs

if __name__ == "__main__":
    allpools, upgrades = [], []
    for label, cid in FACTORIES.items():
        recs = enumerate_events(cid, label)
        pools = [r for r in recs if r["topics"] and r["topics"][0] == "pool_created"]
        print(f"# {label} {cid}: {len(recs)} events, {len(pools)} pool_created", flush=True)
        for r in pools:
            b = parse_body(r["bodyXdr"])
            b["_ledger"] = int(r["id"].split("-")[0]); b["_ts"] = r["ts"]; b["_factory"] = label
            b["_initiator"] = r["initiator"]; allpools.append(b)
        for r in recs:
            if r["topics"] and r["topics"][0] == "pool_upgraded":
                b = parse_body(r["bodyXdr"]); b["_ledger"] = int(r["id"].split("-")[0]); b["_ts"] = r["ts"]
                upgrades.append(b)
    json.dump(allpools, open("/home/heisenberg/CA/sushi-stellar/analysis/pools.json", "w"), indent=1)
    json.dump(upgrades, open("/home/heisenberg/CA/sushi-stellar/analysis/pool_upgrades.json", "w"), indent=1)
    print("TOTAL pools:", len(allpools), "upgrades:", len(upgrades))
    seen = {}
    for p in allpools: seen[p["pool_address"]] = p
    print("UNIQUE pools:", len(seen))
    for p in allpools:
        print(p["_factory"], p["_ledger"], p["fee"], p.get("tick_spacing"), p["token0"], p["token1"], "->", p["pool_address"])
