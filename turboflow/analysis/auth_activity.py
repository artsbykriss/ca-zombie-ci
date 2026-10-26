#!/usr/bin/env python3
"""Check activity/roles of the upgrade authority and bridge PDA. Read-only."""
import json, base64
from rpc import call
from probe import on_curve

ADDRS = {
 "upgrade_authority": "HJbtKYPEum9bMVorEs8DEJUXLXv5XCi3mYuzJ45bYCxK",
 "bridge_pda": "8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4",
 "bridge_admin_candidate": "GZhzWVhJtsj7Xg9zUt3JiJXzfJZby8sdpGDfyqZ8GdSq",
}

def main():
    for name, a in ADDRS.items():
        print("###", name, a, "on_curve=", on_curve(a))
        try:
            sigs = call("getSignaturesForAddress", [a, {"limit": 10}])
            print("   sigs:", len(sigs))
            for s in sigs[:5]:
                print("    ", s["slot"], s["signature"], "err=", s.get("err"))
        except Exception as e:
            print("   ERR", e)
        try:
            r = call("getAccountInfo", [a, {"encoding": "base64"}])
            v = r["value"]
            if v:
                print("   acct owner=", v["owner"], "lamports=", v["lamports"],
                      "len=", len(v["data"][0]) if v.get("data") else 0)
            else:
                print("   acct NULL")
        except Exception as e:
            print("   ERR", e)

if __name__ == "__main__":
    main()
