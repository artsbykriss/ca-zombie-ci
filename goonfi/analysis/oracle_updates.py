#!/usr/bin/env python3
"""Who updates the GoonFi oracle-relay accounts? Fetch + decode recent update txs."""
import json, os, sys, base64, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from wire_tx import decode_wire

OUT = os.path.dirname(os.path.abspath(__file__))

ORACLES = {
    "7yec_GMCJ": "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3",
    "FggV_Daop": "FggV5dLyuFC5SMqxhpF64xkHu1rXiTUP3CwufV5ZSam4",
    "oracle_prog": "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu",
    "updater_pda": "updapqBoqhn48uaVxD7oKyFVEwEcHmqbgQa1GvHaUuX",
}


def sigs(addr, limit=25):
    r = rpc("getSignaturesForAddress", [addr, {"limit": limit}])
    return r.get("result", [])


def main():
    for label, addr in ORACLES.items():
        s = sigs(addr)
        print(f"== {label} {addr}: {len(s)} sigs")
        for x in s[:12]:
            print("   slot", x["slot"], "sig", x["signature"][:48], "err", x.get("err") is not None)
        with open(os.path.join(OUT, f"oracle-sigs-{label}.json"), "w") as f:
            json.dump(s, f, indent=1)
        time.sleep(0.4)
    # decode the most recent oracle-update tx
    s = json.load(open(os.path.join(OUT, "oracle-sigs-7yec_GMCJ.json")))
    if s:
        sig = s[0]["signature"]
        r = rpc("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 0}])
        tx = r.get("result")
        if tx:
            t = tx["transaction"]
            b64 = t[0] if isinstance(t, list) else t
            dec = decode_wire(b64)
            r2 = rpc("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
            jtx = r2.get("result")
            keys = [k["pubkey"] for k in jtx["transaction"]["message"]["accountKeys"]]
            signers = [k["pubkey"] for k in jtx["transaction"]["message"]["accountKeys"] if k.get("signer")]
            print("\n== latest oracle-update tx", sig)
            print("slot", tx["slot"], "signers:", signers)
            print("accounts:", keys)
            for i, ix in enumerate(dec["ixs"]):
                print(f"[{i}] pid={keys[ix['pid']]} data={ix['data'].hex()}")
                print("    accs:", [keys[a] for a in ix["accs"]])
            print("logs:")
            for l in tx["meta"].get("logMessages", [])[:40]:
                print("  ", l)
            with open(os.path.join(OUT, "oracle-update-tx.json"), "w") as f:
                json.dump({"sig": sig, "slot": tx["slot"], "signers": signers, "accounts": keys,
                           "ixs": [{"pid": keys[ix["pid"]], "data": ix["data"].hex(),
                                    "accs": [keys[a] for a in ix["accs"]]} for ix in dec["ixs"]],
                           "logs": tx["meta"].get("logMessages", [])}, f, indent=1)


if __name__ == "__main__":
    main()
