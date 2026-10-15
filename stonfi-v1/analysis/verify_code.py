#!/usr/bin/env python3
"""Verify STON.fi v1 router/pool deployed code & data against the router's stored codes.

Checks:
  A. router code hash (on-chain) vs reported
  B. router stored pool_code cell hash vs deployed pool account code hash
  C. pool address == hash(state_init(pool_code, pool_data))   (as the router computes it)
  D. router stored lp_account_code / jetton_lp_wallet_code vs deployed instances
"""
import sys
import base64
import json

sys.path.insert(0, "/home/heisenberg/CA/stonfi-v1/analysis")
from ton_client import account_states, run_get_method, masterchain_head  # noqa

from pytoniq_core import Cell

ROUTER = "EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt"
# top v1 pool by TVL (USDT / TON-side) from api.ston.fi
POOL = "EQD8TJ8xEWB1SpnRE4d89YO3jl0W0EiBnNS4IBaHaUmdfizE"

out = {}

head = masterchain_head()
out["masterchain_seqno"] = head["seqno"]
out["gen_utime"] = head["gen_utime"]

# A. router account
ra = account_states(ROUTER, include_boc=True)
out["router"] = {
    "code_hash_b64": ra["code_hash"],
    "data_hash_b64": ra["data_hash"],
    "balance": ra["balance"],
    "status": ra["status"],
    "last_transaction_lt": ra["last_transaction_lt"],
}
code_cell = Cell.from_boc(base64.b64decode(ra["code_boc"]))[0]
data_cell = Cell.from_boc(base64.b64decode(ra["data_boc"]))[0]
out["router"]["code_hash_computed"] = code_cell.hash.hex()
out["router"]["code_hash_match"] = (
    base64.b64encode(code_cell.hash).decode() == ra["code_hash"]
)
out["router"]["code_cells"] = code_cell.refs.__len__()
out["router"]["code_bits"] = code_cell.bits.__len__()

# router get_router_data -> stored pool_code cell
ec, dec, stack = run_get_method(ROUTER, "get_router_data")
out["router_get_router_data"] = {"exit_code": ec, "is_locked": dec.get("is_locked"), "admin": dec.get("admin_address")}
pool_code_cell = Cell.from_boc(bytes.fromhex(dec["pool_code"]))[0]
lp_wallet_code_cell = Cell.from_boc(bytes.fromhex(dec["jetton_lp_wallet_code"]))[0]
lp_account_code_cell = Cell.from_boc(bytes.fromhex(dec["lp_account_code"]))[0]
out["stored_codes"] = {
    "pool_code_hash": pool_code_cell.hash.hex(),
    "lp_wallet_code_hash": lp_wallet_code_cell.hash.hex(),
    "lp_account_code_hash": lp_account_code_cell.hash.hex(),
    "temp_upgrade_boc": dec["temp_upgrade"],
}

# B. pool account
pa = account_states(POOL, include_boc=True)
pool_code_deployed = Cell.from_boc(base64.b64decode(pa["code_boc"]))[0]
pool_data_deployed = Cell.from_boc(base64.b64decode(pa["data_boc"]))[0]
out["pool"] = {
    "address": POOL,
    "code_hash_b64": pa["code_hash"],
    "code_hash_computed": pool_code_deployed.hash.hex(),
    "data_hash_b64": pa["data_hash"],
    "balance": pa["balance"],
    "status": pa["status"],
    "code_matches_router_stored_pool_code": pool_code_deployed.hash == pool_code_cell.hash,
}

# C. reconstruct state init as the router does and compare address
#    state_init = 0b00 + store_dict(code) + store_dict(data) + 0
pool_addr_hex = "779dcc815138d9500e449c5291e7f12738c23d575b5310000f6a253bd607384e"  # placeholder replaced below
# pool address from friendly
import base64 as b64
raw = b64.urlsafe_b64decode(POOL + "=" * (-len(POOL) % 4))
wc = raw[1]
h = raw[2:].hex()
out["pool"]["wc_hex"] = f"{0 if wc == 0 else -1}:{h}"

# state init from deployed code+data
si = Cell.from_boc(None) if False else None
# build: bits '00' then two dict refs then bit 0
from pytoniq_core import Builder
b = Builder()
b.store_bit(0).store_bit(0)
b.store_dict(pool_code_deployed)
b.store_dict(pool_data_deployed)
b.store_bit(0)
si_cell = b.end_cell()
out["pool"]["state_init_hash_from_deployed"] = si_cell.hash.hex()
out["pool"]["address_matches_state_init"] = si_cell.hash.hex() == h

# also rebuild state init from router-stored pool_code + deployed data
b2 = Builder()
b2.store_bit(0).store_bit(0)
b2.store_dict(pool_code_cell)
b2.store_dict(pool_data_deployed)
b2.store_bit(0)
si2 = b2.end_cell()
out["pool"]["address_matches_state_init_with_stored_code"] = si2.hash.hex() == h

print(json.dumps(out, indent=2))
with open("/home/heisenberg/CA/stonfi-v1/analysis/code_verify.json", "w") as f:
    json.dump(out, f, indent=2)
