#!/usr/bin/env python3
"""Fast scan of an ELF for embedded zlib-compressed Anchor IDL blobs."""
import sys, zlib, re

def main():
    data = open(sys.argv[1], "rb").read()
    n = len(data)
    best = None
    count = 0
    for m in re.finditer(rb"\x78[\x01\x5e\x9c\xda]", data):
        off = m.start()
        if off + 16 >= n:
            continue
        count += 1
        try:
            d = zlib.decompressobj()
            out = d.decompress(data[off:off+3_000_000])
            if not d.eof or len(out) < 300:
                continue
            if b"instructions" in out[:8000] or b'"name"' in out[:200]:
                print(f"  HIT off=0x{off:x} decomp={len(out)}")
                if best is None or len(out) > len(best[1]):
                    best = (off, out)
        except Exception:
            continue
    print(f"candidates tried: {count}")
    if best:
        if len(sys.argv) > 2:
            open(sys.argv[2], "wb").write(best[1])
            print("wrote", sys.argv[2], len(best[1]))
        print(best[1][:800])
    else:
        print("no embedded IDL found")

if __name__ == "__main__":
    main()
