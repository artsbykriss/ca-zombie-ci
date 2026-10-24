#!/usr/bin/env python3
import base64, json, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import get_account, call
from solders.pubkey import Pubkey

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big"); s = ""
    while n > 0:
        n, r = divmod(n, 58); s = ALPHABET[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\x00"))) + s

MINT = {
 "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":"USDC",
 "So11111111111111111111111111111111111111112":"SOL",
 "cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij":"cbBTC",
 "8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z":"pikUSDC",
 "4J93x2zCNMrL4Qq8Nuvjk9yNLNkf1Vmqz14UxtcM4uny":"exSOL-LST",
 "HabWg55SK5Jam5WUpbk8Wfq7JbuAaFVPu8KVFMJj9yVg":"exBTC-LST",
 "9ir8o6rj7dJsXXFQPbDZcWCiPx4UDcdTKrYZfnct6GDm":"pUSD",
 "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs":"7vfC(?)",
}

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
    initial_exchange_rate = struct.unpack_from("<Q", data, o)[0]; o += 8
    last_rate = struct.unpack_from("<Q", data, o)[0]; o += 8
    last_timestamp = struct.unpack_from("<q", data, o)[0]; o += 8
    extra = data[o:]
    return dict(pair_bump=pair_bump, lst_mint_bump=lst_mint_bump, base_mint=base_mint,
        base_symbol=MINT.get(base_mint, "?"), base_decimals=base_decimals, lst_mint=lst_mint,
        lst_symbol_name=MINT.get(lst_mint, "?"), lst_decimals=lst_decimals, symbol=symbol,
        interval_rate=interval_rate, seconds_per_interval=seconds_per_interval,
        initial_exchange_rate=initial_exchange_rate, last_rate=last_rate,
        last_timestamp=last_timestamp, extra_len=len(extra), extra=extra.hex(), total_len=len(data))

PAIRS = json.load(open("/home/heisenberg/CA/exceed-finance/analysis/childB/program-accounts.json"))["Pair"]
out = {}
for pk, ln, lam in PAIRS:
    a = get_account(pk)
    raw = base64.b64decode(a["data"][0])
    d = decode_pair(raw)
    d["address"] = pk; d["lamports"] = lam
    out[pk] = d
    print(f"\n=== {pk} len={ln} lamports={lam} ===")
    print(f"  symbol={d['symbol']} base={d['base_symbol']} lst={d['lst_symbol_name']} rate={d['last_rate']/1e12:.6f} last_ts={d['last_timestamp']} interval_rate={d['interval_rate']} spi={d['seconds_per_interval']} extra={d['extra']}")
    print(f"  base_mint={d['base_mint']} lst_mint={d['lst_mint']}")
json.dump(out, open("/home/heisenberg/CA/exceed-finance/analysis/childB/all-pairs.json","w"), indent=2)
