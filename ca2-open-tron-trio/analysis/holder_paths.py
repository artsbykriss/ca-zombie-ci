#!/usr/bin/env python3
"""Targeted holder-path evidence: known depositors/players, read-only constant calls."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

OUT = os.path.dirname(os.path.abspath(__file__))
F = T.fresh_address()
ZERO = T.enc_addr(T.hex_to_addr("0" * 40))
res = {"block": None, "probe_address": F, "cases": []}


def call(owner, contract, sig, param=""):
    r = T.trigger(owner, contract, sig, param)
    return {"sig": sig, "owner": owner, "result": r.get("result"),
            "constant_result": r.get("constant_result"),
            "energy_used": r.get("energy_used")}


def w(r):
    b = "".join(r.get("constant_result") or [])
    return [int(b[i:i + 64], 16) for i in range(0, len(b), 64)] if b else []


res["block"] = T.now_block()
# Cherry: top historical depositor (90.44M TRX deposited)
cherry_user = "TC75n5u2iwvWi9VP1dir7GDEbCZp7T5kaM"
for sig, p in [("getUserTokenAmount(address)", T.enc_addr(cherry_user)),
               ("tokenUserAmountOf(address,address)", T.enc_addr(cherry_user) + ZERO),
               ("withdrawTronAll()", ""), ("withdrawAll()", "")]:
    r = call(cherry_user, "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR", sig, p)
    r["decoded"] = w(r)
    res["cases"].append({"contract": "CherryPool", **r})
    print("Cherry", sig, r["decoded"], "energy", r["energy_used"])
    time.sleep(1.0)

# FireFull: a recent withdrawer + a super player; players() field8 then withdraw()
for u in ["TMn2W1YbY1uJk9nS8xWqXrW1tQ4Fh2fVvX" ]:
    pass
for u in ["TMP5tuCmVoaxJ5cGTE7qt3AaaKmT41Ecc4"]:
    for sig, p in [("players(address)", T.enc_addr(u)),
                   ("superPlayerList(address)", T.enc_addr(u)),
                   ("withdraw()", ""), ("superPlayerWithdraw()", "")]:
        r = call(u, "TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW", sig, p)
        r["decoded"] = w(r)
        res["cases"].append({"contract": "FireFull", **r})
        print("FireFull", u, sig, r["decoded"], "energy", r["energy_used"], "msg",
              (r["result"] or {}).get("message"))
        time.sleep(1.0)

# Poker: known paid player of game 18 (balance_of == 0 now) and owner
for u in ["TYzvvbgbJGRCtie2j8sZNFTjr3ckkPPFdj"]:
    for sig, p in [("balance_of(address)", T.enc_addr(u)), ("withdraw()", "")]:
        r = call(u, "TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn", sig, p)
        r["decoded"] = w(r)
        res["cases"].append({"contract": "PokerGame", **r})
        print("Poker", u, sig, r["decoded"], "energy", r["energy_used"])
        time.sleep(1.0)

json.dump(res, open(f"{OUT}/holder_paths.json", "w"), indent=1)
print("wrote holder_paths.json")
