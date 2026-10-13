#!/usr/bin/env python3
"""Download the 01 program ELF from its programData account (read-only) and extract strings."""
import json, urllib.request, time, base64, sys

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=6, timeout=120):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(2*(i+1))
    raise RuntimeError(str(last))

pd = "52xHuqibnMfqrPeN2zpg1ygKkLpJ3HHxU1QzX97VB4AN"  # 01 program programData
r = rpc("getAccountInfo",[pd,{"encoding":"base64"}])
v=r["result"]["value"]
raw=base64.b64decode(v["data"][0])
open("analysis/01_program_programdata.bin","wb").write(raw)
# ELF starts at offset 45 (after 4 tag + 8 slot + 1 option + 32 authority)
elf = raw[45:]
open("analysis/01_program.elf","wb").write(elf)
print("programData size:", len(raw), "ELF size:", len(elf), "magic:", elf[:4])
