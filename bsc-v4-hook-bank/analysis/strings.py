#!/usr/bin/env python3
import json
code=open("/tmp/opencode/kh/bsc_bank.hex").read().strip()
if code.startswith("0x"): code=code[2:]
b=bytes.fromhex(code)
print("code len",len(b))
# find ASCII "SPL"
for s in [b"SPL", b"Unauthorized", b"InvalidSqrtPriceLimit", b"Pool", b"swap", b"bank", b"Bank", b"whitelist", b"Whitelist", b"builder", b"trader"]:
    idx=b.find(s)
    print(f"  {s!r}: {'@'+hex(idx) if idx>=0 else 'not found'}")
# selectors of interest
import binascii
for sel in ["f35ca728","d1e57635","9e1941ca","a3f8ea7c","43308267","9a462d4a","f9125e2c","b6a5d7de","716629d5","483bd75e","05e85860","35230cd8","fad7c5c6","e7dd6c65","fc102e12","8eb1172f","d3a57c62"]:
    needle=b"\x63"+bytes.fromhex(sel)   # PUSH4 sel
    pos=b.find(needle)
    print(f"  PUSH4 {sel} @ {hex(pos) if pos>=0 else 'nf'}")
# find Unauthorized selector 0x82b42900 as PUSH4
print("PUSH4 0x82b42900 @", hex(b.find(b"\x63\x82\xb4\x29\x00")))
print("PUSH4 0xb5c41efe @", hex(b.find(b"\x63\xb5\xc4\x1e\xfe")))
