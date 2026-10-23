#!/usr/bin/env python3
"""Oracle 071f push simulator. Read-only: simulateTransaction with sigVerify=false.
Usage: python3 sim_oracle.py [ix_index]   (0,1,2 -> which real tx push to replay)
"""
import json,base64,sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

TX=json.load(open("/home/heisenberg/CA/cardboard-trade/analysis/tx1.json"))["result"]
KEYS=TX["transaction"]["message"]["accountKeys"]
ORACLE="5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
EXCHANGE="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
P=lambda s: Pubkey.from_string(s)

# real oracle push account index lists (from tx1.json)
IX_ACCTS=[[12,7,20,41,3,42,8,19,32,30,15,21,40,37,16,23,31],
          [9,4,20,41,11,42,13,33,35,26,18,22,40,37,36,17,31],
          [2,10,20,41,1,42,6,29,38,39,27,28,40,37,34,24,31]]
WRITABLE=set(range(0,14))   # 0 signer + 1..13 unsigned writable (from tx header)

def simulate(ixs,payer,label,acct_out=None):
    msg=Message.new_with_blockhash(ixs, payer, Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    cfg={"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}
    if acct_out:
        cfg["accounts"]={"encoding":"base64","addresses":[{"address":a} for a in acct_out]}
    r=rpc("simulateTransaction",[raw,cfg])
    v=r.get("result",{}).get("value",{})
    print(f"\n===== {label} =====\nerr:{v.get('err')}  cu:{v.get('unitsConsumed')}")
    for l in (v.get("logs") or []):
        print("   ",l)
    for a in v.get("accounts") or []:
        d=a.get("data")
        dl=len(base64.b64decode(d[0])) if d else None
        print(f"   POST {a.get('pubkey')} lamports={a.get('lamports')} len={dl} data={(base64.b64decode(d[0]).hex()[:80] if d else None)}")
    return v

def build_oracle_ix(idx, override=None, payer_signer=False):
    accts=list(IX_ACCTS[idx])
    if override:
        for pos,newkey in override.items():
            accts[pos]=newkey if isinstance(newkey,int) else KEYS.index(newkey)
    metas=[]
    for pos,i in enumerate(accts):
        metas.append(AccountMeta(P(KEYS[i]), payer_signer and pos==0, i in WRITABLE))
    return Instruction(P(ORACLE), bytes.fromhex("071f"), metas)

if __name__=="__main__":
    idx=int(sys.argv[1]) if len(sys.argv)>1 else 0
    mode=sys.argv[2] if len(sys.argv)>2 else "real"
    payer=Pubkey.from_string(KEYS[0])
    if mode=="real":
        # oracle-owned accounts that should update: feed(12) + weights(7) for ix0
        out=[KEYS[12],KEYS[7],KEYS[3],KEYS[8]]
        simulate([build_oracle_ix(idx)], payer, f"ORACLE push 071f ix{idx} (real accounts, payer=keeper, sigVerify=false)", out)
    elif mode=="freshpayer":
        # fresh random payer (no lamports) - test permissionlessness
        import secrets
        fp=Keypair() if False else None
        from solders.keypair import Keypair as KP
        kp=KP()
        simulate([build_oracle_ix(idx)], kp.pubkey(), f"ORACLE push 071f ix{idx} (FRESH random payer)", [KEYS[12],KEYS[7]])
