#!/usr/bin/env python3
"""Deep-dive a marginfi account: decode balances, compute per-position health with both
protocol (cache) and market prices, and compare against the account's own health cache.
Usage: python3 inspect_account.py <account_pubkey> [--json]"""
import base64, json, os, struct, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base58

HERE = os.path.dirname(os.path.abspath(__file__))
RPC = "https://api.mainnet-beta.solana.com"
I80F48 = float(1 << 48)

def rpc(method, params, tries=5):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as f:
                r = json.load(f)
            if "error" in r:
                last = r["error"]; time.sleep(1 + i); continue
            return r["result"]
        except Exception as e:
            last = str(e); time.sleep(1 + i)
    raise RuntimeError(f"rpc {method} failed: {last}")

def decode_balances(raw, base=72):
    out = []
    for i in range(16):
        o = base + i * 104
        if o + 104 > len(raw): break
        if not raw[o]: continue
        bank = base58.b58encode(raw[o+1:o+33]).decode()
        a = int.from_bytes(raw[o+40:o+56], 'little', signed=True) / I80F48
        l = int.from_bytes(raw[o+56:o+72], 'little', signed=True) / I80F48
        tag = struct.unpack_from('<H', raw, o+33)[0]
        out.append((bank, a, l, tag))
    return out

def main():
    pk = sys.argv[1]
    banks = json.load(open(os.path.join(os.path.dirname(HERE), "ci", "data", "banks_compact.json")))
    v = rpc("getAccountInfo", [pk, {"encoding": "base64"}])["value"]
    raw = base64.b64decode(v["data"][0])
    print(f"account {pk} size={len(raw)} lamports={v['lamports']}")
    # health cache (protocol's last computed)
    hc = raw[1840:2140]
    def f16(b): return int.from_bytes(b, 'little', signed=True) / I80F48
    av_i, lv_i, av_m, lv_m, av_e, lv_e = (f16(hc[i*16:(i+1)*16]) for i in range(6))
    ts = struct.unpack_from('<q', hc, 96)[0]
    flags = struct.unpack_from('<I', hc, 104)[0]
    print(f"health_cache: av_i=${av_i:,.2f} lv_i=${lv_i:,.2f} av_m=${av_m:,.2f} lv_m=${lv_m:,.2f} "
          f"equity av=${av_e:,.2f} lv=${lv_e:,.2f} flags={flags} age={(time.time()-ts)/3600 if ts else -1:.1f}h")
    print(f"account_flags={struct.unpack_from('<Q', raw, 1800)[0]}")
    # balances
    bals = decode_balances(raw)
    print(f"\n{len(bals)} active balances:")
    tot_dep = tot_bor = 0.0
    m_a = m_l = i_a = i_l = 0.0
    for bank_pk, a_sh, l_sh, tag in bals:
        b = banks.get(bank_pk)
        if not b:
            print(f"  bank {bank_pk} UNKNOWN"); continue
        dec = 10.0 ** b["dec"]
        px_mkt = b.get("price_market") or 0
        px_cache = b.get("price_cache") or 0
        px_scan = b.get("price") or 0
        amt_a = a_sh * b["asv"] / dec
        amt_l = l_sh * b["lsv"] / dec
        for label, px in (("scan", px_scan),):
            va = amt_a * px; vl = amt_l * px
            tot_dep += va; tot_bor += vl
            m_a += va * b["awm"]; m_l += vl * b["lwm"]
            i_a += va * b["awi"]; i_l += vl * b["lwi"]
        print(f"  bank {bank_pk[:14]} {b['mint'][:12]:12} {b['oracle']:16} {b['op']:12} "
              f"asset={amt_a:,.6f} liab={amt_l:,.6f} px_scan={px_scan:,.6f} px_mkt={px_mkt:,.6f} "
              f"aw_m={b['awm']:.3f} lw_m={b['lwm']:.3f} tag={tag} dep=${amt_a*px_scan:,.2f} bor=${amt_l*px_scan:,.2f}")
    print(f"\nscan-price totals: deposits ${tot_dep:,.2f} borrows ${tot_bor:,.2f}")
    print(f"maintenance: assets(weighted) ${m_a:,.2f} liab(weighted) ${m_l:,.2f} -> deficit ${m_l-m_a:,.2f}")
    print(f"initial:     assets(weighted) ${i_a:,.2f} liab(weighted) ${i_l:,.2f} -> deficit ${i_l-i_a:,.2f}")

if __name__ == "__main__":
    main()
