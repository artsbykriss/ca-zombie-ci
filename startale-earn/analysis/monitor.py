#!/usr/bin/env python3
"""ZH4-02 Startale Earn — closing-condition / competitor-bot monitor.

Read-only, keyless public RPC. Exit code 1 if any ALERT fires.
Usage: python3 monitor.py [LOOKBACK_BLOCKS] [OUT_JSON]
"""
import json
import sys
import urllib.request

RPC = "https://rpc.soneium.org"
VAULT = "0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0"
RR = "0xda798684ffD5eb509c2Ab7b8352EC55B31F18201"
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
EXPECTED_IMPL = "0x7dca02767dfd57888ce087900f9cfdf3d9a2af6f"
EXPECTED_OWNER = "0x3c27038d9906caa5d68355b1800625eacacd93da"
SEL = {
    "paused": "0x5c975abb",
    "owner": "0x8da5cb5b",
    "pauser": "0x9fd0506d",
    "fee": "0x30961c4a",
    "maxAge": "0x4af8a0ee",
    "lastSnapBlock": "0x4c1ed639",
    "lastSnapTs": "0x6f660492",
}
TOPIC_DEP = "0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c"
TOPIC_SNAP = "0x45ab00eeb8cdb789bcd9bd7ff7d33c27e3f4ba7ad8ac49be117bccccc3047e15"
TOPIC_DIST = "0xb0f6cb92613f539c9994bd9a3e58e6148dd29ea75941f831362f737ba5fdffb0"


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research; read-only)"})
    with urllib.request.urlopen(req, timeout=45) as r:
        j = json.loads(r.read())
    if "result" not in j:
        raise RuntimeError(j.get("error"))
    return j["result"]


def u(x):
    return int(x, 16)


def call(addr, sel):
    return rpc("eth_call", [{"to": addr, "data": sel}, "latest"])


def word(addr, slot):
    return rpc("eth_getStorageAt", [addr, slot, "latest"])


def addr_of(hexword):
    return "0x" + hexword[-40:]


def logs(addr, topic, frm, to):
    out, b = [], frm
    while b <= to:
        e = min(b + 999, to)
        out += rpc("eth_getLogs", [{"address": addr, "fromBlock": hex(b), "toBlock": hex(e),
                                    "topics": [topic]}])
        b = e + 1
    return out


def main():
    lookback = int(sys.argv[1]) if len(sys.argv) > 1 else 12000
    out_path = sys.argv[2] if len(sys.argv) > 2 else "monitor.json"
    latest = u(rpc("eth_blockNumber", []))
    frm = latest - lookback

    impl = addr_of(word(VAULT, IMPL_SLOT))
    paused = u(call(VAULT, SEL["paused"])) != 0
    rr_paused = u(call(RR, SEL["paused"])) != 0
    owner = addr_of(call(VAULT, SEL["owner"]))
    pauser = addr_of(call(VAULT, SEL["pauser"]))
    fee = u(call(RR, SEL["fee"]))
    max_age = u(call(RR, SEL["maxAge"]))
    last_snap_block = u(call(RR, SEL["lastSnapBlock"]))
    last_snap_ts = u(call(RR, SEL["lastSnapTs"]))

    snaps = logs(RR, TOPIC_SNAP, frm, latest)
    dists = logs(RR, TOPIC_DIST, frm, latest)
    deps = logs(VAULT, TOPIC_DEP, frm, latest)

    alerts, jit = [], []
    if impl.lower() != EXPECTED_IMPL:
        alerts.append(f"UPGRADE: EarnVault impl is {impl} (expected {EXPECTED_IMPL})")
    if paused or rr_paused:
        alerts.append(f"PAUSED: vault={paused} redistributor={rr_paused}")
    if fee != 30:
        alerts.append(f"FEE CHANGED: fee_on_yield_bps={fee}")
    if max_age != 300:
        alerts.append(f"SNAPSHOT MAX AGE CHANGED: {max_age}")
    if owner.lower() != EXPECTED_OWNER or pauser.lower() != EXPECTED_OWNER:
        alerts.append(f"OWNER/PAUSER CHANGED: owner={owner} pauser={pauser}")
    if latest - last_snap_block > 8000:  # > ~4.4h at 2s blocks
        alerts.append(f"KEEPER GAP: last snapshot block {last_snap_block}, latest {latest}")

    # pair each snapshot with its next distribution
    windows = []
    for s in snaps:
        sb = u(s["blockNumber"])
        nb = None
        for d in dists:
            db = u(d["blockNumber"])
            if db >= sb:
                nb = db
                break
        windows.append((sb, nb))

    for d in deps:
        db = u(d["blockNumber"])
        amt = u(d["data"]) / 1e6
        for sb, nb in windows:
            if sb - 5 <= db < sb:
                jit.append({"block": db, "amount": amt, "kind": "PRE_SNAPSHOT",
                            "snapshotBlock": sb, "user": addr_of(d["topics"][1])})
                break
            if nb is not None and sb < db <= nb:
                jit.append({"block": db, "amount": amt, "kind": "IN_WINDOW",
                            "snapshotBlock": sb, "distributeBlock": nb,
                            "user": addr_of(d["topics"][1])})
                break
    big = [x for x in jit if x["amount"] >= 100_000]
    if big:
        alerts.append(f"COMPETITOR JIT: {len(big)} deposit(s) >= $100k in the epoch window")
    elif jit:
        alerts.append(f"window deposits: {len(jit)} small (max ${max(x['amount'] for x in jit):,.2f})")

    res = {
        "latestBlock": latest, "lookback": lookback,
        "impl": impl, "paused": paused, "rrPaused": rr_paused,
        "owner": owner, "pauser": pauser, "feeBps": fee, "snapshotMaxAge": max_age,
        "lastSnapshotBlock": last_snap_block, "lastSnapshotTimestamp": last_snap_ts,
        "snapshots": len(snaps), "distributions": len(dists), "deposits": len(deps),
        "windowDeposits": jit, "alerts": alerts, "status": "ALERT" if alerts else "OK",
    }
    with open(out_path, "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps({k: res[k] for k in ("latestBlock", "impl", "paused", "rrPaused", "feeBps",
                                          "snapshotMaxAge", "lastSnapshotBlock", "snapshots",
                                          "distributions", "deposits", "status")}, indent=1))
    print("alerts:", alerts if alerts else "none")
    print("windowDeposits:", len(jit), "max $", max([x["amount"] for x in jit], default=0))
    sys.exit(1 if alerts else 0)


if __name__ == "__main__":
    main()
