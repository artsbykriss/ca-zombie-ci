#!/usr/bin/env python3
"""READ-ONLY: when did the pool last touch a drifted validator stake account,
and what does the drift look like across all 110 accounts?"""
import json, sys, base64, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from rpc import rpc, b58enc, b58dec  # noqa
from verify_records_vs_chain import parse_stake, STAKE_PROG, WITHDRAW_AUTH  # noqa
import decode_vlist_v210 as vl  # noqa

POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"


def main():
    data = vl.load(str(HERE.parent / "raw_vlist.b64"))
    n = int.from_bytes(data[5:9], "little")
    recs = []
    for i in range(n):
        o = 9 + i * 73
        act, tr, lue, tss, unused, vss, st = __import__("struct").unpack_from("<QQQQIIB", data, o)
        vote = b58enc(data[o + 41:o + 73])
        recs.append(dict(i=i, vote=vote, active=act, transient=tr, last=lue))
    import pda
    pool_b = pda.b58d(POOL); prog_b = pda.b58d("SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy")
    addrs = []
    for r in recs:
        pk, _ = pda.find_program_address([pda.b58d(r["vote"]), pool_b], prog_b)
        addrs.append(b58enc(pk))
    info = {}
    for s in range(0, len(addrs), 55):
        for a, v in zip(addrs[s:s + 55], rpc("getMultipleAccounts", [addrs[s:s + 55], {"encoding": "base64", "commitment": "confirmed"}])["value"]):
            info[a] = v
    epi = rpc("getEpochInfo", [{"commitment": "confirmed"}])
    print(f"epoch={epi['epoch']} slotIndex={epi['slotIndex']} absoluteSlot={epi['absoluteSlot']}")
    print(f"{'i':>3} {'deleg_stake':>18} {'excess=acct-rent-deleg':>22} {'dl=acct-rec':>14} {'dl/deleg':>12} {'excess/deleg':>13}")
    rows = []
    for r, a in zip(recs, addrs):
        v = info[a]
        ps = parse_stake(base64.b64decode(v["data"][0]))
        deleg = ps.get("deleg_stake", 0)
        rent = ps.get("rent_exempt_reserve", 0)
        excess = v["lamports"] - rent - deleg
        dl = v["lamports"] - r["active"]
        rows.append((r["i"], deleg, excess, dl))
        print(f"{r['i']:>3} {deleg:>18} {excess:>22} {dl:>14} "
              f"{(dl/deleg if deleg else 0):>12.3e} {(excess/deleg if deleg else 0):>13.3e}")
    tl = sum(x[3] for x in rows); td = sum(x[1] for x in rows); te = sum(x[2] for x in rows)
    print(f"\nsum dl={tl}  sum excess={te}  sum deleg={td}")
    print(f"dl/deleg = {tl/td:.6e}   excess/deleg = {te/td:.6e}")
    # the dust account
    print("\ndust accounts (dl==0 or tiny deleg):")
    for r in rows:
        if r[1] < 10**9:
            print("  ", r)

    # recent activity on the most-drifted account + the pool
    worst = max(rows, key=lambda x: x[3])
    wa = addrs[worst[0]]
    print(f"\nworst-drift account idx={worst[0]} {wa} dl={worst[3]}")
    for name, addr in [("worst-drift stake acct", wa), ("pool", POOL)]:
        sigs = rpc("getSignaturesForAddress", [addr, {"limit": 12, "commitment": "confirmed"}])
        print(f"--- last {len(sigs)} sigs for {name} ({addr})")
        for s in sigs:
            t = rpc("getBlockTime", [s["slot"]])
            print(f"    slot={s['slot']} bt={t} err={s.get('err')} sig={s['signature'][:20]}...")
    # EpochRewards sysvar now
    er = rpc("getAccountInfo", ["SysvarEpochRewards1111111111111111111111111",
                                {"encoding": "base64", "commitment": "confirmed"}])
    if er and er.get("value"):
        d = base64.b64decode(er["value"]["data"][0])
        print(f"\nEpochRewards sysvar len={len(d)} hex={d.hex()}")
        # layout: u64 distribution_starting_block_height, u64 num_partitions,
        #         [u8;32] parent_blockhash, u128 total_points, u64 total_rewards,
        #         u64 distributed_rewards, bool active
        o = 0
        print("  distribution_starting_block_height =", int.from_bytes(d[0:8], "little")); o = 8
        print("  num_partitions =", int.from_bytes(d[8:16], "little"))
        print("  total_points =", int.from_bytes(d[48:64], "little"))
        print("  total_rewards =", int.from_bytes(d[64:72], "little"))
        print("  distributed_rewards =", int.from_bytes(d[72:80], "little"))
        print("  active =", bool(d[80]))


if __name__ == "__main__":
    main()
