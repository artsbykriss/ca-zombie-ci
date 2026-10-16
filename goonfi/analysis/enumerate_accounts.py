#!/usr/bin/env python3
"""Enumerate GoonFi program accounts (state) + decode 2048-byte pool states.
Read-only. Tries multiple RPCs for getProgramAccounts."""
import json, os, sys, base64, struct, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

OUT = os.path.dirname(os.path.abspath(__file__))
PROG = "goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE"
RPCS = ["https://solana-rpc.publicnode.com", "https://api.mainnet-beta.solana.com"]


def call(url, method, params, retries=3):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for a in range(retries):
        try:
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.loads(r.read())
            if "error" in out:
                last = out["error"]
                time.sleep(1.5 * (a + 1)); continue
            return out
        except Exception as ex:  # noqa
            last = str(ex); time.sleep(1.5 * (a + 1))
    return {"error": last}


def gpa(url, size):
    return call(url, "getProgramAccounts", [PROG, {
        "encoding": "base64",
        "filters": [{"dataSize": size}],
        "commitment": "finalized",
    }])


def main():
    all_accs = {}
    for url in RPCS:
        for size in (2048, 719000, 165, 32):
            r = gpa(url, size)
            if "result" in r:
                print(url.split("/")[2], "size", size, "->", len(r["result"]))
                for item in r["result"]:
                    all_accs[item["pubkey"]] = {"size": size, "data": item["account"]["data"][0],
                                                "owner": item["account"]["owner"], "lamports": item["account"]["lamports"]}
            else:
                print(url.split("/")[2], "size", size, "-> ERR", str(r.get("error"))[:120])
            time.sleep(0.5)
        if all_accs:
            break
    with open(os.path.join(OUT, "program-accounts.json"), "w") as f:
        json.dump(all_accs, f, indent=1)
    print("total accounts:", len(all_accs))
    # decode 2048-byte states: dump first 256 bytes hex + strings
    dec = {}
    for pk, a in all_accs.items():
        if a["size"] != 2048:
            continue
        raw = base64.b64decode(a["data"])
        dec[pk] = {
            "lamports": a["lamports"],
            "hex0_128": raw[:128].hex(),
            "hex128_256": raw[128:256].hex(),
            "u64_at": {str(off): struct.unpack("<Q", raw[off:off + 8])[0] for off in range(0, 96, 8)},
        }
    with open(os.path.join(OUT, "state-2048-decoded.json"), "w") as f:
        json.dump(dec, f, indent=1)
    print("2048-byte states:", len(dec))
    for pk in list(dec)[:5]:
        print(pk, dec[pk]["hex0_128"])


if __name__ == "__main__":
    main()
