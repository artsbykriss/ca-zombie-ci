#!/usr/bin/env python3
"""Count live program accounts per Anchor account type (read-only)."""
import sys, time
from rpc import call
from b58 import b58enc
from disc import ACC_DISC

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"

def main():
    for n, d in ACC_DISC.items():
        try:
            r = call("getProgramAccounts", [PID, {"encoding": "base64",
                     "dataSlice": {"offset": 0, "length": 0},
                     "filters": [{"memcmp": {"offset": 0, "bytes": b58enc(d)}}]}])
            print(f"{n}: {len(r)}")
        except Exception as e:
            print(n, "ERR", e)
        time.sleep(0.35)

if __name__ == "__main__":
    main()
