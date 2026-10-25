#!/usr/bin/env python3
"""Loopscale Curation (Solana) read-only probe: Exponent strategy vaults whose curator role is
Loopscale Asset Curation, plus the gating simulation matrix for the vault program.
Writes JSON to $OUT (default loopscale_results.json).
Read-only: getAccountInfo / getProgramAccounts / getSignaturesForAddress / getTransaction /
simulateTransaction(sigVerify=false).
"""
import json, os, sys, base64, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s
import soltx
import pda
try:
    import base58 as b58
except Exception:
    import b58

PROG="sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD"
DISC=bytes([98,228,39,201,116,210,39,11])
CUR_B58="bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN"
CUR=b58.b58decode(CUR_B58)
NEUTRAL="5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9"

def prog_info(pk):
    v=s.get_account_info(pk, encoding="base64")["result"]["value"]
    d=base64.b64decode(v["data"][0]); pdaa=b58.b58encode(d[4:36]).decode()
    d2=base64.b64decode(s.get_account_info(pdaa, encoding="base64")["result"]["value"]["data"][0])
    auth=b58.b58encode(d2[13:45]).decode() if d2[12]==1 else None
    return {"program":pk,"programdata":pdaa,"deployed_slot":int.from_bytes(d2[4:12],'little'),
            "upgrade_authority":auth,"upgrade_authority_on_curve":bool(auth and pda.is_on_curve(b58.b58decode(auth))),
            "elf_len":len(d2)-45}

def vaults():
    r=s.rpc("getProgramAccounts",[PROG,{"encoding":"base64","commitment":"confirmed",
        "filters":[{"memcmp":{"offset":0,"bytes":b58.b58encode(DISC).decode()}}]}])
    out=[]
    for a in r["result"]:
        d=base64.b64decode(a["account"]["data"][0])
        if CUR not in d: continue
        X=d.find(CUR); cnt=int.from_bytes(d[X-4:X],'little')
        curators=[b58.b58encode(d[X+32*i:X+32*i+32]).decode() for i in range(min(cnt,8))]
        # parse tokenEntries (priceId Simple/Multiply)
        o=8+32*3; n=int.from_bytes(d[o:o+4],'little'); o+=4; entries=[]
        if n<=20:
            for _ in range(n):
                try:
                    mint=b58.b58encode(d[o:o+32]).decode(); o+=32
                    k=d[o]; o+=1
                    if k==0: o+=8
                    elif k==1: m=int.from_bytes(d[o:o+4],'little'); o+=4+m*8
                    else: break
                    sq=b58.b58encode(d[o:o+32]).decode(); o+=32
                    tv=b58.b58encode(d[o:o+32]).decode(); o+=32
                    last=int.from_bytes(d[o:o+8],'little'); o+=8
                    fn=int.from_bytes(d[o:o+4],'little'); o+=4+fn*8
                    entries.append({"mint":mint,"token_account_vault":tv})
                except Exception:
                    break
        out.append({"vault":a["pubkey"],"len":len(d),
                    "squads_settings":b58.b58encode(d[40:72]).decode(),
                    "squads_vault":b58.b58encode(d[72:104]).decode(),
                    "curator_count":cnt,"curators":curators,"token_entries":entries})
    return out

def token_vault_balances(entries):
    tot={}
    addrs=[e["token_account_vault"] for e in entries if e.get("token_account_vault")]
    if not addrs: return tot
    for i in range(0,len(addrs),80):
        vals=s.rpc("getMultipleAccounts",[addrs[i:i+80],{"encoding":"jsonParsed","commitment":"confirmed"}])["result"]["value"]
        for a,v in zip(addrs[i:i+80],vals):
            if not v: continue
            try:
                info=v["data"]["parsed"]["info"]
                m=info["mint"]; amt=float(info["tokenAmount"]["uiAmountString"] or 0)
                tot[m]=tot.get(m,0)+amt
            except Exception:
                pass
    return tot

def squads_vault_value(sq):
    try:
        r=s.get_token_accounts_by_owner(sq)
        accts=r.get("result",{}).get("value",[])
    except Exception:
        return {}
    tot={}
    for a in accts:
        info=a["account"]["data"]["parsed"]["info"]
        m=info["mint"]; amt=float(info["tokenAmount"]["uiAmountString"] or 0)
        tot[m]=tot.get(m,0)+amt
    return tot

def price(mints):
    prices={}
    ms=list(mints)
    for i in range(0,len(ms),50):
        url="https://coins.llama.fi/prices/current/"+",".join(f"solana:{m}" for m in ms[i:i+50])
        try:
            d=json.load(urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"audit"})))
            prices.update(d.get("coins",{}))
        except Exception as e:
            pass
    return prices

def run(label, accounts, data, fee=NEUTRAL):
    res,keys=soltx.sim(accounts, set(), PROG, data, fee_payer=fee)
    sm=soltx.summarize(res)
    return {"label":label,"err":sm.get("err"),"anchor_err":sm.get("anchor_err")}

def main():
    out={"prog":prog_info(PROG),"slot":s.get_slot()["result"]}
    vs=vaults()
    out["curated_vault_count"]=len(vs)
    # live value held by each vault's token_account_vault entries
    allmints={}; per=[]
    for v in vs:
        tot=token_vault_balances(v["token_entries"])
        per.append({"vault":v["vault"],"curators":v["curators"],"balances":tot})
        for m,a in tot.items(): allmints[m]=allmints.get(m,0)+a
    prices=price(allmints)
    usd=0; detail=[]
    for m,a in allmints.items():
        p=prices.get(f"solana:{m}",{}).get("price")
        if p: usd+=a*p
        detail.append({"mint":m,"amount":a,"price":p,"usd":(a*p if p else None)})
    out["vaults"]=per
    out["vault_value_detail"]=detail
    out["vault_value_usd"]=round(usd,2)
    # gating simulation matrix (using a live UpdatePrice tx + neutral signer)
    up=["ACfqroCCvTQBocSt5DdRuCu5DKbQm7cLDrxKkSzyvFb","S5RKRU7ESAL13NoC7Rd9RAwk37E3ZUpkCPVULU1FpC2",
        "FZTyomD17Y47VUHVt1reKvGYE5yr6itFEVqCHz2pRC68","3t4JZcueEzTbVP6kLxXrL3VpWx45jDer4eqysweBchNH",
        "ERhozr6u9drmAANXGRNP1oh3quSqPKEwioKH5b8v9Kkt"]
    d=bytes.fromhex("07020000001a0000000000000000200000000000000001")
    res=[]
    res.append(run("UpdatePrice:control",up,d))
    a=list(up); a[0]=up[1]; res.append(run("UpdatePrice:prices-PDA-substituted",a,d))
    a=list(up); a[1]=up[2]; res.append(run("UpdatePrice:price-entry-substituted",a,d))
    a=list(up); a[4]=up[0]; res.append(run("UpdatePrice:feed-account-substituted",a,d))
    out["sims"]=res
    dest=os.environ.get("OUT","loopscale_results.json")
    json.dump(out,open(dest,"w"),indent=1)
    print(json.dumps(out,indent=1)[:3500])

if __name__=="__main__":
    main()
