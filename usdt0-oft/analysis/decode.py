#!/usr/bin/env python3
"""Decode LayerZero ULN302 getConfig(...)(bytes) output into a JSON map.

The raw cast return for `getConfig(oapp, lib, eid, CONFIG_TYPE_ULN=2)` is the
ABI encoding of the ULN config tuple, prefixed by one 32-byte word (0x20) that
cast emits as the outer `bytes` offset. After dropping that first word the body
is: (uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount,
uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs).
"""
import json, sys
from eth_abi import decode as abi_decode

def parse(text):
    out = {}
    eid = None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("EID "):
            eid = line.split()[1]
        elif line.startswith("0x"):
            h = line[2:]
            words = [h[i:i + 64] for i in range(0, len(h), 64)]
            body = bytes.fromhex("".join(words[1:]))  # drop outer 0x20 offset word
            v = abi_decode(
                ["uint64", "uint8", "uint8", "uint8", "address[]", "address[]"],
                body,
            )
            out[eid] = {
                "confirmations": v[0],
                "requiredDVNCount": v[1],
                "optionalDVNCount": v[2],
                "optionalDVNThreshold": v[3],
                "requiredDVNs": [a.lower() for a in v[4]],
                "optionalDVNs": [a.lower() for a in v[5]],
            }
    return out

if __name__ == "__main__":
    print(json.dumps(parse(open(sys.argv[1]).read()), indent=2))
