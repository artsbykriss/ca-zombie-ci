#!/usr/bin/env python3
"""Compute the live Reflect Tranches value: senior (proxy vaults), junior (pool vaults),
and the value sitting in *matured, unclaimed* RLP Cooldowns (the cooldown-ownership surface)."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

st = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json")))
pr = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "prices.json")))["llama"]
cools = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cooldowns.json")))

def price(mint):
    c = pr.get("solana:" + mint)
    return c["price"] if c else None

TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
NOW = 1792741085

# per-pool LP supply + pool NAV
pool_nav = {}
senior_total = junior_total = 0.0
print(f"{'pool':46} {'asset':14} {'junior_tok':>16} {'senior_tok':>16} {'USD_junior':>12} {'USD_senior':>12}")
for r in st["rows"]:
    p = r["pool"]; pv = r["proxy"]
    mint = pv["stablecoin_mint"]
    px = price(mint) or 0.0
    j = sum(float(t["ui"]) for t in r["pool_token_accounts"] if t["mint"] == mint)
    s = sum(float(t["ui"]) for t in r["proxy_token_accounts"] if t["mint"] == mint)
    ju = j * px; su = s * px
    junior_total += ju; senior_total += su
    pool_nav[p["pubkey"]] = {"mint": mint, "px": px, "junior_tok": j, "senior_tok": s,
                             "usd_junior": ju, "usd_senior": su, "lp_mint": p["lp_mint"]}
    print(f"{p['pubkey']:46} {mint[:12]:14} {j:16.6f} {s:16.6f} {ju:12.2f} {su:12.2f}")

print(f"\nSENIOR total (proxy vaults): ${senior_total:,.2f}")
print(f"JUNIOR total (pool vaults):  ${junior_total:,.2f}")
print(f"TOTAL:                       ${senior_total + junior_total:,.2f}")

# LP supplies
print("\nLP supplies:")
for pk, v in pool_nav.items():
    r = rpc("getTokenSupply", [v["lp_mint"]])
    val = r.get("result", {}).get("value") or {}
    v["lp_supply"] = float(val.get("uiAmountString") or 0)
    print(f"  {pk} lp={v['lp_mint']} supply={v['lp_supply']}")

# matured cooldowns
print("\nmatured unclaimed Cooldowns:")
tot = 0.0
rows = []
for c in cools:
    d = bytes.fromhex(c["hex"])
    auth = str(__import__("solders.pubkey", fromlist=["Pubkey"]).Pubkey.from_bytes(d[17:49]))
    pool = d[49]; idx = int.from_bytes(d[9:17], "little")
    unlock = int.from_bytes(d[50:58], "little"); locked = int.from_bytes(d[58:66], "little")
    # find the pool account for this pool id
    pool_pk = None
    for r in st["rows"]:
        if r["pool"]["assetIdxs"][0] == d[58+8+1] if False else False:
            pass
    matured = unlock < NOW
    # value: locked LP / lp_supply * pool NAV (junior+senior? cooldown redeems pro-rata pool assets)
    nav = None; supply = None
    for pk, v in pool_nav.items():
        pass
    rows.append({"cooldown": c["pubkey"], "authority": auth, "pool_id": pool, "index": idx,
                 "unlock_ts": unlock, "locked_lp": locked, "matured": matured})
    print(f"  {c['pubkey']} auth={auth[:8]} pool={pool} idx={idx} unlock={unlock} matured={matured} locked_lp={locked}")

# map pool_id -> pool pubkey using seeds
from solders.pubkey import Pubkey
RLP = Pubkey.from_string("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
def pool_pda(i): return str(Pubkey.find_program_address([b"liquidity_pool", bytes([i])], RLP)[0])
matured_val = 0.0
for r in rows:
    if not r["matured"]:
        continue
    pk = pool_pda(r["pool_id"])
    v = pool_nav.get(pk)
    if not v or not v["lp_supply"]:
        continue
    # LP holder share of the pool's *own* (junior) assets + its claim on senior? A cooldown
    # redeems a pro-rata share of the pool reserves (junior side) only.
    share = r["locked_lp"] / v["lp_supply"]
    usd = share * v["usd_junior"]
    r["usd"] = usd
    matured_val += usd
    print(f"  -> {r['cooldown']} pool={r['pool_id']} share={share:.6f} USD≈${usd:,.2f}")
print(f"\nTOTAL matured unclaimed cooldown value ≈ ${matured_val:,.2f}")
json.dump({"senior_total": senior_total, "junior_total": junior_total, "pool_nav": pool_nav,
           "cooldowns": rows, "matured_cooldown_usd": matured_val, "now": NOW},
          open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "value_summary.json"), "w"), indent=2)
