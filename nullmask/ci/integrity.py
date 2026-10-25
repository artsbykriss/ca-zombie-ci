#!/usr/bin/env python3
"""Source <-> deployed-bytecode integrity check for the Nullmask Base implementation.

READ-ONLY. Compiles the VERIFIED source (bundled locally under analysis/src/impl, as pulled
from Etherscan V2) with the recorded settings (solc 0.8.28, optimizer runs=0, cancun) via
`forge build`, and compares the resulting runtime bytecode with the live code at the ERC-1967
implementation slot. Immutable slots (VIRTUAL_CHAIN_ID, UNISWAP_V2_ROUTER) are zeroed on the
on-chain copy before comparison because they are patched in at construction time.

Writes ci-out/integrity.json. No secrets; no network needed for the source.
"""
import json, os, shutil, subprocess, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
BASE_RPC = os.environ.get("BASE_RPC_URL") or "https://base-rpc.publicnode.com"
PROXY = "0xd64EF1417EB047ed0b54736a5a41F01178C391c6"
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
OUT = os.path.join(ROOT, "ci-out")
WORK = "/tmp/nullmask-verified"
os.makedirs(OUT, exist_ok=True)


def rpc(method, params):
    req = urllib.request.Request(
        BASE_RPC,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "nullmask-research"},
    )
    return json.loads(urllib.request.urlopen(req, timeout=60).read()).get("result")


def strip_metadata(code_hex):
    """Remove the trailing Solidity CBOR metadata (last 2 bytes = CBOR length)."""
    b = bytes.fromhex(code_hex)
    if len(b) < 2:
        return b
    meta_len = int.from_bytes(b[-2:], "big")
    if meta_len + 2 > len(b):
        return b
    return b[: len(b) - meta_len - 2]


def main():
    res = {"proxy": PROXY, "impl": None, "compiled": False, "match": None, "notes": []}
    impl = "0x" + int(rpc("eth_getStorageAt", [PROXY, IMPL_SLOT, "latest"]), 16).to_bytes(20, "big").hex()
    res["impl"] = impl
    onchain = rpc("eth_getCode", [impl, "latest"])[2:].lower()
    res["onchain_code_bytes"] = len(onchain) // 2

    src_tree = os.path.join(ROOT, "analysis", "src", "impl")
    if not os.path.isdir(src_tree):
        res["notes"].append(f"verified source tree not found at {src_tree}")
    else:
        if os.path.isdir(WORK):
            shutil.rmtree(WORK)
        os.makedirs(os.path.join(WORK, "src"))
        for sub in ("npm", "project"):
            shutil.copytree(os.path.join(src_tree, sub), os.path.join(WORK, "src", sub))
        open(os.path.join(WORK, "foundry.toml"), "w").write(
            '[profile.default]\n'
            'src = "src"\nout = "out"\nsolc = "0.8.28"\n'
            'optimizer = true\noptimizer_runs = 0\nevm_version = "cancun"\n'
            'remappings = [\n'
            '  "@openzeppelin/contracts/=src/npm/@openzeppelin/contracts@5.4.0/",\n'
            '  "poseidon2-lib/=src/npm/poseidon2-lib@0.0.0/",\n'
            '  "@zk-kit/lean-imt.sol/=src/npm/@zk-kit/lean-imt.sol@2.0.1/"\n'
            ']\n'
        )
        try:
            subprocess.run(["forge", "build"], cwd=WORK, check=True, capture_output=True, timeout=1800)
            art = json.load(open(os.path.join(WORK, "out", "Nullmask.sol", "Nullmask.json")))
            compiled = art["deployedBytecode"]["object"][2:].lower()
            res["compiled"] = True
            res["compiled_code_bytes"] = len(compiled) // 2
            masked = onchain
            for val, nm in ((43618, "VIRTUAL_CHAIN_ID"),
                            (int("be6d8f0d05cc4be24d5167a3ef062215be6d18a5", 16), "UNISWAP_V2_ROUTER")):
                pat = val.to_bytes(32, "big").hex()
                if pat in masked:
                    masked = masked.replace(pat, "00" * 32)
                    res["notes"].append(f"masked immutable {nm}")
            res["match"] = masked == compiled
            res["match_no_metadata"] = strip_metadata(masked) == strip_metadata(compiled)
            res["onchain_code_no_meta_bytes"] = len(strip_metadata(masked))
            res["compiled_code_no_meta_bytes"] = len(strip_metadata(compiled))
            if not res["match"]:
                a, b = strip_metadata(masked), strip_metadata(compiled)
                res["notes"].append(f"{sum(1 for x, y in zip(a, b) if x != y)} differing bytes in code (metadata stripped)")
            if not res["match_no_metadata"]:
                res["notes"].append("code differs after stripping metadata")
        except Exception as e:  # noqa: BLE001
            res["notes"].append(f"compile failed: {e}")

    with open(os.path.join(OUT, "integrity.json"), "w") as f:
        json.dump(res, f, indent=2)
    print(json.dumps(res, indent=2))


if __name__ == "__main__":
    main()
