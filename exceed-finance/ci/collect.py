#!/usr/bin/env python3
"""Self-contained Exceed Finance collector (stdlib only, PUBLIC RPC).
Dumps the program ELF, derives instruction discriminators, decodes pair
accounts, and computes the scheduled-liability table. Writes to ci-out/."""
import json, os, base64, hashlib, struct, urllib.request, time

RPC = os.environ.get("RPC", "https://api.mainnet-beta.solana.com")
OUT = "ci-out"
PROGRAM = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV"
PAIRS = {
    "pikUSDC(exUSDC)": "EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7",
    "exSOL": "HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop",
    "exBTC": "GpV9U2yY3L5u4DkWC6Unejsz42iNME4Usk5RzTaA23to",
    "figUSDC": "7H59KP2prV63CEbVs37LBbiVFuMBjtNxvXc96wk4Dh4X",
    "pikSOL": "J6szVgxaWyCrvKJHfjrV6CzbFUcvfgu7KqQ7gJ1DtWii",
}
ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def call(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for i in range(5):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read())
            if "error" in out:
                time.sleep(2 * (i + 1)); continue
            return out
        except Exception:
            time.sleep(2 * (i + 1))
    raise RuntimeError("rpc failed: " + method)

def b58(b):
    n = int.from_bytes(b, "big"); s = ""
    while n > 0:
        n, r = divmod(n, 58); s = ALPHABET[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\x00"))) + s

def disc(prefix, name):
    return hashlib.sha256(f"{prefix}:{name}".encode()).digest()[:8].hex()

def get(pk):
    return call("getAccountInfo", [pk, {"encoding": "base64"}])["result"]["value"]

os.makedirs(OUT, exist_ok=True)

# 1) ELF dump
acct = get(PROGRAM)
raw = base64.b64decode(acct["data"][0])
pd_addr = b58(raw[4:36])
pd = get(pd_addr)
pdraw = base64.b64decode(pd["data"][0])
upgrade_auth = b58(pdraw[13:45]) if pdraw[12] else None
elf = pdraw[45:]
open(f"{OUT}/exceed.elf", "wb").write(elf)
elf_sha = hashlib.sha256(elf).hexdigest()
meta = {"program": PROGRAM, "programdata": pd_addr, "upgrade_authority": upgrade_auth,
        "deploy_slot": int.from_bytes(pdraw[4:12], "little"), "elf_len": len(elf), "elf_sha256": elf_sha}
json.dump(meta, open(f"{OUT}/elf-meta.json", "w"), indent=2)
print("[elf]", json.dumps(meta))

# 2) instruction names present in ELF + discriminators
import re
names = []
for m in re.finditer(rb"Instruction: ([A-Za-z0-9_]+)", elf):
    nm = m.group(1).decode()
    if nm not in names: names.append(nm)
# also the ones we know are in the deployed set
KNOWN = ["create_access_control","create_pair","stake","create_withdrawal_window","request_withdraw",
 "execute_withdraw","restake_expired_withdraw","fund_withdrawal_window","vault_withdraw","update_pair_yield",
 "initiate_authority_transfer","accept_authority_transfer","cancel_authority_transfer","close_withdrawal_window",
 "cancel_withdrawal_request","swap_lst","seal_program","unseal_program","manage_guardian","update_pair_limits",
 "update_sol_usdc_feed","update_whitelist","withdraw_fees","create_token_metadata","migrate","update_pair_type",
 "update_nav","migrate_pair_v2","migrate_access_control_v2"]
ixmap = {disc("global", n): n for n in KNOWN}
json.dump({"elf_instruction_strings": names, "instruction_discriminators": ixmap},
          open(f"{OUT}/instruction-map.json", "w"), indent=2)
print("[ix] instruction strings found in ELF:", len(names))

# 3) decode pairs + liability
now = call("getBlockTime", [call("getSlot", [{"commitment": "confirmed"}])["result"]])["result"]
rows = []
for name, addr in PAIRS.items():
    a = get(addr); d = base64.b64decode(a["data"][0]); o = 8
    o += 2
    base_mint = b58(d[o:o+32]); o += 32
    base_dec = d[o]; o += 1
    lst_mint = b58(d[o:o+32]); o += 32
    lst_dec = d[o]; o += 1
    sl = struct.unpack_from("<I", d, o)[0]; o += 4
    symbol = d[o:o+sl].decode("utf-8", "replace"); o += sl
    interval_rate = struct.unpack_from("<Q", d, o)[0]; o += 8
    spi = struct.unpack_from("<i", d, o)[0]; o += 4
    o += 8
    last_rate = struct.unpack_from("<Q", d, o)[0]; o += 8
    last_ts = struct.unpack_from("<q", d, o)[0]; o += 8
    dep_cap = struct.unpack_from("<Q", d, o)[0]; o += 8
    min_dep = struct.unpack_from("<Q", d, o)[0]; o += 8
    stake_bps = struct.unpack_from("<H", d, o)[0]; o += 2
    swap_bps = struct.unpack_from("<H", d, o)[0]; o += 2
    wd_bps = struct.unpack_from("<H", d, o)[0]
    # live exchange rate (program formula)
    P = 10**12
    if now > last_ts:
        el = now - last_ts; iv = el // spi; rem = el % spi
        comp = (interval_rate ** iv) // (P ** (iv - 1)) if iv > 0 else P
        lin = (interval_rate - P) * rem // spi
        rate = last_rate * (comp + lin) // P
    else:
        rate = last_rate
    sup = call("getTokenSupply", [lst_mint])["result"]["value"]
    amt = int(sup["amount"])
    base_amt = amt * rate // P
    gap = base_dec - lst_dec
    if gap > 0: base_amt *= 10**gap
    elif gap < 0: base_amt //= 10**(-gap)
    rows.append(dict(name=name, pair=addr, base_mint=base_mint, base_decimals=base_dec, lst_mint=lst_mint,
                     lst_decimals=lst_dec, symbol=symbol, interval_rate=interval_rate, seconds_per_interval=spi,
                     last_rate=last_rate, last_timestamp=last_ts, live_rate=rate, lst_supply=amt,
                     base_amount=base_amt, deposit_cap=dep_cap, minimum_deposit=min_dep,
                     stake_fee_bps=stake_bps, swap_fee_bps=swap_bps, withdraw_fee_bps=wd_bps))
    print(f"[pair] {name:14s} {symbol:8s} rate={rate/1e12:.6f} supply={amt} -> base={base_amt}")
json.dump({"chain_time": now, "pairs": rows}, open(f"{OUT}/pairs.json", "w"), indent=2)
print("[done]")
