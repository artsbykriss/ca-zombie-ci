#!/usr/bin/env python3
"""LeetSwap deep-dive scanner (read-only) — runs in CI.

For each chain/factory:
  * enumerate all pairs
  * per pair: variant probe (LeetSwapV2Pair vs UniV2), token0/1, reserves, balances,
    LP totalSupply, factory, excess (skim-able), vulnerable-function presence
  * per factory: isPaused / protocolFees* / feeTo / owner / pauser / pairCodeHash
  * per counterpart token: symbol/decimals/totalSupply/owner()/mint-probe
Output: ci-out/vuln-scan.json  (+ summary CSV)
Only eth_call/eth_blockNumber/eth_getCode — no tx, no secrets.
"""
import json, os, sys, time, urllib.request, socket, csv
from concurrent.futures import ThreadPoolExecutor, as_completed

# IPv4 preference (public endpoints resolve IPv6-first in some environments)
_orig_gai = socket.getaddrinfo
def _gai4(host, port, family=0, type=0, proto=0, flags=0):
    try:
        res = _orig_gai(host, port, socket.AF_INET, type, proto, flags)
        if res: return res
    except Exception: pass
    return _orig_gai(host, port, family, type, proto, flags)
socket.getaddrinfo = _gai4

RPCS = {
    "op_bnb": ["https://opbnb.publicnode.com", "https://opbnb-mainnet-rpc.bnbchain.org",
               "https://opbnb.drpc.org", "https://1rpc.io/opbnb"],
    "manta": ["https://pacific-rpc.manta.network/http", "https://manta-pacific.drpc.org",
              "https://1rpc.io/manta"],
    "scroll": ["https://rpc.scroll.io", "https://scroll.drpc.org", "https://1rpc.io/scroll"],
    "linea": ["https://rpc.linea.build", "https://linea.drpc.org", "https://1rpc.io/linea"],
    "polygon_zkevm": ["https://zkevm-rpc.com", "https://polygon-zkevm.drpc.org",
                      "https://1rpc.io/polygon-zkevm"],
    "shibarium": ["https://rpc.shibarium.shib.io", "https://shibarium.drpc.org"],
    "canto": ["https://canto.gravitychain.io", "https://canto-rpc.publicnode.com"],
    "base": ["https://mainnet.base.org", "https://base.publicnode.com", "https://base.drpc.org"],
}

FACTORIES = {
    "op_bnb": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
    "manta": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
    "scroll": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
    "linea": "0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c",
    "polygon_zkevm": "0xcE87E0960f4e2702f4bFFE277655E993Ae720e84",
    "shibarium": "0xd3Ea3BC1F5A3F881bD6cE9761cbA5A0833a5d737",
    "canto": "0x116e8a41E8B0A5A87058AF110C0Ddd55a0ed82B7",
    "base": "0x169C06b4cfB09bFD73A81e6f2Bb1eB514D75bB19",
}

SEL = {
    "allPairsLength": "0x574f2ba3",
    "allPairs": "0x1e3dd18b",
    "token0": "0x0dfe1681", "token1": "0xd21220a7",
    "getReserves": "0x0902f1ac",
    "totalSupply": "0x18160ddd",
    "balanceOf": "0x70a08231",
    "decimals": "0x313ce567", "symbol": "0x95d89b41", "name": "0x06fdde03",
    "factory": "0xc45a0155",
    "isPaused": "0xb187bd26", "pauser": "0x9fd0506d",
    "protocolFeesShare": "0xafda13e9", "protocolFeesRecipient": "0x68930637",
    "tradingFees": "0x5cf73108", "feeTo": "0x017e7e58", "owner": "0x8da5cb5b",
    "paused": "0x5c975abb", "pairCodeHash": "0xdc4c90d3",
    "stable": "0x22be3de1", "fees": "0x9af1d35a", "kLast": "0x7464fc3d",
    "MINIMUM_LIQUIDITY": "0xba9a7a56",
    "TF": "0xec7e683d",   # _transferFeesSupportingTaxTokens(address,uint256)
    "skim": "0xbc25cf77", "sync": "0xfff6cae9",
    "mint1": "0x6a627842", "burn1": "0x89afcb44", "swap4": "0x022c0d9f",
}

NULL64 = "0x" + "0" * 64
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT, exist_ok=True)


class Rpc:
    def __init__(self, chain):
        self.chain = chain
        self.urls = RPCS[chain]
        self.url_i = 0
        self.block = None

    def _post(self, payload, url, timeout=60):
        req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                     headers={"Content-Type": "application/json",
                                              "User-Agent": "Mozilla/5.0 (research; read-only)"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode())

    def batch(self, calls, tries=4):
        """Batch with chunking (public RPCs cap batch size) + per-chunk retry."""
        out = [None] * len(calls)
        CHUNK = 40
        for start in range(0, len(calls), CHUNK):
            chunk = calls[start:start + CHUNK]
            payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
                       for i, (m, p) in enumerate(chunk)]
            got = False
            last = None
            for _ in range(tries):
                url = self.urls[self.url_i % len(self.urls)]
                self.url_i += 1
                try:
                    d = self._post(payload, url)
                    if isinstance(d, dict):
                        d = [d]
                    by = {x.get("id"): x for x in d}
                    for i in range(len(chunk)):
                        out[start + i] = by.get(i, {}).get("result")
                    got = True
                    break
                except Exception as e:
                    last = e
                    time.sleep(0.4)
            if not got:
                # one more try per-call (slow path) to avoid losing data
                for i, (m, p) in enumerate(chunk):
                    for _ in range(2):
                        try:
                            d = self._post({"jsonrpc": "2.0", "id": 0, "method": m, "params": p},
                                           self.urls[self.url_i % len(self.urls)])
                            out[start + i] = d.get("result")
                            break
                        except Exception as e:
                            last = e
                            self.url_i += 1
                            time.sleep(0.3)
        return out

    def block_number(self):
        if self.block is None:
            for u in self.urls:
                try:
                    d = self._post({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}, u)
                    self.block = int(d["result"], 16)
                    return self.block
                except Exception:
                    continue
            raise RuntimeError("no block")
        return self.block


def words(h):
    h = h[2:] if h.startswith("0x") else h
    return [h[i:i + 64] for i in range(0, len(h) - 63, 64)]


def dec_addr(w): return "0x" + w[-40:]
def dec_uint(w): return int(w, 16)


def dec_str(raw):
    try:
        ws = words(raw); off = dec_uint(ws[0]); ln = dec_uint(ws[off // 32])
        return bytes.fromhex(raw[2 + off * 2:2 + off * 2 + ln * 2]).decode("utf-8", "replace")
    except Exception:
        try:
            return bytes.fromhex(raw[2:].rstrip("0")).decode("utf-8", "replace")
        except Exception:
            return "?"


def pad_addr(a): return a.lower().replace("0x", "").rjust(64, "0")
def pad_uint(n): return hex(int(n))[2:].rjust(64, "0")


def call_ok(r):
    return r is not None and r != "0x"


def scan_chain(chain, max_pairs=250, focus_pairs=None):
    rpc = Rpc(chain)
    f = FACTORIES[chain]
    res = {"chain": chain, "factory": f}
    blk = rpc.block_number()
    res["block"] = blk
    print(f"[{chain}] block {blk}", flush=True)
    # factory reads
    fcalls = [
        ("eth_call", [{"to": f, "data": SEL["allPairsLength"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["isPaused"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["protocolFeesShare"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["protocolFeesRecipient"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["feeTo"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["owner"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["pauser"]}, "latest"]),
        ("eth_call", [{"to": f, "data": SEL["pairCodeHash"]}, "latest"]),
        ("eth_getCode", [f, "latest"]),
    ]
    r = rpc.batch(fcalls)
    res["factory_code_size"] = len(r[8] or "0x") // 2 if r[8] else 0
    res["allPairsLength"] = dec_uint(words(r[0])[0]) if call_ok(r[0]) else None
    res["isPaused"] = bool(dec_uint(words(r[1])[0])) if call_ok(r[1]) else None
    res["protocolFeesShare"] = dec_uint(words(r[2])[0]) if call_ok(r[2]) else None
    res["protocolFeesRecipient"] = dec_addr(words(r[3])[0]) if call_ok(r[3]) else None
    res["feeTo"] = dec_addr(words(r[4])[0]) if call_ok(r[4]) else None
    res["owner"] = dec_addr(words(r[5])[0]) if call_ok(r[5]) else None
    res["pauser"] = dec_addr(words(r[6])[0]) if call_ok(r[6]) else None
    res["pairCodeHash"] = r[7] if call_ok(r[7]) else None
    n = res["allPairsLength"] or 0
    print(f"[{chain}] allPairs={n} isPaused={res['isPaused']} feeTo={res['feeTo']} owner={res['owner']}", flush=True)
    pairs = []
    if n:
        idx = list(range(min(n, max_pairs)))
        pr = rpc.batch([("eth_call", [{"to": f, "data": SEL["allPairs"] + pad_uint(i)}, "latest"]) for i in idx])
        pairs = [dec_addr(words(x)[0]) for x in pr if call_ok(x)]
    # always include focus pairs (e.g. funded Base pairs beyond the enumeration cap)
    for p in (focus_pairs or []):
        if p.lower() not in {x.lower() for x in pairs}:
            pairs.append(p)
    res["pairs_scanned"] = len(pairs)
    print(f"[{chain}] enumerating {len(pairs)} pairs", flush=True)

    def scan_pair(p):
        row = {"pair": p}
        try:
            c = rpc.batch([
                ("eth_call", [{"to": p, "data": SEL["token0"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["token1"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["getReserves"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["totalSupply"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["stable"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["fees"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["kLast"]}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["TF"] + pad_addr("0x0000000000000000000000000000000000000001") + pad_uint(0)}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL["MINIMUM_LIQUIDITY"]}, "latest"]),
                ("eth_getCode", [p, "latest"]),
            ])
            row["t0"] = dec_addr(words(c[0])[0]) if call_ok(c[0]) else None
            row["t1"] = dec_addr(words(c[1])[0]) if call_ok(c[1]) else None
            if call_ok(c[2]):
                ws = words(c[2])
                row["r0"], row["r1"] = dec_uint(ws[0]), dec_uint(ws[1])
            row["lp_supply"] = dec_uint(words(c[3])[0]) if call_ok(c[3]) else None
            row["has_stable"] = call_ok(c[4])
            row["fees_addr"] = dec_addr(words(c[5])[0]) if call_ok(c[5]) else None
            row["has_kLast"] = call_ok(c[6])
            row["TF_present"] = call_ok(c[7])
            row["TF_ret"] = c[7][:66] if call_ok(c[7]) else None
            row["has_min_liq"] = call_ok(c[8])
            row["code_size"] = len(c[9] or "0x") // 2 if c[9] else 0
            if row["t0"]:
                b = rpc.batch([
                    ("eth_call", [{"to": row["t0"], "data": SEL["balanceOf"] + pad_addr(p)}, "latest"]),
                    ("eth_call", [{"to": row["t1"], "data": SEL["balanceOf"] + pad_addr(p)}, "latest"]),
                    ("eth_getCode", [row["t0"], "latest"]),
                    ("eth_getCode", [row["t1"], "latest"]),
                ])
                row["b0"] = dec_uint(words(b[0])[0]) if call_ok(b[0]) else None
                row["b1"] = dec_uint(words(b[1])[0]) if call_ok(b[1]) else None
                row["code0"] = len(b[2] or "0x") // 2 - 1 if b[2] else None
                row["code1"] = len(b[3] or "0x") // 2 - 1 if b[3] else None
                if row.get("r0") is not None:
                    row["excess0"] = (row["b0"] or 0) - row["r0"]
                    row["excess1"] = (row["b1"] or 0) - row["r1"]
        except Exception as e:
            row["err"] = str(e)[:120]
        return row

    rows = []
    with ThreadPoolExecutor(max_workers=6) as ex:
        futs = [ex.submit(scan_pair, p) for p in pairs]
        for i, fu in enumerate(as_completed(futs)):
            rows.append(fu.result())
            if i and i % 200 == 0:
                print(f"[{chain}] {i}/{len(pairs)}", flush=True)
    res["pairs"] = rows

    # token metadata for tokens that appear (dedupe, cap)
    toks = []
    seen = set()
    focus_lower = {p.lower() for p in (focus_pairs or [])}
    # focus-pair tokens first
    for row in rows:
        if row.get("pair", "").lower() in focus_lower:
            for t in (row.get("t0"), row.get("t1")):
                if t and t not in seen:
                    seen.add(t); toks.append(t)
    for row in rows:
        for t in (row.get("t0"), row.get("t1")):
            if t and t not in seen:
                seen.add(t); toks.append(t)
    toks = toks[:500]
    meta = {}
    for i in range(0, len(toks), 25):
        chunk = toks[i:i + 25]
        calls = []
        for t in chunk:
            calls += [
                ("eth_call", [{"to": t, "data": SEL["symbol"]}, "latest"]),
                ("eth_call", [{"to": t, "data": SEL["decimals"]}, "latest"]),
                ("eth_call", [{"to": t, "data": SEL["totalSupply"]}, "latest"]),
                ("eth_call", [{"to": t, "data": SEL["owner"]}, "latest"]),
                ("eth_call", [{"to": t, "data": SEL["mint1"] + pad_addr("0x0000000000000000000000000000000000000001") + pad_uint(1)}, "latest"]),
                ("eth_getCode", [t, "latest"]),
            ]
        try:
            rr = rpc.batch(calls)
        except Exception as e:
            print(f"[{chain}] token meta batch fail {str(e)[:80]}", flush=True)
            continue
        for j, t in enumerate(chunk):
            b = rr[j * 6:j * 6 + 6]
            meta[t] = {
                "symbol": dec_str(b[0]) if call_ok(b[0]) else None,
                "decimals": dec_uint(words(b[1])[0]) if call_ok(b[1]) else None,
                "totalSupply": dec_uint(words(b[2])[0]) if call_ok(b[2]) else None,
                "owner": dec_addr(words(b[3])[0]) if call_ok(b[3]) else None,
                "mint_probe_ok": call_ok(b[4]),
                "code_size": len(b[5] or "0x") // 2 if b[5] else 0,
            }
    res["tokens"] = meta
    print(f"[{chain}] done", flush=True)
    return res


def main():
    only = os.environ.get("LEET_ONLY", "")
    max_pairs = int(os.environ.get("LEET_MAX_PAIRS", "250"))
    focus_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "focus.json")
    focus = {}
    if os.path.exists(focus_path):
        for f in json.load(open(focus_path)):
            focus.setdefault(f["chain"], []).append(f["pair"])
    chains = [c for c in FACTORIES if (not only or c in only.split(","))]
    out = {"generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "chains": {}}
    for chain in chains:
        try:
            out["chains"][chain] = scan_chain(chain, max_pairs, focus.get(chain, []))
        except Exception as e:
            print(f"[{chain}] FAIL {str(e)[:200]}", flush=True)
            out["chains"][chain] = {"error": str(e)[:300]}
        json.dump(out, open(os.path.join(OUT, "vuln-scan.json"), "w"), indent=1)
    # summary csv
    with open(os.path.join(OUT, "vuln-summary.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["chain", "pair", "t0", "t1", "r0", "r1", "b0", "b1", "excess0", "excess1",
                    "lp_supply", "TF_present", "has_stable", "has_kLast", "code0", "code1", "code_size", "err"])
        for chain, cres in out["chains"].items():
            for row in cres.get("pairs", []):
                w.writerow([chain, row.get("pair"), row.get("t0"), row.get("t1"), row.get("r0"),
                            row.get("r1"), row.get("b0"), row.get("b1"), row.get("excess0"),
                            row.get("excess1"), row.get("lp_supply"), row.get("TF_present"),
                            row.get("has_stable"), row.get("has_kLast"), row.get("code0"),
                            row.get("code1"), row.get("code_size"), row.get("err", "")])
    print("wrote ci-out/vuln-scan.json + vuln-summary.csv", flush=True)


if __name__ == "__main__":
    main()
