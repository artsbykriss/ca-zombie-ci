#!/usr/bin/env python3
"""Corrected live-state dump v2 for Hover (Kava EVM). Read-only. Usage: python3 dump2.py [blockhex]"""
import json, sys
from rpc import rpc, batch, sel, enc_addr, enc_u256

COMP = "0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC"
IMPL = "0xb618fb7c9921fb35a75fddf5ee1bbdf19080020c"
ORACLE = "0xE8Ae943de7f036Cfa505127641Eee7c5b6606878"
MARKETS = {
    "hKAVA": "0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636",
    "hATOM": "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd",
    "hUSDT": "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961",
}
ALLOWLIST = "0x49AE3cc17eD67c9Bc9cd11E4d799c329bC90203F"

def r0(v):
    if not isinstance(v, str): return v
    return v

def dec(v):
    if isinstance(v, str) and v.startswith("0x") and len(v) >= 3:
        return int(v, 16)
    return v

def main():
    blk = sys.argv[1] if len(sys.argv) > 1 else rpc("eth_blockNumber", [])
    block = hex(int(blk, 16)) if isinstance(blk, str) else hex(blk)
    bn = int(block, 16)
    out = {"chain": "kava", "chain_id": 2222, "block": bn, "rpc": "https://evm.kava.io (keyless)"}

    # --- comptroller (via Unitroller proxy) ---
    comp_calls = {
        "admin()": sel("admin()"),
        "pendingAdmin()": sel("pendingAdmin()"),
        "oracle()": sel("oracle()"),
        "closeFactorMantissa()": sel("closeFactorMantissa()"),
        "liquidationIncentiveMantissa()": sel("liquidationIncentiveMantissa()"),
        "pauseGuardian()": sel("pauseGuardian()"),
        "_mintGuardianPaused()": sel("_mintGuardianPaused()"),
        "_borrowGuardianPaused()": sel("_borrowGuardianPaused()"),
        "transferGuardianPaused()": sel("transferGuardianPaused()"),
        "seizeGuardianPaused()": sel("seizeGuardianPaused()"),
        "comptrollerImplementation()": sel("comptrollerImplementation()"),
        "pendingComptrollerImplementation()": sel("pendingComptrollerImplementation()"),
        "maxAssets()": sel("maxAssets()"),
        "isComptroller()": sel("isComptroller()"),
        "liquidatorsWhitelistVerifier()": sel("liquidatorsWhitelistVerifier()"),
        "protocolTokenAddress()": sel("protocolTokenAddress()"),
        "rewardNativeToken()": sel("rewardNativeToken()"),
        "borrowCapGuardian()": sel("borrowCapGuardian()"),
        "getBlockTimestamp()": sel("getBlockTimestamp()"),
    }
    vals = batch([(COMP, d) for d in comp_calls.values()], block=block)
    C = {}
    for k, v in zip(comp_calls, vals):
        C[k] = v if isinstance(v, dict) else dec(v)
    out["comptroller"] = C
    # arrays
    for fn, key in [("getAllMarkets()", "all_markets"), ("getAllRewardTokens()", "all_reward_tokens")]:
        r = batch([(COMP, sel(fn))], block=block)[0]
        if isinstance(r, str) and len(r) > 2:
            # decode address[]
            n = int(r[2:66], 16)
            addrs = ["0x" + r[66 + i*64 + 24: 66 + i*64 + 64] for i in range(n)]
            C[key] = addrs
    # mark struct: markets(addr) -> (isListed, collateralFactorMantissa) + accountMembership mapping at slot hash
    for name, m in MARKETS.items():
        r = batch([(COMP, sel("markets(address)") + enc_addr(m))], block=block)[0]
        C[f"markets[{name}]"] = r
        for fn in ["mintGuardianPaused(address)", "borrowGuardianPaused(address)", "borrowCaps(address)",
                   "supplyRewardSpeeds(uint8,address)", "borrowRewardSpeeds(uint8,address)", "rewardSupplyState(uint8,address)", "rewardBorrowState(uint8,address)"]:
            for idx in ([0, 1, 2] if ("uint8" in fn and "State" not in fn) else ([0, 1, 2] if "State" in fn else [None])):
                data = sel(fn) + (enc_u256(idx) if idx is not None else "") + enc_addr(m)
                r = batch([(COMP, data)], block=block)[0]
                C[f"{fn}[{idx},{name}]" if idx is not None else f"{fn}[{name}]"] = r if isinstance(r, dict) else dec(r) if isinstance(r, str) and len(r) < 100 else r

    # --- markets ---
    out["markets"] = {}
    for name, m in MARKETS.items():
        calls = {
            "symbol()": sel("symbol()"), "name()": sel("name()"), "decimals()": sel("decimals()"),
            "decimals_impl()": sel("decimals()"),
            "totalSupply()": sel("totalSupply()"), "totalBorrows()": sel("totalBorrows()"),
            "totalReserves()": sel("totalReserves()"), "getCash()": sel("getCash()"),
            "exchangeRateStored()": sel("exchangeRateStored()"),
            "reserveFactorMantissa()": sel("reserveFactorMantissa()"),
            "borrowIndex()": sel("borrowIndex()"),
            "accrualBlockTimestamp()": sel("accrualBlockTimestamp()"),
            "borrowRatePerTimestamp()": sel("borrowRatePerTimestamp()"),
            "supplyRatePerTimestamp()": sel("supplyRatePerTimestamp()"),
            "protocolSeizeShareMantissa()": sel("protocolSeizeShareMantissa()"),
            "admin()": sel("admin()"), "pendingAdmin()": sel("pendingAdmin()"),
            "comptroller()": sel("comptroller()"), "interestRateModel()": sel("interestRateModel()"),
            "implementation()": sel("implementation()"),
            "isCToken()": sel("isCToken()"),
            "underlying()": sel("underlying()"),
            "exchangeRateCurrent()": sel("exchangeRateCurrent()"),
        }
        vals = batch([(m, d) for d in calls.values()], block=block)
        M = {}
        for k, v in zip(calls, vals):
            M[k] = v if isinstance(v, dict) else dec(v)
        # native balance + underlying balances
        bal = rpc("eth_getBalance", [m, block])
        M["native_balance_wei"] = int(bal, 16)
        for tokname, tok in [("uATOM", "0x15932E26f5BD4923d46a2b205191C4b5d5f43FE3"), ("uUSDT", "0x919C1c267BC06a7039e03fcc2eF738525769109c"), ("wKAVA", None)]:
            if tok:
                r = batch([(tok, sel("balanceOf(address)") + enc_addr(m))], block=block)[0]
                M[f"balanceOf_{tokname}"] = dec(r) if isinstance(r, str) else r
        out["markets"][name] = M

    # --- allowlist ---
    A = {}
    for label, a in [("random", "0x1111111111111111111111111111111111111111"), ("admin", "0xcecC934494adED6c0c82C52656a845862176ceeE"), ("zero", "0x0000000000000000000000000000000000000000")]:
        r = batch([(ALLOWLIST, sel("allowed(address)") + enc_addr(a))], block=block)[0]
        A[f"allowed({label})"] = r
    r = batch([(ALLOWLIST, sel("owner()"))], block=block)[0]
    A["owner()"] = r
    out["allowlist"] = A

    # --- oracle ---
    O = {}
    for name, m in MARKETS.items():
        r = batch([(ORACLE, sel("getUnderlyingPrice(address)") + enc_addr(m))], block=block)[0]
        O[f"getUnderlyingPrice({name})"] = r if isinstance(r, dict) else dec(r)
    for fn in ["admin()", "owner()", "paused()"]:
        r = batch([(ORACLE, sel(fn))], block=block)[0]
        O[fn] = r if isinstance(r, dict) else dec(r)
    out["oracle"] = O

    # gas price
    gp = rpc("eth_gasPrice", [])
    out["gas_price_wei"] = int(gp, 16)
    bn_info = rpc("eth_getBlockByNumber", [block, False])
    out["block_timestamp"] = int(bn_info["timestamp"], 16)
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
