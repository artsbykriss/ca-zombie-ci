#!/usr/bin/env python3
"""Probe 5: DIA updater identity + OracleUpdate log history. Read-only, no secrets."""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls

DIA = "0x86c5997d10d1df6cbb15c01280e596ed5ac90a33"
UPDATER = "0x4b4c4a6e760fdea078efc6bea046946b639bddea"
API = "https://api.teloscan.io/api"

def api_get(url, tries=5):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1.0 * (i + 1))
    raise last

def main():
    rpc = RPC(default_urls("telos"), "telos")
    out = {}
    code, err = rpc.call_ret("eth_getCode", [UPDATER, "latest"])
    out["updater_code"] = code
    out["updater_is_contract"] = bool(code and code not in ("0x", "0x0"))
    nonce, err2 = rpc.call_ret("eth_getTransactionCount", [UPDATER, "latest"])
    out["updater_nonce"] = int(nonce, 16) if nonce else None
    print("updater code:", (code or "")[:100], "len", len(code or "") // 2 - 1, "nonce", out["updater_nonce"])

    # OracleUpdate logs on DIA contract
    topic = "0xa7fc99ed7617309ee23f63ae90196a1e490d362e6f6a547a59bc809ee2291782"
    j = api_get(f"{API}?module=logs&action=getLogs&address={DIA}&fromBlock=1&toBlock=latest&topic0={topic}")
    logs = j.get("result") or []
    out["n_oracleupdate_logs"] = len(logs)
    print("OracleUpdate logs:", len(logs))
    if logs:
        out["first"] = {"block": logs[0]["blockNumber"], "tx": logs[0]["transactionHash"]}
        out["last"] = {"block": logs[-1]["blockNumber"], "tx": logs[-1]["transactionHash"]}
        # decode last few: key in data[0], value, timestamp
        recent = []
        for l in logs[-12:]:
            d = l["data"][2:]
            # event OracleUpdate(string key, uint128 value, uint128 timestamp) -> non-indexed string
            # ABI: offset(0), value(1), ts(2); string at offset
            try:
                off = int(d[0:64], 16)
                ln = int(d[off*2:off*2+64], 16)
                key = bytes.fromhex(d[off*2+64:off*2+64+ln*2]).decode()
                value = int(d[64:128], 16)
                ts = int(d[128:192], 16)
                recent.append({"block": int(l["blockNumber"], 16), "key": key, "value": value, "ts": ts, "tx": l["transactionHash"]})
            except Exception as e:
                recent.append({"decode_err": str(e)[:100], "data": d[:200]})
        out["recent"] = recent
        for r in recent:
            print(r)

    # updater tx history page 1
    j2 = api_get(f"{API}?module=account&action=txlist&address={UPDATER}&page=1&offset=25&sort=desc")
    txs = j2.get("result") or []
    out["updater_n_txs_page1"] = len(txs)
    print("updater txs page1:", len(txs))
    for t in txs[:10]:
        print(t.get("blockNumber"), t.get("to"), t.get("functionName", "")[:60], t.get("timeStamp"))

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "telos-probe5.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
