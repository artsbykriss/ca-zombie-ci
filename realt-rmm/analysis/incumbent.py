"""Incumbent cluster + recent liquidation activity. Read-only.

Writes analysis/incumbent.json:
  - Safe owners / threshold (live)
  - RealToken holdings of the Safe, its parity exit wallet and owner1 (all 623 tokens, at marks)
  - wrapper LiquidationCall events over the last 30 days, decoded (liquidator, debt repaid, seize value)
"""
import json
import os
import sys

from eth_abi import decode as abi_decode

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
SAFE = "0x4F7765c9feBc51cD63F68f573920c0B7bF803151"
EXIT = "0x134d928B26DB2Da678F16974580B22E799293E6c"
OWNER1 = "0xCa543f90a221dac783490BfeE4a1173AE07547c2"
TOPIC = "0x" + g.keccak(text="LiquidationCall(address[],uint256[],address,uint256,address,address,uint8)").hex()


def token_holdings(addrs, tokens, marks, block):
    calls = []
    for a in addrs:
        for t in tokens:
            calls.append((t, g.sel("balanceOf(address)") + g.abi_encode(["address"], [a]).hex()))
    res = g.multicall(calls, block=block)
    out = {}
    i = 0
    for a in addrs:
        rows = []
        total = 0.0
        for t in tokens:
            ok, ret = res[i]
            i += 1
            bal = int.from_bytes(ret[:32], "big") if ok else 0
            if bal > 0:
                v = bal * marks.get(t, 0) / 1e18
                rows.append({"token": t, "amount": str(bal), "value_usd_marks": round(v, 2)})
                total += v
        rows.sort(key=lambda x: -x["value_usd_marks"])
        out[a] = {"positions": len(rows), "value_usd_marks": round(total, 2), "top": rows[:15]}
    return out


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    toks = [t["address"] for t in wt["tokens"]]
    marks = {t["address"]: t["price_1e8"] / 1e8 for t in wt["tokens"]}

    safe = {}
    for sig, types in [("getOwners()(address[])", ["address[]"]), ("getThreshold()(uint256)", ["uint256"]),
                       ("nonce()(uint256)", ["uint256"])]:
        try:
            safe[sig.split("(")[0]] = g.dec(types, g.call(SAFE, sig, block=block))[0]
        except Exception as e:  # noqa: BLE001
            safe[sig.split("(")[0]] = f"ERR {e}"

    holdings = token_holdings([SAFE, EXIT, OWNER1], toks, marks, block)

    # --- last 30 days of wrapper liquidations ---
    frm = block - int(30 * 24 * 3600 / 5)
    logs = []
    b = frm
    while b <= block:
        e = min(b + 150_000, block)
        try:
            ls = g.rpc("eth_getLogs", [{"address": WRAPPER, "fromBlock": hex(b), "toBlock": hex(e),
                                        "topics": [TOPIC]}])
        except Exception as ex:  # noqa: BLE001
            print("getLogs failed", b, e, str(ex)[:160])
            ls = []
        logs.extend(ls)
        b = e + 1
    events = []
    for l in logs:
        try:
            # debtAsset and user are INDEXED (topics[1], topics[2]); the rest is in data
            assets, amounts, debt_cover, liquidator, method = abi_decode(
                ["address[]", "uint256[]", "uint256", "address", "uint8"],
                bytes.fromhex(l["data"][2:]))
            debt_asset = "0x" + l["topics"][1][-40:]
            user = "0x" + l["topics"][2][-40:]
        except Exception as ex:  # noqa: BLE001
            print("decode failed", l["transactionHash"], str(ex)[:120])
            continue
        # seize value at marks: sum(amount * price)
        seize = 0.0
        for a, amt in zip(assets, amounts):
            seize += amt * marks.get(a.lower(), 0) / 1e18
        dd = 6 if debt_asset.lower() == "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83" else 18
        events.append({"block": int(l["blockNumber"], 16), "tx": l["transactionHash"],
                       "liquidator": liquidator.lower(), "user": user.lower(),
                       "debt_asset": debt_asset.lower(), "debt_repaid": str(debt_cover),
                       "debt_repaid_usd": round(debt_cover / 10 ** dd, 2),
                       "method": method, "seize_usd_marks": round(seize, 2),
                       "assets": [a.lower() for a in assets], "amounts": [str(x) for x in amounts]})

    by_liq = {}
    for e in events:
        d = by_liq.setdefault(e["liquidator"], {"count": 0, "debt_repaid": 0.0, "seize_usd_marks": 0.0,
                                                "methods": set(), "last_block": 0})
        d["count"] += 1
        # debt in 18-dec WXDAI or 6-dec USDC
        dec = 6 if e["debt_asset"] == "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83" else 18
        d["debt_repaid"] += e["debt_repaid_usd"]
        d["seize_usd_marks"] += e["seize_usd_marks"]
        d["methods"].add(e["method"])
        d["last_block"] = max(d["last_block"], e["block"])
    for d in by_liq.values():
        d["methods"] = sorted(d["methods"])
        d["debt_repaid"] = round(d["debt_repaid"], 2)
        d["seize_usd_marks"] = round(d["seize_usd_marks"], 2)

    out = {
        "chain": "gnosis", "chain_id": 100, "block": block, "timestamp": ts,
        "safe": SAFE, "safe_details": safe,
        "exit_wallet": EXIT, "owner1": OWNER1,
        "holdings": holdings,
        "liquidations_30d": {
            "count": len(events),
            "by_liquidator": by_liq,
            "latest": events[-5:],
            "total_debt_repaid": round(sum(e["debt_repaid_usd"] for e in events), 2),
            "total_seize_usd_marks": round(sum(e["seize_usd_marks"] for e in events), 2),
        },
    }
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "incumbent.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=2)
    print("wrote", p)
    print("safe owners", safe)
    print("holdings", {k: v["value_usd_marks"] for k, v in holdings.items()})
    print("liquidations 30d", len(events), "top:", sorted(by_liq.items(), key=lambda kv: -kv[1]["count"])[:4])
    if events:
        print("latest", events[-1])


if __name__ == "__main__":
    main()
