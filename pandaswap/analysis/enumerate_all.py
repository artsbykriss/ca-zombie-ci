#!/usr/bin/env python3
"""Full per-pair state for all 129 PandaSwap pairs, checkpointed. Reads pairs-list.json."""
import json, os, sys, time, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number, encode_addr, as_addr, as_int

HERE = os.path.dirname(os.path.abspath(__file__))
PLIST = os.path.join(HERE, "pairs-list.json")
OUT = os.path.join(HERE, "all-pairs.json")

SEL_TOKEN0 = "0x0dfe1681"
SEL_TOKEN1 = "0xd21220a7"
SEL_RESERVES = "0x0902f1ac"
SEL_TOTALSUPPLY = "0x18160ddd"
SEL_BALANCEOF = "0x70a08231"
SEL_SYMBOL = "0x95d89b41"
SEL_DECIMALS = "0x313ce567"
SEL_NAME = "0x06fdde03"
SEL_FACTORY = "0xc45a0155"


def decode_string(hexstr):
    """Decode ABI-encoded string OR bytes32 string."""
    if not hexstr or hexstr == "0x":
        return None
    raw = hexstr[2:]
    if len(raw) == 64:  # bytes32
        try:
            return bytes.fromhex(raw).rstrip(b"\x00").decode("utf-8", "replace") or None
        except Exception:
            return None
    if len(raw) > 64:
        try:
            off = int(raw[0:64], 16)
            if off == 32 and len(raw) >= 128:
                ln = int(raw[64:128], 16)
                if 0 < ln <= 200:
                    return bytes.fromhex(raw[128:128 + ln * 2]).decode("utf-8", "replace")
        except Exception:
            pass
        try:
            return bytes.fromhex(raw).rstrip(b"\x00").decode("utf-8", "replace") or None
        except Exception:
            return None
    return None


def paced_batch(calls, label, retries=12, batch=20, pause=0.6):
    """Run calls in batches with pacing + retries; returns results list."""
    results = [None] * len(calls)
    pending = list(range(len(calls)))
    attempt = 0
    while pending and attempt < retries:
        chunk = pending[:batch]
        rest = pending[batch:]
        t0 = time.time()
        out = rpc_batch([calls[i] for i in chunk], retries=3, batch=batch)
        for j, i in enumerate(chunk):
            if out[j] is not None:
                results[i] = out[j]
        pending = [i for i in chunk if results[i] is None] + rest
        attempt += 1
        got = sum(1 for i in chunk if results[i] is not None)
        print(f"  [{label}] attempt {attempt}: {got}/{len(chunk)} ok, {len(pending)} pending, {time.time()-t0:.1f}s", flush=True)
        if pending:
            time.sleep(pause * attempt)
    return results


def main():
    plist = json.load(open(PLIST))
    pairs = [p for p in plist["pairs"] if p]
    bn = plist["block"]
    print(f"pairs={len(pairs)} block={bn}", flush=True)

    # checkpoint structure
    state = {"block": bn, "factory": plist["factory"], "pairs": {p: {} for p in pairs}}
    if os.path.exists(OUT):
        try:
            old = json.load(open(OUT))
            if old.get("block") == bn:
                state = old
                print("resuming from checkpoint", flush=True)
        except Exception:
            pass

    def done(p, keys):
        return all(k in state["pairs"].get(p, {}) for k in keys)

    # 1) token0/token1
    todo = [p for p in pairs if not done(p, ["token0", "token1"])]
    if todo:
        calls = []
        for p in todo:
            calls.append(("eth_call", [{"to": p, "data": SEL_TOKEN0}, hex(bn)]))
        calls += [("eth_call", [{"to": p, "data": SEL_TOKEN1}, hex(bn)]) for p in todo]
        out = paced_batch(calls, "tokens")
        for j, p in enumerate(todo):
            state["pairs"][p]["token0"] = as_addr(out[j])
            state["pairs"][p]["token1"] = as_addr(out[len(todo) + j])
        json.dump(state, open(OUT, "w"), indent=1)

    # 2) reserves
    todo = [p for p in pairs if not done(p, ["reserve0"])]
    if todo:
        out = paced_batch([("eth_call", [{"to": p, "data": SEL_RESERVES}, hex(bn)]) for p in todo], "reserves")
        for j, p in enumerate(todo):
            r = out[j]
            if r and len(r) >= 194:
                state["pairs"][p]["reserve0"] = int(r[2:66], 16)
                state["pairs"][p]["reserve1"] = int(r[66:130], 16)
                state["pairs"][p]["blockTimestampLast"] = int(r[130:194], 16)
        json.dump(state, open(OUT, "w"), indent=1)

    # 3) LP total supply
    todo = [p for p in pairs if not done(p, ["lpTotalSupply"])]
    if todo:
        out = paced_batch([("eth_call", [{"to": p, "data": SEL_TOTALSUPPLY}, hex(bn)]) for p in todo], "lpsupply")
        for j, p in enumerate(todo):
            state["pairs"][p]["lpTotalSupply"] = as_int(out[j])
        json.dump(state, open(OUT, "w"), indent=1)

    # 4) balances (excess detection)
    todo = [p for p in pairs if not done(p, ["bal0", "bal1"])]
    if todo:
        calls = []
        for p in todo:
            calls.append(("eth_call", [{"to": state["pairs"][p].get("token0") or "0x0000000000000000000000000000000000000000", "data": SEL_BALANCEOF + encode_addr(p)}, hex(bn)]))
        calls += [("eth_call", [{"to": state["pairs"][p].get("token1") or "0x0000000000000000000000000000000000000000", "data": SEL_BALANCEOF + encode_addr(p)}, hex(bn)]) for p in todo]
        out = paced_batch(calls, "balances")
        for j, p in enumerate(todo):
            state["pairs"][p]["bal0"] = as_int(out[j])
            state["pairs"][p]["bal1"] = as_int(out[len(todo) + j])
        json.dump(state, open(OUT, "w"), indent=1)

    # 5) token metadata
    tokens = sorted({v.get("token0") for v in state["pairs"].values() if v.get("token0")} |
                    {v.get("token1") for v in state["pairs"].values() if v.get("token1")})
    tmeta = state.get("tokens", {})
    todo = [t for t in tokens if t not in tmeta or not tmeta[t].get("symbol")]
    if todo:
        calls = [("eth_call", [{"to": t, "data": SEL_SYMBOL}, hex(bn)]) for t in todo]
        calls += [("eth_call", [{"to": t, "data": SEL_DECIMALS}, hex(bn)]) for t in todo]
        out = paced_batch(calls, "tokmeta")
        for j, t in enumerate(todo):
            tmeta[t] = {"symbol": decode_string(out[j]), "decimals": as_int(out[len(todo) + j])}
        state["tokens"] = tmeta
        json.dump(state, open(OUT, "w"), indent=1)

    # summary
    n_excess = 0
    for p, v in state["pairs"].items():
        e0 = (v.get("bal0") or 0) - (v.get("reserve0") or 0)
        e1 = (v.get("bal1") or 0) - (v.get("reserve1") or 0)
        if e0 > 0 or e1 > 0:
            n_excess += 1
    missing = [p for p in pairs if not done(p, ["token0", "reserve0", "lpTotalSupply", "bal0"])]
    print(f"DONE. excess pairs={n_excess}, incomplete={len(missing)}", flush=True)
    json.dump(state, open(OUT, "w"), indent=1)


if __name__ == "__main__":
    main()
