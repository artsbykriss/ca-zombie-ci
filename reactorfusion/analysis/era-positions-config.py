#!/usr/bin/env python3
"""Read Comptroller + oracle config for ReactorFusion Era. Saves era-positions-config.json."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, calldata, dec

C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
ORACLE_CLAIMED = "0x1d54DD49218333125C858c0239bbdA424db55C43"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}

def main():
    rpc = RPC([("public:zksync.drpc.org", "https://zksync.drpc.org")], "era", batch=3)
    block = rpc.block_number()
    out = {"block": block, "comptroller": C, "note": "all values at 'latest' block recorded"}
    plan = []
    for k, sig, ot in [
        ("oracle", "oracle()", ["address"]),
        ("closeFactorMantissa", "closeFactorMantissa()", ["uint256"]),
        ("liquidationIncentiveMantissa", "liquidationIncentiveMantissa()", ["uint256"]),
        ("admin", "admin()", ["address"]),
        ("pauseGuardian", "pauseGuardian()", ["address"]),
        ("_borrowGuardianPaused", "_borrowGuardianPaused()", ["bool"]),
        ("_mintGuardianPaused", "_mintGuardianPaused()", ["bool"]),
        ("compRate", "compRate()", ["uint256"]),
        ("getCompAddress", "getCompAddress()", ["address"]),
        ("allMarkets", "allMarkets()", ["address[]"]),
        ("getAllMarkets", "getAllMarkets()", ["address[]"]),
    ]:
        plan.append(("C." + k, C, sig, [], ot))
    items = [(to, calldata(sig, [], [])) for _, to, sig, _, _ in plan]
    res = rpc.try_calls(items, block=hex(block))
    for (k, to, sig, _, ot), (raw, err) in zip(plan, res):
        v = None
        if raw is not None:
            try:
                v = dec(ot, raw)
                v = v[0] if len(v) == 1 else list(v)
            except Exception as e:
                err = f"decode: {e}"
        if isinstance(v, bytes):
            v = "0x" + v.hex()
        out[k] = {"v": v, "err": err}
    print("oracle:", out.get("C.oracle"))
    print("closeFactor:", out.get("C.closeFactorMantissa"))
    print("liqIncentive:", out.get("C.liquidationIncentiveMantissa"))
    print("allMarkets:", out.get("C.allMarkets"))

    O = (out.get("C.oracle", {}).get("v")) or ORACLE_CLAIMED
    out["oracle_addr"] = O
    # per-market comptroller + oracle + ctoken reads
    plan = []
    for m, a in MARKETS.items():
        for k, to, sig, ot in [
            ("isListed", C, "markets(address)", ["bool", "uint256", "bool"]),
            ("collateralFactor", C, "collateralFactorMantissa(address)", ["uint256"]),
            ("mintPaused", C, "mintGuardianPaused(address)", ["bool"]),
            ("borrowPaused", C, "borrowGuardianPaused(address)", ["bool"]),
            ("supplyCap", C, "supplyCaps(address)", ["uint256"]),
            ("borrowCap", C, "borrowCaps(address)", ["uint256"]),
            ("price", O, "getUnderlyingPrice(address)", ["uint256"]),
            ("decimals", a, "decimals()", ["uint256"]),
            ("underlying", a, "underlying()", ["address"]),
            ("accrualBlockNumber", a, "accrualBlockNumber()", ["uint256"]),
            ("interestRateModel", a, "interestRateModel()", ["address"]),
            ("reserveFactor", a, "reserveFactorMantissa()", ["uint256"]),
            ("admin", a, "admin()", ["address"]),
        ]:
            plan.append((f"{m}.{k}", to, sig, [a] if sig.endswith("(address)") else [], ot))
    items = [(to, calldata(sig, ["address"] if sig.endswith("(address)") else [], a if sig.endswith("(address)") else [])) for _, to, sig, a, _ in plan]
    res = rpc.try_calls(items, block=hex(block))
    out["markets"] = {}
    for (k, to, sig, a, ot), (raw, err) in zip(plan, res):
        v = None
        if raw is not None:
            try:
                v = dec(ot, raw)
                v = v[0] if len(v) == 1 else list(v)
            except Exception as e:
                err = f"decode: {e}"
        if isinstance(v, bytes):
            v = "0x" + v.hex()
        if isinstance(v, (list, tuple)):
            v = list(v)
        out["markets"][k] = {"v": v, "err": err}
        print(f"{k} = {v} {('ERR:'+str(err)[:70]) if err else ''}", flush=True)
    json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "era-positions-config.json"), "w"), indent=1)
    print("saved era-positions-config.json")

if __name__ == "__main__":
    main()
