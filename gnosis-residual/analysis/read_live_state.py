#!/usr/bin/env python3
"""Live-state reader for 1Hive Gardens v2 (Gnosis). READ-ONLY eth_call. No keys.
Writes gardens-live-state.json into the analysis folder."""
import json, time, urllib.request

RPC = "https://gnosis-rpc.publicnode.com"
OUT = "/home/heisenberg/CA/gnosis-residual/analysis/gardens-live-state.json"

def rpc(method, params, _id=1):
    body = json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception as e:
            time.sleep(1.5*(attempt+1))
    raise RuntimeError("rpc failed")

def batch(calls):
    out=[]
    for i in range(0,len(calls),10):
        chunk=calls[i:i+10]
        body=[{"jsonrpc":"2.0","id":j,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for j,(nm,t,d) in enumerate(chunk)]
        req=urllib.request.Request(RPC,data=json.dumps(body).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        with urllib.request.urlopen(req,timeout=90) as r:
            res=json.load(r)
        res.sort(key=lambda x:x["id"])
        for (nm,t,d),rr in zip(chunk,res):
            out.append({"name":nm,"to":t,"data":d,"result":rr.get("result"),"error":rr.get("error")})
    return out

STRAT="0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2"
RC="0xE2396fe2169ca026962971d3B2E373Ba925B6257"
ALLO="0x1133eA7Af70876e64665ecD07C0A0476d09465a1"
FACT="0x08Df82f74D1f56F650E98da2dd4240F1A31711bc"
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
GPC="0xce853207ce3e16e268f572ea982801b8045f0afc"
COUNCIL="0xc6c2E9EFB898A42DB4137B07b727b45e0C353d81"
FRESH="0x000000000000000000000000000000000000dEaD"
ALLOWLIST_ROLE="0x"+ (b"ALLOWLIST".hex()) + "00"*31 + "1b"  # "ALLOWLIST" + uint256(27)

def sig(p8):  # tiny helper: caller passes full selector
    return p8

calls = [
 # strategy
 ("strat.cvParams", STRAT, "0x2506b870"),
 ("strat.getPoolAmount", STRAT, "0x4ab4ba42"),
 ("strat.totalPointsActivated", STRAT, "0xaba9ffee"),
 ("strat.totalStaked", STRAT, "0x817b1cd2"),
 ("strat.getPoolId", STRAT, "0x38fff2d0"),
 ("strat.isPoolActive", STRAT, "0xdf868ed3"),
 ("strat.pointSystem", STRAT, "0x2dbd6fdd"),
 ("strat.getMaxAmount", STRAT, "0x0ba95909"),
 ("strat.proposalCounter", STRAT, "0x0c0512e9"),
 ("strat.sybilScorer", STRAT, "0xb6c61f31"),
 ("strat.proposalType", STRAT, "0x351d9f96"),
 ("strat.registryCommunity", STRAT, "0x6003e414"),
 ("strat.getAllo", STRAT, "0x15cc481e"),
 ("strat.getPoolThresholdPoints", STRAT, "0x00735c98"),
 ("strat.activeProposalCount", STRAT, "0x76e43099"),
 ("strat.activeProposalCountInitialized", STRAT, "0x962896f6"),
 ("strat.votingPowerRegistry", STRAT, "0x80fd91cd"),
 ("strat.superfluidToken", STRAT, "0x05caa7f3"),
 ("strat.getArbitrableConfig", STRAT, "0x059351cd"),
 ("strat.getPointSystem", STRAT, "0xc3292171"),
 ("strat.currentArbitrableConfigVersion", STRAT, "0x125fd1d9"),
 ("strat.owner", STRAT, "0x8da5cb5b"),
 ("strat.pauseController", STRAT, "0x60b47789"),
 ("strat.conviction.p1", STRAT, "0x60b0645a"+"00"*31+"01"),
 ("strat.conviction.p2", STRAT, "0x60b0645a"+"00"*31+"02"),
 ("strat.conviction.p3", STRAT, "0x60b0645a"+"00"*31+"03"),
 ("strat.conviction.p4", STRAT, "0x60b0645a"+"00"*31+"04"),
 ("hny.balanceOf.strategy", HNY, "0x70a08231"+"00"*12+STRAT[2:].lower()),
 # RC
 ("rc.isMember.dead", RC, "0xa230c524"+"00"*12+FRESH[2:].lower()),
 ("rc.totalMembers", RC, "0x76e92559"),
 ("rc.hasRole.ALLOWLIST27.zero", RC, "0x91d14854"+ALLOWLIST_ROLE[2:]+"00"*12+"00"*20),
 ("rc.hasRole.ALLOWLIST27.council", RC, "0x91d14854"+ALLOWLIST_ROLE[2:]+"00"*12+COUNCIL[2:].lower()),
 ("rc.registerStakeAmount", RC, "0x78a0b8a9"),
 ("rc.communityFee", RC, "0x8961be6b"),
 ("rc.isKickEnabled", RC, "0x1f787d28"),
 ("rc.councilSafe", RC, "0x6c53db9a"),
 ("rc.owner", RC, "0x8da5cb5b"),
 ("rc.pauseController", RC, "0x60b47789"),
 ("rc.getBasisStakedAmount", RC, "0x0331383c"),
 ("rc.getStakeAmountWithFees", RC, "0x28c309e9"),
 ("rc.enabledStrategies.strat", RC, "0x3a871fe1"+"00"*12+STRAT[2:].lower()),
 ("rc.isCouncilMember.council", RC, "0xebd7dc52"+"00"*12+COUNCIL[2:].lower()),
 ("hny.balanceOf.rc", HNY, "0x70a08231"+"00"*12+RC[2:].lower()),
 ("hny.balanceOf.council", HNY, "0x70a08231"+"00"*12+COUNCIL[2:].lower()),
 ("hny.balanceOf.allo", HNY, "0x70a08231"+"00"*12+ALLO[2:].lower()),
 ("hny.totalSupply", HNY, "0x18160ddd"),
 # allo
 ("allo.getPool.27", ALLO, "0x068bcd8d"+"00"*31+"1b"),
 ("allo.isPoolManager.27.dead", ALLO, "0x29e40d4b"+"00"*31+"1b"+"00"*12+FRESH[2:].lower()),
 ("allo.isPoolManager.27.council", ALLO, "0x29e40d4b"+"00"*31+"1b"+"00"*12+COUNCIL[2:].lower()),
 # factory
 ("fact.getProtocolFee.rc", FACT, "0x0a992e0c"+"00"*12+RC[2:].lower()),
 ("fact.getGardensFeeReceiver", FACT, "0x987435be"),
 ("fact.globalPauseController", FACT, "0x8c68f2a9"),
 # global pause controller
 ("gpc.isPaused.strategy", GPC, "0x5b14f183"+"00"*12+STRAT[2:].lower()),
 ("gpc.isPaused.rc", GPC, "0x5b14f183"+"00"*12+RC[2:].lower()),
 ("gpc.paused", GPC, "0x5c975abb"),
]

block = rpc("eth_blockNumber", [])["result"]
res = batch(calls)
dump = {"chain":"gnosis","block":int(block,16),"rpc":RPC,"calls":res}
with open(OUT,"w") as f:
    json.dump(dump,f,indent=1)
print("block", int(block,16))
for c in res:
    print(f"{c['name']:42s} {c['result'] if c['result'] else 'ERR:'+json.dumps(c['error'])[:80]}")
