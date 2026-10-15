#!/usr/bin/env python3
"""Revert-proof: simulate permissionless extraction paths via eth_call from a fresh EOA.
Read-only (no tx sent). Output: revert-proofs.json"""
import json
import rpcmulti as R

FRESH = "0x000000000000000000000000000000000000dEaD"
FRESH2 = "0x1111111111111111111111111111111111111111"

SNX_PROXY = "0xc0eff7749b125444953ef89682201fb8c6a917cd"   # HZN ProxyERC20 (system entry)
SNX = "0x0110bcbeb89a43ec47e62d1980e29e0683745ffc"
SCHED = "0x45151b3b1fff51d404e7fcdb2a4067ed50165a55"
LIQ = "0x2a7b78b705ea48d278d673e80c880d7eb479f44c"
LIQUIDATIONS = "0x5bcdb40000347ad047008c9295fedbeda7487ad2"
FEEPOOL = "0xb80f834ff243cb66a48f2fe9e37064db0cd9d6fd"
DEPOT = "0x9b957b4a90287ebb33faad9c15199ed9c17d114d"
REDEEMER = "0x05af42bfccd27b0db5697c4a34b8d1aa73f4f186"
REWD = "0xceb4976140994bfb83f29dfbb80bb2d9fc719dac"
LIQREW = "0x05178294edd61ba3f6a78ef419165ad4d0124362"
BRIDGE = "0x4ceb5c49d7e8ad212f19b8e5ea4a5f48c01630fb"
STAKING_HZN = "0x67d5a94f444df4bba254645065a4137fc665bf98"
STAKING_LP = "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8"
ZUSD = "0x7f11125a2f22e1dcc19213475267d2dd2f838ff5"

def eth_call_ret(to, data, frm=FRESH):
    """Returns (result|None, error|None)."""
    r = R._rpc_one("eth_call", [{"from": frm, "to": to, "data": data}, "latest"])
    if isinstance(r, dict):
        return None, r.get("error")
    return r, None

def sel(sig):
    import subprocess
    return subprocess.check_output(["cast", "sig", sig]).decode().strip()

def main():
    out = {}
    tests = [
        ("Synthetix.mint()", SNX_PROXY, sel("mint()")),
        ("Synthetix.issueMaxSynths()", SNX_PROXY, sel("issueMaxSynths()")),
        ("Synthetix.burnSynths(uint256)", SNX_PROXY, sel("burnSynths(uint256)") + "0"*63 + "1"),
        ("Synthetix.claimFees()", SNX_PROXY, sel("claimFees()")),
        ("Synthetix.exchange(bytes32,uint256,bytes32)", SNX_PROXY,
         sel("exchange(bytes32,uint256,bytes32)") + b"zUSD".hex().ljust(64, "0") + "0"*63 + "1" + b"zBNB".hex().ljust(64, "0")),
        ("FeePool.closeCurrentFeePeriod()", FEEPOOL, sel("closeCurrentFeePeriod()")),
        ("FeePool.claimFees()", FEEPOOL, sel("claimFees()")),
        ("Liquidator.flagAccountForLiquidation(0xdead)", LIQ, sel("flagAccountForLiquidation(address)") + FRESH[2:].rjust(64, "0")),
        ("Liquidations.flagAccountForLiquidation(0xdead)", LIQUIDATIONS, sel("flagAccountForLiquidation(address)") + FRESH[2:].rjust(64, "0")),
        ("Synthetix.liquidateDelinquentAccount(0xdead)", SNX_PROXY, sel("liquidateDelinquentAccount(address)") + FRESH[2:].rjust(64, "0")),
        ("Depot.exchangeEtherForSynths()", DEPOT, sel("exchangeEtherForSynths()")),
        ("SynthRedeemer.redeem(zUSD)", REDEEMER, sel("redeem(address)") + ZUSD[2:].rjust(64, "0")),
        ("RewardsDistribution.distributeRewards(1e18)", REWD, sel("distributeRewards(uint256)") + hex(10**18)[2:].rjust(64, "0")),
        ("LiquidatorRewards.getReward(0xdead)", LIQREW, sel("getReward(address)") + FRESH[2:].rjust(64, "0")),
        ("Bridge.deposit(0)", BRIDGE, sel("deposit(uint256)") + "0"*64),
        ("Bridge.forwardTokensToEscrow(HZN)", BRIDGE, sel("forwardTokensToEscrow(address)") + "c0eff7749b125444953ef89682201fb8c6a917cd".rjust(64, "0")),
        ("Staking(HZN).getReward()", STAKING_HZN, sel("getReward()")),
        ("Staking(LP).getReward()", STAKING_LP, sel("getReward()")),
        ("Staking(HZN).withdraw(1)", STAKING_HZN, sel("withdraw(uint256)") + "0"*63 + "1"),
        ("SupplySchedule.mintableSupply()", SCHED, sel("mintableSupply()")),
        ("HZN.transfer(fresh,1e18)", SNX_PROXY, sel("transfer(address,uint256)") + FRESH[2:].rjust(64, "0") + hex(10**18)[2:].rjust(64, "0")),
    ]
    fns = [(lambda t=t: eth_call_ret(t[1], t[2])) for t in tests]
    res = R.multi(fns, workers=8)
    for (name, to, data), (r, e) in zip(tests, res):
        out[name] = {"to": to, "result": r, "error": e}
        print(f"{name:55s} -> {'REVERT: ' + str(e)[:90] if e else 'OK: ' + str(r)[:70]}")
    json.dump(out, open("revert-proofs.json", "w"), indent=1, sort_keys=True)

if __name__ == "__main__":
    main()
