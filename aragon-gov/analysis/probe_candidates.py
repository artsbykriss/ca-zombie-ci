#!/usr/bin/env python3
"""Targeted on-chain reads for the key Aragon candidates. Keyless public RPC only."""
import json, os, sys, urllib.request

RPCS = ["https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"]
_extra = os.environ.get("RPC_URL")
if _extra and _extra.startswith("http") and "flashbots" not in _extra:
    RPCS.insert(0, _extra)


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for _ in range(3):
        for u in RPCS:
            try:
                req = urllib.request.Request(u, data=body,
                                             headers={"content-type": "application/json", "User-Agent": "ag/1"})
                r = json.load(urllib.request.urlopen(req, timeout=20))
                if "result" in r:
                    return r["result"]
            except Exception:
                continue
    return None


from Crypto.Hash import keccak
def kh(b):
    h = keccak.new(digest_bits=256); h.update(b); return h.hexdigest()
def nh(name):
    node = b"\x00" * 32
    for label in reversed(name.split(".")):
        node = bytes.fromhex(kh(node + bytes.fromhex(kh(label.encode()))))
    return node.hex()
S = lambda sig: "0x" + kh(sig.encode())[:8]
PAD = lambda a: a.lower().replace("0x", "").rjust(64, "0")
def call(to, data): return rpc("eth_call", [{"to": to, "data": data}, "latest"])
def dec(x): return int(x, 16) if isinstance(x, str) and x != "0x" else None
def addr(x): return "0x" + x[-40:] if isinstance(x, str) and len(x) >= 42 and x != "0x" else None
def sstr(x):
    if not isinstance(x, str) or x == "0x":
        return None
    try:
        b = bytes.fromhex(x[2:])
        n = int.from_bytes(b[32:64], "big")
        return b[64:64+n].decode("utf-8", "replace")
    except Exception:
        return None

TM_ID = nh("token-manager.aragonpm.eth")
RM = {nh("voting.aragonpm.eth"): "voting", nh("vault.aragonpm.eth"): "vault",
      nh("agent.aragonpm.eth"): "agent", nh("acl.aragonpm.eth"): "acl", TM_ID: "token-manager"}
TR = kh(b"TRANSFER_ROLE")
CV = kh(b"CREATE_VOTES_ROLE")
ANY = "ff" * 20
HP = S("hasPermission(address,address,bytes32,bytes)")

apps = json.load(open(os.path.join(os.path.dirname(__file__), "aragon_apps.json")))


def has_perm(acl, who, where, what):
    return dec(call(acl, HP + PAD(who) + PAD(where) + what + PAD("80") + PAD("0")))


def probe(dao):
    dao = dao.lower()
    m = apps.get(dao, {})
    named = {RM[k]: v for k, v in m.items() if k in RM}
    voting = named.get("voting")
    hold = named.get("agent") or named.get("vault")
    acl = addr(call(dao, S("acl()")))
    out = {"dao": dao, "apps": named, "voting": voting, "holding": hold, "acl": acl}
    if acl and hold:
        out["transfer_mgr"] = addr(call(acl, S("getPermissionManager(address,bytes32)") + PAD(hold) + TR))
        out["voting_has_transfer"] = has_perm(acl, voting, hold, TR) if voting else None
        out["any_has_transfer"] = has_perm(acl, ANY, hold, TR)
        out["cv_manager"] = addr(call(acl, S("getPermissionManager(address,bytes32)") + PAD(voting) + CV)) if voting else None
        out["any_has_create"] = has_perm(acl, ANY, voting, CV) if voting else None
        if voting:
            out["voting_has_create"] = has_perm(acl, voting, voting, CV)
        if named.get("token-manager"):
            out["tm_has_create"] = has_perm(acl, named["token-manager"], voting, CV)
    if voting:
        out["voteTime"] = dec(call(voting, S("voteTime()")))
        out["support"] = dec(call(voting, S("supportRequiredPct()")))
        out["minAQ"] = dec(call(voting, S("minAcceptQuorumPct()")))
        tok = addr(call(voting, S("token()")))
        out["token"] = tok
        if tok:
            out["tok_symbol"] = sstr(call(tok, S("symbol()")))
            out["tok_name"] = sstr(call(tok, S("name()")))
            out["tok_totalSupply"] = dec(call(tok, S("totalSupply()")))
            out["tok_decimals"] = dec(call(tok, S("decimals()")))
            out["tok_controller"] = addr(call(tok, S("controller()")))
    if hold:
        out["vault_eth"] = dec(rpc("eth_getBalance", [hold, "latest"]))
    return out


if __name__ == "__main__":
    targets = sys.argv[1:] or [
        "0x23b5db33e824822e8d98698c4929be2ff1ba70e4",  # pass7 fork-proof DAO (2.9 ETH)
        "0x3173b1691de5be1cb4be98ae895a8e5182c79b5a",  # ANY-open + 0.70 ETH
        "0x2de83b50af29678774d5abc4a7cb2a588762f28c",  # ANT, minAQ=0, 2.20 ETH
        "0xf6b32eee531a651dca4ac81ba9aed06cca2495c0",  # minAQ=0 + TokenManager, 1.71 ETH
        "0xa323b631f3fee1471c8d520ae48dae907ffe6ff0",  # minAQ=0 + TokenManager, 0.30 ETH
    ]
    out = []
    for t in targets:
        r = probe(t)
        out.append(r)
        print(json.dumps(r, indent=1))
    json.dump(out, open(os.path.join(os.path.dirname(__file__), "probe_candidates.json"), "w"), indent=1)
