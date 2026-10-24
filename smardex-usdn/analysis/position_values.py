#!/usr/bin/env python3
"""Read-only: compute each live position's liquidation price / value / buffer."""
import json
from web3 import Web3
from eth_abi import encode, decode

RPC = "https://ethereum-rpc.publicnode.com"
PROXY = Web3.to_checksum_address("0x656cB8C6d154Aad29d8771384089be5B5141f01a")
w3 = Web3(Web3.HTTPProvider(RPC, request_kwargs={"timeout": 30}))

def call(sig, types, vals):
    sel = Web3.keccak(text=sig)[:4]
    data = sel + encode(types, vals)
    r = w3.eth.call({"to": PROXY, "data": data})
    return r

def main():
    d = json.load(open("analysis/positions.json"))
    lastPrice = int(d["lastPrice"])
    lastUpdate = None  # read separately
    # last update timestamp at slot S+26 high 128 bits
    S = int("d143a936a6a372725e12535db83a2cfabcb3715dfd88bc350da3399604dc9700", 16)
    v = int.from_bytes(w3.eth.get_storage_at(PROXY, S + 26), "big")
    lastUpdate = v >> 128
    out = []
    for p in d["positions"]:
        tick = p["tick"]
        posid = (tick, p["tickVersion"], p["index"])
        liq = decode(["uint128"], call("getEffectivePriceForTick(int24)", ["int24"], [tick]))[0]
        pv = decode(["int256"], call("getPositionValue((int24,uint256,uint256),uint128,uint128)",
                                     ["(int24,uint256,uint256)", "uint128", "uint128"],
                                     [posid, lastPrice, lastUpdate]))[0]
        buf = (lastPrice - liq) / lastPrice * 100 if liq < lastPrice else -1
        out.append(dict(tick=tick, tickVersion=p["tickVersion"], index=p["index"], user=p["user"],
                        amountWei=str(p["amount"]), expoWei=str(p["totalExpo"]),
                        liqPriceWei=str(liq), liqPrice=liq / 1e18,
                        valueWei=str(pv), value=pv / 1e18, bufferPct=round(buf, 3)))
    out.sort(key=lambda x: -x["liqPrice"])
    res = dict(block=w3.eth.block_number, lastPrice=lastPrice / 1e18, lastUpdateTimestamp=lastUpdate,
               positions=out)
    json.dump(res, open("analysis/position_values.json", "w"), indent=2)
    print(f"block {res['block']} lastPrice {res['lastPrice']:.2f} lastUpdate {lastUpdate}")
    print(f"{'tick':>7} {'idx':>4} {'amount':>9} {'value':>9} {'liqPrice':>9} {'buffer%':>8} user")
    for o in out:
        print(f"{o['tick']:>7} {o['index']:>4} {int(o['amountWei'])/1e18:>9.3f} {o['value']:>9.3f} "
              f"{o['liqPrice']:>9.2f} {o['bufferPct']:>8.2f} {o['user']}")

if __name__ == "__main__":
    main()
