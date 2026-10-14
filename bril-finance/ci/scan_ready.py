#!/usr/bin/env python3
"""Re-scan Bril Finance live state at the CI fork block: enumerate all strategy instances and
probe rebalance()/performUpkeep() from a fresh unprivileged address (eth_call, read-only).
Uses BSC_RPC_URL from env (never printed). Writes JSON to ci-out/ready-scan.json.
"""
import json, os, subprocess, urllib.request

RPC = os.environ.get("BRIL_RPC") or os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
FACTORY = "0xfaa2e7c69F7F34195D3Ef6CF98B6B009A6A07F30"
ATTACKER = "0x000000000000000000000000000000000000dEaD"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out", "ready-scan.json")

def sel(sig):
    return subprocess.check_output(["cast", "sig", sig], text=True).strip()

def batch(calls, frm=None):
    payload = []
    for i, (to, data) in enumerate(calls):
        p = {"to": to, "data": data}
        if frm: p["from"] = frm
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call", "params": [p, "latest"]})
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    d = json.load(urllib.request.urlopen(req, timeout=120))
    m = {x["id"]: x for x in d}
    return [("ok", m[i].get("result")) if "error" not in m[i] else ("err", str(m[i]["error"])[:160]) for i in range(len(payload))]

def main():
    bn = json.load(urllib.request.urlopen(urllib.request.Request(
        RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"}), timeout=60))["result"]
    block = int(bn, 16)
    s_tcount = sel("getStrategyTypeCount()")
    s_tstrategies = sel("getTypeStrategies(uint256)")
    s_paused = sel("paused()")
    s_reb = sel("rebalance()")
    s_pu = sel("performUpkeep(bytes)")
    s_vault = sel("vault()")

    n_types = int(batch([(FACTORY, s_tcount)])[0][1], 16)
    strategies = []
    for t in range(n_types):
        r = batch([(FACTORY, s_tstrategies + hex(t)[2:].rjust(64, "0"))])[0]
        if r[0] != "ok": continue
        h = r[1][2:]
        off = int(h[0:64], 16) // 32
        ln = int(h[off*64:(off+1)*64], 16)
        for k in range(ln):
            base = (off + 1 + k * 4) * 64
            st = {"typeId": t, "strategy": "0x" + h[base+64:base+128][-40:], "vault": "0x" + h[base+128:base+192][-40:],
                  "enabled": int(h[base+192:base+256], 16) == 1}
            strategies.append(st)

    calls = []
    for st in strategies:
        calls.append((st["strategy"], s_paused))
        calls.append((st["strategy"], s_reb))
        calls.append((st["strategy"], s_vault))
    res = batch(calls, frm=ATTACKER)
    ready = []
    for i, st in enumerate(strategies):
        pa, rb, va = res[3*i], res[3*i+1], res[3*i+2]
        st["paused"] = (pa[1] == "0x" + "0"*63 + "1") if pa[0] == "ok" else None
        st["vault"] = "0x" + va[1][-40:] if va[0] == "ok" else st["vault"]
        if rb[0] == "ok":
            st["rebalance_from_attacker"] = "SUCCESS"
            ready.append(st)
        else:
            m = rb[1]
            st["rebalance_from_attacker"] = m
    out = {"block": block, "n_strategies": len(strategies), "n_ready": len(ready),
           "ready": ready, "all": strategies}
    json.dump(out, open(OUT, "w"), indent=1)
    print(f"block={block} strategies={len(strategies)} ready(rebalance succeeds from attacker)={len(ready)}")
    for st in ready:
        print(f"  READY t{st['typeId']} {st['strategy']} vault={st['vault']} paused={st.get('paused')}")

if __name__ == "__main__":
    main()
