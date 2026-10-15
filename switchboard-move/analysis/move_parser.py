#!/usr/bin/env python3
"""Minimal Move bytecode (Aptos, v9) table parser: extracts identifier pool,
module handles, address identifiers. Read-only analysis of on-chain bytecode."""
import json, sys, re

def uleb(data, pos):
    result = 0; shift = 0
    while True:
        b = data[pos]; pos += 1
        result |= (b & 0x7f) << shift
        if not (b & 0x80):
            break
        shift += 7
    return result, pos

TABLE_NAMES = {0x1:'MODULE_HANDLES',0x2:'STRUCT_HANDLES',0x3:'FUNCTION_HANDLES',0x4:'FUNCTION_INST',
 0x5:'SIGNATURES',0x6:'CONSTANT_POOL',0x7:'IDENTIFIERS',0x8:'ADDRESS_IDENTIFIERS',0xA:'STRUCT_DEFS',
 0xB:'STRUCT_DEF_INST',0xC:'FUNCTION_DEFS',0xD:'FIELD_HANDLES',0xE:'FIELD_INST',0xF:'FRIEND_DECLS',
 0x10:'METADATA',0x11:'VARIANT_FIELD_HANDLES',0x12:'VARIANT_FIELD_INST',0x13:'STRUCT_VARIANT_HANDLES',
 0x14:'STRUCT_VARIANT_INST'}

def parse(data):
    magic = data[:4]
    assert magic == bytes([0xA1,0x1C,0xEB,0x0B]), "bad magic"
    version = int.from_bytes(data[4:8], 'little') & ~0x0A000000
    pos = 8
    table_count, pos = uleb(data, pos)
    headers = []
    for _ in range(table_count):
        kind = data[pos]; pos += 1
        off, pos = uleb(data, pos)
        cnt, pos = uleb(data, pos)
        headers.append((kind, off, cnt))
    content_start = pos
    tables = {}
    for kind, off, cnt in headers:
        # NOTE: `cnt` is the BYTE LENGTH of the table data (verified via contiguous tiling)
        tables[TABLE_NAMES.get(kind, f'KIND_{kind}')] = (content_start + off, cnt)
    out = {'version': version, 'tables': {k: {'start': v[0], 'bytes': v[1]} for k, v in tables.items()}}
    # identifiers
    if 'IDENTIFIERS' in tables:
        start, nbytes = tables['IDENTIFIERS']
        end = start + nbytes
        p = start; idents = []
        while p < end:
            size, p = uleb(data, p)
            idents.append(data[p:p+size].decode('utf-8', 'replace')); p += size
        out['identifiers'] = idents
    # module handles
    if 'MODULE_HANDLES' in tables:
        start, nbytes = tables['MODULE_HANDLES']
        end = start + nbytes
        p = start; mh = []
        while p < end:
            a, p = uleb(data, p)
            n, p = uleb(data, p)
            mh.append((a, n))
        out['module_handles_idx'] = mh
    # address identifiers (16 bytes each)
    if 'ADDRESS_IDENTIFIERS' in tables:
        start, nbytes = tables['ADDRESS_IDENTIFIERS']
        addrs = []
        for i in range(nbytes // 16):
            addrs.append('0x' + data[start+i*16:start+(i+1)*16].hex())
        out['addresses'] = addrs
    # resolve module handles to (address, name)
    if 'identifiers' in out and 'module_handles_idx' in out:
        resolved = []
        for a, n in out['module_handles_idx']:
            addr = out.get('addresses', [])
            resolved.append({'address': addr[a] if a < len(addr) else f'#{a}',
                             'name': out['identifiers'][n] if n < len(out['identifiers']) else f'#{n}'})
        out['module_handles'] = resolved
    return out

if __name__ == "__main__":
    path = sys.argv[1]
    d = json.load(open(path))
    data = bytes.fromhex(d['bytecode'][2:])
    info = parse(data)
    print('version:', info['version'])
    print('tables:', json.dumps(info['tables']))
    print('addresses:', info.get('addresses'))
    print('module handles:')
    for m in info.get('module_handles', []):
        print('   ', m['address'][:20], '::', m['name'])
    print('identifiers (%d):' % len(info.get('identifiers', [])))
    print('   ', ', '.join(info.get('identifiers', [])))
