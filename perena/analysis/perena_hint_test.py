#!/usr/bin/env python3
"""Perena hint-bypass experiments via swap_exact_in_quote (return data) + hinted.
Read-only simulateTransaction (sigVerify:false)."""
import json, hashlib, struct, base64, time
from rpc import call
from b58 import b58dec
from sim import build_legacy, simulate
from perena_sim import PID, TOKEN, TOKEN22, POOL, CFG, PAYER, PAIRS, data_hinted, data_quote, data_hintless

IN_TRADER = "2NjQCWsU8WHcUt5fxyjRFdNARXWoxKrT8tpfD5sSfzKB"   # USD* (pair2)
OUT_TRADER = "GVDpmDSG9hsEkJJPyyTNWNQBCRzbNrhbyqJKD9f194q1" # USDT (pair1)

def msg_and_sim(data, in_i=2, out_i=1, payer=PAYER):
    im, om = PAIRS[in_i], PAIRS[out_i]
    accounts = [POOL, im["mint"], om["mint"], IN_TRADER, OUT_TRADER,
                im["vault"], om["vault"], CFG, payer, TOKEN, TOKEN22]
    writable = [POOL, im["mint"], om["mint"], IN_TRADER, OUT_TRADER, im["vault"], om["vault"], CFG]
    readonly = [TOKEN, TOKEN22, PID]
    bh = call("getLatestBlockhash",[{"commitment":"processed"}])["value"]["blockhash"]
    tx = build_legacy(payer, [payer], writable, readonly, bh, [(PID, accounts, data)])
    return simulate(tx)

def show(tag, r):
    v = r["value"]
    err = v.get("err")
    rd = v.get("returnData")
    logs = v.get("logs") or []
    line = next((l for l in logs if "Error Code" in l or "failed:" in l), "")
    print(f"[{tag}] err={err} cu={v.get('unitsConsumed')}")
    if line: print("     ", line.strip()[:160])
    if rd:
        raw = base64.b64decode(rd["data"][0])
        print("      returnData len", len(raw), raw.hex())
        # try interpret as u64s
        if len(raw) % 8 == 0:
            print("      u64s:", [struct.unpack_from("<Q", raw, i)[0] for i in range(0, len(raw), 8)])
    return v

if __name__ == "__main__":
    amt = 100000
    print("=== quote baseline hints=0 ===")
    show("quote h0", msg_and_sim(data_quote(2,1,amt,0,[0]*10,[0]*10)))
    for v in [1, 10, 1000, 100000, 10**9, 10**15, 2**63, 2**64-1]:
        show(f"quote h={v}", msg_and_sim(data_quote(2,1,amt,0,[v]*10,[0]*10)))
        time.sleep(0.2)
    print("=== hinted variants ===")
    for v in [0, 1, 100000, 10**15, 2**64-1]:
        show(f"hinted h={v}", msg_and_sim(data_hinted(2,1,amt,0,[v]*10,[0]*10)))
        time.sleep(0.2)
