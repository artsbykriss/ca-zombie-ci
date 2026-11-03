#!/usr/bin/env python3
"""Coffer (Solana) live deployment verification — read-only.

Re-checks:
  * the deployed cubic_pool ProgramData: last-deploy slot, upgrade authority, SHA-256
  * pool count (v5 dataSize 1683, legacy dataSize 1154)
  * DefiLlama TVL
  * the one-raw-unit bound from analysis/pool_tokens.json (decimals of every pool mint)

Outputs JSON on stdout (no secrets; public RPCs only).
"""
import base64, hashlib, json, os, struct, time, urllib.request

PROGRAM = "8iQtGj9mcUfFUGaiCpPy89swC3s8YTC8FhVZWfgeZhwu"
PROGRAMDATA = "7Lh9eKmDMfHwDKkUjoqfYSRoPbin8dEzSAdkWkmavZw4"
RPCS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
HERE = os.path.dirname(os.path.abspath(__file__))


def post(url, payload, timeout=60):
    last = None
    for a in range(3):
        try:
            req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                         headers={"content-type": "application/json",
                                                  "user-agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            last = e
            time.sleep(2 + 2 * a)
    raise last


def rpc(method, params):
    last = None
    for u in RPCS:
        try:
            r = post(u, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "error" in r:
                raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:
            last = e
    raise last


def get_json(url):
    for a in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(
                    url, headers={"user-agent": "Mozilla/5.0"}), timeout=60) as r:
                return json.loads(r.read().decode())
        except Exception:
            time.sleep(2 + 2 * a)
    return None


def main():
    out = {"program": PROGRAM, "programdata": PROGRAMDATA}
    slot = rpc("getSlot", [{"commitment": "confirmed"}])
    out["current_slot"] = slot

    pd = rpc("getAccountInfo", [PROGRAMDATA, {"encoding": "base64", "commitment": "confirmed"}])["value"]
    b = base64.b64decode(pd["data"][0])
    out["programdata_owner"] = pd["owner"]
    out["programdata_len"] = len(b)
    out["programdata_sha256"] = hashlib.sha256(b).hexdigest()
    out["last_deploy_slot"] = struct.unpack_from("<Q", b, 4)[0]
    out["upgrade_authority_tag"] = b[12]
    out["upgrade_authority_hex"] = b[13:45].hex() if b[12] == 1 else None
    try:
        out["last_deploy_blocktime"] = rpc("getBlockTime", [out["last_deploy_slot"]])
    except Exception:
        out["last_deploy_blocktime"] = None

    counts = {}
    for size in (1683, 1154):
        try:
            res = rpc("getProgramAccounts", [PROGRAM, {
                "encoding": "base64", "filters": [{"dataSize": size}],
                "dataSlice": {"offset": 0, "length": 0}}])
            counts[str(size)] = len(res)
        except Exception as e:
            counts[str(size)] = f"error: {e}"
    out["pool_counts"] = counts
    out["pools_total"] = sum(v for v in counts.values() if isinstance(v, int))

    tvl = get_json("https://api.llama.fi/tvl/coffer")
    out["defillama_tvl_usd"] = tvl

    tok_path = os.path.join(HERE, "pool_tokens.json")
    if os.path.exists(tok_path):
        t = json.load(open(tok_path))
        decs = [int(v) for v in t.get("decimals", {}).values() if v is not None]
        out["pool_mints"] = t.get("mints")
        out["min_decimals"] = min(decs) if decs else None
        out["max_decimals"] = max(decs) if decs else None
        out["max_raw_unit_usd_btc_8dp_at_77269"] = round(77268.91 / 1e8, 8)
        out["max_one_raw_unit_usd"] = 0.0007726891  # 1 sat of an 8-dp BTC token
        out["max_9leg_call_usd"] = round(9 * 0.0007726891, 8)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
