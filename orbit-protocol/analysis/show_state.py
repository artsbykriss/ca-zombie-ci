"""Pretty-print live_state.json + join with DefiLlama prices. Read-only."""
import json
import os
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, "live_state.json")))
blk = d["block"]
print("block", blk)

# DefiLlama prices for all underlyings + ETH
tokens = list(d["underlyings"].keys()) + ["0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"]
prices = {}
try:
    url = "https://coins.llama.fi/prices/current/" + ",".join(
        f"blast:{t.lower()}" for t in tokens)
    with urllib.request.urlopen(url, timeout=30) as r:
        pj = json.loads(r.read())
    for k, v in pj.get("coins", {}).items():
        prices[k.split(":")[1]] = v["price"]
except Exception as e:  # noqa: BLE001
    print("price fetch failed:", e)

def usd(tok, amt):
    p = prices.get(tok.lower() if tok else None)
    return None if p is None else amt * p

total_cash = 0.0
for lab, c in d["comptrollers"].items():
    print(f"\n== {lab} {c['address']} code={c.get('code_size')} impl={c['comptrollerImplementation']}")
    print(f"   admin={c['admin']} pendingAdmin={c['pendingAdmin']} pauseGuardian={c['pauseGuardian']}")
    print(f"   oracle={c['oracle']} closeFactor={c['closeFactorMantissa']} liqInc={c['liquidationIncentiveMantissa']} compRate={c.get('compRate')}")
    for m in c["markets_detail"]:
        dec = m["decimals"] or 18
        f = lambda x: (x or 0) / 10 ** dec  # noqa: E731
        und = m["underlying"] or "NATIVE-ETH"
        cash = f(m["getCash"]); borr = f(m["totalBorrows"]); sup = f(m["totalSupply"]); res = f(m["totalReserves"])
        ucash = usd(None if und == "NATIVE-ETH" else und, cash)
        if ucash:
            total_cash += ucash
        cf = (m["collateralFactorMantissa"] or 0) / 1e18
        print(f"   {m['market']} {str(m['symbol'])[:9]:9} und={und[:16]:16} dec={dec} cash={cash:,.8g} borr={borr:,.8g} sup={sup:,.8g} res={res:,.8g} "
              f"cf={cf:.2f} bP={m['borrowGuardianPaused']} mP={m['mintGuardianPaused']} cap_b={m['borrowCap']} "
              f"USDcash={ucash if ucash is None else round(ucash, 2)}")
print(f"\nTOTAL cash USD (priced): {total_cash:,.2f}")

print("\n== oracles")
for o, od in d["oracles"].items():
    print(f"  {o} code={od.get('code_size')} owner={od.get('owner')} admin={od.get('admin')} pendingAdmin={od.get('pendingAdmin')}")
    for m, p in od["prices"].items():
        print(f"     {m} -> {p}")

print("\n== underlyings")
for t, td in d["underlyings"].items():
    print(f"  {t} {td.get('symbol')} dec={td.get('decimals')} totalSupply={td.get('totalSupply')} price={prices.get(t.lower())}")

print("\n== prices used")
for k, v in prices.items():
    print(f"  {k}: {v}")
