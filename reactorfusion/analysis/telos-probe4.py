#!/usr/bin/env python3
"""Probe 4: comptroller market params + cToken totals + liquidator whitelist.
Read-only. No secrets."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

C = "0x19646a04bfdcf3553adc8faaf8b16d76ec41e494"
MARKETS = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}

def main():
    rpc = RPC(default_urls("telos"), "telos")
    block = rpc.block_number()
    print("block", block)
    out = {"block": block}
    items, keys = [], []
    def add(to, sig, types, vals, otypes, key):
        items.append((to, calldata(sig, types, vals)))
        keys.append((key, otypes))

    add(C, "whitelistedLiquidator()", (), (), ["address"], "whitelistedLiquidator")
    add(C, "closeFactorMantissa()", (), (), ["uint256"], "closeFactorMantissa")
    add(C, "liquidationIncentiveMantissa()", (), (), ["uint256"], "liquidationIncentiveMantissa")
    add(C, "maxAssets()", (), (), ["uint256"], "maxAssets")
    add(C, "oracle()", (), (), ["address"], "oracle")
    add(C, "admin()", (), (), ["address"], "admin")
    add(C, "getAllMarkets()", (), (), ["address[]"], "getAllMarkets")
    for name, m in MARKETS.items():
        add(C, "markets(address)", ["address"], [m], ["bool", "uint256"], f"markets.{name}")
        add(C, "supplyCaps(address)", ["address"], [m], ["uint256"], f"supplyCaps.{name}")
        add(C, "borrowCaps(address)", ["address"], [m], ["uint256"], f"borrowCaps.{name}")
        add(m, "exchangeRateStored()", (), (), ["uint256"], f"exchangeRateStored.{name}")
        add(m, "exchangeRateCurrent()", (), (), ["uint256"], f"exchangeRateCurrent.{name}")
        add(m, "totalSupply()", (), (), ["uint256"], f"totalSupply.{name}")
        add(m, "totalBorrows()", (), (), ["uint256"], f"totalBorrows.{name}")
        add(m, "totalBorrowsCurrent()", (), (), ["uint256"], f"totalBorrowsCurrent.{name}")
        add(m, "totalReserves()", (), (), ["uint256"], f"totalReserves.{name}")
        add(m, "getCash()", (), (), ["uint256"], f"getCash.{name}")
        add(m, "borrowIndex()", (), (), ["uint256"], f"borrowIndex.{name}")
        add(m, "accrualBlockNumber()", (), (), ["uint256"], f"accrualBlockNumber.{name}")
        add(m, "reserveFactorMantissa()", (), (), ["uint256"], f"reserveFactorMantissa.{name}")
        add(m, "protocolSeizeShareMantissa()", (), (), ["uint256"], f"protocolSeizeShareMantissa.{name}")
        add(m, "borrowRatePerBlock()", (), (), ["uint256"], f"borrowRatePerBlock.{name}")
        add(m, "supplyRatePerBlock()", (), (), ["uint256"], f"supplyRatePerBlock.{name}")
        add(m, "interestRateModel()", (), (), ["address"], f"interestRateModel.{name}")
        add(m, "isCEther()", (), (), ["bool"], f"isCEther.{name}")

    res = rpc.try_calls(items, block=hex(block))
    for (key, otypes), (raw, err) in zip(keys, res):
        v = None
        if raw is not None:
            try:
                v = list(dec(otypes, raw)) if len(otypes) > 1 else dec(otypes, raw)[0]
                if isinstance(v, bytes):
                    v = "0x" + v.hex()
            except Exception as e:
                v = f"decode_err {e} raw={raw[:80]}"
        out[key] = {"v": v, "err": err}
        print(f"{key:42s} = {v!r}  err={err}")

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "telos-probe4.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
