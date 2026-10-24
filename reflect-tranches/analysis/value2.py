#!/usr/bin/env python3
"""Final value summary: senior/junior TVL and the value locked in matured unclaimed Cooldowns."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solders.pubkey import Pubkey

BASE = os.path.dirname(os.path.abspath(__file__))
st = json.load(open(os.path.join(BASE, "live_state.json")))
pr = json.load(open(os.path.join(BASE, "prices.json")))["llama"]
cools = json.load(open(os.path.join(BASE, "cooldowns.json")))
lps = json.load(open(os.path.join(BASE, "lp_supply.json")))

RLP = Pubkey.from_string("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
def pool_pda(i):
    return str(Pubkey.find_program_address([b"liquidity_pool", bytes([i])], RLP)[0])

def price(mint):
    c = pr.get("solana:" + mint)
    return c["price"] if c else 0.0

pool_of = {}   # pool pubkey -> value info
senior = junior = 0.0
for r in st["rows"]:
    p, pv = r["pool"], r["proxy"]
    mint = pv["stablecoin_mint"]
    px = price(mint)
    j = sum(float(t["ui"]) for t in r["pool_token_accounts"] if t["mint"] == mint)
    s = sum(float(t["ui"]) for t in r["proxy_token_accounts"] if t["mint"] == mint)
    senior += s * px
    junior += j * px
    pool_of[p["pubkey"]] = {"mint": mint, "px": px, "junior_tok": j, "senior_tok": s,
                            "usd_junior": j * px, "usd_senior": s * px,
                            "lp_mint": p["lp_mint"], "usd_total": (j + s) * px}

# LP supply from the mint account itself
for pk, v in pool_of.items():
    for k, m in lps.items():
        if m["mint"] == v["lp_mint"]:
            v["lp_supply"] = m["supply"]
NOW = 1792741085
matured = 0.0
rows = []
for c in cools:
    d = bytes.fromhex(c["hex"])
    auth = str(Pubkey.from_bytes(d[17:49]))
    pool_id = d[49]
    unlock = int.from_bytes(d[50:58], "little")
    locked = int.from_bytes(d[58:66], "little")
    pk = pool_pda(pool_id)
    v = pool_of.get(pk)
    usd = 0.0
    if unlock < NOW and v and v.get("lp_supply"):
        usd = (locked / 1e6) / v["lp_supply"] * v["usd_junior"]
        matured += usd
    rows.append({"cooldown": c["pubkey"], "authority": auth, "pool_id": pool_id,
                 "unlock_ts": unlock, "matured": unlock < NOW, "locked_lp": locked,
                 "usd_if_extractable": usd})
out = {"slot": st["slot"], "now": NOW, "senior_usd": senior, "junior_usd": junior,
       "total_usd": senior + junior, "matured_cooldown_usd": matured,
       "pools": pool_of, "cooldowns": rows}
json.dump(out, open(os.path.join(BASE, "value_summary.json"), "w"), indent=2)
print(f"senior ${senior:,.2f}  junior ${junior:,.2f}  total ${senior+junior:,.2f}")
print(f"matured unclaimed cooldowns ${matured:,.2f}")
for r in rows:
    if r["matured"]:
        print("  ", r["cooldown"], f"pool{r['pool_id']}", f"${r['usd_if_extractable']:,.2f}")
