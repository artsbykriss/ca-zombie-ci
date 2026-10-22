#!/usr/bin/env python3
"""
Vault positive control + op discovery: replay REAL LendingVault inbound messages
through the local TVM emulator, report storage change and the in-msg opcode.
READ-ONLY (lite reads + local TVM).
"""
import sys, time
from tonpy.types import LiteClient, Address, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

TARGETS = {
    "LV_factorialTON":  "EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN",
    "LV_factorialUSDT": "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW",
}
NAMES = {0x7362d09c:"jetton_notify",0x0f8a7ea5:"jetton_transfer",0x178d4519:"jetton_internal_transfer",
         0xb0c69ffe:"provide_aggregated_data",0xab7bef17:"take_aggregated_data_deposit",
         0xd9cf8c91:"take_aggregated_data_withdraw",0xcb03bfaf:"withdraw_payload",0xf9471134:"deposit_payload",
         0xd53276db:"excess",0x7bdd97de:"burn_notification"}

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

def retry(fn, n=8):
    last=None
    for _ in range(n):
        try: return fn()
        except Exception as e: last=e; time.sleep(1.5)
    raise last

def in_msg_cell(txcell):
    cs = txcell.begin_parse()
    cs.load_uint(4); cs.load_uint(256); cs.load_uint(64); cs.load_uint(256)
    cs.load_uint(64); cs.load_uint(32); cs.load_uint(15); cs.load_uint(2); cs.load_uint(2)
    aux = cs.load_ref(); acs = aux.begin_parse()
    if not acs.load_bool(): return None
    return acs.load_ref()

def msg_op(msgcell):
    try:
        cs = msgcell.begin_parse()
        cs.load_uint(1); cs.load_bool(); cs.load_bool(); cs.load_bool()
        cs.load_address(); cs.load_address()
        cs.load_var_uint(16)          # value grams
        cs.load_var_uint(16); cs.load_var_uint(16)  # ihr_fee, fwd_fee
        cs.load_uint(64); cs.load_uint(32)
        if cs.load_bool():            # init present -> can't easily skip; bail
            return None
        br = cs.load_bool()
        body = cs.load_ref() if br else cs
        bcs = body.begin_parse() if hasattr(body,'begin_parse') else body
        return bcs.preload_uint(32) if bcs.bits >= 32 else None
    except Exception:
        return None

def main():
    lc = LiteClient(mode="roundrobin", timeout=4, num_try=8)
    blk = retry(lambda: lc.get_masterchain_info_ext().last); now = lc.get_time()
    _, cfgraw = retry(lambda: lc.get_config_all(blk))
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)
    for name, addr in TARGETS.items():
        st = retry(lambda: lc.get_account_state(Address(addr), blk))
        ss = st.to_shard_state()
        hb = data_of_account(ss.begin_parse().load_ref()).get_hash()
        tl = retry(lambda: lc.get_transactions(Address(addr), st.last_trans_lt, st.last_trans_hash, 30))
        print(f"=== {name} ({addr[:14]}) data_before={hb[:12]} ntx={len(tl.transactions)}")
        nch=0; n=0
        for ti in tl.transactions:
            mc = in_msg_cell(ti.transaction)
            if mc is None: continue
            op = msg_op(mc)
            em = Emulator(cfg); em.set_ignore_chksig(True)
            try:
                em.emulate_transaction(ss, mc, now, st.last_trans_lt+1)
                da = data_of_shard(em.account.to_cell())
                ha = da.get_hash() if da is not None else None
            except Exception as e:
                print(f"   op={hex(op) if op else None} {NAMES.get(op,'?')} ERR {e!r}"); continue
            n+=1
            ch = ha != hb
            if ch: nch+=1
            oph = hex(op) if op is not None else "None"
            print(f"   op={oph:>12} {NAMES.get(op,'?'):30s} data_changed={ch}")
        print(f"   -> {nch}/{n} real msgs change storage")

if __name__ == "__main__":
    main()
