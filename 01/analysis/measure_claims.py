#!/usr/bin/env python3
"""Quantify outstanding redeemable claims: simulate redeem for the top-N margins by collateral."""
import json, urllib.request, time, base64
from solders.transaction import Transaction
from solders.message import Message
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.hash import Hash

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=4, timeout=120):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.0*(i+1))
    raise RuntimeError(str(last))

ZO = Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
STATE = Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
VAULT = Pubkey.from_string("HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ")
A2 = Pubkey.from_string("6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon")
A8 = Pubkey.from_string("Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt")
VAULT_ATA = Pubkey.from_string("3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp")
USDC = Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
REDEEM_DATA = bytes.fromhex("658ef6b8c6385cae")
M = lambda pk,s,w: AccountMeta(pk,s,w)

def ata(authority):
    pk,bump = Pubkey.find_program_address([bytes(authority),bytes(TOKEN),bytes(USDC)],ATA_PROG)
    return pk
def redeem_ix(signer,margin,control,dest):
    return Instruction(ZO,REDEEM_DATA,[M(STATE,False,True),M(VAULT,False,False),M(A2,False,True),
        M(signer,True,True),M(margin,False,True),M(control,False,True),M(dest,False,True),
        M(VAULT_ATA,False,True),M(A8,False,False),M(TOKEN,False,False)])
def ata_create_ix(payer,owner,ata_pk):
    return Instruction(ATA_PROG,bytes([1]),[M(payer,True,True),M(ata_pk,False,True),M(owner,False,False),
        M(USDC,False,False),M(SYSTEM,False,False),M(TOKEN,False,False)])

# sanity check ATA derivation
chk=ata(Pubkey.from_string("531euoNtZMvciBcKPBvYgFJoWnUvtu4PjasDhbTTXTGG"))
print("ATA derive check:", chk, "== 3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g ?", str(chk)=="3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g")

def sim(ixs,payer):
    msg=Message.new_with_blockhash(ixs,payer,Hash.default())
    tx=Transaction.new_unsigned(msg)
    b64=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]; logs=v.get("logs") or []
    amt=None; err=v.get("err")
    for l in logs:
        if "Program data:" in l:
            raw=base64.b64decode(l.split("Program data: ")[1].strip())
            if raw.hex().startswith("437a2f4a0f060e20") and len(raw)==80:
                amt=int.from_bytes(raw[-8:],"little")
    errmsg=""
    for l in logs:
        if "AnchorError" in l: errmsg=l.split("Error Message: ")[-1][:60]; break
    return amt, err, errmsg

rows=json.load(open("analysis/all_margins.json"))
def score(r): return max([abs(x) for x in r['collateral']], default=0)
cand=sorted(rows,key=score,reverse=True)
print("top 12 margins by max|collateral|:")
for r in cand[:12]:
    print(f"   {r['margin']} auth={r['authority'][:10]}.. max={score(r):.4f} nz={[(i,round(x,4)) for i,x in enumerate(r['collateral']) if abs(x)>1e-6]}")
cand=[r for r in cand if score(r)>=0.0001][:30]
print(f"\nsimulating {len(cand)} margins...")
results=[]; total=0
for r in cand:
    try:
        margin=Pubkey.from_string(r["margin"]); auth=Pubkey.from_string(r["authority"])
        mv=rpc("getAccountInfo",[r["margin"],{"encoding":"base64"}])["result"]["value"]
        raw=base64.b64decode(mv["data"][0]); ctrl=Pubkey.from_bytes(raw[441:473])
        dest=ata(auth)
        bal=rpc("getBalance",[r["authority"]])["result"]["value"]
        ixs=[redeem_ix(auth,margin,ctrl,dest)]
        if bal>=3_000_000:
            ixs=[ata_create_ix(auth,auth,dest)]+ixs
        amt,err,errmsg=sim(ixs,auth)
        if amt: total+=amt
        print(f"  {r['margin'][:14]}.. auth {r['authority'][:8]}.. claim_raw={amt} (${(amt or 0)/1e6:.6f}) err={json.dumps(err)[:60]} {errmsg}")
        results.append({"margin":r["margin"],"authority":r["authority"],"amount_raw":amt,"err":err,"errmsg":errmsg,"score":score(r)})
    except Exception as e:
        print("  ERR",r["margin"],e)
    time.sleep(0.1)
print(f"\nSUM of measured claims: {total} raw = ${total/1e6:.6f}")
json.dump({"results":results,"total_raw":total},open("analysis/claims_measured.json","w"),indent=1,default=str)
