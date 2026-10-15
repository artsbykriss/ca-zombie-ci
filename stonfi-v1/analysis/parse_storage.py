#!/usr/bin/env python3
"""Parse STON.fi v1 router + pool storage; rebuild the pool's INITIAL state init
(as the router does in get_pool_state_init_and_address) and verify the pool address.
"""
import sys, json, base64
sys.path.insert(0, "/home/heisenberg/CA/stonfi-v1/analysis")
from ton_client import account_states, run_get_method, masterchain_head, friendly  # noqa
from pytoniq_core import Cell, Builder, Address

ROUTER = "EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt"
POOL = "EQD8TJ8xEWB1SpnRE4d89YO3jl0W0EiBnNS4IBaHaUmdfizE"
USDT = "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs"
PTON = "EQBnGWMCf3-FZZq1W4IWcWiGAc3PHuZ0_H-7sad2oY00o83S"
HOLE = "EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c"


def addr_from_slice(sl):
    """parse MsgAddress from a slice -> standard address string 0:hex"""
    a = sl.load_address()
    return a.to_str(False) if a else "none"


def load_data(addr):
    st = account_states(addr, include_boc=True)
    data = Cell.from_boc(base64.b64decode(st["data_boc"]))[0]
    return st, data


out = {}
head = masterchain_head()
out["masterchain_seqno"] = head["seqno"]

# ---------- router data ----------
rst, rdata = load_data(ROUTER)
s = rdata.begin_parse()
is_locked = s.load_uint(1)
admin = addr_from_slice(s)
lp_wallet_code = s.load_ref()
pool_code = s.load_ref()
lp_account_code = s.load_ref()
temp_upgrade = s.load_ref()
tu = temp_upgrade.begin_parse()
end_code = tu.load_uint(64)
end_admin = tu.load_uint(64)
pending_admin = addr_from_slice(tu)
new_code = tu.load_ref()
out["router_data"] = {
    "is_locked": bool(is_locked),
    "admin": admin,
    "admin_friendly": friendly(admin),
    "pool_code_hash": pool_code.hash.hex(),
    "lp_wallet_code_hash": lp_wallet_code.hash.hex(),
    "lp_account_code_hash": lp_account_code.hash.hex(),
    "temp_upgrade": {"end_code": end_code, "end_admin": end_admin,
                     "pending_admin": pending_admin, "new_code_hash": new_code.hash.hex()},
    "balance_nanoton": rst["balance"],
}

# ---------- pool data ----------
pst, pdata = load_data(POOL)
ps = pdata.begin_parse()
pool_router = addr_from_slice(ps)
lp_fee = ps.load_uint(8)
protocol_fee = ps.load_uint(8)
ref_fee = ps.load_uint(8)
token0 = addr_from_slice(ps)
token1 = addr_from_slice(ps)
total_supply_lp = ps.load_coins()
ref0 = ps.load_ref().begin_parse()
collected0 = ref0.load_coins()
collected1 = ref0.load_coins()
protocol_fee_address = addr_from_slice(ref0)
reserve0 = ref0.load_coins()
reserve1 = ref0.load_coins()
pool_lp_wallet_code = ps.load_ref()
pool_lp_account_code = ps.load_ref()

out["pool_data"] = {
    "router": pool_router,
    "fees": {"lp": lp_fee, "protocol": protocol_fee, "ref": ref_fee},
    "token0": token0, "token1": token1,
    "total_supply_lp": total_supply_lp,
    "collected0": collected0, "collected1": collected1,
    "protocol_fee_address": protocol_fee_address,
    "protocol_fee_address_friendly": friendly(protocol_fee_address),
    "reserve0": reserve0, "reserve1": reserve1,
    "lp_wallet_code_hash": pool_lp_wallet_code.hash.hex(),
    "lp_account_code_hash": pool_lp_account_code.hash.hex(),
    "balance_nanoton": pst["balance"],
    "data_hash": pst["data_hash"],
}

# ---------- rebuild INITIAL pool data exactly as pack_pool_data() does ----------
# pack_pool_data(token0, token1, jetton_lp_wallet_code, lp_account_code):
#   router_address(my_address of ROUTER), 20,10,10, token0, token1, total_supply=0,
#   ref(collected0=0, collected1=0, protocol_fee_address=HOLE, reserve0=0, reserve1=0),
#   ref(lp_wallet_code), ref(lp_account_code)
HOLE_RAW = bytes.fromhex("0000000000000000000000000000000000000000000000000000000000000000")


def pack_pool_data(token_a, token_b, lp_wallet_c, lp_account_c):
    b = Builder()
    b.store_address(Address(ROUTER))
    b.store_uint(20, 8)
    b.store_uint(10, 8)
    b.store_uint(10, 8)
    b.store_address(Address(token_a))
    b.store_address(Address(token_b))
    b.store_coins(0)
    inner = Builder()
    inner.store_coins(0)
    inner.store_coins(0)
    inner.store_address(Address(HOLE))
    inner.store_coins(0)
    inner.store_coins(0)
    b.store_ref(inner.end_cell())
    b.store_ref(lp_wallet_c)
    b.store_ref(lp_account_c)
    return b.end_cell()


def state_init_for(code, data):
    b = Builder()
    b.store_bit(0).store_bit(0)
    b.store_dict(code)
    b.store_dict(data)
    b.store_bit(0)
    return b.end_cell()


# try both token orders (the router sorts by slice_hash of the addresses)
for label, (t0, t1) in {
    "as-stored": (token0, token1),
    "swapped": (token1, token0),
}.items():
    d = pack_pool_data(t0, t1, pool_lp_wallet_code, pool_lp_account_code)
    si = state_init_for(pool_code, d)
    # expected address
    import base64 as b64
    raw = b64.urlsafe_b64decode(POOL + "=" * (-len(POOL) % 4))
    target = raw[2:].hex()
    out.setdefault("state_init_check", {})[label] = {
        "state_init_hash": si.hash.hex(),
        "matches_pool_address": si.hash.hex() == target,
        "target": target,
    }

# ---------- token ordering vs slice_hash ----------
out["token_order"] = {
    "hash_token0": token0,
    "hash_token1": token1,
    "note": "pool storage token0 = address with greater slice_hash (per get_pool_state_init_and_address)",
}

# ---------- router's jetton wallets for USDT / pTON ----------
for name, master in {"USDT": USDT, "pTON": PTON}.items():
    try:
        ec, dec, st = run_get_method(master, "get_wallet_address", [{"type": "slice", "value": Address(ROUTER).to_cell().begin_parse()}])
        out.setdefault("router_jetton_wallets", {})[name] = {"exit": ec, "raw": str(st)[:200]}
    except Exception as e:
        out.setdefault("router_jetton_wallets", {})[name] = {"error": str(e)}

print(json.dumps(out, indent=2, default=str))
with open("/home/heisenberg/CA/stonfi-v1/analysis/storage_parse.json", "w") as f:
    json.dump(out, f, indent=2, default=str)
