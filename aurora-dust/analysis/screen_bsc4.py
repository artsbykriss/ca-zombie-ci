#!/usr/bin/env python3
"""LPBonus state getters + BeatXswap NFT positions + GDC extra reads."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

CHAIN = "bsc"
LPB = "0x52272524a22f941f5489c1233732797314bb054b"
NFTMGR = "0x46A15B0b27311cedF172AB29E4f4766fbE7F4364"

# BeatXswap NFT token ids: find via Transfer events? First check balance + use tokenOfOwnerByIndex
CALLS = [
    ("LPBonus userAddAmount(0xdead)", LPB, sel("userAddAmount(address)") + enc_addr("0x000000000000000000000000000000000000dEaD")),
    ("LPBonus takedFIST(0xdead)", LPB, sel("takedFIST(address)") + enc_addr("0x000000000000000000000000000000000000dEaD")),
    ("LPBonus CalcPendingUser(0xdead,1e18)", LPB, sel("CalcPendingUser(address,uint256)") + enc_addr("0x000000000000000000000000000000000000dEaD") + enc_uint(10**18)),
    ("LPBonus totalUserAmount()", LPB, sel("totalUserAmount()")),
    ("LPBonus MSNtoken()", LPB, sel("MSNtoken()")),
    ("LPBonus FISTtoken()", LPB, sel("FISTtoken()")),
    ("LPBonus pair()", LPB, sel("pair()")),
    # NFT manager: tokenOfOwnerByIndex
    ("vest1 NFT id 0", NFTMGR, sel("tokenOfOwnerByIndex(address,uint256)") + enc_addr("0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D") + enc_uint(0)),
    ("vest1 NFT id 1", NFTMGR, sel("tokenOfOwnerByIndex(address,uint256)") + enc_addr("0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D") + enc_uint(1)),
    ("vest2 NFT id 0", NFTMGR, sel("tokenOfOwnerByIndex(address,uint256)") + enc_addr("0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F") + enc_uint(0)),
    ("vest2 NFT id 1", NFTMGR, sel("tokenOfOwnerByIndex(address,uint256)") + enc_addr("0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F") + enc_uint(1)),
    ("vest2 NFT id 2", NFTMGR, sel("tokenOfOwnerByIndex(address,uint256)") + enc_addr("0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F") + enc_uint(2)),
]

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("BSC block:", int(blk,16))
    res = batch(CHAIN, [("eth_call", [{"to": to, "data": data}, "latest"]) for _, to, data in CALLS], chunk=10)
    out=[]
    for (label, to, data), r in zip(CALLS, res):
        v = int(r,16) if isinstance(r,str) and r.startswith("0x") and len(r)>2 else r
        out.append({"label":label,"result":r})
        print(f"{label:36s} -> {str(v)[:90]}")
    json.dump({"block":int(blk,16),"results":out}, open("/home/heisenberg/CA/aurora-dust/analysis/l2-27-lpbonus-nft.json","w"), indent=1)

if __name__=="__main__":
    main()
