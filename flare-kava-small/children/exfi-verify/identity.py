"""Task 1 (re-run after the parent tree was deleted mid-verification):
independently re-derive the payout identity live for verifier-chosen stakers.

unclaimed(user,token) ?= sum_{e=lastClaim+1..latestRewardEpoch} balanceOfEpoch(user,e)*epochRewardRate(e,token)/1e18/10^(18-dec)

Report three arithmetic orders:
  A: per-epoch truncate (b*r//1e18//scale) then sum   <- parent's claim
  C: exact rational -> floor once at the end
"""
import json
from lib import *

MGR = "0xc4D89F8f593F215f3636793E3353A36C196Cf87A"
USERS = [
    ("U1_0B465f43", "0x0B465f43db2F05a3A68F838c5080aCae649f28d4"),
    ("U2_FAA9f4d3", "0xFAA9f4d3dF9bd35fEb56105691748DAf65F420D8"),
    ("U3_1C14e47b", "0x1C14e47bAAe4CBC7C2D5A2B05A76281D82805436"),
]
FRESH = "0x3333333333333333333333333333333333333333"
FRESH_SAMPLE = [1, 50, 150, 300, 370, 375]

def main():
    blk0 = int(rpc("eth_blockNumber", []), 16)
    latest = dec_uint(one_call(MGR, sel("getLatestEpochForRewards()")))
    cur = dec_uint(one_call(MGR, sel("getCurrentEpoch()")))
    tokens = dec_aarr(one_call(MGR, sel("getRewardTokens()")))
    dec_res = batch_eth_call([{"to": t, "data": sel("decimals()")} for t in tokens])
    decimals = [dec_uint(r) if not isinstance(r, dict) else None for r in dec_res]
    scale = [10 ** (18 - d) if d < 18 else 1 for d in decimals]
    syms = ["WSGB", "EXFI", "SFIN", "exXDC", "FXRP", "exETH", "exUSDT", "USDX"]

    # ---- stage 1: per-user claim state
    calls = []
    meta = []
    for name, u in USERS + [("FRESH", FRESH)]:
        calls.append({"to": MGR, "data": sel("userLastRewardClaimEpoch(address)") + addr(u)})
        meta.append((name, "last", None))
        calls.append({"to": MGR, "data": sel("getAllUnclaimedRewards(address)") + addr(u)})
        meta.append((name, "unclaimed", None))
        calls.append({"to": MGR, "data": sel("canClaimRewards(address)") + addr(u)})
        meta.append((name, "can", None))
    res = batch_eth_call(calls)
    state = {}
    for (name, kind, _), r in zip(meta, res):
        state.setdefault(name, {})[kind] = None if isinstance(r, dict) else r
    print("block", blk0, "latestRewardEpoch", latest, "currentEpoch", cur)
    for name, u in USERS + [("FRESH", FRESH)]:
        st = state[name]
        print(f"{name} last={dec_uint(st['last'])} canClaim={bool(int(st['can'],16))} unclaimed={dec_uarr(st['unclaimed'])}")

    # ---- stage 2: balanceOfEpoch + epochRewardRate for each user's claim window
    calls = []
    keymap = []
    for name, u in USERS:
        last = dec_uint(state[name]["last"])
        for e in range(last + 1, latest + 1):
            calls.append({"to": MGR, "data": sel("balanceOfEpoch(address,uint256)") + addr(u) + uint(e)})
            keymap.append((name, e, None))
            for i, t in enumerate(tokens):
                calls.append({"to": MGR, "data": sel("epochRewardRate(uint256,address)") + uint(e) + addr(t)})
                keymap.append((name, e, i))
    # fresh: sample epochs only (unclaimed already 0; this shows past-epoch balances are 0)
    for e in FRESH_SAMPLE:
        calls.append({"to": MGR, "data": sel("balanceOfEpoch(address,uint256)") + addr(FRESH) + uint(e)})
        keymap.append(("FRESH", e, None))
    res = batch_eth_call(calls)
    data = {}
    for (name, e, i), r in zip(keymap, res):
        if isinstance(r, dict):
            continue
        if i is None:
            data[(name, e, "bal")] = dec_uint(r)
        else:
            data[(name, e, i)] = dec_uint(r)

    out = {"meta": {"block_start": blk0, "block_end": int(rpc("eth_blockNumber", []), 16),
                    "latestRewardEpoch": latest, "currentEpoch": cur,
                    "tokens": tokens, "decimals": decimals, "symbols": syms},
           "users": {}, "fresh_sample": {}}
    for name, u in USERS:
        last = dec_uint(state[name]["last"])
        unclaimed = dec_uarr(state[name]["unclaimed"])
        num = [0] * len(tokens)
        calcA = [0] * len(tokens)
        epochs = {}
        for e in range(last + 1, latest + 1):
            b = data.get((name, e, "bal"), 0)
            epochs[e] = {"bal": b}
            if b == 0:
                continue
            for i in range(len(tokens)):
                r = data.get((name, e, i), 0)
                calcA[i] += b * r // 10 ** 18 // scale[i]
                num[i] += b * r
        calcC = [num[i] // (10 ** 18 * scale[i]) for i in range(len(tokens))]
        row = {"addr": u, "lastClaim": last, "canClaim": bool(int(state[name]["can"], 16)),
               "unclaimed": unclaimed, "calcA_per_epoch_trunc": calcA, "calcC_exact_then_floor": calcC,
               "matchA": calcA == unclaimed, "matchC": calcC == unclaimed, "epochs": epochs}
        out["users"][name] = row
        verdict = "MATCH" if row["matchA"] else "MISMATCH"
        print(f"{name}: {verdict}  unclaimed={unclaimed}")
        print(f"    calcA={calcA}")
        if not row["matchA"]:
            print(f"    calcC={calcC}")
    out["fresh_sample"] = {str(e): data.get(("FRESH", e, "bal"), 0) for e in FRESH_SAMPLE}
    print("fresh balanceOfEpoch samples:", out["fresh_sample"])
    json.dump(out, open("identity.json", "w"), indent=1)
    print("saved identity.json")

if __name__ == "__main__":
    main()
