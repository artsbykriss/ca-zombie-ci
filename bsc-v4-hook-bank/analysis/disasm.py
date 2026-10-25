#!/usr/bin/env python3
"""Linear EVM disassembler + PUSH4..EQ dispatch extractor.
Reads a hex runtime blob, prints opcodes, and resolves the selector dispatch table.
Usage: disasm.py <hexfile> [--func 0xabcd1234]
"""
import sys, json

PUSH1=0x60
OPNAMES = {
0x00:"STOP",0x01:"ADD",0x02:"MUL",0x03:"SUB",0x04:"DIV",0x05:"SDIV",0x06:"MOD",0x07:"SMOD",
0x08:"ADDMOD",0x09:"MULMOD",0x0a:"EXP",0x0b:"SIGNEXTEND",0x10:"LT",0x11:"GT",0x12:"SLT",0x13:"SGT",
0x14:"EQ",0x15:"ISZERO",0x16:"AND",0x17:"OR",0x18:"XOR",0x19:"NOT",0x1a:"BYTE",0x1b:"SHL",0x1c:"SHR",
0x1d:"SAR",0x20:"KECCAK256",0x30:"ADDRESS",0x31:"BALANCE",0x32:"ORIGIN",0x33:"CALLER",0x34:"CALLVALUE",
0x35:"CALLDATALOAD",0x36:"CALLDATASIZE",0x37:"CALLDATACOPY",0x38:"CODESIZE",0x39:"CODECOPY",0x3a:"GASPRICE",
0x3b:"EXTCODESIZE",0x3c:"EXTCODECOPY",0x3d:"RETURNDATASIZE",0x3e:"RETURNDATACOPY",0x3f:"EXTCODEHASH",
0x40:"BLOCKHASH",0x41:"COINBASE",0x42:"TIMESTAMP",0x43:"NUMBER",0x44:"PREVRANDAO",0x45:"GASLIMIT",
0x46:"CHAINID",0x47:"SELFBALANCE",0x48:"BASEFEE",0x49:"BLOBHASH",0x4a:"BLOBBASEFEE",0x50:"POP",
0x51:"MLOAD",0x52:"MSTORE",0x53:"MSTORE8",0x54:"SLOAD",0x55:"SSTORE",0x56:"JUMP",0x57:"JUMPI",
0x58:"PC",0x59:"MSIZE",0x5a:"GAS",0x5b:"JUMPDEST",0x5e:"MCOPY",0x5f:"PUSH0",0x80:"DUP1",0x81:"DUP2",
0x82:"DUP3",0x83:"DUP4",0x84:"DUP5",0x85:"DUP6",0x86:"DUP7",0x87:"DUP8",0x88:"DUP9",0x89:"DUP10",
0x8a:"DUP11",0x8b:"DUP12",0x8c:"DUP13",0x8d:"DUP14",0x8e:"DUP15",0x8f:"DUP16",0x90:"SWAP1",
0x91:"SWAP2",0x92:"SWAP3",0x93:"SWAP4",0x94:"SWAP5",0x95:"SWAP6",0x96:"SWAP7",0x97:"SWAP8",
0x98:"SWAP9",0x99:"SWAP10",0x9a:"SWAP11",0x9b:"SWAP12",0x9c:"SWAP13",0x9d:"SWAP14",0x9e:"SWAP15",
0x9f:"SWAP16",0xa0:"LOG0",0xa1:"LOG1",0xa2:"LOG2",0xa3:"LOG3",0xa4:"LOG4",0xf0:"CREATE",
0xf1:"CALL",0xf2:"CALLCODE",0xf3:"RETURN",0xf4:"DELEGATECALL",0xf5:"CREATE2",0xfa:"STATICCALL",
0xfd:"REVERT",0xfe:"INVALID",0xff:"SELFDESTRUCT",
}

def load(path):
    h = open(path).read().strip()
    if h.startswith("0x"): h = h[2:]
    return bytes.fromhex(h)

def disasm(code):
    """Return list of (pc, op, imm, size) skipping nothing (linear)."""
    out = []
    i = 0
    n = len(code)
    while i < n:
        op = code[i]
        if PUSH1 <= op <= 0x7f:
            sz = op - PUSH1 + 1
            imm = code[i+1:i+1+sz]
            out.append((i, op, imm, 1+sz))
            i += 1+sz
        else:
            out.append((i, op, b"", 1))
            i += 1
    return out

def fmt(op, imm):
    name = OPNAMES.get(op)
    if name is None:
        if PUSH1 <= op <= 0x7f:
            name = f"PUSH{op-PUSH1+1}"
        elif 0x60 <= op <= 0x7f:
            name = "PUSH"
        else:
            name = f"0x{op:02x}"
    if imm:
        return f"{name} 0x{imm.hex()}"
    return name

def dispatch(code):
    """Find PUSH4 sel EQ PUSH2 dest JUMPI patterns."""
    ins = disasm(code)
    table = {}
    for idx,(pc,op,imm,sz) in enumerate(ins):
        if op == 0x63 and len(imm)==4:  # PUSH4
            # next should be EQ (0x14), then PUSH2 (0x61), then JUMPI(0x57)
            if idx+3 < len(ins):
                o1 = ins[idx+1]; o2 = ins[idx+2]; o3 = ins[idx+3]
                if o1[1]==0x14 and o2[1]==0x61 and o3[1]==0x57:
                    sel = imm.hex()
                    dest = int.from_bytes(o2[2],'big')
                    table[sel] = (pc, dest)
    return table, ins

if __name__ == "__main__":
    path = sys.argv[1]
    code = load(path)
    tbl, ins = dispatch(code)
    print(f"# code size {len(code)} bytes, {len(ins)} instructions, {len(tbl)} dispatch entries")
    for sel,(pc,dest) in sorted(tbl.items(), key=lambda kv: kv[1][1]):
        print(f"0x{sel}  @pc={pc}  -> {dest}")
