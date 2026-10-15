#!/usr/bin/env python3
"""Build final deliverable JSONs and print all report numbers."""
import json, sys, time, datetime
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")

A = "/home/heisenberg/CA/phase-stake/analysis/"
def ts(x): return datetime.datetime.fromtimestamp(x, datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

print("== dates ==")
for lbl, bt in [("mint created", 1713204023), ("0.01 SOL test to reserve", 1713391603),
                ("reserve created+init", 1713392740), ("pool+vlist created", 1713395218),
                ("first stake deposit (510.27 YIELD)", 1713401112),
                ("early SOL deposit sample", 1714204179),
                ("8QtQ created (AddValidatorToPool CiTY)", 1775498896),
                ("top1 TA last activity", 1791602071),
                ("last tx on old fee acct 3Y3b", 1791668890),
                ("MultisigCreateV2 (Squads)", 1791772089),
                ("new fee ATA created", 1791777342),
                ("SetManager #1 (->Gutj91DY)", 1791778066),
                ("staker->fee 1.001919 YIELD", 1791778245),
                ("SetManager #2 (Squads, 4 pools -> vault 7LqS)", 1791783191),
                ("Jito tip inflow 141.586756 SOL", 1792035875),
                ("last pool update", 1792035941),
                ("chain now", 1792076143),
                ("prt1s vlist oldest", 1753460913)]:
    print(f"{lbl:50s} {bt}  {ts(bt)}")

NOW = 1792076143
CREATE = 1713395218
age_s = NOW - CREATE
age_y = age_s / (365.25 * 86400)
nav = 30002233945691 / 25123581135630
cagr = nav ** (1 / age_y) - 1
print(f"\nage = {age_s} s = {age_s/86400:.2f} days = {age_y:.4f} yr")
print(f"NAV = {nav:.9f}; CAGR(1/x) = {cagr*100:.3f}%/yr")
print("excess over 1:1 =", (30002233945691 - 25123581135630)/1e9, "SOL")
print("implied redemption after 0.1% wfee:", nav * 0.999)
print("last-epoch delta:", (30002233945691 - 29997808108053)/1e9, "SOL over", (1792076143-1792035941)/3600, "h")

# rebuild holders.json properly
tg = json.load(open(A + "token_gpa_holders.json"))
hc = {"top15_classification": json.load(open(A + "holder_class.json"))}
accs = tg["accounts"]
supply = 25123581135630
top = []
for i, h in enumerate(accs[:20]):
    o = h["owner"]
    cls = hc["top15_classification"].get(o, {})
    top.append({"rank": i + 1, "token_account": h["token_account"], "owner": o,
                "amount_raw": h["amount"], "ui_amount": h["amount"] / 1e9,
                "share_of_supply": h["amount"] / supply,
                "owner_account": cls})
conc = {}
for n in (1, 2, 3, 4, 5, 10, 15, 25, 50):
    amt = sum(x["amount"] for x in accs[:n])
    conc[f"top{n}"] = {"amount_raw": amt, "share": amt / supply}
holders = {
    "mint": "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG",
    "decimals": 9, "supply_raw": supply, "n_token_accounts": tg["count"],
    "sum_all_accounts_raw": tg["sum_amount"],
    "concentration": conc,
    "top20": top,
    "method": "getProgramAccounts(Tokenkeg, dataSize=165, memcmp offset0=mint, dataSlice 32..88) via api.mainnet-beta.solana.com; owners classified with getAccountInfo",
    "notes": ["Kamino/Marginfi-style lending vault = rank1 owner 5zqnB8kR... (off-curve PDA)",
              "Loopscale program accounts dominate ranks 2,3,6,7,8,10,12,13 (owner_program 1oopBoJG58...)",
              "rank14 = Sanctum S-Controller (INF) account",
              "fee account GAGMZfQU... balance 2.01457808 YIELD (rank ~26)"],
}
json.dump(holders, open(A + "holders.json", "w"), indent=2)
print("\nwrote holders.json; top20 ui amounts:", [round(t["ui_amount"], 3) for t in top])

summary = {
    "chain_now": {"blockTime": NOW, "utc": ts(NOW), "epoch": 1058},
    "pool": {
        "address": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
        "program": "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn (Sanctum SPL multi-validator stake pool)",
        "created_slot": 260739588, "created_blockTime": CREATE, "created_utc": ts(CREATE),
        "approx_epoch_at_creation": 604,
        "age_years": age_y, "total_lamports": 30002233945691, "pool_token_supply": 25123581135630,
        "nav_sol_per_yield": nav, "nav_cagr": cagr,
        "last_epoch_total_lamports": 29997808108053, "last_epoch_pool_token_supply": 25123581135630,
        "fees_current": {"epoch_fee": "0/100 = 0%", "stake_deposit_fee": "0/1000", "stake_withdrawal_fee": "1/1000 = 0.1%",
                          "sol_deposit_fee": "0/1000", "sol_withdrawal_fee": "1/1000 = 0.1%"},
        "fees_2024-04": {"sol_deposit_fee_observed": "0.1% (998,744 fee tokens on 998,743,528 minted)"},
    },
    "history_counts": {"pool_sigs_fetched": 41000, "pool_complete": False,
                       "reserve_sigs": 14468, "reserve_complete": True,
                       "mint_sigs": 38281, "mint_complete": True,
                       "vlist_sigs": 12878, "vlist_complete": True,
                       "stake8QtQ_sigs": 4056, "stake8QtQ_complete": True,
                       "fee_sigs_total": 15, "manager_pda_sigs": 10},
    "creation_tx": {"sig": "4YRfsPUw43kDXcPFsWpffVdg8FKrcQ6YzRyYnjGjLZynqBvJxnZiDgmZMEMeFZyjXVA65RUtYcu1kbxrYyR36Y2G",
                     "authority": "phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit",
                     "minted_at_init_to_old_fee_account_3Y3b": 3282880},
    "initial_deposits_apr2024": [
        {"utc": ts(1713401112), "kind": "DepositStake", "minted_yield_raw": 510270080016,
         "note": "stake authorize -> pool stake_deposit_authority DTws8vTw..."},
        {"utc": ts(1714204179), "kind": "DepositSol", "minted_yield_raw": 998743528,
         "detail": "user 997744784 + fee 998744 (old fee acct 3Y3b)"},
        {"utc": ts(1714227029), "kind": "DepositSol", "minted_yield_raw": 43185796,
         "detail": "user 43142610 + fee 43186"},
    ],
    "authorities": {
        "manager": {"addr": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
                    "type": "Squads v4 vault[0] of multisig GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v (PDA verified)",
                    "msig": {"create_key": "5VPERwbVnFFw2b95Szam2VHWbXQp8ks7SYQ9Xy3UfJTe", "threshold": 3,
                             "time_lock_s": 86400, "members_byte_len_hint": "264-byte account"}},
        "staker": {"addr": "DxWfcgb2kENzzFy6ATP8KconVj6FriFU2GDnK1TmK6mK", "exists": False,
                   "on_curve": True, "note": "signed SetManager on 2026-10-11 and moved 1.001919 YIELD to new fee ATA"},
        "sol_withdraw_authority": {"addr": "phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d", "exists": True,
                                   "on_curve": True, "lamports": 19995000},
        "stake_deposit_authority": {"addr": "DTws8vTwkJ1U1gpfgtbLsxydVgnDkLBoB9n1KYvw27BT", "exists": False, "on_curve": False},
        "manager_fee_account": {"addr": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
                                "authority": "Gutj91DY4ZS7TCJzCUVMRdDhT9U2ccsDy4fgn74WawgL (EOA)",
                                "balance_raw": 2014578080, "first_used": ts(1791777342)},
        "old_fee_account": {"addr": "3Y3bNqaRLFiG8w3wUUE82oEsbMwc8NjnJ5QLyn39APPU",
                            "authority": "phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit (creator)",
                            "balance_now": 0, "last_used": ts(1791668890)},
    },
    "manager_change_2026_10_11": {
        "seq": [
            {"utc": ts(1791772089), "op": "SQDS MultisigCreateV2 (5-account threshold-3, 24h timelock), vault funded 0.001 SOL"},
            {"utc": ts(1791777342), "op": "new fee ATA GAGMZfQ created (owner Gutj91DY)"},
            {"utc": ts(1791778066), "op": "SPMBzs SetManager (tag 10): accounts [pool, staker DxWfcgb2, new_manager Gutj91DY, fee GAGMZfQ]; signers 4DgxbXBL, DxWfcgb2, Gutj91DY"},
            {"utc": ts(1791778245), "op": "staker DxWfcgb2 -> fee ATA: 1,001,919,179 raw YIELD (1.001919)"},
            {"utc": ts(1791783191), "op": "Squads VaultTransactionExecute: SetManager on 4 pools [phasejkG1, hy1oDeVCV, hy1o2kiY, prt1stdb] -> manager = vault 7LqS"},
        ]
    },
    "jito_tip_inflow": {"utc": ts(1792035875), "lamports": 141586756, "note": "Jito TipRouter/TipDistribution claim credited the pool stake account; swept to reserve by UpdateValidatorListBalance at 1792035941"},
    "siblings_same_manager": {"hy1oDeVCV": {"nav": 1.0803, "tvl_sol": 193734.48},
                              "hy1o2kiY": {"nav": 1.0, "tvl_sol": 10871.93},
                              "prt1stdb": {"nav": 1.0578, "tvl_sol": 1187.19, "vlist_oldest_utc": ts(1753460913)}},
    "pdsol_pool": {"address": "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6",
                   "program": "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy (canonical SPL stake pool)",
                   "mint": "aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF", "manager": "7LqSTwcw... (same Squads vault)",
                   "staker": "QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk",
                   "sol_withdraw_authority": None, "stake_deposit_authority": "4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8",
                   "total_lamports": 1101114884155839, "pool_token_supply": 952415109886148,
                   "nav": 1101114884155839 / 952415109886148, "vlist_min_age_days": 143},
    "rpc_methods_used": ["getAccountInfo (base64/jsonParsed)", "getTokenSupply", "getEpochInfo", "getBlockTime",
                          "getSignaturesForAddress (publicnode + api.mainnet-beta, paginated)",
                          "getTransaction (jsonParsed, maxSupportedTransactionVersion 0)",
                          "getProgramAccounts (SPMBzs dataSize=611 memcmp type=1; Tokenkeg dataSize=165 memcmp mint, dataSlice)",
                          "getTokenLargestAccounts (FAILED: 429 on mainnet-beta; 'indexed requests' blocked on publicnode/onfinality)"],
}
json.dump(summary, open(A + "history_summary.json", "w"), indent=2)
print("\nwrote history_summary.json")
