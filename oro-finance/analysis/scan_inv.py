"""Scan transactions for invocations of the Oro core program and decode instruction
discriminators + account lists. Read-only.
Usage: python3 scan_inv.py <address> <limit> [start_index]
Writes analysis/inv_<address>.json
"""
import sys, json, hashlib, time
sys.path.insert(0, '.')
import rpc2
from b58 import b58dec

PID = "iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
NAMES = ["autorize", "add_to_whitelist_by_auth", "whitelist", "update_price", "sell", "withdraw",
         "deposit", "mint_gold", "burn_gold", "init_integrator", "update_integrator_fees",
         "close_integrator", "withdraw_from_integrator", "update_integrator_market_override",
         "init_integrator_v2", "update_integrator_v2_fees", "close_integrator_v2",
         "withdraw_from_integrator_v2", "update_integrator_v2_market_overrides", "buy"]
D = {hashlib.sha256(("global:" + n).encode()).digest()[:8]: n for n in NAMES}


def fullkeys(tx):
    m = tx["transaction"]["message"]
    k = [x["pubkey"] for x in m["accountKeys"]]
    la = tx["meta"].get("loadedAddresses") or {}
    k += list(la.get("writable") or [])
    k += list(la.get("readonly") or [])
    return k


def scan(addr, limit=300, skip=0):
    sigs = rpc2.call("getSignaturesForAddress", [addr, {"limit": min(limit + skip, 1000)}])
    sigs = sigs[skip:skip + limit]
    out = []
    for k, s in enumerate(sigs):
        try:
            tx = rpc2.call("getTransaction", [s["signature"],
                           {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        except Exception:
            time.sleep(1)
            continue
        if not tx:
            continue
        keys = fullkeys(tx)
        ixs = []
        for ix in tx["transaction"]["message"]["instructions"]:
            if ix.get("programId") == PID:
                ixs.append(("top", ix))
        for g in tx["meta"].get("innerInstructions") or []:
            for ix in g["instructions"]:
                if ix.get("programId") == PID:
                    ixs.append(("inner", ix))
        if not ixs:
            continue
        for kind, ix in ixs:
            d = ix.get("data")
            raw = b58dec(d) if d else b""
            out.append({"sig": s["signature"], "slot": s["slot"], "kind": kind,
                        "name": D.get(raw[:8], raw[:8].hex()),
                        "args": raw[8:].hex(),
                        "accts": ix.get("accounts") or ix.get("accountKeyIndexes"),
                        "keys": keys})
        json.dump(out, open("inv_%s.json" % addr, "w"), indent=1)
        if k % 25 == 0:
            sys.stderr.write("%d/%d hits=%d\n" % (k, len(sigs), len(out)))
            sys.stderr.flush()
        time.sleep(0.1)
    return out


if __name__ == "__main__":
    addr = sys.argv[1]
    lim = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    sk = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    o = scan(addr, lim, sk)
    from collections import Counter
    print("HITS", len(o), Counter(x["name"] for x in o))
