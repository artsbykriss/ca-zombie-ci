#!/usr/bin/env python3
"""Decode Squads multisig GRe1iCBE...; identify top1 holder controller via token-account sigs."""
import json, time, urllib.request, base64, struct, sys
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import b58encode, b58decode

URL = "https://api.mainnet-beta.solana.com"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=20, tag=""):
    for i in range(tries):
        try:
            d = post(method, params)
            if "result" in d:
                return d["result"]
            print(tag, "try", i, str(d.get("error"))[:100], flush=True)
        except Exception as e:
            print(tag, "try", i, "exc", str(e)[:80], flush=True)
        time.sleep(min(45, 8 + i * 4))
    return None

MSIG = "GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v"
r = call("getAccountInfo", [MSIG, {"encoding": "base64"}], tag="msig")
if r:
    v = r["value"]
    d = base64.b64decode(v["data"][0])
    print("multisig lamports:", v["lamports"], "owner:", v["owner"], "datalen:", len(d))
    # Squads v4 Multisig decode (best-effort, documented layout):
    o = 8  # discriminator
    create_key = b58encode(d[o:o+32]); o += 32
    config_authority = b58encode(d[o:o+32]); o += 32
    threshold = struct.unpack_from("<H", d, o)[0]; o += 2
    time_lock = struct.unpack_from("<I", d, o)[0]; o += 4
    tx_index = struct.unpack_from("<Q", d, o)[0]; o += 8
    stale_tx_index = struct.unpack_from("<Q", d, o)[0]; o += 8
    print("create_key:", create_key)
    print("config_authority:", config_authority)
    print("threshold:", threshold, "time_lock(s):", time_lock, "tx_index:", tx_index)
    # members: Option<...> variants; scan for plausible member pubkeys after o
    # Print raw hex of the next 40 bytes to reason
    print("next bytes hex:", d[o:o+48].hex())
    json.dump({"lamports": v["lamports"], "owner": v["owner"], "len": len(d),
               "create_key": create_key, "config_authority": config_authority,
               "threshold": threshold, "time_lock": time_lock, "tx_index": tx_index,
               "stale_tx_index": stale_tx_index, "data_b64": v["data"][0]},
              open("/home/heisenberg/CA/phase-stake/analysis/squads_msig.json", "w"), indent=2)

time.sleep(3)
TOP1_TA = "BvN7jJrLSzvJUd3FcR2kjvfzX6zPRkxBdMoK4Whz4cvD"
sigs = call("getSignaturesForAddress", [TOP1_TA, {"limit": 5}], tag="top1ta")
if sigs is not None:
    print("\ntop1 token account sigs:", len(sigs))
    for s in sigs[:5]:
        print(" ", s["slot"], s["blockTime"], s["err"], s["signature"][:24])
    out = []
    for s in sigs[:4]:
        time.sleep(1.5)
        tx = call("getTransaction", [s["signature"], {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}], tag="t1")
        if tx:
            msg = tx["transaction"]["message"]
            progs = [ix.get("programId", "?")[:14] for ix in msg["instructions"]]
            logs = [l for l in (tx["meta"].get("logMessages") or []) if "Instruction" in l][:6]
            out.append({"sig": s["signature"], "slot": tx["slot"], "progs": progs, "logs": logs})
            print("  tx", s["signature"][:20], progs, logs[:3])
    json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/top1_ta_txs.json", "w"), indent=2)
