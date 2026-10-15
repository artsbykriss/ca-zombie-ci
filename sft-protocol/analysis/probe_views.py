#!/usr/bin/env python3
"""Batch-probe view functions on SFT contracts. Uses fc.py rpc helper with cache."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fc import rpc, load_cache, save_cache

POOL = "0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E"
REWARD = "0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7"
SFT = "0xC5eA96Dd365983cfEc90E72b6A2daC9562f458Ba"
RSPD = "0x97AAe66a1D2a41eAC573397B7a5656a9cF3E5616"
MINT = "0xcdafc875eed0f346d5d2584fc6c37b539459c445"

# selector -> name (from cast sig)
probes = {
    "0x4da5fca3": "totalPooledFIL()",
    "0x3a98ef39": "totalShares()",
    "0xf5eb42dc": "sharesOf(address)",
    "0x01608f5f": "amountOf(address)",
    "0x3ba0b9a9": "exchangeRate()",
    "0x817b1cd2": "totalStaked()",
    "0x2e1a7d4d": "withdraw(uint256)",
    "0xd0e30db0": "deposit()",
    "0xd5fc44bf": "sftToken()",
    "0x6ea69d62": "rewardContract()",
    "0x8da5cb5b": "owner()",
    "0xe30c3978": "pendingOwner()",
    "0x78e97925": "startTime()",
    "0xa62b75a8": "slope1()",
    "0xb8522043": "getUserList()",
    "0x18160ddd": "totalSupply()",
    "0x313ce567": "decimals()",
    "0x06fdde03": "name()",
    "0x95d89b41": "symbol()",
    "0x45a7858f": "redeemPool()",
}

# extra getters to compute on the fly
extra_sigs = [
    "borrowThreshold()", "ltv()", "LTV()", "borrowIndex()", "totalBorrowed()",
    "borrowed()", "totalBorrow()", "rewardPerSFT()", "totalReward()",
    "distributor()", "minerCount()", "getMinerList()", "miners(address)",
    "userInfo(address)", "stakes(address)", "orderCount()", "orders(uint256)",
    "getUserOrders(address)", "borrowLimit()", "maxLTV()", "minStakeAmount()",
    "totalClaimed()", "rewardToken()", "totalRewards()", "claimable(address)",
    "pendingReward(address)", "earned(address)", "apr()", "utilization()",
    "getPrice()", "price()", "oracle()", "rewardRate()",
]

def probe(addr, sel, name, cache, arg=None):
    data = sel + (arg or "")
    try:
        r = rpc('eth_call', [{'to': addr, 'data': data}, 'latest'], cache)
        if r and r != '0x':
            return r
        return '<empty>'
    except Exception as e:
        return f'<revert/err>'

def main():
    cache = load_cache()
    print("=== compute extra selectors ===")
    import subprocess
    computed = {}
    for s in extra_sigs:
        try:
            out = subprocess.run(['cast', 'sig', s], capture_output=True, text=True, timeout=15).stdout.strip()
            if out.startswith('0x'):
                computed[out] = s
        except Exception:
            pass
    allprobes = dict(probes)
    allprobes.update(computed)
    for target_name, addr in [('POOL', POOL), ('REWARD', REWARD), ('SFT', SFT), ('RSPD', RSPD), ('MINT', MINT)]:
        print(f"\n===== {target_name} {addr}")
        for sel, name in sorted(allprobes.items(), key=lambda kv: kv[1]):
            r = probe(addr, sel, name, cache)
            print(f"  {name:32s} {sel} -> {r[:80]}")

if __name__ == '__main__':
    main()
