#!/usr/bin/env python3
"""PandaSwap (BSC) live-state enumeration + proofs — CI job.

Read-only. Single-call RPC (no batching, avoids provider misalignment).
Writes ci-out/*.json + ci-out/enumerate.log lines.

Proofs included:
  * factory runtime embeds the pair creation code; keccak(embedded) == factory.pairCodeHash()
  * deployed pair runtime == runtime portion of the embedded creation code
  * CREATE2(factory, keccak(token0,token1), pairCodeHash) == deployed pair address (all pairs)
  * compiled (solc 0.5.16, optimizer 200) pair runtime == deployed pair runtime (metadata stripped)
  * balance - reserve excess per pair (skim candidates), with token classification
  * DefiLlama pricing of all pair reserves + stale-price arb upper bound
"""
import json, os, sys, time, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) zombie-research"}

# ---------------- keccak256 (pure python) ----------------
RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
      0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
      0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
      0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
      0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
      0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
ROT = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
MASK = (1 << 64) - 1


def _rol(x, n):
    return ((x << n) | (x >> (64 - n))) & MASK


def keccak256(data: bytes) -> bytes:
    rate = 136
    padlen = rate - (len(data) % rate)
    data = data + (b"\x81" if padlen == 1 else b"\x01" + b"\x00" * (padlen - 2) + b"\x80")
    state = [[0] * 5 for _ in range(5)]
    for off in range(0, len(data), rate):
        block = data[off:off + rate]
        for i in range(rate // 8):
            x, y = i % 5, i // 5
            state[x][y] ^= int.from_bytes(block[i * 8:(i + 1) * 8], "little")
        for rnd in range(24):
            c = [state[x][0] ^ state[x][1] ^ state[x][2] ^ state[x][3] ^ state[x][4] for x in range(5)]
            d = [c[(x - 1) % 5] ^ _rol(c[(x + 1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    state[x][y] ^= d[x]
            b = [[0] * 5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    b[y][(2 * x + 3 * y) % 5] = _rol(state[x][y], ROT[x][y])
            for x in range(5):
                for y in range(5):
                    state[x][y] = b[x][y] ^ ((~b[(x + 1) % 5][y] & MASK) & b[(x + 2) % 5][y])
            state[0][0] ^= RC[rnd]
    out = b""
    for y in range(5):
        for x in range(5):
            out += state[x][y].to_bytes(8, "little")
            if len(out) >= 32:
                return out[:32]
    return out[:32]


# ---------------- RPC ----------------
RPCS = []
for name in ("BSC_RPC_URL",):
    v = os.environ.get(name)
    if v:
        RPCS.append(v)
ankr = os.environ.get("ANKR_API_KEY")
if ankr:
    RPCS.append(f"https://rpc.ankr.com/bsc/{ankr}")
drpc = os.environ.get("DRPC_API_KEY")
if drpc:
    RPCS.append(f"https://lb.drpc.org/ogrpc?network=bsc&dkey={drpc}")
alch = os.environ.get("ALCHEMY_API_KEY")
if alch:
    RPCS.append(f"https://bnb-mainnet.g.alchemy.com/v2/{alch}")
RPCS += [
    "https://bsc-rpc.publicnode.com",
    "https://bsc-dataseed1.defibit.io",
    "https://bsc.drpc.org",
]
_state = {"url": None}


def _post(url, payload, timeout=20):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=body, headers={**UA, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())


def call(to, data, block, retries=8):
    payload = {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, block]}
    urls = ([_state["url"]] if _state["url"] else []) + [u for u in RPCS if u != _state["url"]]
    for attempt in range(retries):
        for u in urls:
            try:
                r = _post(u, payload, timeout=18)
                if isinstance(r, dict) and "result" in r:
                    _state["url"] = u
                    return r["result"]
            except Exception:
                continue
        time.sleep(0.8 + 0.4 * attempt)
    return None


def rpc(method, params, block=None, retries=8):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    urls = ([_state["url"]] if _state["url"] else []) + [u for u in RPCS if u != _state["url"]]
    for attempt in range(retries):
        for u in urls:
            try:
                r = _post(u, payload, timeout=18)
                if isinstance(r, dict) and "result" in r:
                    _state["url"] = u
                    return r["result"]
            except Exception:
                continue
        time.sleep(0.8 + 0.4 * attempt)
    return None


def as_int(h):
    """Parse the FIRST 32-byte word of an eth_call result (Venus vToken proxies return
    multi-word responses for some getters; only word0 is the actual value)."""
    if h is None or h == "0x":
        return None
    return int(h[2:66], 16)


def as_addr(h):
    if h is None or len(h) < 42:
        return None
    return "0x" + h[-40:]


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def enc_uint(n):
    return hex(n)[2:].rjust(64, "0")


def dec_str(h):
    if not h or h == "0x":
        return None
    raw = h[2:]
    if len(raw) == 64:
        try:
            return bytes.fromhex(raw).rstrip(b"\x00").decode("utf-8", "replace") or None
        except Exception:
            return None
    try:
        off = int(raw[0:64], 16)
        if off == 32 and len(raw) >= 128:
            ln = int(raw[64:128], 16)
            if 0 < ln <= 200:
                return bytes.fromhex(raw[128:128 + ln * 2]).decode("utf-8", "replace")
    except Exception:
        pass
    return None


SEL = {
    "allPairsLength": "0x574f2ba3", "allPairs": "0x1e3dd18b", "feeTo": "0x017e7e58",
    "feeToSetter": "0x094b7415", "pairCodeHash": "0x9aab9248", "token0": "0x0dfe1681",
    "token1": "0xd21220a7", "getReserves": "0x0902f1ac", "totalSupply": "0x18160ddd",
    "balanceOf": "0x70a08231", "symbol": "0x95d89b41", "decimals": "0x313ce567",
    "owner": "0x8da5cb5b", "cap": "0x355274ea", "manualMinted": "0xe6b2fb4a",
    "manualMintLimit": "0xf85b84a4", "sushi": "0x0a087903",
}

FACTORY = "0x9ad32bf5dafe152cbe027398219611db4e8753b3"
PNDA = "0x47dcc83a14ad53ed1f13d3cae8aa4115f07557c0"
BAR = "0xef88e0d265ddc8f5e725a4fda1871f9fe21b11e2"
MAKER = "0xe1a2cd535c4e7d9c2c187e529f9f491ccea41e07"
MAX_UINT112 = (1 << 112) - 1


def llama_prices(tokens):
    out = {}
    for i in range(0, len(tokens), 60):
        chunk = tokens[i:i + 60]
        url = "https://coins.llama.fi/prices/current/" + ",".join(f"bsc:{t}" for t in chunk)
        for attempt in range(4):
            try:
                req = urllib.request.Request(url, headers=UA)
                d = json.loads(urllib.request.urlopen(req, timeout=30).read())
                for k, v in d.get("coins", {}).items():
                    out[k.split(":")[1].lower()] = v.get("price")
                break
            except Exception:
                time.sleep(1.5 * (attempt + 1))
    return out


def out_amount(amount_in, r_in, r_out, fee=0.997):
    if amount_in <= 0 or r_in <= 0 or r_out <= 0:
        return 0.0
    return r_out * amount_in * fee / (r_in + amount_in * fee)


def best_arb(r0, r1, p0, p1):
    best = (None, 0.0, 0.0)
    for direction in ("pay1_get0", "pay0_get1"):
        if direction == "pay1_get0":
            r_in, r_out, p_in, p_out = r1, r0, p1, p0
        else:
            r_in, r_out, p_in, p_out = r0, r1, p0, p1
        lo, hi = 0.0, r_in * 100
        for _ in range(160):
            m1 = lo + (hi - lo) / 3
            m2 = hi - (hi - lo) / 3
            f1 = out_amount(m1, r_in, r_out) * p_out - m1 * p_in
            f2 = out_amount(m2, r_in, r_out) * p_out - m2 * p_in
            if f1 < f2:
                lo = m1
            else:
                hi = m2
        in_amt = (lo + hi) / 2
        prof = out_amount(in_amt, r_in, r_out) * p_out - in_amt * p_in
        if prof > best[2]:
            best = (direction, in_amt * p_in, prof)
    return best


def strip_metadata(b: bytes) -> bytes:
    """Strip solc metadata (bzzr0/bzzr1) from bytecode: find last marker and truncate."""
    for marker in (bytes.fromhex("a265627a7a72315820"), bytes.fromhex("a165627a7a72305820")):
        i = b.rfind(marker)
        if i > 0:
            return b[:i]
    return b


def main():
    t_start = time.time()
    bn_hex = rpc("eth_blockNumber", [])
    bn = int(bn_hex, 16)
    print(f"latest block {bn}", flush=True)

    # ---- factory
    fac = {}
    fac_code = rpc("eth_getCode", [FACTORY, hex(bn)])
    fac["code_len"] = (len(fac_code) - 2) // 2
    n = as_int(call(FACTORY, SEL["allPairsLength"], hex(bn)))
    fac["allPairsLength"] = n
    fac["feeTo"] = as_addr(call(FACTORY, SEL["feeTo"], hex(bn)))
    fac["feeToSetter"] = as_addr(call(FACTORY, SEL["feeToSetter"], hex(bn)))
    pch = call(FACTORY, SEL["pairCodeHash"], hex(bn))
    fac["pairCodeHash"] = pch
    print(f"factory: pairs={n} feeTo={fac['feeTo']} feeToSetter={fac['feeToSetter']} pairCodeHash={pch}", flush=True)

    # ---- all pair addresses
    pairs = []
    for i in range(n):
        a = as_addr(call(FACTORY, SEL["allPairs"] + enc_uint(i), hex(bn)))
        pairs.append(a)
        if i % 25 == 0:
            print(f"  pair addr {i}/{n}", flush=True)
    print(f"pair addresses: {sum(1 for p in pairs if p)}/{n}", flush=True)
    _limit = int(os.environ.get("PANDA_LIMIT", "0") or "0")
    if _limit:
        pairs = pairs[:_limit]
        n = len(pairs)
        print(f"PANDA_LIMIT={_limit} (smoke mode)", flush=True)

    # ---- init-code extraction proof
    fc = bytes.fromhex(fac_code[2:])
    proof = {"pairCodeHash": pch}
    target = bytes.fromhex(pch[2:])
    init_found = None
    init_start = init_end = None
    # The pair creation code is embedded verbatim (CODECOPY'd for CREATE2). Locate it by its
    # constructor prefix and verify keccak256(slice) == pairCodeHash().
    prefix = bytes.fromhex("60806040526001600c55")
    pos = fc.find(prefix)
    if pos >= 0:
        for L in [9215] + list(range(9000, 9400)):
            if pos + L <= len(fc) and keccak256(fc[pos:pos + L]) == target:
                init_found = fc[pos:pos + L]
                init_start, init_end = pos, pos + L
                break
    proof["init_code_found"] = bool(init_found)
    if init_found:
        proof["init_start"], proof["init_end"], proof["init_len"] = init_start, init_end, len(init_found)
        proof["keccak_matches_pairCodeHash"] = True
        print(f"init code found: [{init_start}:{init_end}] len={len(init_found)} keccak==pairCodeHash", flush=True)
        with open(os.path.join(OUT, "pair_initcode.hex"), "w") as f:
            f.write(init_found.hex())
    else:
        proof["keccak_matches_pairCodeHash"] = False
        print("WARNING: init code not located by keccak scan", flush=True)

    # ---- pairs state
    state = {"block": bn, "factory": fac, "pairs": {}, "tokens": {}, "proof": proof}
    for idx, p in enumerate(pairs):
        if not p:
            continue
        t0 = as_addr(call(p, SEL["token0"], hex(bn)))
        t1 = as_addr(call(p, SEL["token1"], hex(bn)))
        r = call(p, SEL["getReserves"], hex(bn))
        r0 = r1 = ts = None
        if r and len(r) >= 194:
            r0 = int(r[2:66], 16); r1 = int(r[66:130], 16); ts = int(r[130:194], 16)
        lp = as_int(call(p, SEL["totalSupply"], hex(bn)))
        b0 = as_int(call(t0, SEL["balanceOf"] + enc_addr(p), hex(bn))) if t0 else None
        b1 = as_int(call(t1, SEL["balanceOf"] + enc_addr(p), hex(bn))) if t1 else None
        state["pairs"][p] = {"token0": t0, "token1": t1, "reserve0": r0, "reserve1": r1,
                             "blockTimestampLast": ts, "lpTotalSupply": lp, "bal0": b0, "bal1": b1}
        if idx % 20 == 0:
            print(f"  pair state {idx}/{n} elapsed {time.time()-t_start:.0f}s", flush=True)

    # ---- token metadata
    tokens = sorted({v["token0"] for v in state["pairs"].values() if v.get("token0")} |
                    {v["token1"] for v in state["pairs"].values() if v.get("token1")})
    for idx, t in enumerate(tokens):
        sym = dec_str(call(t, SEL["symbol"], hex(bn)))
        dec = as_int(call(t, SEL["decimals"], hex(bn)))
        state["tokens"][t] = {"symbol": sym, "decimals": dec}
        if idx % 25 == 0:
            print(f"  token meta {idx}/{len(tokens)}", flush=True)

    # ---- proofs: pair runtime inside init code + CREATE2 for all pairs
    if init_found and pairs:
        sample = next(p for p in pairs if p)
        pc = rpc("eth_getCode", [sample, hex(bn)])
        praw = bytes.fromhex(pc[2:])
        proof["sample_pair"] = sample
        proof["pair_runtime_len"] = len(praw)
        proof["pair_runtime_in_initcode"] = praw in init_found
        proof["pair_runtime_offset_in_initcode"] = init_found.find(praw)
        print(f"pair runtime len {len(praw)} contained-in-init: {praw in init_found} at {init_found.find(praw)}", flush=True)
    ok = 0
    bad = []
    for p in pairs:
        v = state["pairs"].get(p) or {}
        t0, t1 = v.get("token0"), v.get("token1")
        if not t0 or not t1:
            bad.append([p, "missing tokens"]); continue
        if int(t0, 16) < int(t1, 16):
            token0, token1 = t0, t1
        else:
            token0, token1 = t1, t0
        salt = keccak256(bytes.fromhex(token0[2:] + token1[2:]))
        derived = "0x" + keccak256(b"\xff" + bytes.fromhex(FACTORY[2:]) + salt + bytes.fromhex(pch[2:]))[-20:].hex()
        if derived.lower() == p.lower():
            ok += 1
        else:
            bad.append([p, derived])
    proof["create2_ok"] = ok
    proof["create2_bad"] = bad
    print(f"CREATE2 derivation: {ok}/{len(pairs)} match, bad={len(bad)}", flush=True)

    # ---- compiled-code comparison (if poc05 produced it)
    compiled_path = os.path.join(OUT, "pair_compiled_runtime.hex")
    if os.path.exists(compiled_path) and pairs:
        try:
            compiled = bytes.fromhex(open(compiled_path).read().strip().replace("0x", ""))
            sample = next(p for p in pairs if p)
            pc = rpc("eth_getCode", [sample, hex(bn)])
            praw = bytes.fromhex(pc[2:])
            a, b = strip_metadata(compiled), strip_metadata(praw)
            proof["compiled_pair_runtime_len"] = len(compiled)
            proof["deployed_pair_runtime_len"] = len(praw)
            proof["compiled_equals_deployed_metadata_stripped"] = (a == b)
            print(f"compiled pair runtime == deployed (metadata stripped): {a == b} (len {len(a)} vs {len(b)})", flush=True)
        except Exception as e:
            print("compiled comparison failed:", e, flush=True)

    # ---- excess analysis
    excess = []
    for p, v in state["pairs"].items():
        if v.get("bal0") is None or v.get("reserve0") is None:
            continue
        e0 = (v.get("bal0") or 0) - (v.get("reserve0") or 0)
        e1 = (v.get("bal1") or 0) - (v.get("reserve1") or 0)
        if e0 > 0 or e1 > 0:
            t0m = state["tokens"].get(v.get("token0"), {})
            t1m = state["tokens"].get(v.get("token1"), {})
            excess.append({"pair": p, "sym0": t0m.get("symbol"), "sym1": t1m.get("symbol"),
                           "excess0": e0, "excess1": e1,
                           "reserve0": v.get("reserve0"), "reserve1": v.get("reserve1"),
                           "overflow0": (v.get("bal0") or 0) > MAX_UINT112,
                           "overflow1": (v.get("bal1") or 0) > MAX_UINT112})
    state["excess"] = excess
    print(f"pairs with balance>reserve: {len(excess)}", flush=True)
    for e in excess:
        print("  excess:", json.dumps(e), flush=True)

    # ---- PNDA / BAR / MAKER state
    extra = {
        "pnda": {
            "owner": as_addr(call(PNDA, SEL["owner"], hex(bn))),
            "totalSupply": as_int(call(PNDA, SEL["totalSupply"], hex(bn))),
            "cap": as_int(call(PNDA, SEL["cap"], hex(bn))),
            "manualMinted": as_int(call(PNDA, SEL["manualMinted"], hex(bn))),
            "manualMintLimit": as_int(call(PNDA, SEL["manualMintLimit"], hex(bn))),
        },
        "bar": {
            "pnda": as_int(call(PNDA, SEL["balanceOf"] + enc_addr(BAR), hex(bn))),
            "totalSupply": as_int(call(BAR, SEL["totalSupply"], hex(bn))),
        },
        "maker": {
            "pnda": as_int(call(PNDA, SEL["balanceOf"] + enc_addr(MAKER), hex(bn))),
        },
    }
    state["extra"] = extra
    print("extra:", json.dumps(extra), flush=True)

    with open(os.path.join(OUT, "enumeration.json"), "w") as f:
        json.dump(state, f, indent=1)

    # ---- pricing + arb
    addrs = sorted(state["tokens"].keys())
    prices = llama_prices(addrs)
    rows = []
    total = 0.0
    for p, v in state["pairs"].items():
        t0, t1 = v.get("token0"), v.get("token1")
        r0, r1 = v.get("reserve0"), v.get("reserve1")
        if not (t0 and t1 and r0 and r1):
            continue
        d0 = (state["tokens"].get(t0, {}).get("decimals") or 18)
        d1 = (state["tokens"].get(t1, {}).get("decimals") or 18)
        p0 = prices.get(t0.lower()); p1 = prices.get(t1.lower())
        v0 = (r0 / 10 ** d0) * p0 if p0 else 0.0
        v1 = (r1 / 10 ** d1) * p1 if p1 else 0.0
        total += v0 + v1
        row = {"pair": p, "sym0": state["tokens"].get(t0, {}).get("symbol"),
               "sym1": state["tokens"].get(t1, {}).get("symbol"),
               "t0": t0, "t1": t1, "usd": round(v0 + v1, 2)}
        if p0 and p1:
            rr0, rr1 = r0 / 10 ** d0, r1 / 10 ** d1
            dirn, in_usd, prof = best_arb(rr0, rr1, p0, p1)
            row["arb_dir"] = dirn; row["arb_in_usd"] = round(in_usd, 2); row["arb_profit_usd"] = round(prof, 2)
        rows.append(row)
    rows.sort(key=lambda r: -r["usd"])
    arb_rows = [r for r in rows if r.get("arb_profit_usd", 0) > 0.05]
    arb_rows.sort(key=lambda r: -r["arb_profit_usd"])
    priced = {"block": bn, "total_usd": round(total, 2), "n_tokens": len(addrs), "n_priced": len(prices),
              "top": rows[:40], "arb": arb_rows, "arb_total_usd": round(sum(r["arb_profit_usd"] for r in arb_rows), 2)}
    with open(os.path.join(OUT, "priced.json"), "w") as f:
        json.dump(priced, f, indent=1)
    print(f"TOTAL pair value: ${total:,.2f}; DefiLlama-price arb model: ${priced['arb_total_usd']:,.2f}", flush=True)

    # ---- exact live-market arb vs PancakeSwap pools (authoritative)
    sys.path.insert(0, os.path.join(ROOT, "analysis"))
    try:
        from pancake_arb import ArbEngine
        dec_map = {a: (m.get("decimals") or 18) for a, m in state["tokens"].items()}
        eng = ArbEngine(call, hex(bn), dec_map)
        live_rows = []
        for idx, (p, v) in enumerate(state["pairs"].items()):
            t0, t1 = v.get("token0"), v.get("token1")
            r0, r1 = v.get("reserve0"), v.get("reserve1")
            if not (t0 and t1 and r0 and r1):
                continue
            p0 = prices.get(t0.lower()); p1 = prices.get(t1.lower())
            if not (p0 and p1):
                continue
            try:
                res = eng.compute(t0, t1, r0, r1, dec_map.get(t0, 18), dec_map.get(t1, 18), p0, p1)
            except Exception as e:
                res = {"profit_usd": 0.0, "err": str(e)}
            if res.get("profit_usd", 0) > 0.1:
                live_rows.append({"pair": p, "sym0": state["tokens"].get(t0, {}).get("symbol"),
                                  "sym1": state["tokens"].get(t1, {}).get("symbol"), **res})
            if idx % 20 == 0:
                print(f"  live arb {idx}/{len(state['pairs'])}", flush=True)
        live_rows.sort(key=lambda r: -r["profit_usd"])
        live_total = round(sum(r["profit_usd"] for r in live_rows), 2)
        with open(os.path.join(OUT, "arb-live.json"), "w") as f:
            json.dump({"block": bn, "total_arb_usd": live_total, "rows": live_rows,
                       "method": "exact simulation vs live PancakeSwap pools (direct or via WBNB), fees 0.3%/0.25%"}, f, indent=1)
        print(f"LIVE-MARKET ARB (Pancake): ${live_total:,.2f} over {len(live_rows)} pairs", flush=True)
        for r in live_rows[:15]:
            print(f"  live arb ${r['profit_usd']:>8.2f} {r['sym0']}/{r['sym1']} {r['pair']} {r.get('dir')}", flush=True)
    except Exception as e:
        live_total = None
        print("live arb engine failed:", e, flush=True)

    summary = {
        "block": bn,
        "pairs": len([p for p in pairs if p]),
        "pair_value_usd": round(total, 2),
        "arb_defillama_model_usd": priced["arb_total_usd"],
        "arb_live_pancake_usd": live_total,
        "excess_pairs": len(excess),
        "proof": proof,
        "elapsed_s": round(time.time() - t_start, 1),
    }
    with open(os.path.join(OUT, "summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print("DONE", json.dumps(summary), flush=True)


if __name__ == "__main__":
    main()
