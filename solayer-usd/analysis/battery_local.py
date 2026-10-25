#!/usr/bin/env python3
"""battery_local.py - quick gating tests (light, local). Read-only simulations."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solsim as S, solrpc as rpc

# addresses
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
POOL_SUSD_VAULT="FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds"
POOL_USDC_WITHDRAW="usdcLDuDT41YeWcbiMLJ6AoqTumSbJtTQCebJsZJsih"
OPENEDEN="9HhZLsdF8pGQ9fuSJH5UnqJyXBeuMJ729eYVesXCC6mc"
SUSDOFF="5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz"
SUNSET="EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh"
RWA_VAULT="G9UFgtiWKkuJ2ekuYJJpYxdk8hbNjNkzPcN7p2xd4gkd"
POOL_RWA_MAIN="2pR6cGbrJz9EAdo2Qo9eiUkNa75QZRLGX4bhpdMXnFRM"
HOOK="48n7YGEww7fKMfJ5gJ3sQC3rM6RWGjpUsghqVfXVkR5A"
EXTRAMETAS="9sQhAH7vV3RKTCK13VY4EiNjs3qBq1srSYxdNufdAAXm"
PAUSE="98wFF5MpMjMQbfDF2MPzo8LCGX37unZR1ohRA1mU9GmJ"
FEE_SUSD_ACCT="CApp5oy3HBXrEWkXcTcKhVeWdE2ghDqivXeUYnpMoLTN"
ATA="ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
SYS="11111111111111111111111111111111"

_D = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "discriminators.json")))["instructions"]
D = {v: k for k, v in _D.items()}
def disc(n): return bytes.fromhex(D[n])

ATTACKER = "743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8"

def W(k): return (k, True, False)
def R(k): return (k, False, False)
def SG(k): return (k, True, True)

results = []

# 1. resolve_batch_withdraw with attacker as signer (real operator in acct0)
res = S.run("resolve_batch_withdraw_attacker_signer", ATTACKER, [(
    PROG, [SG(ATTACKER), W(FEERECIP), R(USDC), W(POOL_USDC_MAIN), W(POOL_USDC_WITHDRAW),
           R(SUSD), W(POOL_SUSD_VAULT), W(POOL), W(OPENEDEN), R(ATA), R(TOKEN), R(TOKEN22)],
    disc("resolve_batch_withdraw"))])
results.append(res)

# 2. initiate_batch_withdraw attacker
res = S.run("initiate_batch_withdraw_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(SUSD), W(POOL), W(POOL_SUSD_VAULT), W(SUSDOFF), R(OPENEDEN),
           R(CUSDO), W(RWA_VAULT), W(POOL_RWA_MAIN), R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)],
    disc("initiate_batch_withdraw"))])
results.append(res)

# 3. collect_fee attacker
res = S.run("collect_fee_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(FEERECIP), W(SUSD), W(FEE_SUSD_ACCT), W(POOL), W(SUSDOFF),
           R(ATA), R(TOKEN22), R(SYS)], disc("collect_fee"))])
results.append(res)

# 4. set_fee attacker (newRentRefundRecipient = attacker)
res = S.run("set_fee_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(ATTACKER), W(POOL)], disc("set_fee") + (5).to_bytes(8,"little") + (1000).to_bytes(8,"little"))])
results.append(res)

# 5. set_manager attacker -> attacker
res = S.run("set_manager_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(ATTACKER), W(POOL)], disc("set_manager"))])
results.append(res)

# 6. set_operator attacker -> attacker
res = S.run("set_operator_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(ATTACKER), W(POOL)], disc("set_operator"))])
results.append(res)

# 7. set_rate_authority attacker -> attacker
res = S.run("set_rate_authority_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(ATTACKER), W(POOL)], disc("set_rate_authority"))])
results.append(res)

# 8. update_susd_rate attacker
res = S.run("update_susd_rate_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(SUSD), R(POOL), R(TOKEN22)], disc("update_susd_rate") + (9000).to_bytes(2,"little",signed=True))])
results.append(res)

# 9. emergency_transfer_rwa_token attacker
res = S.run("emergency_transfer_rwa_token_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(POOL), R(OPENEDEN), R(CUSDO), W(POOL_RWA_MAIN), W(RWA_VAULT),
           R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)],
    disc("emergency_transfer_rwa_token") + (1).to_bytes(8,"little"))])
results.append(res)

# 10. create_susd_offset_pda attacker
res = S.run("create_susd_offset_pda_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(POOL), W(SUSDOFF), R(SYS)],
    disc("create_susd_offset_pda") + (1).to_bytes(8,"little"))])
results.append(res)

# 11. sunset_redeem_all attacker
res = S.run("sunset_redeem_all_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(SUSD), W(POOL), W(SUSDOFF), W(OPENEDEN), R(CUSDO),
           W(RWA_VAULT), W(POOL_RWA_MAIN), W(SUNSET), R(TOKEN22), R(SYS)],
    disc("sunset_redeem_all"))])
results.append(res)

# 12. sunset_finalize attacker
res = S.run("sunset_finalize_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(POOL), W(OPENEDEN), W(SUNSET), W(POOL_USDC_MAIN),
           W(POOL_USDC_WITHDRAW), R(TOKEN)], disc("sunset_finalize"))])
results.append(res)

# 13. update_susd_metadata attacker
res = S.run("update_susd_metadata_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(SUSD), R(POOL), R(TOKEN22)],
    disc("update_susd_metadata") + (4).to_bytes(4,"little") + b"name" + (3).to_bytes(4,"little") + b"XXX")])
results.append(res)

for r in results:
    print("##", r["label"], "=> err:", r.get("err"), "cu:", r.get("cu"))
    for l in (r.get("logs") or []):
        if "failed" in l or "Error" in l or "log:" in l:
            print("    ", l)
    print()
json.dump(results, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "battery_local.json"), "w"), indent=1)
