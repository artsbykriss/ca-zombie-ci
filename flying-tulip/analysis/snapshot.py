#!/usr/bin/env python3
"""
Flying Tulip Lend — live oracle/config snapshotter (READ-ONLY).

Reads the deployed Ethereum state of the FT lending stack at a pinned block:
  LendingLens 0x3682168023e6ba8d1f995fda1d920827c5a8a43e (proxy)
    -> PositionsManager 0xbe4050a73a7fb384c65e885a15c33461a4b20055
    -> ConfigRegistry   0xa8777c3d446fa7f0b0fc97a80c1ea1d37f1ca33e
    -> OracleRouterChainlink 0xe4372db43d2814750a19b93950157ad81d93674a

Only eth_chainId / eth_blockNumber / eth_getBlockByNumber / eth_call are used.
No keyed RPC URL or secret is written to disk: RPC is taken from the environment
(FORK_RPC_URL or RPC_URL) and only the *host-less* endpoint label is stored.

Usage:  python3 snapshot.py [output.json]
"""
import json
import os
import sys
import urllib.request

RPC = (os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL")
       or "https://ethereum-rpc.publicnode.com")

LENS = "0x3682168023e6ba8d1f995fda1d920827c5a8a43e"
PM = "0xbe4050a73a7fb384c65e885a15c33461a4b20055"
CR = "0xa8777c3d446fa7f0b0fc97a80c1ea1d37f1ca33e"
OR = "0xe4372db43d2814750a19b93950157ad81d93674a"

SEL_GETASSETCFG = "fb20974f"
SEL_PRICEFEED = "1fd48b9a"
SEL_PRICEUSD = "f4d057ff"
SEL_LRD = "feaf968c"
SEL_DECIMALS = "313ce567"
SEL_ASSETSTATE = "74bd94ca"
SEL_MARGIN_HF_SAFE = "3605436e"
SEL_MARGIN_HF_TARGET = "a6e89ffe"
SEL_ORACLE_ROUTER = "55a29e91"
SEL_ASSET = "38d52e0f"
SEL_TOTALASSETS = "01e1d114"
SEL_CONVERTTOASSETS = "07a2d13a"
SEL_BALANCEOF = "70a08231"
SEL_TOTALSUPPLY = "18160ddd"

# asset symbol -> (underlying token, ftYieldWrapper)
ASSETS = [
    ("WETH",   "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0x460494aF61BcB92B59797B4e09C26A5ADecb2da2"),
    ("wstETH", "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0", "0x01980BD1B58313bD3767f6adc75Af8b6464f3db7"),
    ("WBTC",   "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", "0x1A5730c71576D77048E9FdC79DD40e4B1E8Fe042"),
    ("USDC",   "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "0xD2e4A5ac4B4Da102317cF7C9A1289aDF082639E2"),
    ("USDT",   "0xdAC17F958D2ee523a2206206994597C13D831ec7", "0x28b0905d83BCe5FFA6c54651F25858828A38123B"),
    ("crvUSD", "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E", "0xa41686c6018056b44a7027f4c912e6153cfb5c63"),
    ("scrvUSD","0x0655977FEb2f289A4aB78af67BAB0d17aAb84367", "0xefab1b1856bbe0b6d78f2552614e34efad1eb6c6"),
    ("sUSDe",  "0x9D39A5DE30e57443BfF2A8307A4256c8797A3497", "0xbc940f911744670523c3d4ebc56e1e28489591d7"),
    ("USDG",   "0xe343167631d89B6Ffc58B88d6b7fB0228795491D", "0x8b419a64d95738b3dfcb55a35da7918dfd366bb0"),
    ("FT",     "0x5DD1A7A369e8273371d2DBf9d83356057088082c", "0x7127BB9d9ad0f47B8dA9087e634D67F3946F840E"),
]

SCRVUSD_VAULT = "0x0655977FEb2f289A4aB78af67BAB0d17aAb84367"
CRVUSD = "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E"


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(
        RPC, data=body,
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research read-only)"},
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def call(to, selector, arg=None):
    data = "0x" + selector + (arg or "")
    res = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    if "error" in res:
        return None
    return res.get("result")


def words(hexstr):
    if not hexstr or hexstr == "0x":
        return []
    h = hexstr[2:]
    return [h[i:i + 64] for i in range(0, len(h), 64)]


def to_int(w):
    return int(w, 16)


def to_addr(w):
    return "0x" + w[-40:]


def to_bool(w):
    return int(w, 16) != 0


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else "live-state.json"
    chain_id = int(rpc("eth_chainId", [])["result"], 16)
    block_hex = rpc("eth_blockNumber", [])["result"]
    block = int(block_hex, 16)
    blk = rpc("eth_getBlockByNumber", [block_hex, False])["result"]
    ts = int(blk["timestamp"], 16)

    result = {
        "chain_id": chain_id,
        "block": block,
        "block_timestamp": ts,
        "rpc": "<public-keyless>",
        "addresses": {"lens": LENS, "positionsManager": PM, "configRegistry": CR, "oracleRouter": OR},
        "global": {
            "oracleRouter": "0x" + words(call(CR, SEL_ORACLE_ROUTER))[0][-40:] if call(CR, SEL_ORACLE_ROUTER) else None,
            "marginHfSafeBps": to_int(words(call(CR, SEL_MARGIN_HF_SAFE))[0]),
            "marginHfTargetBps": to_int(words(call(CR, SEL_MARGIN_HF_TARGET))[0]),
        },
        "assets": {},
    }

    for sym, tok, wrap in ASSETS:
        entry = {"symbol": sym, "token": tok, "wrapper": wrap}

        # ConfigRegistry.getAssetCfg(asset) -> (irm, mmBps, enabled, ftYieldWrapper, borrowable, collateral)
        w = words(call(CR, SEL_GETASSETCFG, enc_addr(tok)))
        if w and len(w) >= 6:
            entry["cfg"] = {
                "irm": to_addr(w[0]), "mmBps": to_int(w[1]), "enabled": to_bool(w[2]),
                "ftYieldWrapper": to_addr(w[3]), "borrowable": to_bool(w[4]), "collateral": to_bool(w[5]),
            }

        # OracleRouterChainlink.priceFeed(asset) -> (agg, lastGoodPriceWad, heartbeat, deviationBps, enabled, fallbackOnStale)
        w = words(call(OR, SEL_PRICEFEED, enc_addr(tok)))
        if w and len(w) >= 6:
            agg = to_addr(w[0])
            entry["feed"] = {
                "agg": agg, "lastGoodPriceWad": str(to_int(w[1])), "heartbeat": to_int(w[2]),
                "deviationBps": to_int(w[3]), "enabled": to_bool(w[4]), "fallbackOnStale": to_bool(w[5]),
            }
            # aggregator latestRoundData
            w2 = words(call(agg, SEL_LRD))
            if w2 and len(w2) >= 5:
                entry["agg_round"] = {
                    "roundId": str(to_int(w2[0])), "answer": str(to_int(w2[1])),
                    "startedAt": str(to_int(w2[2])), "updatedAt": str(to_int(w2[3])),
                    "answeredInRound": str(to_int(w2[4])),
                }
            w3 = words(call(agg, SEL_DECIMALS))
            if w3:
                entry["agg_decimals"] = to_int(w3[0])

        # priceUSD(asset)
        pu = call(OR, SEL_PRICEUSD, enc_addr(tok))
        if pu:
            w = words(pu)
            entry["priceUSD_wad"] = str(to_int(w[0])) if w else None
        else:
            entry["priceUSD_wad"] = None

        # lens assetState(asset) -> (cash, borrows, reserves, utilWad)
        w = words(call(LENS, SEL_ASSETSTATE, enc_addr(tok)))
        if w and len(w) >= 4:
            entry["assetState"] = {
                "cash": str(to_int(w[0])), "borrows": str(to_int(w[1])),
                "reserves": str(to_int(w[2])), "utilWad": str(to_int(w[3])),
            }
        result["assets"][sym] = entry

    # scrvUSD ERC4626 donation-resistance check
    sc = {}
    w = words(call(SCRVUSD_VAULT, SEL_TOTALASSETS))
    if w:
        sc["totalAssets"] = str(to_int(w[0]))
    w = words(call(SCRVUSD_VAULT, SEL_TOTALSUPPLY))
    if w:
        sc["totalSupply"] = str(to_int(w[0]))
    w = words(call(CRVUSD, SEL_BALANCEOF, enc_addr(SCRVUSD_VAULT)))
    if w:
        sc["crvusdBalanceOfVault"] = str(to_int(w[0]))
    w = words(call(SCRVUSD_VAULT, SEL_CONVERTTOASSETS, hex(10 ** 18)[2:].rjust(64, "0")))
    if w:
        sc["convertToAssets1e18"] = str(to_int(w[0]))
    result["scrvUSD_vault"] = sc

    with open(out_path, "w") as f:
        json.dump(result, f, indent=1)
    print(f"wrote {out_path} block={block} ts={ts}")


if __name__ == "__main__":
    main()
