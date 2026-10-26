import sys, json, base64
sys.path.insert(0, '.')
import rpc2
from b58 import b58enc


def info(addrs):
    r = rpc2.multi(addrs, {"encoding": "base64"})
    for a, v in zip(addrs, r):
        if v is None:
            print(a, "-> None")
            continue
        raw = base64.b64decode(v["data"][0])
        print(a, "owner", v["owner"], "lam", v["lamports"], "len", len(raw), "exec", v["executable"])
        if v["owner"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" and len(raw) >= 165:
            mint = b58enc(raw[0:32]); owner = b58enc(raw[32:64]); amt = int.from_bytes(raw[64:72], 'little')
            print("   TOKEN mint", mint, "owner", owner, "amount", amt)
        else:
            print("   hex", raw[:80].hex())


if __name__ == "__main__":
    info(sys.argv[1:])
