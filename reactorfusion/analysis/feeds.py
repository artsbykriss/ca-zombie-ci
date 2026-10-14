#!/usr/bin/env python3
"""Read Chainlink feed freshness for ReactorFusion Era oracle + oracle storage slots.
Read-only. Keyless-or-env RPC. Writes analysis/feeds-era.json (no secrets)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

ORACLE = "0x1d54DD49218333125C858c0239bbdA424db55C43"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH": "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC": "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT": "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK": "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDCz": "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
KNOWN_FEEDS = {
    "rfUSDT": "0xB615075979AE1836B476F651f1eB79f0Cd3956a9",
    "rfUSDCe": "0x1824D297C6d6D311A204495277B63e943C2D376E",
    "rfWBTC": "0x4Cba285c15e3B540C474A114a7b135193e4f1EA6",
    "rfETH": "0x6D41d1dc818112880b40e26BD6FD347E41008eDA",
}
SLOTS = {  # keccak-based mapping slots computed locally with cast index address <m> 1
    "rfUSDCe": "0xccfd71bdd10344ceaadd51a6b49878ec929f3fb1461093ad5339a10644d37643",
    "rfETH": "0xbd1687ec6fb3e4a7e44cc8ebb076d2d1260b64d3ac115a4d6eee895c6674d379",
    "rfWBTC": "0x9a11ba251d8fc61f5ac93ed76a67dd1f785af9972414c6e78a2a81bedddc27be",
    "rfUSDT": "0x727409985479f10931e1241cf08f3f33ad51e56378cd9156a89297acd1431f74",
    "rfZK": "0x9a2c981e05a1c8412d0647b8db3a4ae21f6fe9c90e6bb2fb4ef9a51a4998fac0",
    "rfUSDCz": "0xc8e48ed524133bd029ecdac5e2e22e3105420120c2e918e40c82fda4cbac36be",
}

def main():
    rpc = RPC(default_urls("era"), "era")
    block = rpc.block_number()
    out = {"chain": "era", "block": block, "oracle": ORACLE,
           "note": "SimplePriceOracle.getUnderlyingPrice = feed.latestAnswer()*10**(36-feedDec-cTokenDec); NO staleness check in code"}
    # 1) storage slots -> feed addresses
    stor = {}
    for name, slot in SLOTS.items():
        raw, err = rpc.try_call(ORACLE, "x", out_types=None) if False else (None, None)
        try:
            r = rpc.call("eth_getStorageAt", [ORACLE, slot, hex(block)])
            addr = "0x" + r[-40:]
            stor[name] = {"slot": slot, "feed": addr, "raw": r}
        except Exception as e:
            stor[name] = {"slot": slot, "error": str(e)[:200]}
    out["storage_feeds"] = stor

    # 2) feed data for all discovered feeds
    feeds = {}
    allfeeds = {**KNOWN_FEEDS, **{k: v["feed"] for k, v in stor.items() if v.get("feed")}}
    calls = []
    keys = []
    for name, f in allfeeds.items():
        for sig, types, otypes in [("latestRoundData()", (), ["uint80", "int256", "uint256", "uint256", "uint80"]),
                                   ("decimals()", (), ["uint8"]),
                                   ("description()", (), ["string"]),
                                   ("aggregator()", (), ["address"]),
                                   ("owner()", (), ["address"])]:
            calls.append((f, calldata(sig, types, ())))
            keys.append((name, f, sig, otypes))
    res = rpc.try_calls(calls)
    for (name, f, sig, otypes), (raw, err) in zip(keys, res):
        e = feeds.setdefault(name, {"address": f})
        if raw is None:
            e[sig] = {"err": err}
            continue
        try:
            v = dec(otypes, raw)
            e[sig] = list(v)
        except Exception as ex:
            e[sig] = {"raw": raw[:80], "err": f"decode {ex}"}
    out["feeds"] = feeds

    # 3) comptroller market list + cToken decimals
    C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
    calls = [(C, calldata("getAllMarkets()", (), ())), (C, calldata("allMarkets()", (), ()))]
    for m in MARKETS.values():
        calls.append((m, calldata("decimals()", (), ())))
        calls.append((m, calldata("symbol()", (), ())))
    res = rpc.try_calls(calls)
    out["comptroller_getAllMarkets"] = {"raw": res[0][0], "err": res[0][1]}
    out["comptroller_allMarkets"] = {"raw": res[1][0], "err": res[1][1]}
    decs = {}
    for i, name in enumerate(MARKETS):
        raw, err = res[2 + 2 * i]
        v = None
        if raw:
            try:
                v = dec(["uint8"], raw)[0]
            except Exception:
                v = None
        sraw, serr = res[3 + 2 * i]
        sym = None
        if sraw:
            try:
                sym = dec(["string"], sraw)[0]
            except Exception:
                sym = None
        decs[name] = {"decimals": v, "symbol": sym, "err": err or serr}
    out["ctokens_meta"] = decs

    # 4) oracle owner nonce (activity indicator)
    try:
        nonce = int(rpc.call("eth_getTransactionCount", ["0x99999a3c4cb8427c44294ad36895b6a3a047060d", "latest"]), 16)
        out["oracle_owner_0x99999a3c"] = {"nonce": nonce}
    except Exception as e:
        out["oracle_owner_0x99999a3c"] = {"error": str(e)[:200]}

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "feeds-era.json"), "w") as fh:
        json.dump(out, fh, indent=1)
    print("block", block)
    for name, f in feeds.items():
        lr = f.get("latestRoundData()")
        desc = f.get("description()")
        decv = f.get("decimals()")
        print(f"{name:9s} {f['address']} desc={desc} dec={decv} roundData={lr}")
    print("storage feeds:", {k: v.get("feed") for k, v in stor.items()})
    print("ctoken meta:", decs)
    print("owner nonce:", out["oracle_owner_0x99999a3c"])

if __name__ == "__main__":
    main()
