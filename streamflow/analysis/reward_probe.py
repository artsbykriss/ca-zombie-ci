#!/usr/bin/env python3
"""Focused reward-pool simulation probe: claim_rewards gating + vault/mint binding."""
import sys, os, base64, json, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sim_battery as B, simlib as S
from sol import get_program_accounts, get_multiple, b58enc

def adisc(n): return hashlib.sha256(("account:" + n).encode()).digest()[:8]
def pk(raw, o): return b58enc(raw[o:o+32])
def u64(raw, o): return int.from_bytes(raw[o:o+8], "little")

def main():
    raccs = get_program_accounts(B.REWARD, encoding="base64", dataSlice={"offset": 0, "length": 300},
        filters=[{"memcmp": {"offset": 0, "bytes": b58enc(adisc("RewardPool"))}}])
    rps = []
    for a in raccs:
        raw = base64.b64decode(a["account"]["data"][0])
        rps.append({"pubkey": a["pubkey"], "stake_pool": pk(raw, 10), "mint": pk(raw, 42),
                    "authority": pk(raw, 106), "vault": pk(raw, 187),
                    "funded": u64(raw, 219), "claimed": u64(raw, 227)})
    print("reward pools", len(rps), flush=True)
    found = None
    for rp in sorted(rps, key=lambda r: -(r["funded"] - r["claimed"]))[:12]:
        if rp["funded"] - rp["claimed"] <= 0: continue
        res = B.reward_entries_of(rp["pubkey"], n=15)
        if not res: continue
        vals = get_multiple([r["stake_entry"] for r in res], encoding="base64")
        for r, v in zip(res, vals):
            if not v: continue
            raw = base64.b64decode(v["data"][0])
            auth = pk(raw, 76)
            if B.exists(B.ata(auth, rp["mint"])):
                found = (rp, r, auth); break
        if found: break
    if not found:
        print("no reward pool with a claimable entry + existing ATA found"); return
    rp, r, auth = found
    print("RP", rp["pubkey"], "mint", rp["mint"], "vault", rp["vault"], "authority", rp["authority"], "user", auth, flush=True)
    c_data = B.disc("claim_rewards")
    def base(claimant, to, entry, vault=None, mint_a=None):
        return [(rp["pubkey"], False, True), (entry["stake_entry"], False, False), (entry["pubkey"], False, True),
                (vault or rp["vault"], False, True), (to, False, True), (claimant, True, True),
                (mint_a or rp["mint"], False, False), (B.TOKEN, False, False), (S.SYSTEM, False, False)]
    to_acct = B.ata(auth, rp["mint"])
    out = []
    def run(name, accts, expect):
        s = S.summarize(S.sim([(B.REWARD, accts, c_data)]))
        out.append({"name": name, "expect": expect, **s})
        print("[%s] -> %s" % (name, s["err"]), flush=True)
        for l in (s.get("log_tail") or []): print("     ", l, flush=True)
    run("claim_rewards_forged_claimant", base(B.ATTACKER, to_acct, r), "Unauthorized/InvalidRewardEntry")
    run("claim_rewards_control", base(auth, to_acct, r), "passes authority gate")
    sib = next((q for q in rps if q["mint"] == rp["mint"] and q["vault"] != rp["vault"]), None)
    if sib:
        run("claim_rewards_forged_vault", base(auth, to_acct, r, vault=sib["vault"]), "6005 InvalidRewardVault")
    run("claim_rewards_forged_mint", base(auth, to_acct, r, mint_a=rp["stake_pool"]), "6009 InvalidMint")
    # clawback with attacker authority
    k = [(rp["pubkey"], False, True), (rp["stake_pool"], False, False), (rp["vault"], False, True),
         (to_acct, False, True), (B.ATTACKER, True, True), (rp["mint"], False, False),
         (B.TOKEN, False, False), (S.SYSTEM, False, False)]
    sk = S.summarize(S.sim([(B.REWARD, k, B.disc("clawback"))]))
    out.append({"name": "clawback_forged_authority", "expect": "6003 Unauthorized", **sk})
    print("[clawback_forged_authority] ->", sk["err"], flush=True)
    json.dump({"rp": rp, "entry": r, "user": auth, "results": out},
              open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "reward_sims.json"), "w"), indent=1)

if __name__ == "__main__":
    main()
