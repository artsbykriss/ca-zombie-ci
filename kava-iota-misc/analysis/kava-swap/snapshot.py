#!/usr/bin/env python3
"""Snapshot Kava Swap + related state (READ-ONLY).

Writes raw/*.json and state.json into the same directory as this script.
All reads go to public LCD/RPC endpoints; no keys, no transactions.
"""
import json, os, subprocess, time

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw")
os.makedirs(RAW, exist_ok=True)

KAVA_LCD = "https://api.kava.io"
KAVA_RPC = "https://kava-rpc.publicnode.com"
OSMO_LCD = "https://lcd.osmosis.zone"

def get(url, timeout=40):
    r = subprocess.run(["curl", "-s", "--max-time", str(timeout), url], capture_output=True, text=True)
    try:
        return json.loads(r.stdout)
    except Exception:
        return None

def save(name, obj):
    with open(os.path.join(RAW, name), "w") as f:
        json.dump(obj, f, indent=1)
    return obj

def kava_height():
    d = get(f"{KAVA_LCD}/cosmos/base/tendermint/v1beta1/blocks/latest")
    if d and "block" in d:
        return int(d["block"]["header"]["height"]), d["block"]["header"]["time"]
    return None, None

def osmo_height():
    d = get(f"{OSMO_LCD}/cosmos/base/tendermint/v1beta1/blocks/latest")
    if d and "block" in d:
        return int(d["block"]["header"]["height"]), d["block"]["header"]["time"]
    return None, None

def main():
    state = {"generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "endpoints": {
        "kava_lcd": KAVA_LCD, "kava_rpc": KAVA_RPC, "osmosis_lcd": OSMO_LCD}}

    h0, t0 = kava_height()
    print("kava height before:", h0, t0)

    suffix = "?pagination.limit=500"
    state["kava_swap_pools"] = save("kava_swap_pools.json", get(f"{KAVA_LCD}/kava/swap/v1beta1/pools"))
    state["kava_swap_params"] = save("kava_swap_params.json", get(f"{KAVA_LCD}/kava/swap/v1beta1/params"))

    # module accounts of interest
    addrs = {
        "swap": "kava1mfru9azs5nua2wxcd4sq64g5nt7nn4n8s2w8cu",
        "incentive": "kava1hfny2zhlc328ksxjsv3qrrldcgqw36840h3qef",
        "cdp": "kava1wq9ts6l7atfn45ryxrtg4a2gwegsh3xha9e6rp",
        "auction": "kava1j4yzhgjm00ch3h0p9kel7g8sp6g045qf8kzmmd",
        "community": "kava1jv65s3grqf6v6jl3dp4t6c9t9rk99cd8m2splc",
    }
    state["module_balances"] = {}
    for name, a in addrs.items():
        state["module_balances"][name] = save(f"bal_{name}.json",
            get(f"{KAVA_LCD}/cosmos/bank/v1beta1/balances/{a}{suffix}"))

    state["supply"] = save("supply.json", get(f"{KAVA_LCD}/cosmos/bank/v1beta1/supply{suffix}"))
    state["community_pool"] = save("community_pool.json",
        get(f"{KAVA_LCD}/cosmos/distribution/v1beta1/community_pool"))
    state["cdp_params"] = save("cdp_params.json", get(f"{KAVA_LCD}/kava/cdp/v1beta1/params"))
    state["incentive_params"] = save("incentive_params.json", get(f"{KAVA_LCD}/kava/incentive/v1beta1/params"))

    # IBC channel-1 (Osmosis) escrow balance = tokens bridged OUT of Kava
    state["ibc_channel1_escrow"] = save("escrow_ch1.json",
        get(f"{KAVA_LCD}/cosmos/bank/v1beta1/balances/kava1kq2rzz6fq2q7fsu75a9g7cpzjeanmk685s3zdn{suffix}"))
    # channel-4 (Sifchain) & channel-0 (Cosmos Hub) & channel-5 (Akash) escrows
    for ch, addr in [("0", "kava1vdrysc48z2m6zf7dwgvw4g44d07h8pgsxwheck"),
                     ("4", "kava1tv8sxewgddxg6s4xdvxgmna8kjajfvntkpdrap"),
                     ("5", "kava1fmshry6lfkukeytac0ups85hk4j7pn53uds8ar")]:
        state[f"ibc_channel{ch}_escrow"] = save(f"escrow_ch{ch}.json",
            get(f"{KAVA_LCD}/cosmos/bank/v1beta1/balances/{addr}{suffix}"))

    # ibc denom traces used by pools
    traces = {}
    for h in ["0471F1C4E7AFD3F07702BEF6DC365268D64570F7C1FDC98EA6098DD6DE59817B",
              "27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2",
              "799FDD409719A1122586A629AE8FCA17380351A51C1F47A80A1B8E7F2A491098",
              "B448C0CA358B958301D328CCDC5D5AD642FC30A6D3AE106FF721DB315F3DDE5C",
              "B8AF5D92165F35AB31F3FC7C7B444B9D240760FA5D406C49D24862BD0284E395"]:
        traces[h] = save(f"trace_{h[:8]}.json",
            get(f"{KAVA_LCD}/ibc/apps/transfer/v1/denom_traces/{h}"))
    state["kava_ibc_denom_traces"] = traces

    # recent swap activity (226 recent swap events; heights only)
    state["recent_swap_sample"] = save("swap_txs_p1.json",
        get(f"{KAVA_RPC}/tx_search?query=%22message.module%3D%27swap%27%22&order_by=%22desc%22&per_page=100&page=1"))
    # last trade of the zombie pools, if indexed
    for pid, name in [("ibc/B448C0CA358B958301D328CCDC5D5AD642FC30A6D3AE106FF721DB315F3DDE5C:usdx", "uusd"),
                      ("ibc/B8AF5D92165F35AB31F3FC7C7B444B9D240760FA5D406C49D24862BD0284E395:usdx", "uluna")]:
        import urllib.parse
        q = urllib.parse.quote(f'"swap_trade.pool_id=\'{pid}\'"')
        state[f"last_trade_{name}"] = save(f"last_trade_{name}.json",
            get(f"{KAVA_RPC}/tx_search?query={q}&order_by=%22desc%22&per_page=3"))

    h1, t1 = kava_height()
    oh, ot = osmo_height()
    state["heights"] = {"kava_before": h0, "kava_after": h1, "kava_time_before": t0,
                        "kava_time_after": t1, "osmosis": oh, "osmosis_time": ot}
    print("kava height after:", h1, t1)

    # Osmosis pools that carry Kava-bridged tokens
    state["osmosis_pools"] = {}
    for pid in ["792", "1390", "1631"]:
        state["osmosis_pools"][pid] = save(f"osm_pool_{pid}.json",
            get(f"{OSMO_LCD}/osmosis/gamm/v1beta1/pools/{pid}"))
    state["osmosis_supplies"] = {}
    for nm, h in [("usdx", "ibc/C78F65E1648A3DFE0BAEB6C4CDA69CC2A75437F1793C0E6386DFDA26393790AE"),
                  ("swp", "ibc/70CF1A54E23EA4E480DEDA9E12082D3FD5684C3483CBDCE190C5C807227688C5"),
                  ("hard", "ibc/D6C28E07F7343360AC41E15DDD44D79701DDCA2E0C2C41279739C8D4AE5264BC")]:
        import urllib.parse
        state["osmosis_supplies"][nm] = save(f"osm_supply_{nm}.json",
            get(f"{OSMO_LCD}/cosmos/bank/v1beta1/supply/by_denom?denom={urllib.parse.quote(h)}"))

    # external prices (DefiLlama coins API + CoinGecko for HARD)
    price_ids = ["coingecko:kava", "coingecko:cosmos", "coingecko:osmosis", "coingecko:akash-network",
                 "coingecko:terra-luna", "coingecko:terrausd", "coingecko:binancecoin", "coingecko:bitcoin",
                 "coingecko:ripple", "coingecko:binance-usd", "coingecko:usd-coin"]
    prices = save("prices_llama.json", get("https://coins.llama.fi/prices/current/" + ",".join(price_ids)))
    hard = save("price_hard_cg.json", get("https://api.coingecko.com/api/v3/simple/price?ids=kava-lend&vs_currencies=usd&include_market_cap=true"))
    state["prices"] = {"llama": prices, "hard_cg": hard,
                       "note": "SWP price must be derived from Osmosis pool 1631 (CoinGecko feed is stale: no tickers)."}

    with open(os.path.join(HERE, "state.json"), "w") as f:
        json.dump(state, f, indent=1)
    print("wrote state.json + raw/*.json")

if __name__ == "__main__":
    main()
