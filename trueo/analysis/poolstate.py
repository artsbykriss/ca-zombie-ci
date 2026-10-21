#!/usr/bin/env python3
"""Per-market pool state: pool ids, slot0 price, PoolManager inventory, challenge period.

Read-only; keyless public RPC. Writes poolstate.json.
"""
import json, os, sys, time
import requests
from eth_abi import encode, decode
from eth_utils import keccak

RPC = os.environ.get("BASE_RPC", "https://base-rpc.publicnode.com")
MGR = "0x61A98Bef11867c69489B91f340fE545eEfc695d7"
MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
PM = "0x498581fF718922c3f8e6A244956aF099B2652b2b"
HOOK = "0x3E83479B2276EcFb7C7181F67b5d092d3511e0C4"
TYD = "0xb13CF163d916917d9cD6E836905cA5f12a1dEF4B"
HERE = os.path.dirname(os.path.abspath(__file__))


def sig(s):
    return "0x" + keccak(text=s).hex()[:8]


SEL = {k: sig(v) for k, v in {
    "pools": "getPoolIds()", "sup": "getCurrentStatus()", "q": "marketQuestion()",
    "fcp": "firstChallengePeriod()", "scp": "secondChallengePeriod()",
}.items()}
SEL_MC = sig("aggregate3((address,bool,bytes)[])")
SEL_EXT = sig("extsload(bytes32,uint256)")
SEL_BAL = sig("balanceOf(address)")
SEL_PAUSED = sig("poolPaused(bytes32)")


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


def pool_base(pid: bytes) -> bytes:
    return keccak(encode(["bytes32", "uint256"], [pid, 6]))


def main():
    d = json.load(open(os.path.join(HERE, "markets.json")))
    mk = [x for x in d["markets"] if x["status"] == 1]
    print("markets", len(mk), file=sys.stderr)
    out = []
    for i in range(0, len(mk), 40):
        ch = mk[i:i + 40]
        calls = []
        for x in ch:
            calls.append((x["address"], SEL["pools"]))
            calls.append((x["address"], SEL["fcp"]))
        res = mc(calls)
        for j, x in enumerate(ch):
            ok1, r1 = res[2 * j]
            ok2, r2 = res[2 * j + 1]
            if ok1:
                b = bytes(r1)
                x["pid_yes"] = b[0:32].hex()
                x["pid_no"] = b[32:64].hex()
            x["fcp"] = int.from_bytes(r2, "big") if ok2 else None
        # slot0 for both pools + balances + paused
        calls2 = []
        for x in ch:
            for key in ("pid_yes", "pid_no"):
                base = pool_base(bytes.fromhex(x[key]))
                calls2.append((PM, SEL_EXT + base.hex() + format(0, "064x")))
            calls2.append((x["yes"], SEL_BAL + "0" * 24 + PM[2:].lower()))
            calls2.append((x["no"], SEL_BAL + "0" * 24 + PM[2:].lower()))
            calls2.append((HOOK, SEL_PAUSED + x["pid_yes"]))
            calls2.append((HOOK, SEL_PAUSED + x["pid_no"]))
        r2 = mc(calls2)
        k = 0
        for x in ch:
            for key in ("pid_yes", "pid_no"):
                ok, ret = r2[k]; k += 1
                val = int.from_bytes(ret, "big") if ok else None
                if val is not None:
                    sq = val & ((1 << 160) - 1)
                    tick = (val >> 160) & 0xFFFFFF
                    if tick >= 2 ** 23:
                        tick -= 2 ** 24
                    x[key.replace("pid", "sqrt")] = sq
                    x[key.replace("pid", "tick")] = tick
            ok, ret = r2[k]; k += 1
            x["pm_yes"] = int.from_bytes(ret, "big") if ok else None
            ok, ret = r2[k]; k += 1
            x["pm_no"] = int.from_bytes(ret, "big") if ok else None
            ok, ret = r2[k]; k += 1
            x["paused_yes"] = bool(int.from_bytes(ret, "big")) if ok else None
            ok, ret = r2[k]; k += 1
            x["paused_no"] = bool(int.from_bytes(ret, "big")) if ok else None
            out.append(x)
        print(f"  {min(i+40,len(mk))}/{len(mk)}", file=sys.stderr)
    json.dump({"block": d["block"], "markets": out}, open(os.path.join(HERE, "poolstate.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
