#!/usr/bin/env python3
"""Enumerate 01 Margin accounts via getProgramAccounts (dataSlice) and find non-zero collateral."""
import json, urllib.request, time, base64, struct, sys

RPCs = ["https://api.mainnet-beta.solana.com","https://solana-rpc.publicnode.com"]
def rpc(method, params, url, retries=3, timeout=180):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(2*(i+1))
    raise RuntimeError(f"{url}: {last}")

ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,rem=divmod(n,58); s=ALPH[rem]+s
    for by in b:
        if by==0: s='1'+s
        else: break
    return s or '1'

disc = bytes.fromhex("98118ec350c4a130")
disc_b58 = b58e(disc)
print("Margin discriminator b58:", disc_b58)

def i80f48(raw):
    v=int.from_bytes(raw,'little')
    if v & (1<<127): v -= (1<<128)
    return v / (1<<48)

filters=[{"dataSize":793},{"memcmp":{"offset":0,"bytes":disc_b58}}]
for url in RPCs:
    try:
        r=rpc("getProgramAccounts",["Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk",
            {"encoding":"base64","filters":filters,"dataSlice":{"offset":0,"length":441},"commitment":"confirmed"}], url)
        accs=r["result"]
        print(f"{url}: {len(accs)} margin accounts")
        break
    except Exception as e:
        print(f"{url} failed: {e}")
        accs=None
if not accs:
    sys.exit(1)

rows=[]
for a in accs:
    pk=a["pubkey"]; raw=base64.b64decode(a["account"]["data"][0])
    nonce=raw[8]; auth=raw[9:41]
    coll=[i80f48(raw[41+i*16:41+i*16+16]) for i in range(25)]
    nz=[(i,round(x,6)) for i,x in enumerate(coll) if abs(x)>1e-9]
    rows.append({"margin":pk,"authority":b58e(auth),"nonce":nonce,"collateral":coll,"nonzero":nz})
json.dump(rows, open("analysis/all_margins.json","w"), indent=1)
funded=[r for r in rows if r["nonzero"]]
print("margins with non-zero collateral:", len(funded))
for r in funded[:40]:
    print("  ", r["margin"], r["authority"], "nonce", r["nonce"], r["nonzero"])
