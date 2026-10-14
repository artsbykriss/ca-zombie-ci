#!/usr/bin/env python3
"""Extract candidate Radix addresses from a raw notarized transaction hex and
resolve which ones exist on-chain via the public Gateway (read-only)."""
import json, re, sys, urllib.request, time
from bech32m import encode

GW = "https://mainnet.radixdlt.com"
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 read-only-research"}

def http(url, body, timeout=45, tries=6):
    for t in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=UA)
            return json.loads(urllib.request.urlopen(req, timeout=timeout).read())
        except urllib.error.HTTPError as e:
            return json.loads(e.read())
        except Exception:
            time.sleep(1 + t)
    return None

HRP_BY_TYPE = {0x51: "account_rdx", 0x5d: "resource_rdx", 0xc0: "component_rdx",
               0x52: "identity_rdx", 0xd1: "account_rdx", 0x02: "validator_rdx",
               0x03: "accesscontroller_rdx", 0x00: "package_rdx", 0x61: "internal_vault_rdx"}

def candidates(raw):
    out = {}
    for i in range(len(raw) - 30):
        b = raw[i]
        if b in HRP_BY_TYPE:
            blob = bytes(raw[i:i + 30])
            try:
                addr = encode(HRP_BY_TYPE[b], blob)
            except Exception:
                continue
            out.setdefault(addr, (i, blob.hex()))
    return out

def resolve(addrs):
    res = {}
    addrs = list(addrs)
    for i in range(0, len(addrs), 20):
        r = http(f"{GW}/state/entity/details", {"addresses": addrs[i:i + 20]})
        if not r:
            continue
        for it in r.get("items", []):
            det = it.get("details", {}) or {}
            res[it["address"]] = {"type": det.get("type"), "blueprint": det.get("blueprint_name")}
        time.sleep(0.2)
    return res

if __name__ == "__main__":
    path = sys.argv[1]
    d = json.load(open(path))
    raw = bytes.fromhex(d["raw_hex"])
    cands = candidates(raw)
    print(f"{len(cands)} candidates")
    resolved = resolve(cands.keys())
    for addr, info in resolved.items():
        print(f"  {addr}  type={info['type']} bp={info['blueprint']}  off={cands[addr][0]}")
    # ascii context
    for m in re.finditer(rb'[ -~]{4,}', raw):
        s = m.group().decode()
        print(f"  ASCII@{m.start()}: {s}")
