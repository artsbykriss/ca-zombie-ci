#!/usr/bin/env python3
import json,urllib.request
from eth_hash.auto import keccak
def sel(s): return "0x"+keccak(s.encode())[:4].hex()
def rpc(url,m,p):
    req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
        headers={"content-type":"application/json","user-agent":"research/1.0"})
    return json.load(urllib.request.urlopen(req,timeout=40))
def reason(d):
    if not d or d[:10]!="0x08c379a0": return None
    b=d[2:]; n=int(b[8+64:8+128],16); return bytes.fromhex(b[8+128:8+128+n*2]).decode()
out={"asof":{},"probes":[]}
VPM="0xf9cFB8a62f50e10AdDE5Aa888B44cF01C5957055"
RAND="0x1111111111111111111111111111111111111111"; OWNER="0x57e54894eb8e3638364bfcf216d502f1c6817398"
params_liquidate="(41,1,100,0x1111111111111111111111111111111111111111,false,2,0,0,99999999999,0,0,0,0x)"
params_close="(41,1,100,0x1111111111111111111111111111111111111111,false,2,0,0,99999999999,0,0x)"
params_invest="(2,0x1111111111111111111111111111111111111111,[[]],false,99999999999)"
from subprocess import check_output
for chain,url in [("op","https://mainnet.optimism.io"),("base","https://mainnet.base.org")]:
    out["asof"][chain]=int(rpc(url,"eth_blockNumber",[])["result"],16)
    for name,sig,prm in [
        ("liquidateVaultPositionPartially","liquidateVaultPositionPartially((uint256,uint256,uint16,address,bool,uint8,uint256,uint256,uint256,uint256,uint256,uint256,bytes))",params_liquidate),
        ("closeOutOfRangePosition","closeOutOfRangePosition((uint256,uint256,uint16,address,bool,uint8,uint256,uint256,uint256,uint256,bytes))",params_close),
        ("investEarnedFeeToLiquidity","investEarnedFeeToLiquidity((uint256,address,(address,address,bool)[][],bool,uint256))",params_invest),
    ]:
        cd=check_output(["cast","calldata",sig,prm]).decode().strip()
        for who,label in [(RAND,"random"),(OWNER,"owner")]:
            r=rpc(url,"eth_call",[{"to":VPM,"data":cd,"from":who},"latest"])
            err=r.get("error") or {}
            out["probes"].append({"chain":chain,"contract":VPM,"function":name,"selector":cd[:10],"from":label,
                                  "result":r.get("result"),"error":err.get("message"),"revert_data":err.get("data"),
                                  "decoded_reason":reason(err.get("data"))})
json.dump(out,open("evidence/extra_permission_probes.json","w"),indent=1)
for p in out["probes"]: print(p["chain"],p["function"],p["from"],p["error"],p["decoded_reason"])
print(out["asof"])
