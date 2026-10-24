#!/usr/bin/env python3
import json, sys, struct, base64, urllib.request, time
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.pubkey import Pubkey as P

def pk(b): return str(P.from_bytes(b))
accts = json.load(open("program-accounts.json"))["WithdrawalWindow"]
pks = [a[0] for a in accts]
wins = []
for i in range(0, len(pks), 100):
    r = call("getMultipleAccounts", [pks[i:i+100], {"encoding":"base64"}])["result"]["value"]
    wins.extend(r)
    time.sleep(0.3)
info = []
for pk_, s in zip(pks, wins):
    if not s: continue
    d = base64.b64decode(s["data"][0]); o = 8
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
    withdrawn = struct.unpack_from("<Q", d, o+1)[0]
    info.append(dict(pk=pk_, pair=pair, start=start, end=end, req=req, burned=burned,
                     maxw=maxw, ewt=ewt, exp=exp, btm=btm, bta=bta, funded=funded, withdrawn=withdrawn))

# batch read window base token accounts
btas = [x["bta"] for x in info]
toks = []
for i in range(0, len(btas), 100):
    r = call("getMultipleAccounts", [btas[i:i+100], {"encoding":"base64"}])["result"]["value"]
    toks.extend(r); time.sleep(0.3)
sums = {}
nonzero = []
for x, s in zip(info, toks):
    if not s: continue
    d = base64.b64decode(s["data"][0])
    amt = struct.unpack_from("<Q", d, 64)[0]
    x["bal"] = amt
    if amt:
        sums[x["btm"]] = sums.get(x["btm"], 0) + amt
        nonzero.append(x)
print("=== window base token account balances by mint ===")
for m, v in sums.items():
    print(f"   {m} {v} (raw)")
print(f"\n=== windows with nonzero balance: {len(nonzero)} ===")
for x in nonzero:
    print(f"   win={x['pk'][:12]} pair={x['pair'][:8]} mint={x['btm'][:8]} bal={x['bal']} req={x['req']} funded={x['funded']} withdrawn={x['withdrawn']} end={x['end']} exp={x['exp']}")
json.dump({"sums":sums,"nonzero":nonzero}, open("window-capital.json","w"), indent=2)

# pair account lamports
print("\n=== pair account lamports (rent-exempt 160B = 2004480) ===")
for a in json.load(open("program-accounts.json"))["Pair"]:
    print(f"   {a[0][:12]} len={a[1]} lamports={a[2]} extra={a[2]-2004480}")
