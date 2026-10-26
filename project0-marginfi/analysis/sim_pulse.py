#!/usr/bin/env python3
"""marginfi-v2 permissionless price-cache surface: substitution vs control (read-only, sigVerify:false).

T1  lending_pool_pulse_bank_price_cache  with 2 SUBSTITUTED oracle accounts
    -> expect WrongOracleAccountKeys (caller accounts bound to bank_config.oracle_keys)
T2  same instruction with the bank's REAL oracle_keys (Pyth feed + Jito stake pool)
    -> expect success or a price/staleness error, but NOT WrongOracleAccountKeys
"""
import json, sys, os, base64, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import simulate, get_slot, b58dec, b58enc, result

PROG = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
GROUP = "4qp6Fx6tnZkY5Wropq9wUYgtFxXKwE6viZxFHg3rdAG8"
BANK = "Bohoc1ikHLD7xKJuzTyiTyCwzaL5N7ggJQu75A8mKYM8"      # Jito SOL bank (PythLST setup)
PAYER = "CYXEgwbPHu2f9cY3mcUkinzDoDcsSan7myh1uBvYRbEw"     # fee-payer placeholder only (system-owned)
ORACLE0 = "7AviUf9nL62mcxNbQGKm4nKDQnPjswo6c5MX4D57HmyE"   # bank_config.oracle_keys[0] (Pyth feed)
ORACLE1 = "Jito4APyf642JPZPx3hGc6WWJ8zPKtRbRs4P815Awbb"    # bank_config.oracle_keys[1] (Jito stake pool)
SUB0 = "So11111111111111111111111111111111111111112"       # substituted (native mint)
SUB1 = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"       # substituted (USDC mint)
HERE = os.path.dirname(os.path.abspath(__file__))

def disc(name):
    return hashlib.sha256(f"global:{name}".encode()).digest()[:8]

def shortvec(n):
    out = bytearray()
    while True:
        b = n & 0x7F; n >>= 7
        if n == 0:
            out.append(b); break
        out.append(b | 0x80)
    return bytes(out)

def build(keys, n_sig, n_ro_signed, n_ro_unsigned, ix_accounts, prog_idx, data, blockhash):
    msg = bytearray()
    msg += bytes([n_sig, n_ro_signed, n_ro_unsigned])
    msg += shortvec(len(keys))
    for k in keys:
        msg += b58dec(k)
    msg += b58dec(blockhash)
    msg += shortvec(1)
    msg += bytes([prog_idx])
    msg += shortvec(len(ix_accounts))
    msg += bytes(ix_accounts)
    msg += shortvec(len(data)) + data
    return bytes(msg)

def run(name, keys, n_ro_unsigned, ix_accounts, prog_idx, data):
    bh = result("getLatestBlockhash", [{"commitment": "confirmed"}])["value"]["blockhash"]
    msg = build(keys, 1, 0, n_ro_unsigned, ix_accounts, prog_idx, data, bh)
    tx = bytes([1]) + bytes(64) + msg
    out = simulate(base64.b64encode(tx).decode())
    v = (out or {}).get("value", out)
    res = {"test": name, "err": v.get("err"), "logs": (v.get("logs") or [])[-6:],
           "units": v.get("unitsConsumed")}
    print(json.dumps(res, indent=1))
    return res

def main():
    slot = get_slot()
    d = disc("lending_pool_pulse_bank_price_cache")
    results = []
    # keys canonical: [payer(w,s), bank(w,ns), group(r,ns), a1(r,ns), a2(r,ns), prog(r,ns)]
    # T1 substituted
    keys = [PAYER, BANK, GROUP, SUB0, SUB1, PROG]
    results.append(run("T1_substituted_oracle", keys, 4, [2, 1, 3, 4], 5, d))
    # T2 control (real oracle accounts)
    keys = [PAYER, BANK, GROUP, ORACLE0, ORACLE1, PROG]
    results.append(run("T2_real_oracle_control", keys, 4, [2, 1, 3, 4], 5, d))
    with open(os.path.join(HERE, "sim_results.json"), "w") as f:
        json.dump({"slot": slot, "bank": BANK, "instruction": "lending_pool_pulse_bank_price_cache",
                   "results": results}, f, indent=1)

if __name__ == "__main__":
    main()
