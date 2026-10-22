#!/usr/bin/env python3
"""
DECISIVE: replay the exact 0xa1b21e8b message (that made the affUSDTl vault mint
1e16 shares on 2026-10-16) against the vault's CURRENT state.
READ-ONLY (lite reads + local TVM).
"""
import base64, json, time
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

VAULT = "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW"   # affUSDTl master
POOL  = "0:425d0a76b124c986f9d5e83941aa14ec74d31973fb49717409e578e85a2cbe38"
ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"

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

def build_msg(src, dest, value_nano, body_cell, lt, now):
    m = CellBuilder()
    m.store_bool(False); m.store_bool(True); m.store_bool(True); m.store_bool(False)
    m.store_address(Address(src)); m.store_address(Address(dest))
    coins(m, value_nano); m.store_bool(False); coins(m, 0); coins(m, 0)
    m.store_uint(lt, 64); m.store_uint(now, 32)
    m.store_bool(False); m.store_bool(True); m.store_ref(body_cell)
    return m.end_cell()

def retry(fn, n=8):
    last=None
    for _ in range(n):
        try: return fn()
        except Exception as e: last=e; time.sleep(1.5)
    raise last

def main():
    tx = json.load(open("/tmp/opencode/aff/vault_a1b_tx.json"))
    raw = tx["in_msg"]["raw_body"]
    body = Cell(base64.b64encode(bytes.fromhex(raw)).decode())
    print("body cell hash", body.get_hash())

    lc = LiteClient(mode="roundrobin", timeout=4, num_try=8)
    blk = retry(lambda: lc.get_masterchain_info_ext().last); now = lc.get_time()
    _, cfgraw = retry(lambda: lc.get_config_all(blk))
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)
    st = retry(lambda: lc.get_account_state(Address(VAULT), blk))
    lt = st.last_trans_lt + 1
    ss = st.to_shard_state()
    hb = data_of_account(ss.begin_parse().load_ref()).get_hash()
    print("vault data_before", hb, "lt", st.last_trans_lt)

    for tag, src in [("from_pool", POOL), ("from_attacker", ATTACKER)]:
        msg = build_msg(src, VAULT, 1_500_000_000, body, lt, now)
        em = Emulator(cfg); em.set_ignore_chksig(True)
        try:
            ok = em.emulate_transaction(ss, msg, now, lt)
            da = data_of_shard(em.account.to_cell())
            ha = da.get_hash() if da is not None else None
        except Exception as e:
            print(f"[{tag}] ERR {e!r}"); continue
        print(f"[{tag}] src={src[:14]} ok={ok} data_changed={ha != hb} after={str(ha)[:16]}")
        if ha != hb and da is not None:
            open(f"/tmp/opencode/aff/after_a1b_{tag}.boc","wb").write(base64.b64decode(da.to_boc()))

if __name__ == "__main__":
    main()
