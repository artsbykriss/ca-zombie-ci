#!/usr/bin/env python3
"""Decode Perena (numeraire) StablePool accounts. Read-only."""
import json, struct
from rpc import call
from b58 import b58enc

PID = "NUMERUNsFCP3kuNmWZuXtm1AaQCPj9uw6Guv2Ekoi5P"

def rd(b, o, n): return b[o:o+n]
def u64(b,o): return struct.unpack_from("<Q", b, o)[0]
def u32(b,o): return struct.unpack_from("<I", b, o)[0]
def u128(b,o): return struct.unpack_from("<QQ", b, o)
def pk(b,o): return b58enc(b[o:o+32])

def decode_pair(b, o):
    p = {}
    p["pair_authority"] = pk(b,o); o+=32
    p["x_reserve_amount"] = u64(b,o); o+=8
    p["y_reserve"] = u64(b,o); o+=8
    p["curve_Amp"] = u128(b,o); o+=16
    p["curve_a"] = u128(b,o); o+=16
    p["curve_b"] = u128(b,o); o+=16
    p["inv_L"] = u128(b,o); o+=16
    p["owner"] = pk(b,o); o+=32
    p["x_mint"] = pk(b,o); o+=32
    p["x_vault"] = pk(b,o); o+=32
    p["curve_alpha"] = u64(b,o); o+=8
    p["curve_beta"] = u64(b,o); o+=8
    p["newest_rate_num"] = u32(b,o); o+=4
    p["newest_rate_denom"] = u32(b,o); o+=4
    p["decimals"] = b[o]; o+=1
    p["pair_index"] = b[o]; o+=1
    p["x_is_2022"] = b[o]; o+=1
    return p

def decode_pool(raw):
    b = raw[8:]  # skip discriminator
    o = 0
    p = {}
    p["pool_seed"] = pk(b,o); o+=32
    p["lp_mint"] = pk(b,o); o+=32
    p["whitelisted_adder"] = pk(b,o); o+=32
    p["owner"] = pk(b,o); o+=32
    p["inv_T"] = u64(b,o); o+=8
    p["inv_T_max"] = u64(b,o); o+=8
    p["pairs"] = []
    for i in range(10):
        p["pairs"].append(decode_pair(b,o)); o+=368
    p["weights"] = [u32(b,o+4*i) for i in range(10)]; o+=40
    p["total_weight"] = u64(b,o); o+=8
    p["status"] = u32(b,o); o+=4
    p["fee_num"] = u32(b,o); o+=4
    p["fee_denom"] = u32(b,o); o+=4
    p["decimals"] = b[o]; o+=1
    p["num_stables"] = b[o]; o+=1
    return p

def main():
    import base64
    r = call("getProgramAccounts",[PID,{"encoding":"base64"}])
    out = {}
    for e in r:
        raw = base64.b64decode(e["account"]["data"][0])
        if len(raw) != 4024: continue
        try:
            out[e["pubkey"]] = decode_pool(raw)
        except Exception as ex:
            out[e["pubkey"]] = {"err": str(ex)}
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
