#!/usr/bin/env python3
"""Patch TVM-only opcodes in a runtime so it can be executed on the EVM.

For TRX-denominated paths, TVM's CALLTOKENID (0xd0? / 0xd3) and CALLTOKENVALUE
(0xd2) semantically push 0 (TRC10 token id 0 / token value 0). Replacing them
with PUSH0 (0x5f) is length-preserving and semantically equivalent for TRX.

Only opcodes at real instruction boundaries are patched (PUSH immediates are
skipped). Writes <name>_runtime_evm.hex + a report.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from disasm import disasm  # noqa: E402

OUT = os.path.dirname(os.path.abspath(__file__))
NAMES = ["CherryPool", "PokerGame", "FireFull"]


def main():
    report = {}
    for name in NAMES:
        code = bytearray(bytes.fromhex(open(f"{OUT}/{name}_runtime.hex").read().strip()))
        ins = disasm(bytes(code))
        counts = {}
        for pc, op, imm, val in ins:
            if op in ("CALLTOKENID", "CALLTOKENVALUE"):
                old = code[pc]
                code[pc] = 0x5F  # PUSH0
                counts[op] = counts.get(op, 0) + 1
        open(f"{OUT}/{name}_runtime_evm.hex", "w").write(code.hex())
        report[name] = {"bytes": len(code), "patched": counts,
                        "sha256": __import__("hashlib").sha256(code).hexdigest()}
        print(name, report[name])
    json.dump(report, open(f"{OUT}/tvm_patch_report.json", "w"), indent=1)


if __name__ == "__main__":
    main()
