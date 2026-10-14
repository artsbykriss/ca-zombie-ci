#!/usr/bin/env python3
"""opBNB/Manta LEET ecosystem checks: owner contract, other DEX factories, holder tally."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

LEET_OP = "0xf2f41fe10d53e15ba34e410987eb0f986ec7509f"
LEET_MANTA = "0xe650686a3b474c01fbb5ad3b07ecc44093356090"
WBNB = "0x4200000000000000000000000000000000000006"
WETH_MANTA = "0x0dc808adce2099a9f62aa87d9670745aba741746"
OWNER_OP = "0x8d326e13db0f63351a694e6cd2e309170827494c"
OWNER_MANTA = "0x151df330a47f272cdaa5c2acf57e308d5931f110"

# candidate DEX factories on opBNB
OPBNB_FACTORIES = {
    "pancake_v2": "0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E",
    "thena": "0x9f3E6B0e0a0e0a0e0a0e0a0e0a0e0a0e0a0e0a0e",  # placeholder
    "uniswap_v2_fork?": "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
    "leetswap_univ2": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
}
SEL_GETPAIR = "0xe6a43905"
SEL_SYMBOL = "0x95d89b41"
SEL_DEC = "0x313ce567"
SEL_TS = "0x18160ddd"
SEL_OWNER = "0x8da5cb5b"
SEL_PENDING = "0x9a408321"  # pendingLeet? unknown; skip

def main():
    print("== opBNB ==", flush=True)
    calls = []
    # owner contract code + name
    calls.append(("eth_getCode", [OWNER_OP, "latest"]))
    # factories getPair(LEET, WBNB)
    for name, f in OPBNB_FACTORIES.items():
        calls.append(("eth_call", [{"to": f, "data": SEL_GETPAIR + B.pad_addr(LEET_OP) + B.pad_addr(WBNB)}, "latest"]))
    # LEET basics
    calls += [
        ("eth_call", [{"to": LEET_OP, "data": SEL_TS}, "latest"]),
        ("eth_call", [{"to": LEET_OP, "data": SEL_OWNER}, "latest"]),
    ]
    try:
        r = B.batch("op_bnb", calls)
        print("owner_contract code_size:", (len(r[0]) - 2) // 2 if r[0] else 0)
        i = 1
        for name in OPBNB_FACTORIES:
            v = r[i]
            print(f"  {name} getPair(LEET,WBNB) ->", B.dec_addr(B.words(v)[0]) if v and v != "0x" else v)
            i += 1
        print("LEET totalSupply:", B.dec_uint(B.words(r[i])[0]) / 1e18 if r[i] else None)
        print("LEET owner:", B.dec_addr(B.words(r[i+1])[0]) if r[i+1] else None)
    except Exception as e:
        print("opBNB batch fail", str(e)[:150])
    # owner contract probes: is it a farm? check common farm selectors
    print("-- owner contract probes")
    farm_sels = {
        "poolLength()": "0x081e3eda",
        "totalAllocPoint()": "0x17caf6f1",
        "leetPerBlock()": "0x8ae39cac",
        "rewardPerBlock()": "0x8ae39cac",
        "owner()": "0x8da5cb5b",
        "stakingToken()": "0x72f702f3",
        "rewardToken()": "0x0a2c9d9c",
    }
    try:
        r = B.batch("op_bnb", [("eth_call", [{"to": OWNER_OP, "data": s}, "latest"]) for s in farm_sels.values()])
        for (name, _), v in zip(farm_sels.items(), r):
            if v and v != "0x":
                ws = B.words(v)
                print(f"  {name} = {B.dec_uint(ws[0]) if len(v)==66 else v[:40]}")
            else:
                print(f"  {name} ABSENT")
    except Exception as e:
        print("  probe fail", str(e)[:120])

if __name__ == "__main__":
    main()
