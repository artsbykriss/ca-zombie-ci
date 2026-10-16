#!/usr/bin/env python3
"""Keyless live-state dump for the Fables Z3-H13 probe (runs in CI; no secrets, public RPC only).

Writes ci-out/live_state.json + ci-out/live_state.txt. Read-only.
"""
import json
import os
import urllib.request

RPCS = [
    "https://rpc.mainnet.chain.robinhood.com",
    "https://robinhood-rpc.publicnode.com",
    "https://robinhood.drpc.org",
]
UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

REGISTRY = "0x159a113e012593d9b3cc63ad45e30f0467e13ef3"
PM = "0x8366a39cc670b4001a1121b8f6a443a643e40951"
AM = "0xa362d98b33a7bb5b5e2180a05f995a70fb404f30"
HOOKS = {
    "FablesRamp": "0x08e52564bad99e05a694b4809f397edca417a080",
    "FablesRWA": "0x5eb87f69be00df39981622fd60a8de4b7837e080",
    "FablesRampETH": "0x594e8e6281edf2d363a0293a50004cf868e7a080",
    "FablesRWAETH": "0xca89f079af00f752bfd3c345358dc38d4d73e080",
    "FablesRampETH_OLD": "0x06a889870c8f83640d6816319f72e2aa579b6080",
}
USDG = "0x5fc5360d0400a0fd4f2af552add042d716f1d168"
NATIVE = "0x0000000000000000000000000000000000000000"

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
        except Exception as e:  # noqa: BLE001 - failover
            last = e
            _cur += 1
    raise last


def sel(sig):
    import hashlib

    # tiny keccak (only used for a handful of selectors)
    return "0x" + _keccak(sig.encode()).hex()[:8]


def _keccak(data):
    RC = [
        0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
        0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
        0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
        0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
        0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
        0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
    ]
    R = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]

    def rol(x, n):
        return ((x << n) | (x >> (64 - n))) & 0xFFFFFFFFFFFFFFFF

    rate = 136
    data = bytearray(data)
    data.append(0x01)
    while len(data) % rate != 0:
        data.append(0)
    data[-1] |= 0x80
    S = [[0] * 5 for _ in range(5)]
    for off in range(0, len(data), rate):
        blk = data[off:off + rate]
        for i in range(rate // 8):
            S[i % 5][i // 5] ^= int.from_bytes(blk[i * 8:(i + 1) * 8], "little")
        for rnd in range(24):
            C = [S[x][0] ^ S[x][1] ^ S[x][2] ^ S[x][3] ^ S[x][4] for x in range(5)]
            D = [C[(x - 1) % 5] ^ rol(C[(x + 1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    S[x][y] ^= D[x]
            B = [[0] * 5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2 * x + 3 * y) % 5] = rol(S[x][y], R[x][y])
            for x in range(5):
                for y in range(5):
                    S[x][y] = B[x][y] ^ ((~B[(x + 1) % 5][y]) & B[(x + 2) % 5][y])
            S[0][0] ^= RC[rnd]
    return b"".join(S[x][y].to_bytes(8, "little") for y in range(5) for x in range(5))[:32]


def call(to, data, block="latest"):
    r = rpc("eth_call", [{"to": to, "data": data}, block])
    return r


def word(r):
    if not r or r == "0x":
        return 0
    return int(r[2:].rjust(64, "0")[:64], 16)


def addr(r):
    if not r or r == "0x":
        return None
    return "0x" + r[2:].rjust(64, "0")[-40:]


def main():
    out = {"rpc_used": RPCS[_cur % len(RPCS)]}
    out["block_number_eth_blockNumber"] = int(rpc("eth_blockNumber", []), 16)
    blk = rpc("eth_getBlockByNumber", ["latest", False])
    out["latest_header_number"] = int(blk["number"], 16)
    out["latest_header_hash"] = blk["hash"]
    out["latest_timestamp"] = int(blk["timestamp"], 16)

    raw = call(REGISTRY, sel("allPools()"))
    h = raw[2:]
    words = [h[i:i + 64] for i in range(0, len(h), 64)]
    off = int(words[0], 16) // 32
    n = int(words[off], 16)
    out["registry_pool_count"] = n
    hook_counts = {}
    for i in range(n):
        base = off + 1 + i * 7
        hooks = "0x" + words[base + 4][24:]
        hook_counts[hooks.lower()] = hook_counts.get(hooks.lower(), 0) + 1
    out["pools_per_hook"] = hook_counts

    hooks_state = {}
    for name, h in HOOKS.items():
        st = {}
        st["native_balance_wei"] = int(rpc("eth_getBalance", [h, "latest"]), 16)
        st["distributor"] = addr(call(h, sel("distributor()")))
        st["claimFeeRecipient"] = addr(call(h, sel("claimFeeRecipient()")))
        st["ffFeeSink"] = addr(call(h, sel("ffFeeSink()")))
        st["ballotGate"] = addr(call(h, sel("ballotGate()")))
        st["pausedUntil"] = word(call(h, sel("pausedUntil()")))
        st["claimFeeOwed_USDG"] = word(call(h, sel("claimFeeOwed(address)") + USDG[2:].rjust(64, "0")))
        st["claimFeeOwed_native"] = word(call(h, sel("claimFeeOwed(address)") + "0" * 64))
        st["distributorOwed_USDG"] = word(call(h, sel("distributorOwed(address)") + USDG[2:].rjust(64, "0")))
        st["distributorOwed_native"] = word(call(h, sel("distributorOwed(address)") + "0" * 64))
        # hook ERC-6909 claims for USDG and native (PoolManager.balanceOf)
        st["pm_claims_USDG"] = word(
            call(PM, sel("balanceOf(address,uint256)") + h[2:].rjust(64, "0") + USDG[2:].rjust(64, "0"))
        )
        st["pm_claims_native"] = word(
            call(PM, sel("balanceOf(address,uint256)") + h[2:].rjust(64, "0") + "0" * 64)
        )
        st["code_bytes"] = (len(rpc("eth_getCode", [h, "latest"])) - 2) // 2
        hooks_state[name] = st
    out["hooks"] = hooks_state

    am = {}
    for role in [0, 1, 2, 4, 9]:
        am[f"role_{role}_holders_note"] = "see analysis/am_role_sweep.json"
    out["access_manager"] = {
        "address": AM,
        "expiration": word(call(AM, sel("expiration()"))),
        "minSetback": word(call(AM, sel("minSetback()"))),
        "targets_closed": {
            name: bool(word(call(AM, sel("isTargetClosed(address)") + h[2:].rjust(64, "0"))))
            for name, h in HOOKS.items()
        },
    }

    os.makedirs("ci-out", exist_ok=True)
    with open("ci-out/live_state.json", "w") as f:
        json.dump(out, f, indent=1)

    lines = [f"block(eth_blockNumber)={out['block_number_eth_blockNumber']} header={out['latest_header_number']} hash={out['latest_header_hash']}"]
    lines.append(f"registry pools={n} per-hook={hook_counts}")
    for name, st in hooks_state.items():
        lines.append(
            f"{name} {HOOKS[name]} code={st['code_bytes']}B native={st['native_balance_wei']} wei "
            f"distributor={st['distributor']} claimFeeRecipient={st['claimFeeRecipient']} "
            f"ballotGate={st['ballotGate']} pausedUntil={st['pausedUntil']} "
            f"cfo[USDG]={st['claimFeeOwed_USDG']} cfo[native]={st['claimFeeOwed_native']} "
            f"do[USDG]={st['distributorOwed_USDG']} claims[USDG]={st['pm_claims_USDG']}"
        )
    with open("ci-out/live_state.txt", "w") as f:
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
