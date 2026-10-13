#!/usr/bin/env python3
"""1) verify discriminators 2) simulate redeem for the 2nd large margin (with ATA create) 3) test dest constraint."""
import json, urllib.request, time, base64, hashlib
from solders.transaction import Transaction
from solders.message import Message
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.hash import Hash

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=5, timeout=120):
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
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPH.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    pad=len(s)-len(s.lstrip('1'))
    return b'\x00'*pad+b

# 1) discriminators
names=["cache_oracle","close_margin","consume_events","create_margin","finalize_winddown",
       "force_cancel_all_perp_orders","init_state","init_winddown_book","redeem_usdc",
       "set_manual_rates_and_overrides","settle_collateral","update_heimdall","update_oracle","zamm_transfer"]
print("=== Anchor discriminators ===")
for n in names:
    d=hashlib.sha256(("global:"+n).encode()).digest()[:8]
    print(f"  {n:35s} {d.hex()}")
print("observed data:")
for label,datab58 in [("FinalizeWinddown","b5jA8aNeZ8L"),("InitWinddownBook","gJBWVMfqMVq"),
                      ("SetManualRates","7Y2fnrVYSVXXyb2iauGWzsHijzPnxAneMbqFZXgbfToKQ7qkENs"),
                      ("SettleCollateral","JifiSkzTqEEs4BD3xYLkG5Z7YiV64Yrxj9"),
                      ("ZammTransfer?","HzFAW1frkkV")]:
    b=b58d(datab58)
    print(f"  {label:20s} {b[:8].hex()} (len {len(b)})")

# 2) ATA create + redeem for 99000-margin owner
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

def find_pda(seeds, program_id):
    pid=bytes(program_id)
    for bump in range(255,-1,-1):
        h=hashlib.sha256(pid+b''.join(seeds)+bytes([bump])+pid+b"ProgramDerivedAddress").digest()
        p=0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed
        d=(p-121665)*pow(121666,p-2,p)%p
        y=int.from_bytes(h,'little')&((1<<255)-1); ok=False
        if y<p:
            y2=y*y%p; u=(y2-1)%p; v=(d*y2+1)%p; x2=u*pow(v,p-2,p)%p
            ok=(x2==0) or (pow(x2,(p-1)//2,p)==1)
        if not ok: return Pubkey.from_bytes(h),bump
    return None,None
def ata(authority):
    return find_pda([bytes(authority),bytes(TOKEN),bytes(USDC)],ATA_PROG)[0]

def redeem_ix(signer,margin,control,dest):
    return Instruction(ZO,REDEEM_DATA,[M(STATE,False,True),M(VAULT,False,False),M(A2,False,True),
        M(signer,True,True),M(margin,False,True),M(control,False,True),M(dest,False,True),
        M(VAULT_ATA,False,True),M(A8,False,False),M(TOKEN,False,False)])

def ata_create_ix(payer,owner,ata_pk):
    return Instruction(ATA_PROG,bytes([1]),[M(payer,True,True),M(ata_pk,False,True),M(owner,False,False),
        M(USDC,False,False),M(SYSTEM,False,False),M(TOKEN,False,False)])

def sim(ixs,payer,label):
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
    print(f"\n### {label}\n  err: {json.dumps(v.get('err'))}\n  RedeemUsdcLog amount(raw): {amt}")
    for l in logs:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l.lower(): print("   log:",l[:180])
    return {"label":label,"err":v.get("err"),"amount":amt,"logs":logs}

results=[]
# 2) 99000 margin
M99000=Pubkey.from_string("12Vgds9vkUgW9QjeMCtnx71HzVfDmwj48bjpcE3RW8AN")
mv=rpc("getAccountInfo",[str(M99000),{"encoding":"base64"}])["result"]["value"]
raw=base64.b64decode(mv["data"][0]); A99000=Pubkey.from_bytes(raw[9:41]); C99000=Pubkey.from_bytes(raw[441:473])
bal=rpc("getBalance",[str(A99000)])["result"]["value"]
print("99000-margin authority:",A99000,"control:",C99000,"SOL balance:",bal)
dest=ata(A99000)
results.append(sim([ata_create_ix(A99000,A99000,dest), redeem_ix(A99000,M99000,C99000,dest)],A99000,
   "T-OWN2: 99000-margin owner redeems (ATA created in-tx)"))

# 3) dest constraint: 531euoNt signer, own margin, dest = funded user's ATA
S531=Pubkey.from_string("531euoNtZMvciBcKPBvYgFJoWnUvtu4PjasDhbTTXTGG")
S531_ATA=Pubkey.from_string("3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g")
S531_MARGIN=Pubkey.from_string("5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8")
S531_CTRL=Pubkey.from_string("4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV")
A_FUND_ATA=Pubkey.from_string("2CwcHD2rawi5WKzxbdr7qUtvfbeu8rubWXwEFNj6gvoU")
results.append(sim([redeem_ix(S531,S531_MARGIN,S531_CTRL,A_FUND_ATA)],S531,
   "T-DEST: 531euoNt own margin -> FUNDED USER's ATA (dest-authority check?)"))

json.dump(results,open("analysis/sim_redeem4.json","w"),indent=1,default=str)
print("\nDONE")
