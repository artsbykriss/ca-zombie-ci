#!/usr/bin/env python3
"""Fetch live marginfi bank + oracle state for the program-exact health model.

Outputs (analysis/state/):
  banks_raw.json    - raw getProgramAccounts response for Bank accounts
  banks_decoded.json- decoded Bank structs + emode settings (per bank)
  oracles_raw.json  - raw accounts for every oracle key referenced by a bank
  meta.json         - slot, timestamps

Read-only. No secrets.
"""
import base64, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import PROGRAM, rpc, get_accounts, b58encode

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "state")
os.makedirs(STATE, exist_ok=True)
sys.path.insert(0, HERE)
from decode_bank import decode_bank

BANK_DISC = bytes([142, 49, 166, 242, 50, 66, 97, 188])
EMODE_OFFSET = 920  # in account data (incl. 8-byte discriminator); see decode_bank.py
EMODE_LEN = 424


def decode_emode(raw):
    o = EMODE_OFFSET
    tag = int.from_bytes(raw[o:o + 2], "little")
    timestamp = int.from_bytes(raw[o + 8:o + 16], "little", signed=True)
    flags = int.from_bytes(raw[o + 16:o + 24], "little")
    entries = []
    eo = o + 24
    for i in range(10):
        b = raw[eo + i * 40: eo + (i + 1) * 40]
        etag = int.from_bytes(b[0:2], "little")
        eflags = b[2]
        awi = int.from_bytes(b[8:24], "little", signed=True) / (1 << 48)
        awm = int.from_bytes(b[24:40], "little", signed=True) / (1 << 48)
        if etag:
            entries.append({"tag": etag, "flags": eflags, "aw_init": awi, "aw_maint": awm})
    return {"tag": tag, "timestamp": timestamp, "flags": flags, "entries": entries}


def main():
    slot = rpc("getSlot", [])
    body = {"jsonrpc": "2.0", "id": 1, "method": "getProgramAccounts", "params": [
        PROGRAM, {"encoding": "base64",
                  "filters": [{"memcmp": {"offset": 0, "bytes": b58encode(BANK_DISC)}}]}]}
    import urllib.request
    req = urllib.request.Request("https://api.mainnet-beta.solana.com",
                                 data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=600) as f:
        raw = json.load(f)
    banks = {}
    for e in raw["result"]:
        pk = e["pubkey"]
        data = base64.b64decode(e["account"]["data"][0])
        b = decode_bank(data)
        b["_lamports"] = e["account"]["lamports"]
        b["_owner"] = e["account"]["owner"]
        b["emode"] = decode_emode(data)
        banks[pk] = b
    print(f"decoded {len(banks)} banks in {time.time()-t0:.1f}s")

    # oracle accounts
    keys = []
    for pk, b in banks.items():
        for k in b["config"]["oracle_keys"]:
            if k != "11111111111111111111111111111111" and k not in keys:
                keys.append(k)
    oracles = {}
    for i in range(0, len(keys), 100):
        chunk = keys[i:i + 100]
        res = rpc("getMultipleAccounts", [chunk, {"encoding": "base64"}])
        for pk, v in zip(chunk, res["value"]):
            oracles[pk] = None if v is None else {
                "lamports": v["lamports"], "owner": v["owner"],
                "data": v["data"][0], "len": len(base64.b64decode(v["data"][0]))}
    print(f"fetched {len(oracles)} oracle/aux accounts")

    json.dump(banks, open(os.path.join(STATE, "banks_decoded.json"), "w"))
    json.dump(oracles, open(os.path.join(STATE, "oracles_raw.json"), "w"))
    json.dump({"slot": slot, "fetched_at": int(time.time()), "n_banks": len(banks),
               "n_oracles": len(oracles)}, open(os.path.join(STATE, "meta.json"), "w"), indent=1)
    print("slot", slot)


if __name__ == "__main__":
    main()
