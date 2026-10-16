#!/usr/bin/env python3
"""Verify the deployed AssetVault implementation bytecode == local compile of the
verified source.
Two deployment-specific differences are expected and handled:
  (1) the UUPS `__self` immutable (3 x 32-byte slots) holds the impl's own address;
  (2) the trailing 53-byte CBOR metadata suffix (IPFS source hash) differs between
      builds because it hashes compiler settings/paths, not logic.
After patching (1) and stripping (2), the code must match EXACTLY byte-for-byte.
Writes ci-out/bytecode_verification.json. Keyless."""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

RPC = sys.argv[1] if len(sys.argv) > 1 else "https://arbitrum-one-rpc.publicnode.com"
IMPLS = {
    "v1_impl_0x94a99081": "0x94a99081475d0b5B887c5a03FcD9B81e52C264DE",
    "v2_impl_0xb5d7cfae": "0xB5D7cFae3d89036B0Ca026b46420AB44933323B6",
}
ARTIFACT = os.path.join(ROOT, "poc", "out", "AssetVault.sol", "AssetVault.json")
META_BYTES = 53  # standard CBOR metadata suffix

def sh(*args):
    return subprocess.run(args, capture_output=True, text=True).stdout.strip()

def keccak(b: bytes) -> str:
    return sh("cast", "keccak", "0x" + b.hex())

res = {"impls": {}}

if not os.path.exists(ARTIFACT):
    print("artifact missing; running forge build")
    subprocess.run(["forge", "build"], cwd=os.path.join(ROOT, "poc"), capture_output=True)

art = json.load(open(ARTIFACT))
local = art["deployedBytecode"]["object"]
if local.startswith("0x"):
    local = local[2:]
imm_refs = art["deployedBytecode"].get("immutableReferences", {})
res["local_runtime_len"] = len(local) // 2
res["immutable_slots"] = {k: v for k, v in imm_refs.items()}

for name, addr in IMPLS.items():
    onchain = sh("cast", "code", addr, "--rpc-url", RPC)
    if onchain.startswith("0x"):
        onchain = onchain[2:]
    entry = {"address": addr, "onchain_len": len(onchain) // 2}
    entry["onchain_keccak_full"] = keccak(bytes.fromhex(onchain)) if onchain else None
    entry["onchain_metadata"] = onchain[-META_BYTES * 2:]
    # patch immutables with deployed address
    patched = bytearray.fromhex(local)
    addr_bytes = bytes.fromhex(addr[2:])
    for _unit, slots in imm_refs.items():
        for s in slots:
            patched[s["start"]:s["start"] + s["length"]] = bytes(32 - len(addr_bytes)) + addr_bytes
    p = bytes(patched).hex()
    # strip metadata suffix from both, then compare exactly
    p_nometa, oc_nometa = p[:-META_BYTES * 2], onchain[:-META_BYTES * 2]
    entry["code_without_metadata_keccak"] = keccak(bytes.fromhex(oc_nometa))
    entry["bytecode_match"] = (p_nometa == oc_nometa)
    if len(onchain) == len(local):
        diffs = [i // 2 for i in range(0, len(local), 2) if local[i:i+2] != onchain[i:i+2]]
        entry["diff_bytes_raw"] = len(diffs)
        entry["diff_bytes_explained"] = len(diffs) == (3 * 20) + 32  # 3 addr slots (20 nonzero bytes each) + metadata hash
    res["impls"][name] = entry
    print(name, json.dumps(entry, indent=1))

res["verdict"] = all(v.get("bytecode_match") for v in res["impls"].values())
json.dump(res, open(os.path.join(OUT, "bytecode_verification.json"), "w"), indent=1)
print("VERDICT bytecode_match:", res["verdict"])
