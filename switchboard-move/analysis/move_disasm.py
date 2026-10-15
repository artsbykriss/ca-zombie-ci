#!/usr/bin/env python3
"""Move bytecode (Aptos v9) targeted disassembler for function bodies.
Read-only analysis of on-chain module bytecode."""
import json, sys

# opcode -> (name, operand spec) ; spec: list of 'uleb'|'u8'|'u64'|'u128'|'u16'|'u32'|'u256'|'i8'|'i16'|'i32'|'i64'|'i128'|'i256'|'closure'
OPS = {
 0x01:('Pop',[]),0x02:('Ret',[]),0x03:('BrTrue',['uleb']),0x04:('BrFalse',['uleb']),0x05:('Branch',['uleb']),
 0x06:('LdU64',['u64']),0x07:('LdConst',['uleb']),0x08:('LdTrue',[]),0x09:('LdFalse',[]),
 0x0A:('CopyLoc',['uleb']),0x0B:('MoveLoc',['uleb']),0x0C:('StLoc',['uleb']),0x0D:('MutBorrowLoc',['uleb']),
 0x0E:('ImmBorrowLoc',['uleb']),0x0F:('MutBorrowField',['uleb']),0x10:('ImmBorrowField',['uleb']),
 0x11:('Call',['uleb']),0x12:('Pack',['uleb']),0x13:('Unpack',['uleb']),0x14:('ReadRef',[]),0x15:('WriteRef',[]),
 0x16:('Add',[]),0x17:('Sub',[]),0x18:('Mul',[]),0x19:('Mod',[]),0x1A:('Div',[]),0x1B:('BitOr',[]),0x1C:('BitAnd',[]),
 0x1D:('Xor',[]),0x1E:('Or',[]),0x1F:('And',[]),0x20:('Not',[]),0x21:('Eq',[]),0x22:('Neq',[]),0x23:('Lt',[]),
 0x24:('Gt',[]),0x25:('Le',[]),0x26:('Ge',[]),0x27:('Abort',[]),0x28:('Nop',[]),0x29:('Exists',['uleb']),
 0x2A:('MutBorrowGlobal',['uleb']),0x2B:('ImmBorrowGlobal',['uleb']),0x2C:('MoveFrom',['uleb']),0x2D:('MoveTo',['uleb']),
 0x2E:('FreezeRef',[]),0x2F:('Shl',[]),0x30:('Shr',[]),0x31:('LdU8',['u8']),0x32:('LdU128',['u128']),
 0x33:('CastU8',[]),0x34:('CastU64',[]),0x35:('CastU128',[]),0x36:('MutBorrowFieldGeneric',['uleb']),
 0x37:('ImmBorrowFieldGeneric',['uleb']),0x38:('CallGeneric',['uleb']),0x39:('PackGeneric',['uleb']),
 0x3A:('UnpackGeneric',['uleb']),0x3B:('ExistsGeneric',['uleb']),0x3C:('MutBorrowGlobalGeneric',['uleb']),
 0x3D:('ImmBorrowGlobalGeneric',['uleb']),0x3E:('MoveFromGeneric',['uleb']),0x3F:('MoveToGeneric',['uleb']),
 0x40:('VecPack',['uleb','u64']),0x41:('VecLen',['uleb']),0x42:('VecImmBorrow',['uleb']),0x43:('VecMutBorrow',['uleb']),
 0x44:('VecPushBack',['uleb']),0x45:('VecPopBack',['uleb']),0x46:('VecUnpack',['uleb','u64']),0x47:('VecSwap',['uleb']),
 0x48:('LdU16',['u16']),0x49:('LdU32',['u32']),0x4A:('LdU256',['u256']),0x4B:('CastU16',[]),0x4C:('CastU32',[]),
 0x4D:('CastU256',[]),0x4E:('ImmBorrowVariantField',['uleb']),0x4F:('MutBorrowVariantField',['uleb']),
 0x50:('ImmBorrowVariantFieldGeneric',['uleb']),0x51:('MutBorrowVariantFieldGeneric',['uleb']),
 0x52:('PackVariant',['uleb']),0x53:('PackVariantGeneric',['uleb']),0x54:('UnpackVariant',['uleb']),
 0x55:('UnpackVariantGeneric',['uleb']),0x56:('TestVariant',['uleb']),0x57:('TestVariantGeneric',['uleb']),
 0x58:('PackClosure',['uleb','closure']),0x59:('PackClosureGeneric',['uleb','closure']),0x5A:('CallClosure',['uleb']),
 0x5B:('LdI8',['i8']),0x5C:('LdI16',['i16']),0x5D:('LdI32',['i32']),0x5E:('LdI64',['i64']),0x5F:('LdI128',['i128']),
 0x60:('LdI256',['i256']),0x61:('CastI8',[]),0x62:('CastI16',[]),0x63:('CastI32',[]),0x64:('CastI64',[]),
 0x65:('CastI128',[]),0x66:('CastI256',[]),0x67:('Negate',[]),0x68:('AbortMsg',[]),
}
SIZES = {'u8':1,'u16':2,'u32':4,'u64':8,'u128':16,'u256':32,'i8':1,'i16':2,'i32':4,'i64':8,'i128':16,'i256':32}
TBL = {0x1:'MODULE_HANDLES',0x2:'STRUCT_HANDLES',0x3:'FUNCTION_HANDLES',0x4:'FUNCTION_INST',0x5:'SIGNATURES',
 0x6:'CONSTANT_POOL',0x7:'IDENTIFIERS',0x8:'ADDRESS_IDENTIFIERS',0xA:'STRUCT_DEFS',0xB:'STRUCT_DEF_INST',
 0xC:'FUNCTION_DEFS',0xD:'FIELD_HANDLES',0xE:'FIELD_INST',0xF:'FRIEND_DECLS',0x10:'METADATA',
 0x11:'VARIANT_FIELD_HANDLES',0x12:'VARIANT_FIELD_INST',0x13:'STRUCT_VARIANT_HANDLES',0x14:'STRUCT_VARIANT_INST'}

def uleb(data,pos):
    r=0;s=0
    while True:
        b=data[pos];pos+=1;r|=(b&0x7f)<<s
        if not (b&0x80):break
        s+=7
    return r,pos

def parse_tables(data):
    ver=int.from_bytes(data[4:8],'little') & ~0x0A000000
    pos=8
    tc,pos=uleb(data,pos)
    hdrs=[]
    for _ in range(tc):
        kind=data[pos];pos+=1
        off,pos=uleb(data,pos); cnt,pos=uleb(data,pos)
        hdrs.append((kind,off,cnt))
    content=pos
    tables={TBL.get(k,f'K{k}'):(content+o,c) for k,o,c in hdrs}
    return ver, tables

def parse_common(data,tables):
    out={}
    s,n=tables['IDENTIFIERS']; p=s; ids=[]
    while p<s+n:
        l,p=uleb(data,p); ids.append(data[p:p+l].decode('utf-8','replace')); p+=l
    out['identifiers']=ids
    s,n=tables['MODULE_HANDLES']; p=s; mh=[]
    while p<s+n:
        a,p=uleb(data,p); nm,p=uleb(data,p); mh.append((a,nm))
    out['module_handles']=mh
    s,n=tables['ADDRESS_IDENTIFIERS']; out['addresses']=['0x'+data[s+i*16:s+(i+1)*16].hex() for i in range(n//16)]
    return out

def _read_option(data,p):
    # SerializedOption: NONE=0x1, SOME=0x2
    flag=data[p]; p+=1
    if flag not in (1,2): raise ValueError(f'bad option byte {flag:#x}')
    return flag==2, p

def _skip_access_specifiers(data,p):
    has,p=_read_option(data,p)
    if not has: return p
    count,p=uleb(data,p)
    for _ in range(count):
        kind=data[p]; p+=1          # 1=READ,2=WRITE,3=ACQUIRES
        negated=data[p]; p+=1
        rs=data[p]; p+=1            # resource specifier kind
        if rs==2: _,p=uleb(data,p)              # AT_ADDRESS
        elif rs==3: _,p=uleb(data,p)            # IN_MODULE
        elif rs==4: _,p=uleb(data,p)            # RESOURCE
        elif rs==5: _,p=uleb(data,p); _,p=uleb(data,p)  # RESOURCE_INSTANTIATION
        # rs==1 (ANY): no operands
        aspec=data[p]; p+=1         # address specifier kind
        if aspec==2: _,p=uleb(data,p)           # LITERAL
        elif aspec==3:                          # PARAMETER
            _,p=uleb(data,p)
            has2,p=_read_option(data,p)
            if has2: _,p=uleb(data,p)
    return p

def _skip_attributes(data,p):
    count,p=uleb(data,p)
    for _ in range(count):
        kind=data[p]; p+=1
        if kind in (4,6): _,p=uleb(data,p)   # PACK_VARIANT / UNPACK_VARIANT: function handle index
        elif kind in (8,9): _,p=uleb(data,p) # BORROW_FIELD_*: field handle index
        # 1,2,3,5,7 carry no operands
    return p

def parse_function_handles(data,tables,common):
    """v9 FunctionHandle: module, name, params, ret, type_params(count u8+ability), accesses(option), attributes(count)."""
    s,n=tables['FUNCTION_HANDLES']; p=s; end=s+n; fhs=[]
    while p<end:
        mod,p=uleb(data,p); name,p=uleb(data,p); par,p=uleb(data,p); ret,p=uleb(data,p)
        tpc,p=uleb(data,p)
        for _ in range(tpc):
            _,p=uleb(data,p)  # type param ability set (uleb128)
        p=_skip_access_specifiers(data,p)
        p=_skip_attributes(data,p)
        fhs.append((mod,name))
    if p!=end: raise ValueError(f'function handles parse did not consume table ({p} vs {end})')
    return fhs

def parse_function_defs(data,tables,common,fhs):
    s,n=tables['FUNCTION_DEFS']; p=s; end=s+n; defs=[]
    while p<end:
        fh,p=uleb(data,p)
        vis=data[p]; p+=1
        extra=data[p]; p+=1          # bit0x04=entry, bit0x02=native
        acq,p=uleb(data,p); p+=acq
        code=None
        if not (extra & 0x02):       # not native -> code unit present
            locsig,p=uleb(data,p)
            cnt,p=uleb(data,p)
            ops=[]
            for _ in range(cnt):
                op=data[p]; p+=1
                if op not in OPS: raise ValueError(f'unknown opcode {op:#x} at {p-1}')
                name,specs=OPS[op]
                operands=[]
                for sp in specs:
                    if sp=='uleb': v,p=uleb(data,p); operands.append(v)
                    elif sp=='closure':
                        raise ValueError('closure unsupported')
                    else:
                        sz=SIZES[sp]; v=int.from_bytes(data[p:p+sz],'little',signed=sp.startswith('i')); p+=sz
                        operands.append(v)
                ops.append((name,operands))
            code=(locsig,ops)
        defs.append((fh,vis,extra&0x04!=0,code))
    if p!=end: raise ValueError(f'function defs parse did not consume table ({p} vs {end})')
    return defs

def fh_name(fhs,common,idx):
    if idx>=len(fhs): return f'fh#{idx}'
    mod,name=fhs[idx]
    addr=common['addresses'][common['module_handles'][mod][0]] if mod<len(common['module_handles']) else '?'
    mname=common['identifiers'][common['module_handles'][mod][1]] if mod<len(common['module_handles']) else '?'
    return f'{mname}::{common["identifiers"][name]}'

def disassemble(path, func_names=None):
    d=json.load(open(path)); data=bytes.fromhex(d['bytecode'][2:])
    ver,tables=parse_tables(data); common=parse_common(data,tables)
    fhs=parse_function_handles(data,tables,common)
    defs=parse_function_defs(data,tables,common,fhs)
    print(f'module bytecode v{ver}; {len(defs)} functions; {len(fhs)} function handles')
    for i,(fh,vis,entry,code) in enumerate(defs):
        nm=fh_name(fhs,common,fh)
        if func_names and nm not in func_names: continue
        print(f'--- fun {nm} (vis={vis} entry={entry}) ---')
        if not code: print('   (no code)'); continue
        locsig,ops=code
        for j,(op,args) in enumerate(ops):
            if op in ('Call','CallGeneric') and args:
                extra=f'   # -> {fh_name(fhs,common,args[0])}'
            else: extra=''
            print(f'   {j:4d}: {op} {args}{extra}')

if __name__=='__main__':
    disassemble(sys.argv[1], sys.argv[2:] or None)
