#!/usr/bin/env python3
"""Fetch the 0G explorer's verified source, rebuild it with solc 0.8.19 and compare
the runtime bytecode with the deployed code.

Why this exists: chainscan.0g.ai is a JS SPA (no /api/v2, Sourcify returns null), but
the SPA's backend at chainscan-api.0g.ai/v1/contract/<addr> serves the verified source
and compiler settings.  The only expected byte difference is the 20-byte `__self`
immutable (address(this)) which the compiler leaves zeroed in the artifact.
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

API = "https://chainscan-api.0g.ai/v1/contract/"
RPC = os.environ.get("OG_RPC_URL", "https://evmrpc.0g.ai")
BLOCK = os.environ.get("PIN_BLOCK", "47841263")
OUT = os.environ.get("OUT_DIR", "ci-out")

TARGETS = [
    # (label, address, expected contract name)
    ("StakeManager", "0x7a5e1b999a665f2b89e5f6eae32df9471de193c7", "StakeManager"),
    ("StakePool", "0x377db28b688e7fd84bb99a6a8f8f1084a33bb512", "StakePool"),
    ("LsdToken", "0x7bBC63D01CA42491c3E084C941c3E86e55951404", "LsdToken"),
]


def fetch(addr):
    req = urllib.request.Request(API + addr, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)["result"]


def strip_meta(b):
    mlen = int.from_bytes(b[-2:], "big")
    return b[: len(b) - 2 - mlen]


def deployed_code(addr):
    out = subprocess.run(
        ["cast", "code", addr, "--rpc-url", RPC, "--block", BLOCK],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    if out.startswith("0x"):
        out = out[2:]
    return bytes.fromhex(out)


def build(label, source, workdir):
    src_dir = os.path.join(workdir, "src")
    os.makedirs(src_dir, exist_ok=True)
    with open(os.path.join(src_dir, label + ".sol"), "w") as f:
        f.write(source)
    with open(os.path.join(workdir, "foundry.toml"), "w") as f:
        f.write(
            '[profile.default]\nsrc = "src"\nout = "out"\nlibs = []\n'
            'solc = "0.8.19"\noptimizer = true\noptimizer_runs = 200\n'
        )
    env = dict(os.environ)
    env["FOUNDRY_OFFLINE"] = "false"
    subprocess.run(["forge", "build", "--root", workdir], check=True, capture_output=True, env=env)
    art = os.path.join(workdir, "out", label + ".sol", label + ".json")
    with open(art) as f:
        obj = json.load(f)["deployedBytecode"]["object"]
    if obj.startswith("0x"):
        obj = obj[2:]
    return bytes.fromhex(obj)


def main():
    os.makedirs(os.path.join(OUT, "source"), exist_ok=True)
    results = []
    for label, addr, _name in TARGETS:
        print(f"== {label} {addr}")
        info = fetch(addr)
        src = info.get("sourceCode") or ""
        v = info.get("verify") or {}
        open(os.path.join(OUT, "source", label + ".sol"), "w").write(src)
        open(os.path.join(OUT, "source", label + "_abi.json"), "w").write(info.get("abi") or "[]")
        compiler = v.get("version")
        runs = v.get("runs")
        print(f"   verified name={v.get('name')} solc={compiler} runs={runs} exactMatch={v.get('exactMatch')} bytes={len(src)}")
        workdir = os.path.join(OUT, "build_" + label)
        os.makedirs(workdir, exist_ok=True)
        rebuilt = build(label, src, workdir)
        dep = deployed_code(addr)
        a, b = strip_meta(rebuilt), strip_meta(dep)
        self_addr = bytes.fromhex(addr.lower()[2:])
        # mask the immutable __self occurrences
        masked = bytearray(a)
        occurrences = 0
        start = 0
        while True:
            i = b.find(self_addr, start)
            if i < 0:
                break
            if a[i:i + 20] == b"\x00" * 20:
                masked[i:i + 20] = self_addr
                occurrences += 1
            start = i + 1
        equal = bytes(masked) == b
        res = {
            "contract": label,
            "address": addr,
            "explorer_name": v.get("name"),
            "compiler": compiler,
            "optimizer": v.get("optimization"),
            "runs": runs,
            "exact_match_flag": v.get("exactMatch"),
            "source_bytes": len(src),
            "rebuilt_runtime_bytes": len(a),
            "deployed_runtime_bytes": len(b),
            "immutable_self_patches": occurrences,
            "bytecode_identical": equal,
        }
        if not equal:
            diffs = [i for i in range(min(len(a), len(b))) if masked[i] != b[i]]
            res["first_diffs"] = diffs[:10]
            res["n_diffs"] = len(diffs)
        print("   " + json.dumps(res))
        results.append(res)
    with open(os.path.join(OUT, "source_verify.json"), "w") as f:
        json.dump(results, f, indent=2)
    ok = all(r["bytecode_identical"] for r in results)
    print("SOURCE_VERIFY", "OK" if ok else "MISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
