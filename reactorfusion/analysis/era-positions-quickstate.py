#!/usr/bin/env python3
"""Quick read of live state for the 6 ReactorFusion Era cTokens + comptroller."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"

def main():
    rpc = RPC(default_urls('era'), 'era', batch=3)
    block = rpc.block_number()
    print("block:", block, flush=True)
    plan = []
    for m, a in MARKETS.items():
        for key, sig, ot in [
            ("symbol", "symbol()", ["string"]),
            ("underlying", "underlying()", ["address"]),
            ("totalSupply", "totalSupply()", ["uint256"]),
            ("totalBorrows", "totalBorrows()", ["uint256"]),
            ("totalReserves", "totalReserves()", ["uint256"]),
            ("getCash", "getCash()", ["uint256"]),
            ("exchangeRateStored", "exchangeRateStored()", ["uint256"]),
            ("accrualBlockNumber", "accrualBlockNumber()", ["uint256"]),
            ("borrowRatePerBlock", "borrowRatePerBlock()", ["uint256"]),
            ("reserveFactorMantissa", "reserveFactorMantissa()", ["uint256"]),
            ("isCEther", "isCEther()", ["bool"]),
        ]:
            plan.append((m, key, a, sig, ot))
    for m, key, a, sig, ot in [("ALL", "isListed:"+x, C, "markets(address)", ["bool","uint256","bool"]) for x in MARKETS.values()]:
        plan.append((m, key, a, sig, ot))
    items = [(a, calldata(sig, ["address"] if "{m}" in sig else [], [])) for _, _, a, sig, _ in plan]
    res = rpc.try_calls(items, block=hex(block))
    out = {}
    for (m, key, a, sig, ot), (raw, err) in zip(plan, res):
        v = None
        if raw is not None:
            try:
                v = dec(ot, raw)
                if len(v) == 1:
                    v = v[0]
                else:
                    v = list(v)
            except Exception as e:
                err = f"decode: {e}"
        if isinstance(v, bytes):
            v = "0x" + v.hex()
        out.setdefault(m, {})[key] = {"v": v, "err": err}
        print(f"{m}.{key} = {v}   {('ERR: '+str(err)[:80]) if err else ''}", flush=True)
    json.dump({"block": block, "state": out}, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "era-positions-quickstate.json"), "w"), indent=1)

if __name__ == "__main__":
    main()
