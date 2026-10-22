#!/usr/bin/env python3
"""Scan recent logs on BSC via keyless public RPC (publicnode)."""
import json, urllib.request, time, sys, os

RPC = os.environ.get("BSC_PUBLIC_RPC", "https://bsc-rpc.publicnode.com")


def call(m, p, tries=8):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    last = None
    for i in range(tries):
        try:
            r = urllib.request.Request(RPC, data=b, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            d = json.loads(urllib.request.urlopen(r, timeout=45).read())
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = e
        time.sleep(1.5 * (i + 1))
    raise RuntimeError("rpc failed: %s" % last)


def logs(addr, topic0, frm, to):
    return call("eth_getLogs", [{"fromBlock": hex(frm), "toBlock": hex(to), "address": addr, "topics": [topic0]}])


def blk_ts(bn):
    b = call("eth_getBlockByNumber", [hex(bn), False])
    return int(b["timestamp"], 16)


if __name__ == "__main__":
    bn = int(call("eth_blockNumber", []), 16)
    TRANSFER = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    SYNC = "0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1"
    SWAP = "0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822"
    targets = [
        ("BT-Transfer", "0xb1939843fb9220719d13076dceefb0aeaef06666", TRANSFER),
        ("BT-PAIR-Sync", "0x3cc292bb0011951f3151eb998816c31680a2ce87", SYNC),
        ("BT-PAIR-Swap", "0x3cc292bb0011951f3151eb998816c31680a2ce87", SWAP),
        ("NS-Transfer", "0x33f1c4fbb7e4e040f4f4e6bc492e4fedf750fd41", TRANSFER),
        ("NS-PAIR-Sync", "0xf1a5896d91c1e2372b159455ad013b2d17c0bb0b", SYNC),
        ("DMD-Transfer", "0x939df4a5a5022037bb33102c6489e774e063b160", TRANSFER),
        ("DMD-PAIR-Sync", "0x29f9148a8518e327e8677ba21c3fa3a55dd1e6bc", SYNC),
    ]
    span = 8000
    out = {"block": bn, "span": span}
    for label, addr, topic in targets:
        got = []
        end = bn
        while end > bn - span:
            start = max(bn - span, end - 1000)
            try:
                got += logs(addr, topic, start, end)
            except Exception as e:
                print("ERR", label, start, end, e)
            end = start
        out[label] = {"count": len(got), "first": None, "last": None}
        if got:
            fb = int(got[0]["blockNumber"], 16)
            lb = int(got[-1]["blockNumber"], 16)
            out[label]["first"] = {"block": fb, "ts": blk_ts(fb)}
            out[label]["last"] = {"block": lb, "ts": blk_ts(lb)}
        print(label, "count", len(got), out[label]["last"])
    json.dump(out, open(os.path.join(os.path.dirname(__file__), "activity.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))
