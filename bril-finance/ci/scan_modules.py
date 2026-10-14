#!/usr/bin/env python3
"""Scan ALL modules of the Bril Safe 0x05cC3CA6... : probe rebalance()/performUpkeep() from an
unprivileged address and trace the ones that execute, extracting vault.rebalance args + any pool swap.
Read-only eth_call/debug_traceCall. Uses BSC_RPC_URL (env) for calls and optional DRPC for traces.
Writes ci-out/modules-scan.json. Never prints secrets.
"""
import json, os, re, subprocess, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "ci-out", "modules-scan.json")
SAFE = "0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12"
ATTACKER = "0x000000000000000000000000000000000000dEaD"

def pick_rpc():
    for k in ("BRIL_RPC", "BSC_RPC_URL"):
        v = os.environ.get(k, "")
        if v: return v
    return "https://bsc-rpc.publicnode.com"

RPC = pick_rpc()
TRACE_RPC = None
if os.environ.get("DRPC_API_KEY"):
    TRACE_RPC = f"https://lb.drpc.org/ogrpc?network=bsc&dkey={os.environ['DRPC_API_KEY']}"

def rpc_call(method, params, url=None, timeout=120):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    req = urllib.request.Request(url or RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    for attempt in range(3):
        try:
            return json.load(urllib.request.urlopen(req, timeout=timeout))
        except Exception as e:
            last = e
    return {"error": str(last)}

def sel(sig):
    return subprocess.check_output(["cast", "sig", sig], text=True).strip()

def batch_calls(calls, frm=None):
    payload = []
    for i, (to, data) in enumerate(calls):
        p = {"to": to, "data": data}
        if frm: p["from"] = frm
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call", "params": [p, "latest"]})
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    for attempt in range(3):
        try:
            r = json.load(urllib.request.urlopen(req, timeout=180))
            break
        except Exception as e:
            err = e
    else:
        return [("err", str(err))] * len(calls)
    m = {x["id"]: x for x in r}
    return [("ok", m[i].get("result")) if "error" not in m[i] else ("err", str(m[i]["error"])[:200]) for i in range(len(payload))]

def enumerate_modules():
    mods = []
    start = "0x0000000000000000000000000000000000000001"
    for _ in range(10):
        h = batch_calls([(SAFE, sel("getModulesPaginated(address,uint256)") + start[2:].rjust(64, "0") + hex(100)[2:].rjust(64, "0"))])[0]
        if h[0] != "ok": break
        hx = h[1][2:]
        off = int(hx[0:64], 16) // 32
        nxt = "0x" + hx[64:128][-40:]
        ln = int(hx[off*64:(off+1)*64], 16)
        arr = ["0x" + hx[(off+1+i)*64:(off+2+i)*64][-40:] for i in range(ln)]
        mods += arr
        if nxt.lower() == "0x0000000000000000000000000000000000000001": break
        start = nxt
    return mods

def trace_args(strategy):
    """Return (vault_rebalance_args, pool_swap_seen) or None."""
    if not TRACE_RPC: return None, None
    payload = {"jsonrpc": "2.0", "id": 1, "method": "debug_traceCall",
               "params": [{"from": ATTACKER, "to": strategy, "data": "0x7d7c2a1c"}, "latest", {"tracer": "callTracer"}]}
    req = urllib.request.Request(TRACE_RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    try:
        d = json.load(urllib.request.urlopen(req, timeout=180))
        t = d.get("result")
    except Exception:
        return None, None
    if not t: return None, None
    flat = []
    def walk(n, dep=0):
        flat.append((dep, n))
        for c in n.get("calls", []) or []: walk(c, dep + 1)
    walk(t)
    vr = None; sw = None
    def i24(w):
        v = int(w, 16)
        return v - (1 << 256) if v >= (1 << 255) else v
    for _, n in flat:
        inp = n.get("input", "") or ""
        if inp.startswith("0xd87346aa") and vr is None:
            w = [inp[10:][i:i+64] for i in range(0, 320, 64)]
            vr = {"vault": n.get("to"), "baseLo": i24(w[0]), "baseUp": i24(w[1]), "limitLo": i24(w[2]),
                  "limitUp": i24(w[3]), "swapQuantity": i24(w[4])}
        if inp.startswith("0x128acb08") and sw is None:
            sw = {"pool": n.get("to"), "zeroForOne": int(inp[10:][:64], 16) == 1,
                  "amountSpecified": i24(inp[10:][64:128])}
    return vr, sw

def main():
    mods = enumerate_modules()
    print("modules:", len(mods))
    s_reb = sel("rebalance()")
    s_paused = sel("paused()")
    s_vault = sel("vault()")
    s_owner = sel("owner()")
    res = batch_calls([(m, s_reb) for m in mods], frm=ATTACKER)
    ok = [m for m, r in zip(mods, res) if r[0] == "ok"]
    print("rebalance() succeeds from attacker:", len(ok))
    extra = batch_calls([(m, s_paused) for m in ok] + [(m, s_vault) for m in ok] + [(m, s_owner) for m in ok])
    n = len(ok)
    out = {"block": None, "n_modules": len(mods), "n_rebalance_ok": len(ok), "ready": [], "modules": mods}
    bn = rpc_call("eth_blockNumber", [])
    if "result" in bn: out["block"] = int(bn["result"], 16)
    for i, m in enumerate(ok):
        rec = {"module": m,
               "paused": extra[i][1] == "0x" + "0" * 63 + "1" if extra[i][0] == "ok" else None,
               "vault": "0x" + extra[n + i][1][-40:] if extra[n + i][0] == "ok" else None,
               "owner": "0x" + extra[2 * n + i][1][-40:] if extra[2 * n + i][0] == "ok" else None}
        vr, sw = trace_args(m)
        rec["vault_rebalance"] = vr
        rec["pool_swap"] = sw
        out["ready"].append(rec)
        print(json.dumps(rec))
    json.dump(out, open(OUT, "w"), indent=1)
    print("wrote", OUT)

if __name__ == "__main__":
    main()
