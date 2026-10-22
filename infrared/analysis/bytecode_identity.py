#!/usr/bin/env python3
"""Prove the deployed iBERA implementation bytecode IS the verified source.

Method (fully reproducible, no secrets):
  1. take the Etherscan-V2 standard-JSON source bundle for the implementation
  2. recompile with the exact compiler (solc 0.8.26+commit.8a97fa7a), optimizer
     runs=50, evmVersion=cancun
  3. link the BeaconRootsVerify library at the address recorded in the
     verification record
  4. fill the 3 constructor-set `immutable __self` slots with the implementation's
     own address (that is exactly what `address(this)` yields at deploy time)
  5. require byte-for-byte equality with `eth_getCode` of the implementation,
     including the trailing CBOR metadata fingerprint.

Usage: bytecode_identity.py <verified-json> <impl-address> <rpc-url> [<solc-bin>]
"""
import copy, json, os, re, subprocess, sys, urllib.request

def rpc_code(rpc, addr):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_getCode",
                       "params": [addr, "latest"]}).encode()
    req = urllib.request.Request(rpc, data=body, headers={
        "content-type": "application/json", "user-agent": "Mozilla/5.0 (research)"})
    return json.loads(urllib.request.urlopen(req, timeout=60).read())["result"].lower()

def main():
    vjson, impl, rpc = sys.argv[1], sys.argv[2], sys.argv[3]
    solc = sys.argv[4] if len(sys.argv) > 4 else "/tmp/solc-0.8.26"
    out = {}
    d = json.load(open(vjson)); r = d["result"][0]
    sj = json.loads(r["SourceCode"].strip()[1:-1])
    rec = {
        "contract": r["ContractName"],
        "compiler": r["CompilerVersion"],
        "optimizer_runs": r["Runs"],
        "evm_version": r["EVMVersion"],
        "similar_match": r.get("SimilarMatch", ""),
    }
    out["verification_record"] = rec
    libs = sj["settings"].get("libraries", {})
    out["libraries_recorded"] = libs

    # metadata on-chain corresponds to a build where linking happened AFTER
    # compilation (no `libraries` in the compiler settings) -> reproduce that.
    sj2 = copy.deepcopy(sj)
    sj2["settings"].pop("libraries", None)
    p = subprocess.run([solc, "--standard-json"], input=json.dumps(sj2).encode(),
                       capture_output=True)
    comp = json.loads(p.stdout)
    errs = [e for e in comp.get("errors", []) if e.get("severity") == "error"]
    if errs:
        print("COMPILE ERROR:", errs[0].get("formattedMessage", "")[:400]); sys.exit(2)
    key = "src/staking/InfraredBERAV2_1.sol"
    c = comp["contracts"][key]["InfraredBERAV2_1"]
    bc = c["evm"]["deployedBytecode"]["object"].lower()

    onchain = rpc_code(rpc, impl)[2:]
    out["solc_local_bytes"] = len(bc) // 2
    out["onchain_bytes"] = len(onchain) // 2

    # 1. substitute the linker placeholders with the recorded library addresses.
    #    There is a single external library (BeaconRootsVerify) in this build.
    lib_addrs = [v.lower().replace("0x", "")
                 for m in libs.values() for v in m.values()]
    assert len(lib_addrs) == 1, f"unexpected library map: {libs}"
    n_link = 0
    for ph in set(re.findall(r"__\$[0-9a-f]{34}\$__", bc)):
        bc = bc.replace(ph, lib_addrs[0])
        n_link += 1
    out["linker_placeholders_substituted"] = n_link
    out["library_address_used"] = "0x" + lib_addrs[0]
    # 2. fill the constructor-set immutables (PUSH32 <24 zero bytes><20 zero bytes>)
    bc, n_imm = re.subn("7f" + "0" * 64, "7f" + "0" * 24 + impl.lower().replace("0x", ""), bc)
    out["immutables_filled"] = n_imm
    out["immutable_value"] = impl

    m = re.search(r"a2646970667358221220([0-9a-f]{64})", onchain)
    out["onchain_metadata_hash"] = m.group(1) if m else None
    m2 = re.search(r"a2646970667358221220([0-9a-f]{64})", bc)
    out["local_metadata_hash"] = m2.group(1) if m2 else None

    out["byte_exact_match"] = (bc == onchain)
    if not out["byte_exact_match"]:
        diffs = [i for i, (a, b) in enumerate(zip(bc, onchain)) if a != b]
        out["num_differing_hex_chars"] = len(diffs)
        out["first_diffs"] = diffs[:10]
    print(json.dumps(out, indent=2))
    return 0 if out["byte_exact_match"] else 1


if __name__ == "__main__":
    sys.exit(main())
