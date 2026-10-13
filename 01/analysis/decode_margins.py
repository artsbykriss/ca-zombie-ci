#!/usr/bin/env python3
"""Decode Margin account collateral (WrappedI80F48) for several users; find funded victims."""
import json, urllib.request, time, base64, struct

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=5):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

def i80f48(raw):
    v=int.from_bytes(raw,'little')
    if v & (1<<127): v -= (1<<128)
    return v / (1<<48)

# Margin accounts from recent RedeemUsdc txs (account[4]) + their owners
cases = {
 "531euoNtZMvciBcKPBvYgFJoWnUvtu4PjasDhbTTXTGG": "5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8",
 "GveuASEeBa24wtT4ZrU194akE9Ev6AYQBcndK4Proqav": "A41H1VJiVy38Aef4p2nFVqTa2oDsw67pR6y32MoA3hc2",
 "7hxZYNbw75M66ZW2ahkh4GKTCxkhU2BhkDAhhLaUYGdx": "3xP3P3yDk5XJUnMzmZ6pK58u5ej3F324EoqpPVDmPNdH",
 "FLLuCgETQJTQbuuR4o9FX7RvPakrmW4EXUa1uiXcLsYU": "5zy9mRDhvFCoG3ke7GLTmD2Bw53YxKW52gqfJPGw9sGV",
 "C66NLz9rvyFCX2TSKYreAB5iLaTiAmR8cFvbZKGUnt5e": "7ZuH5uh7QKahGJnvd5z5mteysJ6azRxdQL227rXEJFFg",
}
out={}
for owner, margin in cases.items():
    r=rpc("getAccountInfo",[margin,{"encoding":"base64"}])
    v=r["result"]["value"]
    raw=base64.b64decode(v["data"][0])
    nonce=raw[8]
    auth=raw[9:41]
    coll=[i80f48(raw[41+i*16:41+i*16+16]) for i in range(25)]
    ctrl=raw[41+25*16:41+25*16+32]
    out[owner]={"margin":margin,"nonce":nonce,"collateral":coll,"ctrl":ctrl.hex()}
    nz=[(i,round(x,6)) for i,x in enumerate(coll) if abs(x)>1e-9]
    print(f"owner {owner[:12]}.. margin {margin[:12]}.. nonce={nonce}")
    print(f"   non-zero collateral (idx,val): {nz}")
json.dump(out, open("analysis/margin_decoded.json","w"), indent=1)
