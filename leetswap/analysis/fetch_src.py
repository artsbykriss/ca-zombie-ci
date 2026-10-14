#!/usr/bin/env python3
"""Fetch verified sources for LeetSwap contracts across chains (Etherscan V2)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from es import source, es

TARGETS = [
    # (chainid, addr, name)
    (59144, "0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c", "linea_factory"),
    (59144, "0x3bc53c353cb117d616c9e51811b2aa2a818c5db3", "linea_pair_top"),
    (204, "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "opbnb_factory"),
    (204, "0x3e5b8c9e1c98a457b68a4337897a8f6020725e18", "opbnb_pair_wbnb"),
    (169, "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "manta_factory"),
    (169, "0xf5f8a569483663e9f7227d16e4ec21de9e729f93", "manta_pair_weth"),
    (8453, "0x169C06b4cfB09bFD73A81e6f2Bb1eB514D75bB19", "base_factory"),
    (8453, "0xcc7697937ca14d59bcb0f2ef6ddcf6a82627cd3c", "base_pair_sample"),
    (1101, "0xcE87E0960f4e2702f4bFFE277655E993Ae720e84", "zkevm_factory"),
    (1101, "0xc6e70676eaeac6ef0c51cc618fc71a717d68b572", "zkevm_pair_top"),
    (534352, "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "scroll_factory"),
    (534352, "0xb355bf1016184de795c786baa78d2cf5fb1165da", "scroll_pair_top"),
    (109, "0xd3Ea3BC1F5A3F881bD6cE9761cbA5A0833a5d737", "shibarium_factory"),
    (109, "0xdd12d8f1f05e534957e85d8d44364c50f7556251", "shibarium_pair_top"),
    (7700, "0x116e8a41E8B0A5A87058AF110C0Ddd55a0ed82B7", "canto_factory"),
]

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
os.makedirs(OUT, exist_ok=True)

for cid, addr, name in TARGETS:
    path = os.path.join(OUT, name + ".json")
    if os.path.exists(path):
        print("skip", name); continue
    t0 = time.time()
    try:
        s = source(cid, addr)
        s["chainid"] = cid
        s["address"] = addr
        json.dump(s, open(path, "w"), indent=1)
        print(f"{name}: name={s.get('name')} verified={s.get('verified')} proxy={s.get('proxy')} ({int(time.time()-t0)}s)")
    except Exception as e:
        print(f"{name}: FAIL {str(e)[:120]} ({int(time.time()-t0)}s)")
    time.sleep(0.5)
print("done")
