#!/usr/bin/env python3
"""Fetch cloned mainnet state for the LiteSVM liquidation PoC (CI).

For each test case (liquidatee + asset_bank + liab_bank) writes poc/accounts/<case>.json
containing every account the harness needs:
  * marginfi program ELF is stored separately at poc/programs/marginfi_program.so
  * group, asset/liab banks, oracle/aux accounts for every balance of the liquidatee
  * the liquidatee account
  * bank vaults + vault authority for the liab bank (insurance-fee SPL transfer)
  * an SPL token program is stored at poc/programs/tokenkeg.so

The harness fabricates its own liquidator marginfi account (our authority) — see the Rust test.
"""
import base64, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import b58encode, get_accounts, decode_balances, pda
from simulate_liquidate import accounts_for_bank
from decode_bank import decode_bank

HERE = os.path.dirname(os.path.abspath(__file__))
POC = os.path.abspath(os.path.join(HERE, "..", "poc"))
ACCOUNTS_DIR = os.path.join(POC, "accounts")
os.makedirs(ACCOUNTS_DIR, exist_ok=True)

CASES = json.load(open(os.path.join(HERE, "poc_cases.json")))

# Empty MarginfiAccount in the same group, used as the liquidator template
# (the harness patches group/authority and adds a deposit balance).
EMPTY_TEMPLATE = "17C8wM8h9yzy42C6H7Mj1cJ8uEEpCqTaMcPFdPG5LBf"


def fetch_case(case):
    liqee = case["liquidatee"]
    asset_bank_pk = case["asset_bank"]
    liab_bank_pk = case["liab_bank"]
    need = {}
    ares = get_accounts([liqee])[0]
    raw = ares[3]
    group = b58encode(raw[8:40])
    need[liqee] = ares
    need[group] = get_accounts([group])[0]
    bals = decode_balances(raw)
    banks = {}
    for b in bals:
        if b["bank"] not in banks:
            banks[b["bank"]] = decode_bank(get_accounts([b["bank"]])[0][3])
    for pk in (asset_bank_pk, liab_bank_pk):
        if pk not in banks:
            banks[pk] = decode_bank(get_accounts([pk])[0][3])
    solb = "CCKtUs6Cgwo4aaQUmBPmyoApH2gUDErxNZCAntD6LYGh"
    if solb not in banks:
        banks[solb] = decode_bank(get_accounts([solb])[0][3])
    # bank accounts + their aux accounts
    aux = set()
    for pk, bank in banks.items():
        need[pk] = get_accounts([pk])[0]
        for a in accounts_for_bank(pk, bank["config"])[1:]:
            aux.add(a)
    liab_bank = banks[liab_bank_pk]
    # vaults + authority for the liab bank (insurance fee transfer)
    va, _ = pda([b"liquidity_vault_auth", __import__("mfi_common").b58decode(liab_bank_pk)])
    need[va] = get_accounts([va])[0] if get_accounts([va])[0] else (va, 0, "11111111111111111111111111111111", b"")
    for v in (liab_bank["liquidity_vault"], liab_bank["insurance_vault"]):
        need[v] = get_accounts([v])[0]
    for a in aux:
        v = get_accounts([a])[0]
        if v:
            need[a] = v
    out = {
        "label": case.get("label", liqee),
        "liquidatee": liqee,
        "asset_bank": asset_bank_pk,
        "liab_bank": liab_bank_pk,
        "asset_amount": case.get("asset_amount", 1),
        "group": group,
        "liab_mint": liab_bank["mint"],
        "asset_mint": banks[asset_bank_pk]["mint"],
        "sol_bank": "CCKtUs6Cgwo4aaQUmBPmyoApH2gUDErxNZCAntD6LYGh",
        "liquidator_template": EMPTY_TEMPLATE,
        "accounts": {pk: {"lamports": v[1], "owner": v[2], "data": base64.b64encode(v[3]).decode()}
                     for pk, v in need.items() if v},
    }
    t = get_accounts([EMPTY_TEMPLATE])[0]
    out["accounts"][EMPTY_TEMPLATE] = {"lamports": t[1], "owner": t[2],
                                       "data": base64.b64encode(t[3]).decode()}
    # SOL bank always included (the fabricated liquidator's deposit bank)
    solb = "CCKtUs6Cgwo4aaQUmBPmyoApH2gUDErxNZCAntD6LYGh"
    if solb not in out["accounts"]:
        v = get_accounts([solb])[0]
        out["accounts"][solb] = {"lamports": v[1], "owner": v[2],
                                 "data": base64.b64encode(v[3]).decode()}
    out["remaining_for_bank"] = {pk: accounts_for_bank(pk, bank["config"])
                                 for pk, bank in banks.items()}
    out["vault_authority"] = va
    out["liab_liquidity_vault"] = liab_bank["liquidity_vault"]
    out["liab_insurance_vault"] = liab_bank["insurance_vault"]
    path = os.path.join(ACCOUNTS_DIR, f"{case.get('label', liqee)}.json")
    json.dump(out, open(path, "w"))
    print(f"{case.get('label')}: {len(out['accounts'])} accounts -> {os.path.basename(path)} "
          f"({os.path.getsize(path)/1e6:.2f} MB)")


if __name__ == "__main__":
    for c in CASES:
        fetch_case(c)
