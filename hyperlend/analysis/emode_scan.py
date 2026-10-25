#!/usr/bin/env python3
"""Decode raw reserve configs, e-mode categories, and reserve totals for HyperLend."""
import json, sys, urllib.request, time, hashlib

RPC = "https://rpc.hyperliquid.xyz/evm"
POOL = "0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b"
_id=0
def rpc(m,p):
    global _id;_id+=1
    b=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    r=urllib.request.Request(RPC,data=b,headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
    for a in range(4):
        try:
            with urllib.request.urlopen(r,timeout=30) as x: d=json.loads(x.read())
            if "result" in d: return d["result"]
            raise RuntimeError(d)
        except Exception as e:
            if a==3: raise
            time.sleep(1.5*(a+1))
SEL={"getConfiguration(address)":"0xc44b11f7","getReservesList()":"0xd1946dbc",
     "getEModeCategoryData(uint8)":"0x6c6f6ae1","getUserEMode(address)":"0xeddf1b79",
     "getReserveData(address)":"0x35ea6a75","getAssetPrice(address)":"0xb3596f07"}
def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")
def call(to,sig,arg=None,argtype="addr"):
    data=SEL[sig]+( (arg if argtype=="raw" else enc_addr(arg)) if arg else "")
    return rpc("eth_call",[{"to":to,"data":data},"latest"])
def as_int(h): return int(h,16) if h and h!="0x" else 0
def dec_str(h):
    if not h or h=="0x": return ""
    b=bytes.fromhex(h[2:])
    off=int.from_bytes(b[:32],"big"); ln=int.from_bytes(b[off:off+32],"big")
    return b[off+32:off+32+ln].decode("utf-8","replace")

# check selector for getEModeCategoryData
print("# getEModeCategoryData selector check:", SEL["getEModeCategoryData(uint8)"])

# raw config decode for USDHL + PT + all
reserves=["0x5555555555555555555555555555555555555555","0x94e8396e0869c9F2200760aF0621aFd240E1CF38",
"0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463","0xBe6727B535545C67d5cAa73dEa54865B92CF7907",
"0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34","0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb",
"0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2","0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5",
"0xfD739d4e423301CE9385c1fb8850539D657C296D","0x0aD339d66BF4AeD5ce31c64Bc37B3244b6394A77",
"0x311dB0FDe558689550c68355783c95eFDfe25329","0xb7379d395F3c83952ad794896205f7E33E358735",
"0x068f321Fa8Fb9f0D135f290Ef6a3e2813e1c8A29","0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9",
"0xb88339CB7199b77E23DB6E890353E22632Ba630f","0x111111a1a0667d36bD57c0A9f569b98057111111",
"0xea84ca9849D9e76a78B91F221F84e9Ca065FC9f5","0x50fC4EDC6346F36993Bb30Fe60E932504Ed17391"]
names=["WHYPE","wstHYPE","UBTC","UETH","USDe","USDT0","sUSDe","USDHL","kHYPE","USR",
"PT-kHYPE-13NOV2025","PT-sUSDe-25SEP2025","USOL","beHYPE","USDC","USDH","PT-kHYPE-19MAR2026","PT-kHYPE-24SEP2026"]
print("\n# raw reserve configs (hex)")
for n,a in zip(names,reserves):
    cfg=as_int(call(POOL,"getConfiguration(address)",a))
    ltv=(cfg>>0)&0xFFFF; lt=(cfg>>16)&0xFFFF; lb=(cfg>>32)&0xFFFF; dec=(cfg>>48)&0xFF
    flags={k:((cfg>>s)&1) for k,s in [("active",56),("frozen",57),("borrowing",58),("stableBorrow",59),("paused",60),("borrowableInIsolation",61),("siloed",62),("flashloan",63)]}
    bcap=(cfg>>64)&0xFFFFFFFF; scap=(cfg>>80)&0xFFFFFFFF
    rf=(cfg>>64+36)&0xFFFF  # reserve factor bits 100-115
    debtCeil=(cfg>>152)&0xFFFFFFFFFFF  # debt ceiling bits 152-211
    virtAcc=(cfg>>255)&1
    print(f"{n:<24} cfg=0x{cfg:064x} ltv={ltv} liqThr={lt} bonus={lb} dec={dec} flags={flags} borrowCap={bcap} supplyCap={scap} debtCeiling={debtCeil} virtualAcc={virtAcc}")

print("\n# e-mode categories (id 1..12)")
for i in range(1,13):
    try:
        r=call(POOL,"getEModeCategoryData(uint8)",format(i,'064x'),argtype="raw")
        b=bytes.fromhex(r[2:])
        ltv=int.from_bytes(b[0:32],"big")&0xFFFF
        lt=int.from_bytes(b[32:64],"big")&0xFFFF
        lb=int.from_bytes(b[64:96],"big")&0xFFFF
        cbm=int.from_bytes(b[96:128],"big")
        off=int.from_bytes(b[128:160],"big")
        bbm=int.from_bytes(b[192:224],"big")
        lzbm=int.from_bytes(b[224:256],"big")
        # label
        lbl=""
        try:
            ln=int.from_bytes(b[off:off+32],"big")
            lbl=b[off+32:off+32+ln].decode("utf-8","replace")
        except Exception: pass
        print(f"cat {i}: ltv={ltv} liqThr={lt} bonus={lb} collateralBitmap=0x{cbm:032x} borrowableBitmap=0x{bbm:032x} ltvzeroBitmap=0x{lzbm:032x} label={lbl!r}")
    except Exception as e:
        print(f"cat {i}: revert/err {e}")
