#!/usr/bin/env python3
"""CI census for the SimpleAccount factory (Arbitrum One) — read-only.

Re-derives the factory's account set from Etherscan internal transactions (create2),
then reads live state at CI time:
  * code size of every factory-created contract
  * ETH balance of every created contract (accounts + guardians + impl)
  * ERC-4337 EntryPoint balanceOf() for every account (gas deposits are a separate value channel)
  * balanceOf() of 6 blue-chip tokens for every account
  * factory nonce (new-account tripwire)
Writes ci-out/census-ci.json and prints a machine-greppable summary.

No secrets are written. RPC URL is taken from ARB_RPC_URL (or a public fallback) and never echoed.
"""
import json, os, sys, time, urllib.request

FACTORY = "0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885"
ENTRYPOINT = "0x0000000071727De22E5E9d8BAf0edAc6f37da032"
TOKENS = {
    "USDC": "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    "USDC.e": "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
    "WETH": "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    "USDT": "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
    "ARB": "0x912CE59144191C1204E64559FE8253a0e49E6548",
    "DAI": "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
}
# The only non-zero asset class on the accounts: two project NFTs, both soulbound
# (transferFrom is onlyRole(DEFAULT_ADMIN_ROLE)).
NFTS = {
    "ART": "0x1feef5e4302ade8ac70beff5f8bb7270c6a9aba1",
    "PAR": "0x3786a10401af9da586a150b6633f5a69915608b8",
}
RPCS = [u for u in [os.environ.get("ARB_RPC_URL", ""), "https://arb1.arbitrum.io/rpc",
                    "https://arbitrum.drpc.org", "https://arbitrum-one-rpc.publicnode.com"] if u]
OUT = "ci-out"
BATCH = 40
_rpc = [0]


def rpc_call(method, params, rpc):
    payload = [{"jsonrpc": "2.0", "id": 0, "method": method, "params": params}]
    req = urllib.request.Request(rpc, data=json.dumps(payload).encode(),
                                 headers={"content-type": "application/json", "user-agent": "zh4-ci/1"})
    with urllib.request.urlopen(req, timeout=90) as r:
        out = json.load(r)
    if isinstance(out, list):
        out = out[0]
    if "result" not in out:
        raise ValueError(str(out.get("error"))[:120])
    return out["result"]


def rpc_batch(calls):
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    req = urllib.request.Request(RPCS[_rpc[0] % len(RPCS)], data=json.dumps(payload).encode(),
                                 headers={"content-type": "application/json", "user-agent": "zh4-ci/1"})
    with urllib.request.urlopen(req, timeout=120) as r:
        out = json.load(r)
    if not isinstance(out, list):
        raise ValueError("non-list")
    res = {o["id"]: o for o in out if isinstance(o, dict) and "id" in o}
    vals = []
    for i in range(len(calls)):
        if i not in res or "result" not in res[i]:
            raise ValueError("missing")
        vals.append(res[i]["result"])
    return vals


def batch(calls):
    for a in range(12):
        if a:
            _rpc[0] += 1
        try:
            return rpc_batch(calls)
        except Exception as e:
            sys.stderr.write(f"  retry{a} {type(e).__name__} {str(e)[:70]}\n")
            time.sleep(0.7 * (a + 1))
    raise SystemExit("RPC batch failed after retries")


def chunks(s, n):
    for i in range(0, len(s), n):
        yield s[i:i + n]


def etherscan(pages=12):
    key = os.environ.get("ETHERSCANV2_API_KEY", "")
    if not key:
        return None
    base = "https://api.etherscan.io/v2/api?chainid=42161&module=account&action=txlistinternal"
    out = []
    for page in range(1, pages + 1):
        url = f"{base}&address={FACTORY}&page={page}&offset=1000&sort=asc&apikey={key}"
        d = None
        for a in range(10):
            try:
                d = json.load(urllib.request.urlopen(url, timeout=90))
                if d.get("status") == "1" or "No transactions" in str(d.get("message")):
                    break
            except Exception:
                pass
            time.sleep(2 + a)
        if not d:
            return None
        if d.get("status") != "1":
            if "No transactions" in str(d.get("message")):
                break
            return None                      # never treat a throttled page as the end of the list
        r = d["result"]
        out += r
        if len(r) < 1000:
            break
    return [t for t in out if t.get("from", "").lower() == FACTORY.lower()
            and t.get("contractAddress") and t.get("isError") == "0"]


def main():
    os.makedirs(OUT, exist_ok=True)
    block = int(rpc_call("eth_blockNumber", [], RPCS[0]), 16)
    res = {"chain": "arbitrum", "chain_id": 42161, "block": block, "factory": FACTORY}

    cre = etherscan()
    if cre is None:
        snap = json.load(open("analysis/census.json"))
        addrs = sorted(snap["contracts"])
        res["source"] = "committed-snapshot (Etherscan unavailable)"
        res["last_creation_block"] = max(v["block"] for v in snap["contracts"].values())
    else:
        addrs = sorted({t["contractAddress"].lower() for t in cre})
        res["source"] = "etherscan-internal-txlist"
        res["last_creation_block"] = max(int(t["blockNumber"]) for t in cre)
        res["last_creation_ts"] = max(int(t["timeStamp"]) for t in cre)
        # EIP-161: a fresh contract starts at nonce 1, so creations == nonce - 1.
        nonce_pre = int(rpc_call("eth_getTransactionCount", [FACTORY, "latest"], RPCS[0]), 16)
        if len(addrs) != nonce_pre - 1:
            res["partial_enumeration"] = {"enumerated": len(addrs), "expected_nonce_minus_1": nonce_pre - 1}
            snap = json.load(open("analysis/census.json"))
            addrs = sorted(snap["contracts"])
            res["source"] = "committed-snapshot (Etherscan enumeration incomplete)"

    res["created_contracts"] = len(addrs)
    res["factory_nonce"] = int(rpc_call("eth_getTransactionCount", [FACTORY, "latest"], RPCS[0]), 16)

    codes, eths, deps = {}, {}, {}
    for part in chunks(addrs, BATCH):
        c = batch([("eth_getCode", [a, "latest"]) for a in part])
        e = batch([("eth_getBalance", [a, "latest"]) for a in part])
        d = batch([("eth_call", [{"to": ENTRYPOINT, "data": "0x70a08231" + a[2:].rjust(64, "0")}, "latest"])
                   for a in part])
        for a, cv, ev, dv in zip(part, c, e, d):
            codes[a] = (len(cv) // 2 - 1) if cv and cv != "0x" else 0
            eths[a] = int(ev, 16)
            deps[a] = int(dv, 16) if dv and dv != "0x" else 0
    res["contracts_with_code"] = sum(1 for v in codes.values() if v)

    # proxies = 130-byte ERC1967Proxy runtime
    proxies = [a for a in addrs if codes[a] == 130]
    res["accounts"] = len(proxies)
    res["guardian_contracts"] = sum(1 for a in addrs if codes[a] == 3496)
    res["implementation"] = [a for a in addrs if codes[a] > 4000]

    tok = {k: {} for k in TOKENS}
    for name, addr in TOKENS.items():
        for part in chunks(proxies, BATCH):
            vals = batch([("eth_call", [{"to": addr, "data": "0x70a08231" + a[2:].rjust(64, "0")}, "latest"])
                          for a in part])
            for a, v in zip(part, vals):
                tok[name][a] = int(v, 16) if v and v != "0x" else 0

    funded = [{"account": a, "eth_wei": eths[a], "entrypoint_deposit": deps[a],
               "tokens": {k: tok[k][a] for k in TOKENS if tok[k].get(a)}}
              for a in proxies if eths[a] or deps[a] or any(tok[k].get(a) for k in TOKENS)]
    res["funded_accounts"] = funded
    res["eth_total_wei"] = sum(eths[a] for a in proxies)
    res["entrypoint_deposit_total"] = sum(deps[a] for a in proxies)
    res["token_hits"] = sum(1 for a in proxies for k in TOKENS if tok[k].get(a))
    res["guardian_with_eth"] = sum(1 for a in addrs if codes[a] == 3496 and eths[a])

    # NFTs (the only non-zero asset class) — ERC-721 balanceOf on the two project collections
    nft = {k: {} for k in NFTS}
    for name, addr in NFTS.items():
        for part in chunks(proxies, BATCH):
            vals = batch([("eth_call", [{"to": addr, "data": "0x70a08231" + a[2:].rjust(64, "0")}, "latest"])
                          for a in part])
            for a, v in zip(part, vals):
                nft[name][a] = int(v, 16) if v and v != "0x" else 0
    res["nft_balances"] = {k: sum(nft[k].values()) for k in NFTS}
    res["nft_holder_accounts"] = sum(1 for a in proxies if any(nft[k].get(a) for k in NFTS))
    res["nft_note"] = ("soulbound: transferFrom/safeTransferFrom are onlyRole(DEFAULT_ADMIN_ROLE) "
                       "on both collections; a taken-over account cannot move them")

    # new accounts since the pass-3 snapshot?
    try:
        snap = json.load(open("analysis/census.json"))
        known = set(snap["contracts"])
        new = sorted(set(addrs) - known)
        res["new_since_snapshot"] = len(new)
        res["new_addresses"] = new[:50]
    except Exception:
        res["new_since_snapshot"] = None

    json.dump(res, open(os.path.join(OUT, "census-ci.json"), "w"), indent=1)
    print("CENSUS block=%d created=%d accounts=%d guardians=%d funded=%d new=%s nonce=%d"
          % (block, res["created_contracts"], res["accounts"], res["guardian_contracts"],
             len(funded), res["new_since_snapshot"], res["factory_nonce"]))
    print("CENSUS value: eth_total_wei=%d entrypoint_total=%d token_hits=%d guardian_eth=%d"
          % (res["eth_total_wei"], res["entrypoint_deposit_total"], res["token_hits"],
             res["guardian_with_eth"]))
    print("CENSUS nft: ART=%d PAR=%d holder_accounts=%d (soulbound)"
          % (res["nft_balances"]["ART"], res["nft_balances"]["PAR"], res["nft_holder_accounts"]))
    if funded:
        print("RE-ARM: funded accounts found ->", json.dumps(funded[:10]))
    else:
        print("NO FUNDS: every factory account is empty (ETH, EntryPoint deposit, 6 blue-chips)")


if __name__ == "__main__":
    main()
