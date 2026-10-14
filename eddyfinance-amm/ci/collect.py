#!/usr/bin/env python3
"""CI evidence collector for EddyFinance AMM (ZetaChain). Keyless public RPCs only.
Writes ci-out/live-state.json, ci-out/arb-results.txt, ci-out/SUMMARY.txt."""
import json, time, urllib.request, os, sys
from decimal import Decimal, getcontext
getcontext().prec = 80

RPCS = [
    "https://7000.rpc.thirdweb.com",
    "https://zeta-chain.drpc.org",
    "https://zetachain-evm.blockpi.network/v1/rpc/public",
    "https://zetachain.rpc.thirdweb.com",
]
UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}
FACTORY = "0x9fd96203f7b22bCF72d9DCb40ff98302376cE09c"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT, exist_ok=True)

def rpc(method, params, rpc_idx=0):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(6):
        url = RPCS[(rpc_idx + attempt) % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=payload, headers=UA)
            out = json.load(urllib.request.urlopen(req, timeout=12))
            if "result" in out:
                return out["result"]
            last = out.get("error")
        except Exception as e:
            last = e
        time.sleep(0.3)
    raise RuntimeError(f"{method} failed: {last}")

SEL = {
    "allPairsLength": "0x574f2ba3",
    "allPairs(uint256)": "0x1e3dd18b",
    "token0": "0x0dfe1681",
    "token1": "0xd21220a7",
    "getReserves": "0x0902f1ac",
    "totalSupply": "0x18160ddd",
    "balanceOf(address)": "0x70a08231",
    "kLast": "0x7464fc3d",
    "symbol": "0x95d89b41",
    "decimals": "0x313ce567",
    "feeTo": "0x017e7e58",
    "feeToSetter": "0x094b7415",
    "stakingToken": "0x72f702f3",
    "rewardsToken": "0xd1af0c7d",
    "owner": "0x8da5cb5b",
    "rewardRate": "0x7b0a47ee",
    "periodFinish": "0xebe2b12b",
    "earned(address)": "0x008cc262",
    "balances(uint256)": "0x4903b0d1",
    "A": "0xf446c1d0",
    "fee()": "0xddca3f43",
    "admin_balances(uint256)": "0xe2e7d264",
    "coins(uint256)": "0xc6610657",
    "convertStZETAToZETA(uint256)": "0x962fc585",
}

def pad(h):
    return h.lower().replace("0x", "").rjust(64, "0")

def call(to, sig, arg=None):
    data = SEL[sig] + (pad(arg) if arg else "")
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def uint(h):
    return int(h, 16) if h and h != "0x" else 0

def addr(h):
    return "0x" + h[-40:] if h and len(h) >= 42 else None

def sstr(h):
    if not h or h == "0x": return ""
    b = bytes.fromhex(h[2:])
    if len(b) >= 64:
        off = int.from_bytes(b[0:32], "big"); ln = int.from_bytes(b[off:off+32], "big")
        return b[off+32:off+32+ln].decode("utf-8", "replace")
    return b.decode("utf-8", "replace")

def main():
    block = int(rpc("eth_blockNumber", []), 16)
    n = uint(call(FACTORY, "allPairsLength"))
    pairs = [addr(call(FACTORY, "allPairs(uint256)", hex(i))) for i in range(n)]
    feeTo = addr(call(FACTORY, "feeTo"))
    feeToSetter = addr(call(FACTORY, "feeToSetter"))
    out = {"block": block, "factory": FACTORY, "allPairsLength": n, "feeTo": feeTo,
           "feeToSetter": feeToSetter, "pairs": []}
    toks = set()
    for i, p in enumerate(pairs):
        t0 = addr(call(p, "token0")); t1 = addr(call(p, "token1"))
        res = call(p, "getReserves")[2:]
        r0 = int(res[0:64], 16); r1 = int(res[64:128], 16)
        ts = uint(call(p, "totalSupply"))
        b0 = uint(call(t0, "balanceOf(address)", p))
        b1 = uint(call(t1, "balanceOf(address)", p))
        lpself = uint(call(p, "balanceOf(address)", p))
        kl = uint(call(p, "kLast"))
        out["pairs"].append({"pair": p, "token0": t0, "token1": t1, "r0": r0, "r1": r1,
                             "totalSupply": ts, "b0": b0, "b1": b1, "lpSelf": lpself,
                             "kLast": kl, "excess0": b0 - r0, "excess1": b1 - r1})
        toks.add(t0); toks.add(t1)
        print(f"pairs {i+1}/{n}", flush=True)
    meta = {}
    for t in toks:
        meta[t] = {"symbol": sstr(call(t, "symbol")), "decimals": uint(call(t, "decimals"))}
    out["tokens"] = meta
    # farms
    farms = ["0x14a4Ab67b637c366AC58C4F416C297Cd3037bDb3",
             "0xB681eC7C35534bd9131e02A31fe0eb698a81843F",
             "0xFd9048fC1f26765f60272f4E8B8D1C8faC62EB89"]
    out["farms"] = []
    for f in farms:
        st = addr(call(f, "stakingToken")); rt = addr(call(f, "rewardsToken"))
        d = {"farm": f, "stakingToken": st, "rewardsToken": rt,
             "owner": addr(call(f, "owner")),
             "totalSupply": uint(call(f, "totalSupply")),
             "rewardRate": uint(call(f, "rewardRate")),
             "periodFinish": uint(call(f, "periodFinish")),
             "rewardsTokenBalance": uint(call(rt, "balanceOf(address)", f)) if rt else None,
             "earnedFresh": uint(call(f, "earned(address)", "0x000000000000000000000000000000000000bEEF"))}
        out["farms"].append(d)
    # stableswap pools
    pools = {
        "stzeta_pool": ("0x01a9cd602c6c3f05ea9a3a55184c2181bd43e4b8", 2),
        "stzeta_pool2": ("0xee1629de70afaf3ae3592a9d6d859949750aa697", 2),
        "fourpool": ("0x448028804461e8e5a8877c228F3adFd58c3Da6B6", 4),
        "twopool": ("0x89cb3fA2A7910A268e9f7F619108aFADBD7587c4", 2),
    }
    out["pools"] = {}
    for name, (p, nc) in pools.items():
        d = {"address": p, "owner": addr(call(p, "owner")), "A": uint(call(p, "A")),
             "fee": uint(call(p, "fee()")), "balances": [], "admin_balances": [], "coins": []}
        for i in range(nc):
            d["balances"].append(uint(call(p, "balances(uint256)", hex(i))))
            d["coins"].append(addr(call(p, "coins(uint256)", hex(i))))
            try:
                d["admin_balances"].append(uint(call(p, "admin_balances(uint256)", hex(i))))
            except Exception:
                d["admin_balances"].append(None)
        out["pools"][name] = d
    json.dump(out, open(os.path.join(OUT, "live-state.json"), "w"), indent=1)
    print("wrote live-state.json")

    # ---- summary ----
    lines = [f"EddyFinance AMM live state @ ZetaChain block {block}",
             f"factory {FACTORY} allPairsLength={n} feeTo={feeTo} feeToSetter={feeToSetter}"]
    ex = [(p["pair"], p["excess0"], p["excess1"], p["lpSelf"]) for p in out["pairs"]
          if p["excess0"] or p["excess1"] or p["lpSelf"]]
    zero = [(p["pair"], p["token0"], p["token1"], p["r0"], p["r1"]) for p in out["pairs"]
            if p["r0"] == 0 or p["r1"] == 0]
    lines.append(f"pairs with excess balance or self-held LP: {len(ex)} {ex}")
    lines.append(f"pairs with a zero reserve: {len(zero)} {zero}")
    for d in out["farms"]:
        lines.append(f"farm {d['farm']} staking={d['stakingToken']} rewards={d['rewardsToken']} "
                     f"staked={d['totalSupply']} rewardRate={d['rewardRate']} periodFinish={d['periodFinish']} "
                     f"rewardBal={d['rewardsTokenBalance']} earned(0xbeef)={d['earnedFresh']}")
    for name, d in out["pools"].items():
        lines.append(f"pool {name} {d['address']} owner={d['owner']} A={d['A']} fee={d['fee']} "
                     f"balances={d['balances']} admin={d['admin_balances']}")
    open(os.path.join(OUT, "SUMMARY.txt"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))

    # ---- arb quantification (ZetaEarn stZETA discount on Eddy pair 0x6b3ee329) ----
    def univ2_out(dx, r_in, r_out):
        return dx * 997 * r_out // (r_in * 1000 + dx * 997)
    pair_stz = next((p for p in out["pairs"] if p["pair"].lower() == "0x6b3ee329b0dc80d730d2de370bad93ca122e75db"), None)
    arb_lines = []
    if pair_stz:
        # ZetaEarn vault redemption rate (proxy -> convertStZETAToZETA(1e18))
        try:
            r = call("0x45334a5b0a01ce6c260f2b570ec941c680ea62c0", "convertStZETAToZETA(uint256)", hex(10**18))
            rate = int(r[2:][0:64], 16) / 1e18 if r and r != "0x" else None
        except Exception as e:
            rate = None
        arb_lines.append(f"ZetaEarn convertStZETAToZETA(1e18) = {rate} ZETA/stZETA")
        R0, R1 = pair_stz["r0"], pair_stz["r1"]
        arb_lines.append(f"Eddy pair 0x6b3ee329 reserves: {R0} stZETA / {R1} WZETA; marginal {R1/R0:.6f} WZETA/stZETA")
        if rate:
            arb_lines.append(f"discount vs vault redemption: {100*(1-(R1/R0)/rate):.2f}%")
            best = (None, -1, None)
            for xz in [10,50,100,250,500,750,1000,1500,1900,2000,2500,3000,4000]:
                x = xz * 10**18
                stz = univ2_out(x, R1, R0)
                prof = stz * rate - x
                arb_lines.append(f"X={xz} WZETA -> {stz/1e18:.3f} stZETA -> redeem {stz*rate/1e18:.3f} ZETA | profit {prof/1e18:.4f} ZETA ({100*prof/x:.2f}%)")
                if prof > best[1]: best = (xz, prof, stz)
            arb_lines.append(f"OPTIMUM: x={best[0]} WZETA -> profit ~{best[1]/1e18:.4f} ZETA (precondition: ZetaEarn redemption queue works, ~21d)")
    open(os.path.join(OUT, "arb-results.txt"), "w").write("\n".join(arb_lines) + "\n")
    print("\n".join(arb_lines))

if __name__ == "__main__":
    main()
