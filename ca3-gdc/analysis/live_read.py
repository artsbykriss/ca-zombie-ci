#!/usr/bin/env python3
"""Read-only live state for GDC (BSC). Uses keyless public RPC. No secrets."""
import json, sys, urllib.request

RPC = "https://bsc-rpc.publicnode.com"

TOKEN = "0x39a90d082e19bd2ac30da6964d3d2fda50077777"
PAIR = "0xe3349ca6ac1656e02b20b8d5a4c095e28255eb0a"
MAIN = "0x8955Be303f033a837f7C3c407e0B2b3f9bC4fD5C"
DIST = "0x3cf55c7c22C6555139c818aB7a7a89aFf70F8360"
REF = "0xD3Ba7d944544d3416131663919580e039294130E"
WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"

SEL = {
    "getReserves": "0x0902f1ac", "token0": "0x0dfe1681", "token1": "0xd21220a7",
    "balanceOf": "0x70a08231", "totalSupply": "0x18160ddd",
    "maxSellAmount": "0x66d602ae", "currentStage": "0x5bf5d54c",
    "reserveDistributor": "0xac1b0deb", "owner": "0x8da5cb5b",
    "companyAccount": "0x642a833f", "rewardAccount": "0x0e708203",
    "depositContract": "0xe94ad65b", "referrals": "0xd3dc7539", "pair": "0xa8aa1b31",
    "lastTriggerTime": "0x35c8c09a", "deflationCount": "0xa72bbad3",
    "stage1Rounds": "0x0c3d5938", "paused": "0x5c975abb",
    "gdc": "0x660d86ef", "controller": "0xf77c4791", "dividendReceiver": "0x1e77ee15",
    "rootAddress": "0xaaa2b8c8", "pendingReserveDividend": "0x4afbb842",
    "distributionRemaining": "0x9b3fa91c", "originalDeflationReward": "0x1ad6c4e8",
    "minAmount": "0x9b2cb5d8", "maxAmount": "0x5f48f393", "LP_MIN_BALANCE": "0x0f7a83ec",
    "eligibilityRound": "0x25da1038", "lastSellAt": "0x...",
}

def pad(addr):
    return "0" * 24 + addr[2:].lower()

calls = []
def add(tag, to, data):
    calls.append({"jsonrpc": "2.0", "id": len(calls) + 1, "method": "eth_call",
                  "params": [{"to": to, "data": data}, "latest"]})

add("block", TOKEN, "0x")  # placeholder removed later
calls = []
add("pair.getReserves", PAIR, SEL["getReserves"])
add("pair.token0", PAIR, SEL["token0"])
add("pair.token1", PAIR, SEL["token1"])
add("pair.totalSupply", PAIR, SEL["totalSupply"])
for nm, a in [("GDC", TOKEN), ("WBNB", WBNB), ("pair", PAIR), ("MAIN", MAIN), ("DIST", DIST), ("REF", REF)]:
    add(f"{nm}.balance", TOKEN if nm != "WBNB" else WBNB, SEL["balanceOf"] + pad(a))
add("WBNB.balanceOf(pair)", WBNB, SEL["balanceOf"] + pad(PAIR))
for f in ["maxSellAmount", "currentStage", "reserveDistributor", "owner", "companyAccount",
          "rewardAccount", "depositContract", "referrals", "pair", "totalSupply",
          "lastTriggerTime", "deflationCount", "stage1Rounds", "LP_MIN_BALANCE"]:
    add(f"token.{f}", TOKEN, SEL[f])
for f in ["owner", "minAmount", "maxAmount", "pendingReserveDividend", "distributionRemaining",
          "originalDeflationReward", "deflationCount", "eligibilityRound"]:
    add(f"main.{f}", MAIN, SEL[f])
for f in ["gdc", "controller", "dividendReceiver"]:
    add(f"dist.{f}", DIST, SEL[f])
add("ref.rootAddress", REF, SEL["rootAddress"])
add("main.paused()", MAIN, SEL["paused"])

req = urllib.request.Request(RPC, data=json.dumps(calls).encode(),
                             headers={"Content-Type": "application/json", "User-Agent": "research/1.0"})
res = json.load(urllib.request.urlopen(req, timeout=60))
byid = {r["id"]: r for r in res}

# block number
breq = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
                              headers={"Content-Type": "application/json", "User-Agent": "research/1.0"})
blk = int(json.load(urllib.request.urlopen(breq, timeout=30))["result"], 16)

out = {"rpc": "publicnode (keyless)", "block": blk, "targets": {
    "token": TOKEN, "pair": PAIR, "main": MAIN, "distributor": DIST, "referrals": REF, "wbnb": WBNB}}
vals = {}
for i, c in enumerate(calls):
    tag = c and None
    r = byid.get(i + 1, {})
    vals[i] = r.get("result", "ERR:" + str(r.get("error")))

# decode
names = [c for c in [
 "pair.getReserves","pair.token0","pair.token1","pair.totalSupply",
 "GDC.balance","WBNB.balance","pair.balance","MAIN.balance","DIST.balance","REF.balance",
 "WBNB.balanceOf(pair)",
 "token.maxSellAmount","token.currentStage","token.reserveDistributor","token.owner","token.companyAccount",
 "token.rewardAccount","token.depositContract","token.referrals","token.pair","token.totalSupply",
 "token.lastTriggerTime","token.deflationCount","token.stage1Rounds","token.LP_MIN_BALANCE",
 "main.owner","main.minAmount","main.maxAmount","main.pendingReserveDividend","main.distributionRemaining",
 "main.originalDeflationReward","main.deflationCount","main.eligibilityRound",
 "dist.gdc","dist.controller","dist.dividendReceiver","ref.rootAddress","main.paused()"]]
assert len(names) == len(calls), (len(names), len(calls))
dec = {}
for i, nm in enumerate(names):
    h = vals[i]
    dec[nm] = h
    if not isinstance(h, str) or not h.startswith("0x"):
        continue
    raw = h[2:]
    if nm == "pair.getReserves":
        r0 = int(raw[0:64], 16); r1 = int(raw[64:128], 16); ts = int(raw[128:192], 16)
        dec[nm] = {"reserve0": r0, "reserve1": r1, "blockTimestampLast": ts}
    elif len(raw) == 64:
        v = int(raw, 16)
        if nm.endswith("owner") or nm.endswith("Account") or nm.endswith("Contract") or nm in (
                "pair.token0","pair.token1","token.reserveDistributor","token.referrals","token.pair",
                "dist.gdc","dist.controller","dist.dividendReceiver","ref.rootAddress"):
            dec[nm] = "0x" + raw[24:]
        else:
            dec[nm] = v
    elif len(raw) > 64:
        dec[nm] = raw

out["state"] = dec
out["note"] = "all reads eth_call at latest block"
print(json.dumps(out, indent=2))
