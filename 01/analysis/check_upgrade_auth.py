#!/usr/bin/env python3
"""Check upgrade authorities of the two programs."""
import json, urllib.request, time, base64

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

for name, pd in [("01_program (Zo1ggz...)","52xHuqibnMfqrPeN2zpg1ygKkLpJ3HHxU1QzX97VB4AN"),
                 ("L2TEx_program","CJ5WEjifs4d77pEA9DpewppByFjHcAkNv3YYSuSoDk7c")]:
    r=rpc("getAccountInfo",[pd,{"encoding":"base64"}])
    v=r["result"]["value"]
    raw=base64.b64decode(v["data"][0])
    # programData layout: [0..4] enum tag (3), [4..12] slot, [12] option tag for authority, [13..45] authority
    slot=int.from_bytes(raw[4:12],"little")
    has_auth=raw[12]
    auth=None
    if has_auth==1:
        auth_bs=raw[13:45]
        # base58 encode
        ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
        n=int.from_bytes(auth_bs,'big'); s=''
        while n: n,rem=divmod(n,58); s=ALPH[rem]+s
        for b in auth_bs:
            if b==0: s='1'+s
            else: break
        auth=s
    print(f"{name}: programData owner={v['owner']} size={v['space']} last_deploy_slot={slot} upgrade_authority={auth if auth else 'NONE (immutable)'}")
    print("   data hex head:", raw[:60].hex())
