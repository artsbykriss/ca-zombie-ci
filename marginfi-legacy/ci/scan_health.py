#!/usr/bin/env python3
"""marginfi v2 (MFv2hWf31...) full-account health scan.

Fetches every MarginfiAccount's balances from the public Solana RPC (dataSlice), decodes
them, and computes initial/maintenance health per account using a compact bank snapshot
(bundled) plus per-bank protocol prices. Reports any accounts that are underwater today.

Memory-safe: the (large) RPC response is streamed to disk and parsed with a regex pass.

Outputs (ci-out/): health_scan.json, scan_health.log
Read-only: getProgramAccounts only. No transactions.
"""
import base64, json, os, re, struct, sys, time, urllib.request, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)
TMP = "/tmp/mfi_scan"
os.makedirs(TMP, exist_ok=True)

PROGRAM = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
ACCOUNT_DISC_B58 = "CKkRR4La3xu"
RPC_ENDPOINTS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
I80F48 = float(1 << 48)
ENTRY_RE = re.compile(rb'"pubkey":"([1-9A-HJ-NP-Za-km-z]{32,44})","account":\{[^}]*?"data":\["([A-Za-z0-9+/=]+)"')

# Minimal base58 decoder (avoids pip installs on the CI runner)
_B58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
_B58_MAP = {c: i for i, c in enumerate(_B58_ALPHABET)}

def b58decode(s):
    n = 0
    for c in s:
        n = n * 58 + _B58_MAP[c]
    b = n.to_bytes((n.bit_length() + 7) // 8, 'big') if n else b''
    pad = len(s) - len(s.lstrip('1'))
    return b'\x00' * pad + b

def log(msg):
    print(msg, flush=True)

def rpc_to_file(method, params, path, tries=6, timeout=1800):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        ep = RPC_ENDPOINTS[i % len(RPC_ENDPOINTS)]
        try:
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json"})
            t0 = time.time()
            with urllib.request.urlopen(req, timeout=timeout) as f, open(path, "wb") as out:
                shutil.copyfileobj(f, out, length=1 << 20)
            log(f"  fetched {os.path.getsize(path)/1e6:.1f} MB from {ep} in {time.time()-t0:.0f}s")
            return True
        except Exception as e:
            last = str(e); time.sleep(3 + 3 * i)
    log(f"  fetch failed: {last}")
    return False

def iter_entries(path):
    """Yield (pubkey, raw_bytes) from a getProgramAccounts JSON file without full json.load."""
    with open(path, "rb") as f:
        data = f.read()
    for m in ENTRY_RE.finditer(data):
        yield m.group(1).decode(), base64.b64decode(m.group(2))
    del data

def decode_balances(raw):
    out = []
    for i in range(16):
        o = i * 104
        if o + 104 > len(raw):
            break
        if not raw[o]:
            continue
        bank = raw[o+1:o+33]
        a = int.from_bytes(raw[o+40:o+56], 'little', signed=True) / I80F48
        l = int.from_bytes(raw[o+56:o+72], 'little', signed=True) / I80F48
        out.append((bank, a, l))
    return out

def main():
    banks = json.load(open(os.path.join(HERE, "data", "banks_compact.json")))
    bank_keys = {b58decode(k): v for k, v in banks.items()}
    emode = json.load(open(os.path.join(HERE, "data", "bank_emode.json")))
    bank_names = {b58decode(k): k for k in banks}

    def reconcile_maint(used):
        """Classic emode reconciliation: intersection of tags across all used banks, min weight."""
        maps = [{x["tag"]: x for x in emode.get(b, {}).get("entries", [])} for b in used]
        if not maps:
            return {}
        common = set(maps[0])
        for m in maps[1:]:
            common &= set(m)
        return {t: min(m[t]["aw_maint"] for m in maps) for t in common}

    slot = json.load(urllib.request.urlopen(urllib.request.Request(
        RPC_ENDPOINTS[0], data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "getSlot", "params": []}).encode(),
        headers={"Content-Type": "application/json"}), timeout=60))["result"]
    log(f"slot {slot}")

    bal_path = os.path.join(TMP, "balances.json")
    ok = rpc_to_file("getProgramAccounts", [PROGRAM, {"encoding": "base64", "dataSlice": {"offset": 72, "length": 1664},
                                                      "filters": [{"memcmp": {"offset": 0, "bytes": ACCOUNT_DISC_B58}}]}],
                     bal_path)
    if not ok:
        log("FATAL: could not fetch balances")
        json.dump({"error": "balance fetch failed", "slot": slot}, open(os.path.join(OUT, "health_scan.json"), "w"))
        return

    total_dep_usd = total_bor_usd = 0.0
    n_accounts = n_with_borrow = 0
    unhealthy, init_deficit = [], []
    per_bank_liab = {}
    missing = set()
    t0 = time.time()
    for pk, raw in iter_entries(bal_path):
        n_accounts += 1
        bals = decode_balances(raw)
        used = [bank_names[br] for br, _, _ in bals if br in bank_names]
        recon = reconcile_maint(used)
        m_asset = m_liab = i_asset = i_liab = 0.0
        dep_usd = bor_usd = 0.0
        for bank_raw, a_shares, l_shares in decode_balances(raw):
            b = bank_keys.get(bank_raw)
            if b is None:
                missing.add(bank_raw.hex()); continue
            px = b["price"] or 0.0
            if px <= 0:
                continue
            dec = 10.0 ** b["dec"]
            if a_shares:
                v = a_shares * b["asv"] / dec * px
                dep_usd += v
                tag = emode.get(bank_names[bank_raw], {}).get("tag", 0)
                awm = b["awm"]
                if tag and tag in recon:
                    awm = max(awm, recon[tag])
                m_asset += v * awm
                i_asset += v * b["awi"]
            if l_shares:
                v = l_shares * b["lsv"] / dec * px
                bor_usd += v; m_liab += v * b["lwm"]; i_liab += v * b["lwi"]
                per_bank_liab[b["mint"]] = per_bank_liab.get(b["mint"], 0.0) + v
        total_dep_usd += dep_usd; total_bor_usd += bor_usd
        if bor_usd > 0.01:
            n_with_borrow += 1
        md = m_liab - m_asset
        if md > 0.01:
            unhealthy.append({"account": pk, "maint_deficit_usd": round(md, 2),
                              "dep_usd": round(dep_usd, 2), "bor_usd": round(bor_usd, 2)})
        idd = i_liab - i_asset
        if idd > 0.01:
            init_deficit.append({"account": pk, "init_deficit_usd": round(idd, 2),
                                 "dep_usd": round(dep_usd, 2), "bor_usd": round(bor_usd, 2)})
    log(f"scanned {n_accounts} accounts in {time.time()-t0:.0f}s")

    unhealthy.sort(key=lambda r: -r["maint_deficit_usd"])
    init_deficit.sort(key=lambda r: -r["init_deficit_usd"])

    # Liquidation-fee opportunity bound (designed mechanism, NOT a vulnerability):
    # liquidator repays R of debt and seizes R*(1+f) of collateral; health improves by
    # R*(lwm - (1+f)*awm). Using conservative averages lwm=1.1, awm=0.85, f=0.025.
    f = 0.025
    denom = max(1.1 - (1 + f) * 0.85, 0.05)
    liq_profit = 0.0
    for r in unhealthy:
        R = min(r["maint_deficit_usd"] / denom, r["bor_usd"], r["dep_usd"] / (1 + f))
        liq_profit += max(R, 0) * f
    xcheck = []
    for k, b in banks.items():
        if not b["tls"]:
            continue
        nominal = b["tls"] * b["lsv"] / (10.0 ** b["dec"]) * (b["price"] or 0.0)
        if nominal > 1000:
            scanned = per_bank_liab.get(b["mint"], 0.0)
            xcheck.append({"bank": k, "mint": b["mint"], "bank_total_usd": round(nominal, 2),
                           "scanned_accounts_usd": round(scanned, 2),
                           "ratio": round(scanned / nominal, 4) if nominal else None})
    xcheck.sort(key=lambda r: -r["bank_total_usd"])

    result = {
        "slot": slot, "accounts_scanned": n_accounts, "accounts_with_borrows": n_with_borrow,
        "total_deposits_usd_scanned": round(total_dep_usd, 2),
        "total_borrows_usd_scanned": round(total_bor_usd, 2),
        "n_unhealthy_maint": len(unhealthy), "n_init_deficit": len(init_deficit),
        "unhealthy_total_deficit_usd": round(sum(r["maint_deficit_usd"] for r in unhealthy), 2),
        "init_deficit_total_usd": round(sum(r["init_deficit_usd"] for r in init_deficit), 2),
        "liquidation_fee_opportunity_usd_bound": round(liq_profit, 2),
        "top_unhealthy": unhealthy[:60],
        "top_init_deficit": init_deficit[:60],
        "bank_liability_crosscheck_top30": xcheck[:30],
        "unknown_bank_keys": list(missing)[:20],
        "note": "health computed from balances + bundled bank snapshot (protocol prices, market fallback); "
                "emode boosts not applied (only make accounts healthier); no confidence-interval discount applied",
    }
    json.dump(result, open(os.path.join(OUT, "health_scan.json"), "w"), indent=1)
    log(json.dumps({k: v for k, v in result.items() if not isinstance(v, list)}, indent=1))
    for r in unhealthy[:20]:
        log("UNHEALTHY " + json.dumps(r))
    for r in xcheck[:10]:
        log("XCHECK " + json.dumps(r))

if __name__ == "__main__":
    main()
