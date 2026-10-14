#!/usr/bin/env python3
"""Minimal EVM disassembler to inspect the deployed factory's pairCodeHash function."""
import sys, json
sys.path.insert(0, ".")
from rpc import block_number, code, _post, RPCS, as_addr
import time

FACTORY = "0x9ad32bf5dafe152cbe027398219611db4e8753b3"

PUSH = {0x60 + i: i + 1 for i in range(32)}


def disasm(code_bytes, start, end):
    i = start
    out = []
    while i < end and i < len(code_bytes):
        op = code_bytes[i]
        if op in PUSH:
            n = PUSH[op]
            imm = code_bytes[i + 1:i + 1 + n].hex()
            out.append((i, f"PUSH{n} 0x{imm}"))
            i += 1 + n
        elif op == 0x5b:
            out.append((i, "JUMPDEST"))
            i += 1
        else:
            names = {0x00: "STOP", 0x01: "ADD", 0x02: "MUL", 0x03: "SUB", 0x04: "DIV", 0x05: "SDIV", 0x06: "MOD",
                     0x10: "LT", 0x11: "GT", 0x14: "EQ", 0x15: "ISZERO", 0x16: "AND", 0x17: "OR", 0x18: "XOR",
                     0x19: "NOT", 0x1b: "SHL", 0x1c: "SHR", 0x20: "SHA3", 0x30: "ADDRESS", 0x31: "BALANCE",
                     0x32: "ORIGIN", 0x33: "CALLER", 0x34: "CALLVALUE", 0x35: "CALLDATALOAD", 0x36: "CALLDATASIZE",
                     0x37: "CALLDATACOPY", 0x38: "CODESIZE", 0x39: "CODECOPY", 0x3a: "GASPRICE", 0x3b: "EXTCODESIZE",
                     0x3c: "EXTCODECOPY", 0x3d: "RETURNDATASIZE", 0x3e: "RETURNDATACOPY", 0x3f: "EXTCODEHASH",
                     0x40: "BLOCKHASH", 0x41: "COINBASE", 0x42: "TIMESTAMP", 0x43: "NUMBER", 0x44: "DIFFICULTY",
                     0x45: "GASLIMIT", 0x46: "CHAINID", 0x47: "SELFBALANCE", 0x50: "POP", 0x51: "MLOAD",
                     0x52: "MSTORE", 0x53: "MSTORE8", 0x54: "SLOAD", 0x55: "SSTORE", 0x56: "JUMP", 0x57: "JUMPI",
                     0x58: "PC", 0x59: "MSIZE", 0x5a: "GAS", 0x80: "DUP1", 0x81: "DUP2", 0x82: "DUP3", 0x83: "DUP4",
                     0x84: "DUP5", 0x85: "DUP6", 0x86: "DUP7", 0x87: "DUP8", 0x88: "DUP9", 0x89: "DUP10",
                     0x90: "SWAP1", 0x91: "SWAP2", 0x92: "SWAP3", 0x93: "SWAP4", 0x94: "SWAP5", 0x95: "SWAP6",
                     0xa0: "LOG0", 0xa1: "LOG1", 0xa2: "LOG2", 0xa3: "LOG3", 0xa4: "LOG4", 0xf0: "CREATE",
                     0xf1: "CALL", 0xf2: "CALLCODE", 0xf3: "RETURN", 0xf4: "DELEGATECALL", 0xf5: "CREATE2",
                     0xfa: "STATICCALL", 0xfd: "REVERT", 0xfe: "INVALID", 0xff: "SELFDESTRUCT"}
            out.append((i, names.get(op, f"0x{op:02x}")))
            i += 1
    return out


def main():
    bn = block_number()
    fc = bytes.fromhex(code(FACTORY, bn)[2:])
    sel = bytes.fromhex("9aab9248")
    pos = fc.find(sel)
    print("selector 9aab9248 at:", pos)
    if pos >= 0:
        start = max(0, pos - 60)
        for off, txt in disasm(fc, start, pos + 220):
            print(f"{off:6d}: {txt}")
    # also find create2 opcode sites
    sites = [i for i, b in enumerate(fc) if b == 0xf5]
    print("CREATE2 opcode sites:", sites)


if __name__ == "__main__":
    main()
