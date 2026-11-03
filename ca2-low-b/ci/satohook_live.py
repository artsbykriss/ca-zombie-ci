#!/usr/bin/env python3
"""SatoHook (Ethereum) live storage snapshot at a pinned block.

Read-only JSON-RPC. Writes ci-out/satohook_live.json and prints the two
load-bearing numbers: ethAt(totalMintedFair) and the permanent offset
ethCum - ethAt(totalMintedFair).
"""
import json, time, urllib.request, os
from decimal import Decimal, getcontext

getcontext().prec = 60
RPC = os.environ.get("SATO_RPC", "https://eth.drpc.org")
BLOCK = int(os.environ.get("SATO_BLOCK", "26334425"))
HOOK = "0x0000f07d2B5F1Ddf3244b8780F972f306EFd2888"
SATO = "0x829f4B62EEBE12Af653b4dD4fFc480966F7d7f09"

# keccak256 selectors (cast sig)
SEL = {
    "ethCum": "0x360e73af",
    "totalMintedFair": "0xd404154c",
    "feesAccrued": "0x94db0595",
    "curveReserveEth": "0x43d97445",
    "selfDeprecated": "0xbff6abc5",
    "poolInitialized": "0xb98ad255",
    "GENESIS_BLOCK": "0xddbfc5c6",
    "SATO_TOKEN": "0x0076d480",
    "COOLDOWN_BLOCKS": "0x54831354",
    "MAX_BUY_WEI": "0x1d1ae6c8",
    "totalSupply": "0x18160ddd",
    "balanceOf": "0x70a08231",
}


def rpc(method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body,
                                         headers={"Content-Type": "application/json",
                                                  "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=45) as r:
                d = json.load(r)
            if "error" in d:
                last = d["error"]
                time.sleep(2 + 2 * i)
                continue
            return d["result"]
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 + 2 * i)
    raise RuntimeError(f"rpc failed: {last}")


def call(to, data, block=BLOCK):
    return rpc("eth_call", [{"to": to, "data": data}, hex(block)])


def u256(hexstr):
    return int(hexstr, 16) if hexstr and hexstr != "0x" else 0


def main():
    reads = {
        "ethCum": u256(call(HOOK, SEL["ethCum"])),
        "totalMintedFair": u256(call(HOOK, SEL["totalMintedFair"])),
        "feesAccrued": u256(call(HOOK, SEL["feesAccrued"])),
        "curveReserveEth": u256(call(HOOK, SEL["curveReserveEth"])),
        "selfDeprecated": u256(call(HOOK, SEL["selfDeprecated"])),
        "poolInitialized": u256(call(HOOK, SEL["poolInitialized"])),
        "GENESIS_BLOCK": u256(call(HOOK, SEL["GENESIS_BLOCK"])),
        "SATO_TOKEN": "0x" + call(HOOK, SEL["SATO_TOKEN"])[-40:],
        "COOLDOWN_BLOCKS": u256(call(HOOK, SEL["COOLDOWN_BLOCKS"])),
        "MAX_BUY_WEI": u256(call(HOOK, SEL["MAX_BUY_WEI"])),
        "SATO_totalSupply": u256(call(SATO, SEL["totalSupply"])),
        "SATO_balanceOf_hook": u256(call(SATO, SEL["balanceOf"] + HOOK[2:].rjust(64, "0"))),
    }
    bal = u256(rpc("eth_getBalance", [HOOK, hex(BLOCK)]))

    K = Decimal(21_000_000) * Decimal(10) ** 18
    S = Decimal(500) * Decimal(10) ** 18
    T = Decimal(reads["totalMintedFair"])
    eth_at = S * (K / (K - T)).ln()
    eth_at_net = eth_at * Decimal("0.997")
    offset = Decimal(reads["ethCum"]) - eth_at
    stuck = Decimal(bal) - eth_at_net

    out = {"block": BLOCK, "hook": HOOK, "sato": SATO,
           "reads": {k: str(v) for k, v in reads.items()},
           "balance_wei": str(bal),
           "ethAt_T_wei": str(int(eth_at)),
           "ethAt_T_net_wei": str(int(eth_at_net)),
           "offset_ethCum_minus_ethAt_wei": str(int(offset)),
           "balance_minus_max_payout_wei": str(int(stuck))}
    os.makedirs("ci-out", exist_ok=True)
    with open(os.path.join("ci-out", "satohook_live.json"), "w") as f:
        json.dump(out, f, indent=1)

    print(f"block {BLOCK}")
    for k, v in reads.items():
        print(f"  {k} = {v}")
    print(f"  balance = {bal} ({Decimal(bal)/Decimal(10)**18} ETH)")
    print(f"  ethAt(T) gross = {int(eth_at)} ({eth_at/Decimal(10)**18} ETH)")
    print(f"  ethAt(T) net   = {int(eth_at_net)} ({eth_at_net/Decimal(10)**18} ETH)")
    print(f"  offset         = {int(offset)} ({offset/Decimal(10)**18} ETH)")
    print(f"  balance - max sell payout = {int(stuck)} ({stuck/Decimal(10)**18} ETH)")
    print("wrote ci-out/satohook_live.json")


if __name__ == "__main__":
    main()
