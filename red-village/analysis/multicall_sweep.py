#!/usr/bin/env python3
"""Local allowance+balance sweep for the Red Village ZooKeeper (read-only, public RPC).

Reads analysis/weth_approval_owners.json (unique WETH approvers of TRVZooKeeper,
from the full-history Approval log sweep) and checks, via Multicall3 aggregate3,
each owner's current allowance(owner, ZooKeeper) and balanceOf(owner).

Outputs analysis/sweep_summary.json with the live sets. No keys are used.
"""
import json
import os
import urllib.request
import time

RPC = os.environ.get("POLYGON_RPC", "https://polygon.drpc.org")
WETH = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"
ZK = "0x426d27190a2ddb87f1c6235f710e159a0a3774d4"
MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
CHUNK = 400


def rpc(method, params, tries=3):
    for _ in range(tries):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            resp = json.loads(urllib.request.urlopen(req, timeout=60).read())
            if "result" in resp:
                return resp["result"]
        except Exception:
            time.sleep(1.0)
    raise RuntimeError(f"rpc failed: {method}")


def enc_address(addr):
    a = addr[2:] if addr.startswith("0x") else addr
    return a.lower().rjust(64, "0")


def enc_uint(n):
    return hex(n)[2:].rjust(64, "0")


def enc_bytes(data_hex):
    b = data_hex[2:] if data_hex.startswith("0x") else data_hex
    ln = len(b) // 2
    padded = b + "0" * ((64 - (len(b) % 64)) % 64)
    return enc_uint(ln) + padded


def build_aggregate3(calls):
    """calls: list of (target, data_hex). Returns 0x-prefixed calldata."""
    n = len(calls)
    # tuple area starts after: offset word (0x20) + length word + n offset words
    offsets = []
    cursor = n * 32
    tuples = []
    for target, data in calls:
        tup = enc_address(target) + enc_uint(1) + enc_uint(0x60) + enc_bytes(data)
        offsets.append(cursor)
        cursor += len(tup) // 2
        tuples.append(tup)
    head = enc_uint(0x20) + enc_uint(n) + "".join(enc_uint(o) for o in offsets)
    return "0x82ad56cb" + head + "".join(tuples)


def decode_results(return_hex):
    """Decode Result3[]: array of (bool success, bytes returnData)."""
    d = return_hex[2:]
    off = int(d[0:64], 16) * 2
    n = int(d[off:off + 64], 16)
    offs_start = off + 64
    results = []
    for i in range(n):
        tup_off = int(d[offs_start + i * 64: offs_start + (i + 1) * 64], 16) * 2 + offs_start
        success = int(d[tup_off:tup_off + 64], 16) == 1
        b_off = tup_off + int(d[tup_off + 64: tup_off + 128], 16) * 2
        blen = int(d[b_off:b_off + 64], 16)
        ret = d[b_off + 64: b_off + 64 + blen * 2]
        results.append((success, ret))
    return results


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    owners = json.load(open(os.path.join(here, "weth_approval_owners.json")))["owners"]
    print(f"owners: {len(owners)}")

    with_allowance = 0
    total_allowance = 0
    with_both = 0
    drainable = 0
    live_wallets = []
    top = (None, 0)
    checked = 0

    for start in range(0, len(owners), CHUNK):
        chunk = owners[start:start + CHUNK]
        calls = []
        for o in chunk:
            calls.append((WETH, "0xdd62ed3e" + enc_address(o) + enc_address(ZK)))  # allowance(owner, ZK)
            calls.append((WETH, "0x70a08231" + enc_address(o)))                     # balanceOf(owner)
        data = build_aggregate3(calls)
        ret = rpc("eth_call", [{"to": MULTICALL3, "data": data}, "latest"])
        res = decode_results(ret)
        for j, o in enumerate(chunk):
            ok_a, ret_a = res[j * 2]
            ok_b, ret_b = res[j * 2 + 1]
            allowance = int(ret_a, 16) if ok_a and ret_a else 0
            balance = int(ret_b, 16) if ok_b and ret_b else 0
            if allowance > 0:
                with_allowance += 1
                total_allowance += allowance
                if balance > 0:
                    with_both += 1
                    d = min(allowance, balance)
                    drainable += d
                    live_wallets.append({"owner": o, "allowance": str(allowance), "balance": str(balance), "drainable": str(d)})
                    if d > top[1]:
                        top = (o, d)
        checked += len(chunk)
        if start % (CHUNK * 10) == 0:
            print(f"checked {checked}/{len(owners)}...")

    summary = {
        "rpc": "public",
        "owners_checked": len(owners),
        "owners_with_allowance": with_allowance,
        "total_residual_allowance_wei": str(total_allowance),
        "total_residual_allowance_weth": f"{total_allowance / 1e18:.18f}",
        "owners_with_allowance_and_balance": with_both,
        "drainable_now_wei": str(drainable),
        "drainable_now_weth": f"{drainable / 1e18:.18f}",
        "top_drainable_owner": top[0],
        "top_drainable_wei": str(top[1]),
        "live_wallets": live_wallets,
    }
    json.dump(summary, open(os.path.join(here, "sweep_summary.json"), "w"), indent=1)
    print(json.dumps({k: v for k, v in summary.items() if k != "live_wallets"}, indent=1))


if __name__ == "__main__":
    main()
