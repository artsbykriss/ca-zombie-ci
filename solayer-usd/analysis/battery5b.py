#!/usr/bin/env python3
"""battery5b: remaining gating tests, fixed payloads."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solsim as S, solrpc as rpc, pda

PROG="s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
POOL="FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
SUSD="susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
CUSDO="BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
MANAGER="7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru"
OPERATOR="AxnDY6nekRa4hEY1rm1g11A51EPPU29iAXXxh8vAqpM8"
RATEAUTH="uRwMu2114gN23NZVFxkjM6Dwk1iqSc1LLQsHMmiT6Lr"
FEERECIP="3NC1UF4pus6ditVzbcJCLFCVyBLVJm2kxKMhb3mPAoaz"
POOL_USDC_MAIN="DN2KzAeiHFnndVpjWSTw8UkwF9PZaFSthSnVoW1MVThQ"
POOL_USDC_WITHDRAW="usdcLDuDT41YeWcbiMLJ6AoqTumSbJtTQCebJsZJsih"
POOL_SUSD_VAULT="FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds"
POOL_SUSD_RESERVE="93AZbo6a7De8YjSMbAL8xVasetsfwUjJnU5HMnzEaFXK"
OPENEDEN="9HhZLsdF8pGQ9fuSJH5UnqJyXBeuMJ729eYVesXCC6mc"
SUSDOFF="5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz"
SUNSET="EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh"
RWA_VAULT="G9UFgtiWKkuJ2ekuYJJpYxdk8hbNjNkzPcN7p2xd4gkd"
POOL_RWA_MAIN="2pR6cGbrJz9EAdo2Qo9eiUkNa75QZRLGX4bhpdMXnFRM"
RWA_TOKEN_VAULT_AUTH="HkYTTC8Cqp1dFvz2smP5fzpU79dGWWCmqEQ4xocpVncR"
USDC_VAULT="5kEhbsRrjmuNDmcnstxPDXAuLVzQQraZPXFRrPggVTjy"
USDC_VAULT_AUTH="FPyi9yJKNX8y5gkadeFvbC2pDB9VVqxpwfofHxJ6Ed7i"
HOOK="48n7YGEww7fKMfJ5gJ3sQC3rM6RWGjpUsghqVfXVkR5A"
EXTRAMETAS="9sQhAH7vV3RKTCK13VY4EiNjs3qBq1srSYxdNufdAAXm"
PAUSE="98wFF5MpMjMQbfDF2MPzo8LCGX37unZR1ohRA1mU9GmJ"
DEP_PROOF="6kaVVdLZwVzakoGU4mL7WSuKP4M4CDZgG6z1KXD88WBG"
MIG="3U2chkhnisqEoPT8WToTqRSSNKZuNJ45NJJxCNVc6ZHX"
DEP_PROOF_USER_VAULT="4GKFBc5DbLxGRDcF6tQLk2wkft3aqpfRN46Rx32jUVhQ"
ATA="ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
SYS="11111111111111111111111111111111"
_D = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "discriminators.json")))["instructions"]
D = {v: k for k, v in _D.items()}
def disc(n): return bytes.fromhex(D[n])
def W(k): return (k, True, False)
def R(k): return (k, False, False)
def SG(k): return (k, True, True)
ATTACKER = "743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8"
from solsim import b58dec
def s(x):
    b=x.encode(); return len(b).to_bytes(4,"little")+b

results=[]
def run(label, signer, ixs):
    r = S.run(label, signer, ixs); results.append(r)
    print("##", label, "=> err:", r.get("err"), "cu:", r.get("cu"))
    for l in (r.get("logs") or []):
        if "failed" in l or "Error" in l or "log:" in l: print("    ", l)
    print()
    return r

# update_openeden_info with longer payloads
for n in (2,4,6):
    run("update_openeden_info_attacker_%du64"%n, ATTACKER, [(
        PROG, [SG(ATTACKER), W(POOL), W(OPENEDEN), R(CUSDO), W(RWA_VAULT), R(RWA_TOKEN_VAULT_AUTH),
               W(USDC_VAULT), R(USDC_VAULT_AUTH), R(TOKEN22)],
        disc("update_openeden_info") + b"".join((2).to_bytes(8,"little") for _ in range(n)))])

# initialize attacker (pool exists)
run("initialize_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(OPERATOR), W(RATEAUTH), R(USDC),
           W(POOL_USDC_MAIN), W(POOL_USDC_WITHDRAW), W(SUSD), W(POOL_SUSD_VAULT),
           W(POOL), W(OPENEDEN), R(CUSDO), W(POOL_RWA_MAIN), W("cusdzR5sDbSnW5sUpoE6Y57nmBoEva6BSb1ZxWPizkD"),
           R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("initialize") + (5).to_bytes(8,"little") + (1000).to_bytes(8,"little") + b58dec(FEERECIP)
        + s("Solayer USD") + s("sUSD") + s("https://x"))])

# sunset_initiate_batch_withdraw variants
variants = {
 "no_sunset": [W(OPENEDEN)],
 "sunset_after_offset": [W(SUNSET), W(OPENEDEN)],
 "sunset_at_end": [W(OPENEDEN), W(SUNSET)],
}
for name, mid in variants.items():
    accts = [SG(ATTACKER), R(USDC), W(SUSD), W(POOL), W(POOL_SUSD_VAULT), W(SUSDOFF)] + mid + \
            [R(CUSDO), W(RWA_VAULT), W(POOL_RWA_MAIN), R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)]
    run("sunset_initiate_batch_withdraw_"+name, ATTACKER, [(PROG, accts, disc("sunset_initiate_batch_withdraw"))])

json.dump(results, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "battery5.json"),"w"), indent=1)
