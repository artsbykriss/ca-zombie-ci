#!/usr/bin/env python3
"""Classify every equity-collateral USDG market on Robinhood Chain (4663) by oracle family
and compute the free-liquidity (borrowable) surface per family.

Read-only. Uses a keyless public RPC. No secrets.

Oracle families observed:
  * CUSTOM   (code ~5129 B): MAX_BASE_AGE=349200 s (97 h) on the equity feed,
                             MAX_QUOTE_AGE=90000 s (25 h) on the quote feed.
  * V2       (code ~5117 B): canonical MorphoChainlinkOracleV2 -> no staleness check at all.
  * OTHER    (other bytecode, e.g. 93-byte mock oracles).
"""
import json, urllib.request, os

RPC = os.environ.get("RH_RPC_URL", "https://robinhood.drpc.org")
MORPHO = "0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010"
USDG = "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168"
EQ = {"NVDA","SPCX","GOOGL","AAPL","SPY","META","TSLA","COIN","MSTR","CRCL","PLTR",
      "SLV","MSFT","AMZN","INTC","SNDK","RDDT","TTWO","SGOV","bNVDA"}

SEL_MAX_BASE_AGE = "0xe4955b3d"
SEL_MAX_QUOTE_AGE = "0x1b1043c8"

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "content-type":"application/json",
        "user-agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())["result"]

def call(to, data, block="latest"):
    try:
        res = rpc("eth_call", [{"to": to, "data": data}, block])
        return res
    except Exception:
        return None

def as_int(hexstr):
    return int(hexstr, 16) if hexstr and hexstr != "0x" else None

def main():
    block = int(rpc("eth_blockNumber", []), 16)
    print("block", block)
    mkts = json.load(open(os.path.join(os.path.dirname(__file__), "markets_raw.json")))["data"]["markets"]["items"]
    rows = []
    for m in mkts:
        if (m.get("loanAsset") or {}).get("symbol") != "USDG":
            continue
        ca = m.get("collateralAsset") or {}
        if ca.get("symbol") not in EQ:
            continue
        st = m["state"] or {}
        liq = float(st.get("liquidityAssetsUsd") or 0)
        oracle = (m.get("oracle") or {}).get("address")
        if not oracle:
            continue
        code = rpc("eth_getCode", [oracle, "latest"])
        codelen = (len(code) - 2) // 2
        mba = as_int(call(oracle, SEL_MAX_BASE_AGE))
        fam = "CUSTOM_97h" if mba == 349200 else ("V2_unbounded" if codelen in (2557, 2558) else "OTHER")
        rows.append({"marketId": m["marketId"], "coll": ca["symbol"], "oracle": oracle,
                     "code_bytes": codelen, "MAX_BASE_AGE": mba, "family": fam,
                     "free_usd": round(liq, 2), "borrow_usd": round(float(st.get("borrowAssetsUsd") or 0), 2)})
    rows.sort(key=lambda r: -r["free_usd"])
    fam_tot = {}
    for r in rows:
        fam_tot.setdefault(r["family"], 0.0)
        fam_tot[r["family"]] += r["free_usd"]
    out = {"block": block, "markets": rows,
           "free_liquidity_by_family": {k: round(v, 2) for k, v in fam_tot.items()},
           "total_free_usd": round(sum(r["free_usd"] for r in rows), 2)}
    with open(os.path.join(os.path.dirname(__file__), "oracle_families.json"), "w") as f:
        json.dump(out, f, indent=2)
    print(f"{'coll':7} {'family':12} {'free_usd':>12}  oracle")
    for r in rows:
        if r["free_usd"] > 0:
            print(f"{r['coll']:7} {r['family']:12} {r['free_usd']:12,.2f}  {r['oracle']}")
    print("--- free liquidity by family ---")
    for k, v in sorted(fam_tot.items(), key=lambda x: -x[1]):
        print(f"  {k:12} ${v:,.2f}")
    print(f"  {'TOTAL':12} ${sum(r['free_usd'] for r in rows):,.2f}")

if __name__ == "__main__":
    main()
