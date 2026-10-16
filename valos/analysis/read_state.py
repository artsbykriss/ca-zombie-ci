#!/usr/bin/env python3
"""Read-only state dump for Valos vault + AccountableOpenTerm strategy on Monad.
Uses a public keyless RPC (default https://rpc.monad.xyz). No keys, no writes.
"""
import json, sys, urllib.request

RPC = sys.argv[1] if len(sys.argv) > 1 else "https://rpc.monad.xyz"
VAULT = "0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365"
STRAT = "0x8dCE15fc6a98484C995Fc702cBfBdA14A30454af"
AUSD  = "0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a"

# selector computation (keccak via hashlib not available; precomputed below)
SIGS = {
    "permissionLevel()": "0x7a3c4c91",
    "precision()": "0xaaf5eb68",
    "transferableShares()": "0x",
    "totalAssets()": "0x01e1d114",
    "totalSupply()": "0x18160ddd",
    "decimals()": "0x313ce567",
    "sharePrice()": "0x82b2e257",
    "assetShareRatio()": "0x7c8f2f5e",
    "reservedLiquidity()": "0x",
    "totalQueuedShares()": "0x",
    "queue()": "0x",
    "loanState()": "0x",
    "scaleFactor()": "0x",
    "netPrincipal()": "0x",
    "paused()": "0x5c975abb",
    "borrower()": "0x7df1f1b9",
    "investmentManager()": "0x",
    "safetyModule()": "0x",
    "dvnPublisher()": "0x",
    "proofSigner()": "0x",
    "globals()": "0x",
    "feeManager()": "0x",
    "priceOracle()": "0x",
    "managerFeeRecipient()": "0x",
    "penaltiesEnabled()": "0x",
    "securityAdminEnabled()": "0x",
    "operationsAdminEnabled()": "0x",
    "version()": "0x54fd4d50",
    "delinquencyStartTime()": "0x",
    "currentBatch()": "0x",
    "pendingBatch()": "0x",
    "loan()": "0x",
    "maxDeposit(address,address)": "0x",
    "accruedAssets(address)": "0x",
    "sharePrice(address)": "0x",
}

def rpc_batch(calls, url):
    payload = []
    for i, (to, data) in enumerate(calls):
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call",
                        "params": [{"to": to, "data": data}, "latest"]})
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0"})
    out = json.loads(urllib.request.urlopen(req, timeout=60).read())
    res = {}
    for item in out:
        res[item["id"]] = item.get("result", item.get("error"))
    return [res[i] for i in range(len(calls))]

def block_number(url):
    req = urllib.request.Request(url, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return int(json.loads(urllib.request.urlopen(req, timeout=30).read())["result"], 16)

if __name__ == "__main__":
    print("RPC:", RPC)
    print("block:", block_number(RPC))
    print("NOTE: selectors must be filled in; run with a proper implementation")
