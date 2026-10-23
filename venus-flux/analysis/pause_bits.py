#!/usr/bin/env python3
"""Read-only: decode Fluid Liquidity per-user pause bits (bit 255) for BSC Venus Flux.

User-supply config bit 255 = isUserPaused (supply); user-borrow config bit 255 = isUserPaused (borrow).
Slot = keccak256(abi.encode(token, keccak256(abi.encode(user, doubleMappingSlot))))
  supply double-mapping slot = 8, borrow double-mapping slot = 9.
"""
import sys
from web3 import Web3
from eth_abi import encode

RPCS = ["https://bsc-rpc.publicnode.com", "https://bsc-dataseed.binance.org", "https://1rpc.io/bnb"]
LIQ = "0x52Aa899454998Be5b000Ad077a46Bbe360F4e497"
w3 = None
for r in RPCS:
    try:
        w = Web3(Web3.HTTPProvider(r, request_kwargs={"timeout": 40}))
        w.eth.block_number
        w3 = w; print("rpc", r); break
    except Exception:
        continue

def keccak(b):
    return Web3.keccak(b)

def slot(user, token, mapping):
    inter = keccak(encode(["address", "uint256"], [Web3.to_checksum_address(user), mapping]))
    return keccak(encode(["address", "bytes32"], [Web3.to_checksum_address(token), inter]))

def read(s):
    return int.from_bytes(w3.eth.get_storage_at(Web3.to_checksum_address(LIQ), s), "big")

WSTUSR = "0x4254813524695def4163A169e901f3d7a1a55429"
USDT = "0x55d398326f99059fF775485246999027B3197955"
USDC = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"
SYRUP = "0x8E9d4cEa39299323FE8eda678cAD449718556c4e"

users = {
    "T1 wstUSR/USDT vault": "0x3996464c0fCCa8183e13ea5E5e74375e2c8744Dd",
    "T1 wstUSR/USDC vault": "0xeAEf563015634a9d0EE6CF1357A3b205C35e028D",
    "T2 wstUSR/USDT vault": "0xF74cb9D69ada3559903149CFD60fD57cEAF95F30",
    "wstUSR/USDT DEX": "0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7",
    "T1 syrupUSDT/USDT vault": "0x82B27fA821419F5689381b565a8B0786aA2548De",
    "T3 syrupUSDT vault": "0xE6b5D1CdC4935295c84772C4700932b4BFC93274",
}
tokens = {"wstUSR": WSTUSR, "syrupUSDT": SYRUP, "USDT": USDT, "USDC": USDC}

print(f"{'user':28s} {'token':10s} {'supplyPaused':12s} {'borrowPaused':12s}")
for un, u in users.items():
    for tn, t in tokens.items():
        sv = read(slot(u, t, 8))
        bv = read(slot(u, t, 9))
        sp = (sv >> 255) & 1
        bp = (bv >> 255) & 1
        if sv or bv:
            print(f"{un:28s} {tn:10s} {sp:12d} {bp:12d}")
