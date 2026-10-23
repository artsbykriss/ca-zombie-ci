#!/usr/bin/env python3
"""Read-only live-state re-read for shMonad (Monad 143). Keyless public RPC; no keys, no txs.

Emits a JSON blob to stdout (CI writes it to ci-out/live-state.json).
Selectors are keccak(sig)[:4]; they are re-derivable with `cast sig "<sig>"`.
"""
import json
import os
import time
import urllib.request

RPC = os.environ.get("SHMONAD_RPC", "https://rpc.monad.xyz")
PROXY = os.environ.get("SHMONAD_PROXY", "0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c")
IMPL = os.environ.get("SHMONAD_IMPL", "0x8Ee4FF5FF50198dcbB7B882A0781F42724Dd095f")

MON_PRICE = 0.0217534  # DefiLlama coingecko:monad, 2026-10-23


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(
        RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"}
    )
    last = None
    for _ in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.load(r)
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:  # noqa: BLE001
            last = str(e)
        time.sleep(2)
    raise RuntimeError(f"rpc {method} failed: {last}")


def call(data, block="latest"):
    return rpc("eth_call", [{"to": PROXY, "data": data}, block])


def words(hexstr):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return [int(h[i:i + 64], 16) for i in range(0, len(h), 64)]


def main():
    blk = int(rpc("eth_blockNumber", []), 16)
    b = hex(blk)

    out = {"chain": "monad", "chain_id": 143, "block": blk, "proxy": PROXY, "implementation": IMPL,
           "mon_price_usd": MON_PRICE}
    out["proxy_code_size"] = len(rpc("eth_getCode", [PROXY, b])[2:]) // 2
    out["impl_code_size"] = len(rpc("eth_getCode", [IMPL, b])[2:]) // 2
    out["eip1967_impl_slot"] = "0x" + rpc(
        "eth_getStorageAt",
        [PROXY, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", b])[26:]
    out["eip1967_admin_slot"] = "0x" + rpc(
        "eth_getStorageAt",
        [PROXY, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103", b])[26:]

    def one(sel, args=""):
        return words(call(sel + args, b))

    total_assets = one("0x01e1d114")[0]              # totalAssets()
    total_supply = one("0x18160ddd")[0]              # totalSupply()
    liab = one("0x79251e7e")                         # globalLiabilities()
    wc = one("0x934c85d7")                           # getWorkingCapital()
    ap = one("0xe65f8087")                           # getAtomicPoolUtilization()
    gs = one("0x424567eb", "0" * 64)                 # getGlobalStatus(0)
    admin = one("0x2c45d5dc")                        # getAdminValues()

    out["total_assets_mon"] = total_assets / 1e18
    out["total_assets_usd"] = total_assets / 1e18 * MON_PRICE
    out["total_supply_shmon"] = total_supply / 1e18
    out["share_rate_mon_per_shmon"] = total_assets / total_supply
    out["rewards_payable_mon"] = liab[0] / 1e18
    out["redemptions_payable_mon"] = liab[1] / 1e18
    out["total_zero_yield_payable_mon"] = liab[2] / 1e18
    out["staked_amount_mon"] = wc[0] / 1e18
    out["reserved_amount_mon"] = wc[1] / 1e18
    out["atomic_utilized_mon"] = ap[0] / 1e18
    out["atomic_allocated_mon"] = ap[1] / 1e18
    out["atomic_available_mon"] = ap[2] / 1e18
    out["global_status_frozen_closed"] = [bool(gs[0]), bool(gs[1])]
    out["internal_epoch"] = admin[0]
    out["target_liquidity_pct_bps"] = admin[1]
    out["staking_commission_bps"] = admin[3]
    out["boost_commission_bps"] = admin[4]
    out["native_balance_mon"] = int(rpc("eth_getBalance", [PROXY, b]), 16) / 1e18
    out["current_unstake_fee_rate_ray"] = one("0x7710d4ff")[0]

    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
