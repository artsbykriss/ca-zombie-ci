#!/usr/bin/env python3
"""RateX (Solana) read-only probe: live state + attacker simulation matrix.
Writes JSON results to ../ci-out/ratex_results.json (or ./ratex_results.json).
Read-only: only getAccountInfo/getProgramAccounts/getTransaction/simulateTransaction(sigVerify=false).
"""
import json, os, sys, struct, base64, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s
import soltx
try:
    import base58 as b58
except Exception:
    import b58

PROG="RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D"
ADMIN="93KT94uivk9egZVPReW27pmUpiBsHhSV11AmUuSExUVU"
STATE="D332M7rsrdvF3VRcwMw3jvC4J5VPrwa2PoKEJQoCSbDV"
NEUTRAL="5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9"  # large public wallet, used only as an unprivileged signer
ORACLE="G9thCWkdCRBD7dLy68Kc3GG6EBTjE2xGkh51bFYpmhMJ"   # JitoSOL-2412 oracle
ORACLE2="Acm6ToXkt93Hft6RwWj81RFDAYayTwMq8rMbJck43oqG"  # bbSOL-2412 oracle (different market)
YM="6Z5Fg7cD1ubzwHcXYmGeeGLX6NzYfKPrxXQXezdA6gie"
OBS="BpKfP11JJ2cHS5e5YDgF27ZbvkJSPW3wgeVaMcBaaUZ3"
DISC={
 "update_oracle":[112,41,209,18,248,226,252,188],
 "update_yield_market_status":[177,3,6,192,64,227,170,23],
 "epoch_update_begin":[91,166,232,37,88,175,78,243],
 "rollback_oracle":[229,81,205,92,162,102,13,135],
 "observe":[204,78,178,115,194,147,65,74],
 "calculate_pt_price":[244,35,167,21,93,179,102,235],
 "earn_redeem":[93,162,58,1,75,18,212,66],
 "earn_invest":[110,63,157,138,202,152,33,172],
}
ACCT_DISC={
 "YieldMarket":[140,119,210,6,237,21,244,227],"EarnVault":[50,118,31,24,200,163,174,156],
 "Oracle":[139,194,131,179,140,179,229,244],"State":[216,146,107,94,104,75,182,177],
 "MarginMarket":[239,74,160,96,142,137,58,112],"Lp":[31,47,62,188,110,128,12,82],
 "User":[159,117,95,227,239,151,58,236],"ObservationState":[122,174,197,53,129,9,165,132],
}

def prog_info(pk):
    v=s.get_account_info(pk, encoding="base64")["result"]["value"]
    d=base64.b64decode(v["data"][0])
    pda=b58.b58encode(d[4:36]).decode()
    d2=base64.b64decode(s.get_account_info(pda, encoding="base64")["result"]["value"]["data"][0])
    return {"program":pk,"programdata":pda,"deployed_slot":int.from_bytes(d2[4:12],'little'),
            "upgrade_authority":b58.b58encode(d2[13:45]).decode() if d2[12]==1 else None,"elf_len":len(d2)-45}

def enum_types():
    out={}
    for name,disc in ACCT_DISC.items():
        r=s.rpc("getProgramAccounts",[PROG,{"encoding":"base64","commitment":"confirmed",
            "filters":[{"memcmp":{"offset":0,"bytes":b58.b58encode(bytes(disc)).decode()}}]}])
        out[name]=[a["pubkey"] for a in r.get("result",[])] if "error" not in r else []
    return out

def run(label, accounts, signers, data, fee_payer=NEUTRAL):
    res,keys=soltx.sim(accounts, signers, PROG, data, fee_payer=fee_payer)
    sm=soltx.summarize(res)
    return {"label":label,"err":sm.get("err"),"units":sm.get("units"),
            "anchor_err":sm.get("anchor_err"),"logs_tail":(sm.get("logs") or [])[-6:]}

def find_recent_ix(disc_bytes, scan=60):
    sigs=s.get_signatures(PROG, limit=scan).get("result",[])
    for sg in sigs:
        if sg.get("err"): continue
        tx=s.get_transaction(sg["signature"], encoding="jsonParsed").get("result")
        if not tx: continue
        m=tx["transaction"]["message"]
        signers={k["pubkey"] for k in m["accountKeys"] if k.get("signer")}
        for ix in m["instructions"]:
            if ix.get("programId")==PROG and ix.get("data"):
                try: raw=b58.b58decode(ix["data"])
                except Exception: continue
                if list(raw[:8])==disc_bytes:
                    return {"sig":sg["signature"],"accounts":ix["accounts"],"data":raw,"signers":signers}
    return None

def main():
    out={"prog":prog_info(PROG), "slot":s.get_slot()["result"], "types":enum_types()}
    results=[]
    # 1) admin gating
    args=struct.pack("<QQQq",1233886169,1233886169,1232221089,1759104603)
    d=bytes(DISC["update_oracle"])+args
    results.append(run("update_oracle:unprivileged-signer",[NEUTRAL,ORACLE,STATE],{NEUTRAL},d))
    results.append(run("update_oracle:admin-signer(control)",[ADMIN,ORACLE,STATE],{ADMIN},d))
    d=bytes(DISC["update_yield_market_status"])+bytes([2])
    results.append(run("update_yield_market_status:unprivileged",[NEUTRAL,STATE,YM,ORACLE],{NEUTRAL},d))
    d=bytes(DISC["epoch_update_begin"])+bytes([0])
    results.append(run("epoch_update_begin:unprivileged",[NEUTRAL,STATE,YM,ORACLE],{NEUTRAL},d))
    d=bytes(DISC["rollback_oracle"])+struct.pack("<QQQqq",1,1,1,1,1)
    results.append(run("rollback_oracle:unprivileged",[NEUTRAL,ORACLE,STATE],{NEUTRAL},d))
    # 2) permissionless views
    d=bytes(DISC["observe"])+b"\x01\x00\x00\x00"+b"\x00\x00\x00\x00"
    results.append(run("observe:permissionless",[YM,OBS],set(),d))
    results.append(run("calculate_pt_price:permissionless",[YM,"5mB83ye3jdjneDJDx15HAvYxT7SCsGZF5urpVMzuLr1t",ORACLE2],set(),bytes(DISC["calculate_pt_price"])))
    # 3) PT/YT pricing-path account substitution on a live earn_redeem
    er=find_recent_ix(DISC["earn_redeem"])
    if er:
        out["earn_redeem_tx"]=er["sig"]
        acc=er["accounts"]; d=er["data"]; sg=er["signers"]
        results.append(run("earn_redeem:replay-control",acc,sg,d))
        # locate oracle index by matching a known oracle
        oracles=set(out["types"].get("Oracle",[]))
        oi=next((i for i,a in enumerate(acc) if a in oracles),None)
        if oi is not None:
            other_o=[x for x in out["types"]["Oracle"] if x!=acc[oi]]
            if other_o:
                alt=list(acc); alt[oi]=other_o[0]
                results.append(run(f"earn_redeem:oracle-substituted(idx{oi})",alt,sg,d))
        yms=set(out["types"].get("YieldMarket",[]))
        yi=next((i for i,a in enumerate(acc) if a in yms),None)
        if yi is not None:
            other=[x for x in out["types"]["YieldMarket"] if x!=acc[yi]]
            if other:
                alt=list(acc); alt[yi]=other[0]
                results.append(run(f"earn_redeem:yield_market-substituted(idx{yi})",alt,sg,d))
        # authority substitution (unprivileged signer owning a different token account)
        ai=next((i for i,a in enumerate(acc) if a in sg),None)
        if ai is not None:
            alt=list(acc); alt[ai]=NEUTRAL
            results.append(run(f"earn_redeem:authority-substituted(idx{ai})",alt,{NEUTRAL},d))
    out["results"]=results
    dest=os.environ.get("OUT","ratex_results.json")
    os.makedirs(os.path.dirname(dest) or ".",exist_ok=True)
    json.dump(out,open(dest,"w"),indent=1)
    print(json.dumps(out,indent=1)[:4000])

if __name__=="__main__":
    main()
