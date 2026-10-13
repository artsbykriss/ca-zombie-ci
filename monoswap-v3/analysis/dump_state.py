#!/usr/bin/env python3
"""Read-only live-state dump for MonoSwap V3 (Blast) at latest block. Batched.
Keyless public RPCs only. No transactions. Writes analysis/live_state.json.
"""
import json, time, urllib.request, concurrent.futures as cf

RPCS = ["https://rpc.blast.io", "https://blast-rpc.publicnode.com", "https://blast.drpc.org"]
FACTORY = "0x48d0F09710794313f33619c95147F34458BF7C3b"
USDB = "0x4300000000000000000000000000000000000003"
WETH = "0x4300000000000000000000000000000000000004"

SEL = {
    "slot0": "0x3850c7bd", "liquidity": "0x1a686502", "protocolFees": "0x1ad8b03b",
    "fee": "0xddca3f43", "tickSpacing": "0xd0c93a7c", "token0": "0x0dfe1681",
    "token1": "0xd21220a7", "factory": "0xc45a0155", "balanceOf": "0x70a08231",
    "owner": "0x8da5cb5b", "feeAmountTickSpacing": "0x22afcccb",
    "getClaimableAmount": "0xe12f3a61",
}

FAILS = []
def batch(rpc_url, calls):
    """calls: list of (to, data). Returns list of hex results (None on error)."""
    payload = [{"jsonrpc": "2.0", "id": i, "method": "eth_call",
                "params": [{"to": to, "data": data}, "latest"]} for i, (to, data) in enumerate(calls)]
    body = json.dumps(payload).encode()
    for a in range(4):
        try:
            req = urllib.request.Request(rpc_url, data=body,
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read())
            res = [None] * len(calls)
            if isinstance(d, dict):
                FAILS.append((rpc_url, str(d)[:200]))
                raise RuntimeError(str(d)[:100])
            for item in d:
                i = item.get("id")
                if "result" in item:
                    res[i] = item["result"]
                else:
                    FAILS.append((rpc_url, str(item.get("error"))[:120]))
            return res
        except Exception as e:
            if a == 3:
                return [None] * len(calls)
            time.sleep(1.0 * (a + 1))

def main():
    latest = int(batch(RPCS[0], [("0x0", "0x")])[0] and 0 or 0)  # placeholder
    # get latest block via single call
    import urllib.request as ur
    def single(rpc_url, method, params):
        body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
        req = ur.Request(rpc_url, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        with ur.urlopen(req, timeout=30) as r:
            return json.loads(r.read())["result"]
    latest = int(single(RPCS[0], "eth_blockNumber", []), 16)
    blk = single(RPCS[0], "eth_getBlockByNumber", [hex(latest), False])
    ts = int(blk["timestamp"], 16)
    out = {"block": latest, "block_timestamp": ts, "factory": FACTORY, "pools": {}}

    pools = json.load(open("/home/heisenberg/CA/monoswap-v3/analysis/pools.json"))
    addr_word = lambda a: "000000000000000000000000" + a[2:].lower()

    # ---- build all calls ----
    calls = [("FACTORY", "owner", FACTORY, SEL["owner"])]
    calls.append(("FACTORY", "owner_code", None, None))  # special
    for f in (100, 500, 3000, 10000, 250, 2000):
        calls.append(("FACTORY", f"feeAmountTickSpacing:{f}", FACTORY, SEL["feeAmountTickSpacing"] + hex(f)[2:].rjust(64, "0")))
    for p in pools:
        pool = p["pool"]
        for name in ("slot0", "liquidity", "protocolFees", "fee", "tickSpacing", "factory"):
            calls.append((pool, name, pool, SEL[name]))
        for t in (p["t0"], p["t1"]):
            calls.append((pool, "bal:" + t.lower(), t, SEL["balanceOf"] + addr_word(pool)))
            if t.lower() in (USDB, WETH):
                calls.append((pool, "claim:" + t.lower(), t, SEL["getClaimableAmount"] + addr_word(pool)))

    # ---- execute in parallel batches ----
    B = 10
    chunks = [(i, calls[i:i+B]) for i in range(0, len(calls), B)]
    results = {}
    def run(chunk):
        idx, cs = chunk
        rpc_url = RPCS[(idx // B) % len(RPCS)]
        sub = [(c[2], c[3]) for c in cs if c[2] is not None]
        res = batch(rpc_url, sub)
        return idx, cs, res
    with cf.ThreadPoolExecutor(max_workers=4) as ex:
        for idx, cs, res in ex.map(run, chunks):
            j = 0
            for c in cs:
                if c[2] is None:
                    results[(c[0], c[1])] = None
                    continue
                results[(c[0], c[1])] = res[j]
                j += 1

    def word(h, k=0):
        return h[2:][k*64:(k+1)*64]
    def addr_of(w): return "0x" + w[-40:]
    def u(w): return int(w, 16)
    def i24(w):
        v = int(w, 16)
        return v - 2**24 if v >= 2**23 else v

    out["factory_owner"] = addr_of(word(results[("FACTORY", "owner")]))
    out["factory_owner_code_size"] = len(single(RPCS[0], "eth_getCode", [out["factory_owner"], "latest"])[2:]) // 2
    out["fee_tiers"] = {}
    for f in (100, 500, 3000, 10000, 250, 2000):
        h = results[("FACTORY", f"feeAmountTickSpacing:{f}")]
        if h:
            v = i24(word(h))
            if v != 0:
                out["fee_tiers"][f] = v
    for p in pools:
        pool = p["pool"]
        rec = {"t0": p["t0"], "t1": p["t1"]}
        s0 = results[(pool, "slot0")]
        if s0 and len(s0) >= 2 + 64*7:
            rec["sqrtPriceX96"] = str(u(word(s0, 0)))
            rec["tick"] = i24(word(s0, 1))
            rec["observationIndex"] = u(word(s0, 2))
            rec["observationCardinality"] = u(word(s0, 3))
            rec["observationCardinalityNext"] = u(word(s0, 4))
            rec["feeProtocol"] = u(word(s0, 5))
            rec["unlocked"] = u(word(s0, 6)) != 0
        lq = results[(pool, "liquidity")]
        rec["liquidity"] = str(u(lq)) if lq else None
        pf = results[(pool, "protocolFees")]
        if pf:
            rec["protocolFees0"] = str(u(word(pf, 0)))
            rec["protocolFees1"] = str(u(word(pf, 1)))
        fe = results[(pool, "fee")]
        rec["fee"] = u(fe) if fe else None
        tsx = results[(pool, "tickSpacing")]
        rec["tickSpacing"] = i24(tsx) if tsx else None
        fac = results[(pool, "factory")]
        rec["factory_ok"] = bool(fac) and addr_of(word(fac)).lower() == FACTORY.lower()
        for key, t in (("t0", p["t0"]), ("t1", p["t1"])):
            b = results[(pool, "bal:" + t.lower())]
            rec["bal_" + key] = str(u(b)) if b else None
            if t.lower() in (USDB, WETH):
                c = results[(pool, "claim:" + t.lower())]
                rec["claimable_" + key] = str(u(c)) if c else None
        out["pools"][pool] = rec
    json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/live_state.json", "w"), indent=1)
    print("block", latest, "ts", ts, "owner", out["factory_owner"], "owner_code", out["factory_owner_code_size"])
    print("fee_tiers", out["fee_tiers"])
    nz = [(k, v) for k, v in out["pools"].items() if v.get("bal_t0", "0") not in (None, "0") or v.get("bal_t1", "0") not in (None, "0")]
    print("pools:", len(out["pools"]), "nonzero-balance pools:", len(nz))
    tot_claim = 0
    for k, v in out["pools"].items():
        c0 = int(v.get("claimable_t0") or 0); c1 = int(v.get("claimable_t1") or 0)
        if c0 or c1: tot_claim += 1
    print("pools with claimable yield (USDB/WETH):", tot_claim)
    print("batch failures:", len(FAILS), FAILS[:3])

if __name__ == "__main__":
    main()
