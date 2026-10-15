#!/usr/bin/env python3
"""READ-ONLY: is the pool's stored total_lamports consistent with the chain RIGHT NOW?

Computes  T_chain = (reserve.lamports - reserve_rent) + sum(validator stake accounts)
and compares it with stake_pool.total_lamports, all read at the same commitment.
Reports the current epoch / slot and the liquidity ratio T/S.
"""
import base64, json, sys, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from rpc import rpc, b58enc, b58dec  # noqa
from decode_pool_v210 import decode  # noqa
import decode_vlist_v210 as vl  # noqa

POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"
RESERVE = "aeroivis36SwDvAJpzQCDX9Y7cCLXBdv9vTn1DtDnVC"
MINT = "aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF"

RENT_EXEMPT_MIN = 890880  # lamports/byte baseline; recomputed below exactly


def main():
    recs = json.loads((HERE / "derived_validator_stakes.json").read_text())
    addrs = [POOL, RESERVE, MINT] + [r["validator_stake"] for r in recs]
    info = {}
    for s in range(0, len(addrs), 60):
        chunk = addrs[s:s + 60]
        res = rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "confirmed"}])
        for a, v in zip(chunk, res["value"]):
            info[a] = v
    slot = rpc("getSlot", [{"commitment": "confirmed"}])
    epi = rpc("getEpochInfo", [{"commitment": "confirmed"}])
    rent_exempt = rpc("getMinimumBalanceForRentExemption", [200, {"commitment": "confirmed"}])
    print(f"slot={slot} epoch={epi['epoch']} epochProgress={epi['slotIndex']}/{epi['slotsInEpoch']}")

    pool = info[POOL]
    st = decode(base64.b64decode(pool["data"][0]))
    print(f"pool.last_update_epoch = {st['last_update_epoch']}   (chain epoch {epi['epoch']})")
    print(f"pool.total_lamports    = {st['total_lamports']}")
    print(f"pool.pool_token_supply = {st['pool_token_supply']}")
    print(f"stale? last_update_epoch < epoch -> {st['last_update_epoch'] < epi['epoch']}")

    reserve = info[RESERVE]
    mint = info[MINT]
    print(f"reserve.lamports = {reserve['lamports']}  owner={reserve['owner']}")
    print(f"mint.owner={mint['owner']} supply={int.from_bytes(base64.b64decode(mint['data'][0])[36:44],'little')}")
    rent200 = rent_exempt
    res_contrib = reserve["lamports"] - rent200
    print(f"rent(min 200B) = {rent200}; reserve contribution to T = {res_contrib}")

    # sum live validator stake accounts
    tot = 0
    deltas = []
    for r in recs:
        v = info[r["validator_stake"]]
        tot += v["lamports"]
        deltas.append(v["lamports"] - r["active"])
    T_chain = res_contrib + tot
    T_stored = st["total_lamports"]
    print(f"\nsum(live validator stake lamports) = {tot}")
    print(f"T_chain  = reserve_contrib + sum_accounts = {T_chain}")
    print(f"T_stored = {T_stored}")
    d = T_chain - T_stored
    print(f"T_chain - T_stored = {d} lamports ({d/1e9:.9f} SOL)  ratio={T_chain/T_stored:.12f}")
    print(f"sum(account-record deltas) = {sum(deltas)}  (per-account min={min(deltas)} max={max(deltas)})")
    # implied profit for a deposit-then-update-then-withdraw cycle
    S = st["pool_token_supply"]
    print(f"\nif T_stored were below reality by X, attacker edge per deposited SOL = X/T")
    print(f"current edge = {(T_chain/T_stored - 1)*100:.9f}%   (withdraw-blocked if stale={st['last_update_epoch'] < epi['epoch']})")
    (HERE / "consistency_now.json").write_text(json.dumps(
        {"slot": slot, "epoch": epi["epoch"], "last_update_epoch": st["last_update_epoch"],
         "T_stored": T_stored, "T_chain": T_chain, "reserve": reserve["lamports"],
         "sum_accounts": tot, "rent200": rent200, "delta": d}, indent=1))


if __name__ == "__main__":
    main()
