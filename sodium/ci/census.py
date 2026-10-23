#!/usr/bin/env python3
"""Heavy census for P5-01 (runs in CI): for every account created by the Sodium
factory, classify (proxy -> impl), and read native ETH, a basket of ERC-20 balances
and EntryPoint deposits. Writes ci-out/census.json + ci-out/census_summary.txt.

Uses ARB_RPC_URL from the environment (never printed/stored).
"""
import json, os, sys, time, urllib.request

RPC_CANDIDATES = [os.environ.get("ARB_RPC_URL") or ""]
if os.environ.get("ANKR_API_KEY"):
    RPC_CANDIDATES.append("https://rpc.ankr.com/arbitrum/" + os.environ["ANKR_API_KEY"])
if os.environ.get("INFURA_API_KEY"):
    RPC_CANDIDATES.append("https://arbitrum-mainnet.infura.io/v3/" + os.environ["INFURA_API_KEY"])
RPC_CANDIDATES += ["https://arb1.arbitrum.io/rpc", "https://1rpc.io/arb",
                   "https://arbitrum-one-rpc.publicnode.com"]
RPC = next(u for u in RPC_CANDIDATES if u)
IMPL = "0xb5bc46df04dee31d219e7664122e29eed9506b8b"
PROXY_LEN = 384
MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"

TOKENS = {
    "USDT0":  "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
    "USDC":   "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    "USDC.e": "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
    "WETH":   "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    "ARB":    "0x912CE59144191C1204E64559FE8253a0e49E6548",
    "DAI":    "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
    "WBTC":   "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
    "LINK":   "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
    "wstETH": "0x5979D7b546E38E414F7E9822514be443A4800529",
    "USDe":   "0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34",
    "weETH":  "0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe",
    "FRAX":   "0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F",
}
ENTRYPOINTS = {
    "v0.6": "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789",
    "v0.7": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
    "v0.8": "0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108",
}
SEL_BALANCEOF = "70a08231"
_ids = [0]


def _post(payload, timeout=60, url=None):
    req = urllib.request.Request(url or RPC, data=json.dumps(payload).encode(),
                                 headers={"content-type": "application/json",
                                          "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


_POOL = [u for u in RPC_CANDIDATES if u]
_POOLI = [0]


def rpc_post(payload, timeout=60):
    """POST a batch, rotating across the endpoint pool on failure / HTTP 429."""
    last = None
    for attempt in range(3 * len(_POOL) + 2):
        u = _POOL[_POOLI[0] % len(_POOL)]
        try:
            return _post(payload, timeout=timeout, url=u)
        except Exception as e:
            last = e
            _POOLI[0] += 1
            time.sleep(0.3 + 0.4 * attempt)
    raise last


def pick_rpc():
    """Choose a working Arbitrum RPC; sanity-check the block height so an Ethereum
    endpoint (e.g. FORK_RPC_URL) is never used by mistake."""
    global RPC
    for u in RPC_CANDIDATES:
        if not u:
            continue
        try:
            r = _post({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []},
                      timeout=20, url=u)
            bn = int(r["result"], 16)
            if bn > 400_000_000:
                RPC = u
                return u, bn
        except Exception:
            continue
    raise SystemExit("no working Arbitrum RPC found")


def rpc(method, params):
    return _post({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})


def batch(calls, chunk=40, tries=8):
    out = [None] * len(calls)
    for attempt in range(tries):
        pend = [i for i in range(len(calls)) if out[i] is None]
        if not pend:
            break
        for k in range(0, len(pend), chunk):
            sub = pend[k:k + chunk]
            payload = [{"jsonrpc": "2.0", "id": j, "method": calls[i][0], "params": calls[i][1]}
                       for j, i in enumerate(sub)]
            try:
                res = rpc_post(payload)
                if isinstance(res, list):
                    for item in res:
                        if "result" in item:
                            out[sub[item["id"]]] = item["result"]
            except Exception as e:
                sys.stderr.write(f"batch error: {e}\n")
                time.sleep(0.5 + 0.5 * attempt)
            time.sleep(0.03)
        if any(out[i] is None for i in range(len(calls))):
            time.sleep(0.6 * (attempt + 1))
    return out


# ---------------------------------------------------------------- multicall3

def _enc_words(*words):
    return "".join(w if isinstance(w, str) else format(w, "064x") for w in words)


def _enc_bytes(b):
    b = b[2:] if b.startswith("0x") else b
    n = len(b) // 2
    return format(n, "064x") + b + "0" * ((64 - (len(b) % 64)) % 64)


def multicall_tryAggregate(calls):
    """calls: list of (target, calldata_hex_without_0x). Returns list of (ok, retbytes)."""
    sel = "bce38bd7"  # tryAggregate(bool,(address,bytes)[])
    n = len(calls)
    elems = []
    for (tgt, cd) in calls:
        # element encoding: address word, offset to bytes (0x40), bytes
        elems.append(_enc_words(tgt[2:].lower().rjust(64, "0")) + format(0x40, "064x") + _enc_bytes(cd))
    offsets = []
    pos = n * 32  # element area starts after the n offset words
    for e in elems:
        offsets.append(pos)
        pos += len(e) // 2
    data = ("0x" + sel + _enc_words(0) + format(0x40, "064x") + format(n, "064x")
            + "".join(format(o, "064x") for o in offsets) + "".join(elems))
    r = rpc_post({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                  "params": [{"to": MULTICALL3, "data": data}, "latest"]})
    res = r.get("result")
    if not res:
        return None
    body = res[2:]
    words = [body[i:i + 64] for i in range(0, len(body), 64)]
    arr_off = int(words[0], 16) // 32          # offset to the Result[] array
    ln = int(words[arr_off], 16)
    elem_area = arr_off + 1                    # index of the first element-offset word
    out = []
    for i in range(ln):
        e_off = int(words[elem_area + i], 16) // 32      # relative to elem area start
        e0 = elem_area + e_off
        ok = int(words[e0], 16) == 1
        b_off = int(words[e0 + 1], 16) // 32
        blen = int(words[e0 + b_off], 16)
        raw = "".join(words[e0 + b_off + 1 + j] for j in range((blen + 31) // 32))
        out.append((ok, raw[:blen * 2]))
    return out


def token_balances(accounts):
    """Return {account: {symbol: int}} using multicall3 over all accounts x tokens."""
    bal = {a: {} for a in accounts}
    pairs = [(a, sym, tok) for a in accounts for sym, tok in TOKENS.items()]
    CHUNK = 300
    for k in range(0, len(pairs), CHUNK):
        sub = pairs[k:k + CHUNK]
        calls = [(tok, SEL_BALANCEOF + a[2:].lower().rjust(64, "0")) for (a, sym, tok) in sub]
        res = None
        for _ in range(3):
            res = multicall_tryAggregate(calls)
            if res and len(res) == len(sub):
                break
            time.sleep(1)
        if not res:
            continue
        for (a, sym, tok), (ok, raw) in zip(sub, res):
            if ok and raw:
                bal[a][sym] = int(raw, 16)
        sys.stderr.write(f"  token scan {min(k+CHUNK,len(pairs))}/{len(pairs)}\n")
    return bal


def main():
    rpc_url, latest = pick_rpc()
    print(f"# using an Arbitrum RPC (redacted), latest block {latest}", flush=True)
    print(f"# latest block {latest}", flush=True)
    cand = json.load(open(os.path.join(os.path.dirname(__file__), "..",
                                       "analysis", "sodium_factory_accounts.json")))["accounts"]
    print(f"# candidates {len(cand)}", flush=True)

    calls = []
    for a in cand:
        calls.append(("eth_getCode", [a, "latest"]))
        calls.append(("eth_getStorageAt", [a, "0x" + a[2:].rjust(64, "0"), "latest"]))
    res = batch(calls)
    sodium, other = [], []
    for j, a in enumerate(cand):
        code = res[2 * j] or "0x"
        slot = res[2 * j + 1] or "0x0"
        if len(code) == 2 + PROXY_LEN * 2:
            impl = "0x" + slot[-40:]
            (sodium if impl.lower() == IMPL else other).append((a, impl))
    print(f"# sodium accounts -> impl: {len(sodium)}; proxy -> other impl: {len(other)}", flush=True)

    addrs = [a for a, _ in sodium]
    native = batch([("eth_getBalance", [a, "latest"]) for a in addrs])
    nbal = {a: int((native[i] or "0x0"), 16) for i, a in enumerate(addrs)}

    # EntryPoint deposits: balanceOf(account)
    dep = {}
    for name, ep in ENTRYPOINTS.items():
        calls = [(ep, SEL_BALANCEOF + a[2:].lower().rjust(64, "0")) for a in addrs]
        vals = {}
        for k in range(0, len(calls), 300):
            sub = calls[k:k + 300]
            r = multicall_tryAggregate(sub)
            if not r:
                continue
            for a, (ok, raw) in zip(addrs[k:k + 300], r):
                if ok and raw:
                    vals[a] = int(raw, 16)
        dep[name] = vals
        print(f"# deposit {name}: {sum(1 for v in vals.values() if v>0)} funded accounts", flush=True)

    tbal = token_balances(addrs)

    # aggregate
    funded_eth = {a: v for a, v in nbal.items() if v > 0}
    funded_tok = {}
    for a, d in tbal.items():
        nz = {k: v for k, v in d.items() if v > 0}
        if nz:
            funded_tok[a] = nz
    funded_dep = {}
    for name, vals in dep.items():
        nz = {a: v for a, v in vals.items() if v > 0}
        if nz:
            funded_dep[name] = nz

    summary = {
        "latest_block": latest, "impl": IMPL,
        "candidates": len(cand), "sodium_accounts": len(sodium),
        "proxy_other_impl": other[:50], "proxy_other_impl_count": len(other),
        "funded_native": funded_eth, "funded_tokens": funded_tok,
        "funded_deposits": funded_dep,
        "n_funded_native": len(funded_eth), "n_funded_tokens": len(funded_tok),
    }
    outdir = os.path.join(os.path.dirname(__file__), "..", "ci-out")
    os.makedirs(outdir, exist_ok=True)
    json.dump({"summary": summary, "native_wei": nbal, "tokens": tbal,
               "deposits": dep, "sodium_accounts": addrs},
              open(os.path.join(outdir, "census.json"), "w"), indent=1)
    with open(os.path.join(outdir, "census_summary.txt"), "w") as f:
        f.write(f"Sodium census @ block {latest}\n")
        f.write(f"factory candidates: {len(cand)}\n")
        f.write(f"accounts -> vulnerable impl: {len(sodium)}\n")
        f.write(f"proxy accounts -> other impl: {len(other)}\n")
        f.write(f"accounts with native ETH>0: {len(funded_eth)}\n")
        f.write(f"accounts with any token>0: {len(funded_tok)}\n")
        for name, vals in funded_dep.items():
            f.write(f"accounts with EntryPoint {name} deposit>0: {len(vals)}\n")
        if funded_eth:
            for a, v in funded_eth.items():
                f.write(f"  NATIVE {a} {v/1e18:.8f} ETH\n")
        if funded_tok:
            for a, d in funded_tok.items():
                f.write(f"  TOKENS {a} {d}\n")
    print("WROTE ci-out/census.json", flush=True)


if __name__ == "__main__":
    main()
