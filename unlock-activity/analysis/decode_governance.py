#!/usr/bin/env python3
"""Decode UnlockProtocolGovernor logs (Base) from gov_logs_raw.json.
Read-only; no network. Outputs proposals.csv / votes.csv / per-proposal JSON.
"""
import json, csv, collections, datetime
from eth_abi import decode as abi_decode

RAW = "gov_logs_raw.json"
GOV = "0x65ba0624403fc5ca2b20479e9f626ed4d78e0ad9"

T_PROPOSAL_CREATED = "0x7d84a6263ae0d98d3329bd7b46bb4e8d6f98cd35a7adb45c274c8b7fd5ebd5e0"
T_VOTE_CAST = "0xb8e138887d0aa13bab447e82de9d5c1777041ecd21ca36ba824ff1e6c07ddda4"
T_QUEUED = "0x9a2e42fd6722813d69113e7d0079d3d940171428df7373df9c7f7617cfda2892"
T_EXECUTED = "0x712ae1383f79ac853f8d882153778e0260ef8f03b504e2866e0593e04d2b291f"
T_CANCELED = "0x789cf55be980739dad1d0699b93b58e806b51c9d96619bfa8fe0a28abaa7b30c"

def load(path=RAW):
    return json.load(open(path))

def main():
    logs = load()
    proposals = {}
    votes = []
    queued = {}
    executed = set()
    canceled = set()

    for l in logs:
        t0 = l["topics"][0]
        bn = int(l["blockNumber"], 16)
        ts = int(l["blockTimestamp"], 16)
        tx = l["transactionHash"]
        if t0 == T_PROPOSAL_CREATED:
            (pid, proposer, targets, values, sigs, calldatas, vote_start, vote_end, desc) = abi_decode(
                ["uint256", "address", "address[]", "uint256[]", "string[]", "bytes[]", "uint256", "uint256", "string"],
                bytes.fromhex(l["data"][2:]),
            )
            proposals[pid] = dict(
                id=pid, block=bn, ts=ts, tx=tx, proposer=proposer,
                targets=targets, values=[str(v) for v in values], signatures=sigs,
                calldatas=[c.hex() for c in calldatas],
                vote_start=vote_start, vote_end=vote_end, description=desc,
            )
        elif t0 == T_VOTE_CAST:
            voter = "0x" + l["topics"][1][-40:]
            (pid, support, weight, reason) = abi_decode(
                ["uint256", "uint8", "uint256", "string"], bytes.fromhex(l["data"][2:])
            )
            votes.append(dict(pid=pid, voter=voter.lower(), support=support,
                              weight=str(weight), reason=reason, block=bn, ts=ts, tx=tx))
        elif t0 == T_QUEUED:
            (pid, eta) = abi_decode(["uint256", "uint256"], bytes.fromhex(l["data"][2:]))
            queued[pid] = dict(block=bn, ts=ts, eta=eta)
        elif t0 == T_EXECUTED:
            (pid,) = abi_decode(["uint256"], bytes.fromhex(l["data"][2:]))
            executed.add(pid)
        elif t0 == T_CANCELED:
            (pid,) = abi_decode(["uint256"], bytes.fromhex(l["data"][2:]))
            canceled.add(pid)

    # aggregates
    agg = collections.defaultdict(lambda: dict(f=0, a=0, ab=0, n=0, voters=set()))
    for v in votes:
        a = agg[v["pid"]]
        w = int(v["weight"])
        if v["support"] == 0: a["a"] += w
        elif v["support"] == 1: a["f"] += w
        else: a["ab"] += w
        a["n"] += 1
        a["voters"].add(v["voter"])

    rows = []
    for pid, p in sorted(proposals.items(), key=lambda kv: kv[1]["block"]):
        a = agg[pid]
        quorum = 3_000_000 * 10**18
        turnout = a["f"] + a["a"] + a["ab"]
        if a["f"] + a["ab"] < quorum:
            outcome = "NO_QUORUM"
        elif pid in executed:
            outcome = "EXECUTED"
        elif a["f"] > a["a"]:
            outcome = "SUCCEEDED" if pid not in canceled else "CANCELED"
        else:
            outcome = "DEFEATED"
        if pid in canceled: outcome = "CANCELED"
        title = p["description"].split("\n")[0][:160]
        rows.append(dict(
            id=str(pid), block=p["block"],
            time=datetime.datetime.utcfromtimestamp(p["ts"]).isoformat() + "Z",
            proposer=p["proposer"], vote_start=p["vote_start"], vote_end=p["vote_end"],
            for_votes=str(a["f"]), against_votes=str(a["a"]), abstain_votes=str(a["ab"]),
            voters=a["n"], turnout=str(turnout), quorum_ok=(a["f"] + a["ab"] >= quorum),
            executed=pid in executed, queued=pid in queued, canceled=pid in canceled,
            outcome=outcome, title=title,
            targets=";".join(p["targets"]), values=";".join(p["values"]),
        ))

    with open("proposals.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)

    with open("votes.csv", "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["pid", "voter", "support", "weight", "block", "ts", "tx"])
        for v in sorted(votes, key=lambda x: (x["pid"], x["block"])):
            w.writerow([v["pid"], v["voter"], v["support"], v["weight"], v["block"], v["ts"], v["tx"]])

    json.dump(dict(proposals=rows, n_proposals=len(rows), n_votes=len(votes)),
              open("governance_decoded.json", "w"), indent=1)

    # quick stats
    turnouts = sorted(int(r["turnout"]) / 1e18 for r in rows)
    import statistics
    print("proposals", len(rows), "votes", len(votes))
    print("turnout min/median/max UP:", turnouts[0], statistics.median(turnouts), turnouts[-1])
    print("below 3M quorum:", sum(1 for t in turnouts if t < 3_000_000))
    print("outcomes:", collections.Counter(r["outcome"] for r in rows))
    print("proposers:", collections.Counter(r["proposer"].lower() for r in rows).most_common(10))
    # deployer / key delegates
    for who in ["0x81dd955d02d337db81ba6c9c5f6213e647672052",
                "0x38b826a4426a0d4d9b4377ac57c9af0308281c5d"]:
        vv = [v for v in votes if v["voter"] == who]
        print(who, "votes cast:", len(vv), "support counts:", collections.Counter(v["support"] for v in vv))

if __name__ == "__main__":
    main()
