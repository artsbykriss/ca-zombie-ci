#!/usr/bin/env python3
"""Classify Trueo markets as V2 (Uniswap v4) or V3 (Uniswap v3) and read pool state.

Read-only; keyless public RPC. Writes poolstate.json (block-pinned).
"""
import json, os, sys, time
import requests
from eth_abi import encode, decode
from eth_utils import keccak

RPC = os.environ.get("BASE_RPC", "https://base-rpc.publicnode.com")
MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
PM = "0x498581fF718922c3f8e6A244956aF099B2652b2b"
HOOK = "0x3E83479B2276EcFb7C7181F67b5d092d3511e0C4"
TYD = "0xb13CF163d916917d9cD6E836905cA5f12a1dEF4B"
HERE = os.path.dirname(os.path.abspath(__file__))
ZERO = "0x0000000000000000000000000000000000000000"


def sig(s):
    return "0x" + keccak(text=s).hex()[:8]


S = {k: sig(v) for k, v in {
    "pools_v4": "getPoolIds()", "fcp": "firstChallengePeriod()", "scp": "secondChallengePeriod()",
    "yesPool": "yesPool()", "noPool": "noPool()", "token0": "token0()", "token1": "token1()",
    "slot0v3": "slot0()", "liq_v3": "liquidity()", "fee_v3": "fee()",
    "bal": "balanceOf(address)", "paused": "poolPaused(bytes32)", "extsload": "extsload(bytes32,uint256)",
}.items()}
SEL_MC = sig("aggregate3((address,bool,bytes)[])")


def rpc(method, params, tries=6):
    for i in range(tries):
        try:
            r = requests.post(RPC, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params},
                              timeout=90, headers={"User-Agent": "Mozilla/5.0 research"})
            j = r.json()
            if "result" in j:
                return j["result"]
        except Exception:
            pass
        time.sleep(1.5 * (i + 1))
    raise RuntimeError("rpc fail")


def mc(calls):
    enc = encode(["(address,bool,bytes)[]"], [[(t, True, bytes.fromhex(d[2:])) for t, d in calls]])
    res = rpc("eth_call", [{"to": MC3, "data": SEL_MC + enc.hex()}, "latest"])
    return decode(["(bool,bytes)[]"], bytes.fromhex(res[2:]))[0]


def main():
    d = json.load(open(os.path.join(HERE, "markets.json")))
    mk = [x for x in d["markets"] if x["status"] == 1]
    print("markets", len(mk), file=sys.stderr)

    # classify: getPoolIds works => V2
    for i in range(0, len(mk), 50):
        ch = mk[i:i + 50]
        res = mc([(x["address"], S["pools_v4"]) for x in ch])
        for x, (ok, ret) in zip(ch, res):
            if ok and len(ret) >= 64:
                x["kind"] = "v2"
                x["pid_yes"] = bytes(ret)[0:32].hex()
                x["pid_no"] = bytes(ret)[32:64].hex()
            else:
                x["kind"] = "v3"

    # V3 pool addresses
    v3 = [x for x in mk if x["kind"] == "v3"]
    for i in range(0, len(v3), 60):
        ch = v3[i:i + 60]
        calls = []
        for x in ch:
            calls += [(x["address"], S["yesPool"]), (x["address"], S["noPool"])]
        res = mc(calls)
        for j, x in enumerate(ch):
            ok1, r1 = res[2 * j]
            ok2, r2 = res[2 * j + 1]
            x["yesPool"] = "0x" + bytes(r1)[-20:].hex() if ok1 else None
            x["noPool"] = "0x" + bytes(r2)[-20:].hex() if ok2 else None

    # read pool state
    for i in range(0, len(mk), 30):
        ch = mk[i:i + 30]
        calls, idx = [], []
        for x in ch:
            if x["kind"] == "v2":
                for key in ("pid_yes", "pid_no"):
                    base = keccak(encode(["bytes32", "uint256"], [bytes.fromhex(x[key]), 6]))
                    calls.append((PM, S["extsload"] + base.hex() + format(1, "064x")))
                    idx.append((x["address"], key.split("_")[1] + "_slot0"))
                    calls.append((PM, S["extsload"] + format(int.from_bytes(base, "big") + 3, "064x")))
                    idx.append((x["address"], key.split("_")[1] + "_liq"))
                calls.append((HOOK, S["paused"] + x["pid_yes"]))
                idx.append((x["address"], "paused_yes"))
                calls.append((HOOK, S["paused"] + x["pid_no"]))
                idx.append((x["address"], "paused_no"))
                calls.append((x["yes"], S["bal"] + "0" * 24 + PM[2:].lower()))
                idx.append((x["address"], "pool_yes"))
                calls.append((x["no"], S["bal"] + "0" * 24 + PM[2:].lower()))
                idx.append((x["address"], "pool_no"))
            else:
                for key in ("yesPool", "noPool"):
                    p = x[key]
                    if p and p != ZERO:
                        calls.append((p, S["slot0v3"]))
                        idx.append((x["address"], ("yes" if key=="yesPool" else "no") + "_slot0"))
                        calls.append((p, S["liq_v3"]))
                        idx.append((x["address"], ("yes" if key=="yesPool" else "no") + "_liq"))
                        calls.append((p, S["token0"]))
                        idx.append((x["address"], ("yes" if key=="yesPool" else "no") + "_t0"))
                        calls.append((p, S["token1"]))
                        idx.append((x["address"], ("yes" if key=="yesPool" else "no") + "_t1"))
                        calls.append((p, S["fee_v3"]))
                        idx.append((x["address"], ("yes" if key=="yesPool" else "no") + "_fee"))
                        calls.append((x["yes"], S["bal"] + "0" * 24 + p[2:]))
                        idx.append((x["address"], "pool_yes"))
                        calls.append((x["no"], S["bal"] + "0" * 24 + p[2:]))
                        idx.append((x["address"], "pool_no"))
        res = mc(calls)
        by = {x["address"]: x for x in ch}
        for (a, key), (ok, ret) in zip(idx, res):
            x = by[a]
            if not ok:
                continue
            b = bytes(ret)
            if key.endswith("_slot0"):
                if x["kind"] == "v2":
                    v = int.from_bytes(b, "big")
                    x[key.replace("_slot0", "_sqrt")] = v & ((1 << 160) - 1)
                    t = (v >> 160) & 0xFFFFFF
                    x[key.replace("_slot0", "_tick")] = t - 2 ** 24 if t >= 2 ** 23 else t
                else:
                    v = int.from_bytes(b[0:32], "big")
                    x[key.replace("_slot0", "_sqrt")] = v & ((1 << 160) - 1)
                    t = (v >> 160) & 0xFFFFFF
                    x[key.replace("_slot0", "_tick")] = t - 2 ** 24 if t >= 2 ** 23 else t
            elif key.endswith("_liq"):
                x[key] = int.from_bytes(b, "big")
            elif key.endswith("_t0") or key.endswith("_t1"):
                x[key] = "0x" + b[-20:].hex()
            elif key.endswith("_fee"):
                x[key] = int.from_bytes(b, "big")
            elif key == "pool_yes" or key == "pool_no":
                x[key] = int.from_bytes(b, "big")
            elif key.startswith("paused"):
                x[key] = bool(int.from_bytes(b, "big"))
        print(f"  {min(i+30,len(mk))}/{len(mk)}", file=sys.stderr)

    # derive human YES/NO prices in TYD
    DEC_YES = 18
    for x in mk:
        for side in ("yes", "no"):
            sq = x.get(side + "_sqrt")
            if not sq:
                continue
            praw = (sq / 2 ** 96) ** 2
            if x["kind"] == "v2":
                # currency0 = min(addr). YES/NO token likely currency0 (18d), TYD currency1 (6d)
                t0 = x["yes"] if x[side] < TYD else TYD
                # v2 pool: currency0 = min(token, TYD)
                if x[side].lower() < TYD.lower():
                    # token0 = side token (18d), token1 = TYD (6d)
                    price = praw * 10 ** (DEC_YES - 6)
                else:
                    price = 1.0 / (praw * 10 ** (6 - DEC_YES)) if praw else None
            else:
                t0 = x.get(side + "_t0")
                t1 = x.get(side + "_t1")
                if not t0 or not t1:
                    continue
                if t0.lower() == x[side].lower() and t1.lower() == TYD.lower():
                    price = praw * 10 ** (DEC_YES - 6)
                elif t0.lower() == TYD.lower() and t1.lower() == x[side].lower():
                    price = 1.0 / (praw * 10 ** (6 - DEC_YES)) if praw else None
                else:
                    price = None
            x[side + "_price"] = price
        x.pop("q", None)
    json.dump({"block": d["block"], "markets": mk}, open(os.path.join(HERE, "poolstate.json"), "w"), indent=1)
    from collections import Counter
    print(Counter(x["kind"] for x in mk), file=sys.stderr)


if __name__ == "__main__":
    main()
