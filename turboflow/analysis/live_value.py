#!/usr/bin/env python3
"""Read live value: bridge PDA balance, bridge token accounts, recent program txs. Read-only."""
import sys, json, time
from rpc import call

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"
PDA = "8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4"
USDC = "9ayXbTyhkJ49WtG6DA2PCN6EAKtM8DCneMzhJPTMRWcj"
USDT = "6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2"
EXTRA = ["6FaXzEC4CNAh1ECxc8FUnjpcnMYYG4M7DVJ5ZMbTmcWH",
         "4wHLLe6ovPqmGoBjvk6ogxgFbiGMCUUPvnMqmxyprX5C"]

def main():
    slot = call("getSlot", [{"commitment": "finalized"}])
    print("slot(finalized)=", slot)
    out = {"slot": slot}
    # PDA lamports + account info
    r = call("getAccountInfo", [PDA, {"encoding": "base64"}])
    out["pda"] = r["value"]
    print("PDA", PDA, "lamports=", r["value"]["lamports"] if r["value"] else None,
          "owner=", r["value"]["owner"] if r["value"] else None,
          "len=", len(r["value"]["data"][0]) if r["value"] and r["value"].get("data") else 0)
    for name, addr in [("USDC", USDC), ("USDT", USDT)]:
        try:
            b = call("getTokenAccountBalance", [addr])
            print(name, addr, "->", b["value"])
            out[name] = b["value"]
        except Exception as e:
            print(name, "ERR", e); out[name] = {"error": str(e)}
        time.sleep(0.3)
    for a in EXTRA:
        try:
            r = call("getAccountInfo", [a, {"encoding": "base64"}])
            v = r["value"]
            print("EXTRA", a, "lamports=", v["lamports"] if v else None, "owner=", v["owner"] if v else None,
                  "len=", len(v["data"][0]) if v and v.get("data") else 0)
            out[a] = {"lamports": v["lamports"], "owner": v["owner"]} if v else None
        except Exception as e:
            print("EXTRA ERR", a, e)
        time.sleep(0.3)
    json.dump(out, open("live_value.json", "w"), indent=1)

if __name__ == "__main__":
    main()
