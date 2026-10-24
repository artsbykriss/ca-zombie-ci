#!/usr/bin/env python3
"""Self-contained read-only verification for the Sushi Stellar (Soroban) deployment.

Runs in CI (or locally). Keyless public endpoints only. NEVER signs or sends a
transaction: it uses Soroban `simulateTransaction` (a dry run) and read-only
ledger/event reads.

Resilient by design: probes several keyless Soroban RPC endpoints, retries with
backoff, and falls back to the committed `analysis/pools.json` if the event API
is unavailable. Records any failures instead of aborting, so the job exits 0 as
long as a result file was produced.

Outputs ci-out/sushi-stellar-ci.json and prints a human summary.
"""
import json, os, sys, time, urllib.request, base64
from concurrent.futures import ThreadPoolExecutor

RPC_CANDIDATES = [
    "https://mainnet.sorobanrpc.com",
    "https://soroban-rpc.mainnet.stellar.gateway.fm",
    "https://soroban-mainnet.stellar.org",
    "https://rpc.stellar.org",
]
FACTORY = "CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF"
LEGACY_FACTORY = "CCRSMJDITH3VK5QOGYCVZDAKIY5GL3RCG4TCVLIAVB662IW2V5KJGZGF"
POSMGR = "CARTUL5AWDZYBSN7HUUJZSKCAKCIAKM7M54Z76G6KRYCK4XPR3OHUQZ4"
ROUTER = "CDMIM23WOUL5CZBKX3GOA3V5R5AMVIMTCP52KCDQORWELAPLJ27WZCHL"
SRC = "GCFB64LD5OX6XXUQW44LXAE7RAHORF2FJTSQ3DXEAV6DXVOML433X6HF"  # tx source only (never signs)
POOL_WASM = "003710b383f9da7d650a7f719a7be479110266427817ebbed61d924505fcd7c7"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "ci-out")
FALLBACK_POOLS = os.path.join(HERE, "..", "analysis", "pools.json")

from stellar_sdk import SorobanServer, TransactionBuilder, Network, scval, Address, xdr

_s = None
RPC_USED = None

def pick_rpc():
    global _s, RPC_USED
    for url in RPC_CANDIDATES:
        try:
            s = SorobanServer(url)
            led = s.get_latest_ledger()
            if led and led.sequence:
                _s, RPC_USED = s, url
                print(f"[rpc] using {url} (latest ledger {led.sequence})")
                return
        except Exception as e:
            print(f"[rpc] {url} unavailable: {str(e)[:80]}")
    raise SystemExit("no Soroban RPC endpoint reachable")

def retry(fn, tries=4, delay=2.0):
    last = None
    for i in range(tries):
        try:
            return fn()
        except Exception as e:
            last = e
            time.sleep(delay * (i + 1))
    raise last

def A(a): return Address(a).to_xdr_sc_val()
def u128(n): return scval.to_uint128(n)
def u32(n): return scval.to_uint32(n)
def i32(n): return scval.to_int32(n)
def b(x): return scval.to_bool(x)
def u256(n): return scval.to_uint256(n)
def hints(): return scval.to_struct({"checkpoint": u32(0), "checkpoint_min": u32(0), "slot": u128(0)})

def sim(cid, fn, params=None, source=SRC):
    def once():
        acct = _s.load_account(source)
        tx = (TransactionBuilder(source_account=acct, network_passphrase=Network.PUBLIC_NETWORK_PASSPHRASE, base_fee=100000)
              .append_invoke_contract_function_op(contract_id=cid, function_name=fn, parameters=params or [])
              .set_timeout(60).build())
        return _s.simulate_transaction(tx)
    return retry(once)

def val(v):
    if isinstance(v, dict): return v
    if v is None: return None
    if v.type == xdr.SCValType.SCV_ADDRESS: return Address.from_xdr_sc_address(v.address).address
    if v.type == xdr.SCValType.SCV_U32: return v.u32.uint32
    if v.type == xdr.SCValType.SCV_I32: return v.i32.int32
    if v.type == xdr.SCValType.SCV_U64: return v.u64.uint64
    if v.type == xdr.SCValType.SCV_BOOL: return v.b
    if v.type == xdr.SCValType.SCV_SYMBOL: return v.sym.sc_symbol.decode()
    if v.type == xdr.SCValType.SCV_STRING: return v.str.sc_string.decode()
    if v.type == xdr.SCValType.SCV_BYTES: return bytes(v.bytes.sc_bytes).hex()
    if v.type == xdr.SCValType.SCV_U128: return (v.u128.hi.uint64 << 64) + v.u128.lo.uint64
    if v.type == xdr.SCValType.SCV_I128: return (v.i128.hi.int64 << 64) + v.i128.lo.uint64
    if v.type == xdr.SCValType.SCV_U256:
        u = v.u256; return (u.hi_hi.uint64 << 192) | (u.hi_lo.uint64 << 128) | (u.lo_hi.uint64 << 64) | u.lo_lo.uint64
    if v.type == xdr.SCValType.SCV_MAP: return {val(m.key): val(m.val) for m in v.map.sc_map}
    if v.type == xdr.SCValType.SCV_VEC: return [val(x) for x in v.vec.sc_vec]
    return str(v)

def read(cid, fn, params=None, source=SRC):
    try:
        r = sim(cid, fn, params, source)
    except Exception as e:
        return {"__error__": f"rpc:{str(e)[:80]}"}
    if getattr(r, "error", None): return {"__error__": r.error.split("\n")[0][:120]}
    if r.results and getattr(r.results[0], "xdr", None):
        try: return val(xdr.SCVal.from_xdr(r.results[0].xdr))
        except Exception as e: return {"__error__": f"decode:{e}"}
    return None

def probe(cid, fn, params=None, source=SRC):
    try:
        r = sim(cid, fn, params, source)
    except Exception as e:
        return {"error": f"rpc:{str(e)[:100]}", "auth_count": 0}
    out = {"error": (r.error.split("\n")[0][:140] if getattr(r, "error", None) else None), "auth_count": 0}
    if r.results:
        a = getattr(r.results[0], "auth", None)
        out["auth_count"] = len(a or [])
    return out

def fetch_json(url, tries=4):
    def once():
        req = urllib.request.Request(url, headers={"User-Agent": "readonly-research"})
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r)
    return retry(once, tries=tries, delay=3.0)

def enumerate_pools(factory):
    """Returns (pools, event_count, source). Falls back to the committed pools.json."""
    try:
        url = f"https://api.stellar.expert/explorer/public/contract/{factory}/events?order=asc&limit=200"
        recs, pages = [], 0
        while url and pages < 20:
            d = fetch_json(url); batch = d["_embedded"]["records"]; recs.extend(batch); pages += 1
            nxt = d["_links"].get("next", {}).get("href")
            if not batch or not nxt: break
            url = "https://api.stellar.expert" + nxt
            time.sleep(0.2)
        pools = []
        for r in recs:
            if not r.get("topics") or r["topics"][0] != "pool_created": continue
            v = xdr.SCVal.from_xdr(r["bodyXdr"]); m = {}
            for e in v.map.sc_map:
                m[e.key.sym.sc_symbol.decode()] = val(e.val)
            m["_ledger"] = int(r["id"].split("-")[0])
            pools.append(m)
        return pools, len(recs), "stellar.expert"
    except Exception as e:
        print(f"[enum] stellar.expert unavailable ({str(e)[:80]}); falling back to committed pools.json")
        allp = json.load(open(FALLBACK_POOLS))
        label = "current" if factory == FACTORY else "legacy"
        pools = [{"pool_address": p["pool_address"], "token0": p["token0"], "token1": p["token1"],
                  "fee": p["fee"], "_ledger": p.get("_ledger")} for p in allp if p["_factory"] == label]
        return pools, len(pools), "analysis/pools.json (fallback)"

def pool_balances(pool):
    t0, t1 = read(pool, "token0"), read(pool, "token1")
    out = {"pool": pool, "token0": t0, "token1": t1, "fee": read(pool, "fee"),
           "protocol_fees": read(pool, "protocol_fees")}
    for k, t in (("bal0", t0), ("bal1", t1)):
        out[k] = read(t, "balance", [A(pool)]) if isinstance(t, str) and t.startswith("C") else None
    return out

def main():
    pick_rpc()
    res = {"rpc": RPC_USED, "factory": FACTORY, "legacy_factory": LEGACY_FACTORY,
           "latest_ledger": _s.get_latest_ledger().sequence}
    print("[1] factory state")
    res["factory_state"] = {
        "owner": read(FACTORY, "get_owner"),
        "flash_executor": read(FACTORY, "get_flash_executor"),
        "pool_wasm_hash": read(FACTORY, "get_pool_wasm_hash"),
        "protocol_fee0": read(FACTORY, "get_protocol_fee_0"),
        "protocol_fee1": read(FACTORY, "get_protocol_fee_1"),
        "upgrade_frozen": read(FACTORY, "is_upgrade_frozen"),
        "upgrade_permanently_disabled": read(FACTORY, "is_upgrade_permanently_disabled"),
    }
    print("    pool_wasm_hash =", res["factory_state"]["pool_wasm_hash"])
    res["pool_wasm_hash_matches_expected"] = (res["factory_state"]["pool_wasm_hash"] == POOL_WASM)

    print("[2] enumerate pools")
    cur, ncur, srcc = enumerate_pools(FACTORY)
    leg, nleg, srcl = enumerate_pools(LEGACY_FACTORY)
    res["counts"] = {"factory_events": ncur, "current_pools": len(cur), "source_current": srcc,
                     "legacy_events": nleg, "legacy_pools": len(leg), "source_legacy": srcl}
    print("   ", res["counts"])

    print("[3] read balances for current pools")
    with ThreadPoolExecutor(max_workers=6) as ex:
        res["pools"] = list(ex.map(pool_balances, sorted({p["pool_address"] for p in cur})))
    bad = [p["pool"] for p in res["pools"] if isinstance(p.get("bal0"), dict) or isinstance(p.get("bal1"), dict)]
    res["pools_unreadable_balances"] = bad
    print("    pools with unreadable balances:", len(bad))

    print("[4] authorization probes (simulateTransaction, dry-run)")
    some = res["pools"][0]["pool"] if res["pools"] else None
    s0 = read(some, "slot0") or {}
    cur_sqrt = s0.get("sqrt_price_x96") if isinstance(s0, dict) else None
    lim = u256(max(4295128739, (cur_sqrt or 2**96) - 10**24))
    probes = {
      "factory.set_protocol_fee(4,4)": (FACTORY, "set_protocol_fee", [u32(4), u32(4)]),
      "factory.set_pool_router_authorized(pool,router,true)": (FACTORY, "set_pool_router_authorized", [A(some), A(ROUTER), b(True)]),
      "factory.upgrade_pool": (FACTORY, "upgrade_pool", [A(some), scval.to_bytes(bytes.fromhex(POOL_WASM))]),
      "pool.collect_protocol(self,0,0)": (some, "collect_protocol", [A(SRC), u128(0), u128(0)]),
      "pool.set_router_authorized(factory,self,true)": (some, "set_router_authorized", [A(FACTORY), A(SRC), b(True)]),
      "pool.upgrade(poolwasm)": (some, "upgrade", [scval.to_bytes(bytes.fromhex(POOL_WASM))]),
      "pool.pause()": (some, "pause", []),
      "pool.migrate()": (some, "migrate", []),
      "pool.collect(owner=POSMGR,recipient=self)": (some, "collect", [A(POSMGR), A(SRC), i32(0), i32(10), u128(10**12), u128(10**12)]),
      "pool.flash_end()": (some, "flash_end", []),
      "pool.initialize(2^96)": (some, "initialize", [u256(2**96)]),
      "pool.swap_prefunded(router,self,true,1,limit,{})": (some, "swap_prefunded", [A(ROUTER), A(SRC), b(True), scval.to_int128(1), lim, hints()]),
      "pool.swap_prefunded(unpriv,self,...)": (some, "swap_prefunded", [A(SRC), A(SRC), b(True), scval.to_int128(1), lim, hints()]),
      "posmgr.set_admin(self)": (POSMGR, "set_admin", [A(SRC)]),
      "posmgr.upgrade(pmwasm)": (POSMGR, "upgrade", [scval.to_bytes(bytes.fromhex("be969de545da89a04508e4952e94a53a77e76ecfa67d74b23fd56e0be42290d4"))]),
      "posmgr.collect(tid=4,operator=self)": (POSMGR, "collect", [scval.to_struct({"amount0_max": u128(10**12), "amount1_max": u128(10**12), "operator": A(SRC), "recipient": A(SRC), "token_id": u32(4)})]),
      "router.init_router(factory,xlm)": (ROUTER, "init_router", [A(FACTORY), A("CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA")]),
    }
    res["auth_probes"] = {}
    for lab, (cid, fn, params) in probes.items():
        try:
            pr = probe(cid, fn, params)
            res["auth_probes"][lab] = pr
            print(f"    {lab}: err={pr.get('error')} auth_entries={pr.get('auth_count')}")
        except Exception as e:
            res["auth_probes"][lab] = {"exception": str(e)[:120]}
            print(f"    {lab}: EXC {e}")

    res["latest_ledger_after"] = _s.get_latest_ledger().sequence
    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, "sushi-stellar-ci.json")
    json.dump(res, open(p, "w"), indent=1)
    print("wrote", p)
    return res

if __name__ == "__main__":
    try:
        r = main()
        # exit non-zero only if the core invariant could not be observed at all
        ok = r.get("pool_wasm_hash_matches_expected") and r.get("counts", {}).get("current_pools", 0) > 0
        print("[ci] core invariant observed:", ok)
        sys.exit(0 if ok else 2)
    except SystemExit:
        raise
    except Exception as e:
        print("[ci] FATAL:", repr(e))
        sys.exit(3)
