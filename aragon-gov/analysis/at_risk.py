#!/usr/bin/env python3
"""
At-risk set analysis for the Aragon-legacy governance class (ZH4-PASS7 P7-01).

Inputs (all in analysis/, no secrets):
  aragon_join.json          - 2,202 funded holding apps (dao, vault, eth, minAQ, sup, token)
  aragon_mgr_scan.json      - per-DAO: is Voting the TRANSFER_ROLE permission-manager?
  aragon_instant_params.json- per-DAO voting app + minAQ/sup/token
  aragon_apps.json          - per-DAO installed apps (appId hash -> proxy)
  aragon_liq_all.json       - per-token Uniswap V2/V3 + Sushi pair discovery (1,368 funded, minAQ<=20%)

Output: at_risk.json + printed tables.

Effective gate = "can an attacker acquire minAQ * totalSupply of the governance token?"
  - vote creation is possible if ANY-open newVote, OR a TokenManager exists (holder forward),
  - but passing always needs minAQ * totalSupply of voting power at the block-1 snapshot.
"""
import json, os
from Crypto.Hash import keccak

HERE = os.path.dirname(os.path.abspath(__file__))


def kh(b):
    h = keccak.new(digest_bits=256); h.update(b); return h.hexdigest()


def nh(name):
    node = b"\x00" * 32
    for label in reversed(name.split(".")):
        node = bytes.fromhex(kh(node + bytes.fromhex(kh(label.encode()))))
    return node.hex()


TM_ID = nh("token-manager.aragonpm.eth")
print("token-manager appId:", TM_ID)

join = json.load(open(os.path.join(HERE, "aragon_join.json")))
mgr = {x["dao"]: x for x in json.load(open(os.path.join(HERE, "aragon_mgr_scan.json")))}
liq = {x["dao"]: x for x in json.load(open(os.path.join(HERE, "aragon_liq_all.json")))}
apps = json.load(open(os.path.join(HERE, "aragon_apps.json")))
params = {p["dao"].lower(): p for p in json.load(open(os.path.join(HERE, "aragon_instant_params.json")))}

funded_mgr = [r for r in join if mgr.get(r["dao"], {}).get("isMgr")]
print("funded DAOs:", len(join), "| manager-funded:", len(funded_mgr),
      "| ETH:", round(sum(r["eth"] for r in funded_mgr) / 1e18, 3))

# ---- token-manager presence -------------------------------------------------
def has_tm(dao):
    return TM_ID in apps.get(dao, {})

n_tm = sum(1 for r in funded_mgr if has_tm(r["dao"]))
print("manager-funded DAOs with a TokenManager app:", n_tm)

# ---- liquidity intersection -------------------------------------------------
with_pool = [r for r in funded_mgr if liq.get(r["dao"], {}).get("liq")]
print("manager-funded DAOs whose token has ANY Uniswap V2/V3/Sushi pool:", len(with_pool))
print("  (note: liq was computed only for minAQ<=20% rows)")

# ---- the two acquisition channels ------------------------------------------
# ANY-open newVote is stored in aragon_cands_verified.json (anyCanCreate) only for a
# small verified subset; the full anyCanCreate set comes from the pass-7 join scan.
cands = {x["dao"]: x for x in json.load(open(os.path.join(HERE, "aragon_cands_verified.json")))}

rows = []
for r in funded_mgr:
    d = r["dao"]
    lq = liq.get(d, {}).get("liq", [])
    rows.append({
        "dao": d, "eth": r["eth"], "minAQ": r["minAQ"], "sup": r["sup"], "token": r["token"],
        "token_manager": has_tm(d),
        "any_open_verified": cands.get(d, {}).get("anyCanCreate"),
        "pools": lq,
        "pool_liquidity_usd": liq.get(d, {}).get("liq_usd"),
    })

# best candidates: manager + (ANY-open or TokenManager) + smallest minAQ + funded
best = sorted([x for x in rows if x["token_manager"] or x["any_open_verified"] == 1],
              key=lambda x: (x["minAQ"] is None, x["minAQ"] if x["minAQ"] is not None else 1, -x["eth"]))
print("\n-- manager + creatable (ANY-open or TokenManager), lowest minAQ first --")
for x in best[:25]:
    print(f"  {x['dao']} eth={x['eth']/1e18:.4f} minAQ={x['minAQ']} tm={x['token_manager']} "
          f"anyOpen={x['any_open_verified']} pools={x['pools']}")

# manager + liquidity (the "one AMM listing away" set)
print("\n-- manager + token already has a pool --")
for r in sorted(with_pool, key=lambda r: -r["eth"])[:25]:
    print(f"  {r['dao']} eth={r['eth']/1e18:.4f} minAQ={r['minAQ']} token={r['token']} "
          f"pools={liq.get(r['dao'], {}).get('liq')}")

json.dump({"funded": len(join), "manager_funded": len(funded_mgr),
           "manager_funded_eth": sum(r["eth"] for r in funded_mgr) / 1e18,
           "token_manager_present": n_tm,
           "with_pool": len(with_pool),
           "rows": rows, "best_creatable": best[:60], "with_pool_rows": with_pool},
          open(os.path.join(HERE, "at_risk.json"), "w"), indent=1)
print("\nwrote at_risk.json")
