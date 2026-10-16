#!/usr/bin/env python3
"""Decode Valos vault event logs (Etherscan V2 JSON)."""
import json, sys

def word(data, i):
    d = data[2:] if data.startswith("0x") else data
    return int(d[i*64:(i+1)*64], 16)

def addr(topic):
    return "0x" + topic[-40:]

def load(name):
    d = json.load(open(f"logs_{name}.json"))
    return d.get("result") or []

def ts(log):
    return int(log["timeStamp"], 16)

import datetime
def iso(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%S")

out = []

# AllowedSet(address indexed,bool)
for l in load("allowedset"):
    acct = addr(l["topics"][1]); allowed = word(l["data"], 0) == 1
    out.append(f"[allowedset] blk={int(l['blockNumber'],16)} {iso(ts(l))} acct={acct} allowed={allowed}")

# Deposit(controller indexed, receiver indexed, assets, shares)
for l in load("deposit"):
    ctrl = addr(l["topics"][1]); recv = addr(l["topics"][2])
    assets = word(l["data"],0)/1e6; shares = word(l["data"],1)/1e6
    out.append(f"[deposit] blk={int(l['blockNumber'],16)} {iso(ts(l))} ctrl={ctrl} recv={recv} assets=${assets:,.2f} shares={shares:,.6f}")

# RedeemRequest(controller, owner, requestId indexed, sender, shares)
for l in load("redeemrequest"):
    ctrl = addr(l["topics"][1]); owner = addr(l["topics"][2]); rid = int(l["topics"][3],16)
    sender = addr("0x"+l["data"][0:64][-40:]) if len(l["data"])>=64 else "?"
    shares = word(l["data"],1)/1e6
    out.append(f"[redeemreq] blk={int(l['blockNumber'],16)} {iso(ts(l))} ctrl={ctrl} owner={owner} requestId={rid} shares={shares:,.6f}")

# RedeemClaimable(controller indexed, requestId indexed, assets, shares)
for l in load("redeemclaimable"):
    ctrl = addr(l["topics"][1]); rid = int(l["topics"][2],16)
    assets = word(l["data"],0)/1e6; shares = word(l["data"],1)/1e6
    out.append(f"[claimable] blk={int(l['blockNumber'],16)} {iso(ts(l))} ctrl={ctrl} requestId={rid} assets=${assets:,.2f} shares={shares:,.6f}")

# Withdraw(sender indexed, receiver indexed, controller indexed, assets, shares)
for l in load("withdraw"):
    sender = addr(l["topics"][1]); recv = addr(l["topics"][2]); ctrl = addr(l["topics"][3])
    assets = word(l["data"],0)/1e6; shares = word(l["data"],1)/1e6
    out.append(f"[withdraw] blk={int(l['blockNumber'],16)} {iso(ts(l))} sender={sender} recv={recv} ctrl={ctrl} assets=${assets:,.2f} shares={shares:,.6f}")

# LockAssets(caller indexed, assets)
for l in load("lockassets"):
    caller = addr(l["topics"][1]); assets = word(l["data"],0)/1e6
    out.append(f"[lock] blk={int(l['blockNumber'],16)} {iso(ts(l))} caller={caller} assets=${assets:,.2f}")

# ReleaseAssets(caller indexed, assets)
for l in load("releaseassets"):
    caller = addr(l["topics"][1]); assets = word(l["data"],0)/1e6
    out.append(f"[release] blk={int(l['blockNumber'],16)} {iso(ts(l))} caller={caller} assets=${assets:,.2f}")

out.sort(key=lambda s: int(s.split("blk=")[1].split()[0]))
print("\n".join(out))
print("\nTOTAL lines:", len(out))
