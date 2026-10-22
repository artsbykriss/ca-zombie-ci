#!/usr/bin/env python3
"""
Harness positive-control: replay REAL BasicPool inbound messages through the local
TVM emulator and check whether ANY of them changes the pool's storage (data) cell.
READ-ONLY (lite-server reads + local TVM).
"""
import base64, json, time
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount, Transaction

POOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"

def _data(acc):
    if acc is None or not hasattr(acc, "storage"): return None
    stt = acc.storage.state
    if not hasattr(stt, "x"): return None
    d = stt.x.data
    return None if d is None else getattr(d, "value", d)
def data_of_account(c): return _data(Account().cell_unpack(c, rec_unpack=True))
def data_of_shard(c):
    sa = ShardAccount().cell_unpack(c, rec_unpack=True)
    return _data(sa.account if sa is not None else None)

def main():
    lc = LiteClient(mode="roundrobin", timeout=3, num_try=5)
    blk = lc.get_masterchain_info_ext().last; now = lc.get_time()
    st = lc.get_account_state(Address(POOL), blk)
    ss = st.to_shard_state()
    hb = data_of_account(ss.begin_parse().load_ref()).get_hash()
    _, cfgraw = lc.get_config_all(blk)
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)
    print("current pool data hash:", hb, "lt", st.last_trans_lt)

    tl = None
    for attempt in range(5):
        try:
            tl = lc.get_transactions(Address(POOL), st.last_trans_lt, st.last_trans_hash, 30)
            break
        except Exception as e:
            print("get_transactions retry", attempt, repr(e)); time.sleep(1)
    if tl is None:
        print("could not fetch transactions"); return
    print("fetched transactions:", len(tl.transactions))
    changed = 0
    for i, ti in enumerate(tl.transactions):
        tx = Transaction().cell_unpack(ti.transaction, rec_unpack=True)
        inmsg = tx.r1.in_msg
        msgcell = None
        try:
            cs = ti.transaction.begin_parse()
            cs.load_uint(4)      # $0111
            cs.load_uint(256)    # account_addr
            cs.load_uint(64)     # lt
            cs.load_uint(256)    # prev_trans_hash
            cs.load_uint(64)     # prev_trans_lt
            cs.load_uint(32)     # now
            cs.load_uint(15)     # outmsg_cnt
            cs.load_uint(2)      # orig_status
            cs.load_uint(2)      # end_status
            aux = cs.load_ref()
            acs = aux.begin_parse()
            if acs.load_bool():
                msgcell = acs.load_ref()
        except Exception as e:
            print(f"  tx{i} msg-extract ERR {e!r}"); continue
        if msgcell is None:
            continue
        if msgcell is None:
            continue
        # emulate this inbound message against the CURRENT state
        em = Emulator(cfg); em.set_ignore_chksig(True)
        try:
            ok = em.emulate_transaction(ss, msgcell, now, st.last_trans_lt + 1)
        except Exception as e:
            print(f"  tx{i} lt={tx.lt} emu ERR {e!r}")
            continue
        da = data_of_shard(em.account.to_cell())
        ha = da.get_hash() if da is not None else "None"
        ch = ha != hb
        if ch: changed += 1
        print(f"  tx{i} lt={tx.lt} orig_status={tx.orig_status} ok={ok} data_changed={ch} after={ha[:16]}")
    print("REAL-tx storage-changing count:", changed, "/", len(tl.transactions))

if __name__ == "__main__":
    main()
