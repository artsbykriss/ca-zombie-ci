#!/usr/bin/env python3
"""childA on-chain scan: enumerate 62 Nuri gauges -> feeDistributors -> balances.
Read-only. Public Scroll RPC only. No secrets. Saves childA-raw.json.
"""
import json, urllib.request, sys, time

RPC = "https://rpc.scroll.io"
UA = "Mozilla/5.0"
OUT = "/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"

VOTER = "0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869"
FEE_COLLECTOR = "0xAAA2A49958a443Dc9d19FdDEe873B5D1d6e84A2f"
FD_FACTORY = "0xAAA1c31Cc1d1C2da7e634130DeD0ea2043271744"
COMMAND_CENTER = "0xAAA11500dDdB2B67a90d1a154dfB7eaBB518EAE6"
TOKENS = {
    "WETH": "0x5300000000000000000000000000000000000004",
    "USDC": "0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4",
    "USDT": "0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df",
    "NURI": "0xAAAE8378809bb8815c08D3C59Eb0c7D1529aD769",
}

# selectors
S = {
    "gauges": "0xb9a09fd5",
    "feeDistributors": "0x49e4974a",
    "isAlive": "0x1703e5f9",
    "balanceOf": "0x70a08231",
    "getRewardTokens": "0xc4f59f9b",
    "firstPeriod": "0xc4e3a63b",
    "voter": "0x46c96aac",
    "pairFees": "0x4eceb5ff",
    "votes": "0x5df81330",
    "rewardSupply": "0x8bb28cb5",
    "getPeriod": "0x1ed24195",
    "owner": "0x8da5cb5b",
    "implementation": "0x5c60da1b",
    "lastFeeDistributor": "0x5d52996a",
    "treasury": "0x61d027b3",
    "treasuryFees": "0x9a67430f",
    "isTokenLive": "0x2a8d07b3",
    "getRoleMemberCount": "0xca15c873",
    "getRoleMember": "0x9010d07c",
}
ROLES = {
    "DEFAULT_ADMIN_ROLE": "0x" + "00" * 32,
    "OPERATOR_ROLE": None,
    "FEE_SETTER_ROLE": None,
}


def keccak_hex(s):
    # use cast for keccak to avoid deps
    import subprocess
    return subprocess.check_output(["cast", "keccak", s]).decode().strip()


def pad(addr_or_int):
    if isinstance(addr_or_int, str) and addr_or_int.startswith("0x") and len(addr_or_int) == 42:
        return addr_or_int[2:].lower().rjust(64, "0")
    if isinstance(addr_or_int, str) and addr_or_int.startswith("0x") and len(addr_or_int) == 66:
        return addr_or_int[2:].lower()
    return hex(int(addr_or_int))[2:].rjust(64, "0")


_id = [0]
def enc(sel, args):
    _id[0] += 1
    return {"jsonrpc": "2.0", "id": _id[0], "method": "eth_call",
            "params": [{"to": None, "data": sel + "".join(pad(a) for a in args)}, "latest"]}


def enc_to(to, sel, args, tag="latest"):
    c = enc(sel, args)
    c["params"][0]["to"] = to
    c["params"][1] = tag
    return c


def rpc_batch(calls, block=None):
    CHUNK = 5
    res = {}
    for i in range(0, len(calls), CHUNK):
        chunk = calls[i:i + CHUNK]
        for c in chunk:
            if block:
                c["params"][1] = hex(block)
        body = json.dumps(chunk).encode()
        req = urllib.request.Request(RPC, data=body, headers={"User-Agent": UA, "Content-Type": "application/json"})
        out = None
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    out = json.loads(r.read().decode())
                break
            except Exception as e:
                if attempt == 3:
                    raise
                time.sleep(2 * (attempt + 1))
        by_id = {x["id"]: x for x in out}
        for c in chunk:
            x = by_id.get(c["id"], {})
            res[c["id"]] = x.get("result") if "result" in x else {"error": x.get("error")}
    return res


def get_uint(resmap, cid):
    r = resmap[cid]
    if isinstance(r, dict):
        return None
    return int(r, 16) if r and r != "0x" else 0


def get_addr(resmap, cid):
    r = resmap[cid]
    if isinstance(r, dict):
        return None
    return "0x" + r[-40:]


def main():
    gauges = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/gauges.json"))
    # latest block + timestamp
    lb = json.loads(urllib.request.urlopen(urllib.request.Request(
        RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
        headers={"User-Agent": UA, "Content-Type": "application/json"})).read().decode())
    block = int(lb["result"], 16)
    blk = json.loads(urllib.request.urlopen(urllib.request.Request(
        RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_getBlockByNumber", "params": [hex(block), False]}).encode(),
        headers={"User-Agent": UA, "Content-Type": "application/json"})).read().decode())
    ts = int(blk["result"]["timestamp"], 16)
    WEEK = 604800
    period = (ts // WEEK) * WEEK
    print("block", block, "ts", ts, "period", period, file=sys.stderr)

    data = {"block": block, "timestamp": ts, "period": period, "gauges": [], "fds": {}, "misc": {}}

    # Phase 1: per gauge, verify mapping + get fd
    calls = []
    idx = {}
    for i, g in enumerate(gauges):
        for name in ("gauges", "isAlive", "feeDistributors"):
            to = VOTER
            arg = g["pool"] if name == "gauges" else g["gauge"]
            c = enc_to(to, S[name], [arg], hex(block))
            calls.append(c)
            idx[c["id"]] = (i, name)
    res = rpc_batch(calls)
    for i, g in enumerate(gauges):
        g["gauges_chain"] = None
        g["isAlive_chain"] = None
        g["feeDistributor"] = None
    for cid, (i, name) in idx.items():
        if name == "gauges":
            gauges[i]["gauges_chain"] = get_addr(res, cid)
        elif name == "isAlive":
            gauges[i]["isAlive_chain"] = get_uint(res, cid)
        else:
            gauges[i]["feeDistributor"] = get_addr(res, cid)

    # Phase 2: per unique FD -> balances, reward tokens, voter, pairFees, firstPeriod
    fds = sorted({g["feeDistributor"] for g in gauges if g["feeDistributor"]})
    print("unique FDs:", len(fds), file=sys.stderr)
    calls = []
    idx = {}
    for fd in fds:
        for name in ("balanceOf", "getRewardTokens", "firstPeriod", "voter", "pairFees"):
            if name == "balanceOf":
                for tn, ta in TOKENS.items():
                    c = enc_to(fd, S["balanceOf"], [ta], hex(block))
                    calls.append(c)
                    idx[c["id"]] = (fd, name, tn)
            else:
                c = enc_to(fd, S[name], [], hex(block))
                calls.append(c)
                idx[c["id"]] = (fd, name, None)
    res = rpc_batch(calls)
    fdm = {fd: {"balances": {}, "getRewardTokens": None, "firstPeriod": None, "voter": None, "pairFees": None} for fd in fds}
    for cid, (fd, name, tn) in idx.items():
        if name == "balanceOf":
            fdm[fd]["balances"][tn] = get_uint(res, cid)
        elif name == "getRewardTokens":
            r = res[cid]
            if not isinstance(r, dict):
                raw = r[2:]
                n = int(raw[64:128], 16) if len(raw) >= 128 else 0
                toks = ["0x" + raw[128 + 64 * k: 128 + 64 * k + 64][24:] for k in range(n)]
                fdm[fd]["getRewardTokens"] = toks
            else:
                fdm[fd]["getRewardTokens"] = {"error": r}
        elif name == "voter":
            fdm[fd]["voter"] = get_addr(res, cid)
        elif name == "pairFees":
            fdm[fd]["pairFees"] = get_addr(res, cid)
        elif name == "firstPeriod":
            fdm[fd]["firstPeriod"] = get_uint(res, cid)
    data["fds"] = fdm

    # Phase 3: misc contract reads
    misc_calls = []
    idx = {}
    def add(to, name, args, tag, blockn=None):
        c = enc_to(to, S[name], args, hex(blockn or block))
        misc_calls.append(c)
        idx[c["id"]] = (tag, name)
        return c
    add(FEE_COLLECTOR, "treasury", [], "feeCollector")
    add(FEE_COLLECTOR, "treasuryFees", [], "feeCollector")
    add(FEE_COLLECTOR, "isTokenLive", [], "feeCollector")
    add(FEE_COLLECTOR, "voter", [], "feeCollector")
    add(FEEC := FEE_COLLECTOR, "balanceOf", [TOKENS["WETH"]], "feeCollector")
    add(FEE_COLLECTOR, "balanceOf", [TOKENS["USDC"]], "feeCollector")
    add(FEE_COLLECTOR, "balanceOf", [TOKENS["USDT"]], "feeCollector")
    add(FEE_COLLECTOR, "balanceOf", [TOKENS["NURI"]], "feeCollector")
    add(FD_FACTORY, "owner", [], "fdFactory")
    add(FD_FACTORY, "implementation", [], "fdFactory")
    add(FD_FACTORY, "lastFeeDistributor", [], "fdFactory")
    # roles
    role_op = keccak_hex("OPERATOR_ROLE")
    role_fs = keccak_hex("FEE_SETTER_ROLE")
    ROLES["OPERATOR_ROLE"] = role_op
    ROLES["FEE_SETTER_ROLE"] = role_fs
    data["roles_hashes"] = ROLES
    for rname, rh in ROLES.items():
        add(COMMAND_CENTER, "getRoleMemberCount", [rh], "cc")
        for k in range(10):
            add(COMMAND_CENTER, "getRoleMember", [rh, k], "cc_" + rname)
    res = rpc_batch(misc_calls)
    misc = {"feeCollector": {}, "fdFactory": {}, "cc_counts": {}, "cc_members": {}}
    for cid, (tag, name) in idx.items():
        if tag == "feeCollector":
            v = res[cid]
            if name in ("treasury", "voter"):
                misc["feeCollector"][name] = get_addr(res, cid)
            else:
                misc["feeCollector"][name] = get_uint(res, cid)
        elif tag == "fdFactory":
            if name in ("owner", "implementation", "lastFeeDistributor"):
                misc["fdFactory"][name] = get_addr(res, cid)
        elif tag == "cc":
            misc["cc_counts"][name] = get_uint(res, cid)
        else:
            bits = tag.split("_", 1)[1]
            arr = misc["cc_members"].setdefault(bits, [])
            v = get_addr(res, cid)
            if v and int(v, 16) != 0:
                arr.append(v)
    data["misc"] = misc
    json.dump(data, open(OUT, "w"), indent=1)
    print("saved", OUT, file=sys.stderr)
    # compact stdout summary
    print(json.dumps({"block": block, "fds": {k: {"balances": v["balances"], "voter": v["voter"], "pairFees": v["pairFees"], "firstPeriod": v["firstPeriod"], "getRewardTokens": v["getRewardTokens"]} for k, v in fdm.items()}, "misc": misc}, indent=1))

if __name__ == "__main__":
    main()
