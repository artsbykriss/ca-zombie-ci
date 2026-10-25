#!/usr/bin/env python3
"""Correct e-mode category decode (handles dynamic-struct return pointer)."""
import json, urllib.request, time
RPC="https://rpc.hyperliquid.xyz/evm"; POOL="0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b"
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
NAMES=["WHYPE","wstHYPE","UBTC","UETH","USDe","USDT0","sUSDe","USDHL","kHYPE","USR",
"PT-kHYPE-13NOV2025","PT-sUSDe-25SEP2025","USOL","beHYPE","USDC","USDH","PT-kHYPE-19MAR2026","PT-kHYPE-24SEP2026"]
def bits(bm, n=18):
    return [NAMES[i] for i in range(n) if (bm>>i)&1]
for i in range(1,13):
    try:
        r=rpc("eth_call",[{"to":POOL,"data":"0x6c6f6ae1"+format(i,'064x')},"latest"])
        b=bytes.fromhex(r[2:])
        ptr=int.from_bytes(b[0:32],"big")            # pointer to struct
        s=ptr
        ltv=int.from_bytes(b[s:s+32],"big")&0xFFFF
        lt=int.from_bytes(b[s+32:s+64],"big")&0xFFFF
        lb=int.from_bytes(b[s+64:s+96],"big")&0xFFFF
        cbm=int.from_bytes(b[s+96:s+128],"big")
        lbloff=int.from_bytes(b[s+128:s+160],"big")
        bbm=int.from_bytes(b[s+160:s+192],"big")
        lzbm=int.from_bytes(b[s+192:s+224],"big")
        ls=s+lbloff
        ln=int.from_bytes(b[ls:ls+32],"big")
        lbl=b[ls+32:ls+32+ln].decode("utf-8","replace")
        print(f"cat {i}: ltv={ltv} liqThr={lt} bonus={lb}")
        print(f"       label={lbl!r}")
        print(f"       collateralBitmap=0x{cbm:032x} -> {bits(cbm)}")
        print(f"       borrowableBitmap=0x{bbm:032x} -> {bits(bbm)}")
        print(f"       ltvzeroBitmap=0x{lzbm:032x} -> {bits(lzbm)}")
    except Exception as e:
        print(f"cat {i}: err {e}")
