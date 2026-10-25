#!/usr/bin/env python3
"""Fetch programdata ELF (read-only) and save to file for strings analysis."""
import json, base64, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s

PDATA = "7bzcebKDN8qDkftxobwArKJL8xSGaZ6zBPaY4C4wEhkf"
HERE = os.path.dirname(os.path.abspath(__file__))
# fetch in two slices to be nice
out = b""
for off in (0, 500000, 1000000):
    r = s.get_account_info(PDATA, encoding="base64")
    break
v = r["result"]["value"]
raw = base64.b64decode(v["data"][0])
print("programdata bytes:", len(raw), "space", v["space"], "lamports", v["lamports"])
# header 45 bytes: [0:4] state enum, [4:12] last deploy slot, [12] has auth, [13:45] auth
import struct
print("state", struct.unpack_from("<I", raw, 0)[0])
print("last_deploy", struct.unpack_from("<Q", raw, 4)[0])
elf = raw[45:]
open(os.path.join(HERE, "solayer_susd.so"), "wb").write(elf)
print("elf bytes:", len(elf), "magic", elf[:4].hex())
# check for embedded anchor IDL at tail
tail = raw[-2000:]
open(os.path.join(HERE, "programdata_tail.bin"), "wb").write(tail)
print("tail printable:", "".join(chr(c) if 32 <= c < 127 else "." for c in tail[-400:]))
