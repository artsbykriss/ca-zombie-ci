#!/usr/bin/env python3
"""Minimal EVM/TVM disassembler with Solidity dispatcher recovery.

Usage: python3 disasm.py <runtime.hex> <out.asm> [--json out.json]

Handles both classic `PUSH1 0 CALLDATALOAD PUSH1 0xe0 SHR` and old
`PUSH1 0 CALLDATALOAD PUSH29 0x010000... DIV` selector extraction, and marks
TVM-only opcodes 0xd0-0xd5. Also emits a selector -> jump-target table by
scanning the standard Solidity dispatcher patterns (PUSH4 sel / EQ / PUSHn dst / JUMPI).
"""
import json
import sys

# --- opcode table (EVM Shanghai/Cancun + TVM extensions) ---
NAMES = {
    0x00: "STOP", 0x01: "ADD", 0x02: "MUL", 0x03: "SUB", 0x04: "DIV", 0x05: "SDIV",
    0x06: "MOD", 0x07: "SMOD", 0x08: "ADDMOD", 0x09: "MULMOD", 0x0A: "EXP", 0x0B: "SIGNEXTEND",
    0x10: "LT", 0x11: "GT", 0x12: "SLT", 0x13: "SGT", 0x14: "EQ", 0x15: "ISZERO", 0x16: "AND",
    0x17: "OR", 0x18: "XOR", 0x19: "NOT", 0x1A: "BYTE", 0x1B: "SHL", 0x1C: "SHR", 0x1D: "SAR",
    0x20: "SHA3", 0x30: "ADDRESS", 0x31: "BALANCE", 0x32: "ORIGIN", 0x33: "CALLER",
    0x34: "CALLVALUE", 0x35: "CALLDATALOAD", 0x36: "CALLDATASIZE", 0x37: "CALLDATACOPY",
    0x38: "CODESIZE", 0x39: "CODECOPY", 0x3A: "GASPRICE", 0x3B: "EXTCODESIZE",
    0x3C: "EXTCODECOPY", 0x3D: "RETURNDATASIZE", 0x3E: "RETURNDATACOPY", 0x3F: "EXTCODEHASH",
    0x40: "BLOCKHASH", 0x41: "COINBASE", 0x42: "TIMESTAMP", 0x43: "NUMBER", 0x44: "DIFFICULTY",
    0x45: "GASLIMIT", 0x46: "CHAINID", 0x47: "SELFBALANCE", 0x48: "BASEFEE", 0x49: "BLOBHASH",
    0x4A: "BLOBBASEFEE",
    0x50: "POP", 0x51: "MLOAD", 0x52: "MSTORE", 0x53: "MSTORE8", 0x54: "SLOAD", 0x55: "SSTORE",
    0x56: "JUMP", 0x57: "JUMPI", 0x58: "PC", 0x59: "MSIZE", 0x5A: "GAS", 0x5B: "JUMPDEST",
    0x5C: "TLOAD", 0x5D: "TSTORE", 0x5E: "MCOPY", 0x5F: "PUSH0",
    0x60: "PUSH1", 0x61: "PUSH2", 0x62: "PUSH3", 0x63: "PUSH4", 0x64: "PUSH5", 0x65: "PUSH6",
    0x66: "PUSH7", 0x67: "PUSH8", 0x68: "PUSH9", 0x69: "PUSH10", 0x6A: "PUSH11", 0x6B: "PUSH12",
    0x6C: "PUSH13", 0x6D: "PUSH14", 0x6E: "PUSH15", 0x6F: "PUSH16", 0x70: "PUSH17", 0x71: "PUSH18",
    0x72: "PUSH19", 0x73: "PUSH20", 0x74: "PUSH21", 0x75: "PUSH22", 0x76: "PUSH23", 0x77: "PUSH24",
    0x78: "PUSH25", 0x79: "PUSH26", 0x7A: "PUSH27", 0x7B: "PUSH28", 0x7C: "PUSH29", 0x7D: "PUSH30",
    0x7E: "PUSH31", 0x7F: "PUSH32",
    0x80: "DUP1", 0x81: "DUP2", 0x82: "DUP3", 0x83: "DUP4", 0x84: "DUP5", 0x85: "DUP6",
    0x86: "DUP7", 0x87: "DUP8", 0x88: "DUP9", 0x89: "DUP10", 0x8A: "DUP11", 0x8B: "DUP12",
    0x8C: "DUP13", 0x8D: "DUP14", 0x8E: "DUP15", 0x8F: "DUP16",
    0x90: "SWAP1", 0x91: "SWAP2", 0x92: "SWAP3", 0x93: "SWAP4", 0x94: "SWAP5", 0x95: "SWAP6",
    0x96: "SWAP7", 0x97: "SWAP8", 0x98: "SWAP9", 0x99: "SWAP10", 0x9A: "SWAP11", 0x9B: "SWAP12",
    0x9C: "SWAP13", 0x9D: "SWAP14", 0x9E: "SWAP15", 0x9F: "SWAP16",
    0xA0: "LOG0", 0xA1: "LOG1", 0xA2: "LOG2", 0xA3: "LOG3", 0xA4: "LOG4",
    0xF0: "CREATE", 0xF1: "CALL", 0xF2: "CALLCODE", 0xF3: "RETURN", 0xF4: "DELEGATECALL",
    0xF5: "CREATE2", 0xFA: "STATICCALL", 0xFD: "REVERT", 0xFE: "INVALID", 0xFF: "SELFDESTRUCT",
    # TVM extensions (java-tron)
    0xD0: "CALLTOKEN", 0xD1: "TOKENBALANCE", 0xD2: "CALLTOKENVALUE", 0xD3: "CALLTOKENID",
    0xD4: "ISCONTRACT", 0xD5: "TVM_D5",
}


def disasm(code):
    n = len(code)
    out = []
    i = 0
    while i < n:
        op = code[i]
        name = NAMES.get(op, f"UNKNOWN_0x{op:02x}")
        if 0x60 <= op <= 0x7F:
            k = op - 0x5F
            imm = code[i + 1:i + 1 + k]
            out.append((i, name, imm.hex(), int.from_bytes(imm, "big") if imm else 0))
            i += 1 + k
        else:
            out.append((i, name, None, None))
            i += 1
    return out


def selector_table(ins):
    """Recover selector -> handler PCs from classic Solidity dispatch idioms."""
    table = {}
    # pattern: PUSH4 <sel> [DUP1] EQ PUSHn <dst> JUMPI
    for idx, (pc, name, imm, val) in enumerate(ins):
        if name == "PUSH4":
            for j in range(idx + 1, min(idx + 5, len(ins))):
                if ins[j][1] == "EQ":
                    for k in range(j + 1, min(j + 3, len(ins))):
                        if ins[k][1].startswith("PUSH") and ins[k][3] is not None:
                            table.setdefault(imm, {"pc": pc, "dst": ins[k][3],
                                                   "dst_op": ins[k][1]})
                    break
    return table


def main():
    src = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else src + ".asm"
    code = bytes.fromhex(open(src).read().strip().replace("0x", ""))
    ins = disasm(code)
    sel = selector_table(ins)
    dsts = {v["dst"] for v in sel.values()}
    with open(out_path, "w") as f:
        f.write(f"; file={src} runtime_bytes={len(code)}\n")
        f.write("; selector table (PUSH4 sel / EQ / PUSHn dst / JUMPI):\n")
        for s, v in sorted(sel.items()):
            f.write(f";   0x{s} -> 0x{v['dst']:04x} (dispatch@{v['pc']:04x})\n")
        f.write("\n")
        for pc, name, imm, val in ins:
            note = ""
            if name.startswith("PUSH") and val in dsts:
                note = "  ; <- handler for selector(s) " + ",".join(
                    "0x" + s for s, v in sel.items() if v["dst"] == val)
            line = f"{pc:05x}: {name}"
            if imm is not None:
                line += f" 0x{imm}"
                if name in ("PUSH1", "PUSH2", "PUSH3", "PUSH4") and val is not None:
                    line += f" ({val})"
            f.write(line + note + "\n")
    meta = {
        "runtime_bytes": len(code),
        "selectors": {s: v for s, v in sel.items()},
        "tvm_opcodes": sorted({name for _, name, _, _ in ins if name.startswith(("CALLTOKEN", "TOKENBALANCE", "ISCONTRACT")) or name == "TVM_D5"}),
        "selfdestruct": sum(1 for _, n, _, _ in ins if n == "SELFDESTRUCT"),
        "delegatecall": sum(1 for _, n, _, _ in ins if n == "DELEGATECALL"),
        "create": sum(1 for _, n, _, _ in ins if n in ("CREATE", "CREATE2")),
    }
    if len(sys.argv) > 3:
        json.dump(meta, open(sys.argv[3], "w"), indent=1)
    print(json.dumps(meta, indent=1))


if __name__ == "__main__":
    main()
