#!/usr/bin/env python3
"""Probe tonpy LiteClient connectivity + fetch Affluent BasicPool account state.
READ-ONLY: lite-server queries only. No secrets."""
import sys, json, time
from tonpy.types import LiteClient, Address, Cell

POOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"

def main():
    lc = LiteClient(mode="roundrobin", timeout=3, num_try=5, loglevel=0)
    print("connected:", lc.get_connected())
    t = lc.get_time()
    print("lite time:", t, time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(t)))
    mc = lc.get_masterchain_info_ext()
    blk = mc.last
    print("last mc block:", blk.id.workchain, blk.id.shard, blk.id.seqno)
    st = lc.get_account_state(Address(POOL), blk)
    print("last_trans_lt:", st.last_trans_lt, "last_trans_hash:", st.last_trans_hash)
    sa = st.to_shard_state()
    print("shard_state hash:", sa.get_hash())
    open("/tmp/opencode/aff/pool_shard_state.boc","wb").write(sa.to_boc())
    acct = st.get_parsed()
    print("account parsed ok")
    # config
    blkid2, cfg = lc.get_config_all(blk)
    print("config vm dict size:", len(cfg.get_cell().to_boc()) if hasattr(cfg,'get_cell') else '?')
    open("/tmp/opencode/aff/config.boc","wb").write(cfg.get_cell().to_boc() if hasattr(cfg,'get_cell') else cfg.to_boc())
    print("OK")

if __name__ == "__main__":
    main()
