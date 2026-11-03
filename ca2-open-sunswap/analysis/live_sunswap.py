#!/usr/bin/env python3
"""Read-only live snapshot of SunSwap V4 PoolManager on Tron. No keys, public TronGrid only."""
import json, time, hashlib, urllib.request, sys
sys.path.insert(0, "/home/heisenberg/CA/ca2-open-sunswap/analysis")
import troncall as t

PM_B58 = "TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br"
PM_HEX = "d8de75898a30b097da826464e932934a512c7be3"
ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58(b):
    n = int.from_bytes(b, "big"); s = ""
    while n:
        n, r = divmod(n, 58); s = ALPH[r] + s
    for c in b:
        if c == 0: s = "1" + s
        else: break
    return s

def to_b58(hex20):
    b = bytes.fromhex("41" + hex20)
    chk = hashlib.sha256(hashlib.sha256(b).digest()).digest()[:4]
    return b58(b + chk)

def word_addr(hex20):
    return "0" * 24 + hex20

def call(sel, param="", owner=PM_B58):
    return t.constant(PM_B58, sel, param, owner=owner)

def token_call(tok_hex, sel, param=""):
    return t.constant(to_b58(tok_hex), sel, param, owner=PM_B58)

def first(out):
    return out[0] if out else ""

def as_int(h):
    h = h[2:] if h.startswith("0x") else h
    return int(h, 16) if h else None

out = {"generated_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
       "read_only": True, "chain": "tron", "pool_manager": PM_B58,
       "pool_manager_hex": "0x" + PM_HEX}

# block + account
blk = t.post("/wallet/getnowblock", {})
out["block"] = blk.get("block_header", {}).get("raw_data", {}).get("number")
acc = t.account(PM_B58)
out["native_balance_sun"] = acc.get("balance")
out["native_balance_trx"] = (acc.get("balance") or 0) / 1e6
out["account_name"] = acc.get("account_name")

# core state
for sel, key in [("owner()", "owner"), ("paused()", "paused"), ("poolCount()", "pool_count"),
                 ("protocolFeeController()", "protocol_fee_controller"), ("getLocker()", "locker"),
                 ("getVaultReserve()", "vault_reserve")]:
    r = call(sel); out[key] = r.get("constant_result", []); out[key + "_energy"] = r.get("energy_used")
    time.sleep(0.15)

# protocol fees accrued (USDT + native)
for tok, name in [("a614f803b6fd780986a42c78ec9c7f77e6ded13c", "usdt"),
                  ("0000000000000000000000000000000000000000", "native")]:
    r = call("protocolFeesAccrued(address)", word_addr(tok))
    out["protocol_fees_accrued_" + name] = first(r.get("constant_result", []))
    time.sleep(0.15)

# token balances for the most-used currencies
summary = json.load(open("/home/heisenberg/CA/ca2-open-sunswap/analysis/pool_summary.json"))
toks = [c for c, n in summary["top_currencies"] if c != "0x0000000000000000000000000000000000000000"][:12]
balances = []
for h in toks:
    hx = h[2:] if h.startswith("0x") else h
    entry = {"hex": "0x" + hx, "base58": to_b58(hx)}
    for sel, k in [("symbol()", "symbol"), ("decimals()", "decimals")]:
        r = token_call(hx, sel)
        w = first(r.get("constant_result", []))
        if k == "symbol" and w and len(w) >= 128:
            try:
                off = int(w[0:64], 16); ln = int(w[64:128], 16)
                entry[k] = bytes.fromhex(w[128 + off * 2:128 + off * 2 + ln * 2]).decode(errors="replace")
            except Exception:
                entry[k] = ""
        elif w:
            entry[k] = as_int(w)
        time.sleep(0.15)
    r = token_call(hx, "balanceOf(address)", word_addr(PM_HEX))
    w = first(r.get("constant_result", []))
    entry["balance_raw"] = str(as_int(w)) if w else None
    if entry.get("decimals") is not None and entry.get("balance_raw") is not None:
        entry["balance"] = int(entry["balance_raw"]) / (10 ** entry["decimals"])
    balances.append(entry)
    time.sleep(0.15)
out["token_balances"] = balances

# DefiLlama TVL reference
try:
    import subprocess
    raw = subprocess.check_output(["curl","-s","-m","30","https://api.llama.fi/protocol/sunswap-v4"], timeout=40)
    d = json.loads(raw)
    out["defillama_tvl"] = d.get("currentChainTvls") or d.get("tvl")
except Exception as e:
    out["defillama_error"] = str(e)

json.dump(out, open("/home/heisenberg/CA/ca2-open-sunswap/analysis/live_sunswap.json", "w"), indent=1)
print(json.dumps({k: v for k, v in out.items() if k not in ("token_balances",)}, indent=1)[:2500])
print("tokens:", json.dumps(balances, indent=1)[:2500])
