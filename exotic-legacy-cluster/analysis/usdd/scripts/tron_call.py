#!/usr/bin/env python3
"""Minimal TRON read helper (public TronGrid, no keys).
Usage:
  python3 tron_call.py <contract_b58> <function_sig> [abi_arg ...]
ABI args are plain values; uint/int are decimal, address is base58, bytes32 is 0x-hex.
Prints JSON {block, contract, function, result_hex, decoded...}
"""
import json, sys, urllib.request, urllib.error

RPC = "https://api.trongrid.io"
SEL = {
    # tiny built-in selector table for convenience (verified against ABI where possible)
    "totalSupply()": "18160ddd",
    "decimals()": "313ce567",
    "symbol()": "95d89b41",
    "name()": "06fdde03",
    "balanceOf(address)": "70a08231",
    "allowance(address,address)": "dd62ed3e",
    "owner()": "8da5cb5b",
    "authority()": "5c658165",
}


def keccak_selector(sig: str) -> str:
    try:
        from Crypto.Hash import keccak  # pycryptodome
        k = keccak.new(digest_bits=256)
        k.update(sig.encode())
        return k.hexdigest()[:8]
    except Exception:
        return SEL[sig]


def enc_arg(t: str, v: str) -> str:
    if t == "address":
        from base58 import b58decode  # type: ignore
        raw = b58decode(v)[:-4]
        h = raw[1:].hex()
        return h.rjust(64, "0")[-64:]
    if t in ("uint256", "int256", "uint128", "uint64", "uint32", "uint24", "uint16", "uint8"):
        return format(int(v), "064x")
    if t == "bytes":
        h = v[2:] if v.startswith("0x") else v
        n = len(h)//2
        return format(32, "064x") + format(n, "064x") + h.ljust((n + (n % 32 != 0)*32)*2, "0")
    if t == "bytes32":
        h = v[2:] if v.startswith("0x") else v
        return h.rjust(64, "0")
    raise ValueError(t)


def call(contract: str, sig: str, args=None, owner="TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz"):
    args = args or []
    sel = keccak_selector(sig)
    itypes = []
    if "(" in sig:
        inside = sig[sig.index("(") + 1 : sig.rindex(")")]
        itypes = [x.strip() for x in inside.split(",") if x.strip()]
    param = "".join(enc_arg(t, a) for t, a in zip(itypes, args))
    body = json.dumps({
        "owner_address": owner,
        "contract_address": contract,
        "function_selector": sig,
        "parameter": param,
        "visible": True,
    }).encode()
    req = urllib.request.Request(RPC + "/wallet/triggerconstantcontract", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.load(r)
    return {
        "contract": contract,
        "function": sig,
        "parameter": param,
        "selector": sel,
        "result": d.get("result"),
        "constant_result": d.get("constant_result"),
        "energy_used": d.get("energy_used"),
        "txid": d.get("txID"),
    }


def block():
    body = json.dumps({}).encode()
    req = urllib.request.Request(RPC + "/wallet/getnowblock", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.load(r)
    return d["block_header"]["raw_data"]["number"], d["blockID"]


if __name__ == "__main__":
    c, sig = sys.argv[1], sys.argv[2]
    args = sys.argv[3:]
    n, bid = block()
    out = call(c, sig, args)
    out["block"] = n
    out["blockID"] = bid
    print(json.dumps(out, indent=1))
