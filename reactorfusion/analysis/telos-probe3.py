#!/usr/bin/env python3
"""Probe 3: DIA oracle storage/updater/permission simulation + ABIs.
Read-only (eth_call simulation only; no transactions). No secrets."""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec, _keccak

DIA = "0x86c5997d10d1df6cbb15c01280e596ed5ac90a33"
ORACLE = "0x0fa9de8362e662d6659a05ad284a2f454f49a8e2"

def api(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read())

def main():
    rpc = RPC(default_urls("telos"), "telos")
    block = rpc.block_number()
    out = {"block": block}

    # storage slots
    stor = {}
    for slot in range(0, 4):
        r, e = rpc.call_ret("eth_getStorageAt", [DIA, hex(slot), "latest"])
        stor[slot] = r
        print(f"slot {slot}: {r} err={e}")
    out["dia_storage_slots_0_3"] = stor

    # code size
    code, e = rpc.call_ret("eth_getCode", [DIA, "latest"])
    out["dia_code_len"] = len(code) // 2 - 1 if code else None
    print("dia code bytes:", out["dia_code_len"])

    # simulate setValue from arbitrary EOA vs from storage-slot-1 address
    updater = None
    if stor.get(1):
        updater = "0x" + stor[1][-40:]
    out["candidate_updater_slot1"] = updater
    print("candidate updater (slot 1):", updater)

    calldata_setvalue = calldata("setValue(string,uint128,uint128)", ["string", "uint128", "uint128"],
                                 ["TLOS/USD", 1, 1791999850])
    for label, frm in [("random", "0x000000000000000000000000000000000000dEaD"),
                       ("owner9999", "0x99999a3c4cb8427c44294ad36895b6a3a047060d"),
                       ("updater", updater)]:
        if not frm:
            continue
        try:
            r = rpc._post(rpc.urls[0][1], {"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                                           "params": [{"to": DIA, "from": frm, "data": calldata_setvalue}, "latest"]}, timeout=25)
            out[f"sim_setValue_{label}"] = r
            print(f"sim setValue from {label}: {str(r)[:160]}")
        except Exception as ex:
            out[f"sim_setValue_{label}"] = f"transport err {ex}"
            print(f"sim setValue from {label}: ERR {ex}")

    # ABIs
    for label, addr in [("dia", DIA), ("oracle", ORACLE)]:
        try:
            j = api(f"https://api.teloscan.io/api?module=contract&action=getabi&address={addr}")
            abi = json.loads(j["result"]) if j.get("result") else []
            fns = sorted(x.get("name", "?") for x in abi if x.get("type") == "function")
            out[f"abi_{label}_functions"] = fns
            print(f"{label} functions:", fns)
        except Exception as ex:
            out[f"abi_{label}"] = f"err {ex}"
            print(label, "ABI err", ex)

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "telos-probe3.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
