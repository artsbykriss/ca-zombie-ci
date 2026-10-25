#!/usr/bin/env python3
"""Read live USDC + native balance and impl for each candidate clone via public Unichain RPC.
READ-ONLY (eth_call / eth_getCode / eth_getBalance only). Public endpoints.
Outputs: vaults.json, vaults.csv, ci-out/rpc_raw.json
"""
import json, os, time, sys
import requests

H = {"User-Agent": "Mozilla/5.0 (research; read-only)", "Content-Type": "application/json"}
RPC = os.environ.get("UNICHAIN_RPC", "https://mainnet.unichain.org")
USDC = "0x078D782b760474a361dDA0AF3839290b0EF57AD6"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ci-out")
os.makedirs(OUT, exist_ok=True)
PROXY_PREFIX = "0x60806040523615604957366000803760008036817f"
PROXY_SUFFIX = "5af43d6000803e156044573d6000f35b3d6000fd5b00"

def rpc_batch(calls, tries=6):
    """calls: list of (method, params). returns list of results (or None)."""
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    for attempt in range(tries):
        try:
            r = requests.post(RPC, headers=H, data=json.dumps(payload), timeout=60)
            if r.status_code == 200:
                d = r.json()
                if isinstance(d, dict):  # single error
                    raise RuntimeError(str(d))
                by_id = {x["id"]: x for x in d}
                out = []
                for i in range(len(calls)):
                    x = by_id.get(i)
                    out.append(x.get("result") if x and "result" in x else None)
                return out
            time.sleep(1.5 * (attempt + 1))
        except Exception:
            time.sleep(1.5 * (attempt + 1))
    return [None] * len(calls)

def pad_addr(a):
    return "0x" + a.lower().replace("0x", "").rjust(64, "0")

def main():
    recs = json.load(open(os.path.join(OUT, "clones_raw.json")))
    addrs = [r["address"] for r in recs if r.get("address")]
    print("clones", len(addrs))
    raw = {}
    CHUNK = 3  # 3 clones x 3 calls = 9 calls per JSON-RPC batch (public RPC caps batches at 10)
    for i in range(0, len(addrs), CHUNK):
        chunk = addrs[i:i + CHUNK]
        calls = []
        for a in chunk:
            calls.append(("eth_call", [{"to": USDC, "data": "0x70a08231" + pad_addr(a)[2:]}, "latest"]))
            calls.append(("eth_getCode", [a, "latest"]))
            calls.append(("eth_getBalance", [a, "latest"]))
        res = rpc_batch(calls)
        for j, a in enumerate(chunk):
            bal = res[3 * j]
            code = res[3 * j + 1]
            nat = res[3 * j + 2]
            raw[a.lower()] = {"usdc_raw": bal, "code": code, "native_raw": nat}
        if (i // CHUNK) % 10 == 0:
            print("batched", i + len(chunk))
        time.sleep(0.15)
    # block number
    bn = rpc_batch([("eth_blockNumber", [])])[0]
    raw["_block"] = bn
    json.dump(raw, open(os.path.join(OUT, "rpc_raw.json"), "w"))

    vaults = []
    for r in recs:
        a = r["address"]
        k = a.lower()
        d = raw.get(k, {})
        usdc = int(d["usdc_raw"], 16) if d.get("usdc_raw") else None
        native = int(d["native_raw"], 16) if d.get("native_raw") else None
        code = d.get("code") or ""
        is_proxy = code.startswith(PROXY_PREFIX) and code.endswith(PROXY_SUFFIX)
        impl_from_code = "0x" + code[-(64 + 2):-2][-40:] if len(code) >= 66 else None
        ca = r.get("constructor_args") or ""
        impl_from_args = ("0x" + ca[-40:]) if len(ca) >= 40 else None
        vaults.append({
            "address": a,
            "impl_from_args": impl_from_args,
            "impl_from_code": impl_from_code,
            "creator": r.get("creator"),
            "creation_tx": r.get("creation_tx"),
            "usdc_raw": usdc,
            "usdc": (usdc / 1e6) if usdc is not None else None,
            "native_wei": native,
            "is_proxy_clone": is_proxy,
            "code_len": len(code) // 2 - 1 if code.startswith("0x") else 0,
            "verified_at": r.get("verified_at"),
        })
    vaults.sort(key=lambda v: (v["usdc_raw"] or 0), reverse=True)
    json.dump({"block": raw.get("_block"), "vaults": vaults}, open(os.path.join(HERE, "vaults.json"), "w"), indent=1)
    with open(os.path.join(HERE, "vaults.csv"), "w") as f:
        f.write("address,impl,creator,usdc,usdc_raw,native_wei,is_proxy_clone,creation_tx\n")
        for v in vaults:
            f.write(f"{v['address']},{v['impl_from_args']},{v['creator']},{v['usdc']},{v['usdc_raw']},{v['native_wei']},{v['is_proxy_clone']},{v['creation_tx']}\n")
    funded = [v for v in vaults if (v["usdc_raw"] or 0) > 0]
    tot = sum(v["usdc_raw"] or 0 for v in vaults)
    print("BLOCK", raw.get("_block"))
    print("total clones", len(vaults), "proxy-shaped", sum(1 for v in vaults if v["is_proxy_clone"]))
    print("funded (>0 USDC)", len(funded), "total USDC", tot / 1e6)
    print("impls:", {})
    import collections
    print(collections.Counter(v["impl_from_args"] for v in vaults))
    for v in vaults[:20]:
        print(f"  {v['address']} {v['usdc']} USDC impl={v['impl_from_args']}")

if __name__ == "__main__":
    main()
