#!/usr/bin/env python3
"""ZH4-01 HAI live-state verifier. Read-only eth_call/eth_getLogs. No secrets stored."""
import json, os, sys, time, urllib.request

RPC = os.environ.get("OP_RPC_URL") or "https://mainnet.optimism.io"
PUBLIC = "https://mainnet.optimism.io"

GOV = "0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777"
TL = "0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899"
SAFE = "0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724"
KITE = "0xf467c7d5a4a9c4687ffc7986ac6ad5a4c81e1404"
HAI = "0x10398abc267496e49106b07dd6be13364d10dc71"
STAKING = "0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90"
OP = "0x4200000000000000000000000000000000000042"
WETH = "0x4200000000000000000000000000000000000006"
VELO = "0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db"
TARGET = "0x1472934131f7af94f3cf2542b6121a44d236cf39"
DEFENDERS = [
    "0xCAFd432b7EcAfff352D92fcB81c60380d437E99D",
    "0xE02e8AFcE6BFE464edA586E3a54ba9901FF2C81d",
    "0xBad58e133138549936D2576ebC33251bE841d3e9",
    "0x35d067D337Dd3F7E2BBb4367bed467DCfae1E1fb",
]

HARDENING = 103806721447535921384462690981123294371878165558661022162562047341447243780649
DESC_HASH = "0xd110f9c013e1374b0e1a455bf856f1c02080cc9a1f4b94031935686650d3b8f2"
OP_ID = "0x52aa3307449685539d09e8b83eea5982b2962b02f23d50b0cd3ef2cb129150e6"
SINCE_BLOCK = 158262010
PAYLOAD = open("ci/payload.txt").read().strip()
HARNESS = open("ci/harness_code.txt").read().strip()

# selectors
S = {
    "votingDelay": "0x3932abb1", "votingPeriod": "0x02a251a3", "proposalThreshold": "0xb58131b0",
    "quorumNumerator": "0xa7713a70", "timelock": "0xd33219b4", "token": "0xfc0c546a",
    "quorum": "0xf8ce560a", "state": "0x3e4f49e6", "proposalEta": "0xab58fb8e",
    "proposalVotes": "0x544ffc9c", "getVotes": "0xeb9019d4", "getMinDelay": "0xf27a0c92",
    "isOperationReady": "0x13bc9f20", "isOperationDone": "0x2ab0f529", "getTimestamp": "0xd45c4435",
    "getOwners": "0xa0e67e2b", "getThreshold": "0xe75235b8", "nonce": "0xaffed0e0",
    "balanceOf": "0x70a08231", "totalSupply": "0x18160ddd", "delegates": "0x587cde1e",
    "auth": "0x2e391876", "authAddr": "0x24ba5884",
}
RUN_PAYLOAD = "0xe072ce0e"
RUN_HARDENING = "0x67f3cfe5"

def eu(x): return hex(x)[2:].rjust(64, "0")
def ea(a): return a.lower().replace("0x", "").rjust(64, "0")

def post(url, body, timeout=60):
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=timeout))

def rpc(method, params, url=None):
    last = None
    for i in range(3):
        try:
            r = post(url or RPC, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "error" in r:
                raise RuntimeError(str(r["error"])[:300])
            return r["result"]
        except Exception as e:
            last = e
            time.sleep(1.5 * (i + 1))
    raise last

def call(to, data, tag="latest", url=None):
    return rpc("eth_call", [{"to": to, "data": data}, tag], url=url)

def call_override(to, data, override, url=None):
    try:
        return rpc("eth_call", [{"from": "0x0000000000000000000000000000000000001234", "to": to, "data": data},
                                "latest", override], url=url)
    except Exception:
        return rpc("eth_call", [{"from": "0x0000000000000000000000000000000000001234", "to": to, "data": data},
                                "latest", override], url=PUBLIC)

def u(h):
    return int(h, 16) if h and h != "0x" else None

def arr_bytes(items):
    n = len(items); heads = []; tails = ""
    base = n * 32
    for it in items:
        b = bytes.fromhex(it.replace("0x", "")); pad = (32 - len(b) % 32) % 32
        heads.append(eu(base + len(tails) // 2))
        tails += eu(len(b)) + b.hex() + "00" * pad
    return eu(n) + "".join(heads) + tails

def arr_static(vals):
    return eu(len(vals)) + "".join(eu(v) for v in vals)

def hardening_calldata():
    targets = [GOV, GOV, GOV]
    values = [0, 0, 0]
    calls = [
        "0xe540d01d0000000000000000000000000000000000000000000000000000000000069780",
        "0x06f3f9e60000000000000000000000000000000000000000000000000000000000000005",
        "0xece40cc100000000000000000000000000000000000000000000043c33c1937564800000",
    ]
    t = arr_static([int(x, 16) for x in targets]); v = arr_static(values); c = arr_bytes(calls)
    head = eu(4 * 32) + eu(4 * 32 + len(t) // 2) + eu(4 * 32 + len(t) // 2 + len(v) // 2) + DESC_HASH[2:]
    return RUN_HARDENING + head + t + v + c

def payload_calldata():
    p = PAYLOAD[2:]
    pad = (32 - (len(p) // 2) % 32) % 32
    return RUN_PAYLOAD + eu(32) + eu(len(p) // 2) + p + "00" * pad

def main():
    out = {"finding": "ZH4-01", "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    bn = int(rpc("eth_blockNumber", []), 16)
    blk = rpc("eth_getBlockByNumber", [hex(bn), False])
    ts = int(blk["timestamp"], 16)
    out.update(block=bn, timestamp=ts, iso=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(ts)))
    tp = ts - 1

    g = {}
    g["votingDelay"] = u(call(GOV, S["votingDelay"]))
    g["votingPeriod"] = u(call(GOV, S["votingPeriod"]))
    g["proposalThreshold"] = u(call(GOV, S["proposalThreshold"]))
    g["quorumNumerator"] = u(call(GOV, S["quorumNumerator"]))
    g["quorum_now"] = u(call(GOV, S["quorum"] + eu(tp)))
    g["timelock"] = "0x" + call(GOV, S["timelock"])[-40:]
    g["token"] = "0x" + call(GOV, S["token"])[-40:]
    g["hardening_state"] = u(call(GOV, S["state"] + eu(HARDENING)))
    g["hardening_eta"] = u(call(GOV, S["proposalEta"] + eu(HARDENING)))
    hv = call(GOV, S["proposalVotes"] + eu(HARDENING))
    g["hardening_votes"] = [u(hv[2 + i * 64:2 + (i + 1) * 64]) for i in range(3)] if hv != "0x" else None
    g["defender_votes"] = [u(call(GOV, S["getVotes"] + ea(a) + eu(tp))) for a in DEFENDERS]
    out["governor"] = g

    t = {}
    t["minDelay"] = u(call(TL, S["getMinDelay"]))
    t["op_eta"] = u(call(TL, S["getTimestamp"] + OP_ID[2:]))
    t["op_ready"] = u(call(TL, S["isOperationReady"] + OP_ID[2:]))
    t["op_done"] = u(call(TL, S["isOperationDone"] + OP_ID[2:]))
    out["timelock"] = t

    own = call(SAFE, S["getOwners"])
    owners = []
    if own and own != "0x":
        n = int(own[66:130], 16)
        owners = ["0x" + own[130 + i * 64 + 24:130 + (i + 1) * 64] for i in range(n)]
    out["safe"] = {
        "owners": owners,
        "threshold": u(call(SAFE, S["getThreshold"])),
        "nonce": u(call(SAFE, S["nonce"])),
        "kite": u(call(KITE, S["balanceOf"] + ea(SAFE))),
        "op": u(call(OP, S["balanceOf"] + ea(SAFE))),
        "weth": u(call(WETH, S["balanceOf"] + ea(SAFE))),
        "velo": u(call(VELO, S["balanceOf"] + ea(SAFE))),
        "kite_delegatee_before": "0x" + call(KITE, S["delegates"] + ea(SAFE))[-40:],
    }

    tok = {}
    tok["kite_totalSupply"] = u(call(KITE, S["totalSupply"]))
    tok["kite_timelock_authorized"] = u(call(KITE, S["authAddr"] + ea(TL)))
    tok["hai_totalSupply"] = u(call(HAI, S["totalSupply"]))
    tok["hai_timelock_authorized"] = u(call(HAI, S["authAddr"] + ea(TL)))
    tok["staking_kite"] = u(call(KITE, S["balanceOf"] + ea(STAKING)))
    tok["staking_timelock_authorized"] = u(call(STAKING, S["authAddr"] + ea(TL)))
    auth = call(STAKING, S["auth"])
    if auth and auth != "0x":
        n = int(auth[66:130], 16)
        tok["staking_authorized"] = ["0x" + auth[130 + i * 64 + 24:130 + (i + 1) * 64] for i in range(n)]
    out["tokens"] = tok

    # --- fork simulations via eth_call with code override ---
    checks = []
    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})

    # 1) hardening executable now, permissionless
    hard_override = {"0x000000000000000000000000000000000000BEEF": {"code": HARNESS}}
    hard = None
    if g["hardening_state"] == 5:
        try:
            hr = call_override("0x000000000000000000000000000000000000BEEF", hardening_calldata(), hard_override)
            w = [u(hr[2 + i * 64:2 + (i + 1) * 64]) for i in range(5)]
            hard = {"ok": w[0], "quorumNumerator": w[1], "proposalThreshold": w[2],
                    "votingPeriod": w[3], "totalSupply": w[4]}
        except Exception as e:
            hard = {"error": str(e)[:200]}
    out["hardening_execution_sim"] = hard
    if g["hardening_state"] == 5:
        check("hardening_executable_permissionlessly",
              hard.get("ok") == 1 and hard.get("quorumNumerator") == 5
              and hard.get("proposalThreshold") == 20_000 * 10**18
              and hard.get("votingPeriod") == 432_000, str(hard))
    elif g["hardening_state"] == 7:
        check("hardening_already_executed", g["quorumNumerator"] == 5, "state=Executed")
    else:
        check("hardening_state_known", False, str(g["hardening_state"]))

    # 2) treasury payload executes from Timelock -> delegates 296,143.98 KITE
    safe_override = {TL: {"code": HARNESS}}
    sim = None
    try:
        sr = call_override(TL, payload_calldata(), safe_override)
        w = [u(sr[2 + i * 64:2 + (i + 1) * 64]) for i in range(7)]
        sim = {"ok": w[0], "delegatee": "0x" + hex(w[1])[2:].rjust(40, "0")[-40:],
               "safe_kite": w[2], "fed2_kite": w[3], "op_468c": w[4],
               "allowance_staking": w[5], "safe_nonce_after": w[6]}
    except Exception as e:
        sim = {"error": str(e)[:200]}
    out["safe_payload_sim"] = sim
    check("payload_executes_from_timelock",
          sim.get("ok") == 1 and sim.get("delegatee", "").lower() == TARGET.lower()
          and sim.get("safe_kite") == 327_643_981_253_588_267_391_953
          and sim.get("op_468c") == 100 * 10**18
          and sim.get("allowance_staking") == 50_000 * 10**18, str(sim))

    # 3) direct timelock execution by EOA must revert
    eoa = "0x000000000000000000000000000000000000BEEF"
    tb = "0xe38335e5"  # executeBatch(address[],uint256[],bytes[],bytes32,bytes32)
    data = tb + eu(5 * 32) + eu(5 * 32 + 32) + eu(5 * 32 + 64) + eu(0) + eu(0) + eu(0) + eu(0) + eu(0)
    try:
        r = post(RPC, {"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"from": eoa, "to": TL, "data": data}, "latest"]})
        blocked = "error" in r
    except Exception:
        blocked = True
    out["direct_timelock_execution_blocked"] = blocked
    check("direct_timelock_execution_blocked", blocked, "")

    # 4) structural assertions
    check("hardening_operation_ready", t["op_ready"] == 1 and t["op_done"] == 0, str(t))
    check("safe_owned_by_timelock", owners and owners[0].lower() == TL.lower() and out["safe"]["threshold"] == 1, str(owners))
    check("treasury_kite_intact", out["safe"]["kite"] >= 328_000 * 10**18, str(out["safe"]["kite"]))
    check("treasury_not_delegated", out["safe"]["kite_delegatee_before"] == "0x" + "0" * 40, out["safe"]["kite_delegatee_before"])
    check("kite_mint_authority_timelock", tok["kite_timelock_authorized"] == 1, "")
    check("hai_mint_authority_timelock", tok["hai_timelock_authorized"] == 1, "")
    check("staking_manager_authorized_timelock", tok["staking_timelock_authorized"] == 1, "")
    if g["quorumNumerator"] == 1:
        check("quorum_still_1pct", g["quorum_now"] == 9_739_670_000_000_000_000_000, str(g["quorum_now"]))
        check("threshold_still_5k", g["proposalThreshold"] == 5_000 * 10**18, str(g["proposalThreshold"]))
    check("defense_bloc_present", sum(g["defender_votes"]) >= 70_000 * 10**18, str(sum(g["defender_votes"])))

    # 5) activity since last local dataset
    topics = {
        "ProposalCreated": "0x7d84a6263ae0d98d3329bd7b46bb4e8d6f98cd35a7adb45c274c8b7fd5ebd5e0",
        "VoteCast": "0xb8e138887d0aa13bab447e82de9d5c1777041ecd21ca36ba824ff1e6c07ddda4",
        "ProposalExecuted": "0x712ae1383f79ac853f8d882153778e0260ef8f03b504e2866e0593e04d2b291f",
        "CallExecuted": "0xc2617efa69bab66782fa219543714338489c4e9e178271560a91b82c3f612b58",
    }
    recent = {}
    for name, topic in topics.items():
        addr = TL if name == "CallExecuted" else GOV
        logs = []
        b = SINCE_BLOCK
        while b <= bn:
            e = min(b + 8000 - 1, bn)
            logs += rpc("eth_getLogs", [{"address": addr, "fromBlock": hex(b), "toBlock": hex(e), "topics": [topic]}])
            b = e + 1
        recent[name] = len(logs)
    out["recent_activity"] = recent

    out["checks"] = checks
    out["ok"] = all(c["ok"] for c in checks)
    os.makedirs("ci-out", exist_ok=True)
    json.dump(out, open("ci-out/verify.json", "w"), indent=2)
    print(json.dumps({k: out[k] for k in ("block", "iso", "ok", "recent_activity")}, indent=1))
    for c in checks:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + ("" if c["ok"] else " :: " + c["detail"][:300]))
    if not out["ok"]:
        sys.exit(1)

if __name__ == "__main__":
    main()
