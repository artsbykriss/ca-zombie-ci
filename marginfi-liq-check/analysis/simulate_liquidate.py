#!/usr/bin/env python3
"""Simulate marginfi `lending_account_liquidate` against LIVE mainnet state (read-only).

No transaction is signed or sent: `simulateTransaction` with sigVerify=false executes the
instruction against current mainnet accounts and returns logs / error / post-state.

This is the program's own verdict on whether a target is genuinely liquidatable
(6068 HealthyAccount == not liquidatable at these oracle prices).

Usage:
  python3 simulate_liquidate.py --liquidatee <pk> --liquidator <pk> --asset-bank <pk> \
      --liab-bank <pk> [--amount N] [--tag TAG]
"""
import argparse, base64, json, os, struct, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import (PROGRAM, I80F48, b58decode, b58encode, rpc, get_accounts,
                        decode_balances, pda, i80)

LIQ_DISC = bytes([214, 169, 151, 213, 251, 167, 86, 219])
TOKEN_PROGRAM = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
COMPUTE_BUDGET = "ComputeBudget111111111111111111111111111111"

ORACLE_SETUP = {0: 'None', 1: 'PythLegacy', 2: 'SwitchboardV2', 3: 'PythPushOracle', 4: 'SwitchboardPull',
                5: 'StakedWithPythPush', 6: 'KaminoPythPush', 7: 'KaminoSwitchboardPull', 8: 'Fixed',
                9: 'DriftPythPull', 10: 'DriftSwitchboardPull', 11: 'SolendPythPull',
                12: 'SolendSwitchboardPull', 13: 'FixedKamino', 14: 'FixedDrift', 15: 'JuplendPythPull',
                16: 'JuplendSwitchboardPull', 17: 'FixedJuplend', 18: 'Scope', 19: 'PythMSOL',
                20: 'KaminoMSOL', 21: 'JuplendMSOL', 22: 'PythLST', 23: 'KaminoLST', 24: 'JuplendLST',
                25: 'PTPyth', 26: 'PTFixed', 27: 'ScopeKamino', 28: 'ScopeJuplend'}
ASSET_TAG = {0: 'Default', 1: 'SOL', 2: 'Kamino', 3: 'Drift', 4: 'Solend', 5: 'Staked', 6: 'Juplend'}

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decode_bank import decode_bank


def shortvec(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        if n == 0:
            out += bytes([b])
            return out
        out += bytes([b | 0x80])


class Meta:
    def __init__(self):
        self.keys = []           # ordered unique pubkey strings
        self.meta = {}           # pubkey -> [signer, writable]

    def add(self, pk, signer=False, writable=False):
        if pk not in self.meta:
            self.keys.append(pk)
            self.meta[pk] = [signer, writable]
        else:
            self.meta[pk][0] |= signer
            self.meta[pk][1] |= writable
        return self.keys.index(pk)


def accounts_for_bank(bank_pk, bank_cfg):
    """Return the per-bank remaining account list (bank + oracle/aux accounts).
    Mirrors get_remaining_accounts_per_bank() in the deployed program."""
    setup = bank_cfg["oracle_setup"]
    keys = bank_cfg["oracle_keys"]
    out = [bank_pk]
    if setup == 'Fixed':
        pass
    elif setup in ('FixedKamino', 'FixedDrift', 'FixedJuplend'):
        out.append(keys[1])
    elif setup in ('PythPushOracle', 'SwitchboardPull', 'Scope', 'StakedWithPythPush'):
        out.append(keys[0])
    elif setup == 'PythLST':
        out += [keys[0], keys[1]]
    elif setup == 'PythMSOL':
        out += [keys[0], keys[1]]
    elif setup in ('KaminoLST', 'JuplendLST', 'KaminoMSOL', 'JuplendMSOL'):
        out += [keys[0], keys[1], keys[2]]
    elif setup == 'PTPyth':
        out += [keys[0], keys[1]]
    elif setup == 'PTFixed':
        out.append(keys[1])
    elif setup in ('ScopeKamino', 'ScopeJuplend'):
        out += [keys[0], keys[1]]
    elif setup in ('KaminoPythPush', 'KaminoSwitchboardPull', 'JuplendPythPull',
                   'JuplendSwitchboardPull'):
        out += [keys[0], keys[1]]
    else:
        # asset-tag based fallback (bank, oracle[, integration]) — tags are numeric
        tag = bank_cfg["asset_tag"]
        if tag in (0, 1):            # Default | SOL
            out.append(keys[0])
        elif tag in (3, 4, 5, 6):    # Kamino | Drift | Solend | Juplend
            out += [keys[0], keys[1]]
        elif tag == 2:               # Staked: bank, oracle, lst mint, lst pool, onramp
            out += [keys[0], keys[1], keys[2], keys[3]]
        else:
            raise RuntimeError(f"unknown setup {setup} tag {tag}")
    return out


def build_tx(fee_payer, instructions, blockhash="11111111111111111111111111111111"):
    """instructions: list of (program_id, [ (pk, signer, writable), ... ], data)."""
    m = Meta()
    m.add(fee_payer, True, True)
    ix_build = []
    for prog, metas, data in instructions:
        idxs = []
        for pk, sg, wr in metas:
            idxs.append(m.add(pk, sg, wr))
        pi = m.add(prog, False, False)
        ix_build.append((pi, idxs, data))
    n_sig = sum(1 for k in m.keys if m.meta[k][0])
    n_ro_sig = sum(1 for k in m.keys if m.meta[k][0] and not m.meta[k][1])
    n_ro_unsig = sum(1 for k in m.keys if not m.meta[k][0] and not m.meta[k][1])
    # reorder: writable signers, readonly signers, writable unsigned, readonly unsigned
    ws = [k for k in m.keys if m.meta[k][0] and m.meta[k][1]]
    rs = [k for k in m.keys if m.meta[k][0] and not m.meta[k][1]]
    wu = [k for k in m.keys if not m.meta[k][0] and m.meta[k][1]]
    ru = [k for k in m.keys if not m.meta[k][0] and not m.meta[k][1]]
    keys = ws + rs + wu + ru
    idx = {k: i for i, k in enumerate(keys)}
    old2new = {i: idx[m.keys[i]] for i in range(len(m.keys))}
    msg = bytes([n_sig, n_ro_sig, n_ro_unsig])
    msg += shortvec(len(keys))
    for k in keys:
        msg += b58decode(k)
    msg += b58decode(blockhash)
    msg += shortvec(len(ix_build))
    for pi, idxs, data in ix_build:
        msg += bytes([old2new[pi]])
        msg += shortvec(len(idxs))
        msg += bytes([old2new[i] for i in idxs])
        msg += shortvec(len(data)) + data
    return bytes([n_sig]) + b"\x00" * 64 * n_sig + msg  # dummy sigs (sigVerify=false)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--liquidatee", required=True)
    ap.add_argument("--liquidator", required=True)
    ap.add_argument("--asset-bank", required=True)
    ap.add_argument("--liab-bank", required=True)
    ap.add_argument("--amount", type=int, default=1_000_000_000)
    ap.add_argument("--authority", default=None)
    ap.add_argument("--label", default="")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    slot = rpc("getSlot", [])
    # banks
    bres = get_accounts([args.asset_bank, args.liab_bank])
    asset_bank = decode_bank(bres[0][3])
    liab_bank = decode_bank(bres[1][3])
    # liquidatee + liquidator accounts
    ares = get_accounts([args.liquidatee, args.liquidator])
    if ares[0] is None or ares[1] is None:
        raise RuntimeError("account missing")
    liqee = ares[0][3]
    liqor = ares[1][3]
    liqee_group = b58encode(liqee[8:40])
    liqor_group = b58encode(liqor[8:40])
    assert liqee_group == liqor_group, "different groups"
    group = liqee_group
    liqor_authority = args.authority or b58encode(liqor[40:72])

    liqee_bal = decode_balances(liqee)
    liqor_bal = decode_balances(liqor)

    # post-liquidation balances (sorted desc by bank_pk bytes)
    def post_balances(bals, extra_banks):
        seen = {b["bank"] for b in bals}
        all_banks = [b["bank"] for b in bals] + [b for b in extra_banks if b not in seen]
        return sorted(set(all_banks), key=lambda p: b58decode(p), reverse=True)

    liqee_banks = post_balances(liqee_bal, [])
    liqor_banks = post_balances(liqor_bal, [args.asset_bank, args.liab_bank])

    bank_cache = {args.asset_bank: asset_bank, args.liab_bank: liab_bank}

    def get_bank_cfg(pk):
        if pk not in bank_cache:
            bank_cache[pk] = decode_bank(get_accounts([pk])[0][3])
        return bank_cache[pk]

    liqee_ais = []
    for pk in liqee_banks:
        liqee_ais += accounts_for_bank(pk, get_bank_cfg(pk)["config"])
    liqor_ais = []
    for pk in liqor_banks:
        liqor_ais += accounts_for_bank(pk, get_bank_cfg(pk)["config"])

    asset_oracles = accounts_for_bank(args.asset_bank, asset_bank["config"])[1:]
    liab_oracles = accounts_for_bank(args.liab_bank, liab_bank["config"])[1:]

    # named accounts
    liq_auth_pda, _ = pda([b"liquidity_vault_auth", b58decode(args.liab_bank)])

    metas = [
        (group, False, False),
        (args.asset_bank, False, True),
        (args.liab_bank, False, True),
        (args.liquidator, False, True),
        (liqor_authority, True, False),
        (args.liquidatee, False, True),
        (liq_auth_pda, False, False),
        (liab_bank["liquidity_vault"], False, True),
        (liab_bank["insurance_vault"], False, True),
        (TOKEN_PROGRAM, False, False),
    ]
    for pk in asset_oracles + liab_oracles + liqor_ais + liqee_ais:
        metas.append((pk, False, False))

    data = LIQ_DISC + struct.pack("<QBB", args.amount, len(liqee_ais), len(liqor_ais))
    cb_data = bytes([2]) + struct.pack("<I", 1_400_000)   # SetComputeUnitLimit
    tx = build_tx(liqor_authority, [(COMPUTE_BUDGET, [], cb_data), (PROGRAM, metas, data)])

    res = rpc("simulateTransaction", [base64.b64encode(tx).decode(),
              {"encoding": "base64", "sigVerify": False, "replaceRecentBlockhash": True,
               "commitment": "processed"}], timeout=120)
    val = res["value"]
    out = {
        "slot": slot, "label": args.label,
        "liquidatee": args.liquidatee, "liquidator": args.liquidator,
        "asset_bank": args.asset_bank, "liab_bank": args.liab_bank,
        "amount": args.amount,
        "liqee_banks": liqee_banks, "liqor_banks": liqor_banks,
        "n_liqee_ais": len(liqee_ais), "n_liqor_ais": len(liqor_ais),
        "err": val.get("err"), "units_consumed": val.get("unitsConsumed"),
        "logs": val.get("logs", []),
    }
    if args.out:
        json.dump(out, open(args.out, "w"), indent=1)
    print(json.dumps({k: v for k, v in out.items() if k != "logs"}, indent=1))
    print("--- logs tail ---")
    for l in out["logs"][-25:]:
        print(l)


if __name__ == "__main__":
    main()
