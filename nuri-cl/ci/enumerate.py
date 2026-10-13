#!/usr/bin/env python3
"""Nuri CL (Scroll) — CI-side heavy enumeration (batch + retry, keyless public RPCs).

Read-only. No secrets. Falls back across public Scroll RPCs on 429/5xx.

Outputs (ci-out/):
  nfp_positions.json  - per-pool position census of the Nuri NFP manager.
  gauge_balances.json - NURI/WETH/USDC/USDT balances of all gauges.
  summary_enum.json   - totals.
"""
import json
import os
import threading
import time
import urllib.request
import urllib.error
import concurrent.futures

RPCS = [
    os.environ.get("SCROLL_RPC_URL") or "https://rpc.scroll.io",
    "https://scroll-rpc.publicnode.com",
    "https://scroll.drpc.org",
]
NFP = "0xAAA78E8C4241990B4ce159E105dA08129345946A"
VOTER = "0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869"
TOKENS = {
    "NURI": "0xAAAE8378809bb8815c08D3C59Eb0c7D1529aD769",
    "WETH": "0x5300000000000000000000000000000000000004",
    "USDC": "0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4",
    "USDT": "0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df",
}
_rpc_idx = [0]


def _post(url, payload):
    req = urllib.request.Request(
        url,
        json.dumps(payload).encode(),
        {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def rpc_batch(method, params_list, retries=6, workers=2, chunk=10):
    """JSON-RPC batch (chunks of `chunk`), small worker pool, rotating public RPCs on failure."""
    if not params_list:
        return []
    chunks = [params_list[i : i + chunk] for i in range(0, len(params_list), chunk)]
    results = [None] * len(chunks)
    lock = threading.Lock()

    def _attempt(part):
        payload = [
            {"jsonrpc": "2.0", "id": i, "method": method, "params": p}
            for i, p in enumerate(part)
        ]
        with lock:
            url = RPCS[_rpc_idx[0] % len(RPCS)]
        res = _post(url, payload)
        if not isinstance(res, list):
            raise ValueError(f"non-list batch response: {str(res)[:120]}")
        by_id = {r.get("id"): r for r in res if isinstance(r, dict)}
        got = [by_id.get(i, {}).get("result") for i in range(len(part))]
        if any(g is None for g in got):
            errs = [r for r in res if isinstance(r, dict) and r.get("error")]
            raise ValueError(f"missing batch results: {str(errs)[:160]}")
        return got

    def work(ci):
        part = chunks[ci]
        for attempt in range(retries):
            try:
                results[ci] = _attempt(part)
                return
            except Exception:  # 429 / 5xx / network / bad response
                with lock:
                    _rpc_idx[0] += 1
                time.sleep(1.0 * (attempt + 1))
        # last resort: single-call fallback for this chunk
        got = []
        for p in part:
            for attempt in range(retries):
                try:
                    got.append(_attempt([p])[0])
                    break
                except Exception:
                    with lock:
                        _rpc_idx[0] += 1
                    time.sleep(1.0 * (attempt + 1))
            else:
                got.append(None)
        results[ci] = got

    with concurrent.futures.ThreadPoolExecutor(workers) as ex:
        list(ex.map(work, range(len(chunks))))
    out = []
    for r in results:
        out.extend(r)
    return out


def call_batch(to, datas):
    return rpc_batch("eth_call", [[{"to": to, "data": d}, "latest"] for d in datas])


def words(hexstr):
    h = (hexstr or "0x")[2:]
    return [h[i : i + 64] for i in range(0, len(h), 64)]


def addr(w):
    return "0x" + w[-40:]


def main():
    os.makedirs("ci-out", exist_ok=True)
    bn = int(rpc_batch("eth_blockNumber", [[]])[0], 16)
    total = int(call_batch(NFP, ["0x18160ddd"])[0], 16)  # totalSupply()
    print(f"block={bn} nfp_totalSupply={total}", flush=True)

    # stratified sample (public-RPC friendly): first 300, last 300, plus 200 deterministic middles
    sample_idx = list(range(min(300, total))) + list(range(max(0, total - 300), total))
    step = max(1, (total - 600) // 200)
    sample_idx += list(range(300, max(300, total - 300), step))[:200]
    sample_idx = sorted(set(sample_idx))
    cap = int(os.environ.get("NURI_SAMPLE_MAX", "0") or 0)
    if cap and len(sample_idx) > cap:
        sample_idx = sample_idx[: cap // 2] + sample_idx[-(cap // 2) :]
    print(f"sampling {len(sample_idx)} of {total} token indexes", flush=True)

    ids_raw = call_batch(NFP, ["0x4f6ccce7" + hex(i)[2:].zfill(64) for i in sample_idx])
    ids = [int(x, 16) for x in ids_raw if x]
    print(f"token ids read: {len(ids)}", flush=True)

    pos_raw = call_batch(NFP, ["0x99fbab88" + hex(t)[2:].zfill(64) for t in ids])
    pos = []
    for t, r in zip(ids, pos_raw):
        if not r:
            continue
        w = words(r)
        if len(w) < 12:
            continue
        try:
            pos.append(
                {
                    "tokenId": t,
                    "t0": addr(w[2]),
                    "t1": addr(w[3]),
                    "fee": int(w[4], 16),
                    "tickLower": int(w[5], 16),
                    "tickUpper": int(w[6], 16),
                    "liquidity": int(w[7], 16),
                    "owed0": int(w[10], 16),
                    "owed1": int(w[11], 16),
                }
            )
        except Exception:
            continue
    print(f"positions parsed: {len(pos)}", flush=True)

    by_pool = {}
    for p in pos:
        key = f"{p['t0']}|{p['t1']}|{p['fee']}"
        d = by_pool.setdefault(key, {"count": 0, "liquidity": 0, "owed0": 0, "owed1": 0, "sample": []})
        d["count"] += 1
        d["liquidity"] += p["liquidity"]
        d["owed0"] += p["owed0"]
        d["owed1"] += p["owed1"]
    # owners for the top-liquidity positions (batch ownerOf)
    flat = sorted(pos, key=lambda x: -x["liquidity"])[:40]
    own_raw = call_batch(NFP, ["0x6352211e" + hex(p["tokenId"])[2:].zfill(64) for p in flat])
    owners = {}
    for p, r in zip(flat, own_raw):
        if r and len(r) >= 42:
            owners[p["tokenId"]] = addr(words(r)[0])
    for p in flat:
        key = f"{p['t0']}|{p['t1']}|{p['fee']}"
        d = by_pool[key]
        if len(d["sample"]) < 6:
            d["sample"].append(
                {"tokenId": p["tokenId"], "liquidity": p["liquidity"], "owner": owners.get(p["tokenId"])}
            )

    n = int(call_batch(VOTER, ["0x1f7b6d32"])[0], 16)  # length()
    pools_raw = call_batch(VOTER, ["0xac4afa38" + hex(i)[2:].zfill(64) for i in range(n)])
    pools = [addr(words(r)[0]) for r in pools_raw if r]
    gauges_raw = call_batch(VOTER, ["0xb9a09fd5" + p[2:].rjust(64, "0") for p in pools])
    gauges = [addr(words(r)[0]) for r in gauges_raw if r]
    alive_raw = call_batch(VOTER, ["0x1703e5f9" + g[2:].rjust(64, "0") for g in gauges])
    rows = []
    for p, g, a in zip(pools, gauges, alive_raw):
        rows.append({"pool": p, "gauge": g, "alive": bool(a) and int(a, 16) == 1})
    for name, tok in TOKENS.items():
        bals = call_batch(tok, ["0x70a08231" + r["gauge"][2:].rjust(64, "0") for r in rows])
        for r, b in zip(rows, bals):
            r[name] = int(b, 16) if b else None

    out = {
        "block": bn,
        "nfp_totalSupply": total,
        "positions_read": len(pos),
        "pools": by_pool,
        "gauges": rows,
        "gauge_nuri_total": sum(r.get("NURI") or 0 for r in rows),
    }
    json.dump(out, open("ci-out/nfp_positions.json", "w"), indent=1)
    json.dump(rows, open("ci-out/gauge_balances.json", "w"), indent=1)
    json.dump(
        {
            "block": bn,
            "nfp_totalSupply": total,
            "positions_read": len(pos),
            "gauge_nuri_total": out["gauge_nuri_total"],
            "pools_top": sorted(
                [{"key": k, **{kk: vv for kk, vv in v.items() if kk != "sample"}} for k, v in by_pool.items()],
                key=lambda x: -x["liquidity"],
            )[:10],
        },
        open("ci-out/summary_enum.json", "w"),
        indent=1,
    )
    print("done", flush=True)


if __name__ == "__main__":
    main()
