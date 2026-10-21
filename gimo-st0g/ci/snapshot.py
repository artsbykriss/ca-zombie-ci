#!/usr/bin/env python3
"""Pin-block snapshot, era-cadence scan, claim enumeration and JIT economics for Gimo st0G.

All reads are eth_call / eth_getLogs / eth_getBalance against the public 0G RPC.
No transaction is signed.  Outputs land in ci-out/.
"""
import json
import os
import subprocess
import sys
import time
import urllib.request

RPC = os.environ.get("OG_RPC_URL", "https://evmrpc.0g.ai")
BLOCK = int(os.environ.get("PIN_BLOCK", "47841263"))
OUT = os.environ.get("OUT_DIR", "ci-out")
MGR = "0xAc06d1Df23a4Fa00981aFAC0f33A5936Bd2135aF"
POOL = "0x136b56554671976EF8366B01B31185F91Ae696AF"
TOKEN = "0x7bBC63D01CA42491c3E084C941c3E86e55951404"
VALIDATOR = "0xeC856948CF28a7c36E4c0D7877d027bA0a8AF17d"
TOPIC_NEWERA = "0x02105621fc31aa3ac04a9845beacd54c700e2ab23ff8acdd755dfd878ae61f02"

_SEL_CACHE = {}


def sel(sig):
    if sig not in _SEL_CACHE:
        _SEL_CACHE[sig] = subprocess.run(["cast", "sig", sig], capture_output=True,
                                         text=True, check=True).stdout.strip()
    return _SEL_CACHE[sig]


def curl_json(payload):
    last = None
    for attempt in range(5):
        p = subprocess.run(
            ["curl", "-s", "-m", "120", "-A", "Mozilla/5.0", "-X", "POST", RPC,
             "-H", "content-type: application/json", "-d", json.dumps(payload)],
            capture_output=True, text=True,
        )
        if p.stdout.strip():
            try:
                return json.loads(p.stdout)
            except Exception as e:
                last = e
        else:
            last = RuntimeError("empty response")
        time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"RPC failed after retries: {last}")


def call(to, data, block=BLOCK):
    r = curl_json({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                   "params": [{"to": to, "data": data}, hex(block)]})
    return int(r["result"], 16)


def call_many(to, datas, block=BLOCK):
    out = {}
    for i in range(0, len(datas), 100):
        chunk = datas[i:i + 100]
        reqs = [{"jsonrpc": "2.0", "id": i + j, "method": "eth_call",
                 "params": [{"to": to, "data": d}, hex(block)]} for j, d in enumerate(chunk)]
        res = curl_json(reqs)
        for r in res:
            if "result" in r and r["result"] not in (None, "0x"):
                out[r["id"]] = r["result"]
    return out


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def enc_u(x):
    return hex(x)[2:].rjust(64, "0")


def get_logs(addr, topic, lo, hi):
    r = curl_json({"jsonrpc": "2.0", "id": 1, "method": "eth_getLogs",
                   "params": [{"address": addr, "topics": [topic],
                               "fromBlock": hex(lo), "toBlock": hex(hi)}]})
    if "error" in r:
        raise RuntimeError(r["error"])
    return r["result"]


def main():
    os.makedirs(OUT, exist_ok=True)
    snap = {"chain_id": 16661, "block": BLOCK}

    blk = curl_json({"jsonrpc": "2.0", "id": 1, "method": "eth_getBlockByNumber",
                     "params": [hex(BLOCK), False]})["result"]
    snap["block_timestamp"] = int(blk["timestamp"], 16)

    def rd(sig_str, to=MGR, args=None):
        return call(to, sel(sig_str) + "".join(args or []))

    state = {
        "rate": rd("rate()"),
        "totalSupply": rd("totalSupply()", TOKEN),
        "latestEra": rd("latestEra()"),
        "currentEra": rd("currentEra()"),
        "eraSeconds": rd("eraSeconds()"),
        "eraOffset": rd("eraOffset()"),
        "unbondingDuration": rd("unbondingDuration()"),
        "rateChangeLimit": rd("rateChangeLimit()"),
        "protocolFeeCommission": rd("protocolFeeCommission()"),
        "totalProtocolFee": rd("totalProtocolFee()"),
        "minStakeAmount": rd("minStakeAmount()"),
        "nextUnstakeIndex": rd("nextUnstakeIndex()"),
        "managerLsdBalance": rd("balanceOf(address)", TOKEN, [enc_addr(MGR)]),
        "poolLiquid": int(curl_json({"jsonrpc": "2.0", "id": 1, "method": "eth_getBalance",
                                     "params": [POOL, hex(BLOCK)]})["result"], 16),
        "managerNative": int(curl_json({"jsonrpc": "2.0", "id": 1, "method": "eth_getBalance",
                                        "params": [MGR, hex(BLOCK)]})["result"], 16),
        "poolPendingBond": rd("pendingBond()", POOL),
        "poolReservedFee": rd("reservedFee()", POOL),
        "poolOwner": "0x" + rd("owner()", POOL).to_bytes(32, "big")[12:].hex(),
        "managerOwner": "0x" + rd("owner()", MGR).to_bytes(32, "big")[12:].hex(),
        "tokenMinter": "0x" + rd("minter()", TOKEN).to_bytes(32, "big")[12:].hex(),
        "impl": "0x" + int(curl_json({"jsonrpc": "2.0", "id": 1, "method": "eth_getStorageAt",
                                      "params": [MGR, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", hex(BLOCK)]})["result"], 16).to_bytes(32, "big")[12:].hex(),
    }
    pi = call_many(MGR, [sel("poolInfoOf(address)") + enc_addr(POOL)])
    raw = list(pi.values())[0][2:]
    state["poolInfo"] = {
        "era": int(raw[0:64], 16), "bond": int(raw[64:128], 16),
        "unbond": int(raw[128:192], 16), "active": int(raw[192:256], 16),
    }
    state["getTotalDelegated"] = call(
        POOL, sel("getTotalDelegated(address[])") + enc_u(32) + enc_u(1) + enc_addr(VALIDATOR))
    state["validator"] = VALIDATOR
    state["eraRate_399"] = call(MGR, sel("eraRate(uint256)") + enc_u(399))
    state["eraRate_400"] = call(MGR, sel("eraRate(uint256)") + enc_u(400))
    snap["state"] = state

    # ---- economics
    supply = state["totalSupply"] / 1e18
    active = state["poolInfo"]["active"] / 1e18
    rate = state["rate"] / 1e18
    d_rate = (state["eraRate_400"] - state["eraRate_399"]) / 1e18
    reward_per_era = d_rate * supply
    try:
        px = json.load(urllib.request.urlopen(
            "https://coins.llama.fi/prices/current/coingecko:zero-gravity", timeout=30))
        price = px["coins"]["coingecko:zero-gravity"]["price"]
        price_ts = px["coins"]["coingecko:zero-gravity"]["timestamp"]
    except Exception:
        price, price_ts = 0.0, 0
    econ = {
        "block": BLOCK,
        "price_0g_usd": price,
        "price_source": "DefiLlama coins.llama.fi coingecko:zero-gravity",
        "price_timestamp": price_ts,
        "tvl_0g": active,
        "tvl_usd": active * price,
        "st0g_supply": supply,
        "rate_0g_per_st0g": rate,
        "era_rate_delta": d_rate,
        "era_reward_0g": reward_per_era,
        "era_reward_usd": reward_per_era * price,
        "annualised_nav_yield_pct": d_rate / rate * 365 * 100,
        "jit": [],
    }
    c = state["protocolFeeCommission"] / 1e18
    for mult in (0.01, 0.1, 0.5, 1, 5, 10, 100):
        X = active * mult
        f = X / (X + active)
        gain = f * (1 - c) * reward_per_era
        ret = gain / X if X else 0
        econ["jit"].append({
            "capital_x_tvl": mult, "capital_0g": X, "capital_usd": X * price,
            "share_f": f, "profit_0g": gain, "profit_usd": gain * price,
            "profit_bps_per_3era_cycle": ret * 1e4,
            "annualised_pct": ret * (365 / 3) * 100,
        })
    snap["economics"] = econ

    # ---- era cadence
    evs = []
    for i in range(0, 34):
        hi = BLOCK - i * 90000
        lo = hi - 90000
        try:
            for x in get_logs(MGR, TOPIC_NEWERA, lo, hi):
                evs.append({
                    "block": int(x["blockNumber"], 16),
                    "era": int(x["topics"][1], 16),
                    "rate": int(x["data"], 16),
                    "ts": int(x["blockTimestamp"], 16) if "blockTimestamp" in x else None,
                    "tx": x["transactionHash"],
                })
        except Exception as e:
            print("log chunk failed", lo, hi, e, file=sys.stderr)
    uniq = {(e["block"], e["era"]): e for e in evs}
    evs = sorted(uniq.values(), key=lambda z: z["block"])
    prev = None
    for e in evs:
        e["dt_s"] = (e["ts"] - prev["ts"]) if prev and e["ts"] and prev["ts"] else None
        e["late_s"] = (e["ts"] - (state["eraOffset"] + e["era"]) * state["eraSeconds"]) if e["ts"] else None
        prev = e
    snap["newera_events"] = evs
    with open(os.path.join(OUT, "newera_cadence.csv"), "w") as f:
        f.write("era,block,timestamp,rate,dt_s,seconds_after_boundary,tx\n")
        for e in evs:
            f.write(f'{e["era"]},{e["block"]},{e["ts"]},{e["rate"]},{e["dt_s"]},{e["late_s"]},{e["tx"]}\n')

    # ---- claims
    n = state["nextUnstakeIndex"]
    datas = [sel("unstakeAtIndex(uint256)") + enc_u(i) for i in range(n)]
    got = call_many(MGR, datas)
    recs = {}
    for k, v in got.items():
        d = v[2:]
        recs[int(k)] = {
            "era": int(d[0:64], 16), "pool": "0x" + d[88:128],
            "receiver": "0x" + d[152:192], "amount": int(d[192:256], 16),
        }
    receivers = sorted({r["receiver"].lower() for r in recs.values()})
    outs = call_many(MGR, [sel("getUnstakeIndexListOf(address)") + enc_addr(r) for r in receivers])
    live = set()
    for v in outs.values():
        d = v[2:]
        cnt = int(d[64:128], 16)
        for j in range(cnt):
            live.add(int(d[128 + 64 * j:192 + 64 * j], 16))
    total = sum(recs[i]["amount"] for i in live if i in recs)
    matured = sum(recs[i]["amount"] for i in live if i in recs
                  and recs[i]["era"] + state["unbondingDuration"] <= state["currentEra"])
    snap["claims"] = {
        "records_total": n,
        "records_enumerated": len(recs),
        "unique_receivers": len(receivers),
        "outstanding_records": len(live),
        "outstanding_0g": total / 1e18,
        "outstanding_matured_0g": matured / 1e18,
        "outstanding_unmatured_0g": (total - matured) / 1e18,
        "pool_liquid_0g": state["poolLiquid"] / 1e18,
        "matured_vs_liquid_ratio": (matured / state["poolLiquid"]) if state["poolLiquid"] else None,
    }

    with open(os.path.join(OUT, "live_state.json"), "w") as f:
        json.dump(snap, f, indent=2)
    print(json.dumps({"block": snap["block"], "ts": snap["block_timestamp"],
                      "economics": snap["economics"], "claims": snap["claims"]}, indent=2))
    print("wrote", os.path.join(OUT, "live_state.json"))


if __name__ == "__main__":
    main()
