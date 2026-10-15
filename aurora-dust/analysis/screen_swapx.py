#!/usr/bin/env python3
"""swapX (BSC 2023 incident): live allowance residue check."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr

CHAIN = "bsc"
SWAPX = "0x6D8981847Eb3cc2234179d0F0e72F6b6b2421a01"
BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
DND = "0x34EA3F7162E6f6Ed16bD171267eC180fD5c848da"
VICTIMS = [
 "0x0b70e2Abe6F1A056E23658aED1FF9EF9901CB2A3","0x210C9E1d9E0572da30B2b8b9ca57E5e380528534",
 "0x6906f738daFD4Bf14d6e3e979d4Aaf980FF5392D","0x708a34D4C5a7d7fd39eE4DB0593be18df58fd227",
 "0x48ba64b8CBd8BBcE086E8e8ECc6f4De34AA35D08","0xBF57dea8e19022562F002Da6b7bbe2A2DB85c2c0",
 "0x4148b0B927cC8246f65AF9B77dfA84b60565820c","0x57070188BAA313c73fffDbA43c0ABE17fbFB41f9",
 "0x08943873222CE63eC48f8907757928dcb06af388","0x047252B87FB7ecb7e29F8026dd117EB8B8E6cF0f",
 "0x8C51b7BB3f64845912616914455517DF294A0d0B","0x91243b8242f13299C5af661ef5d19bfE0D3bf024",
 "0xfe23ea0CEC98D54A677F4aD3082D64f8A0207eB7","0x54D7AFCaF140fA45Ff5387f0f2954bC913c0796F",
 "0x76bf18aFED5AcCFd59525D10ce15C4B8Cb64370d","0xe5d985b7b934dc0e0E1043Fc11f50ba9E229465C",
]
BAL = sel("balanceOf(address)")
ALLOW = sel("allowance(address,address)")

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("BSC block:", int(blk,16))
    code = rpc(CHAIN, "eth_getCode", [SWAPX, "latest"])
    print("swapX codelen:", len(code)//2-1 if isinstance(code,str) else code)
    # does the exploit selector exist?
    print("has 0x4f1f05bc:", "4f1f05bc" in code if isinstance(code,str) else "?")
    tot = 0
    rows = []
    for v in VICTIMS:
        calls = [("eth_call",[{"to":BUSD,"data":BAL+enc_addr(v)},"latest"]),
                 ("eth_call",[{"to":BUSD,"data":ALLOW+enc_addr(v)+enc_addr(SWAPX)},"latest"]),
                 ("eth_call",[{"to":DND,"data":BAL+enc_addr(v)},"latest"]),
                 ("eth_call",[{"to":DND,"data":ALLOW+enc_addr(v)+enc_addr(SWAPX)},"latest"])]
        res = batch(CHAIN, calls, chunk=4)
        try:
            busd_bal=int(res[0],16); busd_all=int(res[1],16); dnd_bal=int(res[2],16); dnd_all=int(res[3],16)
        except Exception as e:
            print(v, "ERR", str(res)[:80]); continue
        drainable = min(busd_bal, busd_all)
        tot += drainable
        rows.append({"victim":v,"busd_bal":busd_bal,"busd_allowance":busd_all,"dnd_bal":dnd_bal,"dnd_allowance":dnd_all,"drainable_busd_raw":drainable})
        if busd_bal>0 or busd_all>0:
            print(f"{v} BUSD bal={busd_bal/1e18:.6f} allow={busd_all/1e18:.6f} -> drainable={drainable/1e18:.6f} | DND bal={dnd_bal/1e18:.3f} allow={dnd_all/1e18:.3f}")
    print(f"TOTAL drainable BUSD raw: {tot} = {tot/1e18:.6f} BUSD")
    # BUSD price
    import urllib.request
    try:
        with urllib.request.urlopen(urllib.request.Request("https://coins.llama.fi/prices/current/bsc:0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",headers={"User-Agent":"research"}),timeout=30) as r:
            d=json.load(r); print("BUSD price:", (d.get("coins") or {}))
    except Exception as e: print("price err", e)
    json.dump({"block":int(blk,16),"rows":rows}, open("/home/heisenberg/CA/aurora-dust/analysis/swapx-residue.json","w"), indent=1)

if __name__ == "__main__":
    main()
