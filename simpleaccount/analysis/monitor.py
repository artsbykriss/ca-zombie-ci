#!/usr/bin/env python3
"""SimpleAccount factory re-arm monitor (Arbitrum One) — READ-ONLY.

Watches the exact re-arm condition for ZH4-PASS3 P3-03:

    RE-ARM  ==  any of the 1,036 factory-created SimpleAccount proxies becomes
                funded with ANY value (native ETH or ERC-4337 EntryPoint deposit),
                OR the factory deploys a NEW account (nonce != 2074).

Because `SimpleAccount.setGuardian(address)` is unauthenticated and
`executeRecovery(address)` applies the new owner instantly (no period/timelock),
the FIRST funded account is drainable by anyone in 2 transactions.

Usage:
    python3 analysis/monitor.py            # one check, exit 1 if re-armed
    python3 analysis/monitor.py --watch    # loop every 300 s

ERC-20 coverage is NOT re-scanned here (2,073 Etherscan calls); the full transfer
history proof in token-hits.json shows no ERC-20 has ever touched these addresses,
so a fresh ERC-20 inflow would also require a fresh inbound Transfer. Run
ci/census-ci.py for the blue-chip + NFT census.

No secrets are written. Uses ARB_RPC_URL if set, else public Arbitrum RPCs.
"""
import json, os, sys, time, urllib.request

FACTORY = "0x47C705EAe895BfF833d95a9D2A0Daa31B25d2885"
ENTRYPOINT = "0x0000000071727De22E5E9d8BAf0edAc6f37da032"
BASELINE_NONCE = 2074          # 1 impl (ctor) + 2073 create2 accounts; frozen since 2025-08-29
HERE = os.path.dirname(os.path.abspath(__file__))
RPCS = [u for u in [os.environ.get("ARB_RPC_URL", ""),
                    "https://arb1.arbitrum.io/rpc",
                    "https://arbitrum.drpc.org"] if u]
_rpc = [0]


def rpc_batch(calls):
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
               for i, (m, p) in enumerate(calls)]
    req = urllib.request.Request(RPCS[_rpc[0] % len(RPCS)], data=json.dumps(payload).encode(),
                                 headers={"content-type": "application/json", "user-agent": "sa-monitor/1"})
    with urllib.request.urlopen(req, timeout=90) as r:
        out = json.load(r)
    by_id = {o["id"]: o.get("result") for o in out}
    return [by_id[i] for i in range(len(calls))]


def rpc1(method, params):
    return rpc_batch([(method, params)])[0]


def main():
    code = json.load(open(os.path.join(HERE, "census-code.json")))
    accts = sorted(json.load(open(os.path.join(HERE, "census.json")))["contracts"])
    proxies = [a for a in accts if code.get(a) == 130]

    block = int(rpc1("eth_blockNumber", []), 16)
    nonce = int(rpc1("eth_getTransactionCount", [FACTORY, "latest"]), 16)

    hits = []
    for i in range(0, len(proxies), 50):
        part = proxies[i:i + 50]
        vals = rpc_batch([("eth_getBalance", [a, "latest"]) for a in part])
        deps = rpc_batch([("eth_call", [{"to": ENTRYPOINT, "data": "0x70a08231" + a[2:].rjust(64, "0")},
                                         "latest"]) for a in part])
        for a, ev, dv in zip(part, vals, deps):
            eth = int(ev, 16) if ev else 0
            dep = int(dv, 16) if dv and dv != "0x" else 0
            if eth or dep:
                hits.append({"account": a, "eth_wei": eth, "entrypoint_deposit": dep})

    armed = bool(hits) or nonce != BASELINE_NONCE
    print(json.dumps({"block": block, "factory_nonce": nonce, "baseline_nonce": BASELINE_NONCE,
                      "accounts_checked": len(proxies), "funded": hits[:20],
                      "new_deployments": nonce - BASELINE_NONCE, "RE_ARMED": armed}, indent=1))
    return 1 if armed else 0


if __name__ == "__main__":
    if "--watch" in sys.argv:
        while True:
            if main():
                sys.exit(1)
            time.sleep(300)
    sys.exit(main())
