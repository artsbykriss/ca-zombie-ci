#!/usr/bin/env python3
"""Decode SCVal helpers: addresses, maps, i128/u128/u256."""
import sys
from stellar_sdk import xdr, Address, StrKey

def sval_str(v):
    t = v.type
    if t == xdr.SCValType.SCV_ADDRESS:
        return Address.from_xdr_sc_address(v.address).address
    if t == xdr.SCValType.SCV_U32: return v.u32.uint32
    if t == xdr.SCValType.SCV_I32: return v.i32.int32
    if t == xdr.SCValType.SCV_U64: return v.u64.uint64
    if t == xdr.SCValType.SCV_I64: return v.i64.int64
    if t == xdr.SCValType.SCV_BOOL: return v.b
    if t == xdr.SCValType.SCV_SYMBOL: return v.sym.sc_symbol.decode()
    if t == xdr.SCValType.SCV_BYTES: return bytes(v.bytes.sc_bytes).hex()
    if t == xdr.SCValType.SCV_U128:
        return (v.u128.hi.uint64 << 64) + v.u128.lo.uint64
    if t == xdr.SCValType.SCV_I128:
        return (v.i128.hi.int64 << 64) + v.i128.lo.uint64
    if t == xdr.SCValType.SCV_U256:
        u = v.u256
        return (u.hi_hi.uint64 << 192) | (u.hi_lo.uint64 << 128) | (u.lo_hi.uint64 << 64) | u.lo_lo.uint64
    if t == xdr.SCValType.SCV_MAP:
        return {sval_str(m.key): sval_str(m.val) for m in v.map.sc_map}
    if t == xdr.SCValType.SCV_VEC:
        return [sval_str(x) for x in v.vec.sc_vec]
    return str(v)

def py(v):
    return sval_str(v)
