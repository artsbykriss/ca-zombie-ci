#!/usr/bin/env python3
"""L2-27 screens: Ethereum (OrderFactory, Reddio RSV, Startale) + HyperEVM (Prime)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr

BAL = sel("balanceOf(address)")

ETH_CALLS = [
    # OrderFactory incident (Ethereum)
    ("OrderFactory: native", None, "0xa27bcd590195b2a9bdc29379de4f040b2d8066e0", None),
    ("AccountSystem: native", None, "0xfcf3d97c6db4c3bf6020a2b99af074b595bda163", None),
    ("OrderFactory code len", "eth_getCode", "0xa27bcd590195b2a9bdc29379de4f040b2d8066e0", None),
    ("AccountSystem code len", "eth_getCode", "0xfcf3d97c6db4c3bf6020a2b99af074b595bda163", None),
    ("Deployer code len", "eth_getCode", "0xdd3068d772764443e4c4b18b8c96aee153d83056", None),
    # Reddio RSV diamond (Ethereum)
    ("RSV diamond: native", None, "0x4315990D9eeAFFdFAfD49958b4851F203FA1126f", None),
    ("RSV: WETH bal", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0x4315990D9eeAFFdFAfD49958b4851F203FA1126f", BAL),
    ("RSV: stETH bal", "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84", "0x4315990D9eeAFFdFAfD49958b4851F203FA1126f", BAL),
    ("RSV: USDC bal", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "0x4315990D9eeAFFdFAfD49958b4851F203FA1126f", BAL),
    ("RSV: USDT bal", "0xdAC17F958D2ee523a2206206994597C13D831ec7", "0x4315990D9eeAFFdFAfD49958b4851F203FA1126f", BAL),
    # Startale (Ethereum)
    ("Startale factory code len", "eth_getCode", "0x0000003B3E7b530b4f981aE80d9350392Defef90", None),
    ("Startale impl code len", "eth_getCode", "0x000000b8f5f723A680d3D7EE624Fe0bC84a6E05A", None),
    ("Startale USDC bal", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "0x0000003B3E7b530b4f981aE80d9350392Defef90", BAL),
    ("Startale USDT bal", "0xdAC17F958D2ee523a2206206994597C13D831ec7", "0x0000003B3E7b530b4f981aE80d9350392Defef90", BAL),
    ("Startale collector USDC", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "0xe2719E3b28EeF69bf3C4A9D7FC7280c5a015EcdE", BAL),
    ("Startale collector native", None, "0xe2719E3b28EeF69bf3C4A9D7FC7280c5a015EcdE", None),
]

HYP_CALLS = [
    ("Prime pool: native", None, "0xb339448E13E273f6F46e3390e0932Ab7fF9F113F", None),
    ("aWHYPE: WHYPE bal", "0x5555555555555555555555555555555555555555", "0xCF4642EF89683D0299B59738b1Cc3AC0177348Ba", BAL),
    ("aWHYPE: native", None, "0xCF4642EF89683D0299B59738b1Cc3AC0177348Ba", None),
    ("WHYPE/PRFI pool: WHYPE", "0x5555555555555555555555555555555555555555", "0x981F145a71Da6DF4A7cBe892807782c9CC9a5515", BAL),
    ("WHYPE/PRFI pool: PRFI", "0x7BBCf1B600565AE023a1806ef637Af4739dE3255", "0x981F145a71Da6DF4A7cBe892807782c9CC9a5515", BAL),
    ("PRFI: WHYPE bal", "0x5555555555555555555555555555555555555555", "0x7BBCf1B600565AE023a1806ef637Af4739dE3255", BAL),
    ("DataStreamConsumer code len", "eth_getCode", "0x04EDBF3904789d80B0C991e0B66577F2208A2bE6", None),
    ("Prime pool code len", "eth_getCode", "0xb339448E13E273f6F46e3390e0932Ab7fF9F113F", None),
]

def run(chain, calls):
    blk = rpc(chain, "eth_blockNumber", [])
    print(f"== {chain} block:", int(blk, 16) if isinstance(blk, str) else blk)
    reqs = []
    for label, token, addr, data in calls:
        if token is None:
            reqs.append(("eth_getBalance", [addr, "latest"]))
        elif token == "eth_getCode":
            reqs.append(("eth_getCode", [addr, "latest"]))
        else:
            reqs.append(("eth_call", [{"to": token, "data": data + enc_addr(addr)}, "latest"]))
    res = batch(chain, reqs, chunk=10)
    out = []
    for (label, token, addr, data), r in zip(calls, res):
        if isinstance(r, str) and r.startswith("0x") and token in (None, "eth_getCode"):
            v = len(r) // 2 - 1 if token == "eth_getCode" else int(r, 16)
        elif isinstance(r, str) and r.startswith("0x"):
            v = int(r, 16)
        else:
            v = r
        out.append({"label": label, "addr": addr, "value": v})
        print(f"{label:32s} -> {str(v)[:80]}")
    return {"block": int(blk, 16), "results": out}

if __name__ == "__main__":
    out = {"ethereum": run("ethereum", ETH_CALLS), "hyperevm": run("hyperevm", HYP_CALLS)}
    json.dump(out, open("/home/heisenberg/CA/aurora-dust/analysis/l2-27-eth-hyp.json", "w"), indent=1)
