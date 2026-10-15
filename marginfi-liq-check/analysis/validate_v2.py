#!/usr/bin/env python3
"""Validate the program-exact health model against the DEPLOYED program via live simulations.

For each account: pick (asset_bank, liab_bank) from its balances, simulate
lending_account_liquidate with sigVerify=false, and extract the program's own
`pre_liquidation_health` from the logs (or 6068 == healthy).
"""
import argparse, base64, json, os, re, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import b58decode, b58encode, rpc, get_accounts, decode_balances, pda
from simulate_liquidate import (LIQ_DISC, TOKEN_PROGRAM, accounts_for_bank, build_tx)
from decode_bank import decode_bank

HERE = os.path.dirname(os.path.abspath(__file__))
HEALTH_RE = re.compile(r"pre_liquidation_health: ([\-0-9.]+) \(([\-0-9.]+) - ([\-0-9.]+)\)")


def simulate(liqee_pk, liqor_pk, authority, asset_bank_pk, liab_bank_pk, amount=1):
    bres = get_accounts([asset_bank_pk, liab_bank_pk])
    asset_bank = decode_bank(bres[0][3])
    liab_bank = decode_bank(bres[1][3])
    ares = get_accounts([liqee_pk, liqor_pk])
    liqee, liqor = ares[0][3], ares[1][3]
    group = b58encode(liqee[8:40])
    liqee_bal = decode_balances(liqee)
    liqor_bal = decode_balances(liqor)

    def post_bals(bals, extra):
        seen = {b["bank"] for b in bals}
        return sorted(set([b["bank"] for b in bals] + [e for e in extra if e not in seen]),
                      key=lambda p: b58decode(p), reverse=True)

    bank_cache = {asset_bank_pk: asset_bank, liab_bank_pk: liab_bank}

    def cfg(pk):
        if pk not in bank_cache:
            bank_cache[pk] = decode_bank(get_accounts([pk])[0][3])
        return bank_cache[pk]["config"]

    liqee_ais = []
    for pk in post_bals(liqee_bal, []):
        liqee_ais += accounts_for_bank(pk, cfg(pk))
    liqor_ais = []
    for pk in post_bals(liqor_bal, [asset_bank_pk, liab_bank_pk]):
        liqor_ais += accounts_for_bank(pk, cfg(pk))
    asset_oracles = accounts_for_bank(asset_bank_pk, asset_bank["config"])[1:]
    liab_oracles = accounts_for_bank(liab_bank_pk, liab_bank["config"])[1:]
    liq_auth_pda, _ = pda([b"liquidity_vault_auth", b58decode(liab_bank_pk)])
    metas = [(group, False, False), (asset_bank_pk, False, True), (liab_bank_pk, False, True),
             (liqor_pk, False, True), (authority, True, False), (liqee_pk, False, True),
             (liq_auth_pda, False, False), (liab_bank["liquidity_vault"], False, True),
             (liab_bank["insurance_vault"], False, True), (TOKEN_PROGRAM, False, False)]
    for pk in asset_oracles + liab_oracles + liqor_ais + liqee_ais:
        metas.append((pk, False, False))
    data = LIQ_DISC + struct.pack("<QBB", amount, len(liqee_ais), len(liqor_ais))
    cb_data = bytes([2]) + struct.pack("<I", 1_400_000)
    tx = build_tx(authority, [("ComputeBudget111111111111111111111111111111", [], cb_data),
                              ("MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA", metas, data)])
    res = rpc("simulateTransaction", [base64.b64encode(tx).decode(),
              {"encoding": "base64", "sigVerify": False, "replaceRecentBlockhash": True,
               "commitment": "processed"}], timeout=120)
    return res["value"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--accounts", required=True, help="comma-separated account pubkeys")
    ap.add_argument("--liquidator", default="3dk61VCbDAJKH27vwbSke5969ch4Z9f7apXCdw1G88dB")
    ap.add_argument("--authority", default="HYYdpVq3SDferJDUnDpL7exGwxWFtJ5AuzvwbkvLUsrU")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    accts = args.accounts.split(",")
    out = []
    for pk in accts:
        v = get_accounts([pk])[0]
        raw = v[3]
        bals = decode_balances(raw)
        if not bals:
            print(pk, "no balances"); continue
        # choose liab = largest liability, asset = largest asset
        liabs = [b for b in bals if b["liability_shares"] > 0]
        assets = [b for b in bals if b["asset_shares"] > 0]
        if not liabs:
            print(pk, "no liabilities"); continue
        liab_bank = max(liabs, key=lambda b: b["liability_shares"])["bank"]
        asset_bank = max(assets, key=lambda b: b["asset_shares"])["bank"] if assets else \
            "CCKtUs6Cgwo4aaQUmBPmyoApH2gUDErxNZCAntD6LYGh"
        try:
            val = simulate(pk, args.liquidator, args.authority, asset_bank, liab_bank)
        except Exception as e:
            print(pk, "SIM ERROR", e); continue
        logs = val.get("logs", [])
        health = None
        for l in logs:
            m = HEALTH_RE.search(l)
            if m:
                health = {"health": float(m.group(1)), "assets": float(m.group(2)),
                          "liabs": float(m.group(3))}
        err = val.get("err")
        errcode = None
        if isinstance(err, dict) and "InstructionError" in err:
            e = err["InstructionError"][1]
            errcode = e.get("Custom") if isinstance(e, dict) else str(e)
        rec = {"account": pk, "asset_bank": asset_bank, "liab_bank": liab_bank,
               "program_health": health, "err_code": errcode,
               "n_balances": len(bals)}
        out.append(rec)
        print(json.dumps(rec))
    if args.out:
        json.dump(out, open(args.out, "w"), indent=1)


if __name__ == "__main__":
    main()
