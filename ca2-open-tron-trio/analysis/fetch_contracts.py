#!/usr/bin/env python3
"""Fetch TronGrid getcontract (creation bytecode + on-chain ABI) for the trio.

Read-only. Public keyless endpoint. Serial + retry/backoff; raw responses cached
under analysis/raw/ so re-runs are offline-friendly.
Extracts runtime from the creation tail (constructor + CODECOPY + optional args).
Writes <name>_creation.hex, <name>_runtime.hex, <name>_abi.json, contracts.json.
"""
import json, os, sys, time, hashlib

import requests

OUT = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(OUT, "raw")
os.makedirs(RAW, exist_ok=True)
BASE = "https://api.trongrid.io"
ADDRS = {
    "CherryPool": "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR",
    "PokerGame": "TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn",
    "FireFull": "TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW",
}
HEAD = {"Content-Type": "application/json", "User-Agent": "ca2-tron-research/1.0"}


def post(path, payload, tries=10):
    delay = 3
    for i in range(tries):
        try:
            r = requests.post(BASE + path, json=payload, headers=HEAD, timeout=40)
            if r.status_code == 200:
                j = r.json()
                if isinstance(j, dict) and j.get("Error"):
                    raise RuntimeError(str(j)[:300])
                return j
            err = RuntimeError(f"HTTP {r.status_code}: {r.text[:200]}")
        except Exception as e:  # noqa: BLE001
            err = e
        print(f"  retry {i+1}/{tries} {path}: {str(err)[:160]}", file=sys.stderr)
        time.sleep(delay)
        delay = min(delay * 2, 60)
    raise SystemExit(f"failed: {path} {payload}")


def get_contract(name, addr):
    cache = os.path.join(RAW, f"{name}_getcontract.json")
    if os.path.exists(cache):
        with open(cache) as f:
            return json.load(f)
    j = post("/wallet/getcontract", {"value": addr, "visible": True})
    with open(cache, "w") as f:
        json.dump(j, f)
    time.sleep(2)
    return j


def extract_runtime(code_hex):
    """Parse the Solidity creation tail: PUSHn len [DUP1] PUSHn off PUSH1 0 CODECOPY
    PUSH1 0 RETURN, and return code[off:off+len]. Verified against the runtime prologue.
    """
    import sys
    sys.path.insert(0, OUT)
    from disasm import disasm

    code = bytes.fromhex(code_hex[2:] if code_hex.startswith("0x") else code_hex)
    n = len(code)
    ins = disasm(code)
    for idx, (pc, name, imm, val) in enumerate(ins):
        if name != "CODECOPY":
            continue
        # following: PUSH1 0, RETURN
        if not (idx + 2 < len(ins) and ins[idx + 1][1] == "PUSH1" and ins[idx + 1][3] == 0
                and ins[idx + 2][1] == "RETURN"):
            continue
        # look back up to 6 instructions for PUSH2/PUSH3 size+offset
        win = ins[max(0, idx - 8):idx]
        pushes = [(p, v) for p, nm, im, v in win if nm in ("PUSH2", "PUSH3") and v is not None]
        cands = []
        for ln, off in [(a[1], b[1]) for a in pushes for b in pushes if a is not b]:
            if 0 < ln <= n and off + ln <= n and code[off:off + 5] in (
                    bytes.fromhex("6080604052"), bytes.fromhex("6060604052")):
                cands.append((ln, off))
        if cands:
            ln, off = max(cands)
            runtime = code[off:off + ln]
            return runtime.hex(), off, ln
    # fallback: metadata-trailer slice
    starts = []
    for pro in ("6080604052", "6060604052"):
        i = 0
        needle = bytes.fromhex(pro)
        while True:
            i = code.find(needle, i)
            if i < 0:
                break
            if i >= 1 and code[i - 1] in (0xF3,):
                starts.append(i)
            i += 1
    if not starts:
        raise SystemExit("no runtime prologue")
    start = starts[0]
    end = n
    meta = code.find(bytes.fromhex("a26474726f6e"), start)
    if meta >= 0:
        solc = code.find(bytes.fromhex("64736f6c63"), meta)
        z = code.find(b"\x00\x31", solc) if solc >= 0 else -1
        if z >= 0:
            end = z + 2
    return code[start:end].hex(), start, end - start


def main():
    meta = {"endpoint": "POST https://api.trongrid.io/wallet/getcontract",
            "fetched_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    blk_file = os.path.join(RAW, "nowblock.json")
    if os.path.exists(blk_file):
        block = json.load(open(blk_file))
    else:
        block = post("/wallet/getnowblock", {})
        json.dump(block, open(blk_file, "w"))
    meta["block"] = block.get("block_header", {}).get("raw_data", {}).get("number")
    meta["contracts"] = {}
    for name, addr in ADDRS.items():
        print(f"[{name}] {addr}", file=sys.stderr)
        j = get_contract(name, addr)
        code = j.get("bytecode") or ""
        abi = j.get("abi") or []
        if not code:
            raise SystemExit(f"{name}: no bytecode")
        runtime, off, ln = extract_runtime(code)
        with open(f"{OUT}/{name}_creation.hex", "w") as f:
            f.write(code)
        with open(f"{OUT}/{name}_runtime.hex", "w") as f:
            f.write(runtime)
        with open(f"{OUT}/{name}_abi.json", "w") as f:
            json.dump(abi, f, indent=1, sort_keys=True)
        meta["contracts"][name] = {
            "address": addr,
            "address_hex": j.get("contract_address"),
            "name": j.get("name"),
            "origin_address": j.get("origin_address"),
            "creation_bytes": len(bytes.fromhex(code)),
            "runtime_bytes": ln,
            "runtime_offset": off,
            "abi_entries": len(abi),
            "abi_sha256_prefix": hashlib.sha256(
                json.dumps(abi, sort_keys=True).encode()).hexdigest()[:16],
        }
        print(f"  creation {len(bytes.fromhex(code))}B runtime {ln}B off {off}", file=sys.stderr)
    with open(f"{OUT}/contracts.json", "w") as f:
        json.dump(meta, f, indent=1)
    print(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
