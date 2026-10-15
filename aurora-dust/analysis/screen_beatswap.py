#!/usr/bin/env python3
"""BeatXswap V3 NFT positions + LPBonus lpaddress; compute position token amounts."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

CHAIN = "bsc"
NFTMGR = "0x46A15B0b27311cedF172AB29E4f4766fbE7F4364"
POOL = "0xA5Db84d7BCcb799fb31bd3c417D04d5bC29Da96D"  # PCS V3 USDT/BTX fee100
LPB = "0x52272524a22f941f5489c1233732797314bb054b"

IDS = [6065537, 7392248, 6065533, 6065577, 7392249]
POS_SEL = sel("positions(uint256)")
SLOT0_SEL = sel("slot0()")

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("BSC block:", int(blk,16))
    calls = [("lpaddress", LPB, sel("lpaddress()"))]
    for i in IDS:
        calls.append((f"positions({i})", NFTMGR, POS_SEL + enc_uint(i)))
    calls.append(("pool slot0", POOL, SLOT0_SEL))
    res = batch(CHAIN, [("eth_call", [{"to": to, "data": d}, "latest"]) for _, to, d in calls], chunk=10)
    out = {}
    for (label, to, d), r in zip(calls, res):
        print(label, "->", str(r)[:120])
        out[label] = r
    json.dump({"block": int(blk,16), "results": out}, open("/home/heisenberg/CA/aurora-dust/analysis/l2-27-beatswap-nft.json","w"), indent=1)

    # decode positions
    import math
    slot0 = out.get("pool slot0")
    if isinstance(slot0, str) and slot0.startswith("0x"):
        words = [int(slot0[2:][i*64:(i+1)*64], 16) for i in range(len(slot0[2:])//64)]
        sqrtP = words[0]
        tick = words[1]
        print("slot0 sqrtPriceX96:", sqrtP, "tick:", tick)
        P = (sqrtP / 2**96) ** 2
        print("price token1/token0:", P, "(token0=USDT, token1=BTX)")
    for i in IDS:
        r = out.get(f"positions({i})")
        if not (isinstance(r, str) and r.startswith("0x")): continue
        w = [int(r[2:][j*64:(j+1)*64], 16) for j in range(len(r[2:])//64)]
        # (nonce, operator, token0, token1, fee, tickLower, tickUpper, liquidity, fg0, fg1, owed0, owed1)
        nonce, operator, t0, t1, fee, tl, tu, liq, fg0, fg1, owed0, owed1 = w
        print(f"NFT {i}: t0={hex(t0)} t1={hex(t1)} fee={fee} ticks=({tl},{tu}) liq={liq} owed0={owed0} owed1={owed1}")
        # amounts at current price (sqrtP)
        if liq > 0 and sqrtP > 0:
            sp = sqrtP / 2**96
            sa = math.sqrt(1.0001**tl)
            sb = math.sqrt(1.0001**tu)
            if sp <= sa:
                a0 = liq * (1/sa - 1/sb)
                a1 = 0
            elif sp < sb:
                a0 = liq * (1/sp - 1/sb)
                a1 = liq * (sp - sa)
            else:
                a0 = 0
                a1 = liq * (sb - sa)
            print(f"   -> amount0(USDT raw)={a0:.0f} amount1(BTX raw)={a1:.0f} | USDT={a0/1e18:.6f} BTX={a1/1e18:.6f}")

if __name__ == "__main__":
    main()
