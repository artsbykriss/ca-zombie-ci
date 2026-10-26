#!/usr/bin/env python3
import json, urllib.request, sys, time, subprocess
RPC="https://rpc.hyperliquid.xyz/evm"; BLK=int(sys.argv[1]) if len(sys.argv)>1 else 49508160
_id=0
def rpc(m,p):
    global _id; _id+=1
    body=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"r/1"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=40) as r: d=json.loads(r.read())
            return d.get("result") if "error" not in d else {"__err__":d["error"]}
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(1.2)
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},hex(BLK)])
def a(h): return "0x"+h[-40:] if isinstance(h,str) and len(h)>=42 else h
def u(h):
    try: return int(h,16)
    except: return h
def s4(s): return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()
def enc_addr(x): return x[2:].rjust(64,"0")

TOKENS={
 "lstHYPE":"0x81e064d0eB539de7c3170EDF38C1A42CBd752A76",
 "liquidHYPE":"0x441794D6a8F9A3739F5D4E98a728937b33489D29",
 "hbUSDT":"0x5e105266db42f78FA814322Bce7f388B4C2e61eb",
 "hbUSDC":"0x057ced81348D57Aad579A672d521d7b4396E8a61",
 "dnHYPE":"0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29",
 "dnPUMP":"0x8858A307a85982c2B3CB2AcE1720237f2f09c39B",
 "hbXAUt":"0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8",
 "wVLP":"0xD66d69c288d9a6FD735d7bE8b2e389970fC4fD42",
 "nLP":"0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA",
 "masterUSD":"0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03",
}
DEPOSITORS={"lstHYPE":"0x205ac1e0380b0b9cce691bd4c6f3c14258ae9201",
            "liquidHYPE":"0x5bfb09dd155c0ec3f375b266a7353c0ba64f9d60"}
S={"depositReceiver":s4("depositReceiver()"),"vaultToken":s4("vaultToken()"),"pricer":s4("pricer()"),
   "isPaused":s4("isPaused()"),"depositFee":s4("depositFee()"),"depositCap":s4("depositCap()"),
   "depositFeeRecipient":s4("depositFeeRecipient()"),"isDepositToken":s4("isDepositToken(address)"),
   "owner":s4("owner()"),"authority":s4("authority()"),"baseAsset":s4("baseAsset()")}
out={"block":BLK,"depositors":{}}
for n,d in DEPOSITORS.items():
    row={"depositor":d,"vaultToken":TOKENS[n]}
    row["vaultToken_read"]=a(call(d,S["vaultToken"]))
    row["pricer"]=a(call(d,S["pricer"]))
    row["depositReceiver"]=a(call(d,S["depositReceiver"]))
    row["isPaused"]=u(call(d,S["isPaused"]))
    row["depositFee"]=u(call(d,S["depositFee"]))
    row["depositCap"]=u(call(d,S["depositCap"]))
    row["depositFeeRecipient"]=a(call(d,S["depositFeeRecipient"]))
    row["owner"]=a(call(d,S["owner"]))
    row["authority"]=a(call(d,S["authority"]))
    row["isDepositToken"]={}
    for tn,t in TOKENS.items():
        r=call(d,S["isDepositToken"]+enc_addr(t))
        if isinstance(r,str) and r.endswith("1"):
            row["isDepositToken"][tn]=t
    out["depositors"][n]=row
    print(f"DEPOSITOR {n}: paused={row['isPaused']} fee={row['depositFee']} cap={row['depositCap']} recv={row['depositReceiver']} owner={row['owner']} auth={row['authority']}")
    print(f"   isDepositToken TRUE: {list(row['isDepositToken'].keys())}")
# common tokens
COMMON=["0x5555555555555555555555555555555555555555","0xb88339cb7199b77e23db6e890353e22632ba630f",
        "0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb","0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",
        "0x9fdbda0a5e284c32744d2f17ee5c74b284993463","0xf4d9235269a96aadafc9adae454a0618ebe37949",
        "0xbe6727b535545c67d5caa73dea54865b92cf7907","0x9ab96a4668456896d45c301bc3a15cee76aa7b8d",
        "0x0ad339d66bf4aed5ce31c64bc37b3244b6394a77"]
for n,d in DEPOSITORS.items():
    trues=[]
    for t in COMMON:
        r=call(d,S["isDepositToken"]+enc_addr(t))
        if isinstance(r,str) and r.endswith("1"): trues.append(t)
    print(f"DEPOSITOR {n} common-token TRUE: {trues}")
    out["depositors"][n]["common_tokens"]=trues
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/depositor_state.json","w"),indent=1)
print("WROTE")
