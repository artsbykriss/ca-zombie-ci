#!/usr/bin/env python3
"""Read-only state reader for Katana Vault Bridge. No secrets stored; RPCs from env or public defaults."""
import json, os, sys, urllib.request
from eth_utils import keccak

ETH = os.environ.get("RPC_URL", "https://ethereum-rpc.publicnode.com")
KAT_RPC = os.environ.get("KATANA_RPC_URL", "https://rpc.katana.network")

def sel(sig):
    return "0x" + keccak(text=sig)[:4].hex()

def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        d = json.loads(r.read())
    if "error" in d: return None
    return d.get("result")

def call(url, to, sig, args=()):
    data = sel(sig)
    for a in args:
        if isinstance(a, int):
            data += a.to_bytes(32, "big").hex()
        elif isinstance(a, str) and a.startswith("0x") and len(a) == 42:
            data += "0" * 24 + a[2:].lower()
        elif isinstance(a, str):
            data += a
        else:
            raise ValueError(a)
    return rpc(url, "eth_call", [{"to": to, "data": data}, "latest"])

def u(out):
    if out in (None, "0x"):
        return None
    return int(out, 16)

def addr(out):
    if out in (None, "0x"):
        return None
    return "0x" + out[-40:]

def b32(out):
    return out

L1 = {
    "vbUSDC": "0x53E82ABbb12638F09d9e624578ccB666217a765e",
    "vbUSDT": "0x6d4f9f9f8f0155509ecd6Ac6c544fF27999845CC",
    "vbWBTC": "0x2C24B57e2CCd1f273045Af6A5f632504C432374F",
    "vbETH": "0x2DC70fb75b88d2eB4715bc06E1595E6D97c34DFF",
    "vbUSDS": "0x3DD459dE96F9C28e3a343b831cbDC2B93c8C4855",
    "adapter": "0xb5bada33542a05395d504a25885e02503a957bb3",
    "yieldVaultUSDC": "0xbeefb9f61cc44895d8aec381373555a64191a9c4",
}
L2 = {
    "minter": "0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0",
    "vbUSDC": "0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36",
    "vbUSDT": "0x2DCa96907fde857dd3D816880A0df407eeB2D2F2",
    "vbWBTC": "0x0913DA6Da4b42f538B445599b46Bb4622342Cf52",
    "vbETH": "0xEE7D8BCFb72bC1880D0Cf19822eB0A2e6577aB62",
    "yvvbUSDC": "0x80c34BD3A3569E126e7055831036aa7b212cB159",
}

out = {"eth_block": u(rpc(ETH, "eth_blockNumber", [])), "kat_block": u(rpc(KAT_RPC, "eth_blockNumber", [])), "l1": {}, "l2": {}}

for n, a in L1.items():
    d = {}
    for sig in ["name()", "symbol()", "decimals()", "totalSupply()", "totalAssets()", "asset()",
                "owner()", "paused()", "token()", "peers(uint32)", "globalInitializationCounter()",
                "secondaryChainBalance()", "endpoint()", "delegate()", "bridge()"]:
        try:
            raw = call(ETH, a, sig, (30101,) if sig.startswith("peers") else ())
        except Exception as e:
            d[sig] = "ERR " + str(e)[:80]; continue
        if sig in ("name()", "symbol()"):
            try:
                ln = u(raw[2:66]); s = bytes.fromhex(raw[130:130 + ln * 2]).decode(errors="replace") if ln else ""
                d[sig] = s
            except Exception:
                d[sig] = (raw or "0x")[:80]
        elif sig in ("decimals()",):
            d[sig] = u(raw)
        elif sig in ("totalSupply()", "totalAssets()", "globalInitializationCounter()", "secondaryChainBalance()"):
            d[sig] = u(raw)
        elif sig == "paused()":
            d[sig] = u(raw)
        elif sig == "peers(uint32)":
            d[sig] = raw
        else:
            d[sig] = addr(raw)
    out["l1"][n] = d

for n, a in L2.items():
    d = {}
    for sig in ["name()", "symbol()", "decimals()", "totalSupply()", "totalAssets()", "asset()",
                "owner()", "paused()", "token()", "peers(uint32)", "globalInitializationCounter()",
                "secondaryChainBalance()", "endpoint()", "delegate()", "bridge()", "balance()", "totalDebt()"]:
        try:
            raw = call(KAT_RPC, a, sig, (30101,) if sig.startswith("peers") else ())
        except Exception as e:
            d[sig] = "ERR " + str(e)[:80]; continue
        if sig in ("name()", "symbol()"):
            try:
                ln = u(raw[2:66]); s = bytes.fromhex(raw[130:130 + ln * 2]).decode(errors="replace") if ln else ""
                d[sig] = s
            except Exception:
                d[sig] = (raw or "0x")[:80]
        elif sig in ("decimals()", "totalSupply()", "totalAssets()", "globalInitializationCounter()", "secondaryChainBalance()", "balance()", "totalDebt()"):
            d[sig] = u(raw)
        elif sig == "paused()":
            d[sig] = u(raw)
        elif sig == "peers(uint32)":
            d[sig] = raw
        else:
            d[sig] = addr(raw)
    out["l2"][n] = d

# peer for Katana EID on both adapters: determine EID by scanning known
for url, tag, a in [(ETH, "l1", L1["adapter"]), (KAT_RPC, "l2", L2["minter"])]:
    out[tag]["peer_scan"] = {}
    for eid in [30101, 30102, 30110, 30184, 30333, 30495, 30496, 30500, 747474]:
        try:
            out[tag]["peer_scan"][eid] = call(url, a, "peers(uint32)", (eid,))
        except Exception as e:
            out[tag]["peer_scan"][eid] = "ERR"

print(json.dumps(out, indent=1))
