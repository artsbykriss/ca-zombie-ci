#!/usr/bin/env python3
"""Live-state dump for Hover (Kava EVM). Read-only. Usage: python3 dump_state.py [block]"""
import json, sys
from rpc import rpc, batch, sel, enc_addr, enc_u256

COMP = "0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC"
ORACLE = "0xE8Ae943de7f036Cfa505127641Eee7c5b6606878"
MARKETS = {
    "hKAVA": "0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636",
    "hATOM": "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd",
    "hUSDT": "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961",
}
EIP1967_IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
EIP1967_BEACON = "0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50"
EIP1967_ADMIN = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"

def u256(h):
    if not isinstance(h, str): return h
    return int(h, 16) if h and h != "0x" else 0

def call1(to, data, block):
    r = batch([(to, data)], block=block)[0]
    return r

def main():
    blk = sys.argv[1] if len(sys.argv) > 1 else rpc("eth_blockNumber", [])
    block = hex(int(blk, 16)) if isinstance(blk, str) else hex(blk)
    out = {"chain": "kava", "chain_id": 2222, "block": int(block, 16), "contracts": {}}

    # Comptroller getters
    comp_reads = {
        "admin()": sel("admin()"), "pendingAdmin()": sel("pendingAdmin()"), "oracle()": sel("oracle()"),
        "closeFactorMantissa()": sel("closeFactorMantissa()"),
        "liquidationIncentiveMantissa()": sel("liquidationIncentiveMantissa()"),
        "pauseGuardian()": sel("pauseGuardian()"),
        "borrowGuardianPaused()": sel("borrowGuardianPaused()"),
        "mintGuardianPaused()": sel("mintGuardianPaused()"),
        "seizeGuardianPaused()": sel("seizeGuardianPaused()"),
        "transferGuardianPaused()": sel("transferGuardianPaused()"),
        "allMarkets length": sel("allMarkets(uint256)")[:-2] + "00",
        "compRate()": sel("compRate()"),
        "_notEntered()": sel("_notEntered()"),
    }
    c = out["contracts"].setdefault(COMP, {"role": "Comptroller", "reads": {}})
    vals = batch([(COMP, d) for d in comp_reads.values()], block=block)
    for (k, _), v in zip(comp_reads.items(), vals):
        c["reads"][k] = v

    # allMarkets enumeration
    n = 0
    markets_list = []
    for i in range(0, 20):
        r = call1(COMP, sel("allMarkets(uint256)")[:-2] + enc_u256(i), block)
        if isinstance(r, str) and r != "0x" and int(r, 16) != 0:
            markets_list.append("0x" + r[-40:])
        else:
            n = i
            break
    c["allMarkets"] = markets_list
    c["allMarkets_count"] = len(markets_list)

    # per-market
    for name, m in MARKETS.items():
        mm = out["contracts"].setdefault(m, {"role": name, "reads": {}})
        reads = {
            "symbol()": sel("symbol()"), "name()": sel("name()"), "decimals()": sel("decimals()"),
            "underlying()": sel("underlying()"),
            "comptroller()": sel("comptroller()"), "interestRateModel()": sel("interestRateModel()"),
            "admin()": sel("admin()"), "implementation()": sel("implementation()"),
            "totalSupply()": sel("totalSupply()"), "totalBorrows()": sel("totalBorrows()"),
            "totalReserves()": sel("totalReserves()"), "getCash()": sel("getCash()"),
            "exchangeRateStored()": sel("exchangeRateStored()"),
            "exchangeRateCurrent()": sel("exchangeRateCurrent()"),
            "reserveFactorMantissa()": sel("reserveFactorMantissa()"),
            "accrualBlockNumber()": sel("accrualBlockNumber()"),
            "borrowRatePerBlock()": sel("borrowRatePerBlock()"),
            "supplyRatePerBlock()": sel("supplyRatePerBlock()"),
            "initialExchangeRateMantissa()": sel("initialExchangeRateMantissa()"),
            "reserveGuardian()": sel("reserveGuardian()"),
            "seizeGuardianPaused()": sel("seizeGuardianPaused()"),
            "transferGuardianPaused()": sel("transferGuardianPaused()"),
            "borrowGuardianPaused()": sel("borrowGuardianPaused()"),
            "mintGuardianPaused()": sel("mintGuardianPaused()"),
            "protocolSeizeShareMantissa()": sel("protocolSeizeShareMantissa()"),
        }
        vals = batch([(m, d) for d in reads.values()], block=block)
        for (k, _), v in zip(reads.items(), vals):
            mm["reads"][k] = v
        # EIP-1967 slots
        slots = batch([], block=block) if False else None
        for label, slot in [("eip1967_impl_slot", EIP1967_IMPL), ("eip1967_beacon_slot", EIP1967_BEACON), ("eip1967_admin_slot", EIP1967_ADMIN)]:
            r = rpc("eth_getStorageAt", [m, slot, block])
            mm[label] = r
        # comptroller.markets(m)
        r = call1(COMP, sel("markets(address)")[:-2] + enc_addr(m), block)
        mm["markets()"] = r
        # pause flags via comptroller keyed by market
        for fname in ["borrowGuardianPaused(address)", "mintGuardianPaused(address)", "redeemGuardianPaused(address)", "seizeGuardianPaused(address)", "transferGuardianPaused(address)"]:
            r = call1(COMP, sel(fname)[:-2] + enc_addr(m), block)
            mm[f"comptroller.{fname}"] = r
        # admin / other accounts with special powers
        for fname in ["supplierCap(address)", "borrowCaps(address)"]:
            r = call1(COMP, sel(fname)[:-2] + enc_addr(m), block)
            mm[f"comptroller.{fname}"] = r

    # oracle price per market
    orc = out["contracts"].setdefault(ORACLE, {"role": "Oracle", "reads": {}})
    for name, m in MARKETS.items():
        r = call1(ORACLE, sel("getUnderlyingPrice(address)")[:-2] + enc_addr(m), block)
        orc["reads"][f"getUnderlyingPrice({name})"] = r
    for fname in ["admin()", "owner()", "getFeed(address)", "getPrice(address)", "paused()"]:
        pass
    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
