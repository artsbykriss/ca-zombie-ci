#!/usr/bin/env python3
"""ZH4 incident subagent - read-only THORChain LCD scanner (v2, targeted).

Finds any tx in a height window whose EVENTS or top-level messages look like a
rujira-fin CCL range transfer / nested FIN call.  Prints a running log and
writes hits incrementally so a long scan is not lost.

No secrets, no transactions.

Usage: python3 find_incident2.py <from> <to> [threads] [out.json]
"""
import base64, json, sys, urllib.request, urllib.parse, threading
from concurrent.futures import ThreadPoolExecutor
from collections import Counter

BASE = "https://gateway.liquify.com/chain/thorchain_api"
UA = "Mozilla/5.0 (X11; Linux x86_64) read-only-research"

FIN_ADDRS = set()
with open("/home/heisenberg/CA/rujira-fin/analysis/fin_addrs.txt") as fh:
    for line in fh:
        line = line.strip()
        if line:
            FIN_ADDRS.add(line)

lock = threading.Lock()
HITS = []
TYPES = Counter()
ERRORS = []


def get(path, tries=5, t=45):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
            return json.load(urllib.request.urlopen(req, timeout=t))
        except Exception as e:  # noqa: BLE001
            last = e
    raise last


def fetch_block(h):
    out_resp, out_tx = [], []
    key = None
    while True:
        q = "/cosmos/tx/v1beta1/txs?" + urllib.parse.urlencode(
            {"query": "tx.height=%d" % h, "pagination.limit": 200,
             **({"pagination.key": key} if key else {})})
        d = get(q)
        out_resp += d.get("tx_responses", [])
        out_tx += d.get("txs", [])
        key = (d.get("pagination") or {}).get("next_key")
        if not key:
            break
    return out_resp, out_tx


def b64(s):
    try:
        return base64.b64decode(s).decode("utf-8", "replace")
    except Exception:
        return ""


def scan_block(h):
    try:
        resp, txs = fetch_block(h)
    except Exception as e:  # noqa: BLE001
        with lock:
            ERRORS.append({"h": h, "error": str(e)[:120]})
        return
    for r, tx in zip(resp, txs):
        th = r.get("txhash", "?")
        memo = tx.get("body", {}).get("memo", "")
        top = []
        for m in tx.get("body", {}).get("messages", []):
            typ = m.get("@type", "")
            if typ.endswith("MsgExecuteContract"):
                top.append({"type": typ, "sender": m.get("sender"),
                            "contract": m.get("contract"),
                            "msg_raw": m.get("msg")})
        ev_flags = []
        local_types = []
        for ev in r.get("events", []) or []:
            et = ev.get("type", "")
            local_types.append(et)
            attrs = {a.get("key"): a.get("value") for a in ev.get("attributes", [])}
            blob = et + " " + " ".join(str(v) for v in attrs.values())
            flag = None
            if "range." in et:
                flag = "range_event"
            elif et in ("execute", "instantiate", "wasm") and \
                    attrs.get("_contract_address") in FIN_ADDRS:
                dec = b64(attrs.get("msg", ""))
                if "range" in dec or "transfer" in dec:
                    flag = "fin_execute_msg"
            if flag:
                ev_flags.append({"flag": flag, "type": et, "attrs": attrs})
        top_fin = []
        for t in top:
            if t["contract"] in FIN_ADDRS:
                dec = b64(t.get("msg_raw") or "")
                t["msg_dec"] = dec[:600]
                if "range" in dec or "transfer" in dec:
                    top_fin.append(t)
        if ev_flags or top_fin:
            with lock:
                for t in local_types:
                    TYPES[t] += 1
                HITS.append({"height": r.get("height", h), "txhash": th,
                             "memo": memo[:200], "code": r.get("code"),
                             "top_fin": top_fin, "event_flags": ev_flags})
                print("HIT", r.get("height", h), th[:16], "flags=",
                      [f["flag"] + ":" + f["type"] for f in ev_flags],
                      "top_fin=", [t["contract"][:12] for t in top_fin],
                      "memo=", memo[:50], flush=True)


def main():
    lo, hi = int(sys.argv[1]), int(sys.argv[2])
    threads = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    out = sys.argv[4] if len(sys.argv) > 4 else "/tmp/opencode/incident_scan.json"
    print("fin addrs:", len(FIN_ADDRS), "window", lo, "-", hi, flush=True)
    heights = list(range(lo, hi + 1))
    with ThreadPoolExecutor(max_workers=threads) as ex:
        list(ex.map(scan_block, heights))
    json.dump({"from": lo, "to": hi, "hits": HITS, "errors": ERRORS,
               "event_types_seen": dict(TYPES.most_common(50))},
              open(out, "w"), indent=1)
    print("DONE", lo, "-", hi, "hits", len(HITS), "errors", len(ERRORS),
          "->", out, flush=True)


if __name__ == "__main__":
    main()
