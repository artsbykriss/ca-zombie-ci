#!/usr/bin/env python3
"""Enumerate Exceed Finance program state: access_control, pairs, vaults, windows."""
import base64, json, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import get_account, call
from solders.pubkey import Pubkey

PROGRAM = Pubkey.from_string("par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV")
TOKEN_PROGRAM = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
TOKEN_2022 = Pubkey.from_string("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb")
ATA_PROGRAM = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
SOL_MINT = Pubkey.from_string("So11111111111111111111111111111111111111112")
USDC_MINT = Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
CBBTC_MINT = Pubkey.from_string("cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij")

def ata(mint, owner, tp=TOKEN_PROGRAM):
    return Pubkey.find_program_address([bytes(owner), bytes(tp), bytes(mint)], ATA_PROGRAM)[0]

def pda(seeds):
    return Pubkey.find_program_address(seeds, PROGRAM)[0]

ac, ac_bump = Pubkey.find_program_address([b"access_control"], PROGRAM)
print("access_control PDA:", ac, "bump:", ac_bump)
a = get_account(str(ac))
print(json.dumps({"owner": a["owner"], "lamports": a["lamports"], "len": len(base64.b64decode(a["data"][0]))}, indent=2))

raw = base64.b64decode(a["data"][0])
# AccessControl layout: 8 disc + bump(1) + merkle_root(32) + is_whitelist_enabled(1) +
# 6 pubkeys(32) + feed_id(32) + guardians(5*(1+32)) + is_sealed(1) +
# 6 option pubkeys (1+32 each)
o = 8
bump = raw[o]; o += 1
merkle_root = raw[o:o+32].hex(); o += 32
wl = raw[o]; o += 1
def pk(b): return str(Pubkey.from_bytes(b))
vault_auth = pk(raw[o:o+32]); o += 32
window_auth = pk(raw[o:o+32]); o += 32
deposit_auth = pk(raw[o:o+32]); o += 32
pair_auth = pk(raw[o:o+32]); o += 32
unseal_auth = pk(raw[o:o+32]); o += 32
access_auth = pk(raw[o:o+32]); o += 32
feed_id = raw[o:o+32].hex(); o += 32
guardians = []
for i in range(5):
    tag = raw[o]; o += 1
    if tag:
        guardians.append(pk(raw[o:o+32]))
    o += 32
is_sealed = raw[o]; o += 1
pending = {}
for name in ["vault","window","deposit","pair","unseal","access"]:
    tag = raw[o]; o += 1
    pending[name] = pk(raw[o:o+32]) if tag else None
    o += 32
print(json.dumps(dict(bump=bump, merkle_root=merkle_root, is_whitelist_enabled=bool(wl),
    vault_authority=vault_auth, window_authority=window_auth, deposit_authority=deposit_auth,
    pair_authority=pair_auth, unseal_authority=unseal_auth, access_authority=access_auth,
    sol_usdc_feed_id=feed_id, guardians=guardians, is_sealed=bool(is_sealed),
    pending=pending, consumed=o, total=len(raw)), indent=2))

# Pairs
PAIRS = {
    "exUSDC(pikUSDC)": ("EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7", USDC_MINT, "8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z", "pikUSDC"),
    "exSOL": ("HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop", SOL_MINT, "4J93x2zCNMrL4Qq8Nuvjk9yNLNkf1Vmqz14UxtcM4uny", "exSOL"),
    "exBTC": ("GpV9U2yY3L5u4DkWC6Unejsz42iNME4Usk5RzTaA23to", CBBTC_MINT, "HabWg55SK5Jam5WUpbk8Wfq7JbuAaFVPu8KVFMJj9yVg", "exBTC"),
}
out = {"slot": call("getSlot", [])["result"], "access_control": str(ac), "pairs": {}}
for name, (paddr, base_mint, lst_mint, symbol) in PAIRS.items():
    pair_pk = Pubkey.from_string(paddr)
    base_ata = ata(base_mint, pair_pk)
    lst_ata_fee = ata(Pubkey.from_string(lst_mint), pair_pk)
    lst_mint_pda = pda([b"lst_mint", symbol.encode()])
    rec = dict(pair=paddr, base_mint=str(base_mint), lst_mint=lst_mint,
               pair_base_token_account=str(base_ata), lst_fee_account=str(lst_ata_fee),
               lst_mint_pda=str(lst_mint_pda), lst_mint_pda_matches=(str(lst_mint_pda)==lst_mint))
    for label, addr in [("pair_base_token_account", str(base_ata)), ("lst_fee_account", str(lst_ata_fee))]:
        ai = get_account(addr)
        if ai:
            d = base64.b64decode(ai["data"][0])
            # SPL token account: mint(32) owner(32) amount(8)...
            mint = str(Pubkey.from_bytes(d[0:32])); owner = str(Pubkey.from_bytes(d[32:64]))
            amt = struct.unpack_from("<Q", d, 64)[0]
            rec[label+"_state"] = dict(mint=mint, owner=owner, amount=amt, owner_prog=ai["owner"], lamports=ai["lamports"])
        else:
            rec[label+"_state"] = None
    out["pairs"][name] = rec
    print(f"\n=== {name} ===")
    print(json.dumps(rec, indent=2))

json.dump(out, open("/home/heisenberg/CA/exceed-finance/analysis/childB/state-dump.json","w"), indent=2)
print("\nsaved state-dump.json")
