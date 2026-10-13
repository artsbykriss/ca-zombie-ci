#!/usr/bin/env python3
"""Child1: fetch VASE (Aurora) and BentoBox V1 (Ethereum) deployed bytecodes + block numbers.

Read-only, keyless public RPCs only. No secrets.
Outputs child1_bytecodes.json with raw codes, keccak hashes, lengths, and block numbers.
"""
import json, urllib.request, sys, hashlib

AURORA = "https://mainnet.aurora.dev"
ETH = "https://ethereum-rpc.publicnode.com"

VASE = "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF"
BENTO = "0xF5BCE5077908a1b7370B9ae04AdC565EBd643966"


def rpc(url, method, params, retries=4):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for _ in range(retries):
        try:
            req = urllib.request.Request(url, data=payload,
                                         headers={"Content-Type": "application/json",
                                                  "User-Agent": "Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=60))
            if "error" in r:
                last = r["error"]
                continue
            return r["result"]
        except Exception as e:  # noqa: BLE001
            last = str(e)
    raise RuntimeError(f"rpc failed {method}: {last}")


def keccak256(data: bytes) -> str:
    from Crypto.Hash import keccak  # pycryptodome (keccak, not NIST SHA3)
    h = keccak.new(digest_bits=256)
    h.update(data)
    return "0x" + h.hexdigest()


def main():
    out = {}
    for label, url, addr in (("vase", AURORA, VASE), ("bentobox", ETH, BENTO)):
        code = rpc(url, "eth_getCode", [addr, "latest"])
        blk = rpc(url, "eth_blockNumber", [])
        out[label] = {
            "address": addr,
            "rpc": url,
            "block": int(blk, 16),
            "code": code,
            "len_bytes": (len(code) - 2) // 2,
            "sha256": "0x" + hashlib.sha256(bytes.fromhex(code[2:])).hexdigest(),
            "keccak256": keccak256(bytes.fromhex(code[2:])),
        }
        print(f"{label}: addr={addr} block={int(blk,16)} len={out[label]['len_bytes']} "
              f"sha256={out[label]['sha256']} keccak={out[label]['keccak256']}")
    json.dump(out, open("child1_bytecodes.json", "w"), indent=1)
    print("saved child1_bytecodes.json")


if __name__ == "__main__":
    main()
