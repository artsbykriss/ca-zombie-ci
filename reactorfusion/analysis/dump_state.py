#!/usr/bin/env python3
"""Read-only dump of ReactorFusion (Compound fork) live state on zkSync Era + Telos.
Keyless-or-env RPCs; results contain no secrets. Writes analysis/state-dump.json.
"""
import json, sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

CHAINS = {
    "era": {
        "comptroller": "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2",
        "markets": [
            "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
            "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
            "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
            "0x894cccb9908a0319381c305f947ad0ef44838591",
            "0x0e392b6b05c112677096920ad938a0752d1451f3",
            "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
        ],
    },
    "telos": {
        "comptroller": "0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494",
        "markets": [
            "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
            "0x3d187a993d946f196429c83f9a1831513ac2d2be",
            "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
            "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
        ],
    },
}

COMPTROLLER_SINGLETONS = [
    ("admin", "admin()", (), (), ["address"]),
    ("pendingAdmin", "pendingAdmin()", (), (), ["address"]),
    ("comptrollerImplementation", "comptrollerImplementation()", (), (), ["address"]),
    ("pendingComptrollerImplementation", "pendingComptrollerImplementation()", (), (), ["address"]),
    ("oracle", "oracle()", (), (), ["address"]),
    ("closeFactorMantissa", "closeFactorMantissa()", (), (), ["uint256"]),
    ("liquidationIncentiveMantissa", "liquidationIncentiveMantissa()", (), (), ["uint256"]),
    ("pauseGuardian", "pauseGuardian()", (), (), ["address"]),
    ("transferGuardianPaused", "transferGuardianPaused()", (), (), ["bool"]),
    ("seizeGuardianPaused", "seizeGuardianPaused()", (), (), ["bool"]),
    ("getCompAddress", "getCompAddress()", (), (), ["address"]),
    ("compRate", "compRate()", (), (), ["uint256"]),
    ("borrowCapGuardian", "borrowCapGuardian()", (), (), ["address"]),
    ("_borrowGuardianPaused", "_borrowGuardianPaused()", (), (), ["bool"]),
    ("_mintGuardianPaused", "_mintGuardianPaused()", (), (), ["bool"]),
]

COMPTROLLER_PER_MARKET = [
    ("markets", "markets(address)", ["address"], ["{m}"], ["bool", "uint256", "bool"]),
    ("borrowCaps", "borrowCaps(address)", ["address"], ["{m}"], ["uint256"]),
    ("supplyCaps", "supplyCaps(address)", ["address"], ["{m}"], ["uint256"]),
    ("mintGuardianPaused", "mintGuardianPaused(address)", ["address"], ["{m}"], ["bool"]),
    ("borrowGuardianPaused", "borrowGuardianPaused(address)", ["address"], ["{m}"], ["bool"]),
    ("compSpeeds", "compSpeeds(address)", ["address"], ["{m}"], ["uint256"]),
    ("compSupplySpeeds", "compSupplySpeeds(address)", ["address"], ["{m}"], ["uint256"]),
    ("compBorrowSpeeds", "compBorrowSpeeds(address)", ["address"], ["{m}"], ["uint256"]),
]

CTOKEN_CALLS = [
    ("underlying", "underlying()", (), (), ["address"]),
    ("comptroller", "comptroller()", (), (), ["address"]),
    ("admin", "admin()", (), (), ["address"]),
    ("pendingAdmin", "pendingAdmin()", (), (), ["address"]),
    ("exchangeRateStored", "exchangeRateStored()", (), (), ["uint256"]),
    ("totalSupply", "totalSupply()", (), (), ["uint256"]),
    ("totalBorrows", "totalBorrows()", (), (), ["uint256"]),
    ("totalReserves", "totalReserves()", (), (), ["uint256"]),
    ("getCash", "getCash()", (), (), ["uint256"]),
    ("reserveFactorMantissa", "reserveFactorMantissa()", (), (), ["uint256"]),
    ("protocolSeizeShareMantissa", "protocolSeizeShareMantissa()", (), (), ["uint256"]),
    ("accrualBlockNumber", "accrualBlockNumber()", (), (), ["uint256"]),
    ("interestRateModel", "interestRateModel()", (), (), ["address"]),
    ("initialExchangeRateMantissa", "initialExchangeRateMantissa()", (), (), ["uint256"]),
    ("borrowRatePerBlock", "borrowRatePerBlock()", (), (), ["uint256"]),
    ("supplyRatePerBlock", "supplyRatePerBlock()", (), (), ["uint256"]),
    ("isCEther", "isCEther()", (), (), ["bool"]),
    ("name", "name()", (), (), ["string"]),
    ("symbol", "symbol()", (), (), ["string"]),
]


def run_plan(rpc, plan, block="latest"):
    """plan: list of dicts {key,to,sig,types,vals,out_types}. Returns {key: {'v':..,'err':..}}"""
    items = [(p["to"], calldata(p["sig"], p["types"], [x.format(m=p["to"]) for x in p["vals"]])) for p in plan]
    res = rpc.try_calls(items, block=block)
    out = {}
    for p, (raw, err) in zip(plan, res):
        v, derr = None, err
        if raw is not None:
            try:
                if len(p["out_types"]) == 1:
                    v = dec(p["out_types"], raw)[0]
                else:
                    v = list(dec(p["out_types"], raw))
            except Exception as e:
                derr = f"decode: {e}"
        if isinstance(v, bytes):
            v = "0x" + v.hex()
        out[p["key"]] = {"v": v, "err": derr}
    return out


def dump_chain(name, cfg):
    rpc = RPC(default_urls(name), name)
    block = rpc.block_number()
    out = {"chain": name, "block": block, "rpc": "keyed-env-or-keyless-public (redacted)",
           "comptroller": cfg["comptroller"]}
    C = cfg["comptroller"]

    plan = [dict(key=k, to=C, sig=s, types=t, vals=v, out_types=o) for (k, s, t, v, o) in COMPTROLLER_SINGLETONS]
    plan.append(dict(key="allMarkets", to=C, sig="allMarkets()", types=(), vals=(), out_types=["address[]"]))
    cs = run_plan(rpc, plan)
    out["comptroller_state"] = cs
    markets = cs.get("allMarkets", {}).get("v") or cfg["markets"]
    markets = [m.lower() for m in markets]

    plan = [dict(key=f"{m}|{k}", to=C, sig=s, types=t, vals=v, out_types=o)
            for m in markets for (k, s, t, v, o) in COMPTROLLER_PER_MARKET]
    out["comptroller_markets"] = run_plan(rpc, plan)

    O = cs.get("oracle", {}).get("v")
    if O:
        oplan = [dict(key=f"o|{k}", to=O, sig=s, types=t, vals=v, out_types=o) for (k, s, t, v, o) in
                 [("owner", "owner()", (), (), ["address"]), ("admin", "admin()", (), (), ["address"]),
                  ("pendingOwner", "pendingOwner()", (), (), ["address"])]]
        for m in markets:
            oplan.append(dict(key=f"price|{m}", to=O, sig="getUnderlyingPrice(address)", types=["address"],
                              vals=[m], out_types=["uint256"]))
        out["oracle"] = {"address": O, "state": run_plan(rpc, oplan)}

    plan = [dict(key=f"{m}|{k}", to=m, sig=s, types=t, vals=v, out_types=o)
            for m in markets for (k, s, t, v, o) in CTOKEN_CALLS]
    out["ctokens"] = run_plan(rpc, plan)
    return out


def main():
    outdir = os.path.dirname(os.path.abspath(__file__))
    results = {}
    for name, cfg in CHAINS.items():
        t0 = time.time()
        try:
            results[name] = dump_chain(name, cfg)
            print(f"[ok] {name} block={results[name]['block']} in {time.time()-t0:.0f}s", flush=True)
        except Exception as e:
            results[name] = {"error": str(e)[:500]}
            print(f"[err] {name}: {e}", flush=True)
    with open(os.path.join(outdir, "state-dump.json"), "w") as f:
        json.dump(results, f, indent=1)
    print("written", os.path.join(outdir, "state-dump.json"))


if __name__ == "__main__":
    main()
