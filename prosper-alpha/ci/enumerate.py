#!/usr/bin/env python3
"""Enumerate Prosper Alpha markets on Pharos via ProsperVaultLinked logs and
dump on-chain state (read-only). Writes JSON into ci-out/.
No secrets; keyless public RPC only."""
import json, urllib.request, concurrent.futures, os, sys, time

RPC = os.environ.get("PHAROS_RPC", "https://rpc.pharos.xyz")
FACTORY = "0xefdbb0ea7647b0e21aef7a3b7a5d6a632c3116c8"
TOPIC = "0x6d679d9dcb91cccb2f253f24f8f9b53871eac50c475cb8335cfdd93a32212865"  # ProsperVaultLinked
WPROS = "0x52c48d4213107b20bc583832b0d951fb9ca8f0b0"
FROM_BLOCK = int(os.environ.get("SCAN_FROM", "17516201"))  # adapter hard-coded factory deploy block
MAX_WORKERS = int(os.environ.get("MAX_WORKERS", "6"))
OUT = os.environ.get("OUT_DIR", "ci-out")

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
    for _ in range(4):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.load(r).get("result")
        except Exception as e:
            time.sleep(1)
    return None

def batch(reqs):
    body = json.dumps(reqs).encode()
    req = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
    for _ in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                res = json.load(r)
            return {x["id"]: x.get("result") for x in res}
        except Exception:
            time.sleep(1)
    return {}

def latest():
    if os.environ.get("SCAN_TO"):
        return int(os.environ["SCAN_TO"])
    b = rpc("eth_blockNumber", [])
    return int(b, 16)

def scan_window(args):
    frm, to = args
    r = rpc("eth_getLogs", [{"address": FACTORY, "topics": [TOPIC],
                             "fromBlock": hex(frm), "toBlock": hex(to)}])
    return frm, (r or [])

def main():
    os.makedirs(OUT, exist_ok=True)
    end = latest()
    block = end  # state read block
    print(f"latest block {end}; scanning {FROM_BLOCK}..{end} in 1000-block windows", flush=True)
    windows = [(b, min(b + 999, end)) for b in range(FROM_BLOCK, end + 1, 1000)]
    logs = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        for frm, r in ex.map(scan_window, windows):
            for lg in r:
                logs.append(lg)
    print("raw logs:", len(logs), flush=True)

    markets = {}
    for lg in logs:
        t = lg["topics"]; d = lg["data"][2:]
        market = "0x" + d[24:64]
        buyback = "0x" + d[88:128]
        markets[market.lower()] = {
            "block": int(lg["blockNumber"], 16),
            "tx": lg["transactionHash"],
            "r25Vault": "0x" + t[1][-40:],
            "campaignId": t[2],
            "pToken": "0x" + t[3][-40:],
            "market": market,
            "buyback": buyback,
        }
    print("unique markets:", len(markets), flush=True)

    # on-chain state
    SELS = {
        "externalPair": "0x1c5eac33", "pToken": "0x58a06f07", "curveK": "0x19b80ee7",
        "phase": "0xb1c9fe6e", "startedAt": "0xf21f537d", "endsAt": "0x0a09284a",
        "migrationEscrow": "0x54e9d781", "curatorFeeRecipient": "0x2bbd63d9",
        "wrappedNative": "0xeb6d3a11", "accessController": "0xbc43cbaf",
        "globalConfig": "0xa7c1abe0", "realReserve_0172d417": "0x0172d417",
        "virt_36010120": "0x36010120", "virt_4bc55300": "0x4bc55300",
    }
    reqs = []; keys = []
    mlist = list(markets.keys())
    for m in mlist:
        for name, s in SELS.items():
            reqs.append({"jsonrpc": "2.0", "id": len(reqs), "method": "eth_call",
                         "params": [{"to": m, "data": s}, hex(block)]}); keys.append((m, name))
        reqs.append({"jsonrpc": "2.0", "id": len(reqs), "method": "eth_call",
                     "params": [{"to": WPROS, "data": "0x70a08231" + "0" * 24 + m[2:]}, hex(block)]})
        keys.append((m, "wpros_balance"))
        reqs.append({"jsonrpc": "2.0", "id": len(reqs), "method": "eth_getBalance", "params": [m, hex(block)]})
        keys.append((m, "native_balance"))
    res = {}
    for i in range(0, len(reqs), 10):
        res.update(batch(reqs[i:i + 10]))
    # retry any missing/None reads individually (public RPC occasionally drops batched calls)
    for _ in range(3):
        missing = [k for k in range(len(reqs)) if res.get(k) in (None, "0x")]
        if not missing:
            break
        for k in missing:
            r = rpc(reqs[k]["method"], reqs[k]["params"])
            if r not in (None, "0x"):
                res[k] = r
    for j, (m, name) in enumerate(keys):
        r = res.get(j)
        if r is None or r == "0x":
            v = None
        elif name in ("externalPair", "pToken", "migrationEscrow", "curatorFeeRecipient",
                      "wrappedNative", "accessController", "globalConfig"):
            v = "0x" + r[-40:]
        else:
            v = int(r, 16)
        markets[m][name] = v

    total_wpros = 0
    for m, d in markets.items():
        total_wpros += d.get("wpros_balance") or 0

    out = {"block": block, "market_count": len(markets), "total_wpros_in_markets": total_wpros,
           "markets": markets}
    with open(os.path.join(OUT, "markets_onchain.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("total WPROS held by markets:", total_wpros / 1e18, flush=True)

    # phase summary
    by_phase = {}
    for d in markets.values():
        p = d.get("phase")
        by_phase.setdefault(p, [0, 0])
        by_phase[p][0] += 1
        by_phase[p][1] += d.get("wpros_balance") or 0
    print("by phase (count, wpros):", {k: (v[0], v[1] / 1e18) for k, v in by_phase.items()}, flush=True)

if __name__ == "__main__":
    main()
