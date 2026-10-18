"""Recompute the liquidatable RealT RMM v3 borrower census, live. Read-only.

Source of borrower set: Blockscout v2 holders of the three variable-debt tokens
(WXDAI / USDC / REUSD) -> dedupe -> Multicall3.getUserAccountData.

Writes analysis/census.json.
"""
import json
import os
import sys
import time

import requests

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

POOL = "0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3"
WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
BS = "https://gnosis.blockscout.com/api/v2"
DEBT_TOKENS = {
    "WXDAI": "0x9908801df7902675c3fedd6fea0294d18d5d5d34",
    "USDC": "0x69c731ae5f5356a779f44c355abb685d84e5e9e6",
    "REUSD": "0x00eddae5c334bfe4e929c775aaa7aee1a116e077",
}
S = requests.Session()
S.headers.update({"user-agent": "zh4-research/1.0"})


def holders(token):
    url = f"{BS}/tokens/{token}/holders"
    params = {}
    seen, out = set(), []
    for _ in range(200):
        r = S.get(url, params=params, timeout=40)
        r.raise_for_status()
        j = r.json()
        items = j.get("items", [])
        for it in items:
            a = it["address"]["hash"]
            if a.lower() not in seen:
                seen.add(a.lower())
                out.append(a)
        nxt = j.get("next_page_params")
        if not nxt or not items:
            break
        params = nxt
        time.sleep(0.15)
    return out


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    print("block", block, "ts", ts)

    borrowers, per_token = {}, {}
    for name, tok in DEBT_TOKENS.items():
        hs = holders(tok)
        per_token[name] = len(hs)
        print(name, "debt-token holders", len(hs))
        for a in hs:
            borrowers.setdefault(a.lower(), []).append(name)

    addrs = sorted(borrowers)
    print("unique borrower addresses", len(addrs))

    sig = "getUserAccountData(address)(uint256,uint256,uint256,uint256,uint256,uint256)"
    calls = [(POOL, g.sel(sig) + g.abi_encode(["address"], [a]).hex()) for a in addrs]
    res = g.multicall(calls, block=block)

    rows = []
    for a, (ok, ret) in zip(addrs, res):
        if not ok or len(ret) < 192:
            continue
        v = g.abi_decode(["uint256"] * 6, ret)
        coll = v[0] / 1e8
        debt = v[1] / 1e8
        hf = v[5] / 1e18
        rows.append({
            "address": a,
            "debt_tokens": borrowers[a],
            "collateral_usd_marks": round(coll, 2),
            "debt_usd": round(debt, 2),
            "hf": hf,
            "lt_bps": v[3],
            "ltv_bps": v[4],
        })

    live = [r for r in rows if r["debt_usd"] > 0.01]
    under = [r for r in live if r["hf"] < 1.0]
    for r in under:
        cf = 1.0 if r["hf"] <= 0.95 else 0.5
        dmax = min(r["debt_usd"] * cf, r["collateral_usd_marks"] / 1.1)
        r["close_factor"] = cf
        r["max_repay_usd"] = round(dmax, 2)
        r["max_seize_usd_marks"] = round(dmax * 1.1, 2)
        r["bonus_usd_marks"] = round(dmax * 0.10, 2)
    under.sort(key=lambda x: -x["bonus_usd_marks"])

    out = {
        "chain": "gnosis", "chain_id": 100, "block": block, "timestamp": ts,
        "borrower_holders_per_debt_token": per_token,
        "unique_borrowers": len(addrs),
        "live_borrowers": len(live),
        "liquidatable_count": len(under),
        "total_debt_usd": round(sum(r["debt_usd"] for r in live), 2),
        "liquidatable_debt_usd": round(sum(r["debt_usd"] for r in under), 2),
        "liquidatable_collateral_usd_marks": round(sum(r["collateral_usd_marks"] for r in under), 2),
        "one_shot_bonus_pool_usd_marks": round(sum(r["bonus_usd_marks"] for r in under), 2),
        "top20_bonus_usd_marks": round(sum(r["bonus_usd_marks"] for r in under[:20]), 2),
        "top": under[:30],
        "all_liquidatable": [{"address": r["address"], "hf": r["hf"], "debt_usd": r["debt_usd"],
                              "collateral_usd_marks": r["collateral_usd_marks"],
                              "bonus_usd_marks": r["bonus_usd_marks"]} for r in under],
    }
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "census.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=2)
    print("wrote", p)
    print(json.dumps({k: v for k, v in out.items() if not isinstance(v, list)}, indent=1))
    for r in under[:10]:
        print(f'{r["address"]}  coll ${r["collateral_usd_marks"]:,.0f} debt ${r["debt_usd"]:,.0f} '
              f'HF {r["hf"]:.4f} bonus ${r["bonus_usd_marks"]:,.0f}')


if __name__ == "__main__":
    main()
