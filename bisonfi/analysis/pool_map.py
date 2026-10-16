#!/usr/bin/env python3
"""Build the full pool-state map: 29 POOLSTAT accounts, decode fields, cached balances, last-update slots.
Also decode SPL token account amounts for the main vaults. Read-only."""
import base64, json, os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPHA.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big') if n else b''
def b58e(b):
    n=int.from_bytes(b,'big'); out=''
    while n: n,r2=divmod(n,58); out=ALPHA[r2]+out
    for c in b:
        if c==0: out='1'+out
        else: break
    return out

states=json.load(open(os.path.join(OUT,"pool-states-2048.json")))
rows=[]
for s in states:
    d=base64.b64decode(s["data_b64"])
    name=d[256:272].rstrip(b"\x00").decode('latin1')
    vault_wsol=b58e(d[120:152]); vault_usdc=b58e(d[152:184])
    mint_wsol=b58e(d[184:216]); mint_usdc=b58e(d[216:248])
    slot_a=struct.unpack_from("<Q",d,72)[0]
    slot_b=struct.unpack_from("<Q",d,80)[0]
    ts_ns=struct.unpack_from("<Q",d,88)[0]
    cached_wsol=struct.unpack_from("<Q",d,48)[0]
    cached_usdc=struct.unpack_from("<Q",d,56)[0]
    f64=struct.unpack_from("<Q",d,64)[0]
    p104=struct.unpack_from("<Q",d,104)[0]
    p112=struct.unpack_from("<Q",d,112)[0]
    flags=struct.unpack_from("<Q",d,96)[0]
    rows.append(dict(pubkey=s["pubkey"],name=name,vault_wsol=vault_wsol,vault_usdc=vault_usdc,
                     mint_wsol=mint_wsol,mint_usdc=mint_usdc,last_slot=slot_a,prev_slot=slot_b,
                     ts_ns=ts_ns,cached_wsol=cached_wsol,cached_usdc=cached_usdc,f64=f64,
                     p104=p104,p112=p112,flags=flags,lamports=s["lamports"]))
rows.sort(key=lambda r:-r["last_slot"])
cur=rpc("getSlot",[{"commitment":"confirmed"}]).get("result")
print("current slot:",cur)
print(f"{'pool':44s} {'name':16s} {'lastslot':>10s} {'d':>7s} {'cachedWSOL':>16s} {'cachedUSDC':>16s} {'ts':>12s}")
for r in rows:
    import datetime
    ts=r["ts_ns"]//1_000_000_000
    tstr=datetime.datetime.utcfromtimestamp(ts).strftime("%m-%d %H:%M") if ts>1_500_000_000 else "?"
    print(f"{r['pubkey']:44s} {r['name']:16s} {r['last_slot']:10d} {cur-r['last_slot']:7d} {r['cached_wsol']/1e9:16.4f} {r['cached_usdc']/1e6:16.2f} {tstr:>12s}")
json.dump(rows, open(os.path.join(OUT,"pool-states-decoded.json"),"w"), indent=1)

# decode main vault token accounts
def token_amount(addr):
    r=rpc("getAccountInfo",[addr,{"encoding":"base64","commitment":"confirmed"}])
    v=(r.get("result") or {}).get("value")
    if not v: return None
    d=base64.b64decode(v["data"][0])
    amt=struct.unpack_from("<Q",d,64)[0]
    mint=b58e(d[0:32]); owner=b58e(d[32:64])
    return dict(amount=amt,mint=mint,owner=owner,lamports=v["lamports"])
for label,a in [("cur_wsol_vault","ATRsNGv2nDw7hSMfkUTBoVUDsFDwN7po7KbecyiGWNB4"),
                ("cur_usdc_vault","2Y7HATmn9aJBcxCskE5V2U2epmjvkZmB51zTJBbhj4cU"),
                ("old_wsol_vault","FxGiN5NkigicwrnFshZEAUH9C13yrBALmgYxA9x8sfnQ"),
                ("old_usdc_vault","6DMF4t6Ks8yXhG8K3rrTAeNYrqNrr1DwewHvBmH3a3FX")]:
    t=token_amount(a)
    if t: print(f"{label}: {a} amount={t['amount']} mint={t['mint']} owner={t['owner']} lamports={t['lamports']}")
