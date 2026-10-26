#!/usr/bin/env python3
"""Discover an instruction's account-struct field order by error-driven probing (read-only sim).
At each position, pass a deliberately-wrong account; Anchor names the field that failed.
Usage: python3 probe_fields.py <DISC_HEX> [max_pos]
"""
import sys, json, re
from rpc import call
from b58 import b58enc
from solmsg import build, order_keys
from sim import simulate

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"
WRONG = "GZhzWVhJtsj7Xg9zUt3JiJXzfJZby8sdpGDfyqZ8GdSq"  # system-owned, 0 data
SIGNER = "GUAujt5S2yvnY4HVj5ysiiHfskmLXPkcbVfxcgLVd1is"

def get_bh():
    return call("getLatestBlockhash", [{"commitment": "processed"}])["value"]["blockhash"]

def run(accts, data, signer=SIGNER):
    keys_flags = [(signer, True, True)]
    seen = {signer}
    for a in accts:
        if a in seen:
            continue
        seen.add(a)
        keys_flags.append((a, False, True))
    keys_flags = order_keys(keys_flags)
    keys_flags.append((PID, False, False))
    txb64 = build(keys_flags, get_bh(), [(PID, accts, data)])
    v = simulate(txb64)["value"]
    logs = v.get("logs") or []
    err = json.dumps(v.get("err"))
    field = None
    msg = None
    for l in logs:
        m = re.search(r"caused by account: (\w+)", l)
        if m:
            field = m.group(1)
        m2 = re.search(r"Error Message: (.*)", l)
        if m2:
            msg = m2.group(1)
    return err, field, msg, logs

def main():
    disc = bytes.fromhex(sys.argv[1])
    maxpos = int(sys.argv[2]) if len(sys.argv) > 2 else 16
    prefix = []
    for p in range(maxpos):
        err, field, msg, logs = run(prefix + [WRONG] * 18, disc + b"\x00" * 200)
        print(f"pos {p}: field={field!r} msg={msg!r} err={err}")
        if field is None:
            print("  no account-field error; stopping")
            break
        # heuristic: append the correct account for that field name
        mapping = {
            "signer": SIGNER,
            "authority": SIGNER,
            "payer": SIGNER,
            "role_data": "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47",
            "access_control": "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47",
            "risk_config": "2V8qS36vGHzZogZupifnXsB2u4cg8JRQEWAfY3PaVWW5",
            "risk_config_pending": "JiaCLpaExXxmXk8ZCzdGHmW5jXdvHpRdwznkEdVaMDf",
            "bridge_account": "2WpgSwhTXohXDxxCMmdaKgdaiuD62H6XreDMvu3PykLS",
            "propose_account": "779z6J7LDEXTR94SeEXTRjnaXHMAv9tkiWqnsth69AW9",
            "review_account": "CHFMoiPZUJAUrrTW21yJbgDKBbGPwL2swEPcDE5C23Kx",
            "native_vault": "2qbE2KD98t1QPwQpWf3Rg4SP4Lf8AN9deRfMnEfrrma8",
            "transfer_authority": "8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4",
            "custody_token_account": "6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2",
            "recipient_token_account": "FT4U9VFurWMzytf6891F21aBaWfi2eRPEf7kiU6wYyj8",
            "token_program": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            "system_program": "11111111111111111111111111111111",
            "clock": "SysvarC1ock11111111111111111111111111111111",
        }
        if field not in mapping:
            print("  unknown field; stopping")
            break
        prefix.append(mapping[field])
        print("  appended", mapping[field], "for", field)

if __name__ == "__main__":
    main()
