#!/usr/bin/env python3
"""Analyze RedeemUsdc account layout; check whether per-user accounts embed the signer pubkey."""
import json, urllib.request, time, base64

RPC = "https://api.mainnet-beta.solana.com"
ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,rem=divmod(n,58); s=ALPH[rem]+s
    for by in b:
        if by==0: s='1'+s
        else: break
    return s or '1'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPH.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    pad=len(s)-len(s.lstrip('1'))
    return b'\x00'*pad+b

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

txs=json.load(open("analysis/recent_txs.json"))
sigs=[s for s in txs if txs[s]]
analysis={}
for s in sigs[:6]:
    v=txs[s]
    msg=v["transaction"]["message"]
    keys=[k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
    for ins in msg["instructions"]:
        if isinstance(ins,dict) and ins.get("programId")=="Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk":
            data=b58d(ins["data"])
            accts=ins.get("accounts")
            print("="*90)
            print("tx", s[:24], "blocktime", v.get("blockTime"))
            print("  instruction data:", ins["data"], "->", data.hex(), f"({len(data)} bytes)")
            signer=[k for k in msg["accountKeys"] if isinstance(k,dict) and k.get("signer")][0]["pubkey"]
            print("  signer:", signer)
            for i,a in enumerate(accts):
                print(f"    [{i}] {a}")
            # fetch user accounts (positions 4,5) and look for signer pubkey inside
            for i in (4,5,2,8,0):
                try:
                    r=rpc("getAccountInfo",[accts[i],{"encoding":"base64"}])
                    val=r["result"]["value"]
                    raw=base64.b64decode(val["data"][0])
                    found=[]
                    for off in range(0, max(0,len(raw)-32)+1):
                        if raw[off:off+32]==b58d(signer):
                            found.append(off)
                    # also check reverse (some store as [u8;32] little?) - no
                    print(f"    acct[{i}] {accts[i][:20]}.. len={len(raw)} owner={val['owner'][:10]}.. signer_pubkey_at_offsets={found} head={raw[:44].hex()}")
                except Exception as e:
                    print(f"    acct[{i}] fetch error {e}")
            analysis[s]={"data":data.hex(),"accounts":accts,"signer":signer}
json.dump(analysis, open("analysis/redeem_layout.json","w"), indent=1)
