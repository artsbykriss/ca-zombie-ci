#!/usr/bin/env python3
"""Omnipair unprivileged-extraction simulation harness (read-only).

Builds attacker messages (sigVerify=false, replaceRecentBlockhash=true) and
runs simulateTransaction.  Nothing is signed or broadcast.
"""
import json
import os

import omni as O
import txbuild as T

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "live_state.json")))
PAIRS = {p["pubkey"]: p for p in D["pairs"]}
POSITIONS = D["positions"]
AUTHORITY = D["authorities"][0]
FA_PDA = AUTHORITY["pubkey"]
EA_PDA = O.EVENT_AUTHORITY_PDA
PAYER = T.NEUTRAL_PAYER
COMPUTE_BUDGET = "ComputeBudget111111111111111111111111111111"


def cu_limit_ix(units=1_400_000):
    # ComputeBudget SetComputeUnitLimit (tag 2) + u32 LE
    return (COMPUTE_BUDGET, [], bytes([2]) + units.to_bytes(4, "little"))

POSMAP = {(p["pair"], p["owner"]): p for p in POSITIONS}


def collateral_vault(pair, mint):
    b = PAIRS[pair]["vault_bumps"]
    bump = b["collateral0"] if mint == PAIRS[pair]["token0"] else b["collateral1"]
    return O.b58enc(O.create_pda([O.COLLATERAL_VAULT_SEED, O.b58dec(pair), O.b58dec(mint), bytes([bump])]))


def reserve_vault(pair, mint):
    b = PAIRS[pair]["vault_bumps"]
    bump = b["reserve0"] if mint == PAIRS[pair]["token0"] else b["reserve1"]
    return O.b58enc(O.create_pda([O.RESERVE_VAULT_SEED, O.b58dec(pair), O.b58dec(mint), bytes([bump])]))


def position_pda(pair, owner):
    p = POSMAP.get((pair, owner))
    if not p:
        return None
    return O.b58enc(O.create_pda([O.POSITION_SEED, O.b58dec(pair), O.b58dec(owner), bytes([p["bump"]])]))


def run(label, ixs, writable, readonly, payer=PAYER, signers=None):
    """ixs: list of (program_id, [accounts], data_bytes)."""
    writable = list(writable)
    readonly = list(readonly)
    # auto-include any referenced account not already classified (as readonly)
    for pid, accts, _ in ixs:
        for a in [pid] + list(accts):
            if a not in writable and a not in readonly and a != payer:
                readonly.append(a)
    bh = T.blockhash()
    try:
        tx = T.build_legacy(payer, writable, readonly, bh, ixs, signers=signers)
        r = T.simulate(tx)
    except Exception as e:  # noqa: BLE001
        return {"label": label, "rpc_error": str(e)}
    v = r.get("value") or {}
    return {"label": label, "err": v.get("err"), "cu": v.get("unitsConsumed"),
            "logs": [l for l in (v.get("logs") or []) if "failed" in l or "Program log:" in l or "consumed" in l],
            "raw_logs": v.get("logs") or [],
            "pre": v.get("preTokenBalances"), "post": v.get("postTokenBalances")}


def liquidate_accounts(pair, owner, mint, caller_token_account):
    p = PAIRS[pair]
    return [pair, position_pda(pair, owner), p["rate_model"], FA_PDA,
            collateral_vault(pair, mint), caller_token_account, mint,
            reserve_vault(pair, mint), owner, PAYER,
            O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, EA_PDA, O.PID]


def probe_liquidate(pair, owner, mint, caller_token_account=None):
    accts = liquidate_accounts(pair, owner, mint, caller_token_account or reserve_vault(pair, mint))
    w = {pair, accts[1], PAIRS[pair]["rate_model"], accts[4], accts[5], accts[7], PAYER,
         COMPUTE_BUDGET}
    ro = [a for a in accts if a not in w]
    return run(f"liq:{pair[:6]}:{owner[:6]}:{mint[:6]}",
               [cu_limit_ix(), (O.PID, accts, O.IX["liquidate"])], w, ro)


if __name__ == "__main__":
    print("FA", FA_PDA, "EA", EA_PDA)
    pair = "Cp2nGCWWfqkUmPR3pPKoR376Fti8wuYRFrSWJZq1a9SA"
    owner = "BG4ze1SJc9AkKRRxMoME6Acmw7pKNw1mwZJUNSeXgzzo"
    mint = PAIRS[pair]["token0"]
    r = probe_liquidate(pair, owner, mint)
    print(json.dumps({k: r[k] for k in ("label", "err", "cu")}, indent=1))
    for l in r.get("raw_logs") or []:
        print("  ", l)
