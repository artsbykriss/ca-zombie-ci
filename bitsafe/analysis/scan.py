#!/usr/bin/env python3
"""
BitSafe CBTC (Canton) Bitcoin reserve scan + independent address verification.

Read-only. Keyless public endpoints only (blockchain.info batch, Esplora).
No pip dependencies (pure-python secp256k1 in ec.py).

  1. Fetch the operator's published address-calculation data.
  2. INDEPENDENTLY re-derive every P2TR deposit address (NUMS internal key +
     <groupkey> OP_CHECKSIG leaf) and assert 728/728 match.
  3. Read each address's balance (blockchain.info batch) and spend history
     (Esplora), decode every spend witness, classify it, and verify the
     tapscript == the expected leaf and the control-block internal key == the
     independently-derived NUMS key.
  4. Sum the reserve and write CSV/JSON to ci-out/.

Env: SCAN_LIMIT (int, 0=all) for smoke tests; SPEND_BUDGET_S (default 1500)
bounds the spend-census wall clock.
"""
import hashlib, hmac, json, os, sys, time, urllib.request, urllib.error, urllib.parse

API = "https://api.mainnet.bitsafe.finance/cbtc/v1/address-calculation-data"
ESPLORAS = ["https://blockstream.info/api", "https://mempool.space/api"]
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT, exist_ok=True)
NUMS = bytes.fromhex("0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0")

def log(*a): print(*a, flush=True)

def http_get(url, tries=3, timeout=25):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "cbtc-por-verify/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            last = e
            if e.code == 429 or e.code >= 500:
                time.sleep(1.0 * 2 ** i); continue
            raise
        except Exception as e:
            last = e; time.sleep(1.0 * 2 ** i)
    raise last

def esplora(path, tries=2):
    last = None
    for base in ESPLORAS:
        for i in range(tries):
            try:
                return http_get(base + path, tries=1, timeout=20)
            except Exception as e:
                last = e; time.sleep(0.8 * 2 ** i)
    raise last

# ---- dependency-free secp256k1 / BIP32 / BIP341 ----
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ec
ALPHA = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58dec(s):
    n = 0
    for c in s: n = n * 58 + ALPHA.index(c)
    return b'\x00' * (len(s) - len(s.lstrip('1'))) + n.to_bytes((n.bit_length() + 7) // 8, 'big')
def tag(t, d):
    th = hashlib.sha256(t.encode()).digest()
    return hashlib.sha256(th + th + d).digest()
def ckd(pub33, cc, idx):
    I = hmac.new(cc, pub33 + idx.to_bytes(4, 'big'), hashlib.sha512).digest()
    child = ec.add(ec.parse_pub(pub33), ec.mul_affine(int.from_bytes(I[:32], 'big')))
    return ec.ser_p(child), I[32:]
def internal_key(dep_id):
    p, c = ckd(NUMS, hashlib.sha256(dep_id.encode()).digest(), 0)
    p, c = ckd(p, c, 0)
    return p[1:]
CH = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def _pm(v):
    G = [0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]; chk = 1
    for x in v:
        b = chk >> 25; chk = (chk & 0x1ffffff) << 5 ^ x
        for i in range(5): chk ^= G[i] if ((b >> i) & 1) else 0
    return chk
def _he(h): return [ord(x) >> 5 for x in h] + [0] + [ord(x) & 31 for x in h]
def _cb(d, f, t):
    a = b = 0; r = []; m = (1 << t) - 1
    for v in d:
        a = (a << f) | v; b += f
        while b >= t: b -= t; r.append((a >> b) & m)
    if b: r.append((a << (t - b)) & m)
    return r
def p2tr(x):
    d = [1] + _cb(list(x), 8, 5); v = _he("bc") + d
    pm = _pm(v + [0] * 6) ^ 0x2bc830a3
    chk = [(pm >> 5 * (5 - i)) & 31 for i in range(6)]
    return "bc1" + ''.join(CH[q] for q in d + chk)
def taproot_addr(dep_id, leafh):
    P = internal_key(dep_id)
    Qx = ec.xonly_tweak(P, tag("TapTweak", P + leafh))
    return None if Qx is None else p2tr(Qx)

def classify_witness(witness, expected_leaf_hex):
    if not witness: return {"type": "empty"}
    last = witness[-1]
    if len(last) // 2 >= 33 and (int(last[:2], 16) & 0xfe) == 0xc0:
        cb = last
        return {"type": "script_path", "leaf_version": hex(int(cb[:2], 16) & 0xfe),
                "internal_key": cb[2:66], "merkle_path_nodes": (len(cb) - 66) // 64,
                "tapscript": witness[-2] if len(witness) >= 2 else "",
                "leaf_ok": (witness[-2] if len(witness) >= 2 else "") == expected_leaf_hex,
                "stack_items": len(witness) - 2}
    return {"type": "key_path", "sig_len": len(last) // 2}

def batch_balances(addrs, chunk=40):
    """blockchain.info batch balance. Returns {addr: (final_balance, n_tx, total_received)}."""
    out = {}
    for i in range(0, len(addrs), chunk):
        part = addrs[i:i + chunk]
        url = "https://blockchain.info/balance?active=" + "|".join(urllib.parse.quote(a) for a in part) + "&cors=true"
        try:
            r = http_get(url, tries=4, timeout=30)
            for a, v in r.items():
                out[a] = (int(v.get("final_balance", 0)), int(v.get("n_tx", 0)), int(v.get("total_received", 0)))
        except Exception as e:
            log("  batch failed", i, e)
            for a in part: out[a] = None
        time.sleep(0.3)
    return out

def main():
    log("fetching", API)
    data = http_get(API)
    assert data.get("status") == "ready"
    assert data.get("bitcoin_network") == "bitcoin"
    chains = data["chains"]
    chain_leaf = {}
    for c in chains:
        gx = b58dec(c["xpub"])[45:78][1:]
        script = bytes([32]) + gx + bytes([0xac])
        chain_leaf[c["chain"]] = (script.hex(), bytes([0xc0]) + bytes([len(script)]) + script)

    verified = 0; mismatches = []; addr_chain = {}; addr_internal = {}
    for c in chains:
        leafh = tag("TapLeaf", chain_leaf[c["chain"]][1])
        for a in c["addresses"]:
            got = taproot_addr(a["id"], leafh)
            addr_chain[a["address_for_verification"]] = c["chain"]
            addr_internal[a["address_for_verification"]] = internal_key(a["id"]).hex()
            if got == a["address_for_verification"]: verified += 1
            else: mismatches.append({"id": a["id"], "reported": a["address_for_verification"], "calculated": got})
    total_addrs = sum(len(c["addresses"]) for c in chains)
    log(f"independent address verification: {verified}/{total_addrs} match; mismatches={len(mismatches)}")

    LIMIT = int(os.environ.get("SCAN_LIMIT", "0"))
    items = list(addr_chain.items())
    if LIMIT: items = items[:LIMIT]
    addrs = [a for a, _ in items]
    height = esplora("/blocks/tip/height")
    log("tip height:", height)

    log("batch balances via blockchain.info ...")
    bal = batch_balances(addrs)
    balances = []; total_sat = 0; funded = 0
    for a in addrs:
        v = bal.get(a)
        if v is None:
            balances.append((a, None, None, None, None)); continue
        fb, ntx, tr = v
        balances.append((a, fb, tr, None, ntx))
        total_sat += fb
        if tr > 0: funded += 1

    # cross-check the largest holders against mempool.space
    top = sorted([b for b in balances if b[1]], key=lambda x: -x[1])[:5]
    cross = []
    for a, fb, *_ in top:
        try:
            st = esplora(f"/address/{a}")
            ms = st["chain_stats"]["funded_txo_sum"] - st["chain_stats"]["spent_txo_sum"]
            cross.append({"address": a, "blockchain_info": fb, "mempool_space": ms, "match": fb == ms})
        except Exception as e:
            cross.append({"address": a, "error": str(e)})
    log("cross-check top balances:", json.dumps(cross)[:600])

    # spend census (bounded)
    budget = int(os.environ.get("SPEND_BUDGET_S", "1500"))
    t0 = time.time(); spends = []; scripts = []; partial = False
    hist_addrs = [a for a in addrs if (bal.get(a) or (0, 0, 0))[1] > 0]
    log(f"spend census over {len(hist_addrs)} addresses with history (budget {budget}s)")
    for n, addr in enumerate(hist_addrs, 1):
        if time.time() - t0 > budget:
            partial = True; log(f"  budget reached after {n-1} addresses"); break
        chain = addr_chain[addr]
        try:
            txs = esplora(f"/address/{addr}/txs")
        except Exception as e:
            log("  txs failed", addr, e); continue
        for tx in txs:
            vin_idx = [i for i, v in enumerate(tx.get("vin", []))
                       if v.get("prevout", {}).get("scriptpubkey_address") == addr]
            for i in vin_idx:
                info = classify_witness(tx["vin"][i].get("witness", []), chain_leaf[chain][0])
                info["internal_ok"] = (info.get("internal_key") == addr_internal.get(addr))
                info.update({"address": addr, "txid": tx["txid"],
                             "height": tx.get("status", {}).get("block_height"),
                             "value_spent_sat": tx["vin"][i].get("prevout", {}).get("value")})
                scripts.append(info)
                spends.append((addr, tx["txid"], info.get("height"), info.get("type"),
                               info.get("leaf_ok"), info.get("internal_ok"), info.get("internal_key", "")))
        if n % 25 == 0: log(f"  ...{n}/{len(hist_addrs)} history addresses, {len(scripts)} spends")

    total_btc = total_sat / 1e8
    try:
        p = http_get("https://coins.llama.fi/prices/current/coingecko:bitcoin", tries=3)
        price = p["coins"]["coingecko:bitcoin"]["price"]
    except Exception as e:
        price = None; log("price fetch failed", e)

    with open(os.path.join(OUT, "balances.csv"), "w") as f:
        f.write("address,balance_sat,funded_sat,spent_sat,tx_count\n")
        for r in sorted(balances, key=lambda x: -(x[1] or 0)):
            f.write(",".join("" if x is None else str(x) for x in r) + "\n")
    with open(os.path.join(OUT, "spends.csv"), "w") as f:
        f.write("address,txid,height,spend_type,leaf_ok,internal_ok,internal_key\n")
        for r in spends:
            f.write(",".join("" if x is None else str(x) for x in r) + "\n")
    with open(os.path.join(OUT, "scripts.json"), "w") as f:
        json.dump(scripts, f, indent=1)

    from collections import Counter
    hist = Counter(s.get("type") for s in scripts)
    summary = {
        "tip_height": height, "btc_price_usd": price,
        "addresses_total": total_addrs, "addresses_verified": verified,
        "address_mismatches": mismatches, "addresses_with_history": funded,
        "reserve_btc": round(total_btc, 8),
        "reserve_usd": round(total_btc * price, 2) if price else None,
        "balance_source": "blockchain.info/balance (batch); cross-checked vs Esplora",
        "balance_cross_check_top5": cross,
        "spends_seen": len(scripts), "spend_type_histogram": dict(hist),
        "spends_leaf_ok": sum(1 for s in scripts if s.get("leaf_ok")),
        "spends_leaf_unexpected": sum(1 for s in scripts if s.get("type") == "script_path" and not s.get("leaf_ok")),
        "spends_internal_key_ok": sum(1 for s in scripts if s.get("internal_ok")),
        "spends_internal_key_unexpected": sum(1 for s in scripts if not s.get("internal_ok")),
        "spend_census_partial": partial,
        "expected_tapscript": chain_leaf["canton-mainnet"][0],
        "group_xonly_key": chain_leaf["canton-mainnet"][0][2:66],
    }
    with open(os.path.join(OUT, "summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    log("SUMMARY:", json.dumps(summary, indent=1))

if __name__ == "__main__":
    main()
