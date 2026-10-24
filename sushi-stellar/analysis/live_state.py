#!/usr/bin/env python3
"""Read-only live-state sweep for Sushi Stellar pools (keyless public RPC).
simulateTransaction + ledger reads only. No signing, no sending.
Writes analysis/live_state.json
"""
import json, sys, time
from concurrent.futures import ThreadPoolExecutor
from stellar_sdk import SorobanServer, TransactionBuilder, Network, scval, Address, xdr

sys.path.insert(0, "/home/heisenberg/CA/sushi-stellar/analysis")
from sval import py

RPC = "https://mainnet.sorobanrpc.com"
NET = Network.PUBLIC_NETWORK_PASSPHRASE
SRC = "GCFB64LD5OX6XXUQW44LXAE7RAHORF2FJTSQ3DXEAV6DXVOML433X6HF"
FACTORY = "CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF"
_s = SorobanServer(RPC)

def sim(cid, fn, params=None):
    acct = _s.load_account(SRC)
    tx = (TransactionBuilder(source_account=acct, network_passphrase=NET, base_fee=100000)
          .append_invoke_contract_function_op(contract_id=cid, function_name=fn, parameters=params or [])
          .set_timeout(60).build())
    r = _s.simulate_transaction(tx)
    if getattr(r, "error", None):
        return {"__error__": r.error[:120]}
    if r.results and getattr(r.results[0], "xdr", None):
        try:
            return py(xdr.SCVal.from_xdr(r.results[0].xdr))
        except Exception as e:
            return {"__decode__": str(e)}
    return None

def A(a): return Address(a).to_xdr_sc_val()

def pool_info(pool):
    out = {"pool": pool}
    for fn in ("token0", "token1", "fee", "is_paused", "protocol_fees", "liquidity"):
        try:
            out[fn] = sim(pool, fn)
        except Exception as e:
            out[fn] = f"err:{e}"
    t0, t1 = out.get("token0"), out.get("token1")
    for k, t in (("bal0", t0), ("bal1", t1)):
        if isinstance(t, str) and t.startswith("C"):
            try:
                out[k] = sim(t, "balance", [A(pool)])
            except Exception as e:
                out[k] = f"err:{e}"
    return out

def token_meta(t):
    m = {"token": t}
    for fn in ("symbol", "name", "decimals"):
        try:
            m[fn] = sim(t, fn)
        except Exception as e:
            m[fn] = f"err:{e}"
    return m

if __name__ == "__main__":
    pools = json.load(open("/home/heisenberg/CA/sushi-stellar/analysis/pools.json"))
    cur = sorted({p["pool_address"] for p in pools if p["_factory"] == "current"})
    leg = sorted({p["pool_address"] for p in pools if p["_factory"] == "legacy"})
    print("current pools:", len(cur), "legacy pools:", len(leg), flush=True)
    ledger = _s.get_latest_ledger().sequence
    res = {"latest_ledger": ledger, "rpc": "<keyless public>", "current": [], "legacy": []}
    with ThreadPoolExecutor(max_workers=8) as ex:
        res["current"] = list(ex.map(pool_info, cur))
    print("current done", flush=True)
    with ThreadPoolExecutor(max_workers=8) as ex:
        res["legacy"] = list(ex.map(pool_info, leg))
    print("legacy done", flush=True)
    # token metadata
    toks = set()
    for row in res["current"] + res["legacy"]:
        for k in ("token0", "token1"):
            v = row.get(k)
            if isinstance(v, str) and v.startswith("C"):
                toks.add(v)
    with ThreadPoolExecutor(max_workers=8) as ex:
        res["tokens"] = list(ex.map(token_meta, sorted(toks)))
    res["latest_ledger_after"] = _s.get_latest_ledger().sequence
    json.dump(res, open("/home/heisenberg/CA/sushi-stellar/analysis/live_state.json", "w"), indent=1)
    print("wrote live_state.json; tokens:", len(toks))
