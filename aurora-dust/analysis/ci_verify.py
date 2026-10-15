#!/usr/bin/env python3
"""CI verification: re-read the key live state for the aurora-dust sweep at a pinned block.

Read-only, public RPCs only. Writes ci-out/state-verification.json.
Targets: L2-24 Trisolaris/WannaSwap (Aurora), L2-26 LuigiSwap/SpookySwap/Intercroneswap,
L2-27 victims (LPBonus/MSN, PositionManager, GDC, BeatXswap, DHC, Unifi, OrderFactory,
Reddio RSV, Prime, Startale, swapX approvals).
"""
import sys, json, urllib.request, hashlib, time

sys.path.insert(0, "analysis")
from rpclib import rpc, batch, sel, enc_addr  # noqa: E402

OUT = {"generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "blocks": {}, "checks": []}

def note(name, value, chain=None, addr=None, detail=None):
    OUT["checks"].append({"name": name, "value": str(value), "chain": chain, "address": addr, "detail": detail})
    print(f"  {name}: {value}")

def call(chain, to, data):
    r = rpc(chain, "eth_call", [{"to": to, "data": data}, "latest"])
    try:
        return int(r, 16)
    except Exception:
        return r

def main():
    # ---------- Aurora: Trisolaris / WannaSwap ----------
    print("== Aurora (Trisolaris/WannaSwap)")
    blk = int(rpc("aurora", "eth_blockNumber", []), 16)
    OUT["blocks"]["aurora"] = blk
    tri_factory = "0xc66F594268041dB60507F00703b152492fb176E7"
    n = call("aurora", tri_factory, sel("allPairsLength()"))
    note("Trisolaris factory pairs", n, "aurora", tri_factory)
    # top pair spot check: wNEAR/WETH
    p = "0x63da4db6ef4e7c62168ab03982399f9588fcd198"
    g = rpc("aurora", "eth_call", [{"to": p, "data": sel("getReserves()")}, "latest"])
    if isinstance(g, str) and len(g) >= 2 + 192:
        raw = g[2:]
        r0 = int(raw[:64], 16); r1 = int(raw[64:128], 16)
        b0 = call("aurora", "0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d", sel("balanceOf(address)") + enc_addr(p))
        b1 = call("aurora", "0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB", sel("balanceOf(address)") + enc_addr(p))
        note("wNEAR/WETH pair reserves==balances", f"{r0}=={b0}, {r1}=={b1}", "aurora", p)
    # USN stableswap
    st = "0x458459E48dbAC0C8Ca83F8D0b7b29FEfE60c3970"
    q = call("aurora", st, sel("calculateSwap(uint8,uint8,uint256)") + "0"*63 + "2" + "0"*63 + "1" + format(10**18, "064x"))
    note("USN stableswap 1 USN -> USDT (wei)", q, "aurora", st)
    # WannaSwap
    wf = "0x7928D4FeA7b2c90C732c10aFF59cf403f0C38246"
    note("WannaSwap factory pairs", call("aurora", wf, sel("allPairsLength()")), "aurora", wf)

    # ---------- BSC: L2-27 + L2-26 ----------
    print("== BSC")
    blk = int(rpc("bsc", "eth_blockNumber", []), 16)
    OUT["blocks"]["bsc"] = blk
    # LPBonus
    LPB = "0x52272524a22f941f5489c1233732797314bb054b"
    FIST = "0xc9882dEF23bc42D53895b8361D0b1EDC7570Bc6A"
    PAIR = "0xdD95c8a545e98D2c6de4d20abcc44B104da1e6e5"
    note("LPBonus FIST balance (raw 6dec)", call("bsc", FIST, sel("balanceOf(address)") + enc_addr(LPB)), "bsc", LPB)
    note("LPBonus oneshareFIST", call("bsc", LPB, sel("oneshareFIST()")), "bsc", LPB)
    note("LPBonus registered LP count", call("bsc", LPB, sel("getTotalLPContainer()")), "bsc", LPB)
    g = rpc("bsc", "eth_call", [{"to": PAIR, "data": sel("getReserves()")}, "latest"])
    if isinstance(g, str) and len(g) >= 2 + 192:
        raw = g[2:]
        note("FIST/MSN pair reserves", f"FIST={int(raw[:64],16)} MSN={int(raw[64:128],16)}", "bsc", PAIR)
    # MSN token holds
    MSN = "0xd8b3ef86afce18edba91fed481abe22f173597c1"
    USDT = "0x55d398326f99059fF775485246999027B3197955"
    note("MSN token FIST balance (raw 6dec)", call("bsc", FIST, sel("balanceOf(address)") + enc_addr(MSN)), "bsc", MSN)
    note("MSN token USDT balance (raw 18dec)", call("bsc", USDT, sel("balanceOf(address)") + enc_addr(MSN)), "bsc", MSN)
    # GDC
    GDC = "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822"
    GPAIR = "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c"
    WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    note("GDC stage1Ended()", call("bsc", GDC, sel("stage1Ended()")), "bsc", GDC)
    note("GDC deflationStopped()", call("bsc", GDC, sel("deflationStopped()")), "bsc", GDC)
    g = rpc("bsc", "eth_call", [{"to": GPAIR, "data": sel("getReserves()")}, "latest"])
    if isinstance(g, str) and len(g) >= 2 + 192:
        raw = g[2:]
        note("GDC pair reserves", f"WBNB={int(raw[:64],16)} GDC={int(raw[64:128],16)}", "bsc", GPAIR)
    note("GDC pair WBNB balance", call("bsc", WBNB, sel("balanceOf(address)") + enc_addr(GPAIR)), "bsc", GPAIR)
    # PositionManager
    PM = "0x7cedB2e5d7791c7D46c5C9d35EaC4775bc887F00"
    note("PositionManager USDT balance (raw 18dec)", call("bsc", USDT, sel("balanceOf(address)") + enc_addr(PM)), "bsc", PM)
    # BeatXswap vesting paused + NFT counts
    NFTM = "0x46A15B0b27311cedF172AB29E4f4766fbE7F4364"
    for v in ["0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D", "0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F"]:
        note(f"BeatXswap vesting paused()", call("bsc", v, sel("paused()")), "bsc", v)
        note(f"BeatXswap vesting V3 NFT count", call("bsc", NFTM, sel("balanceOf(address)") + enc_addr(v)), "bsc", v)
    # DHC proxy
    DHC = "0x743F15f4d2481774d970f286f0EbAD9C3Daed6E9"
    DHCP = "0xe2a047aaDbac51b0116Af1cE91EbdAe4b4202094"
    note("DHC proxy DHC balance (raw 18dec)", call("bsc", DHC, sel("balanceOf(address)") + enc_addr(DHCP)), "bsc", DHCP)
    # Unifi manager
    UP = "0x36F20660b9947929Ab3edd8727B5Af60260333A7"
    UM = "0x5D8aA15505aFEc01Bab0dE21F9377673B5246EAE"
    note("Unifi reward manager UP balance (raw 18dec)", call("bsc", UP, sel("balanceOf(address)") + enc_addr(UM)), "bsc", UM)
    # swapX approval residue
    SWAPX = "0x6D8981847Eb3cc2234179d0F0e72F6b6b2421a01"
    BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
    victims = ["0x0b70e2Abe6F1A056E23658aED1FF9EF9901CB2A3", "0x6906f738daFD4Bf14d6e3e979d4Aaf980FF5392D",
               "0x48ba64b8CBd8BBcE086E8e8ECc6f4De34AA35D08", "0xe5d985b7b934dc0e0E1043Fc11f50ba9E229465C"]
    tot_drain = 0
    for v in victims:
        b = call("bsc", BUSD, sel("balanceOf(address)") + enc_addr(v))
        a = call("bsc", BUSD, sel("allowance(address,address)") + enc_addr(v) + enc_addr(SWAPX))
        try: tot_drain += min(int(b), int(a))
        except Exception: pass
    note("swapX drainable BUSD across 4 largest-allowance victims (raw)", tot_drain, "bsc", SWAPX)
    # LuigiSwap opBNB
    print("== opBNB")
    blk = int(rpc("opbnb", "eth_blockNumber", []), 16)
    OUT["blocks"]["opbnb"] = blk
    LF = "0x0dAe6d22182c20AB9150a4DCB3160591Dc41027a"
    note("LuigiSwap opBNB pairs", call("opbnb", LF, sel("allPairsLength()")), "opbnb", LF)
    p = "0xc948161f0eb0979a783388dc3c7744e7b67d7d63"
    g = rpc("opbnb", "eth_call", [{"to": p, "data": sel("getReserves()")}, "latest"])
    if isinstance(g, str) and len(g) >= 2 + 192:
        raw = g[2:]
        note("LuigiSwap sample pair reserves", f"r0={int(raw[:64],16)} r1={int(raw[64:128],16)}", "opbnb", p)
    # phantom-reserve pair
    ph = "0xf9e165b4c7edda48097b5c2d31d9a687c0b6451d"
    g = rpc("opbnb", "eth_call", [{"to": ph, "data": sel("getReserves()")}, "latest"])
    wb = "0x4200000000000000000000000000000000000006"
    b = call("opbnb", wb, sel("balanceOf(address)") + enc_addr(ph))
    if isinstance(g, str) and len(g) >= 2 + 192:
        raw = g[2:]
        note("LuigiSwap phantom pair reserve vs balance", f"reserve0={int(raw[:64],16)} balance={b}", "opbnb", ph)
    # BTTC
    print("== BTTC")
    blk = int(rpc("bttc", "eth_blockNumber", []), 16)
    OUT["blocks"]["bttc"] = blk
    SF = "0xEE4bC42157cf65291Ba2FE839AE127e3Cc76f741"
    note("SpookySwap BTTC pairs", call("bttc", SF, sel("allPairsLength()")), "bttc", SF)
    IF = "0x0cEE0dFb5C680e3CcAA46FA28D5057f204E24F0a"
    note("Intercroneswap BTTC pairs", call("bttc", IF, sel("allPairsLength()")), "bttc", IF)
    # ---------- Ethereum ----------
    print("== Ethereum")
    blk = int(rpc("ethereum", "eth_blockNumber", []), 16)
    OUT["blocks"]["ethereum"] = blk
    note("OrderFactory native balance", call("ethereum", "0xa27bcd590195b2a9bdc29379de4f040b2d8066e0", "0x") if False else rpc("ethereum", "eth_getBalance", ["0xa27bcd590195b2a9bdc29379de4f040b2d8066e0", "latest"]), "ethereum", "0xa27bcd590195b2a9bdc29379de4f040b2d8066e0")
    RSV = "0x4315990D9eeAFFdFAfD49958b4851F203FA1126f"
    note("Reddio RSV USDT balance (raw 6dec)", call("ethereum", "0xdAC17F958D2ee523a2206206994597C13D831ec7", sel("balanceOf(address)") + enc_addr(RSV)), "ethereum", RSV)
    note("rsvUSDT totalSupply", call("ethereum", "0x2e5d4e2a2336045471bfe446caa407f0c3a2419c", sel("totalSupply()")), "ethereum", "0x2e5d4e2a2336045471bfe446caa407f0c3a2419c")
    note("Startale factory USDC balance", call("ethereum", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", sel("balanceOf(address)") + enc_addr("0x0000003B3E7b530b4f981aE80d9350392Defef90")), "ethereum", "0x0000003B3E7b530b4f981aE80d9350392Defef90")
    # ---------- HyperEVM ----------
    print("== HyperEVM")
    blk = int(rpc("hyperevm", "eth_blockNumber", []), 16)
    OUT["blocks"]["hyperevm"] = blk
    aW = "0xCF4642EF89683D0299B59738b1Cc3AC0177348Ba"
    note("Prime aWHYPE WHYPE balance", call("hyperevm", "0x5555555555555555555555555555555555555555", sel("balanceOf(address)") + enc_addr(aW)), "hyperevm", aW)

    json.dump(OUT, open("ci-out/state-verification.json", "w"), indent=1)
    print("\n[ci_verify] wrote ci-out/state-verification.json")
    print("[ci_verify] all reads are public-RPC eth_call/eth_getBalance; no keys, no writes")

if __name__ == "__main__":
    main()
