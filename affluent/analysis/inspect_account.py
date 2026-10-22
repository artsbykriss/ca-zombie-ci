#!/usr/bin/env python3
"""Inspect tonpy parsing of the pool Account -> data cell. READ-ONLY."""
import base64
from tonpy.types import LiteClient, Address, Cell
from tonpy.autogen.block import Account

POOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"

lc = LiteClient(mode="roundrobin", timeout=3, num_try=5)
blk = lc.get_masterchain_info_ext().last
st = lc.get_account_state(Address(POOL), blk)
ss = st.to_shard_state()
acct_cell = ss.begin_parse().load_ref()
acc = Account().cell_unpack(acct_cell, rec_unpack=True)
print("account type:", type(acc))
print("addr:", acc.addr)
storage = acc.storage
print("storage type:", type(storage), "last_trans_lt:", storage.last_trans_lt)
ast = storage.state
print("state type:", type(ast))
si = ast.x
print("stateinit type:", type(si))
print("data type:", type(si.data))
d = si.data
print("data attrs:", [a for a in dir(d) if not a.startswith('_')])
# try to get the underlying cell
for attr in ("value","cell","ref","ref_","data","x"):
    if hasattr(d, attr):
        print("  data.%s = %r" % (attr, getattr(d, attr)))
code = si.code
print("code type:", type(code))
print("code attrs:", [a for a in dir(code) if not a.startswith('_')])
