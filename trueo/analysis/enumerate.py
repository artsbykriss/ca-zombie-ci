#!/usr/bin/env python3
"""Enumerate all Trueo (Base) markets via Manager.getActiveMarketAddress + Multicall3.

Read-only. Uses a keyless public RPC. Writes markets.json next to this script.
"""
import json, os, sys, time
import requests
from eth_abi import encode, decode
from eth_utils import keccak

RPC = os.environ.get("BASE_RPC", "https://base-rpc.publicnode.com")
MGR = "0x61A98Bef11867c69489B91f340fE545eEfc695d7"
MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
TYD = "0xb13CF163d916917d9cD6E836905cA5f12a1dEF4B"


def sig(s):
    return "0x" + keccak(text=s).hex()[:8]


def rpc(method, params, tries=6):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    last = None
    for i in range(tries):
        try:
            r = requests.post(RPC, json=payload, timeout=90,
                              headers={"User-Agent": "Mozilla/5.0 research"})
            j = r.json()
            if "result" in j:
                return j["result"]
            last = j
        except Exception as e:  # noqa
            last = str(e)
        time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"rpc failed {method}: {last}")


SEL = {k: sig(v) for k, v in {
    "n": "numberOfActiveMarkets()",
    "addr": "getActiveMarketAddress(uint256)",
    "status": "getCurrentStatus()",
    "rawstatus": "currentStatus()",
    "end": "endOfTrading()",
    "win": "winningPosition()",
    "propAt": "resolutionProposedAt()",
    "dispAt": "disputedAt()",
    "councilAt": "councilDecisionAt()",
    "escAt": "escalatedDisputeAt()",
    "fcp": "firstChallengePeriod()",
    "yes": "yesToken()",
    "no": "noToken()",
    "rbond": "resolverBondAmount()",
    "cap": "yesNoTokenCap()",
    "q": "marketQuestion()",
    "finAt": "finalizedAt()",
}.items()}
SEL_ERC20 = {
    "bal": sig("balanceOf(address)"),
    "ts": sig("totalSupply()"),
    "dec": sig("decimals()"),
}


def mc_aggregate(calls, block="latest"):
    enc = encode(["(address,bool,bytes)[]"], [[(t, True, bytes.fromhex(d[2:])) for t, d in calls]])
    data = sig("aggregate3((address,bool,bytes)[])") + enc.hex()
    res = rpc("eth_call", [{"to": MULTICALL3, "data": data}, block])
    return decode(["(bool,bytes)[]"], bytes.fromhex(res[2:]))[0]


def pad_addr(a):
    return "0" * 24 + a[2:].lower()


def sel_uint(selector, arg=None):
    return selector + (("0" * 64) if arg is None else format(arg, "064x"))


def main():
    blk = int(rpc("eth_blockNumber", []), 16)
    n = int(rpc("eth_call", [{"to": MGR, "data": SEL["n"]}, "latest"]), 16)
    print("block", blk, "markets", n, file=sys.stderr)

    addrs = []
    for start in range(0, n, 100):
        calls = [(MGR, sel_uint(SEL["addr"], i)) for i in range(start, min(start + 100, n))]
        for ok, ret in mc_aggregate(calls):
            addrs.append("0x" + ret[-20:].hex() if ok else None)
    print("resolved addrs", len(addrs), file=sys.stderr)

    KEYS = ("status", "rawstatus", "end", "win", "propAt", "dispAt", "councilAt", "escAt", "fcp", "cap", "finAt")
    rows = {}
    B = 60
    for start in range(0, len(addrs), B):
        chunk = [a for a in addrs[start:start + B] if a]
        calls, idx = [], []
        for a in chunk:
            for key in KEYS:
                calls.append((a, SEL[key]))
                idx.append((a, key))
            calls.append((a, SEL["yes"]))
            idx.append((a, "yes"))
            calls.append((a, SEL["no"]))
            idx.append((a, "no"))
            calls.append((TYD, SEL_ERC20["bal"] + pad_addr(a)))
            idx.append((a, "tydbal"))
        res = mc_aggregate(calls)
        for (a, key), (ok, ret) in zip(idx, res):
            r = rows.setdefault(a, {"address": a})
            if not ok:
                r[key] = None
            elif key in ("yes", "no"):
                r[key] = "0x" + ret[-20:].hex()
            else:
                r[key] = int.from_bytes(ret, "big")
        print(f"  {min(start+B,len(addrs))}/{len(addrs)}", file=sys.stderr)

    rows = list(rows.values())
    interesting = [r for r in rows if r.get("status") in (1, 2, 3, 4, 5, 6)]
    print("interesting (non-Created/Finalized)", len(interesting), file=sys.stderr)
    for start in range(0, len(interesting), 80):
        chunk = interesting[start:start + 80]
        calls, idx = [], []
        for r in chunk:
            for key in ("yes", "no"):
                t = r.get(key)
                if t:
                    calls.append((t, SEL_ERC20["ts"]))
                    idx.append((r["address"], "ts_" + key))
        if not calls:
            continue
        res = mc_aggregate(calls)
        by = {r["address"]: r for r in chunk}
        for (a, key), (ok, ret) in zip(idx, res):
            by[a][key] = int.from_bytes(ret, "big") if ok else None

    out = {"chain": "base", "block": blk, "manager": MGR, "payment_token": TYD,
           "n_markets": n, "markets": rows}
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "markets.json")
    json.dump(out, open(p, "w"), indent=1)
    print("wrote", p, file=sys.stderr)


if __name__ == "__main__":
    main()
