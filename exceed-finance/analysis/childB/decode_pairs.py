#!/usr/bin/env python3
import base64, json, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import get_account, call

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big"); s = ""
    while n > 0:
        n, r = divmod(n, 58); s = ALPHABET[r] + s
    pad = 0
    for x in b:
        if x == 0: pad += 1
        else: break
    return "1" * pad + s

PAIRS = {
    "exUSDC": "EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7",
    "exSOL":  "HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop",
    "exBTC":  "GpV9U2yY3L5u4DkWC6Unejsz42iNME4Usk5RzTaA23to",
}

slot = call("getSlot", [])["result"]
print("slot:", slot)

def decode_pair(data):
    o = 8
    pair_bump = data[o]; o += 1
    lst_mint_bump = data[o]; o += 1
    base_mint = b58(data[o:o+32]); o += 32
    base_decimals = data[o]; o += 1
    lst_mint = b58(data[o:o+32]); o += 32
    lst_decimals = data[o]; o += 1
    symbol_len = struct.unpack_from("<I", data, o)[0]; o += 4
    symbol = data[o:o+symbol_len].decode("utf-8", "replace"); o += symbol_len
    interval_rate = struct.unpack_from("<Q", data, o)[0]; o += 8
    seconds_per_interval = struct.unpack_from("<i", data, o)[0]; o += 4
    initial_exchange_rate = data[o:o+8].hex(); o += 8
    last_rate = struct.unpack_from("<Q", data, o)[0]; o += 8
    last_timestamp = struct.unpack_from("<q", data, o)[0]
    return dict(pair_bump=pair_bump, lst_mint_bump=lst_mint_bump, base_mint=base_mint,
                base_decimals=base_decimals, lst_mint=lst_mint, lst_decimals=lst_decimals,
                symbol=symbol, interval_rate=interval_rate, seconds_per_interval=seconds_per_interval,
                initial_exchange_rate=initial_exchange_rate, last_rate=last_rate,
                last_timestamp=last_timestamp, total_len=len(data))

out = {"slot": slot, "pairs": {}}
for name, addr in PAIRS.items():
    a = get_account(addr)
    if not a:
        print(name, addr, "NOT FOUND"); continue
    raw = base64.b64decode(a["data"][0])
    d = decode_pair(raw)
    d["address"] = addr
    d["owner"] = a["owner"]
    d["lamports"] = a["lamports"]
    d["raw_len"] = len(raw)
    out["pairs"][name] = d
    print(f"\n=== {name} {addr} len={len(raw)} owner={a['owner']} ===")
    for k, v in d.items():
        print(f"  {k}: {v}")

json.dump(out, open("/home/heisenberg/CA/exceed-finance/analysis/childB/pairs-raw.json", "w"), indent=2)
print("\nsaved pairs-raw.json")
