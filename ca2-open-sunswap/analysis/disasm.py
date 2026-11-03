#!/usr/bin/env python3
"""Minimal EVM/TVM disassembler + selector/JUMPDEST mapper (read-only analysis helper)."""
import sys, json, hashlib

OPS = {
0x00:('STOP',0),0x01:('ADD',0),0x02:('MUL',0),0x03:('SUB',0),0x04:('DIV',0),0x05:('SDIV',0),
0x06:('MOD',0),0x07:('SMOD',0),0x08:('ADDMOD',0),0x09:('MULMOD',0),0x0a:('EXP',0),0x0b:('SIGNEXTEND',0),
0x10:('LT',0),0x11:('GT',0),0x12:('SLT',0),0x13:('SGT',0),0x14:('EQ',0),0x15:('ISZERO',0),
0x16:('AND',0),0x17:('OR',0),0x18:('XOR',0),0x19:('NOT',0),0x1a:('BYTE',0),0x1b:('SHL',0),0x1c:('SHR',0),0x1d:('SAR',0),
0x20:('KECCAK256',0),0x30:('ADDRESS',0),0x31:('BALANCE',0),0x32:('ORIGIN',0),0x33:('CALLER',0),
0x34:('CALLVALUE',0),0x35:('CALLDATALOAD',0),0x36:('CALLDATASIZE',0),0x37:('CALLDATACOPY',0),
0x38:('CODESIZE',0),0x39:('CODECOPY',0),0x3a:('GASPRICE',0),0x3b:('EXTCODESIZE',0),0x3c:('EXTCODECOPY',0),
0x3d:('RETURNDATASIZE',0),0x3e:('RETURNDATACOPY',0),0x3f:('EXTCODEHASH',0),
0x40:('BLOCKHASH',0),0x41:('COINBASE',0),0x42:('TIMESTAMP',0),0x43:('NUMBER',0),0x44:('PREVRANDAO',0),
0x45:('GASLIMIT',0),0x46:('CHAINID',0),0x47:('SELFBALANCE',0),0x48:('BASEFEE',0),
0x50:('POP',0),0x51:('MLOAD',0),0x52:('MSTORE',0),0x53:('MSTORE8',0),0x54:('SLOAD',0),0x55:('SSTORE',0),
0x56:('JUMP',0),0x57:('JUMPI',0),0x58:('PC',0),0x59:('MSIZE',0),0x5a:('GAS',0),0x5b:('JUMPDEST',0),
0x5c:('TLOAD',0),0x5d:('TSTORE',0),0x5e:('MCOPY',0),
0x5f:('PUSH0',0),
0x60:('PUSH1',1),0x61:('PUSH2',2),0x62:('PUSH3',3),0x63:('PUSH4',4),0x64:('PUSH5',5),0x65:('PUSH6',6),
0x66:('PUSH7',7),0x67:('PUSH8',8),0x68:('PUSH9',9),0x69:('PUSH10',10),0x6a:('PUSH11',11),0x6b:('PUSH12',12),
0x6c:('PUSH13',13),0x6d:('PUSH14',14),0x6e:('PUSH15',15),0x6f:('PUSH16',16),0x70:('PUSH17',17),
0x71:('PUSH18',18),0x72:('PUSH19',19),0x73:('PUSH20',20),0x74:('PUSH21',21),0x75:('PUSH22',22),
0x76:('PUSH23',23),0x77:('PUSH24',24),0x78:('PUSH25',25),0x79:('PUSH26',26),0x7a:('PUSH27',27),
0x7b:('PUSH28',28),0x7c:('PUSH29',29),0x7d:('PUSH30',30),0x7e:('PUSH31',31),0x7f:('PUSH32',32),
0x80:('DUP1',0),0x81:('DUP2',0),0x82:('DUP3',0),0x83:('DUP4',0),0x84:('DUP5',0),0x85:('DUP6',0),
0x86:('DUP7',0),0x87:('DUP8',0),0x88:('DUP9',0),0x89:('DUP10',0),0x8a:('DUP11',0),0x8b:('DUP12',0),
0x8c:('DUP13',0),0x8d:('DUP14',0),0x8e:('DUP15',0),0x8f:('DUP16',0),
0x90:('SWAP1',0),0x91:('SWAP2',0),0x92:('SWAP3',0),0x93:('SWAP4',0),0x94:('SWAP5',0),0x95:('SWAP6',0),
0x96:('SWAP7',0),0x97:('SWAP8',0),0x98:('SWAP9',0),0x99:('SWAP10',0),0x9a:('SWAP11',0),0x9b:('SWAP12',0),
0x9c:('SWAP13',0),0x9d:('SWAP14',0),0x9e:('SWAP15',0),0x9f:('SWAP16',0),
0xa0:('LOG0',0),0xa1:('LOG1',0),0xa2:('LOG2',0),0xa3:('LOG3',0),0xa4:('LOG4',0),
0xd0:('TVM_ISCONTRACT',0),0xd1:('TVM_CALLTOKEN',0),0xd2:('TVM_TOKENBALANCE',0),0xd3:('TVM_CALLTOKENVALUE',0),
0xd4:('TVM_CALLTOKENID',0),0xd5:('TVM_ISCONTRACT2',0),
0xf0:('CREATE',0),0xf1:('CALL',0),0xf2:('CALLCODE',0),0xf3:('RETURN',0),0xf4:('DELEGATECALL',0),
0xf5:('CREATE2',0),0xfa:('STATICCALL',0),0xfd:('REVERT',0),0xfe:('INVALID',0),0xff:('SELFDESTRUCT',0),
}

def disasm(code):
    out=[]; i=0; n=len(code)
    while i<n:
        op=code[i]; name,argc=OPS.get(op,(f'UNKNOWN_0x{op:02x}',0))
        if name=='PUSH0': out.append((i,name,None,1)); i+=1; continue
        if 'PUSH' in name:
            v=int.from_bytes(code[i+1:i+1+argc],'big')
            out.append((i,name,v,1+argc)); i+=1+argc; continue
        out.append((i,name,None,1)); i+=1
    return out

def selector_map(code):
    """Find PUSH4 selector / EQ / PUSH2 dest dispatch stubs."""
    ins=disasm(code)
    res={}
    for k,(pc,n,a,s) in enumerate(ins):
        if n=='PUSH4':
            # look ahead up to 3 insns for EQ then PUSH2
            for j in range(k+1,min(k+4,len(ins))):
                if ins[j][1]=='EQ':
                    for m in range(j+1,min(j+3,len(ins))):
                        if ins[m][1]=='PUSH2': res.setdefault(f'0x{a:08x}',[]).append(ins[m][2])
                    break
    return res

if __name__=='__main__':
    code=bytes.fromhex(open(sys.argv[1]).read().strip())
    ins=disasm(code)
    counts={}
    for pc,n,a,s in ins: counts[n]=counts.get(n,0)+1
    print('bytes',len(code),'insns',len(ins))
    for op in ['CALLER','ORIGIN','DELEGATECALL','CALL','STATICCALL','TLOAD','TSTORE','SELFDESTRUCT','SSTORE','SLOAD','CALLVALUE','CREATE','CREATE2','EXTCODEHASH']:
        print(op, counts.get(op,0))
    sm=selector_map(code)
    print('selectors',len(sm))
    if len(sys.argv)>2 and sys.argv[2]=='sel':
        for s,d in sorted(sm.items(), key=lambda x: min(x[1])): print(s, sorted(set(d)))
