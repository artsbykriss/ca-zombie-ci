#!/usr/bin/env python3
"""Cross-chain Nullmask state snapshot (READ-ONLY, keyless public RPCs).

Writes ci-out/state.json. No keys, no tx, no third-party crypto dependency
(selectors are hardcoded; keccak is not needed at runtime).
"""
import json, os, urllib.request

POOL = "0xd64EF1417EB047ed0b54736a5a41F01178C391c6"
OUT = os.path.join(os.path.dirname(__file__), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)

# 4-byte selectors (from `cast sig`)
S = {
    "paused": "0x5c975abb",
    "withdrawalsPaused": "0xe9f2838e",
    "noteTreeSize": "0x9ac8862f",
    "keyRegistrySize": "0x4160de02",
    "depositFeeBps": "0xab879827",
    "withdrawalFeeBps": "0x04336bb3",
    "VIRTUAL_CHAIN_ID": "0x4b6c51fd",
    "guard": "0x7ceab3b1",
    "upgradeController": "0x87543ef6",
    "treasury": "0x61d027b3",
    "protocolFeesAccrued": "0x97e8cd4e",   # + 32-byte token word
    "tokenWhitelist": "0x753d7563",        # + 32-byte token word
    "balanceOf": "0x70a08231",             # + 32-byte account word
}
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

CHAINS = {
    "ethereum": {"rpc": "https://ethereum-rpc.publicnode.com", "native": "ETH", "price": 2342.11},
    "base": {"rpc": "https://base-rpc.publicnode.com", "native": "ETH", "price": 2342.11},
    "bsc": {"rpc": "https://bsc-rpc.publicnode.com", "native": "BNB", "price": 735.59},
}
TOKENS = {
    "ethereum": {"USDT": ("0xdAC17F958D2ee523a2206206994597C13D831ec7", 6)},
    "base": {"USDC": ("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", 6)},
    "bsc": {"USDT": ("0x55d398326f99059fF775485246999027B3197955", 18)},
}


def rpc(url, method, params):
    req = urllib.request.Request(
        url,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "nullmask-research"},
    )
    return json.loads(urllib.request.urlopen(req, timeout=40).read()).get("result")


def call(url, to, data):
    r = rpc(url, "eth_call", [{"to": to, "data": data}, "latest"])
    return None if r is None else int(r, 16)


def word(addr):
    return addr[2:].lower().rjust(64, "0")


def main():
    out = {"pool": POOL, "chains": {}, "prices": {"ETH": 2342.11, "BNB": 735.59, "source": "DefiLlama 2026-10-24"}}
    for name, cfg in CHAINS.items():
        url = cfg["rpc"]
        blk = int(rpc(url, "eth_blockNumber", []), 16)
        native = int(rpc(url, "eth_getBalance", [POOL, "latest"]), 16)
        impl = int(rpc(url, "eth_getStorageAt", [POOL, IMPL_SLOT, "latest"]), 16)
        impl_addr = "0x" + impl.to_bytes(20, "big").hex()
        code = rpc(url, "eth_getCode", [impl_addr, "latest"]) or "0x"
        rec = {
            "block": blk,
            "native_wei": str(native),
            "native": cfg["native"],
            "native_usd": round(native / 1e18 * cfg["price"], 2),
            "impl": impl_addr,
            "impl_code_bytes": (len(code) - 2) // 2,
            "paused": bool(call(url, POOL, S["paused"])),
            "withdrawalsPaused": bool(call(url, POOL, S["withdrawalsPaused"])),
            "noteTreeSize": call(url, POOL, S["noteTreeSize"]),
            "keyRegistrySize": call(url, POOL, S["keyRegistrySize"]),
            "depositFeeBps": call(url, POOL, S["depositFeeBps"]),
            "withdrawalFeeBps": call(url, POOL, S["withdrawalFeeBps"]),
            "virtualChainId": call(url, POOL, S["VIRTUAL_CHAIN_ID"]),
            "guard": "0x" + call(url, POOL, S["guard"]).to_bytes(20, "big").hex(),
            "upgradeController": "0x" + call(url, POOL, S["upgradeController"]).to_bytes(20, "big").hex(),
            "treasury": "0x" + call(url, POOL, S["treasury"]).to_bytes(20, "big").hex(),
            "protocolFeesAccruedNative": str(call(url, POOL, S["protocolFeesAccrued"] + "00" * 32)),
            "tokens": {},
            "erc20_usd": 0.0,
        }
        for sym, (addr, dec) in TOKENS[name].items():
            wl = call(url, POOL, S["tokenWhitelist"] + word(addr))
            bal = call(url, addr, S["balanceOf"] + word(POOL))
            rec["tokens"][sym] = {"address": addr, "whitelist": wl, "raw": str(bal), "amount": bal / 10**dec}
            rec["erc20_usd"] += bal / 10**dec
        rec["total_usd"] = round(rec["native_usd"] + rec["erc20_usd"], 2)
        out["chains"][name] = rec
    out["total_usd_all_chains"] = round(sum(c["total_usd"] for c in out["chains"].values()), 2)
    with open(os.path.join(OUT, "state.json"), "w") as f:
        json.dump(out, f, indent=2)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
