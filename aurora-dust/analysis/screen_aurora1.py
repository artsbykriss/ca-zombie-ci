#!/usr/bin/env python3
"""Aurora screen: Trisolaris factory pairs + stableswap pools + WannaSwap factory."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

CHAIN = "aurora"
TRI_FACTORY = "0xc66F594268041dB60507F00703b152492fb176E7"
TRI_STABLE = [
    ("USDC/USDT/USN", "0x458459E48dbAC0C8Ca83F8D0b7b29FEfE60c3970"),
    ("USDC/USDT", "0x13e7a001EC72AB30D66E2f386f677e25dCFF5F59"),
    ("nUSD-USDC/USDT", "0x3CE7AAD78B9eb47Fd2b487c463A17AAeD038B7EC"),
]
WANNA_FACTORY = "0x792edAdE80af5fC680d96a2eD80A44247D2Cf6Fd"  # to verify

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("Aurora block:", int(blk,16) if isinstance(blk,str) else blk)
    # factory checks
    for name, addr in [("TRI factory", TRI_FACTORY), ("Wanna factory", WANNA_FACTORY)]:
        code = rpc(CHAIN, "eth_getCode", [addr, "latest"])
        print(f"{name} {addr} codelen={len(code)//2-1 if isinstance(code,str) else code}")
        if isinstance(code, str) and len(code) > 2:
            n = rpc(CHAIN, "eth_call", [{"to": addr, "data": sel("allPairsLength()")}, "latest"])
            print("  allPairsLength:", int(n,16) if isinstance(n,str) else n)
    # stableswap pools: balances of their tokens
    TOK = {
        "USDT_e": "0x4988a896b1227218e4A686fdE5EabdcAbd91571f",
        "USDC_e": "0xB12BFcA5A55806AaF64E99521918A4bf0fC40802",
        "USN": "0x5183e1b1091804bc2602586919e6880ac1cf2896",
        "nUSD": "0x07379565cD8B0CaE7c60Dc78e7f601b34AF2A21c",
        "WNEAR": "0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d",
        "TRI": "0xFa94348467F64D5A457F75F8bc40495D33c65aBB",
        "WANNA": "0x7faA64Faf54750a2E3e621b46CeaFc0F145e46c8",
        "AURORA": "0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79",
    }
    calls = []
    for name, addr in TRI_STABLE:
        for tname, taddr in TOK.items():
            calls.append((f"{name}:{tname}", taddr, sel("balanceOf(address)") + enc_addr(addr)))
    res = batch(CHAIN, [("eth_call", [{"to": t, "data": d}, "latest"]) for _, t, d in calls], chunk=10)
    for (label, t, d), r in zip(calls, res):
        v = int(r,16) if isinstance(r,str) and r.startswith("0x") and len(r)>2 else r
        if isinstance(v,int) and v>0:
            print(f"{label:30s} raw={v} (/{10**18}={v/1e18:.6f})")
    json.dump({"block": int(blk,16) if isinstance(blk,str) else blk,
               "stable": [{"label": l, "result": r} for (l,_,_),r in zip(calls,res)]},
              open("/home/heisenberg/CA/aurora-dust/analysis/aurora-stable.json","w"), indent=1)

if __name__ == "__main__":
    main()
