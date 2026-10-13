#!/usr/bin/env python3
"""Multi-redeem in ONE tx: verify each margin pays its standalone nominal amount (pro-rata test)."""
import json, urllib.request, time, base64
from solders.transaction import Transaction
from solders.message import Message
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.hash import Hash

RPC="https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=4, timeout=90):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=timeout) as r: out=json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.0*(i+1))
    raise RuntimeError(str(last))

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
M=lambda pk,s,w: AccountMeta(pk,s,w)
PAYER=Pubkey.from_string("DH7N1sJQxyLJqc79fk67U32mymejUiRVH8SqayTuRtG7")

def ata(a):
    pk,_=Pubkey.find_program_address([bytes(a),bytes(TOKEN),bytes(USDC)],ATA_PROG); return pk
def redeem_ix(signer,margin,control,dest):
    return Instruction(ZO,REDEEM,[M(STATE,False,True),M(VAULT,False,False),M(A2,False,True),
        M(signer,True,True),M(margin,False,True),M(control,False,True),M(dest,False,True),
        M(VAULT_ATA,False,True),M(A8,False,False),M(TOKEN,False,False)])
def ata_create_ix(owner,a):
    return Instruction(ATA_PROG,bytes([1]),[M(PAYER,True,True),M(a,False,True),M(owner,False,False),
        M(USDC,False,False),M(SYSTEM,False,False),M(TOKEN,False,False)])

rows={r['margin']:r for r in json.load(open('analysis/all_margins.json'))}
allr=[]
for f in ['analysis/claims_measured_top45.json','analysis/claims_measured_tail100.json','analysis/claims_measured_146_400.json']:
    for r in json.load(open(f))['results']:
        if r.get('amount_raw'): allr.append(r)
allr.sort(key=lambda r:-r['amount_raw'])
top=allr[:3]
print("top6 standalone claims:", [(r['margin'][:10], r['amount_raw']/1e6) for r in top])

ixs=[]
expected=[]
for r in top:
    margin=Pubkey.from_string(r['margin']); auth=Pubkey.from_string(rows[r['margin']]['authority'])
    full=rpc("getAccountInfo",[r['margin'],{"encoding":"base64"}])["result"]["value"]
    ctrl=Pubkey.from_bytes(base64.b64decode(full["data"][0])[441:473])
    dest=ata(auth)
    ixs.append(ata_create_ix(auth,dest))
    ixs.append(redeem_ix(auth,margin,ctrl,dest))
    expected.append((r['margin'], r['amount_raw']))
msg=Message.new_with_blockhash(ixs,PAYER,Hash.default())
tx=Transaction.new_unsigned(msg)
raw=bytes(tx)
print("tx size:", len(raw), "bytes")
b64=base64.b64encode(raw).decode()
res=rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
v=res["result"]["value"]
print("err:", json.dumps(v.get("err")))
amounts=[]
for l in (v.get("logs") or []):
    if "Program data:" in l:
        raw2=base64.b64decode(l.split("Program data: ")[1].strip())
        if raw2.hex().startswith("437a2f4a0f060e20") and len(raw2)==80:
            amounts.append(int.from_bytes(raw2[-8:],"little"))
print("RedeemUsdcLog amounts in tx:", amounts)
print("expected (standalone):", [e[1] for e in expected])
tot=sum(amounts); exp=sum(e[1] for e in expected)
print(f"paid total=${tot/1e6:.2f} vs standalone total=${exp/1e6:.2f}")
# vault delta
pre=post=None
for b in v.get("preTokenBalances") or []:
    if b["mint"]==str(USDC) and b["owner"]=="HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ":
        pre=int(b["uiTokenAmount"]["amount"])
for b in v.get("postTokenBalances") or []:
    if b["mint"]==str(USDC) and b["owner"]=="HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ":
        post=int(b["uiTokenAmount"]["amount"])
print("vault ATA:", pre, "->", post, "delta:", (post-pre) if (pre is not None and post is not None) else None)
json.dump({"err":v.get("err"),"amounts":amounts,"expected":[e[1] for e in expected],"logs":v.get("logs")},open("analysis/sim_multi_redeem.json","w"),indent=1,default=str)
