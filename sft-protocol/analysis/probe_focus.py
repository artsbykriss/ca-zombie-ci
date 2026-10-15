#!/usr/bin/env python3
"""Focused probe: key getters on POOL + REWARD + tokens. Cache-aware (fast reruns)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fc import rpc, load_cache

TARGETS = {
    'POOL': "0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E",
    'REWARD': "0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7",
    'SFT': "0xC5eA96Dd365983cfEc90E72b6A2daC9562f458Ba",
    'RSPD': "0x97AAe66a1D2a41eAC573397B7a5656a9cF3E5616",
    'MINT': "0xcdafc875eed0f346d5d2584fc6c37b539459c445",
}

probes = [
    ("0x8da5cb5b", "owner()", None),
    ("0xe30c3978", "pendingOwner()", None),
    ("0xd5fc44bf", "sftToken()", None),
    ("0x6ea69d62", "rewardContract()", None),
    ("0xbfe10928", "distributor()", None),
    ("0x78e97925", "startTime()", None),
    ("0x3197cbb6", "endTime()", None),
    ("0x5ae547e3", "borrowThreshold()", None),
    ("0x6fb49d73", "ltv()", None),
    ("0xa62b75a8", "slope1()", None),
    ("0x4da5fca3", "totalPooledFIL()", None),
    ("0x4a417a53", "getUtilizationRate()", None),
    ("0x45a7858f", "redeemPool()", None),
    ("0x18160ddd", "totalSupply()", None),
    ("0xb8522043", "getUserList()", None),
    ("0x70a08231", "balanceOf(POOL)", "0x000000000000000000000000147122d1ebda76e4910ccdc53aeb6a58605eb58e"),
    ("0x70a08231", "balanceOf(REWARD)", "0x000000000000000000000000e86d3dbd8233f1bfa22679cb57fab3428e9654f7"),
    ("0xf5eb42dc", "sharesOf(0xdead)", "0x000000000000000000000000000000000000000000000000000000000000dead"),
    ("0x2e1a7d4d", "withdraw(0) [static probe]", "0x0000000000000000000000000000000000000000000000000000000000000000"),
    ("0x940a4e45", "distributeReward(0) [static probe]", "0x0000000000000000000000000000000000000000000000000000000000000000"),
    ("0x0ecbcdab", "borrow(0,0) [static probe]", "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),
]

def fmt(r):
    if isinstance(r, str) and r.startswith('__REVERT__'):
        return r[:100]
    if isinstance(r, str) and r.startswith('0x'):
        if len(r) == 66:
            return f"{r} (uint={int(r,16)})"
        return r[:100] + (f" (len {(len(r)-2)//2} bytes)" if len(r) > 2 else "")
    return str(r)[:100]

def main():
    cache = load_cache()
    for tname, addr in TARGETS.items():
        print(f"\n===== {tname} {addr}")
        for sel, name, arg in probes:
            data = sel + (arg or "")
            try:
                r = rpc('eth_call', [{'to': addr, 'data': data}, 'latest'], cache)
            except Exception as e:
                r = f'<transport err {str(e)[:60]}>'
            print(f"  {name:34s} -> {fmt(r)}")

if __name__ == '__main__':
    main()
