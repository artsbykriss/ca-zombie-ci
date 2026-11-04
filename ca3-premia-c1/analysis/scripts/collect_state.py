#!/usr/bin/env python3
"""Read-only Premia V3 C-1 state collector (Arbitrum One).

No secrets. Uses ARB_RPC_URL if set, else a keyless public endpoint.
Writes analysis/state.json. Never sends a transaction.
"""
import json
import os
import subprocess
import time
import urllib.request


def keccak(data: bytes) -> bytes:
    """Keccak-256 via the locally installed Foundry `cast` (no pip deps)."""
    out = subprocess.run(["cast", "keccak", "0x" + data.hex()], capture_output=True, text=True)
    return bytes.fromhex(out.stdout.strip()[2:])

RPC = os.environ.get("ARB_RPC_URL") or "https://arb1.arbitrum.io/rpc"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "state.json")

FACTORY = "0xAE4fB6622F25f397587F11638dA8CE88C27b5645"
REGISTRY = "0xBB7456a7661f46ebA8C638cb8CC2Ac181f45F3b9"
STORAGE_BASE = int(keccak(b"premia.contracts.storage.UnderwriterVaultStorage").hex(), 16)

# (name, vault, asset, decimals, isCall, [(maturity, [strikes])])
VAULTS = [
    ("pSV-WBTC/USDCe-C", "0x45dF5EA836A15B561937Ae8373ab9eE984aea531", "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f", 8, True,
     [(1793952000, [78000, 79000, 80000])]),
    ("pSV-WETH/USDCe-C", "0xbae43c546DFADC69576aE73C68e0694A54F08e1B", "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", 18, True,
     [(1793952000, [2200, 2300, 2400]), (1794556800, [2300, 2400])]),
    ("pSV-WETH/USDCe-P", "0xD46993F25D298ebbCD31E941156C66f7e628A52a", "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", 6, False,
     [(1793952000, [2100, 2200, 2300]), (1795161600, [2100, 2200, 2300])]),
    ("pSV-WBTC/USDCe-P", "0x6A1FC0E1c60BA6564CDe4910A425F1F1a1d18C1F", "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", 6, False,
     [(1793952000, [76000, 77000, 78000])]),
    ("pSV-ARB/USDCe-C", "0xDC631d88dbB5eb39f5c4Bf8B4e5298d098912fFf", "0x912CE59144191C1204E64559FE8253a0e49E6548", 18, True,
     [(1793952000, [0.16, 0.17, 0.18]), (1794556800, [0.16])]),
    ("pSV-ARB/USDCe-P", "0xBe3E229319f86F5EE96EE1Dc0B6D55e8b68a439e", "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", 6, False,
     [(1793952000, [0.15, 0.16, 0.17]), (1794556800, [0.15])]),
]

_sel_cache = {}


def sel(sig):
    if sig not in _sel_cache:
        _sel_cache[sig] = "0x" + keccak(sig.encode()).hex()[:8]
    return _sel_cache[sig]


def word(x):
    if isinstance(x, str):
        return x.lower().replace("0x", "").rjust(64, "0")[-64:]
    return format(int(x), "064x")


def rpc(method, params):
    for attempt in range(5):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read())
            if "result" in d:
                return d["result"]
            if attempt == 4:
                raise RuntimeError(d)
        except Exception:
            if attempt == 4:
                raise
        time.sleep(1.5)
    return None


def eth_call(to, data, block):
    return rpc("eth_call", [{"to": to, "data": data}, hex(block)])


def get_storage(addr, slot, block):
    return int(rpc("eth_getStorageAt", [addr, hex(slot), hex(block)]), 16)


def u_call(to, sig, args, block):
    data = sel(sig) + "".join(word(a) for a in args)
    try:
        r = eth_call(to, data, block)
    except Exception as e:
        raise RuntimeError(f"u_call {sig} to {to} args={args}: {e}")

    return int(r, 16) if r and r != "0x" else 0


def a_call(to, sig, args, block):
    data = sel(sig) + "".join(word(a) for a in args)
    try:
        r = eth_call(to, data, block)
    except Exception as e:
        raise RuntimeError(f"a_call {sig} to {to} args={args}: {e}")

    return "0x" + r[-40:] if r and len(r) >= 42 else None


def pool_address(base, quote, oracle, strike18, maturity, is_call, block):
    data = sel("getPoolAddress((address,address,address,uint256,uint256,bool))") + "".join(
        [word(base), word(quote), word(oracle), word(strike18), word(maturity), word(1 if is_call else 0)]
    )
    r = eth_call(FACTORY, data, block)
    if not r or r == "0x":
        return None, None
    body = r[2:]
    addr = "0x" + body[24:64]
    deployed = int(body[64:128], 16) == 1
    return addr, deployed


def main():
    head = int(rpc("eth_blockNumber", []), 16)
    ts = int(rpc("eth_getBlockByNumber", [hex(head), False])["timestamp"], 16)
    out = {"chain": "arbitrum", "chain_id": 42161, "block": head, "block_timestamp": ts, "vaults": []}

    for name, vault, asset, dec, is_call, listings in VAULTS:
        s0 = get_storage(vault, STORAGE_BASE + 0, head)
        s1 = get_storage(vault, STORAGE_BASE + 1, head)
        s2 = get_storage(vault, STORAGE_BASE + 2, head)
        base = "0x" + format(s0, "040x")[-40:]
        quote = "0x" + format(s1, "040x")[-40:]
        oracle = "0x" + format(s2, "040x")[-40:]
        base_dec = (s1 >> 160) & 0xFF
        quote_dec = (s1 >> 168) & 0xFF
        total_assets = get_storage(vault, STORAGE_BASE + 3, head) / 1e18
        total_locked = get_storage(vault, STORAGE_BASE + 4, head) / 1e18
        min_maturity = get_storage(vault, STORAGE_BASE + 14, head)
        max_maturity = get_storage(vault, STORAGE_BASE + 15, head)
        spread = get_storage(vault, STORAGE_BASE + 20, head) / 1e18
        real_balance = u_call(asset, "balanceOf(address)", [vault], head) / 10**dec
        available = total_assets - total_locked - spread

        v = {
            "name": name,
            "vault": vault,
            "asset": asset,
            "asset_decimals": dec,
            "is_call": is_call,
            "implementation": a_call(vault, "getImplementation()", [], head),
            "totalAssets": total_assets,
            "totalLockedAssets": total_locked,
            "totalLockedSpread": spread,
            "available": available,
            "minMaturity": min_maturity,
            "maxMaturity": max_maturity,
            "real_balance": real_balance,
            "positions": [],
        }

        for maturity, strikes in listings:
            inner_base = int.from_bytes(
                keccak(b"".join(int(x).to_bytes(32, "big") for x in [maturity, STORAGE_BASE + 19])), "big"
            )
            for strike in strikes:
                strike18 = int(round(strike * 10**18))
                size_slot = int.from_bytes(
                    keccak(b"".join(int(x).to_bytes(32, "big") for x in [strike18, inner_base])), "big"
                )
                size = get_storage(vault, size_slot, head) / 10**18
                pool, deployed = pool_address(base, quote, oracle, strike18, maturity, is_call, head)
                short = 0
                pool_bal = 0
                if pool and deployed:
                    short = u_call(pool, "balanceOf(address,uint256)", [vault, 0], head) / 10**18
                    pool_bal = u_call(asset, "balanceOf(address)", [pool], head) / 10**dec
                collateral18 = size if is_call else size * strike
                actual18 = short if is_call else short * strike
                collateral = collateral18
                actual_collateral = actual18
                v["positions"].append(
                    {
                        "maturity": maturity,
                        "strike": strike,
                        "positionSize": size,
                        "pool": pool,
                        "isDeployed": deployed,
                        "vaultShort": short,
                        "poolTokenBalance": pool_bal,
                        "collateral_from_positionSize_token": collateral,
                        "collateral_from_actual_short_token": actual_collateral,
                        "backed_pct": (100.0 * pool_bal / actual_collateral) if actual_collateral else None,
                    }
                )
        out["vaults"].append(v)

    # per-vault aggregates
    for v in out["vaults"]:
        v["sum_actual_collateral_token"] = sum(p["collateral_from_actual_short_token"] for p in v["positions"])
        v["sum_pool_cash_token"] = sum(p["poolTokenBalance"] for p in v["positions"])
        v["unbacked_token"] = v["sum_actual_collateral_token"] - v["sum_pool_cash_token"]

    with open(OUT, "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
