#!/usr/bin/env python3
"""Enumerate current borrowers of Deepr IOTA EVM markets and check their health.
Read-only. Uses keyless public RPC + Blockscout v2 API. stdlib only."""
import json, sys, time, urllib.request, urllib.parse
from concurrent.futures import ThreadPoolExecutor

RPC = "https://rpc.ankr.com/iota_evm"
BS = "https://explorer.evm.iota.org"
MARKETS = {
    "dWETH":  "0x0f571c5f3c328f57cdddf204d752c7ddb49686d5",
    "dWIOTA": "0x260817581206317e2665080a2e66854e922269d0",
    "dUSDCe": "0xf96adbfcd3eb9fd61fada3f2ed70ac47e3e1e045",
}
COMPTROLLER = "0xee07121d97FDEA35675e02017837a7a43aeDa48F"
BORROW_TOPIC = "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80"
UA = {"User-Agent": "Mozilla/5.0 deepr-readonly"}

def http_get(url, tries=4):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read())
        except Exception as e:
            if i == tries - 1:
                raise
            time.sleep(1.5)

def rpc(method, params, tries=4):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"deepr-readonly"})
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read())
            if "result" in out:
                return out["result"]
            return None
        except Exception:
            if i == tries-1: raise
            time.sleep(1.2)

def eth_call(to, data):
    return rpc("eth_call", [{"to":to,"data":data},"latest"])

def collect_borrowers(market):
    out = set()
    params = {"topic": BORROW_TOPIC}
    url = f"{BS}/api/v2/addresses/{market}/logs?" + urllib.parse.urlencode(params)
    pages = 0
    while url and pages < 200:
        d = http_get(url)
        items = d.get("items", [])
        for it in items:
            topics = it.get("topics") or []
            d_ = it.get("data") or ""
            if len(topics) >= 2 and topics[1]:
                out.add("0x" + topics[1][-40:])
            elif d_.startswith("0x") and len(d_) >= 66:
                out.add("0x" + d_[2:66][-40:])
        npp = d.get("next_page_params")
        if not npp:
            break
        url = f"{BS}/api/v2/addresses/{market}/logs?" + urllib.parse.urlencode({**params, **npp})
        pages += 1
    return out

def borrow_balance_stored(market, who):
    d = "0x95dd9193" + "0"*24 + who[2:]  # borrowBalanceStored(address)
    r = eth_call(market, d)
    if not r or r == "0x": return None
    return int(r, 16)

def get_account_liquidity(who):
    d = "0x5ec88c79" + "0"*24 + who[2:]
    r = eth_call(COMPTROLLER, d)
    if not r or r == "0x" or len(r) < 2+64*3: return None
    h = r[2:]
    err = int(h[0:64],16); liq = int(h[64:128],16); short = int(h[128:192],16)
    return {"err":err,"liquidity":liq,"shortfall":short}

def main():
    allb = {}
    for name, m in MARKETS.items():
        s = collect_borrowers(m)
        allb[name] = s
        print(f"{name}: {len(s)} unique borrowers ever", file=sys.stderr)
    # check current borrow balances
    jobs = []
    for name, m in MARKETS.items():
        for b in allb[name]:
            jobs.append((name, m, b))
    print(f"checking {len(jobs)} borrower-market pairs ...", file=sys.stderr)
    results = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        futs = {ex.submit(borrow_balance_stored, m, b): (name, m, b) for name, m, b in jobs}
        for f in futs:
            name, m, b = futs[f]
            try:
                v = f.result()
            except Exception as e:
                v = None
            if v:
                results.setdefault(b, {})[name] = v
    print(f"accounts with nonzero borrows: {len(results)}", file=sys.stderr)
    # check liquidity
    out = []
    def check(b):
        return b, get_account_liquidity(b)
    with ThreadPoolExecutor(max_workers=6) as ex:
        for b, liq in ex.map(check, list(results.keys())):
            out.append({"borrower": b, "borrows": results[b], "liquidity": liq})
    out.sort(key=lambda x: -(x["liquidity"]["shortfall"] if x["liquidity"] else 0))
    json.dump(out, open("borrowers_health.json","w"), indent=1)
    print(json.dumps(out[:25], indent=1))

if __name__ == "__main__":
    main()
