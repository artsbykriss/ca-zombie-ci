#!/usr/bin/env python3
import json, urllib.request, sys, time
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
def st(addr,slot): return rpc("eth_getStorageAt",[addr,slot,hex(BLK)])

WQS={
 "lstHYPE":   ("0x8b04cd6561abf2de78112da30ccb919fe8d09d98","0xa980d98de0fff436e1a3e7d9a06999b03c8aa59e","0x5eD0eC0b0643dAB621Dc814C8D058e161b9b884b","0x81e064d0eB539de7c3170EDF38C1A42CBd752A76"),
 "hbUSDT":    ("0x240e0b2cb615ded2fe90fde265b15988dc45b1c6","0xfd1fd829e4e89cae8190596698e84754c3fec16c","0x3636a26ec1d512c5eCff42F7Adaa5cE7964C6579","0x5e105266db42f78FA814322Bce7f388B4C2e61eb"),
 "hbUSDC":    ("0x10024239474120ce410dd7ce203793c81d438be3","0x7abf6da6c2c131b58c1f4cb3947b0cfe2edc1c2a","0xe0995A641d454c149E6C808BAA37Cb2B38763316","0x057ced81348D57Aad579A672d521d7b4396E8a61"),
 "nLP":       ("0x6b68c4459e0f76244e4f0a87e3202d31869c1089","0x5abfb110b61dbe6d029aa7a0018673e167c06a05","0xC23cdFe493bB5E69bedfCF6E710f508710ac668B","0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA"),
 "masterUSD": ("0x6e0b9afaae09a3479cfb7e923e15c05a9b23850d","0x3b66712b3ca873c5cc0fdc54357ffcfe583ce896","0x5362454e5648C6Ac7F03969E8a62CFc61F99b9D6","0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03"),
 "dnHYPE":    ("0xbc63a6057eaead49ea4ec1f07c28659e01058dd1","0x4f7bada89b65366c7b7074b474675d5dcf712a8b","0x5100Aee934F0EE05FA78B03114a068Da18aFEd8D","0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29"),
 "dnPUMP":    ("0xdac07cf2a26a52f8c2fc89dbc244a83f0236094c","0x3067f8df868bdf2916fdbc8d15254222e4ef0775","0x58F6138DB540D0f5bfB24Fd9b17db54694a92ea6","0x8858A307a85982c2B3CB2AcE1720237f2f09c39B"),
 "hbXAUt":    ("0x0d7f3d551edb80b950db723c19792fa4547aad82","0xc8ca861ee85aa7d4804507f0646acce8899ea14e","0x988E3E2C26840F2cAe2c5fB55fAeb5e59CE1A597","0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8"),
}
SEL={"owner":"0x8da5cb5b","authority":"0xbf7e214f","isPaused":"0x5c975abb","isInstantWithdrawalPaused":"0x9c4c5a2d",
 "instantWithdrawalFee":"0x9c9c5a2d","pricer":"0xa6138ed9","vaultToken":"0x703bafd5","baseAsset":"0xcdf456e1",
 "depositReceiver":"0xfc8c0851","getRate":"0x679aefce","totalSupply":"0x18160ddd","withdrawalNonce":"0x0d155f0c",
 "minimumDeadline":"0x24e86d67","totalAssets":"0x01e1d114"}
# correct selectors
import subprocess
def sig(s):
    return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()
for k,s in [("isPaused","isPaused()"),("isInstantWithdrawalPaused","isInstantWithdrawalPaused()"),
            ("instantWithdrawalFee","instantWithdrawalFee()"),("withdrawalNonce","withdrawalNonce()"),
            ("minimumDeadline","minimumDeadline()"),("authority","authority()"),("owner","owner()")]:
    SEL[k]=sig(s)
print("selectors",SEL)
out={"block":BLK,"vaults":{}}
for n,(wq,dr,pr,vt) in WQS.items():
    row={"wq":wq,"depositReceiver":dr,"pricer":pr,"vaultToken":vt}
    row["wq_owner"]=a(call(wq,SEL["owner"]))
    row["wq_authority"]=a(call(wq,SEL["authority"]))
    row["wq_isPaused"]=u(call(wq,SEL["isPaused"]))
    row["wq_isInstantWithdrawalPaused"]=u(call(wq,SEL["isInstantWithdrawalPaused"]))
    row["wq_instantWithdrawalFee"]=u(call(wq,SEL["instantWithdrawalFee"]))
    row["wq_withdrawalNonce"]=u(call(wq,SEL["withdrawalNonce"]))
    row["wq_minimumDeadline"]=u(call(wq,SEL["minimumDeadline"]))
    row["wq_pricer"]=a(call(wq,SEL["pricer"]))
    row["pricer_owner"]=a(call(pr,SEL["owner"]))
    row["pricer_authority"]=a(call(pr,SEL["authority"]))
    row["pricer_rate"]=u(call(pr,"0x679aefce"))
    row["pricer_vaultToken"]=a(call(pr,"0x703bafd5"))
    row["pricer_baseAsset"]=a(call(pr,"0xcdf456e1"))
    row["dr_owner"]=a(call(dr,SEL["owner"]))
    row["dr_withdrawalQueue"]=a(call(dr,"0x37d5fe99"))
    row["vt_owner"]=a(call(vt,SEL["owner"]))
    row["vt_totalSupply"]=u(call(vt,"0x18160ddd"))
    # storage slots 0,1 of pricer
    row["pricer_slot0"]=st(pr,"0x0")
    row["pricer_slot1"]=st(pr,"0x1")
    out["vaults"][n]=row
    print(f"{n:10s} wq_owner={row['wq_owner']} wq_auth={row['wq_authority']} paused={row['wq_isPaused']} instPaused={row['wq_isInstantWithdrawalPaused']} fee={row['wq_instantWithdrawalFee']} nonce={row['wq_withdrawalNonce']} pricer_owner={row['pricer_owner']} rate={row['pricer_rate']} vt_owner={row['vt_owner']}",flush=True)
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/wq_state.json","w"),indent=1)
print("WROTE wq_state.json")
