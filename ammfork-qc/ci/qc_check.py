#!/usr/bin/env python3
"""Independent QC re-reads for the AMM-fork cluster. Read-only; no secrets."""
import json, time, urllib.request, datetime, os

RPC = {
    "flare": "https://flare-api.flare.network/ext/C/rpc",
    "songbird": "https://songbird-api.flare.network/ext/C/rpc",
    "arbitrum": "https://arb1.arbitrum.io/rpc",
    "telos": "https://rpc.telos.net",
    "syscoin": "https://rpc.syscoin.org",
    "chiliz": "https://rpc.chiliz.com",
    "wemix": "https://api.wemix.com",
    "fuse": "https://rpc.fuse.io",
}
out = {"generated_at": datetime.datetime.utcnow().isoformat()+"Z", "checks": {}, "blocks": {}, "pass": True}

def rpc(chain, method, params, tries=3):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC[chain], data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                         headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                d = json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            last = repr(e); time.sleep(1+i)
    raise RuntimeError(last)

def w(h, i=0):
    h = h[2:] if h.startswith("0x") else h
    return int(h[i*64:(i+1)*64], 16) if len(h) >= (i+1)*64 else 0

def a(x): return x.lower().replace("0x","").rjust(64,"0")
def hx(x):
    if x < 0: x = (1<<256)+x
    return format(x,"064x")

def call(chain, to, sel, args=(), block="latest"):
    return rpc(chain, "eth_call", [{"to":to,"data":sel+"".join(args)}, block])

def callr(chain, to, sel, args=(), block="latest", frm=None):
    p = {"to":to,"data":sel+"".join(args)}
    if frm: p["from"] = frm
    return rpc(chain, "eth_call", [p, block])

def ck(section, name, ok, detail):
    out["checks"].setdefault(section, []).append({"check":name,"pass":bool(ok),"detail":detail})
    if not ok: out["pass"] = False

DEAD = "0x000000000000000000000000000000000000dEaD"
MAX128 = "0"*32 + "f"*32
IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"

try:
    # ---------------- Enosys Flare ----------------
    b = int(rpc("flare","eth_blockNumber",[]),16); out["blocks"]["flare"] = b; B = hex(b)
    F = "0x17AA157AC8C54034381b840Cb8f6bf7Fc355f0de"; P = "0x3C2a7B76795E58829FAAa034486D417dd0155162"
    NPM = "0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657"; SAFE = "0xdedda08961216adb9ca09b88986d110127b24270"
    ck("enosys","flare chain id 14", int(rpc("flare","eth_chainId",[]),16)==14, rpc("flare","eth_chainId",[]))
    ck("enosys","flare poolsCount == 106", w(call("flare",F,"0x8c788de0",(),B))==106, w(call("flare",F,"0x8c788de0",(),B)))
    ck("enosys","flare factory owner == 2/6 Safe", call("flare",F,"0x8da5cb5b",(),B)[-40:]==SAFE.lower()[2:], call("flare",F,"0x8da5cb5b",(),B)[-40:])
    ck("enosys","Safe threshold 2", w(call("flare",SAFE,"0xe75235b8",(),B))==2, w(call("flare",SAFE,"0xe75235b8",(),B)))
    owners = call("flare",SAFE,"0xa0e67e2b",(),B); od = owners[2:]; n = int(od[64:128],16)
    ck("enosys","Safe owner count 6", n==6, n)
    ck("enosys","pool impl == 0x23f02a..", rpc("flare","eth_getStorageAt",[P,IMPL,B])[-40:]=="23f02a41dea4fe6180b8e4aa56a745ea1ba4a88e", rpc("flare","eth_getStorageAt",[P,IMPL,B]))
    # negative gates (from a random EOA)
    for name,to,sel,args,needle in [
        ("mint no-pay reverts",P,"0x3c8a7d8d",[a(DEAD),hx(-600),hx(600),hx(10**18),hx(160)],None),
        ("swap no-pay reverts",P,"0x128acb08",[a(DEAD),hx(1),hx(-10**6),hx(4295128740),hx(160)],None),
        ("flash no-repay reverts",P,"0x490e6cbc",[a(DEAD),hx(10**6),hx(0),hx(128)],None),
        ("NPM collect non-owner reverts",NPM,"0xfc6f7865",[hx(1),a(DEAD),MAX128,MAX128],"Not approved"),
        ("NPM burn non-owner reverts",NPM,"0x42966c68",[hx(1)],"Not approved"),
        ("pool collectProtocol non-factory reverts",P,"0x85b66729",[a(DEAD),MAX128,MAX128],"NA"),
        ("pool setFeeProtocol non-factory reverts",P,"0x8206a4d1",[hx(10),hx(10)],"NA"),
        ("factory setPoolImplementation non-owner reverts",F,"0xd6f74898",[a(DEAD)],"not the factory owner"),
    ]:
        r,e = None,None
        try: r = callr("flare",to,sel,args,"latest",DEAD)
        except Exception as ex: e = repr(ex)
        ok = e is not None and (needle is None or needle in e)
        ck("enosys",name,ok, (e or "")[:160])
    # ---------------- Enosys Songbird ----------------
    sb = int(rpc("songbird","eth_blockNumber",[]),16); out["blocks"]["songbird"] = sb; SB=hex(sb)
    SF = "0x416F1CcBc55033Ae0133DA96F9096Fe8c2c17E7d"
    ck("enosys","songbird chain id 19", int(rpc("songbird","eth_chainId",[]),16)==19, rpc("songbird","eth_chainId",[]))
    ck("enosys","songbird poolsCount == 62", w(call("songbird",SF,"0x8c788de0",(),SB))==62, w(call("songbird",SF,"0x8c788de0",(),SB)))
    ck("enosys","songbird factory owner == Safe", call("songbird",SF,"0x8da5cb5b",(),SB)[-40:]=="68d0818bb30b340ad99994592a88a3095e47522f", call("songbird",SF,"0x8da5cb5b",(),SB)[-40:])
except Exception as e:
    ck("enosys","RPC failure", False, repr(e))

try:
    # ---------------- Zappy ----------------
    b = int(rpc("telos","eth_blockNumber",[]),16); out["blocks"]["telos"]=b; B=hex(b)
    AP="0x9E0081f597d4381Aa10F6CfC6960165a2431f2F1"; TM="0xb1f92104e1ad5ed84592666efb1eb52b946e6e68"; SP="0xe696c38b79307f65f2e00bc6c572c2b83e048e36"
    PF="0xe421fc686099c4dec31c9d58b51de9608665fbf2"; A="0x818ec0a7fe18ff94269904fced6ae3dae6d6dc0b"
    ck("zappy","chain id 40", int(rpc("telos","eth_chainId",[]),16)==40, rpc("telos","eth_chainId",[]))
    ck("zappy","ActivePool TLOS 2.373M", abs(w(call("telos",AP,"0x14f6c3be",(),B))/1e18-2373298.084)<1, w(call("telos",AP,"0x14f6c3be",(),B))/1e18)
    ck("zappy","system debt 12,781 USDM", abs(w(call("telos",AP,"0x5eb52fca",(),B))/1e18-12781.191)<1, w(call("telos",AP,"0x5eb52fca",(),B))/1e18)
    ck("zappy","single trove", w(call("telos",TM,"0x49eefeee",(),B))==1, w(call("telos",TM,"0x49eefeee",(),B)))
    price = w(call("telos",PF,"0x0fdb11cf",(),B))/1e18
    ck("zappy","oracle 0.01931", abs(price-0.01931047)<1e-9, price)
    ck("zappy","redemption value ~0.834", abs((1-0.0515)/price*0.01697655-0.834)<0.002, (1-0.0515)/price*0.01697655)
    vault = "0x" + call("telos",A,"0xfbfa77cf",(),B)[-40:]
    ck("zappy","anyUSDC vault is 0-code EOA", (len(rpc("telos","eth_getCode",[vault,B]))-2)//2==0, vault)
    ck("zappy","StabilityPool deposits == 0", w(call("telos",SP,"0x9bf2f1ac",(),B))==0, w(call("telos",SP,"0x9bf2f1ac",(),B)))
except Exception as e:
    ck("zappy","RPC failure", False, repr(e))

try:
    # ---------------- PegaSys ----------------
    b = int(rpc("syscoin","eth_blockNumber",[]),16); out["blocks"]["syscoin"]=b; B=hex(b)
    pairs=["0x2CDF912CbeaF76d67feaDC994D889c2F4442b300","0x8c741Cd1Dc4D027034ce864FFD660BFa44c24674","0xDA3995D0ADDb43935A0c17c187C271Cc6c07Df21","0x56Dbc5768CE4D674228e6825Cb919b402aF428Fc","0x1a7400F4DFE299DBac8034bD2Bb0B3B17fCA9342"]
    ok=True; det={}
    for p in pairs:
        r=call("syscoin",p,"0x0902f1ac",(),B); t0="0x"+call("syscoin",p,"0x0dfe1681",(),B)[-40:]; t1="0x"+call("syscoin",p,"0xd21220a7",(),B)[-40:]
        b0=w(call("syscoin",t0,"0x70a08231",(a(p),),B)); b1=w(call("syscoin",t1,"0x70a08231",(a(p),),B))
        det[p]={"s0":b0-w(r,0),"s1":b1-w(r,1)}
        ok = ok and b0==w(r,0) and b1==w(r,1)
    ck("pegasys","all 5 pairs balance == reserves",ok,det)
    r=call("syscoin",pairs[0],"0x0902f1ac",(),B); usdc=w(r,0)/1e6; wsys=w(r,1)/1e18
    # fixed CoinGecko SYS reference at 2026-10-18
    implied=0.002040132293426376/(usdc/wsys)
    ck("pegasys","implied USDC < $0.01",implied<0.01,implied)
    chef="0x3D974158e4C70dD5204b62AceDa9fd1330f33C7b"; nm=call("syscoin",chef,"0x06fdde03",(),B)
    nb=bytes.fromhex(nm[2:]); ln=int.from_bytes(nb[32:64],"big"); name=nb[64:64+ln].decode(errors="ignore")
    ck("pegasys","Chef quest is an ERC20",name=="Chef quest",name)
except Exception as e:
    ck("pegasys","RPC failure", False, repr(e))

try:
    # ---------------- DORY hook ----------------
    b = int(rpc("arbitrum","eth_blockNumber",[]),16); out["blocks"]["arbitrum"]=b; B=hex(b)
    H="0x6b70fef40d3925881251c018164dbcec6bc94040"; D="0x33b49f2264e85bb124d2730dc180182717d436ae"; U="0xaf88d065e77c8cc2239327c5edb3a432268e5831"
    code=rpc("arbitrum","eth_getCode",[H,B]); size=(len(code)-2)//2
    perms=call("arbitrum",H,"0xc4e833ce",(),B); true_words=[i for i in range(14) if w(perms,i)!=0]
    ck("arbitris","hook runtime 6,953 bytes",size==6953,size)
    ck("arbitris","only afterSwap permission",true_words==[7],true_words)
    ck("arbitris","address low14 == 0x40",(int(H,16)&0x3fff)==0x40,hex(int(H,16)&0x3fff))
    ck("arbitris","hook holds 0 DORY/USDC",w(call("arbitrum",D,"0x70a08231",(a(H),),B))==0 and w(call("arbitrum",U,"0x70a08231",(a(H),),B))==0,"")
    ck("arbitris","hook is NOT a DORY minter",w(call("arbitrum",D,"0xaa271e1a",(a(H),),B))==0,w(call("arbitrum",D,"0xaa271e1a",(a(H),),B)))
    e=None
    try: callr("arbitrum",D,"0x40c10f19",[a(DEAD),hx(10**18)],"latest",DEAD)
    except Exception as ex: e=repr(ex)
    ck("arbitris","DORY mint restricted", e is not None and "Not authorized" in e, (e or "")[:120])
except Exception as e:
    ck("arbitris","RPC failure", False, repr(e))

try:
    # ---------------- Kayen ----------------
    b = int(rpc("chiliz","eth_blockNumber",[]),16); out["blocks"]["chiliz"]=b; B=hex(b)
    ST="0xBF4ca6F798b2e342E36dc2eC80667B58CF480787"; DEP="0xc3cbf2c6b3ea81f1a8a9fd24d8179b6f39860db7"; Q="0xB6892E1b39e5dcB1706d77ABDb595dA361FDCD0F"
    ck("kayen","chain id 88888",int(rpc("chiliz","eth_chainId",[]),16)==88888,rpc("chiliz","eth_chainId",[]))
    supply=w(call("chiliz",ST,"0x18160ddd",(),B)); rate=w(call("chiliz",ST,"0xe6aa216c",(),B)); dep=w(call("chiliz",DEP,"0x7d882097",(),B))
    ck("kayen","LST supply*rate == totalDeposits", abs(supply*rate/1e36-dep/1e18)<1e-6, [supply,rate,dep])
    ck("kayen","4 unclaimed == 155.876 CHZ", w(call("chiliz",Q,"0x70bdf26e",(a(ST),),B))==83, w(call("chiliz",Q,"0x70bdf26e",(a(ST),),B)))
    tot=0
    for i in [5,8,80,82]:
        r=call("chiliz",Q,"0x5be4f765",(a(ST),hx(i)),B); tot+=w(r,0)
    ck("kayen","unclaimed total 155.87628181 CHZ",tot==155876281810000000000,tot)
    r,e=None,None
    try: r=callr("chiliz",ST,"0x379607f5",[hx(82)],B,DEAD)
    except Exception as ex: e=repr(ex)
    ck("kayen","claim(82) non-owner reverts owner-gated",e is not None and "23295f0e" in e,(e or "")[:120])
    r,e=None,None
    try: r=callr("chiliz",ST,"0x379607f5",[hx(82)],B,"0xb02b23f1463c13ee538f2f2321568ea02eada2b0")
    except Exception as ex: e=repr(ex)
    ck("kayen","claim(82) owner succeeds",e is None,(e or "")[:120])
except Exception as e:
    ck("kayen","RPC failure", False, repr(e))

try:
    # ---------------- WEMIX ----------------
    b = int(rpc("wemix","eth_blockNumber",[]),16); out["blocks"]["wemix"]=b; B=hex(b)
    M="0x3fc9d5600525276b89a2d4e126850fe992a86634"; PA="0xb99c720d3ab8c04ba52489781f4a8326e4a88158"
    ck("wemix","chain id 1111",int(rpc("wemix","eth_chainId",[]),16)==1111,rpc("wemix","eth_chainId",[]))
    ck("wemix","manager totalSupply == 434",w(call("wemix",M,"0x18160ddd",(),B))==434,w(call("wemix",M,"0x18160ddd",(),B)))
    ck("wemix","manager admin == ProxyAdmin",rpc("wemix","eth_getStorageAt",[M,ADMIN,B])[-40:]=="b99c720d3ab8c04ba52489781f4a8326e4a88158",rpc("wemix","eth_getStorageAt",[M,ADMIN,B]))
    own="0x"+call("wemix",PA,"0x8da5cb5b",(),B)[-40:]
    ck("wemix","ProxyAdmin owner is 0-code EOA",(len(rpc("wemix","eth_getCode",[own,B]))-2)//2==0,own)
except Exception as e:
    ck("wemix","RPC failure", False, repr(e))

with open("ci-out/qc-verification.json","w") as f:
    json.dump(out,f,indent=2)
print(json.dumps(out,indent=2))
print("ALL_QC_CHECKS_PASS" if out["pass"] else "SOME_QC_CHECKS_FAILED")
