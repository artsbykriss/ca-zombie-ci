#!/usr/bin/env python3
"""ZH4 post-unhalt scan (read-only).

Scans a block window on THORChain for:
  * any CosmWasm MsgExecuteContract txs (is the app layer executing again?)
  * any rujira-fin `range.transfer` messages (the exploit primitive)
  * any rujira-fin `range.*` messages at all
  * top-level callers of FIN and of the contract-owner vectors

Usage: python3 analysis/scan_postunhalt.py <from_height> <to_height> [threads]
Writes ci-out/postunhalt-scan.json. No secrets, no transactions.
"""
import base64, json, sys, urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

BASE = "https://gateway.liquify.com/chain/thorchain_api"
OUT = "ci-out/postunhalt-scan.json"


def get(path, tries=4, t=40):
    last = None
    for _ in range(tries):
        try:
            r = urllib.request.Request(BASE + path, headers={"User-Agent": "Mozilla/5.0"})
            return json.load(urllib.request.urlopen(r, timeout=t))
        except Exception as e:  # noqa: BLE001
            last = e
    raise last


def fin_addrs():
    c = get("/thorchain/contracts")
    return {x["address"] for x in c.get("infos", []) if x.get("contract") == "rujira-fin"}


def scan_block(h, finset):
    try:
        d = get("/cosmos/tx/v1beta1/txs?query=tx.height=%d&pagination.limit=100" % h)
    except Exception:
        return None
    res = {"h": h, "n_tx": len(d.get("txs", [])), "wasm": 0, "fin": [], "transfer": [], "range_any": 0}
    for tx in d.get("txs", []):
        body = tx.get("body", {})
        for m in body.get("messages", []):
            typ = m.get("@type", "")
            if typ.endswith("MsgExecuteContract"):
                res["wasm"] += 1
                contract = m.get("contract", "")
                raw = m.get("msg", "")
                try:
                    msg = json.loads(base64.b64decode(raw).decode())
                except Exception:
                    try:
                        msg = json.loads(raw) if isinstance(raw, str) else raw
                    except Exception:
                        msg = None
                sender = m.get("sender", "")
                if contract in finset and isinstance(msg, dict):
                    keys = list(msg.keys())
                    res["fin"].append({"contract": contract, "sender": sender, "keys": keys})
                    if "range" in msg:
                        res["range_any"] += 1
                        r = msg["range"]
                        if isinstance(r, dict) and "transfer" in r:
                            res["transfer"].append({"contract": contract, "sender": sender,
                                                    "to": r["transfer"].get("to")})
    return res


def main():
    lo, hi = int(sys.argv[1]), int(sys.argv[2])
    threads = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    finset = fin_addrs()
    heights = list(range(lo, hi + 1))
    agg = {"from": lo, "to": hi, "blocks": len(heights), "n_tx": 0, "wasm_exec": 0,
           "fin_range_msgs": 0, "range_transfer": [], "fin_senders": Counter(),
           "fin_msg_keys": Counter(), "blocks_with_fin": 0, "blocks_with_wasm": 0}
    with ThreadPoolExecutor(max_workers=threads) as ex:
        for r in ex.map(lambda h: scan_block(h, finset), heights):
            if not r:
                continue
            agg["n_tx"] += r["n_tx"]
            agg["wasm_exec"] += r["wasm"]
            if r["wasm"]:
                agg["blocks_with_wasm"] += 1
            if r["fin"]:
                agg["blocks_with_fin"] += 1
            agg["fin_range_msgs"] += r["range_any"]
            for f in r["fin"]:
                agg["fin_senders"][f["sender"]] += 1
                agg["fin_msg_keys"]["+".join(f["keys"])] += 1
            agg["range_transfer"] += r["transfer"]
    agg["fin_senders"] = dict(agg["fin_senders"].most_common(20))
    agg["fin_msg_keys"] = dict(agg["fin_msg_keys"].most_common(20))
    json.dump(agg, open(OUT, "w"), indent=1)
    print("window", lo, "-", hi, "blocks", len(heights))
    print("txs", agg["n_tx"], "wasm_exec", agg["wasm_exec"], "blocks_with_wasm", agg["blocks_with_wasm"])
    print("FIN range msgs", agg["fin_range_msgs"], "blocks_with_fin", agg["blocks_with_fin"])
    print("range.transfer events:", agg["range_transfer"] or "(none)")
    print("FIN msg keys:", agg["fin_msg_keys"])
    print("FIN top senders:", list(agg["fin_senders"].items())[:10])


if __name__ == "__main__":
    main()
