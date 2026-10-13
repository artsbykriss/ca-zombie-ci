#!/usr/bin/env python3
"""Corrected per-pair probes: factory.getPoolFeeSplit(pair), pair slot3 (feeSplit/stable/hasActiveGauge),
PairFees.feeDistributor() + PairFees token balances."""
import json, urllib.request

RPC = "https://rpc.scroll.io"
FACTORY = "0xAAA16c016BF556fcD620328f0759252E29b1AB57"

def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

def rpc_batch(calls, block):
    payload = []
    for i, (to, data) in enumerate(calls):
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call",
                        "params": [{"to": to, "data": data}, hex(block)]})
    body = json.dumps(payload).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    resp = json.load(urllib.request.urlopen(req, timeout=60))
    return {it["id"]: it.get("result", {"error": it.get("error")}) for it in resp}

def block_number():
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return int(json.load(urllib.request.urlopen(req, timeout=60))["result"], 16)

d = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs.json"))
block = d["block"]
pairs = [p["pair"] for p in d["pairs"]]

# 1) factory.getPoolFeeSplit(pair)
calls = [(FACTORY, "0xe829263f" + enc_addr(p)) for p in pairs]
res = {}
for s in range(0, len(calls), 8):
    r = rpc_batch(calls[s:s+8], block)
    for k, v in r.items():
        res[s + k] = v
poolsplit = {}
for i, p in enumerate(pairs):
    r = res[i]
    poolsplit[p] = None if isinstance(r, dict) else int(r, 16)
print("factory.getPoolFeeSplit distinct:", sorted(set(poolsplit.values()), key=lambda x: (x is None, x)))

# 2) pair slot 3 -> feeSplit/stable/hasActiveGauge
slot3 = {}
for s in range(0, len(pairs), 8):
    payload = []
    for i, p in enumerate(pairs[s:s+8]):
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_getStorageAt",
                        "params": [p, "0x" + "3".rjust(64, "0"), hex(block)]})
    body = json.dumps(payload).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    resp = json.load(urllib.request.urlopen(req, timeout=60))
    for it in resp:
        p = pairs[s + it["id"]]
        v = int(it["result"], 16)
        slot3[p] = {"feeSplit": v & 0xff, "stable": (v >> 8) & 0xff, "hasActiveGauge": (v >> 16) & 0xff}
from collections import Counter
print("slot3 hasActiveGauge counts:", Counter(s["hasActiveGauge"] for s in slot3.values()))
print("slot3 feeSplit counts:", Counter(s["feeSplit"] for s in slot3.values()))

# 3) PairFees feeDistributor + balances
fees_contracts = [p["fees"] for p in d["pairs"] if p.get("fees")]
calls = []
meta = []
for f in fees_contracts:
    calls.append((f, "0x9af1d35a"))  # placeholder avoid clash; real selector below
    meta.append((f, "feeDistributor"))
# feeDistributor() selector
import subprocess
sel_fd = subprocess.run(["cast", "sig", "feeDistributor()"], capture_output=True, text=True).stdout.strip()
calls = [(f, sel_fd) for f in fees_contracts]
fd = {}
for s in range(0, len(calls), 8):
    r = rpc_batch(calls[s:s+8], block)
    for k, v in r.items():
        fd[fees_contracts[s+k]] = None if isinstance(v, dict) else "0x" + v[-40:]
print("PairFees feeDistributor set:", sum(1 for v in fd.values() if v and int(v,16)!=0), "/", len(fd))

# PairFees balances for token0/token1 of own pair
bal_calls = []
bal_meta = []
for p in d["pairs"]:
    f = p.get("fees")
    for i in (0, 1):
        t = p.get(f"token{i}")
        if f and t:
            bal_calls.append((t, "0x70a08231" + enc_addr(f)))
            bal_meta.append((f, i, t))
bal = {}
for s in range(0, len(bal_calls), 8):
    r = rpc_batch(bal_calls[s:s+8], block)
    for k, v in r.items():
        bal[(bal_meta[s+k][0], bal_meta[s+k][1])] = None if isinstance(v, dict) else int(v, 16)
nonzero = {k: v for k, v in bal.items() if v}
print("PairFees with nonzero token balance:", len(nonzero))
for k, v in list(nonzero.items())[:20]:
    print("  ", k, v)

out = {"block": block, "factory_getPoolFeeSplit": poolsplit, "pair_slot3": slot3,
       "pairfees_feeDistributor": fd, "pairfees_balances": {f"{k[0]}:{k[1]}": v for k, v in bal.items()}}
json.dump(out, open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pair-details.json", "w"), indent=1)
print("saved childC-v2-pair-details.json")
