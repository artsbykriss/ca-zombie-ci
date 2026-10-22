#!/usr/bin/env python3
"""Try a handful of compiler-setting variants to reproduce the on-chain metadata
fingerprint of the iBERA implementation (byte-exact source identity proof).

The metadata hash only depends on the metadata JSON (source keccaks + settings),
not on the contract logic, so a match here proves the whole input was identical.
"""
import copy, json, subprocess, sys, re

SOLC = "/tmp/solc-0.8.26"
TARGET = "c031d2f45be36020e3cec9d2d8e46dc215d787607908dfd0c0b0dd211fe8d2bc"
base = json.loads(open("/tmp/stdinput.json").read())


def run(sj):
    p = subprocess.run([SOLC, "--standard-json"], input=json.dumps(sj).encode(),
                       capture_output=True)
    try:
        out = json.loads(p.stdout)
    except Exception:
        return None, "solc output parse failed: " + p.stderr.decode()[:200]
    errs = [e for e in out.get("errors", []) if e.get("severity") == "error"]
    if errs:
        return None, errs[0].get("formattedMessage", "")[:200]
    c = out["contracts"]["src/staking/InfraredBERAV2_1.sol"]["InfraredBERAV2_1"]
    bc = c["evm"]["deployedBytecode"]["object"]
    m = re.search(r"a2646970667358221220([0-9a-f]{64})", bc)
    return (m.group(1) if m else None), None


variants = {}
variants["baseline"] = base
v = copy.deepcopy(base); del v["settings"]["libraries"]; variants["no_libraries"] = v
v = copy.deepcopy(base); v["settings"]["outputSelection"] = {"*": {"*": ["evm.bytecode", "evm.deployedBytecode"]}}
variants["min_outputSelection"] = v
v = copy.deepcopy(base)
v["settings"]["outputSelection"] = {"*": {"*": ["evm.bytecode", "evm.deployedBytecode", "abi"]}}
variants["outputSelection_no_devdoc"] = v
v = copy.deepcopy(base); del v["settings"]["optimizer"]["details"]; variants["no_optimizer_details"] = v
v = copy.deepcopy(base); v["settings"]["metadata"]["useLiteralContent"] = True
variants["literal_content"] = v
v = copy.deepcopy(base); v["settings"]["remappings"] = []; variants["no_remappings"] = v

for name, sj in variants.items():
    h, err = run(sj)
    print(f"{name:26s} {h or 'ERR'} {'MATCH' if h == TARGET else ''} {err or ''}")
