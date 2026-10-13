#!/usr/bin/env python3
"""Dump 01 protocol state + per-user accounts; search for u64 USDC amounts."""
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

ACCTS = {
 # global / config
 "71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv":"[0] global state",
 "6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon":"[2] global acct",
 "Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt":"[8] 1KB acct",
 # tx1 user-specific (signer 531euoNt...)
 "5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8":"tx1 [4]",
 "4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV":"tx1 [5]",
 # tx2 user-specific (signer GveuASEe...)
 "A41H1VJiVy38Aef4p2nFVqTa2oDsw67pR6y32MoA3hc2":"tx2 [4]",
 "CdaduteUFTPCUuqZW1WWog1UsZX3CdUCPN4b493YnvJA":"tx2 [5]",
 # upgrade authority
 "DtCyZQSP9AjdasXJPs5m5Q8dovo73UJvUG1ieosofDwX":"upgrade authority",
}
out={}
for a,label in ACCTS.items():
    r=rpc("getAccountInfo",[a,{"encoding":"base64"}])
    v=r["result"]["value"]
    if v is None:
        print(f"{a} ({label}): MISSING"); continue
    raw=base64.b64decode(v["data"][0])
    out[a]={"label":label,"owner":v["owner"],"executable":v["executable"],"lamports":v["lamports"],"len":len(raw),"hex":raw.hex()}
    # find plausible u64 values near USDC scale (1e5..1e9 raw = $0.1..$1000)
    cands=[]
    for off in range(0, max(0,len(raw)-8), 1):
        val=struct.unpack_from("<Q", raw, off)[0]
        if 100000 <= val <= 500_000_000_000:
            cands.append((off,val))
    print(f"{a} ({label}): owner={v['owner'][:12]}.. exec={v['executable']} len={len(raw)} lamports={v['lamports']}")
    print(f"   head: {raw[:48].hex()}")
    if cands:
        print(f"   u64 candidates (off,val): {cands[:24]}")
json.dump(out, open("analysis/state_accounts.json","w"), indent=1)
