#!/usr/bin/env python3
"""World Markets Spot (Concord Exchange, MegaETH) — read-only live state dump.

Runs on the CI runner. Uses ONLY the keyless public MegaETH RPC and the public
DefiLlama price API. No keys, no secrets, no transactions. Writes results to ci-out/.
"""
import json
import os
import sys
import time
import urllib.request
from collections import defaultdict

RPC = os.environ.get("MEGAETH_RPC", "https://mainnet.megaeth.com/rpc")
EX = "0x5e3Ae52EbA0F9740364Bd5dd39738e1336086A8b"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")

TOKENS = [1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
ATTACKER = "0x0000000000000000000000000000000000001111"

HDR = {"content-type": "application/json", "User-Agent": "Mozilla/5.0 (research; read-only)"}


def rpc_batch(calls, chunk=40, tries=6):
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        for a in range(tries):
            try:
                body = [{"jsonrpc": "2.0", "id": j, "method": m, "params": p}
                        for j, (m, p) in enumerate(part)]
                req = urllib.request.Request(RPC, json.dumps(body).encode(), HDR)
                res = json.load(urllib.request.urlopen(req, timeout=180))
                if isinstance(res, dict):
                    raise RuntimeError(str(res)[:120])
                res.sort(key=lambda x: x["id"])
                out += res
                break
            except Exception as e:  # noqa: BLE001
                if a == tries - 1:
                    print(f"  ! chunk {i} failed: {e}", file=sys.stderr)
                    out += [{}] * len(part)
                else:
                    time.sleep(2)
    return out


def pad(x, n=64):
    return hex(x)[2:].rjust(n, "0")


BLOCK_TAG = "latest"


def call(to, data, frm=None):
    obj = {"to": to, "data": data}
    if frm:
        obj["from"] = frm
    return ("eth_call", [obj, BLOCK_TAG])


def call_one(to, data, frm):
    """Single (non-batched) eth_call — the batched RPC drops revert data on MegaETH."""
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"from": frm, "to": to, "data": data}, BLOCK_TAG]}).encode()
    for a in range(4):
        try:
            o = json.load(urllib.request.urlopen(urllib.request.Request(RPC, body, HDR), timeout=60))
            if "error" in o:
                return {"error": o["error"]}
            return {"result": o.get("result")}
        except Exception:  # noqa: BLE001
            time.sleep(1)
    return {"error": {"message": "rpc failed"}}


def main():
    os.makedirs(OUT, exist_ok=True)
    res = {"rpc": RPC, "generated_at": int(time.time())}

    bn = int(rpc_batch([("eth_blockNumber", [])])[0]["result"], 16)
    global BLOCK_TAG
    BLOCK_TAG = hex(bn)  # pin every read to this block for an exact reconciliation
    res["block"] = bn
    print("block", bn, "(all reads pinned to this block)")

    # --- token configs ---
    rr = rpc_batch([call(EX, "0xefd8ded2" + pad(i)) for i in TOKENS])
    tokens = {}
    for tid, o in zip(TOKENS, rr):
        v = o.get("result")
        if not v or v == "0x":
            continue
        x = int(v, 16)
        if x == 0:
            continue
        tokens[tid] = {
            "address": "0x" + f"{x & ((1 << 160) - 1):040x}",
            "sequestrationMultiplier": (x >> 160) & 0xFF,
            "positionDecimals": (x >> 168) & 0xFF,
            "vaultDecimals": (x >> 176) & 0xFF,
            "erc20Decimals": (x >> 184) & 0xFF,
            "tokenType": (x >> 192) & 0xFF,
            "riskPricePercent": (x >> 232) & 0xFF,
            "riskSlippagePercentx10": (x >> 240) & 0xFF,
        }
    res["tokens"] = {str(k): v for k, v in tokens.items()}
    print("tokens", len(tokens))

    # --- order books ---
    pairs = [(a, b) for a in range(1, 14) for b in range(1, 14) if a != b]
    books = {}
    for label, sel in (("spot", "0x828daa7e"), ("perp", "0x328f58e2")):
        rr = rpc_batch([call(EX, sel + pad(a) + pad(b)) for a, b in pairs])
        got = {}
        for (a, b), o in zip(pairs, rr):
            v = o.get("result")
            if v and v != "0x" and len(v) >= 2 + 192:
                addr = "0x" + v[2 + 24:2 + 64]
                if addr != "0x" + "0" * 40:
                    got[f"{a},{b}"] = {"book": addr,
                                       "buyToken": int(v[2 + 64:2 + 128], 16),
                                       "payToken": int(v[2 + 128:2 + 192], 16)}
        books[label] = got
    rr = rpc_batch([call(EX, "0x73d848dd" + pad(i)) for i in range(1, 14)])
    lend = {}
    for i, o in zip(range(1, 14), rr):
        v = o.get("result")
        if v and v != "0x" and int(v, 16) != 0:
            lend[str(i)] = "0x" + v[-40:]
    books["lend"] = lend
    res["books"] = books
    print("books spot/perp/lend", len(books["spot"]), len(books["perp"]), len(books["lend"]))

    # --- exchange balances + maxUserId ---
    rr = rpc_batch([call(t["address"], "0x70a08231" + pad(int(EX, 16))) for t in tokens.values()])
    ex_bal = {}
    for (tid, _), o in zip(tokens.items(), rr):
        v = o.get("result")
        ex_bal[str(tid)] = str(int(v, 16)) if v and v != "0x" else "0"
    res["exchange_balances_raw"] = ex_bal
    mv = rpc_batch([call(EX, "0xffffff20")])[0].get("result")
    max_user = int(mv, 16) if mv and mv != "0x" else 0
    limit = int(os.environ.get("MAX_USER_LIMIT", "0") or "0")
    if limit:
        max_user = min(max_user, limit)
    res["max_user_id"] = max_user
    print("maxUserId", max_user, "exchange balances", ex_bal)

    # --- full user x token balance scan ---
    calls, keys = [], []
    for u in range(1, max_user + 1):
        for t in tokens:
            calls.append(call(EX, "0x761966b7" + pad(u) + pad(t)))
            keys.append((u, t))
    rr = rpc_batch(calls)
    users = {}
    sum_bal = defaultdict(int)
    sum_seq = defaultdict(int)
    sum_perp = defaultdict(int)
    pairs_active = 0
    for (u, t), o in zip(keys, rr):
        v = o.get("result")
        if not v or v == "0x" or len(v) < 2 + 192:
            continue
        h = v[2:]
        w0, w1, w2 = int(h[0:64], 16), int(h[64:128], 16), int(h[128:192], 16)
        if w0 or w1 or w2:
            users.setdefault(str(u), {})[str(t)] = {"bal": str(w0), "spotSeq": str(w1), "perpSeq": str(w2)}
            sum_bal[t] += w0
            sum_seq[t] += w1
            sum_perp[t] += w2
            pairs_active += 1
    res["user_scan"] = {
        "active_user_token_pairs": pairs_active,
        "users_with_balances": len(users),
        "sum_balance_raw": {str(k): str(v) for k, v in sum_bal.items()},
        "sum_spot_seq_raw": {str(k): str(v) for k, v in sum_seq.items()},
        "sum_perp_seq_raw": {str(k): str(v) for k, v in sum_perp.items()},
    }
    print("scan: pairs", pairs_active, "users", len(users))

    # --- verification: user balances == exchange custody ---
    checks = {}
    for t in tokens:
        eb = int(ex_bal.get(str(t), "0"))
        ub = sum_bal.get(t, 0)
        checks[str(t)] = {"exchange_raw": str(eb), "user_sum_raw": str(ub),
                          "delta_raw": str(eb - ub),
                          "unattributed_raw": str(eb - ub)}
    res["custody_reconciliation"] = checks
    res["custody_reconciled_exactly"] = all(v["delta_raw"] == "0" for v in checks.values())
    print("custody reconciled exactly:", res["custody_reconciled_exactly"])

    # --- permission matrix from a fresh unprivileged address ---
    matrix = []
    tests = [
        ("withdrawErc20(USDm,1)", "0xbd1f4b52" + pad(int(tokens[1]["address"], 16)) + pad(1)),
        ("depositErc20(USDm,1)", "0x6548b40d" + pad(int(tokens[1]["address"], 16)) + pad(1)),
        ("batchCommands(265,[])", "0xd803a4cf" + pad(265) + pad(32) + pad(0)),
        ("liquidate(265,265,0)", "0xc4019421" + pad(265) + pad(265) + pad(0)),
        ("payInterestAndFees(1,0,false)", "0x9d1c4c83" + pad(1) + pad(0) + pad(0)),
        ("markLendPositionAsNonReturnable(1)", "0xe3a898e0" + pad(1)),
        ("lifoLenderSwap(1)", "0x51e3716b" + pad(1)),
        ("renewLoan(265,265,0)", "0x2e618812" + pad(265) + pad(265) + pad(0)),
        ("bankruptcy(265,10000)", "0x91680b93" + pad(265) + pad(10000)),
        ("requestPerpTrueUp(1,1,4)", "0x9598c7b1" + pad(1) + pad(1) + pad(4)),
        ("allowTradingForAccount(265,attacker)", "0xf42dcf0a" + pad(265) + pad(int(ATTACKER, 16))),
        ("newSpotBuyOrder(book,0)", "0x5175cbc6" + pad(int(books["spot"]["4,1"]["book"], 16)) + pad(0)),
        ("newLendOrder(lend1,0)", "0x64ee5a0c" + pad(int(lend["1"], 16)) + pad(0)),
        ("setTokenConfig(1,1,1)", "0xffffff88" + pad(1) + pad(1) + pad(1)),
        ("setOpsAddress(attacker)", "0x707789c5" + pad(int(ATTACKER, 16))),
        ("changeAdmin(attacker)", "0xffffff42" + pad(int(ATTACKER, 16))),
        ("switchTokenAddress(1,attacker,[])", "0xffffff97" + pad(1) + pad(int(ATTACKER, 16)) + pad(96) + pad(0)),
        ("liqSwap(265,0,0)", "0xffffffa1" + pad(265) + pad(0) + pad(0)),
        ("book.haltTrading(true)", None),
        ("book.setMinOrderQuantity(1)", None),
    ]
    rr = [call_one(EX, d, ATTACKER) for _, d in tests if d]
    it = iter(rr)
    for name, d in tests:
        if d is None:
            continue
        o = next(it)
        if "error" in o:
            matrix.append({"call": name, "result": "revert",
                           "data": str(o["error"].get("data", ""))[:66],
                           "error": str(o["error"].get("message", ""))[:60]})
        else:
            matrix.append({"call": name, "result": "SUCCESS", "ret": str(o.get("result"))[:66]})
    # order book admin calls (targets the spot book)
    book = books["spot"]["4,1"]["book"]
    rr = [call_one(book, "0x795e38bb" + pad(1), ATTACKER),
          call_one(book, "0xbfa806b0" + pad(1), ATTACKER)]
    for name, o in zip(["book.haltTrading(true)", "book.setMinOrderQuantity(1)"], rr):
        if "error" in o:
            matrix.append({"call": name, "result": "revert",
                           "data": str(o["error"].get("data", ""))[:66],
                           "error": str(o["error"].get("message", ""))[:60]})
        else:
            matrix.append({"call": name, "result": "SUCCESS", "ret": str(o.get("result"))[:66]})
    res["permission_matrix"] = matrix
    unexpected = [m for m in matrix if m["result"] == "SUCCESS"]
    res["unprivileged_successes"] = unexpected
    print("unprivileged successes:", unexpected)

    # --- liquidatable set: risk-adjusted portfolio value for every user ---
    rr = rpc_batch([call(EX, "0xfb21a633" + pad(u)) for u in range(1, max_user + 1)])
    underwater = []
    for u, o in zip(range(1, max_user + 1), rr):
        v = o.get("result")
        if not v or v == "0x":
            continue
        x = int(v, 16)
        s = x - (1 << 256) if x >= (1 << 255) else x
        if s < 0:
            underwater.append({"userId": u, "riskAdjustedPortfolioValue": s})
    res["underwater_accounts"] = underwater
    res["underwater_count"] = len(underwater)
    print("underwater (liquidatable) accounts:", len(underwater), underwater[:10])

    # --- can an unprivileged keeper actually liquidate one? (state-less simulation) ---
    keeper = []
    for acct in underwater[:5]:
        r = call_one(EX, "0xc4019421" + pad(acct["userId"]) + pad(1) + pad(0), ATTACKER)
        keeper.append({"target": acct["userId"], "result": "revert" if "error" in r else "SUCCESS",
                       "data": str(r.get("error", {}).get("data", ""))[:66]})
    res["keeper_liquidate_probe"] = keeper
    print("keeper liquidate probe:", keeper)

    # --- prices (via single-call fallback; per-token so one bad key cannot fail all) ---
    prices = {}
    for t in tokens.values():
        try:
            pr = json.load(urllib.request.urlopen(urllib.request.Request(
                "https://coins.llama.fi/prices/current/megaeth:" + t["address"], headers=HDR),
                timeout=40))
            prices.update(pr.get("coins", {}))
        except Exception as e:  # noqa: BLE001
            res.setdefault("prices_error", []).append(str(e)[:120])
    res["prices"] = prices

    with open(os.path.join(OUT, "state.json"), "w") as fh:
        json.dump(res, fh, indent=1)
    with open(os.path.join(OUT, "permission_matrix.json"), "w") as fh:
        json.dump(matrix, fh, indent=1)
    print("wrote ci-out/state.json + ci-out/permission_matrix.json")

    if unexpected:
        print("FAIL: unprivileged call succeeded", file=sys.stderr)
        return 1
    if not res["custody_reconciled_exactly"]:
        print("WARN: custody not exactly reconciled (informational)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
