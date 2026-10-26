#!/usr/bin/env python3
"""Probe the deployed borrow/remove_collateral account list shape."""
import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import omni as O
import simlib as S
import sim_matrix as M

CLOCK = "SysvarC1ock11111111111111111111111111111111"
RENT = "SysvarRent111111111111111111111111111111111"
PAYER = S.PAYER
ISV = M.INSTRSYSVAR


def main():
    pair = "BZi9iPbcpLWDkHs8nNQe5pb9MxLQe8fbgHtypj2pL4UB"
    p = S.PAIRS[pair]
    pos = next(x for x in S.POSITIONS if x["pair"] == pair and
               (x["debt1_shares"][0] or x["debt1_shares"][1]))
    owner, pospda, mint = pos["owner"], pos["pubkey"], p["token1"]
    rv = S.reserve_vault(pair, mint)
    _, ata = M.ata_create_ix(PAYER, owner, mint, O.TOKEN_PROGRAM)
    core = [pair, pospda, p["rate_model"], S.FA_PDA, rv, ata, mint, owner,
            O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM]
    tail = [S.EA_PDA, O.PID]
    variants = {
        "no_sysvar": core + tail,
        "sysvar": core + [ISV] + tail,
        "sysvar_clock": core + [ISV, CLOCK] + tail,
        "sysvar_rent": core + [ISV, RENT] + tail,
        "clock_sysvar": core + [CLOCK, ISV] + tail,
        "sysvar_x2": core + [ISV, ISV] + tail,
        "sysvar_then_ea": core + [ISV] + tail + [ISV],
        "ea_then_sysvar": core + [S.EA_PDA, ISV, O.PID],
    }
    out = {}
    for name, accts in variants.items():
        data = O.IX["borrow"] + (1).to_bytes(8, "little")
        ixs = [(O.ATA_PROGRAM, [PAYER, ata, owner, mint, O.SYSTEM_PROGRAM, O.TOKEN_PROGRAM], bytes([1])),
               (O.PID, accts, data)]
        w = {PAYER, owner, pair, pospda, p["rate_model"], rv, ata}
        ro = [mint, O.TOKEN_PROGRAM, O.TOKEN_2022, O.SYSTEM_PROGRAM, ISV, CLOCK, RENT,
              S.EA_PDA, O.PID, O.ATA_PROGRAM]
        r = S.run("borrow_" + name, ixs, w, ro, signers=[owner])
        out[name] = {"n": len(accts), "err": r.get("err"), "rpc_error": r.get("rpc_error"),
                     "err_name": M.err_name(r), "log_tail": (r.get("logs") or [])[-3:]}
        print(name, len(accts), out[name]["err_name"], out[name]["rpc_error"], flush=True)
    os.makedirs("../ci-out", exist_ok=True)
    json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                     "..", "ci-out", "borrow_probe.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
