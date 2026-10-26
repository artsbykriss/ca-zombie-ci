#!/usr/bin/env python3
"""Perena (numeraire) swap simulations. Read-only: simulateTransaction, sigVerify:false.
Tests whether caller-supplied hints can bypass the swap bound.
"""
import json, hashlib, struct, sys, base64, time
from rpc import call
from b58 import b58dec, b58enc
from sim import build_legacy, simulate

PID = "NUMERUNsFCP3kuNmWZuXtm1AaQCPj9uw6Guv2Ekoi5P"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"

# pool 2w4A1eGy (USDC/USDT/USD*) -- active, real swaps observed
POOL = "2w4A1eGyjRutakyFdmVyBiLPf98qKxNTC2LpuwhaCruZ"
CFG = "FS159v4b2jo3fjGBaUFmDzgx7k616XhpKhMwX2Q3HeeD"
PAYER = "8eBPJ5WnHHqf8tfHCPuV2TTATGimQ8hS7ab8guL348ed"  # funded, from real tx
# pair indices: 0=USDC EPjFW, 1=USDT Es9vMF, 2=USD* 2b1kV6Dk
PAIRS = {
 0: {"mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","vault":"6B8k8At9879r5EsZAWg8W6DEpxzJ798Cwj48twu3pq4b","dec":6},
 1: {"mint":"Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB","vault":"DJfYbGicp4AFXWsragNWv1baugqcdFhw6eFTcK2YWdyK","dec":6},
 2: {"mint":"2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo","vault":"4jV62TqjV4oUyNBioPo9dJZGyjTcgfBDkuG4VbgxfqWC","dec":6},
}

def disc(n): return hashlib.sha256(("global:"+n).encode()).digest()[:8]

def data_hintless(in_i, out_i, amt_in, min_out):
    return disc("swap_exact_in") + struct.pack("<BBQQ", in_i, out_i, amt_in, min_out)

def data_hinted(in_i, out_i, amt_in, min_out, hints, path_hints):
    b = disc("swap_exact_in_hinted") + struct.pack("<BBQQ", in_i, out_i, amt_in, min_out)
    b += struct.pack("<10Q", *hints)
    b += bytes(path_hints)
    return b

def data_quote(in_i, out_i, amt_in, min_out, hints, path_hints):
    b = disc("swap_exact_in_quote") + struct.pack("<BBQQ", in_i, out_i, amt_in, min_out)
    b += struct.pack("<10Q", *hints)
    b += bytes(path_hints)
    return b

def build(in_i, out_i, data, in_trader, out_trader, payer=PAYER):
    im, om = PAIRS[in_i], PAIRS[out_i]
    accounts = [POOL, im["mint"], om["mint"], in_trader, out_trader,
                im["vault"], om["vault"], CFG, payer, TOKEN, TOKEN22]
    writable = [POOL, im["mint"], om["mint"], in_trader, out_trader, im["vault"], om["vault"], CFG]
    readonly = [TOKEN, TOKEN22, PID]
    return accounts, writable, readonly

def run(tag, in_i, out_i, data, in_trader, out_trader, extra_accounts=None):
    bh = call("getLatestBlockhash",[{"commitment":"processed"}])["value"]["blockhash"]
    accounts, writable, readonly = build(in_i,out_i,data,in_trader,out_trader)
    ix = (PID, accounts, data)
    tx = build_legacy(PAYER, [PAYER], writable, readonly, bh, [ix])
    cfg = {"accounts": {"encoding":"base64", "addresses":[out_trader, in_trader]}}
    r = simulate(tx, cfg)
    val = r["value"]
    logs = val.get("logs") or []
    print(f"--- {tag} ---")
    print("err:", val.get("err"))
    print("unitsConsumed:", val.get("unitsConsumed"))
    for l in logs[-14:]:
        print("   ", l)
    for a in val.get("accounts") or []:
        if a:
            try:
                d = base64.b64decode(a["data"][0])
                amt = struct.unpack_from("<Q", d, 64)[0]
                print("    acct", a.get("owner"), "amount", amt)
            except Exception:
                pass
    return r

if __name__ == "__main__":
    # placeholder trader accounts (0 balance) -- we read logs to see computed amounts
    IN_TRADER = "2NjQCWsU8WHcUt5fxyjRFdNARXWoxKrT8tpfD5sSfzKB"
    OUT_TRADER = "GVDpmDSG9hsEkJJPyyTNWNQBCRzbNrhbyqJKD9f194q1"
    amt = 100_000_000  # 100 units (6 dec)
    run("hintless USD*->USDT 0.1", 2, 1, data_hintless(2,1,100000,0), IN_TRADER, OUT_TRADER)
    run("hinted hints=0", 2, 1, data_hinted(2,1,100000,0,[0]*10,[0]*10), IN_TRADER, OUT_TRADER)
    run("hinted hints=MAX", 2, 1, data_hinted(2,1,100000,0,[2**64-1]*10,[0]*10), IN_TRADER, OUT_TRADER)
    run("quote hints=0", 2, 1, data_quote(2,1,100000,0,[0]*10,[0]*10), IN_TRADER, OUT_TRADER)
