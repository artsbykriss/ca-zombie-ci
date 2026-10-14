#!/usr/bin/env python3
"""Enumerate Bril Finance live state on BSC via public RPC (read-only).
Writes analysis/live_state.json
No secrets: uses keyless public RPC by default; override with BRIL_RPC env var.
"""
import json, os, sys, urllib.request, time

RPC = os.environ.get("BRIL_RPC", "https://bsc-rpc.publicnode.com")
FACTORY = "0xfaa2e7c69F7F34195D3Ef6CF98B6B009A6A07F30"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json")

_id = 0
def rpc_batch(calls):
    """calls: list of (to, data) -> list of hex results"""
    global _id
    payload = []
    for (to, data) in calls:
        _id += 1
        payload.append({"jsonrpc": "2.0", "id": _id, "method": "eth_call",
                        "params": [{"to": to, "data": data}, "latest"]})
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    d = json.load(urllib.request.urlopen(req, timeout=90))
    m = {x["id"]: x for x in d}
    out = []
    for p in payload:
        x = m[p["id"]]
        out.append(x.get("result") if "error" not in x else ("0xerr:" + str(x["error"])))
    return out

def sel(sig):
    # tiny keccak-free approach: use known selectors via cast-generated map (fallback: subprocess cast)
    import subprocess
    return subprocess.check_output(["cast", "sig", sig], text=True).strip()

def enc_u256(v):
    return hex(v)[2:].rjust(64, "0")

def dec_words(hexstr):
    if not hexstr or not hexstr.startswith("0x") or hexstr.startswith("0xerr"):
        return None
    h = hexstr[2:]
    return [h[i:i+64] for i in range(0, len(h), 64)]

def dec_addr(w):
    return "0x" + w[-40:]

def dec_u(w):
    return int(w, 16)

def main():
    latest = None
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    latest = int(json.load(urllib.request.urlopen(req, timeout=30))["result"], 16)
    print("latest block:", latest)

    s_count = sel("getStrategyInstanceCount()")
    s_vcount = sel("getVaultCount()")
    s_vidx = sel("getVaultByIndex(uint256)")
    s_tcount = sel("getStrategyTypeCount()")
    s_tbyid = sel("getStrategyTypeById(uint256)")
    s_tstrategies = sel("getTypeStrategies(uint256)")
    s_instance = sel("getStrategyInstance(address)")
    s_amt = sel("vaultAmounts()")
    s_sum = sel("vaultSummary()")
    s_owner = sel("owner()")
    s_enabled = sel("isStrategyEnabled(address)")
    s_bal = sel("balanceOf(address)")
    s_dec = sel("decimals()")
    s_sym = sel("symbol()")

    n_types = dec_u(dec_words(rpc_batch([(FACTORY, s_tcount)])[0])[0])
    n_inst = dec_u(dec_words(rpc_batch([(FACTORY, s_count)])[0])[0])
    n_vaults = dec_u(dec_words(rpc_batch([(FACTORY, s_vcount)])[0])[0])
    print("types", n_types, "instances", n_inst, "vaults", n_vaults)

    types = []
    for i in range(n_types):
        r = rpc_batch([(FACTORY, s_tbyid + enc_u256(i))])[0]
        w = dec_words(r)
        # string dynamic: w0=offset, w1=active, w2=impl, w3=count
        off = dec_u(w[0])
        strlen = dec_u(w[off // 32]) if off else 0
        desc = bytes.fromhex(w[off // 32 + 1])[:strlen].decode("utf-8", "replace") if strlen else ""
        types.append({"typeId": i, "desc": desc, "active": dec_u(w[1]) == 1, "impl": dec_addr(w[2]), "count": dec_u(w[3])})
        print(i, types[-1])

    strategies = []
    for t in types:
        r = rpc_batch([(FACTORY, s_tstrategies + enc_u256(t["typeId"]))])[0]
        w = dec_words(r)
        if w is None:
            print("type", t["typeId"], "err", r); continue
        # dynamic array of structs (uint256,address,address,bool): offset word then len then tuples (4 words each)
        off = dec_u(w[0]) // 32
        ln = dec_u(w[off])
        for k in range(ln):
            base = off + 1 + k * 4
            st = {"typeId": dec_u(w[base]), "strategy": dec_addr(w[base + 1]), "vault": dec_addr(w[base + 2]), "enabled": dec_u(w[base + 3]) == 1}
            st["impl"] = t["impl"]; st["desc"] = t["desc"]
            strategies.append(st)
    print("strategies enumerated:", len(strategies))

    # read per-strategy: vaultAmounts, vaultSummary, owner
    calls = []
    for st in strategies:
        calls.append((st["strategy"], s_amt))
        calls.append((st["strategy"], s_sum))
        calls.append((st["strategy"], s_owner))
    res = rpc_batch(calls)
    for i, st in enumerate(strategies):
        a, s, o = res[3*i], res[3*i+1], res[3*i+2]
        wa = dec_words(a)
        ws = dec_words(s)
        wo = dec_words(o)
        if wa and len(wa) >= 2:
            st["baseTotal"] = dec_u(wa[0]); st["scarceTotal"] = dec_u(wa[1])
        else:
            st["amounts_err"] = a
        if ws and len(ws) >= 5:
            st["vault"] = dec_addr(ws[0]); st["baseToken"] = dec_addr(ws[1]); st["scarceToken"] = dec_addr(ws[2])
            st["inverted"] = dec_u(ws[3]) == 1; st["tickSpacing"] = int(ws[4], 16)
        else:
            st["summary_err"] = s
        if wo and len(wo) >= 1:
            st["owner"] = dec_addr(wo[0])
        else:
            st["owner_err"] = o

    # token metadata for all tokens
    tokens = set()
    for st in strategies:
        for k in ("baseToken", "scarceToken"):
            if st.get(k): tokens.add(st[k].lower())
    token_calls = []
    tlist = sorted(tokens)
    for t in tlist:
        token_calls.append((t, s_dec))
        token_calls.append((t, s_sym))
    tres = rpc_batch(token_calls)
    tmeta = {}
    for i, t in enumerate(tlist):
        d = dec_words(tres[2*i]); s = tres[2*i+1]
        dec = dec_u(d[0]) if d else None
        sym = None
        if s and s.startswith("0x") and len(s) > 2:
            try:
                h = s[2:]
                if len(h) >= 128:  # dynamic string
                    off = int(h[0:64], 16) // 32
                    ln = int(h[off*64:(off+1)*64], 16)
                    sym = bytes.fromhex(h[(off+1)*64:(off+1)*64+ln*2]).decode("utf-8", "replace")
                else:
                    sym = bytes.fromhex(h[:64]).decode("utf-8", "replace").strip("\x00")
            except Exception:
                sym = None
        tmeta[t] = {"decimals": dec, "symbol": sym}
    for st in strategies:
        st["baseTokenMeta"] = tmeta.get((st.get("baseToken") or "").lower())
        st["scarceTokenMeta"] = tmeta.get((st.get("scarceToken") or "").lower())

    out = {"block": latest, "rpc": "public", "factory": FACTORY, "types": types,
           "n_instances": len(strategies), "strategies": strategies, "tokens": tmeta}
    json.dump(out, open(OUT, "w"), indent=1)
    print("wrote", OUT)

if __name__ == "__main__":
    main()
