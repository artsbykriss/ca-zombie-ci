#!/usr/bin/env python3
import base64, json, sys, zlib
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import get_account, call
from solders.pubkey import Pubkey

PROGRAM = Pubkey.from_string("par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV")

# Anchor IDL address = find_program_address([], program_id)
idl_addr, bump = Pubkey.find_program_address([], PROGRAM)
print("Anchor IDL account:", idl_addr, "bump:", bump)
a = get_account(str(idl_addr))
if a:
    raw = base64.b64decode(a["data"][0])
    print("IDL acct len:", len(raw), "owner:", a["owner"])
    print("first 8 bytes (disc):", raw[:8].hex())
    auth = raw[8:40]
    from solders.pubkey import Pubkey as P
    print("authority:", P.from_bytes(auth))
    dlen = int.from_bytes(raw[40:44], "little")
    print("data_len field:", dlen)
    body = raw[44:44+dlen]
    print("body first bytes:", body[:4].hex())
    try:
        dec = zlib.decompress(body)
        print("decompressed len:", len(dec))
        open("/home/heisenberg/CA/exceed-finance/analysis/childB/idl.json", "wb").write(dec)
        print("saved idl.json")
    except Exception as e:
        print("zlib failed:", e)
        # maybe not compressed
        open("/home/heisenberg/CA/exceed-finance/analysis/childB/idl-raw.bin", "wb").write(body)
else:
    print("No IDL account found at", idl_addr)
