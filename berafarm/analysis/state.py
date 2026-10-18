#!/usr/bin/env python3
"""BeraFarm live-state reader (read-only, keyless public RPC)."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/berafarm/analysis")
from rpc import block_number, eth_call, get_code, impl_slot, rpc  # noqa: E402
from eth_abi import encode as abi_encode, decode as abi_decode  # noqa: E402

A = "/home/heisenberg/CA/berafarm/analysis/"


def load_abi(name):
    return json.load(open(A + "abi_" + name + ".json"))


ABIS = {n: load_abi(n) for n in
        ["HubStrategyKodiakIsland", "KodiakSwapController", "PriceOracle", "ProtocolRegistry",
         "StrategyManager", "TrancheVaultFixed", "VaultManagerConfig"]}


def sig_of(abi, name):
    for x in abi:
        if x.get("type") == "function" and x.get("name") == name:
            return name + "(" + ",".join(i["type"] for i in x["inputs"]) + ")", x
    raise KeyError(name)


def call(contract, abi, fn, args=(), blk="latest"):
    sig, item = sig_of(abi, fn)
    import hashlib
    sel = hashlib.sha3_256(sig.encode()).hexdigest()[:8]
    data = "0x" + sel
    if args:
        data += abi_encode([i["type"] for i in item["inputs"]], args).hex()
    out = eth_call(contract, data, blk)
    types = [o["type"] for o in item["outputs"]]
    if not types:
        return None
    return abi_decode(types, bytes.fromhex(out[2:])) if out and out != "0x" else None


def f(x):
    return x / 1e18


VAULTS = {
    "vault0_BUSD-HONEY": "0x4a3c8fdd55017773fee33de4aa7e12dd60b0a054",
    "vault1_WBERA": "0xeb9ce8e12898beb918a7e36a1c30ee094ebcba0a",
    "vault2_undoc": "0xb1e53ccf6e39d61df3ae3deb1af0057c96aeba96",
    "vault3_undoc": "0xea20a9d1b464fff7c8a6a9039c3cf94f0a09471d",
}
STRAT = "0x1ce23321a72f2dae96809cc6192f053a7ad5d8e4"
SWAPCTL = "0x1cac0625ee3a4679dce7f9dc921ecfdd5c378987"
MANAGER0 = "0x9546b34291393fb247db7d4c677f1394d4bbe0dd"
REGISTRY = "0x0c5ab414845386758c50e7a5e08b59964a02f2bd"
ORACLE = "0xeb2cc2df8698250fb7fb6f310cbca6b3266e3b80"
ISLAND = "0xe5a2ab5d2fb268e5ff43a5564e44c3309609aff9"
HUBVAULT = "0x75da1d58a8d97f7b626224e7e71fa44db13689f2"
HONEY = "0xfcbd14dc51f0a4d49d5e53c2e0950e0bc26d0dce"
USDE = "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34"
WBERA = "0x6969696969696969696969696969696969696969"

VAULT_ABI = ABIS["TrancheVaultFixed"]
CFG_ABI = ABIS["VaultManagerConfig"]
MGR_ABI = ABIS["StrategyManager"]
STRAT_ABI = ABIS["HubStrategyKodiakIsland"]
REG_ABI = ABIS["ProtocolRegistry"]


def erc20(addr, fn, blk="latest"):
    if fn == "balanceOf":
        sig, out = "balanceOf(address)", ["uint256"]
        data = "0x70a08231" + abi_encode(["address"], [addr]).hex()
    elif fn == "totalSupply":
        data, out = "0x18160ddd", ["uint256"]
    elif fn == "decimals":
        data, out = "0x313ce567", ["uint8"]
    else:
        raise KeyError(fn)
    r = rpc("eth_call", [{"to": addr if fn != "balanceOf" else None, "data": data}, "latest"])
    return r


def main():
    blk = block_number()
    print("BLOCK", blk)
    out = {"block": blk}

    # --- global state
    try:
        print("protocol paused:", call(REGISTRY, REG_ABI, "getProtocolState"))
    except Exception as e:
        print("protocol state err", e)

    # --- vaults
    for name, v in VAULTS.items():
        try:
            cur = call(v, VAULT_ABI, "currency")
            cfg = call(v, VAULT_ABI, "vaultManagerConfig")
            mgr = call(v, VAULT_ABI, "strategyManager")
            s_sup = call(v, VAULT_ABI, "seniorToken")
            j_sup = call(v, VAULT_ABI, "juniorToken")
            paused_dep = call(v, VAULT_ABI, "depositsPaused") if any(
                x.get("name") == "depositsPaused" for x in VAULT_ABI) else None
            print(f"\n== {name} {v}\n currency={cur} cfg={cfg} mgr={mgr} senior={s_sup} junior={j_sup} depositsPaused={paused_dep}")
            info = call(v, VAULT_ABI, "currentTrancheInformation")
            print(" currentTrancheInformation:", [str(x) for x in info])
            if cfg:
                print(" cfg.isWhitelistedVault:", call(cfg, CFG_ABI, "isWhitelistedVault"))
                for fn in ["getVaultSlippage", "getVaultSwapSlippage", "getVaultLpSlippage"]:
                    try:
                        print(" cfg." + fn, call(cfg, CFG_ABI, fn))
                    except Exception:
                        pass
            for tok, label in ((s_sup, "senior"), (j_sup, "junior")):
                if tok:
                    b = erc20(tok, "balanceOf")
                    print(f" {label} supply", int(erc20(None, "totalSupply") if False else call(tok, json.loads('[{"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]'), "totalSupply"), 16) / 1e18 if False else "")
        except Exception as e:
            print(name, "ERR", type(e).__name__, str(e)[:200])

    # --- manager0
    print("\n== manager0", MANAGER0)
    for fn in ["currency", "strategyCount", "dustStrategy"]:
        try:
            print(" ", fn, call(MANAGER0, MGR_ABI, fn))
        except Exception as e:
            print(" ", fn, "ERR", str(e)[:120])
    try:
        si = call(MANAGER0, MGR_ABI, "getStrategyInformation")
        print(" strategies:", si)
    except Exception as e:
        print(" strategies ERR", str(e)[:200])

    # --- strategy
    print("\n== strategy", STRAT)
    for fn in ["protocolRegistry", "baseToken", "island", "hubVault", "strategyManager", "fee",
               "rewardIntermediaryToken", "getTokenBalance", "getUnderlyingBalance"]:
        try:
            print(" ", fn, call(STRAT, STRAT_ABI, fn))
        except Exception as e:
            print(" ", fn, "ERR", str(e)[:120])

    # --- island
    print("\n== island", ISLAND)
    isl_sig = '[{"inputs":[],"name":"paused","outputs":[{"name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"token0","outputs":[{"name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"token1","outputs":[{"name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getUnderlyingBalances","outputs":[{"name":"amount0Current","type":"uint256"},{"name":"amount1Current","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pool","outputs":[{"name":"","type":"address"}],"stateMutability":"view","type":"function"}]'
    isl = json.loads(isl_sig)
    for fn in ["paused", "totalSupply", "token0", "token1", "getUnderlyingBalances", "pool"]:
        try:
            print(" ", fn, call(ISLAND, isl, fn))
        except Exception as e:
            print(" ", fn, "ERR", str(e)[:120])

    # --- tokens
    print("\n== HONEY bal vault0", int(rpc("eth_call", [{"to": HONEY, "data": "0x70a08231" + abi_encode(["address"], [VAULTS["vault0_BUSD-HONEY"]]).hex()}, "latest"]), 16) / 1e18)
    print("== gauge shares strategy", call(HUBVAULT, STRAT_ABI, "balanceOf", (STRAT,)))

    json.dump(out, open(A + "live_state.json", "w"), indent=1)


if __name__ == "__main__":
    main()
