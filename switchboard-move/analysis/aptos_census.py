#!/usr/bin/env python3
"""Read-only Aptos Switchboard queue/oracle census (public fullnode, no keys)."""
import json, sys, urllib.request, time

VIEW = "https://fullnode.mainnet.aptoslabs.com/v1/view"
PKG = "0xfea54925b5ac1912331e2e62049849b37842efaea298118b66f85a59057752b8"
MAIN_Q = "0x7fdf7235bf3bd872ad093927deb2ff5f1645d1b6dabbfd4a03c3e0442788ce12"
GUARD_Q = "0x3434a45114f5f8fc577557a9a3dda54c1799fee5271313f2599a1093c4a8ba01"

def view(function, args=None, type_args=None):
    body = {"function": function, "type_arguments": type_args or [], "arguments": args or []}
    req = urllib.request.Request(VIEW, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        res = json.load(r)
    return res[0] if isinstance(res, list) and len(res) == 1 else res

def v(fn, *args):
    return view(f"{PKG}::{fn}", list(args))

def census(queue_addr):
    out = {"queue": queue_addr}
    out["view_queue"] = v("queue::view_queue", queue_addr)
    oracle_addrs = v("oracle::view_queue_oracles", queue_addr)
    out["oracle_addresses"] = oracle_addrs
    out["oracles"] = []
    for o in oracle_addrs:
        try:
            out["oracles"].append(v("oracle::view_oracle", o))
        except Exception as e:
            out["oracles"].append({"oracle_address": o, "error": str(e)})
        time.sleep(0.05)
    try:
        out["aggregators"] = v("aggregator::view_queue_aggregators", queue_addr)
    except Exception as e:
        out["aggregators_error"] = str(e)
    return out

if __name__ == "__main__":
    res = {"main_queue": census(MAIN_Q), "guardian_queue": census(GUARD_Q)}
    with open(sys.argv[1] if len(sys.argv) > 1 else "aptos_queue_census.json", "w") as f:
        json.dump(res, f, indent=1)
    for name, q in res.items():
        vq = q["view_queue"]
        print(f"== {name}: {q['queue']}")
        print("   name:", vq.get("name"), "| authority:", vq.get("authority"), "| min_attestations:", vq.get("min_attestations"),
              "| validity_len:", vq.get("oracle_validity_length"), "| fee:", vq.get("fee"), "| guardian_queue:", vq.get("guardian_queue"),
              "| created_at:", vq.get("created_at"), "| last_queue_override:", vq.get("last_queue_override"))
        print("   queue_key:", vq.get("queue_key"))
        print("   oracles:", len(q["oracles"]), "| aggregators:", len(q.get("aggregators") or []))
