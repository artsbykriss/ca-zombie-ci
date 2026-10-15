#!/usr/bin/env python3
"""Fetch + decode oracle accounts for ALL marginfi banks.
Outputs oracles.json (decoded) and oracle_analysis.json (per-bank oracle vs market).
No secrets."""
import json, base64, sys, time, urllib.request, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decode_feed import decode_push, decode_legacy

ENDPOINTS = [os.environ.get("SOLANA_RPC", ""), "https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
ENDPOINTS = [e for e in ENDPOINTS if e]

def rpc(method, params, tries=8):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        ep = ENDPOINTS[i % len(ENDPOINTS)]
        try:
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as f:
                r = json.load(f)
            if "error" in r:
                last = r["error"]; time.sleep(1 + i); continue
            return r["result"]
        except Exception as e:
            last = str(e); time.sleep(1 + i)
    raise RuntimeError(f"rpc {method} failed: {last}")

PYTH_PUSH_OWNER = "rec2HHDDnjLfj4kE7VyEtFA1HPGQLK33259532cRyHp"
PYTH_RECEIVER_OWNER = "rec5EKMGg6MxZYaMdyBfgwp4d5rB9T1VQH5pJv5LtFJ"
PYTH_LEGACY_OWNER = "FsJ3A3u2vn5cTVofAjvy6y5kwABJAqYWpe4975bi2epH"

def main():
    banks = json.load(open("banks.json"))
    keys = {}
    for pk, b in banks.items():
        for k in b["config"]["oracle_keys"]:
            if k != "11111111111111111111111111111111":
                keys[k] = True
    addrs = list(keys)
    print("oracle accounts to fetch:", len(addrs), file=sys.stderr)
    out = {}
    for i in range(0, len(addrs), 100):
        chunk = addrs[i:i+100]
        res = rpc("getMultipleAccounts", [chunk, {"encoding": "base64"}])
        for a, v in zip(chunk, res["value"]):
            if v is None:
                out[a] = {"exists": False}
                continue
            raw = base64.b64decode(v["data"][0])
            owner = v["owner"]
            entry = {"exists": True, "owner": owner, "len": len(raw)}
            try:
                if owner in (PYTH_PUSH_OWNER, PYTH_RECEIVER_OWNER):
                    entry.update(decode_push(raw))
                elif owner == PYTH_LEGACY_OWNER:
                    entry.update(decode_legacy(raw))
                else:
                    entry["raw_hex_head"] = raw[:96].hex()
            except Exception as e:
                entry["decode_error"] = str(e)
            out[a] = entry
        print(f"fetched {min(i+100, len(addrs))}/{len(addrs)}", file=sys.stderr)
        time.sleep(0.3)
    json.dump(out, open("oracles.json", "w"), indent=1)
    now = int(time.time())
    print("now", now, file=sys.stderr)

    # per-bank analysis: use oracle_keys[0] price vs market price
    d = json.load(open("banks_valued.json"))
    rows = d["per_bank"]
    analysis = []
    for r in rows:
        b = banks[r["bank"]]
        ok0 = b["config"]["oracle_keys"][0]
        o = out.get(ok0, {})
        row = {"bank": r["bank"], "mint": r["mint"], "group": r["group"],
               "oracle_setup": b["config"]["oracle_setup"], "oracle_key": ok0,
               "op_state": b["config"]["operational_state"], "risk_tier": b["config"]["risk_tier"],
               "aw_init": b["config"]["asset_weight_init"], "aw_maint": b["config"]["asset_weight_maint"],
               "oracle_max_age": b["config"]["oracle_max_age"],
               "oracle_max_confidence": b["config"]["oracle_max_confidence"],
               "liq_usd": r["liquidity_vault_usd"], "ins_usd": r["insurance_vault_usd"],
               "borrows": r["borrowing_position_count"], "lends": r["lending_position_count"],
               "mkt_price": r["price_usd"],
               "oracle_price": o.get("price_usd"), "oracle_age_s": o.get("age_s"),
               "oracle_owner": o.get("owner"), "oracle_kind": o.get("kind"),
               "cb_tier": b["cb_tier"], "flags": b["flags"],
               "deposit_limit": b["config"]["deposit_limit"], "borrow_limit": b["config"]["borrow_limit"]}
        analysis.append(row)
    analysis.sort(key=lambda x: -(x["liq_usd"] or 0))
    json.dump(analysis, open("oracle_analysis.json", "w"), indent=1)

    # print suspicious rows: oracle price far from market OR stale
    print(f"{'bank':44} {'setup':18} {'op':12} {'age_h':>7} {'maxage_s':>8} {'oracle':>14} {'market':>14} {'ratio':>7} {'liq_usd':>12}")
    for a in analysis:
        if not a["liq_usd"] or a["liq_usd"] < 1000:
            continue
        op = a["oracle_price"]; mp = a["mkt_price"]
        ratio = (op / mp) if (op and mp) else None
        stale = (a["oracle_age_s"] is not None and a["oracle_max_age"] and a["oracle_age_s"] > a["oracle_max_age"])
        flag = "  <<<" if (ratio and (ratio > 1.15 or ratio < 0.87)) or stale else ""
        ageh = f"{(a['oracle_age_s'] or 0)/3600:.1f}" if a["oracle_age_s"] is not None else "?"
        print(f"{a['bank'][:42]:44} {a['oracle_setup']:18} {a['op_state']:12} {ageh:>7} {a['oracle_max_age']:>8} "
              f"{('' if op is None else f'{op:.8f}'):>14} {('' if mp is None else f'{mp:.8f}'):>14} "
              f"{('' if ratio is None else f'{ratio:.3f}'):>7} {(a['liq_usd'] or 0):>12,.0f}{flag}")

if __name__ == "__main__":
    main()
