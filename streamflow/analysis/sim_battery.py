#!/usr/bin/env python3
"""Simulation battery: attacker-built messages vs the deployed Streamflow programs.

simulateTransaction(sigVerify=false, replaceRecentBlockhash=true) only. No signing, no sending.
Results -> analysis/sims.json
"""
import json, os, sys, base64, time, hashlib
from collections import defaultdict
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import (get_program_accounts, get_account_info, find_program_address, b58enc,
                 b58dec, create_program_address, is_on_curve_b58, result)
import simlib as S

HERE = os.path.dirname(os.path.abspath(__file__))
STAKE = "STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH"
REWARD = "RWRDdfRbi3339VgKxTAXg4cjyniF7cbhNbMxZWiSKmj"
VESTING = "strmRqUCoQUgGUan5YhzUZa6KqdzwX5L6FpUxfmKg5m"
STREAM = "STREAMribRwybYpMmSYoCsQUdr6MZNXEqHgm7p1gu9M"
WORKER = "wdrwhnCv4pzW8beKsbPa4S2UDZrXenjg16KJdKSpb5u"
TREASURY = "5SEpbdjFK5FxwTvfsGMXVQTD2v4M2c5tyRTxhdsPkgDw"
TOKEN = S.TOKEN
ATA = S.ATA
ATTACKER = "HGgKAES15w2wgVrNJAc2e9JvTqUiZVH2J6zpNWz17myk"  # neutral on-curve key

def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def adisc(n): return hashlib.sha256(("account:" + n).encode()).digest()[:8]
def pk(raw, off): return b58enc(raw[off:off+32])
def u64(raw, off): return int.from_bytes(raw[off:off+8], "little")
def u32(raw, off): return int.from_bytes(raw[off:off+4], "little")
def ata(owner, mint): return find_program_address([b58dec(owner), b58dec(TOKEN), b58dec(mint)], ATA)[0]
def exists(p): return bool(get_account_info(p))

def entries_of(pool, n=400):
    ents = get_program_accounts(STAKE, encoding="base64", dataSlice={"offset": 0, "length": 120},
        filters=[{"memcmp": {"offset": 0, "bytes": b58enc(adisc("StakeEntry"))}},
                 {"memcmp": {"offset": 12, "bytes": pool}}])
    out = []
    if isinstance(ents, list):
        for a in ents[:n]:
            raw = base64.b64decode(a["account"]["data"][0])
            out.append({"pubkey": a["pubkey"], "nonce": u32(raw, 8), "stake_pool": pk(raw, 12),
                        "payer": pk(raw, 44), "authority": pk(raw, 76), "amount": u64(raw, 108)})
    return out

def reward_entries_of(rpool, n=200):
    rents = get_program_accounts(REWARD, encoding="base64", dataSlice={"offset": 0, "length": 120},
        filters=[{"memcmp": {"offset": 0, "bytes": b58enc(adisc("RewardEntry"))}},
                 {"memcmp": {"offset": 8, "bytes": rpool}}])
    out = []
    if isinstance(rents, list):
        for a in rents[:n]:
            raw = base64.b64decode(a["account"]["data"][0])
            out.append({"pubkey": a["pubkey"], "reward_pool": pk(raw, 8), "stake_entry": pk(raw, 40)})
    return out

def load_state():
    st = {}
    accs = get_program_accounts(STAKE, encoding="base64", dataSlice={"offset": 0, "length": 300},
                                filters=[{"memcmp": {"offset": 0, "bytes": b58enc(adisc("StakePool"))}}])
    pools = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        pools.append({"pubkey": a["pubkey"], "mint": pk(raw, 10), "authority": pk(raw, 74),
                      "vault": pk(raw, 139), "stake_mint": pk(raw, 171), "total_stake": u64(raw, 203)})
    st["pools"] = pools
    by_mint = defaultdict(list)
    for p in pools: by_mint[p["mint"]].append(p)

    chosen = None; ents = None; sibling = None
    for p in sorted(pools, key=lambda x: -x["total_stake"]):
        if p["mint"] != STREAM: continue
        sib = next((q for q in by_mint[p["mint"]] if q["vault"] != p["vault"]), None)
        if not sib: continue
        e = entries_of(p["pubkey"])
        if e: chosen, ents, sibling = p, e, sib; break
    st["chosen_pool"] = chosen; st["sibling_pool"] = sibling

    U = V = None; E_U = E_V = None
    if chosen:
        m, sm = chosen["mint"], chosen["stake_mint"]
        for e in ents:
            a = e["authority"]
            if ata(a, m) != None and exists(ata(a, m)) and exists(ata(a, sm)):
                if U is None: U, E_U = a, e
                elif a != U: V, E_V = a, e; break
    st["user_U"] = U; st["entry_U"] = E_U; st["victim_V"] = V; st["entry_V"] = E_V

    # reward pool for chosen pool + entries for U and V
    raccs = get_program_accounts(REWARD, encoding="base64", dataSlice={"offset": 0, "length": 300},
        filters=[{"memcmp": {"offset": 0, "bytes": b58enc(adisc("RewardPool"))}}])
    rpools = []
    for a in raccs:
        raw = base64.b64decode(a["account"]["data"][0])
        rpools.append({"pubkey": a["pubkey"], "stake_pool": pk(raw, 10), "mint": pk(raw, 42),
                       "authority": pk(raw, 106), "vault": pk(raw, 187)})
    st["reward_pools"] = rpools
    if chosen:
        rp = next((r for r in rpools if r["stake_pool"] == chosen["pubkey"]), None)
        st["chosen_reward_pool"] = rp
        sib_r = None
        if rp:
            sib_r = next((q for q in rpools if q["mint"] == rp["mint"] and q["vault"] != rp["vault"]), None)
            res = reward_entries_of(rp["pubkey"])
            st["reward_entries"] = res
            by_stake = {r["stake_entry"]: r for r in res}
            if E_U: st["reward_entry_U"] = by_stake.get(E_U["pubkey"])
            if E_V: st["reward_entry_V"] = by_stake.get(E_V["pubkey"])
        st["sibling_reward_pool"] = sib_r

    return st

def main():
    print("loading state ...")
    st = load_state()
    P = st.get("chosen_pool"); SIB = st.get("sibling_pool")
    U = st.get("user_U"); E_U = st.get("entry_U"); V = st.get("victim_V"); E_V = st.get("entry_V")
    RP = st.get("chosen_reward_pool"); RSIB = st.get("sibling_reward_pool")
    REU = st.get("reward_entry_U"); REV = st.get("reward_entry_V")
    RS = find_program_address([b"rent-sponsor"], STAKE)[0]
    results = []
    def rec(name, desc, res, expect):
        s = S.summarize(res)
        results.append({"name": name, "desc": desc, "expect": expect, **s})
        print("[%-40s] err=%-42s units=%s" % (name, str(s.get("err"))[:42], s.get("unitsConsumed")))
        for l in (s.get("log_tail") or []):
            if "Error" in l or "error" in l: print("      ", l)

    print("P=%s U=%s V=%s RP=%s" % (P and P["pubkey"], U, V, RP and RP["pubkey"]))
    mint = P["mint"]; smint = P["stake_mint"]

    # ---------------- STAKE ----------------
    if P and U and V and E_U and E_V:
        u_data = disc("unstake") + bytes([1, 1])
        base = lambda auth, entry, to: [
            (P["pubkey"], False, True), (entry["pubkey"], False, True), (ata(auth, smint), False, True),
            (P["vault"], False, True), (to, False, True), (auth, True, True),
            (mint, False, True), (smint, False, True), (RS, False, True), (TOKEN, False, False)]
        rec("unstake_victim_entry", "unstake() victim entry, attacker U (valid own ATAs) as authority",
            S.sim([(STAKE, base(U, E_V, ata(U, mint)), u_data)]), "reject: entry authority != signer")
        rec("unstake_own_entry_CONTROL", "unstake() own entry, real authority U signs",
            S.sim([(STAKE, base(U, E_U, ata(U, mint)), u_data)]), "passes authority gate (control)")
        bv = base(U, E_U, ata(U, mint)); bv[3] = (SIB["vault"], False, True)
        rec("unstake_forged_vault", "unstake() with sibling pool vault substituted",
            S.sim([(STAKE, bv, u_data)]), "6008 InvalidStakeVault")
        bm = base(U, E_U, ata(U, mint)); bm[6] = (smint, False, True)
        rec("unstake_forged_mint", "unstake() with stake_mint substituted for mint",
            S.sim([(STAKE, bm, u_data)]), "6007/6011 InvalidMint")

        w_data = disc("unstake_as_worker")
        w = [(P["pubkey"], False, True), (E_V["pubkey"], False, True), (ata(V, smint), False, True),
             (P["vault"], False, True), (ata(V, mint), False, True), (V, False, True),
             (ATTACKER, True, True), (mint, False, True), (smint, False, True),
             (ATA, False, False), (TOKEN, False, False), (S.SYSTEM, False, False)]
        rec("unstake_as_worker_forged", "unstake_as_worker() victim entry, attacker as worker key",
            S.sim([(STAKE, w, w_data)]), "Unauthorized: worker must be wdrwhn...")
        w2 = list(w); w2[6] = (WORKER, True, True)
        rec("unstake_as_worker_realworker_CONTROL", "unstake_as_worker() with the hard-coded worker signing",
            S.sim([(STAKE, w2, w_data)]), "passes worker gate (control)")

        m_data = disc("migrate_entry") + (E_V["nonce"]).to_bytes(4, "little") + (0).to_bytes(4, "little")
        m = [(P["pubkey"], False, True), (P["pubkey"], False, True), (E_V["pubkey"], False, True),
             (find_program_address([b"stake-entry", b58dec(P["pubkey"]), b58dec(V), (0).to_bytes(4, "little")], STAKE)[0], False, True),
             (P["vault"], False, True), (ata(U, mint), False, True), (ata(U, mint), False, True),
             (U, True, True), (V, False, False), (mint, False, True), (smint, False, True), (smint, False, True),
             (TOKEN, False, False), (S.SYSTEM, False, False)]
        rec("migrate_entry_victim", "migrate_entry() victim entry, attacker U as payer, U destination",
            S.sim([(STAKE, m, m_data)]), "reject: authority/signer")

        rec("change_authority_forged", "change_authority() real pool, attacker U as authority",
            S.sim([(STAKE, [(P["pubkey"], False, True), (U, True, True), (U, False, False)], disc("change_authority"))]),
            "6005 Unauthorized")
        rec("change_authority_CONTROL", "change_authority() with the real pool authority signing",
            S.sim([(STAKE, [(P["pubkey"], False, True), (P["authority"], True, True), (U, False, False)], disc("change_authority"))]),
            "passes authority gate (control)")
        rec("request_unstake_victim", "request_unstake() victim entry, attacker U authority",
            S.sim([(STAKE, [(P["pubkey"], False, True), (E_V["pubkey"], False, True), (U, True, True)], disc("request_unstake"))]),
            "6005 Unauthorized")
        rec("close_entry_victim", "close_entry() victim entry, attacker U authority",
            S.sim([(STAKE, [(P["pubkey"], False, False), (E_V["pubkey"], False, True), (U, True, True), (RS, False, True)], disc("close_entry"))]),
            "6005 Unauthorized")

        # stake() with forged vault (authority = U so `to` ATA exists)
        s_data = disc("stake") + (255).to_bytes(4, "little") + (1).to_bytes(8, "little") + (0).to_bytes(8, "little")
        s_accts = [(P["pubkey"], False, True),
                   (find_program_address([b"stake-entry", b58dec(P["pubkey"]), b58dec(U), (255).to_bytes(4, "little")], STAKE)[0], False, True),
                   (P["vault"], False, True), (SIB["vault"], False, True), (ata(U, smint), False, True),
                   (U, True, True), (U, False, False), (mint, False, True), (smint, False, True),
                   (RS, False, True), (TOKEN, False, False), (S.SYSTEM, False, False)]
        rec("stake_forged_vault", "stake() with sibling pool vault substituted",
            S.sim([(STAKE, s_accts, s_data)]), "6008 InvalidStakeVault")

    # ---------------- REWARD ----------------
    if RP and U:
        rp_mint = RP["mint"]
        c_data = disc("claim_rewards")
        def cbase(claimant, to, entry, vault=RP["vault"], mint_a=None):
            return [(RP["pubkey"], False, True), (entry["stake_entry"], False, False), (entry["pubkey"], False, True),
                    (vault, False, True), (to, False, True), (claimant, True, True),
                    (mint_a or rp_mint, False, False), (TOKEN, False, False), (S.SYSTEM, False, False)]
        if REV:
            rec("claim_rewards_victim_entry", "claim_rewards() victim reward entry, attacker U as claimant",
                S.sim([(REWARD, cbase(U, ata(U, rp_mint), REV), c_data)]), "6003 Unauthorized / 6006")
        if REU:
            rec("claim_rewards_own_CONTROL", "claim_rewards() own reward entry, real authority U signs",
                S.sim([(REWARD, cbase(U, ata(U, rp_mint), REU), c_data)]), "passes authority gate (control)")
            cv = cbase(U, ata(U, rp_mint), REU, vault=(RSIB["vault"] if RSIB else RP["vault"]))
            rec("claim_rewards_forged_vault", "claim_rewards() with sibling reward vault substituted",
                S.sim([(REWARD, cv, c_data)]), "6005 InvalidRewardVault")
            cm = cbase(U, ata(U, rp_mint), REU, mint_a=RP["stake_pool"])
            rec("claim_rewards_forged_mint", "claim_rewards() with a non-mint account",
                S.sim([(REWARD, cm, c_data)]), "6009 InvalidMint")
        rec("clawback_forged_authority", "clawback() attacker U as reward-pool authority",
            S.sim([(REWARD, [(RP["pubkey"], False, True), (RP["stake_pool"], False, False), (RP["vault"], False, True),
                              (ata(U, rp_mint), False, True), (U, True, True), (rp_mint, False, False),
                              (TOKEN, False, False), (S.SYSTEM, False, False)], disc("clawback"))]),
            "6003 Unauthorized")
        if REV and P:
            cw = [(RP["pubkey"], False, True), (RP["stake_pool"], False, True), (REV["stake_entry"], False, True),
                  (REV["pubkey"], False, True), (RP["vault"], False, True), (P["vault"], False, True),
                  (ata(V, rp_mint), False, True), (ata(V, rp_mint), False, True), (V, False, True),
                  (ATTACKER, True, True), (rp_mint, False, True), (smint, False, True), (STAKE, False, False),
                  (ATA, False, False), (TOKEN, False, False), (S.SYSTEM, False, False)]
            rec("claim_rewards_as_worker_forged", "claim_rewards_as_worker() attacker as worker",
                S.sim([(REWARD, cw, disc("claim_rewards_as_worker"))]), "Unauthorized: worker gate")

    # (vesting-program withdraw/cancel sims live in vesting_probe.py, which selects a
    #  stream with a positive currently-available amount so the authority gate is reached)

    with open(os.path.join(HERE, "sim_state.json"), "w") as f: json.dump(st, f, indent=1)
    with open(os.path.join(HERE, "sims.json"), "w") as f: json.dump({"results": results}, f, indent=1)
    print("wrote sims.json:", len(results), "sims")

if __name__ == "__main__":
    main()
