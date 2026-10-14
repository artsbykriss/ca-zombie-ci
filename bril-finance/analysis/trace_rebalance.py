#!/usr/bin/env python3
"""Trace strategy.rebalance() with callTracer and decode the inner vault.rebalance call.
RPC comes from env TRACE_RPC (never written to disk). Saves only decoded results (no URLs).
"""
import json, os, sys, urllib.request

RPC = os.environ["TRACE_RPC"]
ATTACKER = "0x000000000000000000000000000000000000dEaD"

def trace(to, data, frm=ATTACKER):
    payload = {"jsonrpc": "2.0", "id": 1, "method": "debug_traceCall",
               "params": [{"from": frm, "to": to, "data": data}, "latest", {"tracer": "callTracer", "tracerConfig": {"withLog": False}}]}
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    d = json.load(urllib.request.urlopen(req, timeout=180))
    if "error" in d: return {"error": d["error"]}
    return d["result"]

def walk(node, out, depth=0):
    out.append((depth, node))
    for c in node.get("calls", []) or []:
        walk(c, out, depth + 1)

def dec_int24(w):
    v = int(w, 16)
    return v - (1 << 256) if v >= (1 << 255) else v

def main():
    strategies = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ready_strategies.json")))
    results = {}
    for s in strategies:
        t = trace(s["strategy"], "0x7d7c2a1c")  # rebalance()
        if "error" in t:
            results[s["strategy"]] = {"error": t["error"]}
            print(s["strategy"], "TRACE ERROR", t["error"])
            continue
        flat = []
        walk(t, flat)
        entry = {"top": {"to": t.get("to"), "gasUsed": t.get("gasUsed"), "error": t.get("error")}}
        calls = []
        for depth, n in flat[1:]:
            inp = n.get("input", "") or ""
            rec = {"depth": depth, "to": n.get("to"), "type": n.get("type"), "sel": inp[:10], "gasUsed": n.get("gasUsed"), "err": n.get("error")}
            if inp.startswith("0xd87346aa"):
                w = [inp[10:][i:i+64] for i in range(0, 320, 64)]
                rec["vault_rebalance"] = {"baseLo": dec_int24(w[0]), "baseUp": dec_int24(w[1]), "limitLo": dec_int24(w[2]), "limitUp": dec_int24(w[3]),
                                          "swapQuantity": dec_int24(w[4]), "vault": n.get("to")}
            if inp.startswith("0x468721a7"):
                w = [inp[10:][i:i+64] for i in range(0, 320, 64)]
                rec["safe_module_call"] = {"to": "0x" + w[0][-40:], "value": int(w[1], 16), "operation": int(w[3], 16) if len(w) > 3 else None}
            if inp.startswith("0x128acb08"):
                rec["pool_swap"] = {"pool": n.get("to"), "zeroForOne": int(inp[10:][:64], 16) == 1,
                                    "amountSpecified": dec_int24(inp[10:][64:128])}
            if inp.startswith("0xa9059cbb") or inp.startswith("0x095ea7b3") or inp.startswith("0x8dbdbe6d") or inp.startswith("0x00f714ce"):
                rec["token_move"] = True
            calls.append(rec)
        entry["calls"] = calls
        results[s["strategy"]] = entry
        vr = [c for c in calls if "vault_rebalance" in c]
        sw = [c for c in calls if "pool_swap" in c]
        print(f"{s['strategy']} t{s['typeId']} gas={t.get('gasUsed')} err={t.get('error')}")
        for c in vr:
            print("    vault.rebalance:", json.dumps(c["vault_rebalance"]))
        for c in sw:
            print("    pool.swap:", json.dumps(c["pool_swap"]))
        if not vr:
            print("    (no vault.rebalance call in trace)")
    json.dump(results, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "traces_rebalance.json"), "w"), indent=1)
    print("saved traces_rebalance.json")

if __name__ == "__main__":
    main()
