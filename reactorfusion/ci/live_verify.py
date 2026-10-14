#!/usr/bin/env python3
"""CI live-verification harness for ReactorFusion (zkSync Era + Telos).

Read-only. Uses only public/keyless RPCs by default; may use env DRPC_API_KEY
(never stored/printed). Writes results to ../ci-out/live-verification.json
and prints a summary.

Verifies, at a fresh block:
  * market state (cash/borrows/supply/exchange rate/prices)
  * oracle = Chainlink latestAnswer()*scale with NO staleness check + feed freshness
  * admin / reserves / oracle-owner gates (all revert or return unauthorized for an attacker)
  * borrow without collateral reverts
  * liquidation is permissionless (liquidateBorrowAllowed from a random address)
  * simulated liquidation on the live node (eth_call with state override) + profit math
  * aggregate realistic liquidation profit over the underwater candidate set
  * borrow-and-default unprofitability (collateralFactor * oracle/market < 1)
"""
import json, os, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "analysis"))
from rpclib import RPC, default_urls, calldata, dec  # noqa: E402

ERA_COMPTROLLER = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
ERA_ORACLE = "0x1d54DD49218333125C858c0239bbdA424db55C43"
ERA_MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH": "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC": "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT": "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK": "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDCz": "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
ERA_FEEDS = {
    "ETH/USD": ("0x6D41d1dc818112880b40e26BD6FD347E41008eDA", "rfETH"),
    "BTC/USD": ("0x4Cba285c15e3B540C474A114a7b135193e4f1EA6", "rfWBTC"),
    "USDC/USD": ("0x1824D297C6d6D311A204495277B63e943C2D376E", "rfUSDCe"),
    "USDT/USD": ("0xB615075979AE1836B476F651f1eB79f0Cd3956a9", "rfUSDT"),
    "ZK/USD": ("0xd1CE60DC8AE060dDD17cA8716c96f193BC88DD13", "rfZK"),
}
# DefiLlama spot (2026-10-14) for the borrow-and-default condition test
MARKET_PRICES = {
    "rfUSDCe": 0.999735, "rfETH": 2442.41, "rfWBTC": 81708.15,
    "rfUSDT": 0.999306, "rfZK": 0.0151557, "rfUSDCz": 0.999724,
}
ATTACKER = "0x1111111111111111111111111111111111111111"
NAME_MAP = {"rfUSDC": "rfUSDCz"}  # phase-2 scan name -> this script's name
# candidates: underwater accounts found at block 72477761 (child scan) + biggest debtors
CANDIDATES_FILE = os.path.join(HERE, "..", "analysis", "era-positions-raw.json")


def pct(x):
    return f"{x*100:.4f}%"


def main():
    rpc = RPC(default_urls("era"), "era")
    t_start = time.time()
    out = {"generated_at": int(time.time()), "chain": "era", "read_only": True}
    blk = rpc.block_number()
    out["block"] = blk
    C = ERA_COMPTROLLER
    print(f"[live_verify] block={blk}", flush=True)

    # ---------- 1. market state ----------
    mk_state = {}
    calls, keys = [], []
    for name, m in ERA_MARKETS.items():
        for sig, ot in [("getCash()", ["uint256"]), ("totalBorrows()", ["uint256"]), ("totalSupply()", ["uint256"]),
                        ("exchangeRateStored()", ["uint256"]), ("reserveFactorMantissa()", ["uint256"]),
                        ("decimals()", ["uint8"]), ("protocolSeizeShareMantissa()", ["uint256"])]:
            calls.append((m, calldata(sig, (), ()))); keys.append((name, sig, ot))
        calls.append((ERA_ORACLE, calldata("getUnderlyingPrice(address)", ["address"], [m])))
        keys.append((name, "oraclePrice", ["uint256"]))
        calls.append((C, calldata("markets(address)", ["address"], [m])))
        keys.append((name, "marketInfo", ["bool", "uint256"]))
        calls.append((C, calldata("borrowCaps(address)", ["address"], [m])))
        keys.append((name, "borrowCap", ["uint256"]))
        calls.append((C, calldata("borrowGuardianPaused(address)", ["address"], [m])))
        keys.append((name, "borrowPaused", ["bool"]))
        calls.append((C, calldata("mintGuardianPaused(address)", ["address"], [m])))
        keys.append((name, "mintPaused", ["bool"]))
    res = rpc.try_calls(calls)
    for (name, sig, ot), (raw, err) in zip(keys, res):
        e = mk_state.setdefault(name, {})
        if raw is None:
            e[sig] = {"err": err}; continue
        try:
            v = dec(ot, raw)
            e[sig] = list(v) if len(v) > 1 else v[0]
        except Exception as ex:
            e[sig] = {"raw": raw[:40], "err": str(ex)}
    out["markets"] = mk_state
    print(f"[live_verify] markets read ({time.time()-t_start:.0f}s)", flush=True)

    # ---------- 2. oracle freshness / no staleness check ----------
    feeds = {}
    for fname, (faddr, mkt) in ERA_FEEDS.items():
        lr, err = rpc.try_call(faddr, "latestRoundData()", (), (),
                               ["uint80", "int256", "uint256", "uint256", "uint80"])
        decv, _ = rpc.try_call(faddr, "decimals()", (), (), ["uint8"])
        if lr and not err:
            answer, updated_at = lr[1], lr[3]
            fd = decv[0]
            cd = mk_state[mkt]["decimals()"]
            expected = answer * (10 ** (36 - fd - cd))
            live_price = mk_state[mkt]["oraclePrice"]
            feeds[fname] = {"feed": faddr, "market": mkt, "answer": str(answer), "decimals": fd,
                            "updated_at": updated_at, "age_s": int(time.time()) - updated_at,
                            "oracle_price": str(live_price), "oracle_eq_latestAnswer_scaled": expected == live_price,
                            "scale": 36 - fd - cd}
        else:
            feeds[fname] = {"feed": faddr, "err": err}
    out["feeds"] = feeds
    print(f"[live_verify] feeds read ({time.time()-t_start:.0f}s)", flush=True)

    # ---------- 3. gates ----------
    gates = {}
    for name, sig, ot in [("closeFactor", "closeFactorMantissa()", ["uint256"]),
                          ("liqIncentive", "liquidationIncentiveMantissa()", ["uint256"]),
                          ("admin", "admin()", ["address"]), ("oracle", "oracle()", ["address"])]:
        v, err = rpc.try_call(C, sig, (), (), ot)
        gates[name] = {"v": (str(v[0]) if v else None), "err": err}
    v, err = rpc.try_call(ERA_ORACLE, "owner()", (), (), ["address"])
    gates["oracle_owner"] = {"v": v[0] if v else None, "err": err}
    # borrow without collateral must revert
    for mname, m in [("rfETH", ERA_MARKETS["rfETH"]), ("rfUSDCe", ERA_MARKETS["rfUSDCe"])]:
        raw, err = rpc.try_call(m, "borrow(uint256)", ["uint256"], [10 ** 16 if mname == "rfETH" else 10 ** 6])
        gates[f"borrow_without_collateral_{mname}"] = {"reverted": raw is None, "err": err}
    # takeReserves must revert for attacker (eth_call with from=attacker)
    def call_from(to, sig, types=(), vals=(), sender=ATTACKER):
        data = calldata(sig, types, vals)
        try:
            r = rpc.call("eth_call", [{"to": to, "from": sender, "data": data}, "latest"])
            return {"ok": True, "raw": r[:80]}
        except Exception as e:
            return {"ok": False, "err": str(e)[:160]}
    gates["takeReserves_attacker"] = call_from(ERA_MARKETS["rfETH"], "takeReserves()")
    gates["setPriceFeed_attacker"] = call_from(ERA_ORACLE, "setPriceFeed(address,address)",
                                               ["address", "address"], [ERA_MARKETS["rfETH"], ATTACKER])
    gates["_setPriceOracle_attacker"] = call_from(C, "_setPriceOracle(address)", ["address"], [ATTACKER])
    gates["_reduceReserves_attacker"] = call_from(ERA_MARKETS["rfETH"], "_reduceReserves(uint256)", ["uint256"], [1])
    try:
        gates["harvest_fresh_account"] = call_from(
            "0x53C0DE201cab0b3f74EA7C1D95bD76F76EfD12A9", "harvest(bytes32[])",
            ["bytes32[]"], [[bytes(32)]])
    except Exception as ex:
        gates["harvest_fresh_account"] = {"ok": None, "err": str(ex)[:120]}
    out["gates"] = gates
    print(f"[live_verify] gates checked ({time.time()-t_start:.0f}s)", flush=True)

    # ---------- 4. liquidation: permissionless + simulated execution + profit ----------
    # Candidates: the top underwater accounts from the pinned phase-2 scan (block 72477761).
    # For each we re-read LIVE liquidity/debt/collateral on only the markets it actually uses.
    cand_info = {}
    if os.path.exists(CANDIDATES_FILE):
        raw = json.load(open(CANDIDATES_FILE))
        maxacc = int(os.environ.get("LIVE_VERIFY_MAX_ACCOUNTS", "20"))
        uw = sorted(raw.get("underwater", []), key=lambda a: -a.get("shortfall_usd", 0))
        for a in uw[:maxacc]:
            cand_info[a["account"]] = {
                "debt_markets": [NAME_MAP.get(k, k) for k, v in (a.get("debt") or {}).items() if v.get("usd", 0) > 0.01 and NAME_MAP.get(k, k) in ERA_MARKETS],
                "coll_markets": [NAME_MAP.get(k, k) for k, v in (a.get("collateral") or {}).items() if v.get("usd", 0) > 0.001 and NAME_MAP.get(k, k) in ERA_MARKETS],
                "shortfall_usd_pinned": a.get("shortfall_usd"),
            }
        for p in sorted(raw.get("positions", []), key=lambda p: -p.get("debt_usd", 0))[:5]:
            cand_info.setdefault(p["account"], {
                "debt_markets": [NAME_MAP.get(k, k) for k, v in (p.get("debt") or {}).items() if v.get("usd", 0) > 0.01 and NAME_MAP.get(k, k) in ERA_MARKETS],
                "coll_markets": [NAME_MAP.get(k, k) for k, v in (p.get("collateral") or {}).items() if v.get("usd", 0) > 0.001 and NAME_MAP.get(k, k) in ERA_MARKETS],
                "shortfall_usd_pinned": p.get("shortfall_usd"),
            })

    snap = {}
    calls, keys = [], []
    for acct, info in cand_info.items():
        calls.append((C, calldata("getAccountLiquidity(address)", ["address"], [acct])))
        keys.append((acct, "liq", ["uint256", "uint256", "uint256"]))
        for name in info["debt_markets"]:
            calls.append((ERA_MARKETS[name], calldata("borrowBalanceStored(address)", ["address"], [acct])))
            keys.append((acct, f"debt_{name}", ["uint256"]))
        for name in info["coll_markets"]:
            calls.append((ERA_MARKETS[name], calldata("balanceOf(address)", ["address"], [acct])))
            keys.append((acct, f"coll_{name}", ["uint256"]))
    res = rpc.try_calls(calls)
    for (acct, tag, ot), (raw, err) in zip(keys, res):
        e = snap.setdefault(acct, {})
        if raw is None:
            e[tag] = None; continue
        try:
            v = dec(ot, raw)
            e[tag] = [str(x) for x in v] if len(v) > 1 else str(v[0])
        except Exception:
            e[tag] = None
    out["snapshots"] = snap
    print(f"[live_verify] snapshots read ({time.time()-t_start:.0f}s, n={len(snap)})", flush=True)

    mk = out["markets"]
    def price(name):
        return int(mk[name]["oraclePrice"]) / 10 ** (36 - mk[name]["decimals()"])
    mkt_price = MARKET_PRICES

    underwater = []
    total_profit = 0.0
    for acct, s in snap.items():
        liq = s.get("liq")
        if not liq:
            continue
        shortfall = int(liq[2])
        if shortfall <= 0:
            continue  # not liquidatable: no shortfall, no opportunity
        debts = {n: int(s.get(f"debt_{n}") or 0) for n in ERA_MARKETS}
        colls = {n: int(s.get(f"coll_{n}") or 0) for n in ERA_MARKETS}
        if sum(debts.values()) == 0:
            continue
        best = 0.0; best_desc = None
        for dn, dv in debts.items():
            if dv == 0:
                continue
            debt_usd = dv / 10 ** mk[dn]["decimals()"] * price(dn)
            for cn, cv in colls.items():
                if cv == 0:
                    continue
                coll_underlying = cv * int(mk[cn]["exchangeRateStored()"]) / 1e18
                coll_usd = coll_underlying / 10 ** mk[cn]["decimals()"] * price(cn)
                max_repay = min(0.5 * debt_usd, coll_usd / 1.08)
                if max_repay <= 0:
                    continue
                val = max_repay * 1.08 * (1 - 0.028) * (mkt_price[cn] / price(cn)) * (price(dn) / mkt_price[dn])
                profit = val - max_repay
                if profit > best:
                    best = profit
                    best_desc = {"debt_market": dn, "coll_market": cn, "repay_usd": round(max_repay, 4),
                                 "seize_market_value_usd": round(val, 4)}
        underwater.append({"account": acct, "shortfall_usd": shortfall / 1e18, "profit_usd": round(best, 6),
                           "best": best_desc})
        if best > 0:
            total_profit += best
    underwater.sort(key=lambda x: -x["profit_usd"])
    out["liquidation_analysis"] = {"accounts_checked": len(cand_info), "underwater_with_profit": sum(1 for u in underwater if u["profit_usd"] > 0),
                                   "top": underwater[:15], "total_realistic_profit_usd": round(total_profit, 4)}

    # permissionless + simulated execution for the top candidate
    sim = {}
    # prefer an underwater account whose debt market is the native-ETH market: the liquidation
    # then needs no ERC20 allowance and can execute end-to-end in a single eth_call
    pick = None
    for u in underwater:
        if u.get("best") and u["best"]["debt_market"] == "rfETH":
            pick = u
            break
    if pick is None and underwater:
        pick = underwater[0]
    if pick and pick.get("best"):
        acct = pick["account"]
        dname = pick["best"]["debt_market"]
        cname = pick["best"]["coll_market"]
        dm = ERA_MARKETS[dname]
        cm = ERA_MARKETS[cname]
        debt = int(snap[acct].get(f"debt_{dname}") or 0)
        repay = debt // 2  # closeFactor 0.5
        allow = call_from(C, "liquidateBorrowAllowed(address,address,address,address,uint256)",
                          ["address", "address", "address", "address", "uint256"],
                          [dm, cm, ATTACKER, acct, repay])
        sim["liquidateBorrowAllowed_attacker"] = allow
        sim["target"] = {"account": acct, "debt_market": dname, "coll_market": cname, "repay": str(repay)}
        if repay > 0:
            is_eth_market = dname == "rfETH"
            if is_eth_market:
                data = calldata("liquidateBorrow(address,address)", ["address", "address"], [acct, cm])
                params = [{"from": ATTACKER, "to": dm, "data": data, "value": hex(repay)}, "latest",
                          {ATTACKER: {"balance": hex(repay + 10 ** 15)}}]
            else:
                data = calldata("liquidateBorrow(address,uint256,address)", ["address", "uint256", "address"],
                                [acct, repay, cm])
                params = [{"from": ATTACKER, "to": dm, "data": data}, "latest",
                          {ATTACKER: {"balance": hex(10 ** 18)}}]
            try:
                r = rpc.call("eth_call", params)
                sim["simulated_liquidation"] = {"ok": True, "return": r[:80], "repay": str(repay)}
            except Exception as e:
                sim["simulated_liquidation"] = {"ok": False, "err": str(e)[:200], "repay": str(repay)}
            raw, err = rpc.try_call(C, "liquidateCalculateSeizeTokens(address,address,uint256)",
                                    ["address", "address", "uint256"], [dm, cm, repay], ["uint256", "uint256"])
            sim["seize_tokens"] = {"raw": raw, "err": err}
    out["liquidation_simulation"] = sim
    print(f"[live_verify] simulation done ({time.time()-t_start:.0f}s)", flush=True)

    # ---------- 5. borrow-and-default condition ----------
    bad = {}
    for name, m in ERA_MARKETS.items():
        mi = mk[name].get("marketInfo")
        if not mi:
            continue
        cf = mi[1] / 1e18
        ratio = price(name) / mkt_price[name]
        bad[name] = {"cf": cf, "oracle_over_market": round(ratio, 6),
                     "borrow_power_per_market_dollar": round(cf * ratio, 6),
                     "profitable_default": cf * ratio > 1}
    out["borrow_and_default"] = bad

    os.makedirs(os.path.join(HERE, "..", "ci-out"), exist_ok=True)
    with open(os.path.join(HERE, "..", "ci-out", "live-verification.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps({
        "block": blk,
        "cash_eth": mk["rfETH"].get("getCash()"),
        "feeds_age_s": {k: v.get("age_s") for k, v in feeds.items()},
        "oracle_scaled_ok": {k: v.get("oracle_eq_latestAnswer_scaled") for k, v in feeds.items()},
        "gates": {k: (v.get("reverted") if "reverted" in v else v.get("ok")) for k, v in gates.items()},
        "liq": out["liquidation_analysis"]["total_realistic_profit_usd"],
        "liq_top": out["liquidation_analysis"]["top"][:3],
        "sim": sim.get("simulated_liquidation"),
        "borrow_default_profitable": {k: v["profitable_default"] for k, v in bad.items()},
    }, indent=1))


if __name__ == "__main__":
    main()
