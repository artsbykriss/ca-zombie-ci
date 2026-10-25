#!/usr/bin/env python3
"""Reserve totals + available liquidity for HyperLend core pool."""
import json,urllib.request,time
RPC="https://rpc.hyperliquid.xyz/evm"; POOL="0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b"
_id=0
def rpc(m,p):
    global _id;_id+=1
    b=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    for a in range(5):
        try:
            r=urllib.request.Request(RPC,data=b,headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
            d=json.loads(urllib.request.urlopen(r,timeout=30).read())
            if "result" in d: return d["result"]
        except Exception: pass
        time.sleep(0.8*(a+1))
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},"latest"])
def sel(sig): 
    from Crypto.Hash import keccak
    k=keccak.new(digest_bits=256);k.update(sig.encode());return "0x"+k.hexdigest()[:8]
def enc(a): return a.lower().replace("0x","").rjust(64,"0")
def ai(h): return int(h,16) if h and h!="0x" else 0
def dec_str(h):
    b=bytes.fromhex(h[2:]);off=int.from_bytes(b[:32],"big");ln=int.from_bytes(b[off:off+32],"big")
    return b[off+32:off+32+ln].decode("utf-8","replace")

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
decimals=[18,18,8,18,18,6,18,6,18,18,18,18,9,18,6,6,18,18]
SEL_RD=sel("getReserveData(address)")
print("block",int(rpc("eth_blockNumber",[]),16))
print(f"{'reserve':<22}{'aToken':<44}{'supplied':>26}{'vDebt':>26}{'availLiq':>26}")
for n,a,dec in zip(names,reserves,decimals):
    rd=call(POOL,SEL_RD+enc(a))
    b=bytes.fromhex(rd[2:])
    # ReserveData tuple: configuration,liqIndex,cLR,vbIndex,cVBR,cSBR,lastUpd,id,aToken,stableDebt,vDebt,irs,accrued,unbacked,isolationDebt
    def w(i): return b[i*32:(i+1)*32]
    aTok="0x"+w(8)[12:].hex()
    vDebt="0x"+w(10)[12:].hex()
    ats=ai(call(aTok,sel("totalSupply()")))
    vds=ai(call(vDebt,sel("totalSupply()")))
    avail=ai(call(a,sel("balanceOf(address)")+enc(aTok)))
    f=10**dec
    print(f"{n:<22}{aTok:<44}{ats/f:>26.4f}{vds/f:>26.4f}{avail/f:>26.4f}")
