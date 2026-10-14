#!/usr/bin/env python3
"""Era: dist() on cTokens, whitelistedLiquidator, distributor balances, ZK/USDCz feeds.
Read-only. Writes analysis/era-dist.json (no secrets)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
ORACLE = "0x1d54DD49218333125C858c0239bbdA424db55C43"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH": "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC": "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT": "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK": "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDCz": "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
SLOTS_ZK = "0x9a2c981e05a1c8412d0647b8db3a4ae21f6fe9c90e6bb2fb4ef9a51a4998fac0"
SLOTS_USDCZ = "0xc8e48ed524133bd029ecdac5e2e22e3105420120c2e918e40c82fda4cbac36be"

def main():
    rpc = RPC(default_urls("era"), "era")
    block = rpc.block_number()
    out = {"chain": "era", "block": block}

    # dist() per cToken + whitelistedLiquidator + comptroller extras
    calls, keys = [], []
    for n, m in MARKETS.items():
        calls.append((m, calldata("dist()", (), ()))); keys.append(("dist", n))
        calls.append((m, calldata("whitelistedLiquidator()", (), ()))); keys.append(("wl_liq", n))
    for sig in ["protocolSeizeShareMantissa()", "admin()", "oracle()", "liquidationIncentiveMantissa()", "closeFactorMantissa()"]:
        calls.append((C, calldata(sig, (), ()))); keys.append(("comptroller", sig))
    res = rpc.try_calls(calls)
    d = {}
    for (kind, name), (raw, err) in zip(keys, res):
        d.setdefault(kind, {})[name] = {"raw": raw[:70] if raw else None, "err": err}
    out["step1"] = d

    # feed storage for ZK / USDCz
    stor = {}
    for name, slot in [("rfZK", SLOTS_ZK), ("rfUSDCz", SLOTS_USDCZ)]:
        try:
            r = rpc.call("eth_getStorageAt", [ORACLE, slot, hex(block)])
            stor[name] = "0x" + r[-40:]
        except Exception as e:
            stor[name] = f"ERR {e}"[:120]
    out["zk_usdcz_feeds"] = stor

    # feed reads for ZK/USDCz
    freads = {}
    calls, keys = [], []
    for name, f in stor.items():
        if isinstance(f, str) and f.startswith("0x") and len(f) == 42:
            for sig, ot in [("latestRoundData()", ["uint80", "int256", "uint256", "uint256", "uint80"]),
                            ("description()", ["string"]), ("decimals()", ["uint8"])]:
                calls.append((f, calldata(sig, (), ()))); keys.append((name, sig, ot))
    if calls:
        res = rpc.try_calls(calls)
        for (name, sig, ot), (raw, err) in zip(keys, res):
            e = freads.setdefault(name, {"address": stor[name]})
            if raw is None:
                e[sig] = {"err": err}; continue
            try:
                e[sig] = list(dec(ot, raw))
            except Exception as ex:
                e[sig] = {"raw": raw[:70], "err": str(ex)}
    out["feeds_zk_usdcz"] = freads

    # distributor: read underlying + balances of tokens + native
    dists = set()
    for n, v in d.get("dist", {}).items():
        r = v.get("raw")
        if r and r != "0x":
            try:
                dists.add("0x" + dec(["address"], r)[0][2:].lower())
            except Exception:
                pass
    out["distributors"] = sorted(dists)
    dist_out = {}
    for dist in sorted(dists):
        e = {}
        for sig, ot in [("underlying()", ["address"]), ("owner()", ["address"]), ("totalSupply()", ["uint256"]),
                        ("lastReap()", ["uint256"]), ("lastGaugeClaim()", ["uint256"]), ("duration()", ["uint256"]),
                        ("swappedRF()", ["uint256"])]:
            raw, err = rpc.try_call(dist, sig, (), (), ot)
            e[sig] = {"v": (list(raw) if isinstance(raw, tuple) else raw), "err": err}
        dist_out[dist] = e
    out["distributor_state"] = dist_out

    # token balances of distributor + ES33 token stats
    balances = {}
    for dist in sorted(dists):
        for tok, name in [("0x3355df6d4c9c3035724fd0e3914de96a5a83aaf4", "USDCe"),
                          ("0x493257fd37edb34451f62edf8d2a0c418852ba4c", "USDT"),
                          ("0xbbeb516fb02a01611cbbe0453fe3c580d7281011", "WBTC")]:
            raw, err = rpc.try_call(tok, "balanceOf(address)", ["address"], [dist], ["uint256"])
            balances[f"{dist}|{name}"] = {"v": raw[0] if raw and not err else None, "err": err}
        try:
            ethbal = int(rpc.call("eth_getBalance", [dist, hex(block)]), 16)
        except Exception as ex:
            ethbal = f"ERR {ex}"[:100]
        balances[f"{dist}|ETH"] = {"v": ethbal}
    out["distributor_balances"] = balances

    # ES33 token: find from distributor.underlying()
    es33 = None
    for dist, e in dist_out.items():
        u = e.get("underlying()", {}).get("v")
        if isinstance(u, list) and u:
            es33 = u[0]
    out["es33"] = es33
    if es33:
        ee = {}
        for sig, ot in [("name()", ["string"]), ("symbol()", ["string"]), ("totalSupply()", ["uint256"]),
                        ("emissionRate()", ["uint256"]), ("owner()", ["address"]), ("distributor()", ["address"])]:
            raw, err = rpc.try_call(es33, sig, (), (), ot)
            ee[sig] = {"v": (list(raw) if isinstance(raw, tuple) else raw), "err": err}
        out["es33_state"] = ee

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "era-dist.json"), "w") as fh:
        json.dump(out, fh, indent=1)
    print(json.dumps(out, indent=1)[:6000])

if __name__ == "__main__":
    main()
