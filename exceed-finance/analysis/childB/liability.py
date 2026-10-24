#!/usr/bin/env python3
import json, sys, struct, base64, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call, get_account
from solders.pubkey import Pubkey as P

PRECISION = 10**12
def pk(b): return str(P.from_bytes(b))
MINT = {
 "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":"USDC",
 "So11111111111111111111111111111111111111112":"SOL",
 "cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij":"cbBTC",
 "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs":"jupSOL?",
 "9ir8o6rj7dJsXXFQPbDZcWCiPx4UDcdTKrYZfnct6GDm":"pUSD",
}
pairs = json.load(open("all-pairs.json"))
now = call("getBlockTime", [call("getSlot", [{"commitment":"confirmed"}])["result"]])["result"]
print("chain time now:", now)

def calc_rate(p, now):
    last_rate = p["last_rate"]; last_ts = p["last_timestamp"]
    if now <= last_ts: return last_rate
    elapsed = now - last_ts; spi = p["seconds_per_interval"]
    intervals = elapsed // spi; rem = elapsed % spi; ir = p["interval_rate"]
    compounded = (ir ** intervals) // (PRECISION ** (intervals - 1)) if intervals > 0 else PRECISION
    linear = (ir - PRECISION) * rem // spi
    return last_rate * (compounded + linear) // PRECISION

url = "https://coins.llama.fi/prices/current/solana:So11111111111111111111111111111111111111112,solana:EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v,solana:cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij"
pr = json.loads(urllib.request.urlopen(url, timeout=30).read())
PR = {k.split(":")[1]: v["price"] for k, v in pr["coins"].items()}
print("prices:", PR)

# batch supplies
mints = [p["lst_mint"] for p in pairs.values()]
sup = call("getMultipleAccounts", [mints, {"encoding":"base64"}])["result"]["value"]
total = 0; rows = []
for (addr, p), s in zip(pairs.items(), sup):
    d = base64.b64decode(s["data"][0])
    amount = struct.unpack_from("<Q", d, 36)[0]; dec = d[44]
    rate = calc_rate(p, now)
    base_amount = amount * rate // PRECISION
    gap = p["base_decimals"] - dec
    if gap > 0: base_amount *= 10**gap
    elif gap < 0: base_amount //= 10**(-gap)
    price = PR.get(p["base_mint"], 0)
    usd = base_amount / (10**p["base_decimals"]) * price
    total += usd
    rows.append(dict(symbol=p["symbol"], addr=addr, base=p["base_symbol"], supply=amount/(10**dec),
                     rate=rate/1e12, base_amount=base_amount/(10**p["base_decimals"]), usd=usd,
                     last_ts=p["last_timestamp"], interval_rate=p["interval_rate"], deposit_cap=None))
    print(f"  {p['symbol']:8s} base={p['base_symbol']:6s} supply={amount/(10**dec):>14.6f} rate={rate/1e12:.6f} -> {base_amount/(10**p['base_decimals']):>14.6f} = ${usd:,.2f}")
print(f"\nTOTAL scheduled liability = ${total:,.2f}")
json.dump({"now":now,"rows":rows,"total_usd":total,"prices":PR}, open("liability.json","w"), indent=2)

# windows batched
accts = json.load(open("program-accounts.json"))["WithdrawalWindow"]
pks = [a[0] for a in accts]
win = []
for i in range(0, len(pks), 100):
    r = call("getMultipleAccounts", [pks[i:i+100], {"encoding":"base64"}])["result"]["value"]
    win.extend(r)
summary = {}
detail = []
for pk_, s in zip(pks, win):
    if not s: continue
    d = base64.b64decode(s["data"][0])
    o = 8
    pair = pk(d[o:o+32]); o += 32
    start = struct.unpack_from("<q", d, o)[0]; o += 8
    end = struct.unpack_from("<q", d, o)[0]; o += 8
    req = struct.unpack_from("<Q", d, o)[0]; o += 8
    burned = struct.unpack_from("<Q", d, o)[0]; o += 8
    maxw = struct.unpack_from("<Q", d, o)[0]; o += 8
    ewt = struct.unpack_from("<q", d, o)[0]; o += 8
    exp = struct.unpack_from("<q", d, o)[0]; o += 8
    btm = pk(d[o:o+32]); o += 32
    bta = pk(d[o:o+32]); o += 32
    funded = d[o]; o += 1
    bump = d[o]; o += 1
    withdrawn = struct.unpack_from("<Q", d, o)[0]
    key = "ACTIVE" if start <= now < end else ("FUNDED_PENDING" if funded and now < ewt else ("FUNDED_READY" if funded else "past"))
    summary[key] = summary.get(key, 0) + 1
    if start <= now < end or (funded and req>0):
        detail.append(dict(pk=pk_, pair=pair, start=start, end=end, req=req, burned=burned,
                           maxw=maxw, ewt=ewt, exp=exp, funded=funded, withdrawn=withdrawn, state=key))
print("\nwindow states:", summary)
for x in detail:
    print(" ", json.dumps(x))
json.dump({"summary":summary,"detail":detail}, open("windows.json","w"), indent=2)
