#!/usr/bin/env python3
"""Direct eth_getCode check for a list of tokens (chain, addr) pairs."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

JOBS = {
    "base": [
        # top E-U candidates' junk tokens
        "0x38f04e34b3e6f11c2bdf7a19d6558b3473c61362",
        "0x4af5901defa0a57460590ddfae8dd635e9ef0948",
        "0xbeb3daaab0df83f0632dcfb40c6b33ad58e662e7",
        "0x5abd3b0c51acb17842d1eb26be2ab6726989c4f3",
        "0x782619719c97e77b6a6b145b32b018ed64ac5c76",
        "0x4a278e5bcc8d89d5c6acef81e002c191aae0e409",
        "0x9f779b3147ffd2af436366ea113a521583e2ea7a",
        "0x7e9ad461a4d385e9386a6c2482ca2ba7e32f6dd0",
        # suspected codeless ones
        "0x0069b18587e93d508421f1120930406439b53bdb",
        "0x33495b63ae76cd58c8643bd69c835f459144c67f",
        "0xa4535efd0cd7c01b710e1c6e0bc0293c0e3fc064",
        "0x7ceb5fdff59d27b333165e513020877f210da694",
        # WETH
        "0x4200000000000000000000000000000000000006",
    ],
    "linea": [
        "0xd820483a7b345352d063b191942aeb781e8b5aa0",
        "0xcc23e2062d0a82cdca4ebaa2110a6bb6ee2f910b",
        "0xaadc008159375e88e078fef2358caf9a273f1ab4",
        "0x7d43aabc515c356145049227cee54b608342c0ad",
        "0xd4250f9429a781778f97d389c27005cef03ff9e6",
        "0x327195e38da328598e25a604559bc46fdd63b704",
        "0x5cfd7c3406d19046378da7ed5463d4a0b6dda680",
        "0x34be4f01b28f9679135a380a96f96ae34cfa1376",
        "0xdf0d02351a3e7a21d3936cf1cfd1ee554cee0a80",
        "0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f",
    ],
}

for chain, addrs in JOBS.items():
    print("="*40, chain, flush=True)
    calls = [("eth_getCode", [a, "latest"]) for a in addrs]
    try:
        r = B.batch(chain, calls)
        for a, c in zip(addrs, r):
            print(f"  {a} code_size={(len(c)-2)//2 if c else 'ERR'}", flush=True)
    except Exception as e:
        print("  batch fail", str(e)[:120], flush=True)
