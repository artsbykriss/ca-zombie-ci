#!/usr/bin/env python3
"""Keyless live-state dump for the L6 Fables re-probe (CI). Public RPC only; read-only."""
import json, time, urllib.request, os

RPCS = [
    "https://rpc.mainnet.chain.robinhood.com",
    "https://robinhood-rpc.publicnode.com",
    "https://robinhood.drpc.org",
]
UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

REGISTRY = "0x159a113e012593d9b3cc63ad45e30f0467e13ef3"
OLDRAMPETH = "0x06a889870c8f83640d6816319f72e2aa579b6080"
HOOKS = {
    "FablesRamp": "0x08e52564bad99e05a694b4809f397edca417a080",
    "FablesRWA": "0x5eb87f69be00df39981622fd60a8de4b7837e080",
    "FablesRampETH": "0x594e8e6281edf2d363a0293a50004cf868e7a080",
    "FablesRWAETH": "0xca89f079af00f752bfd3c345358dc38d4d73e080",
    "FablesRampETH_OLD": OLDRAMPETH,
}
NATIVE = "0x" + "0" * 40

SEL_POOLCOUNT = "0xf525cb68"
SEL_CFR = "0x7c5e62d0"
SEL_DIST = "0xbfe10928"
SEL_PAUSED = "0xda748b10"
SEL_CFO = "0x2384b554"  # claimFeeOwed(address)

_cur = 0

def rpc(method, params, retries=6):
    global _cur
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        url = RPCS[_cur % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=body, headers=UA)
            with urllib.request.urlopen(req, timeout=25) as r:
                d = json.load(r)
            if "error" in d:
                raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            last = e
            _cur += 1
            time.sleep(0.5)
    raise last

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def word(r):
    return int(r, 16) if isinstance(r, str) and r.startswith("0x") and len(r) >= 66 else 0

out = {"rpc_blockNumber": int(rpc("eth_blockNumber", []), 16)}
out["registry_poolCount"] = word(call(REGISTRY, SEL_POOLCOUNT))
hooks = {}
for name, h in HOOKS.items():
    d = {
        "address": h,
        "eth_balance_wei": int(rpc("eth_getBalance", [h, "latest"]), 16),
        "claimFeeRecipient": "0x" + call(h, SEL_CFR)[-40:],
        "distributor": "0x" + call(h, SEL_DIST)[-40:],
        "pausedUntil": word(call(h, SEL_PAUSED)),
        "claimFeeOwed_native_wei": word(call(h, SEL_CFO + "0" * 64)),
    }
    hooks[name] = d
out["hooks"] = hooks
out["monitor_old_rampeth_zero"] = hooks["FablesRampETH_OLD"]["eth_balance_wei"] == 0

os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/l6_fables_live_state.json", "w"), indent=1)
lines = [f"block(eth_blockNumber)={out['rpc_blockNumber']}",
         f"registry poolCount={out['registry_poolCount']} (68 expected, no new pools)",
         f"MONITOR old FablesRampETH balance = {hooks['FablesRampETH_OLD']['eth_balance_wei']} wei"]
for name, d in hooks.items():
    lines.append(
        f"{name:20s} bal={d['eth_balance_wei']:>20d} potETH={d['claimFeeOwed_native_wei']:>20d} "
        f"cfr={d['claimFeeRecipient']} dist={d['distributor']} pausedUntil={d['pausedUntil']}"
    )
open("ci-out/l6_fables_live_state.txt", "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
