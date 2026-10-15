#!/usr/bin/env python3
"""Live-state read for 1Hive Gardens sDAI pools 8 & 67 (read-only, public RPC).
Writes gardens-sdai-live.json. No secrets."""
import json, urllib.request, time, sys

RPC = "https://rpc.gnosischain.com"
RPC_FB = "https://gnosis-rpc.publicnode.com"

RC   = "0xE2396fe2169ca026962971d3B2E373Ba925B6257"
ALLO = "0x1133eA7Af70876e64665ecD07C0A0476d09465a1"
SDAI = "0xaf204776c7245bF4147c2612BF6e5972Ee483701"
WXDAI= "0xe91D153e0b41518A2Ce8Dd3D7944Fa863463a97d"
STR8 = "0xaa0195986ffe8f3371444fa77ee3ed04ac787eea"
STR67= "0x96dee4849a6ab9e51ae36712794318001515dc91"
STR27= "0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2"
AGREEMENT = "0x59a15718992a42082ab2306bc6cbd662958a178c"
CELESTE = "0x44E4fCFed14E1285c9e0F6eae77D5fDd0F196f85"
CELESTE_STRAT_ARB = "0x92bc0af737f55ff7b677cd942aafd52934fc751d"
GPC = "0xce853207ce3e16e268f572ea982801b8045f0afc"
ADAPTER = "0xD499b51fcFc66bd090F9B2068A71408b98A29923"

def pad32(x):  # x: hex string w/o 0x or int
    if isinstance(x,int): x=hex(x)[2:]
    if x.startswith("0x"): x=x[2:]
    return x.rjust(64,"0").lower()

def rpc(method, params, url=RPC):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    last=None
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            last=e; time.sleep(1.0*(a+1))
            if url==RPC: url=RPC_FB
    raise RuntimeError(f"rpc fail {method}: {last}")

def batch(calls, url=RPC):
    payload=[]
    for i,c in enumerate(calls):
        obj={"to":c[0],"data":c[1]}
        if len(c)>2 and c[2]: obj["from"]=c[2]
        payload.append({"jsonrpc":"2.0","id":i+1,"method":"eth_call","params":[obj,"latest"]})
    body=json.dumps(payload).encode()
    req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    last=None
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=90) as r:
                d=json.load(r)
            out={}
            for item in d:
                out[item["id"]]=item.get("result") if "error" not in item else {"__err":item["error"]}
            return out
        except Exception as e:
            last=e; time.sleep(1.0*(a+1))
            url=RPC_FB if url==RPC else RPC
    raise RuntimeError(f"batch fail: {last}")

blk = int(rpc("eth_blockNumber",[]),16)
def enc_addr(a): return a[2:].lower().rjust(64,"0")
def dec_addr(h): return "0x"+h[-40:] if h and len(h)>=42 else None

ROLE8  = "1e7e708759cd587d69adab3835168eb789586b24a36a778167d4461dadd00250"
ROLE67 = "b607c8c0ce5262160e662a9746016cc82f962c77947c16644f2364fbaeb65c19"

JOBS=[]
def job(label,to,data,from_=None): JOBS.append((label,to,data,from_))

for pid, strat in [(8,STR8),(67,STR67)]:
    job(f"allo.getPool.{pid}", ALLO, "0x068bcd8d"+pad32(pid))
    job(f"strat{pid}.cvParams", strat, "0x2506b870")
    job(f"strat{pid}.getPoolAmount", strat, "0x4ab4ba42")
    job(f"strat{pid}.totalPointsActivated", strat, "0xaba9ffee")
    job(f"strat{pid}.getPoolThresholdPoints", strat, "0x00735c98")
    job(f"strat{pid}.pointSystem", strat, "0x2dbd6fdd")
    job(f"strat{pid}.proposalType", strat, "0x351d9f96")
    job(f"strat{pid}.poolId", strat, "0x38fff2d0")
    job(f"strat{pid}.isPoolActive", strat, "0xdf868ed3")
    job(f"strat{pid}.registryCommunity", strat, "0x6003e414")
    job(f"strat{pid}.getAllo", strat, "0x15cc481e")
    job(f"strat{pid}.getArbitrableConfig", strat, "0x059351cd")
    job(f"strat{pid}.currentArbitrableConfigVersion", strat, "0x125fd1d9")
    job(f"strat{pid}.owner", strat, "0x8da5cb5b")
    job(f"strat{pid}.pauseController", strat, "0x60b47789")
    job(f"strat{pid}.proposalCounter", strat, "0x0c0512e9")
    job(f"strat{pid}.activeProposalCount", strat, "0x76e43099")
    job(f"strat{pid}.activeProposalCountInitialized", strat, "0x962896f6")
    job(f"strat{pid}.getMaxAmount", strat, "0x0ba95909")
    job(f"strat{pid}.sybilScorer", strat, "0xb6c61f31")
    job(f"strat{pid}.totalStaked", strat, "0x817b1cd2")
    for X in [250,500,1000,2000,4000,6000]:
        job(f"strat{pid}.calculateThreshold({X})", strat, "0x59a5db8b"+pad32(X*10**18))
    job(f"sdai.balanceOf.strat{pid}", SDAI, "0x70a08231"+enc_addr(strat))
    job(f"sdai.maxWithdraw.strat{pid}", SDAI, "0xce96cb77"+enc_addr(strat))
    job(f"wxdai.balanceOf.strat{pid}", WXDAI, "0x70a08231"+enc_addr(strat))
    job(f"sdai.maxRedeem.strat{pid}", SDAI, "0xd905777e"+enc_addr(strat))

job("rc.enabledStrategies.8", RC, "0x3a871fe1"+enc_addr(STR8))
job("rc.enabledStrategies.67", RC, "0x3a871fe1"+enc_addr(STR67))
job("rc.hasRole.ALLOWLIST8.zero", RC, "0x91d14854"+ROLE8+enc_addr("0x0000000000000000000000000000000000000000"))
job("rc.hasRole.ALLOWLIST67.zero", RC, "0x91d14854"+ROLE67+enc_addr("0x0000000000000000000000000000000000000000"))
job("rc.hasRole.ALLOWLIST8.council", RC, "0x91d14854"+ROLE8+enc_addr("0xc6c2E9EFB898A42DB4137B07b727b45e0C353d81"))
job("rc.hasRole.ALLOWLIST67.council", RC, "0x91d14854"+ROLE67+enc_addr("0xc6c2E9EFB898A42DB4137B07b727b45e0C353d81"))
job("rc.registerStakeAmount", RC, "0x78a0b8a9")
job("rc.communityFee", RC, "0x8961be6b")
job("rc.councilSafe", RC, "0x6c53db9a")
job("rc.owner", RC, "0x8da5cb5b")
job("rc.totalMembers", RC, "0x76e92559")
job("rc.pauseController", RC, "0x60b47789")
job("rc.hasRole.ALLOWLIST27.zero", RC, "0x91d14854c3b06835cd5ac011ddecef53631f2e5cc1849fe36234eeb2726c56e7a3eae49b"+enc_addr("0x0000000000000000000000000000000000000000"))

job("sdai.asset", SDAI, "0x38d52e0f")
job("sdai.convertToAssets.1e18", SDAI, "0x07a2d13a"+pad32(10**18))
job("sdai.previewRedeem.1e18", SDAI, "0x4cdad506"+pad32(10**18))
job("sdai.previewRedeem.10000e18", SDAI, "0x4cdad506"+pad32(10000*10**18))
job("sdai.totalAssets", SDAI, "0x01e1d114")
job("sdai.totalSupply", SDAI, "0x18160ddd")
job("sdai.decimals", SDAI, "0x313ce567")
job("sdai.balanceOf.adapter", SDAI, "0x70a08231"+enc_addr(ADAPTER))
job("wxdai.balanceOf.adapter", WXDAI, "0x70a08231"+enc_addr(ADAPTER))
job("wxdai.balanceOf.sdai", WXDAI, "0x70a08231"+enc_addr(SDAI))

job("gpc.isPaused.strat8", GPC, "0x5b14f183"+enc_addr(STR8))
job("gpc.isPaused.strat67", GPC, "0x5b14f183"+enc_addr(STR67))

# Agreement disputable info (strategies + known apps)
job("agreement.getDisputableInfo.strat8", AGREEMENT, "0xb86472b1"+enc_addr(STR8))
job("agreement.getDisputableInfo.strat67", AGREEMENT, "0xb86472b1"+enc_addr(STR67))
job("agreement.getDisputableInfo.strat27", AGREEMENT, "0xb86472b1"+enc_addr(STR27))
# collateral req id 3 for strategy 8/67 (same as main report's id for its app) - also try id 1
for which,s in [("strat8",STR8),("strat67",STR67)]:
    for cid in (1,2,3):
        job(f"agreement.getCollateralRequirement.{which}.{cid}", AGREEMENT, "0x221ce7c3"+enc_addr(s)+pad32(cid))

# Celeste arbitrator status (if contract): latestDisputeID? owner? => read code + a few getters
job("celeste.code", CELESTE, None)  # replaced below by eth_getCode
job("celeste.owner", CELESTE, "0x8da5cb5b")
job("celeste.getCurrentRuling.0", CELESTE, "0x2f8fa9d4"+pad32(0))  # Arbitrator interface guess

results={}
print("block:", blk, "jobs:", len(JOBS))

# fetch code for adapter + celeste + old agreement apps
codes={}
for a in [ADAPTER, CELESTE, "0x92bc0af737f55ff7b677cd942aafd52934fc751d", "0x1b8c7f06f537711a7caf6770051a43b4f3e69a7e"]:
    c=rpc("eth_getCode",[a,"latest"])
    codes[a]={"len_bytes":(len(c)-2)//2, "empty":c in ("0x","0x0")}
results["__codes"]=codes

ordered=[(i+1,j) for i,j in enumerate(JOBS)]
for s in range(0,len(ordered),10):
    chunk=ordered[s:s+10]
    calls=[]; labels=[]
    for _, (label,to,data,from_) in chunk:
        if data is None: results[label]={"note":"skipped"}; continue
        calls.append((to,data,from_)); labels.append(label)
    if not calls: continue
    out=batch(calls)
    for k,label in enumerate(labels):
        v=out.get(k+1)
        results[label]=({"error":v["__err"]} if isinstance(v,dict) else v)
    time.sleep(0.15)

def num(label):
    v=results.get(label)
    if isinstance(v,str) and v.startswith("0x") and v!="0x" and len(v)<=66:
        return int(v,16)
    return None

summary={"block":blk}
for pid in (8,67):
    out={}
    cv=results.get(f"strat{pid}.cvParams")
    if isinstance(cv,str) and len(cv)>=2+64*4:
        w=[cv[2+i*64:2+(i+1)*64] for i in range(4)]
        out["cvParams"]={"maxRatio":int(w[0],16),"weight":int(w[1],16),"decay":int(w[2],16),"minThresholdPoints":int(w[3],16)}
    for key in ["getPoolAmount","totalPointsActivated","getPoolThresholdPoints","pointSystem","proposalType","poolId","isPoolActive","proposalCounter","activeProposalCount","activeProposalCountInitialized","totalStaked","getMaxAmount","sybilScorer","currentArbitrableConfigVersion"]:
        out[key]=num(f"strat{pid}.{key}")
    for key in ["registryCommunity","getAllo","owner","pauseController"]:
        v=results.get(f"strat{pid}.{key}")
        out[key]=dec_addr(v) if isinstance(v,str) and len(v)>=42 else v
    ac=results.get(f"strat{pid}.getArbitrableConfig")
    if isinstance(ac,str) and len(ac)>=2+64*6:
        w=[ac[2+i*64:2+(i+1)*64] for i in range(6)]
        out["arbitrableConfig"]={"arbitrator":dec_addr("0x"+w[0]),"tribunalSafe":dec_addr("0x"+w[1]),
            "submitterCollateral":int(w[2],16),"challengerCollateral":int(w[3],16),
            "defaultRuling":int(w[4],16),"defaultRulingTimeout":int(w[5],16)}
    out["balances"]={"sdai":num(f"sdai.balanceOf.strat{pid}"),"wxdai":num(f"wxdai.balanceOf.strat{pid}"),
        "sdai_maxWithdraw":num(f"sdai.maxWithdraw.strat{pid}"),"sdai_maxRedeem":num(f"sdai.maxRedeem.strat{pid}")}
    for X in [250,500,1000,2000,4000,6000]:
        out[f"calculateThreshold({X})"]=num(f"strat{pid}.calculateThreshold({X})")
    summary[f"strategy{pid}"]=out

summary["rc"]={
    "enabledStrategies8":num("rc.enabledStrategies.8"),"enabledStrategies67":num("rc.enabledStrategies.67"),
    "hasRole_ALLOWLIST8_zero":num("rc.hasRole.ALLOWLIST8.zero"),"hasRole_ALLOWLIST67_zero":num("rc.hasRole.ALLOWLIST67.zero"),
    "hasRole_ALLOWLIST8_council":num("rc.hasRole.ALLOWLIST8.council"),"hasRole_ALLOWLIST67_council":num("rc.hasRole.ALLOWLIST67.council"),
    "hasRole_ALLOWLIST27_zero":num("rc.hasRole.ALLOWLIST27.zero"),
    "registerStakeAmount":num("rc.registerStakeAmount"),"communityFee":num("rc.communityFee"),"totalMembers":num("rc.totalMembers"),
    "councilSafe":dec_addr(results.get("rc.councilSafe")),"owner":dec_addr(results.get("rc.owner")),
}
summary["sdai"]={
    "asset":dec_addr(results.get("sdai.asset")),
    "convertToAssets(1e18)":num("sdai.convertToAssets.1e18"),
    "previewRedeem(1e18)":num("sdai.previewRedeem.1e18"),
    "previewRedeem(10000e18)":num("sdai.previewRedeem.10000e18"),
    "totalAssets":num("sdai.totalAssets"),"totalSupply":num("sdai.totalSupply"),"decimals":num("sdai.decimals"),
    "sdai_bal_adapter":num("sdai.balanceOf.adapter"),"wxdai_bal_adapter":num("wxdai.balanceOf.adapter"),"wxdai_bal_sdai":num("wxdai.balanceOf.sdai"),
}
summary["gpc"]={"isPaused8":num("gpc.isPaused.strat8"),"isPaused67":num("gpc.isPaused.strat67")}
summary["agreement"]={k:v for k,v in results.items() if k.startswith("agreement.")}
summary["allo_raw"]={str(pid):results.get(f"allo.getPool.{pid}") for pid in (8,67)}

json.dump({"block":blk,"rpc":RPC,"summary":summary,"raw":results},
          open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-live.json","w"),indent=1)
print(json.dumps(summary,indent=1))
