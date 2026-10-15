#!/usr/bin/env python3
"""CI re-verification of Horizon Protocol (BSC) live state.
Reads BSC_RPC_URL (or FORK_RPC_URL) from env; never prints it. Writes ci-out/extraction.json.
Pure stdlib."""
import json, os, sys, time, urllib.request

RPC = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
if not RPC.strip():
    RPC = "https://bsc-rpc.publicnode.com"

def rpc(method, params, retries=4):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.loads(r.read())
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = str(e)
        time.sleep(2 * (i + 1))
    raise RuntimeError(f"rpc failed: {last}")

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def num(x):
    if isinstance(x, str) and x.startswith("0x") and len(x) > 2:
        return int(x, 16)
    return None

def enc_name(n):
    return n.encode().hex().ljust(64, "0")

def bal_of(token, who):
    return num(call(token, "0x70a08231" + who[2:].rjust(64, "0")))

HZN = "0xc0eff7749b125444953ef89682201fb8c6a917cd"
SNX = "0x0110bcbeb89a43ec47e62d1980e29e0683745ffc"
SCHED = "0x45151b3b1fff51d404e7fcdb2a4067ed50165a55"
SS = "0x344b085489f41fe9a60c6f4b3727b12447d64209"
ER = "0x95a49608f30e8e7ac4adc5565a206e2b874b9763"
LP_STAKING = "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8"
HZN_BNB_PAIR = "0xdc9a574b9b341d4a98ce29005b614e1e27430e74"
CMS = "0xc7938c1f716e2424915685920f4e8bc4ff7bafb8"

def main():
    out = {}
    bn = num(rpc("eth_blockNumber", []))
    blk = rpc("eth_getBlockByNumber", [hex(bn), False])
    out["block"] = bn
    out["block_timestamp"] = num(blk["timestamp"])
    out["gas_price_wei"] = num(rpc("eth_gasPrice", []))
    out["now_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    # suspensions (tuple (bool,uint248))
    for name, sel in [("systemSuspension", "0x2dd8afdb"), ("issuanceSuspension", "0x2366245e"),
                      ("exchangeSuspension", "0xf8b4b084")]:
        v = call(SS, sel)
        out[name + "_suspended"] = bool(num(v[:66])) if v and v != "0x" else None

    # HZN rate + staleness
    out["hzn_rate"] = num(call(ER, "0xac82f608" + enc_name("HZN")))
    out["hzn_rate_updated"] = num(call(ER, "0xce8480ea" + enc_name("HZN")))
    out["hzn_rate_invalid"] = bool(num(call(ER, "0x2528f0fe" + enc_name("HZN"))))
    out["rate_stale_period"] = num(call("0x39989d410137c6eeac8f62369db666836e6cbdba", "0x0ee4951b"))

    # supply schedule
    out["mintable_supply"] = num(call(SCHED, "0xcc5c095c"))
    out["minter_reward"] = num(call(SCHED, "0x9bdd7ac7"))
    out["is_mintable"] = bool(num(call(SCHED, "0x46b45af7")))
    out["last_mint_event"] = num(call(SCHED, "0xbe801f01"))

    # pair price HZN/BNB
    res = call(HZN_BNB_PAIR, "0x0902f1ac")
    r0, r1 = num(res[:66]), num("0x" + res[66:130])
    t0 = call(HZN_BNB_PAIR, "0x0dfe1681")
    out["hzn_bnb_reserve0"] = r0
    out["hzn_bnb_reserve1"] = r1
    out["hzn_bnb_token0"] = "0x" + t0[-40:]
    # token0 = WBNB, token1 = HZN  => HZN per 1 BNB = r1/r0
    hzn_per_bnb = (r1 / r0) if r0 else 0
    out["hzn_per_bnb"] = hzn_per_bnb

    # BNB price from zBNB oracle
    out["zbnb_rate"] = num(call(ER, "0xac82f608" + enc_name("zBNB")))

    # staking state
    out["lp_staking_reward_rate"] = num(call(LP_STAKING, "0x7b0a47ee"))
    out["lp_staking_period_finish"] = num(call(LP_STAKING, "0xebe2b12b"))
    out["lp_staking_total_staked"] = num(call(LP_STAKING, "0x18160ddd"))
    out["lp_staking_hzn_balance"] = bal_of(HZN, LP_STAKING)

    # no loans
    out["collateral_manager_total_loans"] = num(call(CMS, "0xcc952b57"))

    # extraction math
    bnb_usd = (out["zbnb_rate"] or 0) / 1e18
    hzn_usd = (bnb_usd / hzn_per_bnb) if hzn_per_bnb else 0
    reward = (out["minter_reward"] or 0) / 1e18
    out["hzn_usd_price"] = hzn_usd
    out["minter_reward_usd"] = reward * hzn_usd
    out["mint_gas_used"] = 317850  # measured in the Foundry fork PoC (test_mint_live_extraction)
    out["mint_gas_cost_usd"] = (out["mint_gas_used"] * (out["gas_price_wei"] or 0) / 1e18) * bnb_usd
    out["net_minter_reward_usd"] = out["minter_reward_usd"] - out["mint_gas_cost_usd"]
    out["poc_wbnb_out_for_200hzn_wei"] = 76103164045780  # measured on fork via PancakeSwap V2
    out["note"] = ("mint() live (suspensions all false); pays caller minterReward HZN when called on the TARGET "
                   "0x0110bcBEB (calling via the ProxyERC20 credits the proxy); rest distributed to LP staking + "
                   "FeePool (existing stakers / debt-share holders).")

    with open("ci-out/extraction.json", "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    print(json.dumps(out, indent=1, sort_keys=True))

if __name__ == "__main__":
    main()
