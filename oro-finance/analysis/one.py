import sys, json, base64
sys.path.insert(0, '.')
import rpc2
from b58 import b58enc

TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"


def one(a):
    v = rpc2.call("getAccountInfo", [a, {"encoding": "base64"}])["value"]
    if v is None:
        print(a, "-> None")
        return
    raw = base64.b64decode(v["data"][0])
    print(a, "owner", v["owner"], "lam", v["lamports"], "len", len(raw), "exec", v["executable"])
    if v["owner"] == TOKEN and len(raw) >= 165:
        mint = b58enc(raw[0:32]); owner = b58enc(raw[32:64]); amt = int.from_bytes(raw[64:72], 'little')
        print("   TOKEN mint", mint, "owner", owner, "amount", amt)
    else:
        print("   hex", raw[:96].hex())


if __name__ == "__main__":
    for a in sys.argv[1:]:
        try:
            one(a)
        except Exception as e:
            print(a, "ERR", e)
