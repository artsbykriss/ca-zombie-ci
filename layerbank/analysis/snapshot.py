#!/usr/bin/env python3
"""LayerBank (Robinhood Chain 4663) live-state snapshotter.

Read-only: eth_getCode / eth_call / eth_getStorageAt + DefiLlama reference prices.
No secrets, no transactions. Writes ci-out/live-state.json.

Usage:  RH_RPC_URL=https://<rpc> python3 analysis/snapshot.py > ci-out/live-state.json
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

RPC = os.environ.get("RH_RPC_URL") or "https://4663.rpc.thirdweb.com"

POOL = "0x433e21dc2bf027910b1635653c2eb630bc7dad43"
ORACLE = "0x0e1289335e72a9e1799d691fc618656fa69f2ca1"
PROVIDER = "0x6758efc446ee8bde7670b93a6df799dffe8f8969"
ACLMGR = "0x569C94DD0e1c6Ec6E52B758054fE042C2623BE4E"

RESERVES = {
    "NVDA": "0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC",
    "SPY": "0x117cc2133c37B721F49dE2A7a74833232B3B4C0C",
    "USDG": "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168",
    "WETH": "0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73",
    "cbBTC": "0xCEC185eB182c47d1bA1EFc84e6959e18cd620Be4",
    "QQQ": "0xD5f3879160bc7c32ebb4dC785F8a4F505888de68",
    "SGOV": "0x92FD66527192E3e61d4DDd13322Aa222DE86F9B5",
    "GLD": "0xC9a981FEE1F9DEc688bb123ccDeCc63D0deBFC4e",
}
DECIMALS = {"NVDA": 18, "SPY": 18, "USDG": 6, "WETH": 18, "cbBTC": 8, "QQQ": 18, "SGOV": 18, "GLD": 18}

_id = [0]


def rpc(method, params):
    _id[0] += 1
    body = json.dumps({"jsonrpc": "2.0", "id": _id[0], "method": method, "params": params}).encode()
    last = None
    for attempt in range(6):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json",
                                                                  "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:  # 429/5xx -> back off
            last = e
            time.sleep(2 * (attempt + 1))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1)
    raise last


def call(to, data):
    r = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return r.get("result")


def pad(addr):
    return addr[2:].lower().rjust(64, "0")


def word(res, i):
    return int(res[2:][i * 64:(i + 1) * 64] or "0", 16)


def sel(sig_hex):
    return sig_hex


def main():
    head = rpc("eth_blockNumber", [])["result"]
    blk = int(head, 16)
    b = rpc("eth_getBlockByNumber", [head, False])["result"]
    ts = int(b["timestamp"], 16)

    out = {"chain": "robinhood-4663", "block": blk, "block_timestamp": ts,
           "pool": POOL, "oracle": ORACLE, "provider": PROVIDER,
           "pool_code_bytes": (len(rpc("eth_getCode", [POOL, "latest"])["result"]) // 2) - 1,
           "oracle_code_bytes": (len(rpc("eth_getCode", [ORACLE, "latest"])["result"]) // 2) - 1,
           "oracle_is_proxy": rpc("eth_getStorageAt", [ORACLE, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])["result"] != "0x" + "0" * 64,
           "pool_impl": "0x" + rpc("eth_getStorageAt", [POOL, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])["result"][-40:],
           "acl_admin": ("0x" + call(PROVIDER, "0x0e67178c")[-40:]) if call(PROVIDER, "0x0e67178c") else None,
           "base_currency_unit": int(call(ORACLE, "0x8c89b64f"), 16) if call(ORACLE, "0x8c89b64f") else None,
           "oracle_bytecode_has_latestAnswer": "50d25bcd" in rpc("eth_getCode", [ORACLE, "latest"])["result"],
           "oracle_bytecode_has_latestRoundData": "feaf968c" in rpc("eth_getCode", [ORACLE, "latest"])["result"],
           "reserves": {}, "feeds": {}}

    for sym, addr in RESERVES.items():
        raw = call(POOL, "0x35ea6a75" + pad(addr))
        cfg = int(raw[2:66], 16)
        ltv = cfg & 0xFFFF
        lt = (cfg >> 16) & 0xFFFF
        bonus = (cfg >> 32) & 0xFFFF
        dec = (cfg >> 48) & 0xFF
        flags = (cfg >> 56) & 0xFF
        aTok = "0x" + raw[2:][8 * 64 + 24:8 * 64 + 64]
        price = int(call(ORACLE, "0xb3596f07" + pad(addr)), 16)
        src = "0x" + call(ORACLE, "0x92bf2be0" + pad(addr))[-40:]
        free = int(call(addr, "0x70a08231" + pad(aTok)), 16)
        out["reserves"][sym] = {
            "asset": addr, "ltv_bps": ltv, "liq_threshold_bps": lt, "liq_bonus_bps": bonus,
            "decimals": dec, "isActive": bool(flags & 1), "isFrozen": bool(flags & 2),
            "borrowingEnabled": bool(flags & 4), "isPaused": bool(flags & 16),
            "oracle_source": src, "price_1e8": price,
            "aToken": aTok, "free_liquidity_raw": free,
            "free_liquidity_human": free / 10 ** DECIMALS[sym],
            "break_even_gap_pct": (10000 - ltv) / ltv * 100,
        }
        # feed metadata
        fcode = rpc("eth_getCode", [src, "latest"])["result"]
        agg = call(src, "0x245a7bfc")
        lrd = call(src, "0xfeaf968c")
        age = None
        if lrd:
            updatedAt = int(lrd[2:][3 * 64:3 * 64 + 64], 16)
            age = ts - updatedAt
        out["feeds"][sym] = {
            "source": src, "code_bytes": (len(fcode) // 2) - 1,
            "description": _decode_string(call(src, "0x7284e416")),
            "aggregator": ("0x" + agg[-40:]) if agg else None,
            "is_chainlink_proxy": bool(agg),
            "latestRoundData": lrd,
            "updatedAt": (int(lrd[2:][3 * 64:3 * 64 + 64], 16) if lrd else None),
            "age_seconds": age,
        }

    # DefiLlama reference prices (keyless)
    try:
        pairs = ",".join(f"robinhood:{a}" for a in RESERVES.values())
        url = f"https://coins.llama.fi/prices/current/{pairs}"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            dl = json.loads(r.read().decode())["coins"]
        out["defillama"] = {}
        for sym, addr in RESERVES.items():
            c = dl.get(f"robinhood:{addr}")
            if not c:
                continue
            real = c["price"]
            oracle = out["reserves"][sym]["price_1e8"] / 1e8
            gap = (oracle / real - 1) * 100 if real else None
            out["defillama"][sym] = {"real": real, "oracle": oracle, "gap_pct": gap,
                                     "timestamp": c.get("timestamp")}
    except Exception as e:  # noqa: BLE001
        out["defillama_error"] = str(e)

    json.dump(out, sys.stdout, indent=1)
    sys.stdout.write("\n")


def _decode_string(res):
    if not res or len(res) < 130:
        return None
    try:
        off = int(res[2:66], 16)
        ln = int(res[2 + off * 2:2 + off * 2 + 64], 16)
        data = res[2 + off * 2 + 64:2 + off * 2 + 64 + ln * 2]
        return bytes.fromhex(data).decode("utf-8", "replace")
    except Exception:  # noqa: BLE001
        return None


if __name__ == "__main__":
    main()
