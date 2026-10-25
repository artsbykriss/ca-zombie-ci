#!/usr/bin/env python3
"""Read-only probe: shieldedWithdrawal / shieldedTransfer / shieldedSwap from a fresh EOA.

Uses a KEYLESS public Base RPC. eth_call only; nothing is signed or sent.
Builds calldata with eth_abi, so the pool's own _checkSpend / _verifyProof gates are hit.
"""
import json, urllib.request, sys
from eth_abi import encode as abi_encode
from eth_utils import keccak, to_checksum_address

RPC = "https://base-rpc.publicnode.com"
POOL = "0xd64EF1417EB047ed0b54736a5a41F01178C391c6"
FRESH = "0x000000000000000000000000000000000000dEaD"
Z = b"\x00" * 32

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    ).encode(), headers={"Content-Type": "application/json", "User-Agent": "nullmask-research"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())["result"]

def call(data, frm=FRESH):
    try:
        r = rpc("eth_call", [{"from": frm, "to": POOL, "data": data}, "latest"])
        return "OK " + ("0x" + r[2:][:80])
    except KeyError:
        pass
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_call",
         "params": [{"from": frm, "to": POOL, "data": data}, "latest"]}
    ).encode(), headers={"Content-Type": "application/json", "User-Agent": "nullmask-research"})
    body = json.loads(urllib.request.urlopen(req, timeout=30).read())
    err = body.get("error", body)
    return "REVERT " + json.dumps(err)[:300]

block = int(rpc("eth_blockNumber", []), 16)
root = int(rpc("eth_call", [{"to": POOL, "data": "0x" + keccak(text="noteTreeRoot()")[:4].hex()}, "latest"]), 16)
print(f"# block={block} noteTreeRoot={root}")
root32 = root.to_bytes(32, "big")

def sel(sig): return keccak(text=sig)[:4]

# ---- shieldedWithdrawal ----
W_TYPES = ["bytes32[6]", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32",
           "bytes32", "bytes32", "bytes32[9]", "bytes32[9]",
           "(bytes32,bytes32,bytes32)", "bytes32", "bytes32", "bytes32"]
W_SIG = ("shieldedWithdrawal((bytes32[6],bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,"
         "bytes32,bytes32[9],bytes32[9],(bytes32,bytes32,bytes32),bytes32,bytes32,bytes32),bytes)")
w_args = [[Z]*6, Z, root32, Z, Z, Z, Z, Z, [Z]*9, [Z]*9, (Z, Z, Z), Z, Z, Z]
w_data_zero_root = sel(W_SIG) + abi_encode(W_TYPES + ["bytes"], [[Z]*6, Z, Z, Z, Z, Z, Z, Z, [Z]*9, [Z]*9, (Z,Z,Z), Z, Z, Z, b""])
w_data_real_root = sel(W_SIG) + abi_encode(W_TYPES + ["bytes"], w_args + [b"\xde\xad\xbe\xef"])
print("\n== shieldedWithdrawal ==")
print("  zero-root, empty proof   ->", call("0x" + w_data_zero_root.hex()))
print("  real-root, garbage proof ->", call("0x" + w_data_real_root.hex()))

# ---- shieldedTransfer ----
T_TYPES = ["bytes32[6]", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32",
           "bytes32[9]", "bytes32[9]", "bytes32[9]",
           "(bytes32,bytes32,bytes32)", "bytes32", "bytes32", "bytes32"]
T_SIG = ("shieldedTransfer((bytes32[6],bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,"
         "bytes32[9],bytes32[9],bytes32[9],(bytes32,bytes32,bytes32),bytes32,bytes32,bytes32),bytes)")
t_data = sel(T_SIG) + abi_encode(T_TYPES + ["bytes"], [[Z]*6, Z, root32, Z, Z, Z, Z, [Z]*9, [Z]*9, [Z]*9, (Z,Z,Z), Z, Z, Z, b"\xde\xad\xbe\xef"])
print("\n== shieldedTransfer ==")
print("  real-root, garbage proof ->", call("0x" + t_data.hex()))

# ---- shieldedSwap ----
S_TYPES = ["bytes32[6]", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32", "bytes32",
           "(bytes32,bytes32[4],bytes32,bytes32)",
           "bytes32", "bytes32[9]", "bytes32[9]", "bytes32[6]",
           "(bytes32,bytes32,bytes32)", "bytes32", "bytes32", "bytes32"]
S_SIG = ("shieldedSwap((bytes32[6],bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,"
         "(bytes32,bytes32[4],bytes32,bytes32),bytes32,bytes32[9],bytes32[9],bytes32[6],"
         "(bytes32,bytes32,bytes32),bytes32,bytes32,bytes32),bytes)")
s_data = sel(S_SIG) + abi_encode(S_TYPES + ["bytes"], [[Z]*6, Z, root32, Z, Z, Z, Z, (Z,[Z]*4,Z,Z), Z, [Z]*9, [Z]*9, [Z]*6, (Z,Z,Z), Z, Z, Z, b"\xde\xad\xbe\xef"])
print("\n== shieldedSwap ==")
print("  real-root, garbage proof ->", call("0x" + s_data.hex()))

# ---- sweepProtocolFees: who is treasury, does it move money? ----
print("\n== sweepProtocolFees(address(0)) from fresh EOA ==")
print("  ->", call("0x" + (sel("sweepProtocolFees(address)") + abi_encode(["address"], [Z])).hex())[:200])
