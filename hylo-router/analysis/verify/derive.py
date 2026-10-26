#!/usr/bin/env python3
"""Decode the live `route` instruction data and re-derive all exchange PDAs.
Independent of the parent's scripts."""
import json
from solders.pubkey import Pubkey

ROUTER = Pubkey.from_string("hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f")
EXCH = Pubkey.from_string("HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
TOKENKEG = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")

DATA_B58 = "C25r8J4hmLFRQkYnUEH56epfuoypcQH5dPF4xSV8VeVMdYamtqhnr5mG9vc1cYis6sqmCTX5gRwDX2ZBfDGmxxNekyBPVseNkyppPFdeWegewrw"
ACCOUNTS = ['D5YqVMoSxnqeZAKAUUE1Dm3bmjtdxQ5DCF356ozqN9cM','9cd2sAfbBvKs4SX9YKo4dcjwP3TgTVQ8dT5koshGcDND',
'42GzNWvZ1H1hwXaBZ8mbeVZaSEgh6zMm8BABdS3v1BEB','BKdLWcUDE1Kmga2BfSNaMR2wbXSL4YouTbNQ8mTdcqTp',
'CfuSViqf6wvUKEprLhtuCsSanvfAsMbDmkAW92FP95qe','GwxovvRAGWvhpmveKmFLZeojeyfzDG3FcBTgAeWnVW1Z',
'3HT6dD6APJh89XJs9rkn3BmsvkXE9jPG9dWJmUjWu6TS','FWPLy9vhx2VRto91bcqh7f8xSUd285Sz2N12H6JC29rr',
'Hh8N3Fdauxgq1jjcKdzGBR3D8cdkpLZrFEVumL1tYQLp','HqUV7fqfdAgTxaWm6sYqyZFcTCQT4gkQx4juCFX6bwjM',
'31R5W3sxBwnSvKKQg7yS2c31WC1G9d1gr8jhssKWPYrL','5YMkXAYccHSGnHn9nob9xEvv6Pvka9DZWH7nTbotTu9E',
'7ga6rtE9qSb3wdEiDCpTu2kHqoGVfT52jD8ign1rYTvx','98sMhvDwXj1RQi5c5Mndm3vPe9cBqPrbLaufMXFNMh5g',
'9dAoWJ5ua81c43ntstN4xyg3Uo9Zt93x7BjCxSc27V6V','TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
'4VzpNE51Be5vD5Yg8MC3z6TVHq5gGbLJptjv18QbD6WP','HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn']
WRITABLE = {0,2,8,9,10,11,12}
SIGNER = {0}

def b58decode(s):
    A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n=0
    for ch in s: n=n*58+A.index(ch)
    b=n.to_bytes((n.bit_length()+7)//8,"big") if n else b""
    pad=0
    for ch in s:
        if ch=="1": pad+=1
        else: break
    return b"\x00"*pad+b

def pda(seeds, program):
    return Pubkey.find_program_address(seeds, program)[0]

def ata(owner, mint, tp=TOKENKEG):
    return Pubkey.find_program_address([bytes(owner), bytes(tp), bytes(mint)], ATA_PROG)[0]

def main():
    raw = b58decode(DATA_B58)
    print("data len:", len(raw), "disc:", raw[:8].hex())
    assert raw[:8].hex() == "e517cb977ae3ad2a", "route disc mismatch"
    token_a = Pubkey.from_bytes(raw[8:40]); token_b = Pubkey.from_bytes(raw[40:72])
    amount = int.from_bytes(raw[72:80], "little")
    opt = raw[80:]
    print("token_a:", token_a)
    print("token_b:", token_b)
    print("amount:", amount)
    print("tail bytes after amount:", raw[80:].hex(), "(len %d)" % len(raw[80:]))

    A = {i: Pubkey.from_string(a) for i, a in enumerate(ACCOUNTS)}
    collateral_mint = A[13]; levercoin_mint = A[12]; stablecoin_mint = A[11]
    print("\n--- re-derive exchange PDAs under exchange::ID ---")
    checks = [
        ("hylo            idx1 ", pda([b"hylo"], EXCH), A[1]),
        ("exo_pair        idx2 ", pda([b"exo_pair", bytes(collateral_mint)], EXCH), A[2]),
        ("levercoin_auth  idx3 ", pda([b"mint_auth", bytes(levercoin_mint)], EXCH), A[3]),
        ("stablecoin_auth idx4 ", pda([b"mint_auth", bytes(stablecoin_mint)], EXCH), A[4]),
        ("vault_auth      idx5 ", pda([b"exo_vault_auth", bytes(collateral_mint)], EXCH), A[5]),
        ("fee_auth        idx6 ", pda([b"fee_auth", bytes(stablecoin_mint)], EXCH), A[6]),
        ("stablecoin_mint idx11", pda([b"hyUSD"], EXCH), A[11]),
        ("levercoin_mint  idx12", pda([b"exo_levercoin", bytes(collateral_mint)], EXCH), A[12]),
        ("event_auth      idx16", pda([b"__event_authority"], EXCH), A[16]),
        ("collateral_vault idx7", ata(A[5], collateral_mint), A[7]),
        ("fee_vault        idx8", ata(A[6], stablecoin_mint), A[8]),
    ]
    for name, derived, live in checks:
        print(f"  {name} derived={derived} live={live} MATCH={derived==live}")
    print("\nuser idx0:", A[0], "on_curve:", A[0].is_on_curve())
    print("program idx17:", A[17], "==exchange:", A[17]==EXCH)
    print("token_program idx15:", A[15], "==Tokenkeg:", A[15]==TOKENKEG)

    print("\n--- router-owned PDAs ---")
    er = pda([b"exo_registry"], ROUTER)
    ea = pda([b"__event_authority"], ROUTER)
    print("  router exo_registry:", er)
    print("  router event_auth  :", ea)
    print("  exo_registry == any exchange PDA?",
          any(er == c[1] for c in checks))
    print("  event_auth   == any exchange PDA?",
          any(ea == c[1] for c in checks))

    # Cross product: can any router PDA equal any exchange PDA? show program ids differ
    print("\n  router::ID bytes != exchange::ID bytes ->",
          bytes(ROUTER) != bytes(EXCH))

if __name__ == "__main__":
    main()
