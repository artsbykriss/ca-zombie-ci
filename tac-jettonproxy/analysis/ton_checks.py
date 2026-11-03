#!/usr/bin/env python3
"""Read-only TON checks for the TAC JettonProxy target (no tonpy required)."""
import base64
import json
import subprocess
import sys

PROXY = "EQAChAswsPNsU2k3A5ZDO_cfhWknCGS6WMG2Jz15USMwxMdw"
CCL = "EQAgpWmO8nBUrmfOOldIEmRkLEwV-IIfVAlJsphYswnuL80R"


def curl(url):
    return subprocess.run(
        ["curl", "-s", "-m", "30", "-A", "Mozilla/5.0", url], capture_output=True, text=True
    ).stdout


def jcurl(url, retries=4):
    import time
    for _ in range(retries):
        out = curl(url)
        try:
            return json.loads(out)
        except Exception:
            time.sleep(1.5)
    return {}


def main():
    exp = json.load(open("analysis/expected_codes.json"))
    out = {}
    for name, addr in [("proxy", PROXY), ("ccl", CCL)]:
        st = jcurl(f"https://toncenter.com/api/v3/addressInformation?address={addr}&use_v2=true")
        out[name] = {
            "address": addr,
            "balance_nanoton": int(st.get("balance", 0)),
            "last_transaction_lt": st.get("last_transaction_lt"),
            "status": st.get("status"),
            "code_match": st.get("code") == exp[f"{name}_code_b64"],
            "expected_code_hash": exp[f"{name}_code_hash"],
        }

    j = jcurl(f"https://tonapi.io/v2/accounts/{PROXY}/jettons")
    verified = []
    for b in j.get("balances", []):
        jet = b["jetton"]
        if jet.get("verification") == "blacklist":
            continue
        amt = int(b["balance"]) / 10 ** jet["decimals"]
        if amt > 0:
            verified.append(
                {
                    "symbol": jet["symbol"],
                    "master": jet["address"],
                    "amount": amt,
                    "verification": jet.get("verification"),
                }
            )
    out["verified_jettons"] = verified

    tx = jcurl(
        "https://toncenter.com/api/v3/transactions"
        "?account=0:02840b30b0f36c5369370396433bf71f8569270864ba58c1b6273d79512330c4&limit=200",
        retries=4,
    )
    from collections import Counter

    if tx.get("transactions"):
        inops, outops = Counter(), Counter()
        for t in tx.get("transactions", []):
            inops[(t.get("in_msg") or {}).get("opcode")] += 1
            for m in t.get("out_msgs", []):
                outops[m.get("opcode")] += 1
        out["tx_n"] = len(tx.get("transactions", []))
        out["in_ops"] = dict(inops)
        out["out_ops"] = dict(outops)
        out["tx_source"] = "live toncenter"
    else:
        committed = json.load(open("analysis/tx_op_counts.json"))
        out["tx_n"] = committed.get("n_txs", 0)
        out["in_ops"] = committed.get("in_ops", {})
        out["out_ops"] = committed.get("out_ops", {})
        out["tx_source"] = "committed 200-tx sample (live endpoint unavailable)"
    json.dump(out, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
