#!/usr/bin/env python3
"""Pretty-print raw state_raw.json: hex + ascii for each account."""
import sys, json, base64
from b58 import b58enc

def hexd(b, off=0):
    out = []
    for i in range(0, len(b), 32):
        chunk = b[i:i+32]
        h = " ".join(f"{x:02x}" for x in chunk)
        a = "".join(chr(x) if 32 <= x < 127 else "." for x in chunk)
        out.append(f"  {off+i:04x}  {h:<96}  {a}")
    return "\n".join(out)

def main():
    st = json.load(open(sys.argv[1]))
    only = sys.argv[2] if len(sys.argv) > 2 else None
    for name, v in st.items():
        if only and name != only: continue
        if "accounts" not in v: 
            print(f"### {name}: {v}"); continue
        print(f"### {name}  ({v['count']} accounts)")
        for a in v["accounts"][:6]:
            raw = base64.b64decode(a["data_b64"])
            print(f"  pubkey={a['pubkey']} owner={a['owner']} lamports={a['lamports']} len={a['len']}")
            print(hexd(raw))
        if v["count"] > 6:
            print(f"  ... {v['count']-6} more (pubkeys):")
            for a in v["accounts"][6:20]:
                print("    ", a["pubkey"], "len", a["len"])
        print()

if __name__ == "__main__":
    main()
