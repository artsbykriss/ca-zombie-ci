#!/usr/bin/env python3
"""LPBonus/MSN/GDC/BeatXswap deeper live-state screen."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr

CHAIN = "bsc"
GR = sel("getReserves()")
T0 = sel("token0()")
T1 = sel("token1()")

CALLS = [
    # FIST/MSN pair
    ("FIST/MSN pair getReserves", "0xdD95c8a545e98D2c6de4d20abcc44B104da1e6e5", GR),
    ("FIST/MSN pair token0", "0xdD95c8a545e98D2c6de4d20abcc44B104da1e6e5", T0),
    ("FIST/MSN pair token1", "0xdD95c8a545e98D2c6de4d20abcc44B104da1e6e5", T1),
    ("FIST/MSN pair LP totalSupply", "0xdD95c8a545e98D2c6de4d20abcc44B104da1e6e5", sel("totalSupply()")),
    # USDT/FIST FstSwap pair (flash source)
    ("USDT/FIST pair getReserves", "0xb4Ec801aED8C92F2E69589518AAa127afb37d8C9", GR),
    ("USDT/FIST pair token0", "0xb4Ec801aED8C92F2E69589518AAa127afb37d8C9", T0),
    ("USDT/FIST pair token1", "0xb4Ec801aED8C92F2E69589518AAa127afb37d8C9", T1),
    # LPBonus getters
    ("LPBonus oneshareFIST", "0x52272524a22f941f5489c1233732797314bb054b", sel("oneshareFIST()")),
    ("LPBonus MSN bal", "0xd8b3ef86afce18edba91fed481abe22f173597c1", sel("balanceOf(address)") + enc_addr("0x52272524a22f941f5489c1233732797314bb054b")),
    ("LPBonus FIST bal", "0xc9882dEF23bc42D53895b8361D0b1EDC7570Bc6A", sel("balanceOf(address)") + enc_addr("0x52272524a22f941f5489c1233732797314bb054b")),
    # MSN token getters
    ("MSN totalSupply", "0xd8b3ef86afce18edba91fed481abe22f173597c1", sel("totalSupply()")),
    # BeatXswap vesting contracts: V3 NFT positions on PancakeSwap V3 NFT manager
    ("PCS V3 NFTmgr balOf vest1", "0x46A15B0b27311cedF172AB29E4f4766fbE7F4364", sel("balanceOf(address)") + enc_addr("0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D")),
    ("PCS V3 NFTmgr balOf vest2", "0x46A15B0b27311cedF172AB29E4f4766fbE7F4364", sel("balanceOf(address)") + enc_addr("0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F")),
    # BeatXswap vesting: check other getters
    ("vest1 treasury()", "0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D", sel("treasury()")),
    ("vest1 targetPool()", "0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D", sel("targetPool()")),
    ("vest1 BTX bal", "0xAa242a47F4cC074E59cbC7D65309B1F21202AaA3", sel("balanceOf(address)") + enc_addr("0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D")),
    # GDC: token internals
    ("GDC pair token0", "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c", T0),
    ("GDC pair token1", "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c", T1),
    ("GDC pair totalSupply", "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c", sel("totalSupply()")),
    ("GDC totalSupply", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822", sel("totalSupply()")),
    ("GDC swapping()", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822", sel("swapping()")),
    ("GDC swapSellAward()", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822", sel("swapSellAward()")),
]

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("BSC block:", int(blk, 16))
    res = batch(CHAIN, [("eth_call", [{"to": to, "data": data}, "latest"]) for _, to, data in CALLS], chunk=10)
    out = []
    for (label, to, data), r in zip(CALLS, res):
        out.append({"label": label, "to": to, "result": r})
        print(f"{label:36s} -> {str(r)[:100]}")
    json.dump({"block": int(blk, 16), "results": out}, open("/home/heisenberg/CA/aurora-dust/analysis/l2-27-bsc-deep.json", "w"), indent=1)

if __name__ == "__main__":
    main()
