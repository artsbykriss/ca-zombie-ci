#!/usr/bin/env python3
"""Parse Solana ProgramData header + extract ELF. Read-only."""
import json, os, sys, hashlib, struct

OUT = os.path.dirname(os.path.abspath(__file__))


def parse_pd(path):
    raw = open(path, "rb").read()
    tag = struct.unpack("<I", raw[0:4])[0]
    slot = struct.unpack("<Q", raw[4:12])[0]
    auth_tag = raw[12]
    auth = None
    off = 13
    if auth_tag == 1:
        auth = raw[13:45]
        off = 45
    elf = raw[off:]
    return {"tag": tag, "last_deploy_slot": slot, "auth_tag": auth_tag,
            "authority": _b58(auth) if auth else None, "elf_offset": off,
            "elf_len": len(elf), "sha256": hashlib.sha256(elf).hexdigest()}


def _b58(b):
    import base64
    # solana base58 alphabet
    AL = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = AL[r] + s
    for byte in b:
        if byte == 0:
            s = "1" + s
        else:
            break
    return s


def main():
    for name in sys.argv[1:]:
        p = os.path.join(OUT, name)
        info = parse_pd(p)
        print(name, json.dumps(info, indent=1))
        raw = open(p, "rb").read()
        elf = raw[info["elf_offset"]:]
        outelf = p.replace("-account.bin", ".elf")
        with open(outelf, "wb") as f:
            f.write(elf)
        print("  wrote", outelf)


if __name__ == "__main__":
    main()
