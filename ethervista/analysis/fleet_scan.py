#!/usr/bin/env python3
"""
EtherVista fleet scan — Z3-C5 deep-dive (read-only).

Enumerates ALL pairs of the EtherVista factory, reads live state for each at one
pinned block, and computes:
  * code identity (sha256 of runtime code; no keccak needed for grouping)
  * pair.factory() binding (must equal the canonical factory)
  * balances vs reserves  -> skim()-able excess (permissionless E-U if > 0)
  * uint112 K-wrap status (r0*r1 > 2^112)  -> one-call hostile-router drain
  * per-pair USD value and one-call drain value (needs token prices)

Outputs (to --outdir, default ../ci-out):
  fleet_scan.json     full per-pair data
  pairs.csv           the 1,087-pair table
  fleet_summary.json  aggregates used in the report

NO secrets: uses public RPCs / env RPC URLs (never printed). Read-only eth_calls.
"""
import json
import os
import sys
import time
import urllib.request
import hashlib
from math import isqrt

FACTORY = "0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4"
PAIR_TARGET = "0xfdd05552F1377aA488AFed744c8024358AF02041"
WETH = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

# --- function selectors (computed with `cast sig`) ---
SEL = {
    "allPairsLength": "0x574f2ba3",
    "allPairs": "0x1e3dd18b",
    "router": "0xf887ea40",
    "routerSetter": "0x461142c3",
    "feeTo": "0x017e7e58",
    "feeToSetter": "0x094b7415",
    "initCodeHash": "0x257671f5",
    "factory": "0xc45a0155",
    "token0": "0x0dfe1681",
    "token1": "0xd21220a7",
    "getReserves": "0x0902f1ac",
    "totalSupply": "0x18160ddd",
    "poolBalance": "0x96365d44",
    "balanceOf": "0x70a08231",
    "creator": "0x02d05d3f",
    "kLast": "0x7464fc3d",
}

RPC_CANDIDATES = [
    os.environ.get("FORK_RPC_URL", ""),
    os.environ.get("RPC_URL", ""),
    "https://ethereum-rpc.publicnode.com",
    "https://eth.drpc.org",
    "https://1rpc.io/eth",
]
RPC_CANDIDATES = [u for u in RPC_CANDIDATES if u]

UA = {"User-Agent": "zombie-research/1.0"}


def http_json(url, payload, timeout=120):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers={**UA, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())


def http_get(url, timeout=120):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode()


class Rpc:
    def __init__(self):
        self.url = None
        self._id = 0
        for u in RPC_CANDIDATES:
            try:
                res = http_json(u, {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}, timeout=20)
                if "result" in res:
                    self.url = u
                    self.block = int(res["result"], 16)
                    print(f"[rpc] using provider (host hidden), block={self.block}", flush=True)
                    return
            except Exception as e:  # noqa
                print(f"[rpc] candidate failed: {type(e).__name__}", flush=True)
        raise RuntimeError("no working RPC")

    def call(self, method, params):
        for attempt in range(4):
            try:
                self._id += 1
                res = http_json(self.url, {"jsonrpc": "2.0", "id": self._id, "method": method, "params": params})
                if "result" in res:
                    return res["result"]
                if "error" in res:
                    raise RuntimeError(str(res["error"])[:200])
            except Exception as e:
                if attempt == 3:
                    raise
                time.sleep(1.5 * (attempt + 1))

    def batch(self, calls):
        """calls: list of (method, params). returns list of results (None on error)."""
        out = []
        for i in range(0, len(calls), 100):
            chunk = calls[i:i + 100]
            payload = []
            for j, (m, p) in enumerate(chunk):
                self._id += 1
                payload.append({"jsonrpc": "2.0", "id": self._id, "method": m, "params": p})
            res = None
            for attempt in range(4):
                try:
                    res = http_json(self.url, payload, timeout=180)
                    break
                except Exception:
                    time.sleep(2 * (attempt + 1))
            if res is None:
                raise RuntimeError("batch failed")
            byid = {r.get("id"): r for r in res} if isinstance(res, list) else {}
            for j, (m, p) in enumerate(chunk):
                rid = payload[j]["id"]
                r = byid.get(rid, {})
                out.append(r.get("result"))
            print(f"[rpc] batch {i+len(chunk)}/{len(calls)}", flush=True)
        return out


def pad_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def u256(h):
    if h is None:
        return None
    if isinstance(h, str) and h.startswith("0x"):
        h = h[2:]
    return int(h, 16) if h else 0


def addr(h):
    if not h or h == "0x":
        return None
    return "0x" + h[-40:].lower()


def dec_u256(h):
    v = u256(h)
    return None if v is None else v


def min_residue(Kwrap, r0, r1, P0, P1):
    """Min USD value of (b0,b1) s.t. b0*b1 >= Kwrap, 1<=b0<=r0, 1<=b1<=r1.
    Returns (b0, b1, residue_usd) or None if infeasible."""
    if Kwrap <= 0:
        return (1, 1, (P0 + P1) / 1e18 if P0 is not None else None)
    cands = set()

    def add(b0):
        b0 = max(1, min(b0, r0))
        b1 = -(-Kwrap // b0)  # ceil
        if b1 <= r1:
            cands.add((b0, b1))

    # interior estimate b0* = sqrt(Kwrap * P1 / P0) (fall back to sqrt(Kwrap))
    if P0 and P1 and P0 > 0 and P1 > 0:
        est = isqrt(int(Kwrap * P1 / P0)) if Kwrap * P1 / P0 < 2**200 else isqrt(Kwrap)
    else:
        est = isqrt(Kwrap)
    for d in range(-3, 4):
        add(est + d)
    add(1)
    add(r0)                      # corner: take nothing of token0
    add(-(-Kwrap // r1))         # corner: b1 = r1
    add(isqrt(Kwrap))
    best = None
    for (b0, b1) in cands:
        if b0 * b1 < Kwrap:
            continue
        if P0 is None or P1 is None:
            res_usd = None
        else:
            res_usd = (b0 / 1e18) * P0 + (b1 / 1e18) * P1
        if best is None or (res_usd is not None and res_usd < best[2]):
            best = (b0, b1, res_usd)
    return best


def main():
    outdir = os.environ.get("OUTDIR", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out"))
    outdir = os.path.abspath(outdir)
    os.makedirs(outdir, exist_ok=True)

    rpc = Rpc()
    block = rpc.block

    # ---- factory-level state ----
    fac_calls = [
        ("eth_call", [{"to": FACTORY, "data": SEL["allPairsLength"]}, "latest"]),
        ("eth_call", [{"to": FACTORY, "data": SEL["router"]}, "latest"]),
        ("eth_call", [{"to": FACTORY, "data": SEL["routerSetter"]}, "latest"]),
        ("eth_call", [{"to": FACTORY, "data": SEL["feeTo"]}, "latest"]),
        ("eth_call", [{"to": FACTORY, "data": SEL["feeToSetter"]}, "latest"]),
        ("eth_call", [{"to": FACTORY, "data": SEL["initCodeHash"]}, "latest"]),
        ("eth_getCode", [FACTORY, "latest"]),
    ]
    fac_res = rpc.batch(fac_calls)
    n_pairs = u256(fac_res[0])
    factory_router = addr(fac_res[1])
    factory_routerSetter = addr(fac_res[2])
    feeTo = addr(fac_res[3])
    feeToSetter = addr(fac_res[4])
    init_code_hash = fac_res[5]
    factory_code = fac_res[6] or "0x"
    print(f"[fleet] allPairsLength={n_pairs} router={factory_router} routerSetter={factory_routerSetter}", flush=True)

    # ---- enumerate pairs ----
    calls = [("eth_call", [{"to": FACTORY, "data": SEL["allPairs"] + pad_addr(hex(i)[2:])}, "latest"]) for i in range(n_pairs)]
    res = rpc.batch(calls)
    pairs = [addr(r) for r in res]
    assert len(pairs) == n_pairs, "pair enumeration length mismatch"
    assert all(pairs), "null pair address"
    print(f"[fleet] enumerated {len(pairs)} pairs, unique={len(set(pairs))}", flush=True)

    # ---- per-pair reads ----
    per = {}
    calls = []
    for p in pairs:
        calls += [
            ("eth_call", [{"to": p, "data": SEL["factory"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["token0"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["token1"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["getReserves"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["totalSupply"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["poolBalance"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["creator"]}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["kLast"]}, "latest"]),
        ]
    res = rpc.batch(calls)
    k = 0
    for i, p in enumerate(pairs):
        per[p] = {
            "idx": i,
            "pair": p,
            "factory": addr(res[k + 0]),
            "token0": addr(res[k + 1]),
            "token1": addr(res[k + 2]),
            "reserves": res[k + 3],
            "totalSupply": dec_u256(res[k + 4]),
            "poolBalance": dec_u256(res[k + 5]),
            "creator": addr(res[k + 6]),
            "kLast": dec_u256(res[k + 7]),
        }
        k += 8

    # token balances of each pair (needs token addresses -> second batch)
    calls = []
    for p in pairs:
        d = per[p]
        calls += [
            ("eth_call", [{"to": d["token0"], "data": SEL["balanceOf"] + pad_addr(p[2:])}, "latest"]),
            ("eth_call", [{"to": d["token1"], "data": SEL["balanceOf"] + pad_addr(p[2:])}, "latest"]),
            ("eth_call", [{"to": p, "data": SEL["balanceOf"] + pad_addr(p[2:])}, "latest"]),  # self LP
        ]
    res = rpc.batch(calls)
    k = 0
    for p in pairs:
        d = per[p]
        d["bal0"] = dec_u256(res[k + 0])
        d["bal1"] = dec_u256(res[k + 1])
        d["selfLP"] = dec_u256(res[k + 2])
        k += 3

    # ---- code identity (sha256 grouping; batch of 20 to bound response size) ----
    code_groups = {}
    for i in range(0, len(pairs), 20):
        chunk = pairs[i:i + 20]
        calls = [("eth_getCode", [p, "latest"]) for p in chunk]
        res = rpc.batch(calls)
        for p, c in zip(chunk, res):
            c = c or "0x"
            h = hashlib.sha256(c.encode()).hexdigest()
            per[p]["code_sha256"] = h
            per[p]["code_len"] = (len(c) - 2) // 2
            code_groups.setdefault(h, []).append(p)
        print(f"[fleet] code {min(i+20, len(pairs))}/{len(pairs)}", flush=True)

    # ---- prices (DefiLlama, public) ----
    tokens = sorted({per[p]["token0"] for p in pairs} | {per[p]["token1"] for p in pairs})
    prices = {}
    for i in range(0, len(tokens), 50):
        chunk = tokens[i:i + 50]
        url = "https://coins.llama.fi/prices/current/" + ",".join("ethereum:" + t for t in chunk)
        try:
            j = json.loads(http_get(url))
            for kk, v in (j.get("coins") or {}).items():
                a = kk.split(":")[-1].lower()
                prices[a] = v.get("price")
        except Exception as e:
            print(f"[price] chunk failed: {type(e).__name__}", flush=True)
        time.sleep(0.3)
    print(f"[price] priced {len(prices)}/{len(tokens)} unique tokens", flush=True)

    # ---- compute per-pair metrics ----
    TWO112 = 2 ** 112
    rows = []
    total_value = 0.0
    total_value_unpriced = 0
    total_excess_usd = 0.0
    total_excess_unpriced = 0
    total_drain_usd = 0.0
    drain_unpriced = 0
    n_overflow = 0
    n_excess = 0
    n_self_lp = 0
    n_factory_mismatch = 0
    weth_price = prices.get(WETH)

    for p in pairs:
        d = per[p]
        r = d["reserves"]
        if r and len(r) >= 2 + 2:
            r0 = u256(r[2:66]) if r.startswith("0x") else None
            r1 = u256(r[66:130]) if r.startswith("0x") else None
        else:
            r0 = r1 = 0
        r0 = r0 or 0
        r1 = r1 or 0
        b0 = d["bal0"] or 0
        b1 = d["bal1"] or 0
        P0 = prices.get(d["token0"])
        P1 = prices.get(d["token1"])
        excess0 = max(0, b0 - r0)
        excess1 = max(0, b1 - r1)
        overflow = (r0 * r1) > TWO112
        if overflow:
            n_overflow += 1
        if excess0 > 0 or excess1 > 0:
            n_excess += 1
        if (d["selfLP"] or 0) > 0:
            n_self_lp += 1
        if d["factory"] != FACTORY:
            n_factory_mismatch += 1

        if P0 is not None and P1 is not None:
            value_usd = (b0 / 1e18) * P0 + (b1 / 1e18) * P1
            total_value += value_usd
            ex_usd = (excess0 / 1e18) * P0 + (excess1 / 1e18) * P1
            total_excess_usd += ex_usd
        else:
            value_usd = None
            ex_usd = None
            total_value_unpriced += 1
            if excess0 > 0 or excess1 > 0:
                total_excess_unpriced += 1

        drain_usd = 0.0
        if overflow and P0 is not None and P1 is not None:
            Kwrap = (r0 * r1) % TWO112
            mr = min_residue(Kwrap, b0, b1, P0, P1)
            if mr is not None:
                drain_usd = value_usd - mr[2]
                total_drain_usd += drain_usd
            else:
                drain_unpriced += 1
        elif overflow:
            drain_unpriced += 1

        rows.append({
            "idx": d["idx"], "pair": p, "token0": d["token0"], "token1": d["token1"],
            "r0": r0, "r1": r1, "b0": b0, "b1": b1,
            "excess0": excess0, "excess1": excess1,
            "totalSupply": d["totalSupply"], "selfLP": d["selfLP"],
            "poolBalance": d["poolBalance"], "creator": d["creator"],
            "overflow": overflow, "value_usd": value_usd, "drain_usd": drain_usd,
            "code_sha256": d["code_sha256"], "code_len": d["code_len"],
            "factory_ok": (d["factory"] or "").lower() == FACTORY.lower(),
        })

    rows.sort(key=lambda x: -(x["value_usd"] or 0))

    # ---- WETH-side aggregates (hard floor in ETH terms; no price needed) ----
    WETH_L = WETH.lower()
    weth_total = 0
    weth_overflow = 0
    weth_pairs = 0
    weth_max_drain = 0
    for x in rows:
        if x["token0"] == WETH_L:
            w = x["b0"]
        elif x["token1"] == WETH_L:
            w = x["b1"]
        else:
            continue
        weth_pairs += 1
        weth_total += w
        if x["overflow"]:
            weth_overflow += w
            # WETH-maximising one-call drain: keep the other side at its reserve,
            # shrink the WETH side to ceil(Kwrap / other_reserve).
            r0, r1 = x["r0"], x["r1"]
            if x["token0"] == WETH_L:
                b0 = -(-((r0 * r1) % TWO112) // r1) if r1 > 0 else r0
                weth_max_drain += max(0, r0 - b0)
            else:
                b1 = -(-((r0 * r1) % TWO112) // r0) if r0 > 0 else r1
                weth_max_drain += max(0, r1 - b1)
    target_weth = None
    for x in rows:
        if x["pair"] == PAIR_TARGET.lower():
            target_weth = x["b0"] if x["token0"] == WETH_L else x["b1"]

    # ---- best-strategy fleet latent (max of balanced-USD and WETH-max per pair) ----
    best_strategy_usd = 0.0
    for x in rows:
        if not x["overflow"]:
            continue
        r0, r1 = x["r0"], x["r1"]
        K = (r0 * r1) % TWO112
        if x["token0"] == WETH_L:
            b0 = -(-K // r1) if r1 else r0
            wm_usd = max(0, r0 - b0) / 1e18 * weth_price if weth_price else 0
        else:
            b1 = -(-K // r0) if r0 else r1
            wm_usd = max(0, r1 - b1) / 1e18 * weth_price if weth_price else 0
        bal = x["drain_usd"] or 0
        best_strategy_usd += max(wm_usd, bal)

    # ---- summary ----
    target = next((x for x in rows if x["pair"] == PAIR_TARGET.lower()), None)
    summary = {
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "block": block,
        "factory": FACTORY,
        "factory_router": factory_router,
        "factory_routerSetter": factory_routerSetter,
        "factory_feeTo": feeTo,
        "factory_feeToSetter": feeToSetter,
        "factory_init_code_hash": init_code_hash,
        "factory_code_len": (len(factory_code) - 2) // 2,
        "pairs": len(pairs),
        "unique_pairs": len(set(pairs)),
        "distinct_pair_codes": len(code_groups),
        "code_group_sizes": sorted([len(v) for v in code_groups.values()], reverse=True)[:10],
        "factory_mismatch": n_factory_mismatch,
        "pairs_with_k_overflow": n_overflow,
        "pairs_with_skim_excess": n_excess,
        "pairs_with_self_lp": n_self_lp,
        "total_value_usd_priced": round(total_value, 2),
        "pairs_unpriced": total_value_unpriced,
        "total_skim_excess_usd": round(total_excess_usd, 2),
        "pairs_with_excess_unpriced": total_excess_unpriced,
        "total_one_call_drain_usd": round(total_drain_usd, 2),
        "pairs_overflow_unpriced": drain_unpriced,
        "weth_price_usd": weth_price,
        "weth_pairs": weth_pairs,
        "weth_held_all_pairs_wei": weth_total,
        "weth_held_overflow_pairs_wei": weth_overflow,
        "weth_held_target_pair_wei": target_weth,
        "weth_held_all_pairs_usd": round(weth_total / 1e18 * weth_price, 2) if weth_price else None,
        "weth_held_overflow_pairs_usd": round(weth_overflow / 1e18 * weth_price, 2) if weth_price else None,
        "weth_max_drain_overflow_pairs_wei": weth_max_drain,
        "weth_max_drain_overflow_pairs_usd": round(weth_max_drain / 1e18 * weth_price, 2) if weth_price else None,
        "fleet_best_strategy_latent_usd": round(best_strategy_usd, 2),
        "top20_by_value": [
            {k: x[k] for k in ("idx", "pair", "token0", "token1", "value_usd", "drain_usd", "overflow", "excess0", "excess1")}
            for x in rows[:20]
        ],
        "target_pair": target,
    }

    with open(os.path.join(outdir, "fleet_scan.json"), "w") as f:
        json.dump({"block": block, "pairs": rows}, f)
    with open(os.path.join(outdir, "fleet_summary.json"), "w") as f:
        json.dump(summary, f, indent=2)

    cols = ["idx", "pair", "token0", "token1", "r0", "r1", "b0", "b1", "excess0", "excess1",
            "totalSupply", "selfLP", "poolBalance", "creator", "overflow", "value_usd",
            "drain_usd", "code_sha256", "code_len", "factory_ok"]
    with open(os.path.join(outdir, "pairs.csv"), "w") as f:
        f.write(",".join(cols) + "\n")
        for x in rows:
            f.write(",".join(str(x[c]) for c in cols) + "\n")

    # ---- Etherscan PairCreated log cross-check (optional) ----
    key = os.environ.get("ETHERSCANV2_API_KEY", "")
    if key:
        try:
            cnt = 0
            first_block = None
            last_block = None
            for page in (1, 2):
                url = (f"https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs"
                       f"&fromBlock=20000000&toBlock=latest&address={FACTORY}"
                       f"&topic0=0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9"
                       f"&page={page}&offset=1000&apikey={key}")
                j = json.loads(http_get(url))
                rs = j.get("result") or []
                if not isinstance(rs, list):
                    break
                cnt += len(rs)
                for e in rs:
                    b = int(e["blockNumber"], 16)
                    first_block = b if first_block is None else min(first_block, b)
                    last_block = b if last_block is None else max(last_block, b)
                if len(rs) < 1000:
                    break
            summary["paircreated_events"] = cnt
            summary["paircreated_first_block"] = first_block
            summary["paircreated_last_block"] = last_block
            with open(os.path.join(outdir, "fleet_summary.json"), "w") as f:
                json.dump(summary, f, indent=2)
            print(f"[fleet] PairCreated events: {cnt} (blocks {first_block}..{last_block})", flush=True)
        except Exception as e:
            print(f"[fleet] PairCreated cross-check failed: {type(e).__name__}", flush=True)

    print(json.dumps({k: summary[k] for k in ("pairs", "distinct_pair_codes", "factory_mismatch",
                                              "pairs_with_k_overflow", "pairs_with_skim_excess",
                                              "pairs_with_self_lp", "total_value_usd_priced",
                                              "total_skim_excess_usd", "total_one_call_drain_usd",
                                              "weth_held_overflow_pairs_wei", "weth_max_drain_overflow_pairs_wei",
                                              "weth_max_drain_overflow_pairs_usd",
                                              "fleet_best_strategy_latent_usd")}, indent=2), flush=True)
    print(f"[fleet] wrote {outdir}/fleet_scan.json, pairs.csv, fleet_summary.json", flush=True)


if __name__ == "__main__":
    main()
