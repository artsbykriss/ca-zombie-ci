#!/usr/bin/env python3
"""Compute final summary numbers for the README (fresh reads + fleet totals)."""
import json, os, sys, base64, struct, datetime
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
rows = json.load(open(os.path.join(OUT, "pool-states-decoded.json")))
slot = rpc("getSlot", [{"commitment": "confirmed"}]).get("result")
print("slot:", slot)

# SOL price from the publisher oracle feed (dijkbk, 1e6 scale)
r = rpc("getAccountInfo", ["7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3", {"encoding": "base64", "commitment": "confirmed"}])
d = base64.b64decode(r["result"]["value"]["data"][0])
sol_px = struct.unpack_from("<Q", d, 0)[0] / 1e6
sol_slot = struct.unpack_from("<I", d, 16)[0]
print(f"oracle SOL/USD = {sol_px:.6f} (feed slot {sol_slot})")

# active pools (last_slot > 0 and recent)
now = slot
active = [r for r in rows if r["last_slot"] and (now - r["last_slot"]) < 5000]
inactive = [r for r in rows if r["last_slot"] and (now - r["last_slot"]) >= 5000]
de = [r for r in rows if r["last_slot"] == 0]

def usd(r, sol_px):
    # cached_wsol is base units (9dp), cached_usdc is base units of the quote token (assume 6dp stable ~$1)
    return r["cached_wsol"] / 1e9 * sol_px + r["cached_usdc"] / 1e6

tot_active = sum(usd(r, sol_px) for r in active)
tot_inactive = sum(usd(r, sol_px) for r in inactive)
tot_de = sum(usd(r, sol_px) for r in de)
print(f"\nactive pools ({len(active)}): {tot_active:,.2f} USD (cached)")
for r in sorted(active, key=lambda x: -usd(x, sol_px)):
    print(f"   {r['name']:22s} {r['cached_wsol']/1e9:14.4f} WSOL + {r['cached_usdc']/1e6:14.2f} quote = ${usd(r,sol_px):,.0f}  (last update {now-r['last_slot']} slots ago)")
print(f"inactive pools ({len(inactive)}): {tot_inactive:,.2f} USD (cached, stale)")
for r in sorted(inactive, key=lambda x: -usd(x, sol_px)):
    print(f"   {r['name']:22s} {r['cached_wsol']/1e9:14.4f} WSOL + {r['cached_usdc']/1e6:14.2f} quote = ${usd(r,sol_px):,.0f}")
print(f"equity pools (de*, {len(de)}): {tot_de:,.2f} USD (cached)")
print(f"\nTOTAL fleet (cached): ${tot_active+tot_inactive+tot_de:,.2f}")

# fresh vault reads for the main pool
def token_amount(addr):
    r = rpc("getAccountInfo", [addr, {"encoding": "base64", "commitment": "confirmed"}])
    v = r["result"]["value"]
    dd = base64.b64decode(v["data"][0])
    return struct.unpack_from("<Q", dd, 64)[0], v["lamports"]
for name, a in [("cur WSOL vault", "ATRsNGv2nDw7hSMfkUTBoVUDsFDwN7po7KbecyiGWNB4"),
                ("cur USDC vault", "2Y7HATmn9aJBcxCskE5V2U2epmjvkZmB51zTJBbhj4cU"),
                ("old WSOL vault", "FxGiN5NkigicwrnFshZEAUH9C13yrBALmgYxA9x8sfnQ"),
                ("old USDC vault", "6DMF4t6Ks8yXhG8K3rrTAeNYrqNrr1DwewHvBmH3a3FX")]:
    amt, lam = token_amount(a)
    print(f"{name}: {amt} (lamports {lam})")

# upgrade authority balance
r = rpc("getBalance", ["6dDjBZdpafRKe7WuVHYTF1HphW1BWiKqioMD5eBGYipS", {"commitment": "confirmed"}])
print("upgrade authority SOL:", r["result"]["value"] / 1e9)

# oracle updater key balance
r = rpc("getBalance", ["FTp1BybZ51NiZKbnZH6MsrV3tUZNauhpQMbBcqYUEr5f", {"commitment": "confirmed"}])
print("oracle updater SOL:", r["result"]["value"] / 1e9)
