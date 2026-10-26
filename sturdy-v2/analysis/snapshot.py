#!/usr/bin/env python3
"""Sturdy V2 live-state snapshot (READ-ONLY, dependency-free).

Reads AggregatorDataProvider.getStrategies()/getVaults() plus each pair's
exchangeRateInfo() and each oracle's getPrices()/name()/bounds at one pinned block.
Writes JSON to stdout. RPC from env: FORK_RPC_URL, RPC_URL, BLOCKPI_RPC_URL or a
keyless fallback. Only the RPC *host* is recorded (never a keyed URL). No transactions.
"""
import json, os, sys, urllib.request

RPC = (os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL")
       or os.environ.get("BLOCKPI_RPC_URL") or "https://ethereum-rpc.publicnode.com")
DP = "0x69764E3e0671747A7768A1C1AfB7C0C39868CC9e"
H = {"Content-Type": "application/json", "User-Agent": "sturdy-recon/1.0"}

# keccak selectors (precomputed)
SEL = {
    "getStrategies": "0xb49a60bb",
    "getVaults": "0x44d00f82",
    "exchangeRateInfo": "0xfbbbf94c",
    "getPrices": "0xbd9a548b",
    "name": "0x06fdde03",
    "MAX_ORACLE_DELAY": "0xc6d3107f",
    "PRICE_MIN": "0x6f16a595",
    "TWAP_DURATION": "0x879ac8f8",
}

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers=H)
    with urllib.request.urlopen(req, timeout=40) as r:
        j = json.load(r)
    if "error" in j:
        raise RuntimeError(str(j["error"])[:160])
    return j["result"]

def raw_call(to, data, blk):
    return rpc("eth_call", [{"to": to, "data": data}, hex(blk)])

class B:
    def __init__(self, hexstr):
        self.b = bytes.fromhex(hexstr[2:] if hexstr.startswith("0x") else hexstr)
    def word(self, off):
        return int.from_bytes(self.b[off:off+32], "big")
    def addr(self, off):
        return "0x" + self.b[off+12:off+32].hex()

def dec_tuple_dyn(b: B, base: int, layout):
    """layout: list of ('a'|'u'|'s'|'b') for each field of a dynamic tuple at offset `base`."""
    out = []
    for j, t in enumerate(layout):
        if t == "s":
            soff = base + b.word(base + 32*j)
            ln = b.word(soff)
            out.append(b.b[soff+32:soff+32+ln].decode("utf-8", "replace"))
        elif t == "a":
            out.append(b.addr(base + 32*j))
        elif t == "b":
            out.append(bool(b.word(base + 32*j)))
        else:
            out.append(b.word(base + 32*j))
    return out

def dec_dyn_array_of_tuples(hexstr, layout):
    b = B(hexstr)
    arr = b.word(0)                       # offset to array
    n = b.word(arr)
    base = arr + 32                       # start of element-offset table
    out = []
    for i in range(n):
        eoff = base + b.word(base + 32*i)
        out.append(dec_tuple_dyn(b, eoff, layout))
    return out

PAIRDATA_LAYOUT = ["a","s","u","a","s","u","a","a","u","u","u","u","u","u","u","u","u","u","u","u","u"]
PAIRDATA_KEYS = ["asset","assetSymbol","assetDecimals","collateral","collateralSymbol","collateralDecimals",
                 "rateContract","oracle","depositLimit","ratePerSec","fullUtilizationRate","feeToProtocolRate",
                 "maxOacleDeviation","lowExchangeRate","highExchangeRate","maxLTV","protocolLiquidationFee",
                 "totalAsset","totalCollateral","totalBorrow","version"]
VAULT_LAYOUT = ["a","b","a","s","u","s","u","u"]
VAULT_KEYS = ["deployedAt","isShutdown","asset","assetSymbol","assetDecimals","name","totalAssets","totalDebt"]

def dec_strategies(hexstr):
    b = B(hexstr)
    arr = b.word(0)
    n = b.word(arr)
    base = arr + 32
    out = []
    for i in range(n):
        e = base + b.word(base + 32*i)              # outer tuple (deployedAt, pair, pairData)
        pd = e + b.word(e + 64)                     # nested dynamic tuple pairData
        d = {"deployedAt": b.addr(e), "pair": b.addr(e + 32)}
        d.update(dict(zip(PAIRDATA_KEYS, dec_tuple_dyn(b, pd, PAIRDATA_LAYOUT))))
        out.append(d)
    return out

def main():
    blk = int(rpc("eth_blockNumber", []), 16)
    st = dec_strategies(raw_call(DP, SEL["getStrategies"], blk))
    va = [dict(zip(VAULT_KEYS, r)) for r in dec_dyn_array_of_tuples(raw_call(DP, SEL["getVaults"], blk), VAULT_LAYOUT)]
    for s in st:
        # exchangeRateInfo() -> (address, uint32, uint184, uint256, uint256)  [static]
        try:
            b = B(raw_call(s["pair"], SEL["exchangeRateInfo"], blk))
            s["exchangeRateInfo"] = dict(oracle=b.addr(0), maxOracleDeviation=b.word(32),
                                         lastTimestamp=b.word(64), lowExchangeRate=str(b.word(96)),
                                         highExchangeRate=str(b.word(128)))
        except Exception as e:
            s["exchangeRateInfo"] = {"error": str(e)[:100]}
        o = {}
        try:
            b = B(raw_call(s["oracle"], SEL["getPrices"], blk))
            o["isBadData"], o["priceLow"], o["priceHigh"] = bool(b.word(0)), str(b.word(32)), str(b.word(64))
            hi = b.word(64)
            o["deviation_1e5"] = (100000*(hi-b.word(32))//hi) if hi else None
        except Exception:
            o["getPrices_reverted"] = True
        try:
            b = B(raw_call(s["oracle"], SEL["name"], blk))
            so = b.word(0)
            ln = b.word(so)
            o["name"] = b.b[so+32:so+32+ln].decode("utf-8", "replace")
        except Exception:
            o["name"] = None
        for k in ("MAX_ORACLE_DELAY", "PRICE_MIN", "TWAP_DURATION"):
            try:
                o[k] = B(raw_call(s["oracle"], SEL[k], blk)).word(0)
            except Exception:
                o[k] = None
        s["oracle_live"] = o
    print(json.dumps({"block": blk, "rpc_host": RPC.split("/")[2], "strategies": st, "vaults": va}, indent=1))

if __name__ == "__main__":
    main()
