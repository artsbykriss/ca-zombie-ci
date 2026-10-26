#!/usr/bin/env python3
"""Batched full scan of a DexFiVaultFactory chain. Read-only eth_call.

Phases (each batched) so the whole chain (all vaults) can be enumerated fast:
  1. per-vault: publishData, totalSupply, native balance, owner, farmsCount
  2. per (vault,farmIdx): farms(idx) -> beacon, percent
  3. per (vault,beacon): farmConnector
  4. per connector: stakingToken, tokenId
  5. NFT farms: positions(tokenId), stakingTokenData() -> pool, slot0()
  6. token farms: liquidity(conn), balanceOf(conn)
"""
import json, os, sys, time
import rpc_scan as R

BATCH = 40

def multi(url, calls):
    out = [None] * len(calls)
    idxs = list(range(len(calls)))
    for _ in range(6):
        todo = [i for i in idxs if out[i] is None]
        if not todo:
            break
        for i in range(0, len(todo), BATCH):
            chunk = todo[i:i+BATCH]
            res = R.rpc_batch(url, [calls[j] for j in chunk])
            for k, j in enumerate(chunk):
                if res[k] is not None:
                    out[j] = res[k]
    return out

def scan(chain):
    fac = R.FACTORY[chain]; nat = R.NATIVE[chain]
    url = R.working_rpc(chain, fac, "0x" + R.SEL["vaultsCount"])
    print(f"[{chain}] using rpc {url.split('://')[0]}://...", flush=True)
    n = R.dec_uint(R.call_one(url, fac, "0x" + R.SEL["vaultsCount"]))
    print(f"[{chain}] vaultsCount={n}", flush=True)
    # phase 0: addresses
    addrs = [None]*n
    res = multi(url, [(fac, "0x"+R.SEL["vaults"]+R.enc_uint(i)) for i in range(n)])
    for i,h in enumerate(res): addrs[i] = R.dec_addr(h)
    print(f"[{chain}] resolved {sum(1 for a in addrs if a)}/{n} vault addrs", flush=True)

    recs = {}
    # phase 1
    calls=[]
    for v in addrs:
        if not v: continue
        calls += [(v,"0x"+R.SEL["publishData"]),(v,"0x"+R.SEL["totalSupply"]),
                  (nat,"0x"+R.SEL["balanceOf"]+R.enc_addr(v)),(v,"0x"+R.SEL["farmsCount"]),
                  (v,"0x"+R.SEL["owner"])]
    r1 = multi(url, calls)
    vs = [v for v in addrs if v]
    for k,v in enumerate(vs):
        b = r1[5*k:5*k+5]
        rec = {"vault": v, "farms": []}
        pd = b[0]
        if pd and len(pd) >= 130:
            rec["published"] = int(pd[2:66],16) != 0
            rec["publisher"] = R.dec_addr("0x"+pd[90:130])
        rec["supply"] = R.dec_uint(b[1]); rec["nativeBal"] = R.dec_uint(b[2])
        rec["farmsCount"] = R.dec_uint(b[3]) or 0; rec["owner"] = R.dec_addr(b[4])
        recs[v] = rec
    print(f"[{chain}] phase1 done", flush=True)

    # phase 2: farms()
    pairs = [(v,j) for v in vs for j in range(recs[v]["farmsCount"])]
    r2 = multi(url, [(v, "0x"+R.SEL["farms"]+R.enc_uint(j)) for v,j in pairs])
    for (v,j),h in zip(pairs,r2):
        if not h or len(h) < 194: continue
        beacon = "0x"+h[2+64+24:2+128]; percent = int(h[2+128:2+192],16)
        recs[v]["farms"].append({"beacon":beacon,"percent":percent})
    print(f"[{chain}] phase2 done ({len(pairs)} farms)", flush=True)

    # phase 3: farmConnector
    bc = [(v,f["beacon"]) for v in vs for f in recs[v]["farms"]]
    r3 = multi(url, [(v, "0x"+R.SEL["farmConnector"]+R.enc_addr(beacon)) for v,beacon in bc])
    for (v,beacon),h in zip(bc,r3):
        for f in recs[v]["farms"]:
            if f["beacon"] == beacon: f["connector"] = R.dec_addr(h)
    print(f"[{chain}] phase3 done", flush=True)

    # phase 4: stakingToken / tokenId
    conns = []
    for v in vs:
        for f in recs[v]["farms"]:
            if f.get("connector"): conns.append(f["connector"])
    r4 = multi(url, [(c,"0x"+R.SEL["stakingToken"]) for c in conns] + [(c,"0x"+R.SEL["tokenId"]) for c in conns])
    st = {c: R.dec_addr(r4[i]) for i,c in enumerate(conns)}
    tid = {c: R.dec_uint(r4[len(conns)+i]) for i,c in enumerate(conns)}
    for v in vs:
        for f in recs[v]["farms"]:
            c = f.get("connector")
            if c: f["stakingToken"] = st.get(c); f["tokenId"] = tid.get(c)
    print(f"[{chain}] phase4 done ({len(conns)} connectors)", flush=True)

    # phase 5: NFT positions + pool + slot0
    nft = [(v,f) for v in vs for f in recs[v]["farms"] if f.get("tokenId") and f["tokenId"]>0 and f.get("stakingToken")]
    calls=[]
    for v,f in nft:
        calls.append((f["stakingToken"], "0x"+R.SEL["positions"]+R.enc_uint(f["tokenId"])))
    for v,f in nft:
        calls.append((f["connector"], "0x"+R.SEL["stakingTokenData"]))
    r5 = multi(url, calls)
    pools = {}
    for i,(v,f) in enumerate(nft):
        h = r5[i]
        if h and len(h) >= 2+64*12:
            w = lambda k: h[2+64*k:2+64*(k+1)]
            def s24(x):
                v = x & 0xFFFFFF
                return v - 0x1000000 if v >= 0x800000 else v
            f["pos_token0"] = R.dec_addr("0x"+w(2)); f["pos_token1"] = R.dec_addr("0x"+w(3))
            f["pos_fee"] = int(w(4),16); f["pos_tickLower"] = s24(int(w(5),16)); f["pos_tickUpper"] = s24(int(w(6),16))
            f["pos_liq"] = int(w(7),16); f["pos_owed0"] = int(w(10),16); f["pos_owed1"] = int(w(11),16)
        sd = r5[len(nft)+i]
        if sd and len(sd) >= 2+64*6:
            pool = R.dec_addr("0x"+sd[2+128:2+192])
            f["pool"] = pool
            if pool: pools[pool] = None
    # slot0 for pools
    pl = list(pools.keys())
    r6 = multi(url, [(p,"0x"+R.SEL["slot0"]) for p in pl])
    for p,h in zip(pl,r6):
        if h and len(h) >= 66: pools[p] = int(h[2:66],16)
    for v in vs:
        for f in recs[v]["farms"]:
            if f.get("pool"): f["sqrtPriceX96"] = pools.get(f["pool"])
    print(f"[{chain}] phase5 done ({len(nft)} nft farms)", flush=True)

    # phase 6: token farms liquidity + balance
    tf = [(v,f) for v in vs for f in recs[v]["farms"] if f.get("connector") and not (f.get("tokenId") and f["tokenId"]>0) and f.get("stakingToken")]
    calls=[]
    for v,f in tf: calls.append((f["connector"], "0x"+R.SEL["liquidity"]+R.enc_addr(f["connector"])))
    for v,f in tf: calls.append((f["stakingToken"], "0x"+R.SEL["balanceOf"]+R.enc_addr(f["connector"])))
    r7 = multi(url, calls)
    for i,(v,f) in enumerate(tf):
        f["liq"] = R.dec_uint(r7[i]); f["balance"] = R.dec_uint(r7[len(tf)+i])
    print(f"[{chain}] phase6 done ({len(tf)} token farms)", flush=True)

    od = os.environ.get("CI_OUT", "ci-out")
    os.makedirs(od, exist_ok=True)
    fn = os.path.join(od, f"scan_{chain}.json")
    json.dump({"chain":chain,"vaultsCount":n,"records":[recs[v] for v in vs]}, open(fn,"w"))
    print(f"[{chain}] wrote {fn} ({len(vs)} vaults)", flush=True)

if __name__ == "__main__":
    chains = sys.argv[1:] or ["base"]
    for c in chains:
        try:
            scan(c)
        except Exception as e:
            print(f"[{c}] ERROR {e}", flush=True)
