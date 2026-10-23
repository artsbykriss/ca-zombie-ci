#!/usr/bin/env python3
"""Pin deployed Anchor versions for named live Solana programs.

Read-only. For each program id:
  - resolve programdata account + last deploy slot + upgrade authority
  - fetch + save the ELF (truncated to real ELF size)
  - fetch upgrade history (signatures touching the programdata account)
  - classify anchor family from embedded marker strings
  - date the last deploy via blockTime
Outputs analysis/pinned.json
"""
import base64, json, os, sys, time, urllib.request

_B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58encode(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = _B58[r] + out
    for c in b:
        if c == 0: out = "1" + out
        else: break
    return out.encode()
def b58decode(s):
    n = 0
    for ch in s:
        n = n * 58 + _B58.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for ch in s:
        if ch == "1": pad += 1
        else: break
    return b"\x00" * pad + b

import os as _os
ENDPOINTS = [u for u in [_os.environ.get("SOLANA_RPC_URL")] if u] + \
            ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
def rpc_any(method, params):
    last = None
    for u in ENDPOINTS:
        for attempt in range(2):
            try:
                body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
                req = urllib.request.Request(u, data=body, headers={"Content-Type": "application/json"})
                with urllib.request.urlopen(req, timeout=90) as r:
                    j = json.loads(r.read())
                if "error" in j:
                    last = j["error"]; break
                return j
            except Exception as e:
                last = e; time.sleep(1)
    raise RuntimeError(f"{method}: {last}")

def elf_true_size(b):
    if b[:4] != b"\x7fELF": return len(b)
    e_shoff = int.from_bytes(b[0x28:0x30], "little")
    e_shentsize = int.from_bytes(b[0x3a:0x3c], "little")
    e_shnum = int.from_bytes(b[0x3c:0x3e], "little")
    return min(len(b), e_shoff + e_shentsize * e_shnum)

def fetch_program(pid, elfdir):
    info = rpc_any("getAccountInfo", [pid, {"encoding": "base64"}])["result"]["value"]
    if info is None:
        return {"program": pid, "error": "no account"}
    out = {"program": pid, "owner": info["owner"], "executable": info["executable"], "lamports": info["lamports"]}
    if not info["executable"]:
        out["error"] = "not executable"; return out
    d = base64.b64decode(info["data"][0])
    state = int.from_bytes(d[:4], "little")
    out["loader_state"] = state
    if state != 2:
        out["error"] = "not upgradeable"; return out
    pd = b58encode(d[4:36]).decode()
    out["programdata"] = pd
    v2 = rpc_any("getAccountInfo", [pd, {"encoding": "base64"}])["result"]["value"]
    d2 = base64.b64decode(v2["data"][0])
    out["programdata_len"] = len(d2)
    out["programdata_lamports"] = v2["lamports"]
    last_slot = int.from_bytes(d2[4:12], "little")
    has_auth = d2[12]
    out["last_deploy_slot"] = last_slot
    out["upgrade_authority"] = b58encode(d2[13:45]).decode() if has_auth else None
    elf = d2[13 + (32 if has_auth else 0):]
    tsize = elf_true_size(elf)
    out["elf_len_account"] = len(elf)
    out["elf_len_true"] = tsize
    os.makedirs(elfdir, exist_ok=True)
    with open(os.path.join(elfdir, pid + ".so"), "wb") as f:
        f.write(elf[:tsize])
    # block time of last deploy
    try:
        bt = rpc_any("getBlockTime", [last_slot]).get("result")
        out["last_deploy_unix"] = bt
        if bt:
            out["last_deploy_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(bt))
    except Exception as e:
        out["last_deploy_unix_error"] = str(e)
    # upgrade history
    try:
        sigs = rpc_any("getSignaturesForAddress", [pd, {"limit": 25}])["result"]
        hist = []
        for s in sigs:
            hist.append({"sig": s["signature"], "slot": s["slot"], "blockTime": s.get("blockTime"),
                         "err": s.get("err") is not None})
        out["upgrade_history"] = hist
    except Exception as e:
        out["upgrade_history_error"] = str(e)
    return out

PROGRAMS = {
    "marginfi-v2": "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA",
    "raydium-clmm": "CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK",
    "mpl-bubblegum": "BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY",
    "manifest": "MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms",
    "openbook-v2": "opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb",
    "light-system": "SySTEM1eSU2p4BGQfQpimFEWWSC1XDFeun3Nqzz3rT7",
    "chainlink-ocr2": "E3j24rx12SyVsG6quKuZPbQqZPkhAUCh8Uek4XrKYD2x",
    "chainlink-store": "9kRNTZmoZSiTBuXC62dzK9E7gC7huYgcmRRhYv3i4osC",
    "helium-sub-daos": "hdaoVTCqhfHHo75XdAMxBKdUqvq1i5bF23sisBqVgGR",
    "helium-data-credits": "credMBJhYFzfn7NxBMdU4aUqFggAjgztaCcv2Fo6fPT",
    "helium-lazy-distributor": "1azyuavdMyvsivtNxPoz6SucD18eDHeXzFCUPq5XU7w",
    "helium-treasury": "treaf4wWBBty3fHdyBpo35Mz84M8k3heKXmjmi9vFt5",
    "helium-mobile-entity-manager": "memMa1HG4odAFmUbGWfPwS1WWfK95k99F2YTkGvyxZr",
}

if __name__ == "__main__":
    elfdir = sys.argv[1] if len(sys.argv) > 1 else "analysis/elf"
    extra = sys.argv[2:]
    progs = dict(PROGRAMS)
    for i in range(0, len(extra) - 1, 2):
        progs[extra[i]] = extra[i + 1]
    res = {}
    for name, pid in progs.items():
        try:
            r = fetch_program(pid, elfdir)
        except Exception as e:
            r = {"program": pid, "error": str(e)}
        r["name"] = name
        res[name] = r
        print(name, json.dumps(r)[:400], flush=True)
    with open("analysis/pinned_raw.json", "w") as f:
        json.dump(res, f, indent=2)
