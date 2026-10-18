#!/usr/bin/env python3
"""ZH4-02 Startale Earn (Soneium) — live-state dump + recent epoch log.

Read-only; keyless public RPC only (no secrets in output). Usage:
    python3 live_state.py [OUT_JSON] [LOOKBACK_BLOCKS]
"""
import json
import sys
import time
import urllib.request

RPC = "https://rpc.soneium.org"
VAULT = "0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0"
RR = "0xda798684ffD5eb509c2Ab7b8352EC55B31F18201"
USDSC = "0x3f99231dD03a9F0E7e3421c92B7b90fbe012985a"
SUSDSC = "0x938bca6c4281313Baa82154745E4d020E85E7340"
ROLE_MEMBER = "0x86bE13a26d548FA5407Ee3E5a8321B4E1019333C"

# 4-byte selectors
SEL = {
    "totalPrincipal": "0x4b1533b2",
    "claimReserve": "0x3fe5f054",
    "paused": "0x5c975abb",
    "owner": "0x8da5cb5b",
    "pauser": "0x9fd0506d",
    "isBlacklisted": "0xfe575a87",
    "getVersion": "0x0d8e6e2c",
    "fee_on_yield_bps": "0x30961c4a",
    "snapshotMaxAge": "0x4af8a0ee",
    "lastSnapshotTimestamp": "0x6f660492",
    "lastSnapshotBlockNumber": "0x4c1ed639",
    "lastEarnTVL": "0xd9777382",
    "treasury": "0x61d027b3",
    "previewSplitCurrent": "0xe1aa0769",
    "totalSupply": "0x18160ddd",
    "balanceOf": "0x70a08231",
    "yield": "0x28593984",
}

TOPIC_DIST = "0xb0f6cb92613f539c9994bd9a3e58e6148dd29ea75941f831362f737ba5fdffb0"
TOPIC_SNAP = "0x45ab00eeb8cdb789bcd9bd7ff7d33c27e3f4ba7ad8ac49be117bccccc3047e15"


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research; read-only)"})
    for attempt in range(10):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"]
            raise RuntimeError(j.get("error"))
        except urllib.error.HTTPError as e:
            if attempt == 9:
                raise
            time.sleep(60 if e.code == 429 else 3 * (attempt + 1))
        except Exception:
            if attempt == 9:
                raise
            time.sleep(3 * (attempt + 1))


def call(addr, sel, arg=None):
    data = sel if arg is None else sel + arg[2:].rjust(64, "0")
    return rpc("eth_call", [{"to": addr, "data": data}, "latest"])


def u(h):
    return int(h, 16)


def words(data):
    h = data[2:]
    return [int(h[i:i + 64], 16) for i in range(0, len(h), 64)]


def get_logs(addr, topic, frm, to):
    out, b = [], frm
    while b <= to:
        e = min(b + 999, to)
        out += rpc("eth_getLogs", [{"address": addr, "fromBlock": hex(b), "toBlock": hex(e), "topics": [topic]}])
        b = e + 1
    return out


def block_ts(bn):
    return u(rpc("eth_getBlockByNumber", [hex(bn), False])["timestamp"])


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else "live_state.json"
    lookback = int(sys.argv[2]) if len(sys.argv) > 2 else 60000

    blk = u(rpc("eth_blockNumber", []))
    ts = block_ts(blk)
    res = {"rpc": "public keyless https://rpc.soneium.org", "block": blk, "timestamp": ts,
           "iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(ts)), "addresses": {
               "earnVault": VAULT, "rewardRedistributor": RR, "usdsc": USDSC,
               "susdsc": SUSDSC, "keeper": ROLE_MEMBER}}

    p = res["params"] = {}
    p["totalPrincipal_usd"] = u(call(VAULT, SEL["totalPrincipal"])) / 1e6
    p["claimReserve_usd"] = u(call(VAULT, SEL["claimReserve"])) / 1e6
    p["vaultBalance_usd"] = u(call(USDSC, SEL["balanceOf"], VAULT)) / 1e6
    p["vaultPaused"] = u(call(VAULT, SEL["paused"])) != 0
    p["vaultOwner"] = "0x" + call(VAULT, SEL["owner"])[-40:]
    p["vaultPauser"] = "0x" + call(VAULT, SEL["pauser"])[-40:]
    raw = call(VAULT, SEL["getVersion"])[2:]
    off = int(raw[0:64], 16) * 2
    slen = int(raw[off:off + 64], 16)
    p["vaultVersion"] = bytes.fromhex(raw[off + 64:off + 64 + slen * 2]).decode(errors="ignore")
    p["attackerBlacklisted"] = u(call(VAULT, SEL["isBlacklisted"], "0x0000000000000000000000000000000000000001")) != 0
    p["feeBps"] = u(call(RR, SEL["fee_on_yield_bps"]))
    p["snapshotMaxAge_s"] = u(call(RR, SEL["snapshotMaxAge"]))
    p["lastSnapshotTimestamp"] = u(call(RR, SEL["lastSnapshotTimestamp"]))
    p["lastSnapshotBlock"] = u(call(RR, SEL["lastSnapshotBlockNumber"]))
    p["lastEarnTVL_usd"] = u(call(RR, SEL["lastEarnTVL"])) / 1e6
    p["rrPaused"] = u(call(RR, SEL["paused"])) != 0
    p["treasury"] = "0x" + call(RR, SEL["treasury"])[-40:]
    p["usdscTotalSupply_usd"] = u(call(USDSC, SEL["totalSupply"])) / 1e6
    p["usdscPendingYield_usd"] = u(call(USDSC, SEL["yield"])) / 1e6
    try:
        p["susdscTVL_usd"] = u(call(SUSDSC, SEL["totalSupply"])) / 1e6
    except Exception:
        p["susdscTVL_usd"] = None

    pv = words(call(RR, SEL["previewSplitCurrent"]))
    p["previewSplitCurrent"] = {
        "couldBeMinted_usd": pv[0] / 1e6, "feeToStartale_usd": pv[1] / 1e6,
        "toEarnVault_usd": pv[2] / 1e6, "toSUSDSCVault_usd": pv[3] / 1e6,
        "toStartaleExtra_usd": pv[4] / 1e6, "S_base_usd": pv[5] / 1e6,
        "T_earn_usd": pv[6] / 1e6, "T_yield_usd": pv[7] / 1e6}

    # attacked float: USDSC outside the two vaults and the RR
    supply = p["usdscTotalSupply_usd"]
    locked = (p["vaultBalance_usd"] + (p["susdscTVL_usd"] or 0)
              + u(call(USDSC, SEL["balanceOf"], RR)) / 1e6)
    p["attackableFloat_usd"] = max(0.0, supply - locked)

    # recent epochs
    frm = blk - lookback
    dist = get_logs(RR, TOPIC_DIST, frm, blk)
    snap = get_logs(RR, TOPIC_SNAP, frm, blk)
    epochs = []
    for d in dist:
        b = u(d["blockNumber"])
        w = words(d["data"])
        s = None
        for c in reversed(snap):
            if u(c["blockNumber"]) <= b:
                s = c
                break
        epochs.append({
            "distBlock": b, "distTs": block_ts(b),
            "snapBlock": u(s["blockNumber"]) if s else None,
            "snapTs": block_ts(u(s["blockNumber"])) if s else None,
            "minted": w[0] / 1e6, "fee": w[1] / 1e6, "toEarn": w[2] / 1e6,
            "toOn": w[3] / 1e6, "toStartaleExtra": w[4] / 1e6,
            "S_base": w[5] / 1e6, "T_earn": w[6] / 1e6, "T_yield": w[7] / 1e6,
            "tx": d["transactionHash"]})
    res["epochs"] = epochs
    if len(epochs) >= 2:
        res["epochMean"] = {
            "n": len(epochs),
            "minted": sum(e["minted"] for e in epochs) / len(epochs),
            "toEarn": sum(e["toEarn"] for e in epochs) / len(epochs),
            "toOn": sum(e["toOn"] for e in epochs) / len(epochs),
            "toStartaleExtra": sum(e["toStartaleExtra"] for e in epochs) / len(epochs)}
        res["epochMean"]["capturePer1MPerEpoch"] = (
            res["epochMean"]["minted"] * (1 - p["feeBps"] / 10000) * 1e6 / epochs[-1]["S_base"])
        res["epochMean"]["capturePer1MPerDay"] = res["epochMean"]["capturePer1MPerEpoch"] * 8

    res["topHolders"] = []
    try:
        req = urllib.request.Request(
            f"https://soneium.blockscout.com/api/v2/tokens/{USDSC}/holders",
            headers={"User-Agent": "Mozilla/5.0 (research; read-only)"})
        with urllib.request.urlopen(req, timeout=45) as r:
            h = json.loads(r.read())
        res["topHolders"] = [{"address": it["address"]["hash"], "name": it["address"].get("name"),
                              "usdsc": int(it["value"]) / 1e6} for it in h.get("items", [])[:15]]
    except Exception as e:
        res["topHoldersError"] = str(e)[:200]

    with open(out_path, "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps({k: res[k] for k in ("block", "iso")}, indent=1))
    print(json.dumps({k: p[k] for k in ("totalPrincipal_usd", "vaultBalance_usd", "usdscTotalSupply_usd",
                                        "usdscPendingYield_usd", "attackableFloat_usd", "feeBps",
                                        "snapshotMaxAge_s", "lastSnapshotBlock", "vaultPaused", "rrPaused")}, indent=1))
    print("epochs:", len(epochs), "mean:", json.dumps(res.get("epochMean", {})))


if __name__ == "__main__":
    main()
