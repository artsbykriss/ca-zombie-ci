#!/usr/bin/env python3
"""2026-11 escalation: sample OI/caps + BBO mid on Papertrade (HyperEVM 999).
Read-only. Writes escalation_oi_poll.jsonl (append). Public keyless RPC, no secrets."""
import json, time, urllib.request
from Crypto.Hash import keccak

U = "https://rpc.hyperliquid.xyz/evm"
EX = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
ORACLE = "0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"
M96 = 2**96 - 1
M128 = 2**128 - 1


def rpc(m, p, retries=4):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    for i in range(retries):
        try:
            r = urllib.request.Request(U, data=b, headers={"Content-Type": "application/json",
                                                           "User-Agent": "Mozilla/5.0"})
            return json.loads(urllib.request.urlopen(r, timeout=25).read())
        except Exception:
            if i == retries - 1:
                raise
            time.sleep(1.5)


def slot_hash(mid, base):
    k = keccak.new(digest_bits=256)
    k.update(bytes.fromhex(format(mid, '064x') + format(base, '064x')))
    return "0x" + k.hexdigest()


out = open("/home/heisenberg/CA/papertrade/analysis/escalation_oi_poll.jsonl", "a")
for n in range(30):
    try:
        bn = int(rpc("eth_blockNumber", [])["result"], 16)
        blk = hex(bn)
        rec = {"t": int(time.time()), "block": bn, "markets": {}}
        for mid, name in ((0, "BTC"), (1, "ETH")):
            h = slot_hash(mid, 0x24)
            s0 = int(rpc("eth_getStorageAt", [EX, h, blk])["result"], 16)
            s1 = int(rpc("eth_getStorageAt", [EX, hex(int(h, 16) + 1), blk])["result"], 16)
            m = rpc("eth_call", [{"to": ORACLE, "data": "0xc0182669" + format(mid, '064x')}, blk]).get("result")
            ps = s0 >> 192
            mid_px = int(m, 16) / ps if (m and ps) else None
            rec["markets"][name] = {
                "longOI": (s0 & M96) / 1e18,
                "shortOI": ((s0 >> 96) & M96) / 1e18,
                "longCap": (s1 & M128) / 1e18,
                "shortCap": ((s1 >> 128) & M128) / 1e18,
                "mid": mid_px,
            }
        out.write(json.dumps(rec) + "\n")
    except Exception as e:
        out.write(json.dumps({"t": int(time.time()), "err": str(e)[:120]}) + "\n")
    out.flush()
    time.sleep(20)
out.close()
print("done")
