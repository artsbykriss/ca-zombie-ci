#!/usr/bin/env python3
"""Dump account info for 01 protocol key accounts."""
import json, urllib.request, time

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

ACCTS = {
 "Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk": "01 program",
 "L2TExMFKdjpN9kozasaurPirfHy9P8sbXoAN1qA3S95": "L2TEx program",
 "Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt": "vault config?",
 "6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon": "acct3 in RedeemUsdc",
 "71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv": "acct1 in RedeemUsdc",
 "5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8": "acct5",
 "4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV": "acct6",
 "3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp": "vault USDC token acct",
 "3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g": "user USDC ATA",
 "HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ": "vault PDA",
}
out={}
for a,label in ACCTS.items():
    try:
        r=rpc("getAccountInfo",[a,{"encoding":"base64"}])
        v=r["result"]["value"]
        if v is None:
            out[a]={"label":label,"exists":False}
            print(f"{a} ({label}): DOES NOT EXIST")
            continue
        import base64
        raw=base64.b64decode(v["data"][0])
        out[a]={"label":label,"exists":True,"owner":v["owner"],"executable":v["executable"],
                "lamports":v["lamports"],"space":v["space"],"data_b64":v["data"][0],"data_hex":raw.hex()[:4000]}
        print(f"{a} ({label}): owner={v['owner']} exec={v['executable']} lamports={v['lamports']} space={v['space']}")
        if v["executable"]:
            pd=rpc("getAccountInfo",[a,{"encoding":"jsonParsed"}])
            print("   parsed:", json.dumps(pd["result"]["value"].get("data"))[:500])
    except Exception as e:
        print(f"{a}: ERROR {e}")
    time.sleep(0.2)
json.dump(out, open("analysis/accounts_raw.json","w"), indent=1)
