#!/usr/bin/env python3
"""Enumerate every Sodium account/proxy created by the factory family, then
verify each still points at the vulnerable implementation and read its balances.

Data sources:
  * Etherscan V2 (chainid 42161) internal-tx list of the factories  -> CREATE2 addresses
  * keyless public Arbitrum RPC                                       -> code / slot / balances

No secrets are stored here; the Etherscan key is read from /home/heisenberg/CA/.env
at runtime and never written to any artifact.
"""
import json, sys, urllib.request, urllib.parse, time
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, "/home/heisenberg/CA/sodium/analysis")
import lib_rpc as R

IMPL = "0xb5BC46dF04dEe31D219E7664122e29EEd9506b8b"
FACTORIES = [
    "0x5eb4bcaeb78a7a765fa3f7285ee6b3e08ccb2c09",   # main Sodium factory (unverified)
    "0xa225f7262a654f1fe2518ab8933f1b9d8023d6df",   # sibling factory seen in internal txs
]
PROXY_CODE_LEN = 384  # bytes


def _env(path="/home/heisenberg/CA/.env"):
    env = {}
    for line in open(path):
        line = line.strip()
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            env[k] = v.strip().strip('"').strip("'")
    return env


def etherscan(params):
    key = _env().get("ETHERSCANV2_API_KEY", "")
    p = dict(params); p["apikey"] = key
    url = "https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(p)
    for _ in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(
                    url, headers={"User-Agent": "Mozilla/5.0"}), timeout=45) as r:
                return json.loads(r.read())
        except Exception as e:
            time.sleep(1)
            err = str(e)
    return {"error": err}


def factory_creations(addr, max_pages=25):
    """Etherscan caps a page at 1000 rows regardless of the requested offset, so
    paginate with offset=1000."""
    out = []
    seen = set()
    for page in range(1, max_pages + 1):
        r = etherscan({"chainid": 42161, "module": "account", "action": "txlistinternal",
                       "address": addr, "startblock": 0, "endblock": 999999999,
                       "sort": "asc", "page": page, "offset": 1000})
        res = r.get("result")
        if not isinstance(res, list) or not res:
            break
        new = 0
        for t in res:
            key = (t.get("hash"), t.get("traceId", ""))
            if key in seen:
                continue
            seen.add(key)
            new += 1
            if t.get("from", "").lower() == addr.lower() and t.get("type") in ("create", "create2"):
                ca = t.get("contractAddress")
                if ca:
                    out.append(ca.lower())
        if len(res) < 1000 or new == 0:
            break
    return out


def main():
    blk = R.latest()
    print(f"# latest Arbitrum block {blk}")
    cands = set()
    for f in FACTORIES:
        c = factory_creations(f)
        print(f"# factory {f}: {len(c)} creations")
        cands.update(c)
    # also seed the exploit-derived example accounts
    for a in ["0x0209d8fcb0c36399eb49e018a245c55fd37d16bd",
              "0x65DE72bD1897B017C91f41c86de2B15873320804",
              "0x9Ba99e76f2bE6571ae1bf82420621211EFD45236",
              "0x19fC6A309a85B8e4b27046e728245D44dC339B0e",
              "0x11F2a69242de6Ce12dcC1cb44505dAfac1d33d81",
              "0xa2fCBEb061A19006Fb550fCB58C32Ac1f282D767"]:
        cands.add(a.lower())
    cands = sorted(cands)
    print(f"# candidate addresses: {len(cands)}")

    # batch code + impl-slot read
    calls = []
    for a in cands:
        calls.append(("eth_getCode", [a, hex(blk)]))
        calls.append(("eth_getStorageAt", [a, "0x" + a[2:].rjust(64, "0"), hex(blk)]))
    sodium = []
    proxy_other_impl = []
    for i in range(0, len(calls), 200):
        res = R.batch_retry(calls[i:i + 200])
        for j in range(len(res) // 2):
            code = (res[2 * j] or {}).get("result", "0x")
            slot = (res[2 * j + 1] or {}).get("result", "0x0")
            a = cands[(i // 2) + j]
            if len(code) == 2 + PROXY_CODE_LEN * 2:
                impl = "0x" + slot[-40:]
                if slot[-40:].lower() == IMPL[2:].lower():
                    sodium.append(a)
                else:
                    proxy_other_impl.append((a, impl))
        print(f"#   scanned {min(i+200,len(calls))//2}/{len(cands)} candidates, matches={len(sodium)}", flush=True)
    print(f"# accounts pointing at impl {IMPL}: {len(sodium)}")
    print(f"# proxy-coded accounts pointing at a DIFFERENT impl: {len(proxy_other_impl)}")
    for a, im in proxy_other_impl[:20]:
        print(f"   {a} -> {im}")

    # native balances
    bals = {}
    for i in range(0, len(sodium), 200):
        res = R.batch_retry([("eth_getBalance", [a, hex(blk)]) for a in sodium[i:i + 200]])
        for a, x in zip(sodium[i:i + 200], res):
            bals[a] = int((x or {}).get("result", "0x0"), 16)

    funded = {a: b for a, b in bals.items() if b > 0}
    print(f"# with native ETH > 0: {len(funded)}")
    for a, b in sorted(funded.items(), key=lambda x: -x[1])[:30]:
        print(f"   {a} {b/1e18:.6f} ETH")

    json.dump({"latest_block": blk, "impl": IMPL, "candidates": cands,
               "sodium_accounts": sodium,
               "proxy_other_impl": proxy_other_impl,
               "native_balances_wei": bals},
              open("/home/heisenberg/CA/sodium/analysis/census_accounts.json", "w"), indent=1)
    print("# wrote analysis/census_accounts.json")


if __name__ == "__main__":
    main()
