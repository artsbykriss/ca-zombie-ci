#!/usr/bin/env python3
"""Omnipair adversarial simulation matrix (read-only; simulate only).

Every call is simulateTransaction(sigVerify=false, replaceRecentBlockhash=true)
against keyless public RPC.  Nothing is signed or broadcast.

Writes ../ci-out/sim_matrix.json (and .log).
"""
import base64
import json
import os
import sys
import time

import omni as O
import simlib as S
import txbuild as T
from solrpc import rpc as _rpc

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)
PAYER = S.PAYER
NOOP = "noopb9bkMVfRPU8AsbpTUg8AQkHtKwMYZiFUjNRtMmV"
INSTRSYSVAR = "Sysvar1nstructions1111111111111111111111111"

R = {}


def short(r):
    return {"label": r.get("label"), "err": r.get("err"), "cu": r.get("cu"),
            "rpc_error": r.get("rpc_error"),
            "log_tail": (r.get("logs") or [])[-4:]}


def err_name(r):
    """Extract the Anchor error name + number from logs."""
    import re
    for l in reversed(r.get("logs") or []):
        m = re.search(r"Error Code: (\w+)\. Error Number: (\d+)", l)
        if m:
            return {"name": m.group(1), "number": int(m.group(2))}
    e = r.get("err")
    if isinstance(e, dict):
        ie = e.get("InstructionError")
        if ie and isinstance(ie[1], dict) and "Custom" in ie[1]:
            return {"name": "custom", "number": ie[1]["Custom"]}
    return None


def holder_of(mint, n=8):
    for attempt in range(4):
        try:
            r = _rpc("getTokenLargestAccounts", [mint, {"commitment": "confirmed"}],
                     endpoints=T.ENDPOINTS)
            return r["result"]["value"][:n]
        except Exception:  # noqa: BLE001
            time.sleep(3)
    return []


def owner_of_token_account(ta):
    r = _rpc("getAccountInfo", [ta, {"encoding": "jsonParsed", "commitment": "confirmed"}],
             endpoints=T.ENDPOINTS)
    v = r["result"]["value"]
    if not v:
        return None
    return v["data"]["parsed"]["info"]["owner"]


def ata_create_ix(payer, owner, mint, tprog):
    a = O.ata(owner, mint, tprog)
    return (O.ATA_PROGRAM, [payer, a, owner, mint, O.SYSTEM_PROGRAM, tprog], bytes([1])), a


# ---------------------------------------------------------------------------
def t1_liquidate_all():
    """Probe liquidate on every live position with debt.  Expect all
    NotUndercollateralized -> no currently-liquidatable position."""
    res = []
    pairs = S.PAIRS
    for pos in S.POSITIONS:
        p = pairs[pos["pair"]]
        tt0 = pos["debt0_shares"][0] + pos["debt0_shares"][1] * (2 ** 64)
        tt1 = pos["debt1_shares"][0] + pos["debt1_shares"][1] * (2 ** 64)
        if tt0 == 0 and tt1 == 0:
            continue
        # collateral is the opposite token of the debt
        candidates = []
        if tt1 > 0:  # debt1 -> collateral0
            candidates.append(p["token0"])
        if tt0 > 0:  # debt0 -> collateral1
            candidates.append(p["token1"])
        for mint in candidates:
            r = S.probe_liquidate(pos["pair"], pos["owner"], mint)
            res.append({"pos": pos["pubkey"], "pair": pos["pair"], "owner": pos["owner"],
                        "collateral_mint": mint, "err": r.get("err"),
                        "err_name": err_name(r), "rpc_error": r.get("rpc_error"),
                        "cu": r.get("cu"), "log_tail": (r.get("logs") or [])[-3:]})
    ok = sum(1 for x in res if (x["err_name"] or {}).get("name") == "NotUndercollateralized")
    succ = [x for x in res if x["err"] is None]
    R["t1_liquidate_all"] = {"n": len(res), "n_not_undercollateralized": ok,
                             "n_succeeded": len(succ), "succeeded": succ,
                             "all": res}


def t2_substitution():
    """Account substitution on liquidate.  All must be rejected."""
    pair = "BZi9iPbcpLWDkHs8nNQe5pb9MxLQe8fbgHtypj2pL4UB"
    p = S.PAIRS[pair]
    owner = next(x["owner"] for x in S.POSITIONS if x["pair"] == pair and
                 (x["debt1_shares"][0] or x["debt1_shares"][1]))
    mint = p["token0"]
    base = S.liquidate_accounts(pair, owner, mint, S.reserve_vault(pair, mint))

    def run_with(accts, label):
        w = {pair, accts[1], p["rate_model"], accts[4], accts[5], accts[7], PAYER}
        ro = [a for a in accts if a not in w]
        return S.run(label, [(O.PID, accts, O.IX["liquidate"])], w, ro)

    out = {}
    for k, (accts, lbl) in {
        "control_real": (base, "liq_control"),
        "wrong_collateral_mint": (list(base), "liq_wrong_mint"),
        "wrong_user_position": (list(base), "liq_wrong_pos"),
        "wrong_collateral_vault": (list(base), "liq_wrong_vault"),
        "wrong_position_owner": (list(base), "liq_wrong_owner"),
    }.items():
        out[k] = accts
    out["wrong_collateral_mint"][6] = p["lp_mint"]
    out["wrong_user_position"][1] = next(x["pubkey"] for x in S.POSITIONS if x["pair"] != pair)
    out["wrong_collateral_vault"][4] = S.reserve_vault(pair, mint)
    out["wrong_position_owner"][8] = PAYER
    res = {}
    for k, accts in out.items():
        r = run_with(accts, "liq_" + k)
        res[k] = short(r)
        res[k]["err_name"] = err_name(r)
    R["t2_substitution"] = res


def t3_flashloan():
    """Flashloan repayment is enforced post-CPI (flashloan.rs:306)."""
    pair = "BZi9iPbcpLWDkHs8nNQe5pb9MxLQe8fbgHtypj2pL4UB"
    p = S.PAIRS[pair]
    r0 = S.reserve_vault(pair, p["token0"])
    r1 = S.reserve_vault(pair, p["token1"])
    amt = 1000
    data = O.IX["flashloan"] + (amt).to_bytes(8, "little") + (0).to_bytes(8, "little") + (0).to_bytes(4, "little")
    ix_a0, a0 = ata_create_ix(PAYER, PAYER, p["token0"], O.TOKEN_PROGRAM)
    ix_a1, a1 = ata_create_ix(PAYER, PAYER, p["token1"], O.TOKEN_PROGRAM)

    def build(receiver_program):
        accts = [pair, p["rate_model"], S.FA_PDA, r0, r1, p["token0"], p["token1"],
                 a0, a1, receiver_program, PAYER,
                 O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, S.EA_PDA, O.PID]
        w = {PAYER, pair, p["rate_model"], r0, r1, a0, a1}
        ro = [S.FA_PDA, p["token0"], p["token1"], receiver_program, O.TOKEN_PROGRAM,
              O.TOKEN_2022, O.SYSTEM_PROGRAM, S.EA_PDA, O.PID, O.ATA_PROGRAM]
        return S.run("flashloan", [(O.ATA_PROGRAM, ix_a0[1], ix_a0[2]),
                                   (O.ATA_PROGRAM, ix_a1[1], ix_a1[2]),
                                   (O.PID, accts, data)], w, ro)

    out = {}
    # (a) receiver = noop program; it keeps the borrowed tokens -> post-check must fail
    r = build(NOOP)
    out["receiver_keeps_funds"] = short(r); out["receiver_keeps_funds"]["err_name"] = err_name(r)
    # (b) receiver = system program (CPI cannot parse the callback) -> tx must fail
    r = build(O.SYSTEM_PROGRAM)
    out["receiver_system"] = short(r); out["receiver_system"]["err_name"] = err_name(r)
    R["t3_flashloan"] = out


def t4_claim_fees():
    pair = "BZi9iPbcpLWDkHs8nNQe5pb9MxLQe8fbgHtypj2pL4UB"
    p = S.PAIRS[pair]
    r0 = S.reserve_vault(pair, p["token0"])
    r1 = S.reserve_vault(pair, p["token1"])
    ft = S.AUTHORITY["futarchy_treasury"]
    bv = S.AUTHORITY["buybacks_vault"]
    tt = S.AUTHORITY["team_treasury"]

    def build(ft_key, ft0, ft1, label):
        accts = [PAYER, pair, p["rate_model"], S.FA_PDA, r0, r1, p["token0"], p["token1"],
                 ft0, ft1, ft_key,
                 O.ata(bv, p["token0"]), O.ata(bv, p["token1"]), bv,
                 O.ata(tt, p["token0"]), O.ata(tt, p["token1"]), tt,
                 O.TOKEN_PROGRAM, O.TOKEN_2022, O.ATA_PROGRAM, O.SYSTEM_PROGRAM,
                 S.EA_PDA, O.PID]
        w = {PAYER, pair, p["rate_model"], r0, r1, ft0, ft1,
             O.ata(bv, p["token0"]), O.ata(bv, p["token1"]),
             O.ata(tt, p["token0"]), O.ata(tt, p["token1"])}
        ro = [a for a in accts if a not in w]
        return S.run(label, [(O.PID, accts, O.IX["claim_protocol_fees"])], w, ro)

    out = {}
    # legit
    r = build(ft, O.ata(ft, p["token0"]), O.ata(ft, p["token1"]), "claim_legit")
    out["legit"] = short(r); out["legit"]["err_name"] = err_name(r)
    out["legit"]["post_balances"] = r.get("post")
    out["legit"]["raw_logs"] = r.get("raw_logs")
    # attacker substitutes its own recipient address
    r = build(PAYER, O.ata(ft, p["token0"]), O.ata(ft, p["token1"]), "claim_attacker_recipient")
    out["attacker_recipient"] = short(r); out["attacker_recipient"]["err_name"] = err_name(r)
    # attacker substitutes its own ATA but keeps real recipient
    r = build(ft, O.ata(PAYER, p["token0"]), O.ata(ft, p["token1"]), "claim_attacker_ata")
    out["attacker_ata"] = short(r); out["attacker_ata"]["err_name"] = err_name(r)
    R["t4_claim_fees"] = out


def t5_borrow_and_circuit_breaker():
    """borrow beyond collateral; and same-tx add_liquidity circuit breaker."""
    pair = "BZi9iPbcpLWDkHs8nNQe5pb9MxLQe8fbgHtypj2pL4UB"
    p = S.PAIRS[pair]
    pos = next(x for x in S.POSITIONS if x["pair"] == pair and
               (x["debt1_shares"][0] or x["debt1_shares"][1]))
    owner = pos["owner"]
    pospda = pos["pubkey"]
    mint = p["token1"]
    rv = S.reserve_vault(pair, mint)
    _, ata = ata_create_ix(PAYER, owner, mint, O.TOKEN_PROGRAM)

    def borrow_ix(amount, with_sysvar, extra_add_liquidity=False):
        data = O.IX["borrow"] + amount.to_bytes(8, "little")
        accts = [pair, pospda, p["rate_model"], S.FA_PDA, rv, ata, mint, owner,
                 O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM]
        if with_sysvar:
            accts.append(INSTRSYSVAR)
        accts += [S.EA_PDA, O.PID]
        ixs = [(O.ATA_PROGRAM, [PAYER, ata, owner, mint, O.SYSTEM_PROGRAM, O.TOKEN_PROGRAM], bytes([1]))]
        ixs.append((O.PID, accts, data))
        if extra_add_liquidity:
            # fake add_liquidity for the same pair AFTER borrow -> guard must fire
            ixs.append((O.PID, [pair], O.IX["add_liquidity"] + b"\x00" * 24))
        w = {PAYER, owner, pair, pospda, p["rate_model"], rv, ata}
        ro = [mint, O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, INSTRSYSVAR,
              S.EA_PDA, O.PID, O.ATA_PROGRAM]
        return S.run("borrow", ixs, w, ro, signers=[owner])

    out = {}
    r = borrow_ix(2 ** 64 - 1, with_sysvar=True)
    out["v105_borrow_u64max"] = short(r); out["v105_borrow_u64max"]["err_name"] = err_name(r)
    r = borrow_ix(2 ** 64 - 1, with_sysvar=False)
    out["v099_borrow_u64max"] = short(r); out["v099_borrow_u64max"]["err_name"] = err_name(r)
    r = borrow_ix(1, with_sysvar=True)
    out["v105_borrow_1"] = short(r); out["v105_borrow_1"]["err_name"] = err_name(r)
    r = borrow_ix(1, with_sysvar=True, extra_add_liquidity=True)
    out["v105_borrow_with_add_liquidity"] = short(r); out["v105_borrow_with_add_liquidity"]["err_name"] = err_name(r)
    R["t5_borrow"] = out


def t6_remove_collateral():
    pair = "BZi9iPbcpLWDkHs8nNQe5pb9MxLQe8fbgHtypj2pL4UB"
    p = S.PAIRS[pair]
    pos = next(x for x in S.POSITIONS if x["pair"] == pair and
               (x["debt1_shares"][0] or x["debt1_shares"][1]) and x["collateral0"] > 0)
    owner = pos["owner"]; pospda = pos["pubkey"]
    mint = p["token0"]
    cv = S.collateral_vault(pair, mint)
    ix_ata, ata = ata_create_ix(PAYER, owner, mint, O.TOKEN_PROGRAM)

    def rem(amount):
        data = O.IX["remove_collateral"] + amount.to_bytes(8, "little")
        accts = [pair, pospda, p["rate_model"], S.FA_PDA, cv, ata, mint, owner,
                 O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, INSTRSYSVAR, S.EA_PDA, O.PID]
        ixs = [(O.ATA_PROGRAM, [PAYER, ata, owner, mint, O.SYSTEM_PROGRAM, O.TOKEN_PROGRAM], bytes([1])),
               (O.PID, accts, data)]
        w = {PAYER, pair, pospda, p["rate_model"], cv, ata, owner}
        ro = [mint, O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, INSTRSYSVAR, S.EA_PDA, O.PID, O.ATA_PROGRAM]
        return S.run("remove_collateral", ixs, w, ro, signers=[owner])

    out = {}
    r = rem(pos["collateral0"])           # remove everything
    out["remove_all"] = short(r); out["remove_all"]["err_name"] = err_name(r)
    r = rem(1)                            # tiny amount (may be allowed)
    out["remove_1_unit"] = short(r); out["remove_1_unit"]["err_name"] = err_name(r)
    R["t6_remove_collateral"] = out


def t7_liquidate_measure():
    """Measure the exact caller incentive for EVERY currently-liquidatable
    position (read the caller ATA token delta from the simulation)."""
    # reuse t1 results if present, else probe
    liq = R.get("t1_liquidate_all", {}).get("all")
    if not liq:
        t1_liquidate_all()
        liq = R["t1_liquidate_all"]["all"]
    targets = [x for x in liq if x.get("err") is None]
    out = {"n_liquidatable": len(targets), "measured": []}
    for t in targets:
        pair, owner, mint = t["pair"], t["owner"], t["collateral_mint"]
        p = S.PAIRS[pair]
        pospda = t["pos"]
        cv = S.collateral_vault(pair, mint)
        rv = S.reserve_vault(pair, mint)
        _, ata = ata_create_ix(PAYER, PAYER, mint, O.TOKEN_PROGRAM)
        accts = [pair, pospda, p["rate_model"], S.FA_PDA, cv, ata, mint, rv, owner, PAYER,
                 O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, S.EA_PDA, O.PID]
        ixs = [(O.ATA_PROGRAM, [PAYER, ata, PAYER, mint, O.SYSTEM_PROGRAM, O.TOKEN_PROGRAM], bytes([1])),
               S.cu_limit_ix(),
               (O.PID, accts, O.IX["liquidate"])]
        w = {PAYER, pair, pospda, p["rate_model"], cv, ata, rv, S.COMPUTE_BUDGET}
        r = S.run("liquidate_measure", ixs, w, [])
        pre = {b["accountIndex"]: b for b in (r.get("pre") or [])}
        post = {b["accountIndex"]: b for b in (r.get("post") or [])}
        deltas = []
        for i in sorted(set(pre) | set(post)):
            a = pre.get(i) or post.get(i)
            pamt = int((pre.get(i) or {}).get("uiTokenAmount", {}).get("amount") or 0)
            qamt = int((post.get(i) or {}).get("uiTokenAmount", {}).get("amount") or 0)
            if pamt != qamt:
                deltas.append({"owner": a.get("owner"), "mint": a.get("mint"),
                               "pre": pamt, "post": qamt, "delta": qamt - pamt,
                               "decimals": a.get("uiTokenAmount", {}).get("decimals")})
        out["measured"].append({"pos": pospda, "pair": pair, "mint": mint,
                                "err": r.get("err"), "err_name": err_name(r),
                                "caller_ata": ata, "deltas": deltas})
    R["t7_liquidate_measure"] = out


WSOL = "So11111111111111111111111111111111111111112"
SYSTEM_TRANSFER = 2
SYNC_NATIVE = 17


def t8_price_manipulation():
    """[swap (dump WSOL), liquidate] in one tx on a healthy SOL-collateralised
    position.  liquidate prices off the symmetric EMA, which pair.update()
    does not recompute within the same slot, so the manipulated spot must not
    change the liquidation valuation.  Self-contained: the attacker wraps its
    own SOL (the payer is funded) instead of borrowing a holder."""
    # find a pair with token0 == WSOL and a healthy position (collateral0=SOL, debt1>0)
    target = None
    for p in S.PAIRS.values():
        if p["token0"] != WSOL:
            continue
        for x in S.POSITIONS:
            if x["pair"] != p["pubkey"]:
                continue
            tt1 = x["debt1_shares"][0] + x["debt1_shares"][1] * (2 ** 64)
            if x["collateral0"] > 0 and tt1 > 0:
                target = (p, x)
                break
        if target:
            break
    if not target:
        R["t8_price_manipulation"] = {"note": "no WSOL-collateral position with debt found"}
        return
    p, pos = target
    pair = p["pubkey"]
    rv_in = S.reserve_vault(pair, WSOL)          # SOL reserve vault (sell side)
    rv_out = S.reserve_vault(pair, p["token1"])  # other reserve vault
    cv = S.collateral_vault(pair, WSOL)
    wsol_ata = O.ata(PAYER, WSOL, O.TOKEN_PROGRAM)
    _, caller = ata_create_ix(PAYER, PAYER, WSOL, O.TOKEN_PROGRAM)
    out = {"pair": pair, "position": pos["pubkey"], "owner": pos["owner"],
           "collateral0_sol": pos["collateral0"], "debt1_shares": pos["debt1_shares"],
           "pool_reserve0": p["reserve0"], "pool_reserve1": p["reserve1"]}
    LAM = 2_000_000_000  # dump 2 SOL

    def liq_accounts(caller_acct):
        return [pair, pos["pubkey"], p["rate_model"], S.FA_PDA, cv, caller_acct, WSOL,
                rv_in, pos["owner"], PAYER, O.TOKEN_PROGRAM, O.TOKEN_2022,
                O.SYSTEM_PROGRAM, S.EA_PDA, O.PID]

    def wsets(caller_acct):
        w = {PAYER, pair, pos["pubkey"], p["rate_model"], cv, caller_acct, rv_in, rv_out,
             wsol_ata}
        return w

    # baseline: liquidate alone
    base_accts = liq_accounts(caller)
    r0 = S.run("liquidate_baseline", [(O.PID, base_accts, O.IX["liquidate"])],
               wsets(caller), [], )
    out["baseline"] = short(r0); out["baseline"]["err_name"] = err_name(r0)
    # manipulated: create+fund WSOL ATA, dump it via swap, then liquidate
    swap_data = O.IX["swap"] + LAM.to_bytes(8, "little") + (0).to_bytes(8, "little")
    swap_accts = [pair, p["rate_model"], S.FA_PDA, rv_in, rv_out, wsol_ata, O.ata(PAYER, p["token1"], O.TOKEN_PROGRAM),
                  WSOL, p["token1"], PAYER, O.TOKEN_PROGRAM, O.TOKEN_2022, S.EA_PDA, O.PID]
    ixs = [
        (O.ATA_PROGRAM, [PAYER, wsol_ata, PAYER, WSOL, O.SYSTEM_PROGRAM, O.TOKEN_PROGRAM], bytes([1])),
        (O.ATA_PROGRAM, [PAYER, O.ata(PAYER, p["token1"], O.TOKEN_PROGRAM), PAYER, p["token1"],
                         O.SYSTEM_PROGRAM, O.TOKEN_PROGRAM], bytes([1])),
        (O.SYSTEM_PROGRAM, [PAYER, wsol_ata], SYSTEM_TRANSFER.to_bytes(4, "little") + LAM.to_bytes(8, "little")),
        (O.TOKEN_PROGRAM, [wsol_ata], bytes([SYNC_NATIVE])),
        (O.PID, swap_accts, swap_data),
        (O.PID, base_accts, O.IX["liquidate"]),
    ]
    w = wsets(caller) | {O.ata(PAYER, p["token1"], O.TOKEN_PROGRAM)}
    r = S.run("swap_then_liquidate", ixs, w, [])
    out["swap_then_liquidate"] = short(r); out["swap_then_liquidate"]["err_name"] = err_name(r)
    out["swap_and_liquidate_identical"] = (
        (out["baseline"].get("err_name") == out["swap_then_liquidate"].get("err_name")))

    # decisive state-level proof: run ONLY the swap and read the pair post-state.
    # The spot price collapses but the symmetric EMA (used by liquidate) keeps
    # its pre-swap value; only the directional EMA snaps down.
    pre = decode_pair_state(pair)
    swap_only = ixs[:5]
    try:
        tx = T.build_legacy(PAYER, list(w), [], T.blockhash(), swap_only)
        res = T.simulate(tx, extra={"accounts": {"encoding": "base64", "addresses": [pair]}})
        v = res.get("value") or {}
        accs = v.get("accounts") or []
        post = None
        if accs and accs[0]:
            post = O.decode_pair(base64.b64decode(accs[0]["data"][0]))
        out["swap_only_err"] = v.get("err")
        if post:
            out["ema_proof"] = {
                "pre_spot_price0_nad": (pre["reserve1"] * 10 ** 9 // pre["reserve0"]) if pre["reserve0"] else 0,
                "post_spot_price0_nad": (post["reserve1"] * 10 ** 9 // post["reserve0"]) if post["reserve0"] else 0,
                "pre_sym_ema0": pre["last_price0_ema_sym"],
                "post_sym_ema0": post["last_price0_ema_sym"],
                "pre_dir_ema0": pre["last_price0_ema_dir"],
                "post_dir_ema0": post["last_price0_ema_dir"],
                "pre_reserve0": pre["reserve0"], "post_reserve0": post["reserve0"],
                "pre_reserve1": pre["reserve1"], "post_reserve1": post["reserve1"],
                "pre_last_update": pre["last_update"], "post_last_update": post["last_update"],
            }
    except Exception as e:  # noqa: BLE001
        out["ema_proof_error"] = repr(e)
    R["t8_price_manipulation"] = out


def decode_pair_state(pair):
    import base64 as _b
    r = _rpc("getAccountInfo", [pair, {"encoding": "base64", "commitment": "confirmed"}],
             endpoints=T.ENDPOINTS)
    return O.decode_pair(_b.b64decode(r["result"]["value"]["data"][0]))


def M_holder(mint, n=8):
    import time as _t
    for _ in range(4):
        try:
            r = _rpc("getTokenLargestAccounts", [mint, {"commitment": "confirmed"}],
                     endpoints=T.ENDPOINTS)
            return r["result"]["value"][:n]
        except Exception:  # noqa: BLE001
            _t.sleep(4)
    return []


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    tests = {
        "t1": t1_liquidate_all,
        "t2": t2_substitution,
        "t3": t3_flashloan,
        "t4": t4_claim_fees,
        "t5": t5_borrow_and_circuit_breaker,
        "t6": t6_remove_collateral,
        "t7": t7_liquidate_measure,
        "t8": t8_price_manipulation,
    }
    for k, fn in tests.items():
        if which not in ("all", k):
            continue
        print(f"== {k} {fn.__name__} ==", flush=True)
        try:
            fn()
        except Exception as e:  # noqa: BLE001
            R[k] = {"exception": repr(e)}
            print("   EXC", repr(e), flush=True)
        json.dump(R, open(os.path.join(OUT, "sim_matrix.json"), "w"), indent=1)
    print(json.dumps(R, indent=1)[:4000], flush=True)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
