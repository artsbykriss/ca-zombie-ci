#!/usr/bin/env python3
"""Aurora part 2: USN stableswap angle, MasterChef/xTRI/Maker state, WannaSwap enumeration."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

CHAIN = "aurora"
USN = "0x5183e1b1091804bc2602586919e6880ac1cf2896"
USDT = "0x4988a896b1227218e4A686fdE5EabdcAbd91571f"
USDC = "0xB12BFcA5A55806AaF64E99521918A4bf0fC40802"
STABLE = "0x458459E48dbAC0C8Ca83F8D0b7b29FEfE60c3970"
WNEAR_USN = "0xA36DF7c571bEbA7B3fB89F25dFc990EAC75F525A"
MC1 = "0x1f1Ed214bef5E83D8f5d0eB5D7011EB965D0D79B"
MC2 = "0x3838956710bcc9D122Dd23863a0549ca8D5675D6"
XTRI = "0x802119e4e253D5C19aA06A5d567C5a41596D6803"
TRI = "0xFa94348467f64D5A457F75F8bc40495D33c65aBB"
TRIMAKER = "0xe793455c9728fc91A3E5a33FAfF9eB2F228aE151"
PTRI = "0xe559092D2e80d9B1d91a641CE25bACC3cFdCF689"
USDCMAKER = "0x5EBd5e963A00500B6a1234c621811c52AF0aAade"
DAO = "0xf86119de6ee8d4447C8219eEC20E7561d09816d3"

BAL = sel("balanceOf(address)")
GR = sel("getReserves()")
T0 = sel("token0()")
T1 = sel("token1()")
TS = sel("totalSupply()")

def call(to, data):
    return rpc(CHAIN, "eth_call", [{"to": to, "data": data}, "latest"])

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("Aurora block:", int(blk, 16))
    # 1) USN: get_dy variants
    for sig, args in [
        ("get_dy(int128,int128,uint256)", (2, 1, 10**18)),
        ("get_dy(uint8,uint8,uint256)", (2, 1, 10**18)),
    ]:
        s = sel(sig)
        data = s + enc_uint(args[0]) + enc_uint(args[1]) + enc_uint(args[2])
        r = call(STABLE, data)
        print(f"stable {sig} 1 USN->USDT:", r if not isinstance(r, str) or len(r) < 20 else int(r, 16))
    # big trade
    s = sel("get_dy(int128,int128,uint256)")
    for amt in [10**18, 1000*10**18, 10000*10**18, 32705*10**18]:
        r = call(STABLE, s + enc_uint(2) + enc_uint(1) + enc_uint(amt))
        v = int(r, 16) if isinstance(r, str) and r.startswith("0x") and len(r) > 2 else r
        print(f"  get_dy USN->USDT {amt/1e18:.0f} USN => {v if not isinstance(v,int) else v/1e6:.6f} USDT")
    # 2) wNEAR-USN pair
    r = call(WNEAR_USN, GR)
    if isinstance(r, str) and len(r) >= 2 + 192:
        raw = r[2:]
        r0 = int(raw[:64], 16); r1 = int(raw[64:128], 16)
        t0 = call(WNEAR_USN, T0); t1 = call(WNEAR_USN, T1)
        print(f"wNEAR-USN pair reserves: r0={r0} r1={r1}")
        print("  t0:", t0, " t1:", t1)
    else:
        print("wNEAR-USN pair:", r)
    # 3) MasterChef + xTRI + makers
    checks = [
        ("MC1 TRI bal", TRI, BAL + enc_addr(MC1)),
        ("MC1 native", None, MC1),
        ("MC2 TRI bal", TRI, BAL + enc_addr(MC2)),
        ("MC2 native", None, MC2),
        ("xTRI TRI bal", TRI, BAL + enc_addr(XTRI)),
        ("xTRI totalSupply", XTRI, TS),
        ("TRI totalSupply", TRI, TS),
        ("TriMaker TRI bal", TRI, BAL + enc_addr(TRIMAKER)),
        ("TriMaker pTRI bal", PTRI, BAL + enc_addr(TRIMAKER)),
        ("pTRI TRI bal", TRI, BAL + enc_addr(PTRI)),
        ("pTRI totalSupply", PTRI, TS),
        ("USDCMaker USDC bal", USDC, BAL + enc_addr(USDCMAKER)),
        ("DAO TRI bal", TRI, BAL + enc_addr(DAO)),
        ("DAO USDC bal", USDC, BAL + enc_addr(DAO)),
        ("DAO USDT bal", USDT, BAL + enc_addr(DAO)),
        ("DAO WNEAR bal", "0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d", BAL + enc_addr(DAO)),
        ("DAO native", None, DAO),
        ("USN bal in stable pool", USN, BAL + enc_addr(STABLE)),
        ("USDT bal in stable pool", USDT, BAL + enc_addr(STABLE)),
        ("USDC bal in stable pool", USDC, BAL + enc_addr(STABLE)),
    ]
    for label, tok, data in checks:
        if tok is None:
            r = rpc(CHAIN, "eth_getBalance", [data, "latest"])
        else:
            r = call(tok, data)
        v = int(r, 16) if isinstance(r, str) and r.startswith("0x") and len(r) > 2 else r
        print(f"{label:28s} {str(v)[:80]}")
    # 4) WannaSwap factory
    WF = "0x7928D4FeA7b2c90C732c10aFF59cf403f0C38246"
    n = call(WF, sel("allPairsLength()"))
    print("WannaSwap pairs:", int(n, 16) if isinstance(n, str) else n)
    json.dump({"block": int(blk, 16)}, open("/home/heisenberg/CA/aurora-dust/analysis/aurora2.json", "w"))

if __name__ == "__main__":
    main()
