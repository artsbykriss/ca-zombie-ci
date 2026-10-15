#!/usr/bin/env python3
"""Re-parse pools_raw.json with correct SPL Mint/Account layouts and analyze."""
import json, os, urllib.request, time, base64

HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, "pools_raw.json")))
pools, slot, accs = d["pools"], d["slot"], d["accounts"]

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58e(b):
    n = int.from_bytes(b, "big"); s = ""
    while n: n, r = divmod(n, 58); s = ALPH[r] + s
    for c in b:
        if c == 0: s = "1" + s
        else: break
    return s or "1"

def get_data(k):
    v = accs.get(k)
    if not v: return None, None
    return base64.b64decode(v["data_b64"]), v["owner"]

def token_account(k):
    raw, owner = get_data(k)
    if raw is None or len(raw) != 165: return None
    return {"prog": owner, "mint": b58e(raw[0:32]), "owner": b58e(raw[32:64]),
            "amount": int.from_bytes(raw[64:72], "little"),
            "delegate": b58e(raw[76:108]) if int.from_bytes(raw[72:76], "little") == 1 else None,
            "state": raw[108],
            "close_authority": b58e(raw[133:165]) if int.from_bytes(raw[129:133], "little") == 1 else None}

def mint_info(k):
    raw, owner = get_data(k)
    if raw is None or len(raw) != 82: return None
    return {"prog": owner,
            "mint_authority": b58e(raw[4:36]) if int.from_bytes(raw[0:4], "little") == 1 else None,
            "supply": int.from_bytes(raw[36:44], "little"), "decimals": raw[44],
            "initialized": raw[45],
            "freeze_authority": b58e(raw[50:82]) if int.from_bytes(raw[46:50], "little") == 1 else None}

# prices
mints = sorted({p["mint_a"] for p in pools} | {p["mint_b"] for p in pools})
prices = {}
for i in range(0, len(mints), 40):
    url = "https://coins.llama.fi/prices/current/" + ",".join(f"solana:{m}" for m in mints[i:i+40])
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as r:
            for k, v in json.loads(r.read()).get("coins", {}).items():
                prices[k.split(":", 1)[1]] = v["price"]
    except Exception as e:
        print("price err", e)
    time.sleep(0.4)
print(f"mints={len(mints)} priced={len(prices)}")

rows = []
for p in pools:
    va, vb = token_account(p["reserves_a"]), token_account(p["reserves_b"])
    lm = mint_info(p["pool_mint"])
    ma, mb = mint_info(p["mint_a"]), mint_info(p["mint_b"])
    dec_a = ma["decimals"] if ma else None
    dec_b = mb["decimals"] if mb else None
    amt_a = va["amount"] if va else 0
    amt_b = vb["amount"] if vb else 0
    pa, pb = prices.get(p["mint_a"]), prices.get(p["mint_b"])
    ua = amt_a / 10**dec_a * pa if (pa and dec_a is not None) else 0.0
    ub = amt_b / 10**dec_b * pb if (pb and dec_b is not None) else 0.0
    exp = p["expected_authority"]
    rows.append({
        "swap": p["swap"], "paused": p["is_paused"], "admin_key": p["admin_key"],
        "mint_a": p["mint_a"], "mint_b": p["mint_b"], "amt_a": amt_a, "amt_b": amt_b,
        "dec_a": dec_a, "dec_b": dec_b, "price_a": pa, "price_b": pb,
        "usd_a": round(ua, 2), "usd_b": round(ub, 2), "usd": round(ua + ub, 2),
        "vault_a_ok": bool(va and va["owner"] == exp), "vault_b_ok": bool(vb and vb["owner"] == exp),
        "lp_auth_ok": bool(lm and lm["mint_authority"] == exp),
        "lp_freeze": lm["freeze_authority"] if lm else None,
        "lp_supply": lm["supply"] if lm else None, "lp_dec": lm["decimals"] if lm else None,
        "vault_a_owner": va["owner"] if va else None, "vault_b_owner": vb["owner"] if vb else None,
        "lp_mint_authority": lm["mint_authority"] if lm else None, "expected_authority": exp,
        "vault_a_prog": va["prog"] if va else None, "vault_b_prog": vb["prog"] if vb else None,
        "fees": p["fees"],
    })
rows.sort(key=lambda r: -r["usd"])
total = sum(r["usd"] for r in rows)
funded = [r for r in rows if r["amt_a"] or r["amt_b"]]
print(f"pools={len(rows)} funded={len(funded)} total_usd={total:,.2f}")
print("top 25:")
for r in rows[:25]:
    print(f"  {r['swap'][:44]:44s} ${r['usd']:>12,.2f} A={r['amt_a']:>18} B={r['amt_b']:>18} paused={r['paused']} lp_ok={r['lp_auth_ok']} v={r['vault_a_ok']}/{r['vault_b_ok']} lp_supply={r['lp_supply']}")
bad = [r for r in rows if not (r["vault_a_ok"] and r["vault_b_ok"] and r["lp_auth_ok"])]
print(f"\nANOMALIES: {len(bad)}")
for r in bad[:20]:
    print(f"  {r['swap']} usd={r['usd']} vault_a_ok={r['vault_a_ok']} vault_b_ok={r['vault_b_ok']} lp_ok={r['lp_auth_ok']} lp_auth={r['lp_mint_authority']} exp={r['expected_authority']}")
unpriced = [r for r in rows if (r["amt_a"] and not r["price_a"]) or (r["amt_b"] and not r["price_b"])]
print(f"\nunpriced-with-balance: {len(unpriced)}; sum of priced portion: {sum(r['usd'] for r in unpriced):,.2f}")
for r in unpriced[:25]:
    print(f"  {r['swap'][:44]} A={r['amt_a']} ({r['mint_a'][:8]}) B={r['amt_b']} ({r['mint_b'][:8]}) usd_priced={r['usd']}")
paused = [r for r in rows if r["paused"]]
print(f"\npaused pools: {len(paused)} usd={sum(r['usd'] for r in paused):,.2f}")
print(f"zero-fee pools: {sum(1 for r in rows if r['fees']['trade_fee_num']==0 and r['fees']['withdraw_fee_num']==0)}")
print(f"lp freeze auth set: {sum(1 for r in rows if r['lp_freeze'])}")
json.dump({"slot": slot, "rows": rows, "total_usd": total, "prices": prices}, open(os.path.join(HERE, "pools_analysis.json"), "w"), indent=1)
print("wrote pools_analysis.json")
