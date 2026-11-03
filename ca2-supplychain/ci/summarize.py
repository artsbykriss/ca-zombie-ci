#!/usr/bin/env python3
"""Combine the CI outputs into a human-readable markdown summary."""
import json, os, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

def load(path, default=None):
    try:
        return json.load(open(path))
    except Exception:
        return default

def usd(x):
    return f"${x:,.2f}" if isinstance(x, (int, float)) else "n/a"

def main():
    btc = load(os.path.join(ROOT, "ci-out/btcpay/addresses.json"), {})
    fw = load(os.path.join(ROOT, "ci-out/fearless-wallet/verify.json"), {})
    store = load(os.path.join(ROOT, "ci-out/fearless-wallet/store.json"), {})
    lines = []
    lines.append("# ca2-supplychain — CI verification output\n")
    lines.append(f"Generated: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
    lines.append("Read-only: no keys, no signed transactions, no state changes.\n")

    lines.append("## BTCPay incident addresses\n")
    if btc.get("addresses"):
        lines.append(f"Prices: BTC {usd(btc.get('prices_usd',{}).get('bitcoin',{}).get('usd'))}, "
                     f"LTC {usd(btc.get('prices_usd',{}).get('litecoin',{}).get('usd'))}\n")
        lines.append("| chain | address | first seen | last seen | txs | received | current balance | received USD | balance USD |")
        lines.append("|---|---|---|---|---:|---:|---:|---:|---:|")
        for sym, a in btc["addresses"].items():
            lines.append(f"| {sym} | `{a['address']}` | {a.get('first_seen_utc')} | {a.get('last_seen_utc')} | "
                         f"{a.get('txs_paginated')} | {a.get('funded_native'):.8f} | {a.get('balance_native'):.8f} | "
                         f"{usd(a.get('funded_usd'))} | {usd(a.get('balance_usd'))} |")
        gross = sum(a.get("funded_usd", 0) for a in btc["addresses"].values())
        bal = sum(a.get("balance_usd", 0) for a in btc["addresses"].values())
        lines.append(f"\nCombined gross received at the two named addresses: **{usd(gross)}**  ")
        lines.append(f"Combined current balance at the two named addresses: **{usd(bal)}**\n")
    else:
        lines.append("BTCPay trace unavailable.\n")

    lines.append("## Fearless Wallet reported victim transactions\n")
    if fw.get("cases"):
        found = sum(1 for c in fw["cases"] if c.get("found"))
        signer = sum(1 for c in fw["cases"] if c.get("signer_matches_source"))
        amount = sum(1 for c in fw["cases"] if c.get("amount_verified_in_call"))
        dot = sum(c.get("amount", 0) for c in fw["cases"] if c.get("asset") == "DOT")
        ded = sum(c.get("amount", 0) for c in fw["cases"] if c.get("asset") == "DED")
        lines.append(f"Heads: Polkadot {fw.get('heads',{}).get('relay')}, AssetHub {fw.get('heads',{}).get('asset')}\n")
        lines.append(f"Extrinsics found by hash: **{found}/{len(fw['cases'])}**  ")
        lines.append(f"Signer matches the reported victim account: **{signer}/{len(fw['cases'])}**  ")
        lines.append(f"Amount decoded from the call tail: **{amount}/{len(fw['cases'])}** (transfer_all calls carry no amount)\n")
        lines.append(f"Itemized: **{dot:,.2f} DOT** + **{ded:,.2f} DED**\n")
        lines.append("| case | block | found | signer match | amount in call |")
        lines.append("|---|---:|---|---|---|")
        for c in fw["cases"]:
            lines.append(f"| {c['label']} | {c['block']} | {c.get('found')} | {c.get('signer_matches_source')} | {c.get('amount_verified_in_call')} |")
        lines.append("\nDestination balances (current):\n")
        lines.append("| account | chain | DOT | DED |")
        lines.append("|---|---|---:|---:|")
        for a, r in fw.get("balances", {}).items():
            dedv = r.get("ded", {}).get("balance") if "ded" in r else ""
            lines.append(f"| `{a}` | {r.get('chain')} | {r.get('native',{}).get('free_dot',0):.6f} | {dedv} |")
    else:
        lines.append("Fearless verification unavailable.\n")

    lines.append("\n## Fearless Wallet store / switch\n")
    crx = store.get("crx", {})
    sw = store.get("remote_switch", {})
    dns = store.get("dns", {})
    src = store.get("source_305", {})
    lines.append(f"Current CRX manifest version: **{crx.get('manifest_version')}** (sourceCommit `{crx.get('sourceCommit')}`)  ")
    lines.append(f"`tonscanner` / `whitelist?address` hits in current CRX: **{crx.get('tonscanner_hits')}**  ")
    lines.append(f"Remote switch file `ton` present: **{sw.get('ton_present')}** (switch_on={sw.get('switch_on')})  ")
    lines.append(f"3.0.5 source contains `tonscanner.org`: **{src.get('tonscanner_present')}**  ")
    lines.append(f"`tonscanner.org` A records: **{dns.get('a_records')}**  ")
    lines.append(f"TCP 443: **{dns.get('tcp_443')}**  ")
    lines.append(f"Firefox AMO: HTTP {store.get('firefox_amo',{}).get('http_status')} "
                 f"({store.get('firefox_amo',{}).get('detail')})\n")

    text = "\n".join(lines)
    os.makedirs(os.path.join(ROOT, "ci-out"), exist_ok=True)
    open(os.path.join(ROOT, "ci-out/COMBINED.md"), "w").write(text)
    print(text)

if __name__ == "__main__":
    main()
