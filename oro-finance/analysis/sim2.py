"""Fetch a real transaction and replay it read-only via simulateTransaction
(sigVerify:false, replaceRecentBlockhash:true). Supports account-key substitution.

Read-only: nothing is signed or sent.
"""
import sys, json, base64
sys.path.insert(0, '.')
import rpc2

def get_tx_b64(sig):
    tx = rpc2.call("getTransaction", [sig, {"encoding": "base64",
                                            "maxSupportedTransactionVersion": 0}])
    t = tx["transaction"]
    if isinstance(t, list):
        return t[0]
    if isinstance(t, dict):
        return t["data"][0]
    return t

def simulate(b64, cfg_extra=None):
    cfg = {"encoding": "base64", "sigVerify": False,
           "replaceRecentBlockhash": True, "commitment": "processed"}
    if cfg_extra:
        cfg.update(cfg_extra)
    return rpc2.call("simulateTransaction", [b64, cfg])

def show(res, label=""):
    v = res["value"]
    print("== %s  err=%s  units=%s" % (label, v.get("err"), v.get("unitsConsumed")))
    for l in (v.get("logs") or []):
        print("   ", l)
    return v

if __name__ == "__main__":
    sig = sys.argv[1]
    b = get_tx_b64(sig)
    print("tx bytes:", len(base64.b64decode(b)))
    show(simulate(b), "replay " + sig[:12])
