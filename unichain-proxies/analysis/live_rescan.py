#!/usr/bin/env python3
"""Live re-scan of the 299 ImmutableProxy clones on Unichain (chain 130).
READ-ONLY: eth_getCode / eth_call / eth_getBalance only. Public RPC.
No secrets. Writes analysis/live_rescan.json
"""
import json, os, time
import requests

H = {"User-Agent": "Mozilla/5.0 (research; read-only)", "Content-Type": "application/json"}
RPC = os.environ.get("UNICHAIN_RPC", "https://mainnet.unichain.org")
USDC = "0x078D782b760474a361dDA0AF3839290b0EF57AD6"
HERE = os.path.dirname(os.path.abspath(__file__))
CLONES = os.path.join(HERE, "..", "children", "enum", "ci-out", "clones_raw.json")


def rpc_batch(calls, tries=6):
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    for attempt in range(tries):
        try:
            r = requests.post(RPC, headers=H, data=json.dumps(payload), timeout=60)
            if r.status_code == 200:
                d = r.json()
                if isinstance(d, dict):
                    raise RuntimeError(str(d))
                by_id = {x["id"]: x for x in d}
                return [by_id.get(i, {}).get("result") for i in range(len(calls))]
        except Exception:
            pass
        time.sleep(1.5 * (attempt + 1))
    return [None] * len(calls)


def pad(a):
    return "0x" + a.lower().replace("0x", "").rjust(64, "0")


def main():
    recs = json.load(open(CLONES))
    addrs = [r["address"] for r in recs if r.get("address")]
    print("clones", len(addrs))
    out = {}
    CHUNK = 3
    for i in range(0, len(addrs), CHUNK):
        chunk = addrs[i:i + CHUNK]
        calls = []
        for a in chunk:
            calls.append(("eth_call", [{"to": USDC, "data": "0x70a08231" + pad(a)[2:]}, "latest"]))
            calls.append(("eth_getBalance", [a, "latest"]))
            calls.append(("eth_getCode", [a, "latest"]))
        res = rpc_batch(calls)
        for j, a in enumerate(chunk):
            out[a.lower()] = {"usdc": res[3 * j], "native": res[3 * j + 1], "code": res[3 * j + 2]}
        time.sleep(0.12)
    blk = rpc_batch([("eth_blockNumber", [])])[0]
    funded_usdc = {k: v for k, v in out.items() if v["usdc"] and int(v["usdc"], 16) > 0}
    funded_nat = {k: v for k, v in out.items() if v["native"] and int(v["native"], 16) > 0}
    tot_usdc = sum(int(v["usdc"], 16) for v in out.values() if v["usdc"])
    print("block", blk, int(blk, 16))
    print("clones scanned", len(out))
    print("funded USDC", len(funded_usdc), "total USDC", tot_usdc / 1e6)
    print("funded native", len(funded_nat))
    json.dump({"block": blk, "block_dec": int(blk, 16), "n": len(out), "results": out,
               "funded_usdc": funded_usdc, "funded_native": funded_nat,
               "total_usdc_raw": tot_usdc}, open(os.path.join(HERE, "live_rescan.json"), "w"))


if __name__ == "__main__":
    main()
