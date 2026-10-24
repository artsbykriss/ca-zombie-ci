#!/usr/bin/env python3
"""ZH4 incident subagent - read-only THORChain LCD scanner.

Scans a height window block-by-block and flags anything that could be the
2026-09-26 rujira-fin CCL position-transfer incident:
  * top-level wasm MsgExecuteContract whose target is a rujira-fin pair
  * ANY tx event whose type/attributes reference a rujira-fin pair address
  * ANY tx event whose type contains 'range' (rujira-fin/range.transfer etc.)
  * ANY event attribute key/value containing 'transfer' + a fin addr

No secrets, no transactions.  Public keyless endpoint only.

Usage: python3 find_incident.py <from> <to> [threads] [out.json]
"""
import base64, json, sys, urllib.request, urllib.parse
from concurrent.futures import ThreadPoolExecutor

BASE = "https://gateway.liquify.com/chain/thorchain_api"
UA = "Mozilla/5.0 (X11; Linux x86_64) read-only-research"

FIN_ADDRS = set()
try:
    with open("/home/heisenberg/CA/rujira-fin/analysis/fin_addrs.txt") as fh:
        for line in fh:
            line = line.strip()
            if line:
                FIN_ADDRS.add(line)
except Exception:
    pass


def get(path, tries=4, t=45):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
            return json.load(urllib.request.urlopen(req, timeout=t))
        except Exception as e:  # noqa: BLE001
            last = e
    raise last


def fetch_block(h):
    """Return (tx_responses, txs) for a height, following pagination."""
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


def decode_msg(m):
    raw = m.get("msg")
    if raw is None:
        return None
    if isinstance(raw, (dict, list)):
        return raw
    for dec in (lambda s: json.loads(base64.b64decode(s).decode()),
                lambda s: json.loads(s)):
        try:
            return dec(raw)
        except Exception:
            continue
    return raw


def scan_block(h):
    try:
        resp, txs = fetch_block(h)
    except Exception as e:  # noqa: BLE001
        return {"h": h, "error": str(e)[:120]}
    hits = []
    for r, tx in zip(resp, txs):
        hh = r.get("height", h)
        th = r.get("txhash", "?")
        memo = tx.get("body", {}).get("memo", "")
        msgs = tx.get("body", {}).get("messages", [])
        top = []
        for m in msgs:
            typ = m.get("@type", "")
            if typ.endswith("MsgExecuteContract"):
                dec = decode_msg(m)
                top.append({"type": typ, "sender": m.get("sender"),
                            "contract": m.get("contract"), "msg": dec})
        # --- events (this catches nested / sub-message activity) ---
        ev_hits = []
        for ev in r.get("events", []) or []:
            et = ev.get("type", "")
            attrs = {a.get("key"): a.get("value") for a in ev.get("attributes", [])}
            blob = et + " " + " ".join(str(v) for v in attrs.values())
            is_range = "range" in et or "range" in blob
            is_fin = any(a in blob for a in FIN_ADDRS)
            if is_range or is_fin:
                ev_hits.append({"type": et, "attrs": attrs})
        # --- flag ---
        interesting_top = [t for t in top if t["contract"] in FIN_ADDRS]
        if ev_hits or interesting_top:
            hits.append({"height": hh, "txhash": th, "memo": memo[:200],
                         "code": r.get("code"), "top_msgs": top,
                         "event_hits": ev_hits[:20]})
    return {"h": h, "hits": hits}


def main():
    lo, hi = int(sys.argv[1]), int(sys.argv[2])
    threads = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    out = sys.argv[4] if len(sys.argv) > 4 else "/tmp/opencode/incident_scan.json"
    print("fin addrs loaded:", len(FIN_ADDRS), flush=True)
    heights = list(range(lo, hi + 1))
    agg = {"from": lo, "to": hi, "hits": [], "errors": []}
    with ThreadPoolExecutor(max_workers=threads) as ex:
        for r in ex.map(scan_block, heights):
            if "error" in r:
                agg["errors"].append(r)
                print("ERR", r["h"], r["error"], flush=True)
                continue
            for hit in r["hits"]:
                agg["hits"].append(hit)
                print("HIT", hit["height"], hit["txhash"][:16], hit["memo"][:60],
                      "code=", hit["code"], flush=True)
    json.dump(agg, open(out, "w"), indent=1)
    print("DONE window", lo, "-", hi, "hits", len(agg["hits"]),
          "errors", len(agg["errors"]), "->", out, flush=True)


if __name__ == "__main__":
    main()
