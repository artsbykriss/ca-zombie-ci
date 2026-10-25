#!/usr/bin/env python3
"""
Independent re-verification of the ZH4-PASS7 P7-01 claim:

  "On 2,002 of 2,202 funded Aragon DAOs the Voting app is the ACL
   permission-manager for the holding app's TRANSFER_ROLE."

This script re-reads the relationship *from chain* (not from the prior
JSONs) on a deterministic sample, and also reads the vote-creation gate
(CREATE_VOTES_ROLE holders / manager) on the same sample.

RPC: taken from $RPC_URL if set, else a keyless public endpoint.
     NO secrets are embedded here (folder syncs to a public repo).
"""
import json, os, sys, urllib.request, collections
from concurrent.futures import ThreadPoolExecutor

# Keyless public endpoints only (this folder syncs to a PUBLIC repo).
RPCS = ["https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"]
_extra = os.environ.get("RPC_URL")
if _extra and _extra.startswith("http") and "flashbots" not in _extra:
    RPCS.insert(0, _extra)

HERE = os.path.dirname(os.path.abspath(__file__))


def rpc(method, params):
    p = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    body = json.dumps(p).encode()
    for _ in range(3):
        for u in RPCS:
            try:
                req = urllib.request.Request(
                    u, data=body,
                    headers={"content-type": "application/json", "User-Agent": "aragon-gov-verify/1"})
                r = json.load(urllib.request.urlopen(req, timeout=20))
                if "result" in r:
                    return r["result"]
            except Exception:
                continue
    return None


def keccak(s):
    try:
        from Crypto.Hash import keccak as _k
        h = _k.new(digest_bits=256); h.update(s.encode()); return h.hexdigest()
    except Exception:
        import sha3  # fallback
        return sha3.keccak_256(s.encode()).hexdigest()


def namehash(name):
    node = b"\x00" * 32
    for label in reversed(name.split(".")):
        node = bytes.fromhex(keccak_hex(node + bytes.fromhex(keccak_hex(label.encode()) if False else keccak(label))))
    return node.hex()


def keccak_hex(b):
    try:
        from Crypto.Hash import keccak as _k
        h = _k.new(digest_bits=256); h.update(b); return h.hexdigest()
    except Exception:
        import sha3
        return sha3.keccak_256(b).hexdigest()


def nh(name):
    node = b"\x00" * 32
    for label in reversed(name.split(".")):
        node = bytes.fromhex(keccak_hex(node + bytes.fromhex(keccak_hex(label.encode()))))
    return node.hex()


S = lambda sig: "0x" + keccak(sig)[:8]
PAD = lambda a: a.lower().replace("0x", "").rjust(64, "0")
ZERO = "0" * 64
ANY = "ff" * 20
TRANSFER_ROLE = keccak("TRANSFER_ROLE")
CREATE_VOTES_ROLE = keccak("CREATE_VOTES_ROLE")
CREATE_PERMISSIONS_ROLE = keccak("CREATE_PERMISSIONS_ROLE")
HAS_PERM = S("hasPermission(address,address,bytes32,bytes)")


def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])


def addr(x):
    return "0x" + x[-40:] if isinstance(x, str) and x != "0x" and len(x) >= 42 else None


def has_perm(acl, who, where, what):
    d = HAS_PERM + PAD(who) + PAD(where) + what + PAD("80") + PAD("0")
    r = call(acl, d)
    try:
        return int(r, 16)
    except Exception:
        return None


def main():
    apps = json.load(open(os.path.join(HERE, "aragon_apps.json")))
    rows = json.load(open(os.path.join(HERE, "aragon_join.json")))
    params = {p["dao"].lower(): p for p in json.load(open(os.path.join(HERE, "aragon_instant_params.json")))}
    RM = {nh("voting.aragonpm.eth"): "voting", nh("vault.aragonpm.eth"): "vault",
          nh("agent.aragonpm.eth"): "agent", nh("acl.aragonpm.eth"): "acl"}

    # deterministic sample: every 19th funded DAO (~116 rows)
    sample = [r for i, r in enumerate(rows) if i % 19 == 0]
    print(f"sample size = {len(sample)} of {len(rows)} funded DAOs")

    def work(r):
        dao = r["dao"].lower()
        m = apps.get(dao)
        if not m:
            return None
        named = {RM[k]: v for k, v in m.items() if k in RM}
        voting = named.get("voting")
        hold = named.get("agent") or named.get("vault")
        if not (voting and hold):
            return None
        acl = addr(call(dao, S("acl()")))
        if not acl:
            return None
        mgr = addr(call(acl, S("getPermissionManager(address,bytes32)") + PAD(hold) + TRANSFER_ROLE))
        mgr_cv = addr(call(acl, S("getPermissionManager(address,bytes32)") + PAD(voting) + CREATE_VOTES_ROLE))
        any_create = has_perm(acl, ANY, voting, CREATE_VOTES_ROLE)
        voting_create = has_perm(acl, voting, voting, CREATE_VOTES_ROLE)
        return {"dao": dao, "holding_kind": "agent" if "agent" in named else "vault",
                "holding": hold, "voting": voting, "acl": acl, "eth": r["eth"],
                "minAQ": r["minAQ"], "isMgr": (mgr == voting), "transfer_mgr": mgr,
                "create_votes_mgr": mgr_cv, "anyCanCreate": any_create,
                "votingCanCreate": voting_create}

    with ThreadPoolExecutor(max_workers=16) as ex:
        out = [x for x in ex.map(work, sample) if x]

    n = len(out)
    k = sum(1 for x in out if x["isMgr"])
    tot = sum(x["eth"] for x in out if x["isMgr"])
    print(f"re-read {n} DAOs; Voting is TRANSFER_ROLE manager on {k} ({100*k/n:.1f}%)")
    print(f"ETH in those holding apps (sample): {tot/1e18:.3f}")
    print("vote-creation gate on sample:")
    print("  anyCanCreate==1 :", sum(1 for x in out if x["anyCanCreate"] == 1))
    print("  votingCanCreate==1:", sum(1 for x in out if x["votingCanCreate"] == 1))
    cvm = collections.Counter(x["create_votes_mgr"] for x in out)
    print("  CREATE_VOTES_ROLE manager distribution:", dict(cvm))
    # the interesting set: manager AND creatable
    creat = [x for x in out if x["isMgr"] and (x["anyCanCreate"] == 1)]
    print(f"  manager AND ANY-open newVote: {len(creat)}")
    for x in sorted(out, key=lambda y: -y["eth"])[:12]:
        print(f"   {x['dao']} eth={x['eth']/1e18:.4f} minAQ={x['minAQ']} isMgr={x['isMgr']} "
              f"anyCreate={x['anyCanCreate']} cvMgr={x['create_votes_mgr']}")
    json.dump(out, open(os.path.join(HERE, "verify_manager_sample.json"), "w"), indent=1)
    print("wrote verify_manager_sample.json")


if __name__ == "__main__":
    main()
