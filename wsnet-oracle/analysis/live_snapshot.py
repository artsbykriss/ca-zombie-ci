#!/usr/bin/env python3
"""Live-state snapshot for the wsNET/USDG Morpho-Blue market (Robinhood Chain 4663).

Read-only: eth_call / eth_getCode / eth_blockNumber only. No transactions.
Writes JSON to stdout (ci-out/live_state.json). RPC URL from RH_RPC_URL.
"""
import json
import os
import sys
import urllib.request

RPC = os.environ.get("RH_RPC_URL", "https://robinhood.drpc.org")
BLOCK = os.environ.get("RH_BLOCK", "")

MORPHO = "0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010"
ORACLE = "0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16"
PAIRORACLE = "0x929631b33F4070D6f54477fba3FD27566567dAca"
TREASURY = "0x04822Ea321A0DEE6F40656172F29312104855d66"
SNET = "0xb773ec2C326B7f98a5a83fc098825492F020a4c7"
WSNET = "0x63C12667638f2Ae6fC6ae09B43D98Ec84a8586eA"
NET = "0xCA9c78Dd337A67F6e0077F65F5E9218719d30eDf"
USDG = "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168"
PAIR = "0x59F95461E68e0c77605299791E1449f175165B54"
STAKING = "0xB078cc304A0B264C5F3680DC0488954ACcd02E87"
MKT = "0xaa586d26a6fe62d9c0f0948fede6e2130500ac7a655587447e2d4a37e6330589"

SEL = {
    "market": "0x5c60e39a",
    "price": "0xa035b1fe",
    "twapNetUsdg": "0x10aa790e",
    "backingPerToken": "0x1521843e",
    "index": "0x2986c0e5",
    "getReserves": "0x0902f1ac",
    "lastCheckpointAt": "0x1667bcec",
    "totalSupply": "0x18160ddd",
    "balanceOf": "0x70a08231",
    "enabled": "0x238dafe0",
    "warmupEpochs": "0xa6082d5b",
    "circulatingSupply": "0x9358928b",
}


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(
        RPC, data=body, headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"}
    )
    r = json.load(urllib.request.urlopen(req, timeout=60))
    if "result" not in r:
        raise RuntimeError(f"{method} {params} -> {r}")
    return r["result"]


def call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])


def call_ok(to, data, block="latest"):
    try:
        return call(to, data, block)
    except Exception as e:  # noqa: BLE001
        return "REVERT:" + str(e)[:120]


def word(hexstr, i=0):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return int(h[i * 64 : (i + 1) * 64] or "0", 16)


def pad(addr):
    return "0" * 24 + addr[2:].lower()


def main():
    block = BLOCK if BLOCK else rpc("eth_blockNumber", [])
    if not block.startswith("0x"):
        block = hex(int(block))
    bn = int(block, 16)
    try:
        ts = int(rpc("eth_getBlockByNumber", [hex(bn), False])["timestamp"], 16)
    except Exception:  # noqa: BLE001
        ts = None

    out = {"chain": 4663, "block": bn, "timestamp": ts, "rpc_host": RPC.split("/")[2]}

    m = call(MORPHO, SEL["market"] + MKT[2:], block)
    supply, borrow = word(m, 0), word(m, 2)
    out["market"] = {
        "id": MKT,
        "lltv": "0.625e18",
        "totalSupplyAssets": supply,
        "totalBorrowAssets": borrow,
        "freeLiquidity": supply - borrow,
        "freeLiquidity_usd": round((supply - borrow) / 1e6, 2),
    }
    out["oracle"] = {
        "address": ORACLE,
        "price_raw": word(call(ORACLE, SEL["price"], block)),
        "twapNetUsdg_wad": word(call(PAIRORACLE, SEL["twapNetUsdg"], block)),
        "backingPerToken_wad": word(call(TREASURY, SEL["backingPerToken"], block)),
        "sNet_index": word(call(SNET, SEL["index"], block)),
        "lastCheckpointAt": word(call(PAIRORACLE, SEL["lastCheckpointAt"], block)),
        "guard": "one-sided: reverts only when spot < 0.85*twap; upward cap = 5*floor",
    }
    res = call(PAIR, SEL["getReserves"], block)
    r0, r1, ts_last = word(res, 0), word(res, 1), word(res, 2)
    out["pair"] = {
        "address": PAIR,
        "reserve0_usdg_6dec": r0,
        "reserve1_net_9dec": r1,
        "tsLast": ts_last,
        "spot_usdg_per_net_wad": (r0 * 10**21) // r1 if r1 else None,
        "usdg_side_usd": round(r0 / 1e6, 2),
    }
    out["tokens"] = {
        "NET": {"address": NET, "totalSupply": word(call(NET, SEL["totalSupply"], block))},
        "sNET": {
            "address": SNET,
            "totalSupply": word(call(SNET, SEL["totalSupply"], block)),
            "circulatingSupply": word(call(SNET, SEL["circulatingSupply"], block)),
        },
        "wsNET": {"address": WSNET, "totalSupply": word(call(WSNET, SEL["totalSupply"], block))},
        "USDG": {
            "address": USDG,
            "totalSupply": word(call(USDG, SEL["totalSupply"], block)),
            "morphoSingletonBalance": word(call(USDG, SEL["balanceOf"] + pad(MORPHO), block)),
        },
    }
    out["staking"] = {
        "address": STAKING,
        "enabled": bool(word(call(STAKING, SEL["enabled"], block))),
        "warmupEpochs": word(call(STAKING, SEL["warmupEpochs"], block)),
    }
    out["code"] = {
        "oracle_bytes": (len(rpc("eth_getCode", [ORACLE, block])) - 2) // 2,
        "pair_bytes": (len(rpc("eth_getCode", [PAIR, block])) - 2) // 2,
    }
    out["oracle_source_probe"] = {
        "sourcify": "https://sourcify.dev/server/v2/contract/4663/" + ORACLE,
        "file": "src/lending/LoopbackOracle.sol",
        "constants": {
            "HAIRCUT_BPS": 1000,
            "PREMIUM_CAP": 5,
            "DIVERGENCE_BPS": 1500,
            "LLTV": "0.625e18",
        },
    }
    json.dump(out, sys.stdout, indent=1)
    print()


if __name__ == "__main__":
    main()
