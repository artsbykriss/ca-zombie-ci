#!/usr/bin/env python3
"""
read_state.py — for every distinct (token, owner) pair that ever approved the router,
read live allowance(owner, router), balanceOf(owner), decimals() and symbol() at a pinned block.

Read-only. RPC comes from the environment; never written to disk.
Usage:
    export RPC=<rpc>
    python3 read_state.py --in approval_pairs.json --out state_pinned.json [--block 26253889]
"""
import os, sys, json, time, urllib.request

ROUTER = "0x00000000000044a361ae3cac094c9d1b14eece97"
SEL_ALLOWANCE = "0xdd62ed3e"
SEL_BALANCE = "0x70a08231"
SEL_DECIMALS = "0x313ce567"
SEL_SYMBOL = "0x95d89b41"

RPC = os.environ.get("RPC") or os.environ.get("NODEREAL_ETH_RPC_URL") or os.environ.get("RPC_URL")
assert RPC, "set RPC in env"


def rpc_batch(calls):
    body = json.dumps(calls).encode()
    req = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
    r = json.load(urllib.request.urlopen(req, timeout=120))
    if isinstance(r, dict):
        r = [r]
    return r


def pad(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def main():
    args = sys.argv
    inp = args[args.index("--in") + 1] if "--in" in args else "approval_pairs.json"
    out = args[args.index("--out") + 1] if "--out" in args else "state_pinned.json"
    block = args[args.index("--block") + 1] if "--block" in args else None

    pairs = json.load(open(inp))["pairs"]
    if block is None:
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
        block = json.load(urllib.request.urlopen(urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"}), timeout=60))["result"]
    # --block is given in DECIMAL; an eth_blockNumber result arrives as a 0x-hex string.
    blk = block if (isinstance(block, str) and block.startswith("0x")) else hex(int(block))
    print(f"[state] pinned block {int(blk,16)}  pairs={len(pairs)}")

    results = {}
    B = 40  # calls per batch -> 40 calls = 10 pairs * 4 calls
    i = 0
    t0 = time.time()
    while i < len(pairs):
        chunk = pairs[i:i + B]
        calls = []
        idx = 0
        for (tok, owner, _last) in chunk:
            calls.append({"jsonrpc": "2.0", "id": idx, "method": "eth_call", "params": [{"to": tok, "data": SEL_ALLOWANCE + pad(owner) + pad(ROUTER)}, blk]}); idx += 1
            calls.append({"jsonrpc": "2.0", "id": idx, "method": "eth_call", "params": [{"to": tok, "data": SEL_BALANCE + pad(owner)}, blk]}); idx += 1
            calls.append({"jsonrpc": "2.0", "id": idx, "method": "eth_call", "params": [{"to": tok, "data": SEL_DECIMALS}, blk]}); idx += 1
            calls.append({"jsonrpc": "2.0", "id": idx, "method": "eth_call", "params": [{"to": tok, "data": SEL_SYMBOL}, blk]}); idx += 1
        try:
            resp = rpc_batch(calls)
        except Exception as e:
            print("batch err", e, "retry smaller")
            resp = []
            for c in calls:
                try:
                    resp.extend(rpc_batch([c]))
                except Exception as e2:
                    resp.append({"id": c["id"], "error": str(e2)})
        by_id = {r.get("id"): r for r in resp}
        for j, (tok, owner, last) in enumerate(chunk):
            def val(k):
                r = by_id.get(j * 4 + k, {})
                return r.get("result") if "result" in r else None
            results[tok + "|" + owner] = {
                "token": tok, "owner": owner,
                "last_approval_amount": last,
                "allowance": val(0), "balance": val(1),
                "decimals": val(2), "symbol": val(3),
            }
        i += B
        if (i // B) % 10 == 0:
            print(f"[state] {i}/{len(pairs)} {time.time()-t0:.0f}s", flush=True)
    json.dump({"router": ROUTER, "block": int(blk, 16), "pairs": results}, open(out, "w"))
    print(f"[state] wrote {out}")


if __name__ == "__main__":
    main()
