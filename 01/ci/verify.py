#!/usr/bin/env python3
"""
Consolidated live verification for the "01" (01 Exchange / 01.xyz) Solana wind-down program.
Read-only: uses public RPC + simulateTransaction (sigVerify=false, replaceRecentBlockhash=true).
Writes ci-out/01-verify.json and ci-out/01-verify.txt.
"""
import json, urllib.request, time, base64, hashlib, os, sys, datetime
from solders.transaction import VersionedTransaction, Transaction
from solders.message import Message
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.hash import Hash

OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)

RPC=os.environ.get("SOLANA_RPC","https://api.mainnet-beta.solana.com")
FALLBACKS=["https://solana-rpc.publicnode.com","https://api.mainnet-beta.solana.com"]
_cur=[RPC]
def rpc(method, params, retries=5, timeout=120):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        for url in _cur+[u for u in FALLBACKS if u not in _cur]:
            try:
                req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
                with urllib.request.urlopen(req,timeout=timeout) as r: out=json.loads(r.read())
                if "error" in out: raise RuntimeError(out["error"])
                if url!=_cur[0]: _cur.insert(0,url)
                return out
            except Exception as e:
                last=e
        time.sleep(1.2*(i+1))
    raise RuntimeError(f"{method}: {last}")

ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,rem=divmod(n,58); s=ALPH[rem]+s
    for by in b:
        if by==0: s='1'+s
        else: break
    return s or '1'

ZO=Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TOKEN=Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_PROG=Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYSTEM=Pubkey.from_string("11111111111111111111111111111111")
STATE=Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
VAULT=Pubkey.from_string("HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ")
A2=Pubkey.from_string("6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon")
A8=Pubkey.from_string("Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt")
VAULT_ATA=Pubkey.from_string("3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp")
USDC=Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
REDEEM=bytes.fromhex("658ef6b8c6385cae")
FINALIZE=bytes.fromhex("cbc28cbd27150e21")
SETRATES=bytes.fromhex("c2fc9bfe1d8a3348")
ADMIN=Pubkey.from_string("DH7N1sJQxyLJqc79fk67U32mymejUiRVH8SqayTuRtG7")
M=lambda pk,s,w: AccountMeta(pk,s,w)

def ata(a):
    pk,_=Pubkey.find_program_address([bytes(a),bytes(TOKEN),bytes(USDC)],ATA_PROG); return pk
def redeem_ix(signer,margin,control,dest):
    return Instruction(ZO,REDEEM,[M(STATE,False,True),M(VAULT,False,False),M(A2,False,True),
        M(signer,True,True),M(margin,False,True),M(control,False,True),M(dest,False,True),
        M(VAULT_ATA,False,True),M(A8,False,False),M(TOKEN,False,False)])
def ata_create_ix(payer,owner,a):
    return Instruction(ATA_PROG,bytes([1]),[M(payer,True,True),M(a,False,True),M(owner,False,False),
        M(USDC,False,False),M(SYSTEM,False,False),M(TOKEN,False,False)])
def sim(ixs,payer):
    msg=Message.new_with_blockhash(ixs,payer,Hash.default())
    tx=Transaction.new_unsigned(msg)
    b64=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]; logs=v.get("logs") or []
    amt=None
    for l in logs:
        if "Program data:" in l:
            raw=base64.b64decode(l.split("Program data: ")[1].strip())
            if raw.hex().startswith("437a2f4a0f060e20") and len(raw)==80:
                amt=int.from_bytes(raw[-8:],"little")
    errmsg=""
    for l in logs:
        if "AnchorError" in l:
            errmsg=l.split("Error Message: ")[-1][:90] if "Error Message" in l else l[-90:]
            break
    return {"err":v.get("err"),"amount_raw":amt,"errmsg":errmsg}

report={"generated_at":datetime.datetime.utcnow().isoformat()+"Z","rpc":RPC}

# ---------- 1. live state ----------
slot=rpc("getSlot",[{"commitment":"finalized"}])["result"]
bal=rpc("getTokenAccountBalance",[str(VAULT_ATA)])["result"]["value"]
report["slot"]=slot
report["vault_usdc_ui"]=bal["uiAmountString"]
report["vault_usdc_raw"]=bal["amount"]
prog=rpc("getAccountInfo",[str(ZO),{"encoding":"jsonParsed"}])["result"]["value"]
pd=prog["data"]["parsed"]["info"]["programData"]
pdr=rpc("getAccountInfo",[pd,{"encoding":"base64"}])["result"]["value"]
raw=base64.b64decode(pdr["data"][0])
up_auth=b58e(raw[13:45]) if raw[12]==1 else None
report["zo_program"]={"programData":pd,"last_deploy_slot":int.from_bytes(raw[4:12],"little"),
                      "upgrade_authority":up_auth,"upgrade_authority_on_curve":Pubkey.from_string(up_auth).is_on_curve() if up_auth else None}
va=rpc("getAccountInfo",[str(VAULT),{"encoding":"jsonParsed"}])["result"]["value"]
report["vault_pda"]={"owner":va["owner"],"space":va["space"],"on_curve":VAULT.is_on_curve(),"lamports":va["lamports"]}
margs=rpc("getProgramAccounts",[str(ZO),{"encoding":"base64","filters":[{"dataSize":793},{"memcmp":{"offset":0,"bytes":b58e(bytes.fromhex("98118ec350c4a130"))}}],"dataSlice":{"offset":0,"length":441},"commitment":"confirmed"}])["result"]
report["margin_accounts"]=len(margs)

# ---------- 2. RedeemUsdc gate tests ----------
# top funded margin by collateral
best=None
for a in margs:
    raw=base64.b64decode(a["account"]["data"][0])
    vals=[int.from_bytes(raw[41+i*16:41+i*16+16],"little") for i in range(25)]
    # signed decode
    def i80(v):
        return (v-(1<<128))/2**48 if v&(1<<127) else v/2**48
    mx=max(abs(i80(v)) for v in vals)
    if best is None or mx>best[0]:
        best=(mx, a["pubkey"], b58e(raw[9:41]), raw)
score, margin_pk, auth_pk, mraw = best
margin=Pubkey.from_string(margin_pk); auth=Pubkey.from_string(auth_pk)
full=rpc("getAccountInfo",[margin_pk,{"encoding":"base64"}])["result"]["value"]
mfull=base64.b64decode(full["data"][0])
ctrl=Pubkey.from_bytes(mfull[441:473])
report["top_margin"]={"margin":margin_pk,"authority":auth_pk,"max_collateral_i80f48":score}
dest=ata(auth)
tests={}
tests["T1_own_redeem"]=sim([ata_create_ix(ADMIN,auth,dest), redeem_ix(auth,margin,ctrl,dest)],ADMIN)
tests["T2_impersonation"]=sim([ata_create_ix(ADMIN,auth,dest), redeem_ix(ADMIN,margin,ctrl,dest)],ADMIN)
tests["T3_foreign_dest"]=sim([redeem_ix(auth,margin,ctrl,ata(ADMIN))],auth)
tests["T4_fresh_signer"]=sim([ata_create_ix(ADMIN,auth,dest), redeem_ix(Pubkey.new_unique(),margin,ctrl,dest)],ADMIN)
# zamm margin + forged zamm key
ZM=Pubkey.from_string("CX2tWRJC9z3L6zwnBTAk2keWVzUXgju6LFu9wzso9Zfn")
zmv=rpc("getAccountInfo",[str(ZM),{"encoding":"base64"}])["result"]["value"]
zmraw=base64.b64decode(zmv["data"][0]); zauth=Pubkey.from_bytes(zmraw[9:41]); zctrl=Pubkey.from_bytes(zmraw[441:473])
zdest=ata(zauth); forged=Pubkey.new_unique()
tests["T5_zamm_forged_key"]=sim([ata_create_ix(ADMIN,zauth,zdest),
    Instruction(ZO,REDEEM,[M(STATE,False,True),M(VAULT,False,False),M(A2,False,True),M(zauth,True,True),
        M(ZM,False,True),M(zctrl,False,True),M(zdest,False,True),M(VAULT_ATA,False,True),M(A8,False,False),
        M(TOKEN,False,False),M(forged,False,False)])],ADMIN)
report["redeem_gate_tests"]=tests

# ---------- 3. admin gate tests (fresh signer) ----------
fresh=Pubkey.new_unique()
def admin_ix(disc,accounts,args=b""):
    return Instruction(ZO,disc+args,[M(pk,s,w) for (pk,s,w) in accounts])
# FinalizeWinddown accounts: [admin(signer), state, A8]
t6=sim([admin_ix(FINALIZE,[(fresh,True,True),(STATE,False,True),(A8,False,True)])],fresh)
# SetManualRatesAndOverrides accounts: [admin, state, A8] + args(29 bytes placeholder)
t7=sim([admin_ix(SETRATES,[(fresh,True,True),(STATE,False,True),(A8,False,True)],bytes(29))],fresh)
report["admin_gate_tests"]={"T6_finalize_fresh":t6,"T7_setrates_fresh":t7}

# ---------- 4. claim measurement (top 25) ----------
def i80(v): return (v-(1<<128))/2**48 if v&(1<<127) else v/2**48
cand=[]
for a in margs:
    raw=base64.b64decode(a["account"]["data"][0])
    vals=[i80(int.from_bytes(raw[41+i*16:41+i*16+16],"little")) for i in range(25)]
    mx=max(abs(v) for v in vals)
    if mx>1e-6: cand.append((mx,a["pubkey"],b58e(raw[9:41]),raw))
cand.sort(reverse=True)
total=0; measured=[]; n=0
for mx,mpk,apk,raw in cand[:25]:
    try:
        margin=Pubkey.from_string(mpk); auth=Pubkey.from_string(apk)
        full=rpc("getAccountInfo",[mpk,{"encoding":"base64"}])["result"]["value"]
        ctrl=Pubkey.from_bytes(base64.b64decode(full["data"][0])[441:473]); dest=ata(auth)
        r=sim([ata_create_ix(ADMIN,auth,dest), redeem_ix(auth,margin,ctrl,dest)],ADMIN)
        if r["amount_raw"]: total+=r["amount_raw"]; n+=1
        measured.append({"margin":mpk,"claim_raw":r["amount_raw"],"claim_usd":(r["amount_raw"] or 0)/1e6,"errmsg":r["errmsg"]})
    except Exception as e:
        measured.append({"margin":mpk,"error":str(e)})
    time.sleep(0.05)
report["claims_top25"]={"n_measured":n,"sum_raw":total,"sum_usd":total/1e6,"rows":measured}

txt=[f"01 (01 Exchange) Solana wind-down — live verification @ slot {slot} ({datetime.datetime.utcnow().isoformat()}Z)",
     f"Vault USDC: {bal['uiAmountString']} (${float(bal['uiAmountString']):.2f})",
     f"Margin accounts: {len(margs)}",
     f"zo program upgrade authority: {up_auth} (on-curve={report['zo_program']['upgrade_authority_on_curve']})",
     "",
     "RedeemUsdc gate tests:"]
for k,v in tests.items(): txt.append(f"  {k}: err={json.dumps(v['err'])} amount={v['amount_raw']} {v['errmsg']}")
txt.append("Admin gate tests:")
for k,v in report["admin_gate_tests"].items(): txt.append(f"  {k}: err={json.dumps(v['err'])} {v['errmsg']}")
txt.append(f"Claims measured (top25): {n} margins, ${total/1e6:.2f}")
open(os.path.join(OUT,"01-verify.txt"),"w").write("\n".join(txt)+"\n")
json.dump(report,open(os.path.join(OUT,"01-verify.json"),"w"),indent=1,default=str)
print("\n".join(txt))
