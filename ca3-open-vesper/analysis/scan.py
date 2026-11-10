#!/usr/bin/env python3
"""Read-only Vesper V2 fleet scanner.

Enumerates every pool in the Vesper prod registries (Ethereum + Base), reads
core ERC-20/accounting state, proxy implementation + admin slots, the strategy
list from each pool accountant, and per-strategy debt/config.  All reads are
eth_call / eth_getStorageAt at a pinned block.  No transaction is signed.

RPC endpoints are public-only by default; an optional override can be supplied
as the 4th argument (never store a keyed URL in this folder).
"""
import json
import sys
import time
import urllib.request

RPCS = {
    1: "https://ethereum-rpc.publicnode.com",
    8453: "https://base-rpc.publicnode.com",
    10: "https://optimism-rpc.publicnode.com",
}
FALLBACKS = {
    1: ["https://eth.drpc.org", "https://1rpc.io/eth"],
    8453: ["https://mainnet.base.org", "https://base.drpc.org"],
}

SEL = {
    "poolAccountant": "0xc12d636b", "governor": "0x0c340a24", "token": "0xfc0c546a",
    "totalSupply": "0x18160ddd", "totalValue": "0xd4c3eea0", "totalDebt": "0xfc7b9c18",
    "tokensHere": "0xb8cb343d", "pricePerShare": "0x99530b06", "paused": "0x5c975abb",
    "stopEverything": "0x4938649a", "poolRewards": "0x8bc6beb2", "getStrategies": "0xb49a60bb",
    "universalFee": "0x5f895e54", "maxProfitAsFee": "0x3e772925", "minDepositLimit": "0x9fd5be18",
    "decimals": "0x313ce567", "name": "0x06fdde03", "symbol": "0x95d89b41", "VERSION": "0xffa1ad74",
    "asset": "0x38d52e0f", "feeCollector": "0xc415b95c", "pool": "0x16f0115b",
    "totalValueCurrent": "0xe645c202", "totalDebtOf": "0x9f2b2833",
    "getWithdrawQueue": "0x11183052", "strategy": "0x228bfd9f", "balanceOf": "0x70a08231",
    "tvl": "0xe5328e06", "totalAssets": "0x01e1d114",
}

EIP1967_IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
EIP1967_ADMIN = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"


class RPC:
    def __init__(self, chain, override=None):
        self.chain = chain
        self.urls = ([override] if override else []) + [RPCS[chain]] + FALLBACKS.get(chain, [])
        self.url = None
        self._id = 0
        self._pick()

    def _pick(self):
        err = None
        for u in self.urls:
            try:
                self.url = u
                b = self.batch([("eth_blockNumber", [])], allow_fail=True)
                if b and "result" in b[0]:
                    return
                err = b
            except Exception as e:
                err = repr(e)
        raise RuntimeError(f"no rpc for chain {self.chain}: {err}")

    def batch(self, calls, allow_fail=False):
        payload = []
        for m, p in calls:
            self._id += 1
            payload.append({"jsonrpc": "2.0", "id": self._id, "method": m, "params": p})
        req = urllib.request.Request(
            self.url,
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
        )
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    out = json.loads(r.read())
                if isinstance(out, dict):
                    out = [out]
                out.sort(key=lambda x: x.get("id", 0))
                return out
            except Exception as e:
                if attempt == 3:
                    if allow_fail:
                        return [{}]
                    raise
                time.sleep(1.5 * (attempt + 1))


def dec_hex(v):
    if not v:
        return None
    try:
        return int(v, 16)
    except Exception:
        return None


def dec_str(v):
    if not v or v == "0x":
        return None
    try:
        b = bytes.fromhex(v[2:])
        if len(b) < 64:
            return b.rstrip(b"\x00").decode("utf-8", "replace")
        ln = int.from_bytes(b[32:64], "big")
        return b[64:64 + ln].decode("utf-8", "replace")
    except Exception:
        return None


def addr(v):
    if not v or not isinstance(v, str) or len(v) < 42:
        return None
    a = "0x" + v[-40:]
    return None if int(a, 16) == 0 else a


def get(rpc, block, to, sig):
    return rpc.batch([("eth_call", [{"to": to, "data": SEL[sig]}, block])])[0]


def scan_pool(rpc, p, block):
    a = p["address"]
    keys = ["VERSION", "name", "token", "decimals", "totalSupply", "totalValue", "totalDebt",
            "tokensHere", "pricePerShare", "paused", "stopEverything", "governor",
            "poolAccountant", "poolRewards", "universalFee", "maxProfitAsFee", "minDepositLimit"]
    calls = []
    for k in keys:
        calls.append(("eth_call", [{"to": a, "data": SEL[k]}, block]))
    calls.append(("eth_getStorageAt", [a, EIP1967_IMPL, block]))
    calls.append(("eth_getStorageAt", [a, EIP1967_ADMIN, block]))
    res = rpc.batch(calls)
    row = {"chainId": p["chainId"], "symbol": p["symbol"], "pool": a,
           "apiAsset": p["asset"]["address"], "apiAssetSymbol": p["asset"]["symbol"],
           "apiVersion": p.get("version"), "birthblock": p.get("birthblock")}
    for i, k in enumerate(keys):
        r = res[i]
        v = r.get("result") if "result" in r else None
        if k in ("VERSION", "name"):
            row[k.lower() if k != "VERSION" else "version"] = dec_str(v)
        elif k in ("token", "governor", "poolAccountant", "poolRewards"):
            row[k] = addr(v)
        elif k in ("paused", "stopEverything"):
            row[k] = dec_hex(v) == 1
        else:
            row[k] = dec_hex(v)
    for slot_key, out_key in ((len(keys), "impl"), (len(keys) + 1, "proxyAdmin")):
        r = res[slot_key]
        row[out_key] = addr(r.get("result")) if "result" in r else None
    # strategies via accountant
    strats = []
    acct = row.get("poolAccountant")
    if acct:
        r = get(rpc, block, acct, "getStrategies")
        raw = r.get("result", "0x")[2:] if "result" in r else ""
        addrs = []
        if len(raw) >= 128:
            # ABI dynamic array: [offset][length][items...]
            ln = int(raw[64:128], 16) if raw else 0
            for i in range(ln):
                w = raw[128 + i * 64:128 + (i + 1) * 64]
                if len(w) < 64:
                    break
                x = addr("0x" + w)
                if x:
                    addrs.append(x)
        if addrs:
            calls = []
            for s in addrs:
                calls += [
                    ("eth_call", [{"to": s, "data": SEL["pool"]}, block]),
                    ("eth_call", [{"to": s, "data": SEL["feeCollector"]}, block]),
                    ("eth_call", [{"to": s, "data": SEL["token"]}, block]),
                    ("eth_call", [{"to": s, "data": SEL["totalValue"]}, block]),
                    ("eth_call", [{"to": s, "data": SEL["tvl"]}, block]),
                    ("eth_getStorageAt", [s, EIP1967_IMPL, block]),
                ]
            rr = rpc.batch(calls)
            for j, s in enumerate(addrs):
                q = rr[j * 6:(j + 1) * 6]
                strats.append({
                    "address": s,
                    "pool": addr(q[0].get("result")),
                    "feeCollector": addr(q[1].get("result")),
                    "token": addr(q[2].get("result")),
                    "totalValue": dec_hex(q[3].get("result")),
                    "tvl": dec_hex(q[4].get("result")),
                    "impl": addr(q[5].get("result")),
                })
            # per-strategy debt
            for s in strats:
                r2 = rpc.batch([("eth_call", [{"to": acct, "data": SEL["totalDebtOf"] + s["address"][2:].rjust(64, "0")}, block])])
                s["debt"] = dec_hex(r2[0].get("result"))
    row["strategies"] = strats
    # asset balance held directly by pool
    tok = row.get("token")
    if tok:
        r = rpc.batch([("eth_call", [{"to": tok, "data": SEL["balanceOf"] + a[2:].rjust(64, "0")}, block])])
        row["assetBalance"] = dec_hex(r[0].get("result"))
    return row


def main():
    chain = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    api = sys.argv[2] if len(sys.argv) > 2 else ("analysis/api-pools.json" if chain == 1 else "analysis/api-base-pools.json")
    out = sys.argv[3] if len(sys.argv) > 3 else f"analysis/state-{chain}.json"
    override = sys.argv[4] if len(sys.argv) > 4 else None
    pools = json.load(open(api))
    rpc = RPC(chain, override)
    blk = dec_hex(rpc.batch([("eth_blockNumber", [])])[0]["result"])
    rows = []
    for p in pools:
        try:
            rows.append(scan_pool(rpc, p, hex(blk)))
            print("ok", p["symbol"], file=sys.stderr)
        except Exception as e:
            rows.append({"pool": p["address"], "symbol": p["symbol"], "error": str(e)[:200]})
            print("ERR", p["symbol"], e, file=sys.stderr)
    json.dump({"chainId": chain, "block": blk, "rpc": rpc.url, "pools": rows}, open(out, "w"), indent=1)
    print(out, "block", blk, "pools", len(rows), "rpc", rpc.url)


if __name__ == "__main__":
    main()
