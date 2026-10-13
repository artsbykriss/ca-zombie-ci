#!/usr/bin/env python3
"""Read-only live-state dump v2 for MonoSwap V3 (Blast) — individual calls, parallel.
Keyless public RPCs only. No transactions. Writes analysis/live_state2.json.
"""
import json, time, urllib.request, concurrent.futures as cf

RPCS = ["https://blast-rpc.publicnode.com", "https://rpc.blast.io", "https://blast.drpc.org"]
FACTORY = "0x48d0F09710794313f33619c95147F34458BF7C3b"
USDB = "0x4300000000000000000000000000000000000003"
WETH = "0x4300000000000000000000000000000000000004"
BLAST = "0x4300000000000000000000000000000000000002"

SEL = {
    "slot0": "0x3850c7bd", "liquidity": "0x1a686502", "protocolFees": "0x1ad8b03b",
    "fee": "0xddca3f43", "tickSpacing": "0xd0c93a7c", "token0": "0x0dfe1681",
    "token1": "0xd21220a7", "factory": "0xc45a0155", "balanceOf": "0x70a08231",
    "owner": "0x8da5cb5b", "feeAmountTickSpacing": "0x22afcccb",
    "getClaimableAmount": "0xe12f3a61",
    "readGasParams": "0xdde798a4",  # readGasParams(address)
    "readClaimableYield": "0xec3278e8",  # readClaimableYield(address) - verify
}

def call(rpc_url, to, data, retries=4):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    for a in range(retries):
        try:
            req = urllib.request.Request(rpc_url, data=body,
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                d = json.loads(r.read())
            if "result" in d:
                return d["result"], None
            return None, str(d.get("error"))[:100]
        except Exception as e:
            if a == retries - 1:
                return None, str(e)[:100]
            time.sleep(0.4 * (a + 1))
    return None, "exhausted"

def main():
    # latest block
    def single(method, params):
        for rpc_url in RPCS:
            try:
                body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
                req = urllib.request.Request(rpc_url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                return json.loads(urllib.request.urlopen(req, timeout=20).read())["result"]
            except Exception:
                continue
        raise RuntimeError("no rpc for " + method)
    latest = int(single("eth_blockNumber", []), 16)
    ts = int(single("eth_getBlockByNumber", [hex(latest), False])["timestamp"], 16)

    pools = json.load(open("/home/heisenberg/CA/monoswap-v3/analysis/pools.json"))
    addr_word = lambda a: "000000000000000000000000" + a[2:].lower()

    tasks = []  # (key, to, data)
    tasks.append((("FACTORY", "owner"), FACTORY, SEL["owner"]))
    for f in (100, 500, 3000, 10000, 250, 2000):
        tasks.append((("FACTORY", f"fee:{f}"), FACTORY, SEL["feeAmountTickSpacing"] + hex(f)[2:].rjust(64, "0")))
    for p in pools:
        pool = p["pool"]
        for name in ("slot0", "liquidity", "protocolFees", "fee", "tickSpacing", "factory"):
            tasks.append(((pool, name), pool, SEL[name]))
        for t in (p["t0"], p["t1"]):
            tasks.append(((pool, "bal:" + t.lower()), t, SEL["balanceOf"] + addr_word(pool)))
            if t.lower() in (USDB, WETH):
                tasks.append(((pool, "claim:" + t.lower()), t, SEL["getClaimableAmount"] + addr_word(pool)))
        # Blast gas + yield via predeploy
        tasks.append(((pool, "gasParams"), BLAST, SEL["readGasParams"] + addr_word(pool)))

    results = {}
    errs = {}
    def run(i_t):
        i, (key, to, data) = i_t
        rpc_url = RPCS[i % len(RPCS)]
        res, err = call(rpc_url, to, data)
        if res is None:
            res, err = call(RPCS[(i + 1) % len(RPCS)], to, data)
        return key, res, err
    with cf.ThreadPoolExecutor(max_workers=6) as ex:
        for key, res, err in ex.map(run, list(enumerate(tasks))):
            results[key] = res
            if err:
                errs[key] = err

    def word(h, k=0): return h[2:][k*64:(k+1)*64]
    def addr_of(w): return "0x" + w[-40:]
    def u(w): return int(w, 16)
    def i24(w):
        v = int(w, 16)
        return v - 2**24 if v >= 2**23 else v

    out = {"block": latest, "block_timestamp": ts, "factory": FACTORY, "pools": {},
           "errors": {str(k): v for k, v in errs.items()}}
    out["factory_owner"] = addr_of(word(results[("FACTORY", "owner")]))
    out["fee_tiers"] = {}
    for f in (100, 500, 3000, 10000, 250, 2000):
        h = results.get(("FACTORY", f"fee:{f}"))
        if h:
            v = i24(word(h))
            if v != 0:
                out["fee_tiers"][f] = v
    for p in pools:
        pool = p["pool"]
        rec = {"t0": p["t0"], "t1": p["t1"]}
        s0 = results.get((pool, "slot0"))
        if s0 and len(s0) >= 2 + 64 * 7:
            rec["sqrtPriceX96"] = str(u(word(s0, 0)))
            rec["tick"] = i24(word(s0, 1))
            rec["observationCardinality"] = u(word(s0, 3))
            rec["observationCardinalityNext"] = u(word(s0, 4))
            rec["feeProtocol"] = u(word(s0, 5))
            rec["unlocked"] = u(word(s0, 6)) != 0
        lq = results.get((pool, "liquidity"))
        rec["liquidity"] = str(u(lq)) if lq else None
        pf = results.get((pool, "protocolFees"))
        if pf:
            rec["protocolFees0"] = str(u(word(pf, 0)))
            rec["protocolFees1"] = str(u(word(pf, 1)))
        fe = results.get((pool, "fee"))
        rec["fee"] = u(fe) if fe else None
        txs = results.get((pool, "tickSpacing"))
        rec["tickSpacing"] = i24(txs) if txs else None
        fac = results.get((pool, "factory"))
        rec["factory_ok"] = bool(fac) and addr_of(word(fac)).lower() == FACTORY.lower()
        for key, t in (("t0", p["t0"]), ("t1", p["t1"])):
            b = results.get((pool, "bal:" + t.lower()))
            rec["bal_" + key] = str(u(b)) if b else None
            if t.lower() in (USDB, WETH):
                c = results.get((pool, "claim:" + t.lower()))
                rec["claimable_" + key] = str(u(c)) if c else None
        gp = results.get((pool, "gasParams"))
        if gp and len(gp) >= 2 + 64 * 4:
            rec["gas_etherSeconds"] = str(u(word(gp, 0)))
            rec["gas_etherBalance"] = str(u(word(gp, 1)))
            rec["gas_lastUpdated"] = u(word(gp, 2))
            rec["gas_mode"] = u(word(gp, 3))
        out["pools"][pool] = rec
    json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/live_state2.json", "w"), indent=1)
    print("block", latest, "ts", ts, "owner", out["factory_owner"], "fee_tiers", out["fee_tiers"])
    print("errors:", len(out["errors"]))
    no_slot0 = [k for k, v in out["pools"].items() if "sqrtPriceX96" not in v]
    print("pools without slot0:", len(no_slot0), no_slot0[:5])
    bad_fac = [k for k, v in out["pools"].items() if not v.get("factory_ok")]
    print("factory mismatch:", len(bad_fac), bad_fac[:5])
    nz = [k for k, v in out["pools"].items() if v.get("bal_t0", "0") not in (None, "0") or v.get("bal_t1", "0") not in (None, "0")]
    print("nonzero pools:", len(nz))

if __name__ == "__main__":
    main()
