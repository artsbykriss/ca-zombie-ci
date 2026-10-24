#!/usr/bin/env python3
import base64, json, sys
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import get_account, call

PROGRAM = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV"

acct = get_account(PROGRAM)
raw = base64.b64decode(acct["data"][0])
print("program acct bytes:", len(raw), "owner:", acct["owner"], "executable:", acct["executable"])
enum = int.from_bytes(raw[0:4], "little")
print("enum:", enum, "(2=Program)")
pd_addr_bytes = raw[4:36]
# base58 encode
ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n > 0:
        n, r = divmod(n, 58)
        s = ALPHABET[r] + s
    pad = 0
    for x in b:
        if x == 0: pad += 1
        else: break
    return "1" * pad + s
pd_addr = b58(pd_addr_bytes)
print("ProgramData address:", pd_addr)

pd = get_account(pd_addr)
print("programdata owner:", pd["owner"], "executable:", pd["executable"], "lamports:", pd["lamports"])
pdraw = base64.b64decode(pd["data"][0])
print("programdata len:", len(pdraw))
# layout: u32 enum(3=ProgramData), u64 slot, u8 option, 32 upgrade authority, ELF
pd_enum = int.from_bytes(pdraw[0:4], "little")
slot = int.from_bytes(pdraw[4:12], "little")
has_auth = pdraw[12]
auth = pdraw[13:45]
print("pd_enum:", pd_enum, "slot:", slot, "has_authority:", has_auth, "upgrade_authority:", b58(auth) if has_auth else "NONE")
elf = pdraw[45:]
print("elf len:", len(elf), "magic:", elf[:4].hex())
open("/home/heisenberg/CA/exceed-finance/analysis/childB/exceed.elf", "wb").write(elf)
# hash
import hashlib
print("elf sha256:", hashlib.sha256(elf).hexdigest())
json.dump({"program": PROGRAM, "programdata": pd_addr, "slot": slot,
           "upgrade_authority": b58(auth) if has_auth else None,
           "elf_sha256": hashlib.sha256(elf).hexdigest(), "elf_len": len(elf)},
          open("/home/heisenberg/CA/exceed-finance/analysis/childB/elf-meta.json", "w"), indent=2)
print("saved exceed.elf")
