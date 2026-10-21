#!/usr/bin/env python3
"""Second pass: per-market bond snapshot, hook, payment token, pause state."""
import json, os, sys, time
import requests
from eth_abi import encode, decode
from eth_utils import keccak

RPC = os.environ.get("BASE_RPC", "https://base-rpc.publicnode.com")
MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
HERE = os.path.dirname(os.path.abspath(__file__))


def sig(s):
    return "0x" + keccak(text=s).hex()[:8]


S = {k: sig(v) for k, v in {
    "rb": "resolverBondAmount()", "db": "disputerBondAmount()", "eb": "escalatorBondAmount()",
    "hook": "hookAddress()", "pay": "paymentToken()", "paused": "paused()", "bondSettled": "bondSettled()",
}.items()}
SEL_MC = sig("aggregate3((address,bool,bytes)[])")


def rpc(method, params, tries=6):
    for i in range(tries):
        try:
            r = requests.post(RPC, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params},
                              timeout=90, headers={"User-Agent": "Mozilla/5.0 research"}).json()
            if "result" in r:
                return r["result"]
        except Exception:
            pass
        time.sleep(1.5 * (i + 1))
    raise RuntimeError("rpc fail")


def mc(calls):
    enc = encode(["(address,bool,bytes)[]"], [[(t, True, bytes.fromhex(d[2:])) for t, d in calls]])
    res = rpc("eth_call", [{"to": MC3, "data": SEL_MC + enc.hex()}, "latest"])
    return decode(["(bool,bytes)[]"], bytes.fromhex(res[2:]))[0]


def main():
    d = json.load(open(os.path.join(HERE, "markets.json")))
    mk = d["markets"]
    keys = list(S.keys())
    for i in range(0, len(mk), 70):
        ch = mk[i:i + 70]
        calls = []
        for x in ch:
            for k in keys:
                calls.append((x["address"], S[k]))
        res = mc(calls)
        for j, x in enumerate(ch):
            for k in keys:
                ok, ret = res[j * len(keys) + keys.index(k)]
                if not ok:
                    continue
                if k in ("hook", "pay"):
                    x[k] = "0x" + bytes(ret)[-20:].hex()
                else:
                    x[k] = int.from_bytes(ret, "big")
        print(f"  {min(i+70,len(mk))}/{len(mk)}", file=sys.stderr)
    json.dump(d, open(os.path.join(HERE, "markets.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
