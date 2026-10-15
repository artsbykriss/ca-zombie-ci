#!/usr/bin/env python3
"""READ-ONLY verification: does every ValidatorList record match its real
stake account?  (record.active_stake_lamports == account.lamports, owner ==
stake program, authorized staker/withdrawer == pool withdraw authority)

No transactions are built or sent.  Public keyless RPC only.
"""
import json, sys, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
from rpc import rpc, b58dec, b58enc  # noqa

STAKE_PROG = "Stake11111111111111111111111111111111111111"
WITHDRAW_AUTH = "AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn"
LOCKUP_DEFAULT = b"\x00" * 48


def parse_stake(data: bytes):
    if len(data) < 197:
        return {"state": "short", "len": len(data)}
    tag = int.from_bytes(data[0:4], "little")
    names = {0: "Uninitialized", 1: "Initialized", 2: "Stake", 3: "RewardsPool"}
    st = names.get(tag, f"?{tag}")
    out = {"state": st}
    if tag in (1, 2):
        o = 4
        out["rent_exempt_reserve"] = int.from_bytes(data[o:o + 8], "little"); o += 8
        out["staker"] = b58enc(data[o:o + 32]); o += 32
        out["withdrawer"] = b58enc(data[o:o + 32]); o += 32
        ts = int.from_bytes(data[o:o + 8], "little", signed=True); o += 8
        ep = int.from_bytes(data[o:o + 8], "little"); o += 8
        cust = b58enc(data[o:o + 32]); o += 32
        out["lockup"] = [ts, ep, cust]
    if tag == 2:
        out["voter"] = b58enc(data[o:o + 32]); o += 32
        out["deleg_stake"] = int.from_bytes(data[o:o + 8], "little"); o += 8
        out["activation_epoch"] = int.from_bytes(data[o:o + 8], "little"); o += 8
        out["deactivation_epoch"] = int.from_bytes(data[o:o + 8], "little"); o += 8
        o += 8  # warmup_cooldown_rate f64
        out["credits_observed"] = int.from_bytes(data[o:o + 8], "little"); o += 8
    return out


def main():
    recs = json.loads((HERE / "derived_validator_stakes.json").read_text())
    addrs = [r["validator_stake"] for r in recs]
    info = {}
    for s in range(0, len(addrs), 50):
        chunk = addrs[s:s + 50]
        res = rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "confirmed"}])
        assert res and "value" in res, res
        for a, v in zip(chunk, res["value"]):
            info[a] = v
    bad = []
    print(f"{'idx':>3} {'lamports':>18} {'record':>18} {'ok':>4}  owner/state/withdrawer")
    total = 0
    for r in recs:
        v = info.get(r["validator_stake"])
        if v is None:
            bad.append((r["i"], "MISSING ACCOUNT")); print(f"{r['i']:>3}  MISSING"); continue
        lam = v["lamports"]; total += lam
        ps = parse_stake(__import__("base64").b64decode(v["data"][0]))
        ok_lam = lam == r["active"]
        ok_owner = v["owner"] == STAKE_PROG
        ok_auth = ps.get("withdrawer") == WITHDRAW_AUTH and ps.get("staker") == WITHDRAW_AUTH
        ok_voter = ps.get("voter") == r["vote"]
        ok = ok_lam and ok_owner and ok_auth and ok_voter
        if not ok:
            bad.append((r["i"], dict(dl=lam - r["active"], owner=v["owner"], ps=ps)))
        print(f"{r['i']:>3} {lam:>18} {r['active']:>18} {str(ok):>5}  "
              f"{v['owner'][:6]}/{ps['state']}/{str(ps.get('withdrawer'))[:8]}"
              f" lam={ok_lam} own={ok_owner} auth={ok_auth} voter={ok_voter}")
    print(f"\nsum of ALL validator stake account lamports = {total} ({total/1e9:.6f} SOL)")
    print(f"sum of records                            = {sum(r['active'] for r in recs)}")
    print(f"\nMISMATCHES: {len(bad)}")
    for b in bad[:20]:
        print(" ", b)
    (HERE / "vlist_onsite_verify.json").write_text(json.dumps(
        {"mismatches": [str(b) for b in bad], "total_lamports": total}, indent=1))


if __name__ == "__main__":
    main()
