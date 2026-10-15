#!/usr/bin/env python3
"""Strict decoder for the spoo1 ValidatorList account (v2.1.0).

Layout (from state.rs @54cdceda + big_vec.rs):
  offset 0 : u8  account_type (2 = ValidatorList)
  offset 1 : u32 max_validators
  offset 5 : u32 vec_len                <- BigVec::len()  (VEC_SIZE_BYTES = 4)
  offset 9 : 73-byte ValidatorStakeInfo records
ValidatorStakeInfo (Pod, 73 bytes):
  +0  PodU64 active_stake_lamports
  +8  PodU64 transient_stake_lamports
  +16 PodU64 last_update_epoch
  +24 PodU64 transient_seed_suffix
  +32 PodU32 unused
  +36 PodU32 validator_seed_suffix   (0 == None)
  +40 u8    status (0=Active,1=DeactivatingTransient,2=ReadyForRemoval,3=DeactivatingValidator,4=DeactivatingAll)
  +41 [u8;32] vote_account_address
"""
import base64, json, struct, sys, pathlib

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from pda import find_program_address, b58e, is_on_curve  # noqa

POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"
PROG = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"
REC = 73
STATUS = {0: "Active", 1: "DeactivatingTransient", 2: "ReadyForRemoval",
          3: "DeactivatingValidator", 4: "DeactivatingAll"}


def load(path):
    raw = pathlib.Path(path).read_text().strip()
    try:
        return base64.b64decode(raw, validate=True)
    except Exception:
        j = json.loads(raw)
        return base64.b64decode(j["result"]["value"]["data"][0])


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else str(HERE.parent / "raw_vlist.b64")
    data = load(src)
    acct_type = data[0]
    maxv = struct.unpack_from("<I", data, 1)[0]
    n = struct.unpack_from("<I", data, 5)[0]
    print(f"account_type={acct_type} max_validators={maxv} vec_len={n} "
          f"space={len(data)} bytes_fit={9 + n * REC}")
    assert acct_type == 2, "not a ValidatorList"
    assert 9 + n * REC <= len(data), "vec_len exceeds account space"

    pool = __import__("pda").b58d(POOL)
    prog = __import__("pda").b58d(PROG)
    recs = []
    for i in range(n):
        o = 9 + i * REC
        act, tr, lue, tss, unused, vss, st = struct.unpack_from("<QQQQIIB", data, o)
        vote = b58e(data[o + 41:o + 73])
        recs.append(dict(i=i, vote=vote, active=act, transient=tr, last_update=lue,
                         transient_seed=tss, validator_seed=vss, status=STATUS.get(st, f"BAD({st})")))
    return recs, maxv, n, data


if __name__ == "__main__":
    recs, maxv, n, data = main()
    print(f"\n{'idx':>3} {'status':>22} {'active_lamports':>20} {'transient':>20} "
          f"{'last_upd':>9} {'vseed':>11} {'tseed':>22}  vote")
    tot = tt = 0
    for r in recs:
        tot += r["active"]; tt += r["transient"]
        print(f"{r['i']:>3} {r['status']:>22} {r['active']:>20} {r['transient']:>20} "
              f"{r['last_update']:>9} {r['validator_seed']:>11} {r['transient_seed']:>22}  {r['vote']}")
    print(f"\nsum active    = {tot} ({tot/1e9:.3f} SOL)")
    print(f"sum transient = {tt} ({tt/1e9:.3f} SOL)")
    votes = [r["vote"] for r in recs]
    dupes = {v for v in votes if votes.count(v) > 1}
    print("duplicate vote entries:", dupes or "none")
    nz = [r for r in recs if r["validator_seed"] != 0]
    print("#records with non-zero validator_seed_suffix:", len(nz), [r["i"] for r in nz][:20])
    tss = [r for r in recs if r["transient"] != 0]
    print("#records with transient lamports != 0:", len(tss), [(r['i'], r['transient'], r['status']) for r in tss][:20])
    stale = [r for r in recs if r["last_update"] != 1058]
    print("#records with last_update != 1058 (pool says epoch 1058):", len(stale), [r['i'] for r in stale][:20])
    # derive PDAs and test existence via records
    import pda as _pda
    pool = _pda.b58d(POOL)
    prog = _pda.b58d(PROG)
    out = []
    for r in recs:
        v = _pda.b58d(r["vote"])
        seed = r["validator_seed"]
        seeds = [v, pool] + ([struct.pack("<I", seed)] if seed else [])
        pk, bump = find_program_address(seeds, prog)
        out.append(dict(i=r["i"], vote=r["vote"], validator_stake=b58e(pk),
                        seed=None if seed == 0 else seed, active=r["active"], status=r["status"]))
    pathlib.Path(HERE / "derived_validator_stakes.json").write_text(json.dumps(out, indent=1))
    print("\nwrote derived_validator_stakes.json")
