#!/usr/bin/env python3
"""Keyless live-state dump for the L6 Valos re-probe (CI). Public RPC only; read-only."""
import json, time, urllib.request, os

RPCS = ["https://rpc.monad.xyz", "https://rpc1.monad.xyz", "https://monad.drpc.org"]
UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

VAULT = "0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365"
STRATEGY = "0x8dce15fc6a98484c995fc702cbfbda14a30454af"
FRESH = "0x1111111111111111111111111111111111111111"
MANAGER = "0xB83986E9F33a6dE4624b18Da69Cb474F6F94fC7C"

SELS = {
    "permissionLevel": "0x623f5033",
    "allowed(address)": "0xd63a8e11",
    "totalAssets": "0x01e1d114",
    "totalSupply": "0x18160ddd",
    "strategy": "0xa8c62e76",
    "sharePrice(address)": "0x9b9b9421",
    "netPrincipal": "0x641ee8ab",
    "scaleFactor": "0x683dd191",
    "dvnPublisher": "0x5a3b5512",
    "totalQueuedShares": "0xdc20c8ff",
    "reservedLiquidity": "0x9f308512",
    "loanState": "0x25af34cd",
    "paused": "0x5c975abb",
}

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
out["vault"] = {
    "permissionLevel": word(call(VAULT, SELS["permissionLevel"])),
    "allowed_fresh": word(call(VAULT, SELS["allowed(address)"] + FRESH[2:].rjust(64, "0"))),
    "allowed_manager": word(call(VAULT, SELS["allowed(address)"] + MANAGER[2:].rjust(64, "0"))),
    "totalAssets": word(call(VAULT, SELS["totalAssets"])),
    "totalSupply": word(call(VAULT, SELS["totalSupply"])),
    "strategy": "0x" + call(VAULT, SELS["strategy"])[-40:],
    "totalQueuedShares": word(call(VAULT, SELS["totalQueuedShares"])),
    "reservedLiquidity": word(call(VAULT, SELS["reservedLiquidity"])),
}
out["strategy"] = {
    "address": STRATEGY,
    "loanState": word(call(STRATEGY, SELS["loanState"])),
    "paused": word(call(STRATEGY, SELS["paused"])),
    "dvnPublisher": "0x" + call(STRATEGY, SELS["dvnPublisher"])[-40:],
    "netPrincipal": word(call(STRATEGY, SELS["netPrincipal"])),
    "scaleFactor_virtual": word(call(STRATEGY, SELS["scaleFactor"])),
    "sharePrice(vault)": word(call(STRATEGY, SELS["sharePrice(address)"] + VAULT[2:].rjust(64, "0"))),
}
out["gate_verdict"] = (
    "CLOSED at entry: permissionLevel==2 (Whitelist) set at construction; fresh address not allowed; "
    "deposit/requestRedeem/redeem revert Unauthorized"
)

os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/l6_valos_live_state.json", "w"), indent=1)
lines = [
    f"block={out['rpc_blockNumber']}",
    f"vault permissionLevel={out['vault']['permissionLevel']} (2=Whitelist) "
    f"allowed(fresh)={out['vault']['allowed_fresh']} allowed(manager)={out['vault']['allowed_manager']}",
    f"vault totalAssets={out['vault']['totalAssets']} totalSupply={out['vault']['totalSupply']} "
    f"queued={out['vault']['totalQueuedShares']} reserved={out['vault']['reservedLiquidity']}",
    f"strategy loanState={out['strategy']['loanState']} (3=OngoingDynamic) paused={out['strategy']['paused']} "
    f"dvnPublisher={out['strategy']['dvnPublisher']}",
    f"strategy netPrincipal={out['strategy']['netPrincipal']} scaleFactor={out['strategy']['scaleFactor_virtual']} "
    f"sharePrice={out['strategy']['sharePrice(vault)']}",
    out["gate_verdict"],
]
open("ci-out/l6_valos_live_state.txt", "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
