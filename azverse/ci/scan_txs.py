#!/usr/bin/env python3
"""AZverse on-chain history scan (keyless artifacts; API key from env only).
- full tx-selector census for both vaults (proves which entry points are used by whom)
- approval census + live allowance check for custody wallets (unprivileged pull paths)
Writes ci-out/tx_scan.json."""
import json, os, sys, urllib.request, urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)
KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
if not KEY:
    print("no ETHERSCANV2_API_KEY; writing empty scan")
    json.dump({"error": "no key"}, open(os.path.join(OUT, "tx_scan.json"), "w"))
    sys.exit(0)

RPC = os.environ.get("ARB_RPC_URL") or os.environ.get("FORK_RPC_URL") or "https://arbitrum-one-rpc.publicnode.com"
VAULTS = {"v1": "0x91Ba525861c16AA8Cd4D6974E4058cc846f42eBE", "v2": "0x949556cb8634F9a4a8504665C3d0D9d326c600b2"}
CUSTODY = ["0x03A7e58745874D49b3AcC770C40261A3ce206608", "0xdC379823A9a3A2ca9d77C33299551ecDBaBf7A41"]
SPENDERS = [
    "0x00724a470ee46c47bcb8c446236d5fbdc9b58454", "0x27117f7e48e07f9e23042931ab39fe02a62ec587",
    "0x51c8de9bda1eb4ec7915c8266233844899000000", "0x762d40cc9c95d9df39207b9e4532044718b0d363",
    "0x8786f9b8833d2def80f90ad75562f9f5783090a0", "0x96d2b02c2b393f49ef312554a4507e66a590f73a",
    "0xbd3fec0246f1a9a248a5a7c213d853865fdf3556", "0xc50005eb632e52e2d86096e5dae7b633609b348c",
    "0xd46e9950698597fc0d9f27c066512f1f3931582b", "0xe42fb8e892a833c40ba834c0d59ee55529698bc7",
    "0xf485cb0ef96af2051fde3c9627d83808cc8dc88d",
]
TOKENS = {"USDT0": "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", "USDC": "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"}
SEL = {
    "0x37b8edf4": "requestWithdraw", "0xd4e55162": "executeExpiredPendingWithdrawal",
    "0xb24c2a0a": "batchFlushWithdrawals", "0x8668fbd4": "batchTogglePendingWithdrawal",
    "0xb67be801": "rebalanceWithdraw", "0xa836d879": "batchResetWithdrawHotAmount",
    "0xf7e7aab0": "withdrawFees", "0xf2bf0f56": "toggle", "0x92af1f6b": "depositOnBehalf",
    "0xfe4b84df": "initialize", "0x4f1ef286": "upgradeToAndCall", "0x2f2ff15d": "grantRole",
    "0xd547741f": "revokeRole", "0xdee1f2af": "addToken", "0xabcd6cae": "addValidators",
}

def api(params):
    q = urllib.parse.urlencode(params)
    with urllib.request.urlopen(f"https://api.etherscan.io/v2/api?{q}&apikey={KEY}", timeout=60) as r:
        return json.load(r)

def cast(*args):
    import subprocess
    return subprocess.run(["cast", *args, "--rpc-url", RPC], capture_output=True, text=True).stdout.strip()

res = {"vaults": {}, "custody_live_allowances": {}, "custody_approval_spenders": {}}

for name, addr in VAULTS.items():
    txs, page = [], 1
    while True:
        d = api({"chainid": "42161", "module": "account", "action": "txlist", "address": addr,
                 "startblock": "0", "endblock": "999999999", "sort": "asc", "page": page, "offset": 500})
        r = d.get("result") or []
        if not isinstance(r, list) or not r:
            break
        txs.extend(r)
        if len(r) < 500:
            break
        page += 1
    import collections
    c, senders = collections.Counter(), collections.Counter()
    for t in txs:
        s = (t.get("input") or "0x")[:10]
        c[SEL.get(s, s)] += 1
        senders[t["from"]] += 1
    res["vaults"][name] = {"address": addr, "tx_count": len(txs), "by_function": dict(c), "by_sender": dict(senders)}
    print(name, "txs:", len(txs), "fns:", dict(c))

APPR = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
for owner in CUSTODY:
    d = api({"chainid": "42161", "module": "logs", "action": "getLogs", "fromBlock": "0", "toBlock": "latest",
             "topic0": APPR, "topic1": "0x" + "0" * 24 + owner[2:].lower(), "page": 1, "offset": 1000})
    logs = d.get("result") or []
    spenders = sorted({"0x" + l["topics"][2][-40:] for l in logs})
    res["custody_approval_spenders"][owner] = {"events": len(logs), "spenders": spenders}
    print(owner, "approval events:", len(logs), "spenders:", len(spenders))

for owner in CUSTODY:
    per = {}
    for tname, taddr in TOKENS.items():
        for sp in SPENDERS:
            a = cast("call", taddr, "allowance(address,address)(uint256)", owner, sp)
            if a and a != "0":
                per[f"{tname}:{sp}"] = a
    res["custody_live_allowances"][owner] = per or "ALL_ZERO"
    print(owner, "live allowances:", per or "ALL_ZERO")

json.dump(res, open(os.path.join(OUT, "tx_scan.json"), "w"), indent=1)
print("wrote", os.path.join(OUT, "tx_scan.json"))
