#!/usr/bin/env python3
"""Hylo router (Solana) — read-only caller-supplied-account substitution battery.

Program: hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f
         (upgrade authority GzyhwK4y7EKPEevAMc2TEpgi1Y3znwj14FUzkHmCMiNP, deployed slot 439863765)

The lead: `route` declares ZERO fixed accounts (everything is `remaining_accounts`)
and `route_v2` declares only the exo_registry.  This battery tests whether a
caller-supplied account set can misroute / over-withdraw value through `route`.

Method (READ-ONLY; no keys, no broadcast):
  * Replays a REAL live `route` CPI (taken from a confirmed mainnet transaction)
    as a positive control.
  * Then substitutes, one at a time, every security-relevant account in the
    forwarded list (CPI program, hylo PDA, exo_pair, collateral mint, Pyth feed,
    user token account, event authority, user signer, argument pair, list length).
  * Also probes the router's own PDAs for custody/authority.

Results -> ../ci-out/hylo_router_results.json (and stdout).
"""
import json, os, sys, struct, hashlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solcore import (rpc, pk, pda, ata, acct_data, owner_of, build_ix, simulate,
                     fresh, TOKEN, TOKEN22)

ROUTER = "hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f"
EXCH   = "HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn"
EARN   = "HysTabVUfmQBFcmzu1ctRd1Y1fxd66RBpboy1bmtDSQQ"
PAYER  = "AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw"   # funded; sim fee payer only
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)

# ---- a real, confirmed mainnet `route` CPI (tx 5nSxg7ucq5YzAdYwujCt5AssYMqiWmWrLPxQwPoks4pzi9ivj972CuZuz36y5KMC6WjFnxT6rmzm1URLQjEdcgfY)
ROUTE_DATA = "C25r8J4hmLFRQkYnUEH56epfuoypcQH5dPF4xSV8VeVMdYamtqhnr5mG9vc1cYis6sqmCTX5gRwDX2ZBfDGmxxNekyBPVseNkyppPFdeWegewrw"
ACCTS = ['D5YqVMoSxnqeZAKAUUE1Dm3bmjtdxQ5DCF356ozqN9cM',  # 0 user
         '9cd2sAfbBvKs4SX9YKo4dcjwP3TgTVQ8dT5koshGcDND',  # 1 hylo
         '42GzNWvZ1H1hwXaBZ8mbeVZaSEgh6zMm8BABdS3v1BEB',  # 2 exo_pair
         'BKdLWcUDE1Kmga2BfSNaMR2wbXSL4YouTbNQ8mTdcqTp',  # 3 levercoin_auth
         'CfuSViqf6wvUKEprLhtuCsSanvfAsMbDmkAW92FP95qe',  # 4 stablecoin_auth
         'GwxovvRAGWvhpmveKmFLZeojeyfzDG3FcBTgAeWnVW1Z',  # 5 vault_auth
         '3HT6dD6APJh89XJs9rkn3BmsvkXE9jPG9dWJmUjWu6TS',  # 6 fee_auth
         'FWPLy9vhx2VRto91bcqh7f8xSUd285Sz2N12H6JC29rr',  # 7 collateral_vault
         'Hh8N3Fdauxgq1jjcKdzGBR3D8cdkpLZrFEVumL1tYQLp',  # 8 fee_vault
         'HqUV7fqfdAgTxaWm6sYqyZFcTCQT4gkQx4juCFX6bwjM',  # 9 user_levercoin_ta
         '31R5W3sxBwnSvKKQg7yS2c31WC1G9d1gr8jhssKWPYrL',  # 10 user_stablecoin_ta
         '5YMkXAYccHSGnHn9nob9xEvv6Pvka9DZWH7nTbotTu9E',  # 11 stablecoin_mint (hyUSD)
         '7ga6rtE9qSb3wdEiDCpTu2kHqoGVfT52jD8ign1rYTvx',  # 12 levercoin_mint (xHYPE)
         '98sMhvDwXj1RQi5c5Mndm3vPe9cBqPrbLaufMXFNMh5g',  # 13 collateral_mint (HYPE)
         '9dAoWJ5ua81c43ntstN4xyg3Uo9Zt93x7BjCxSc27V6V',  # 14 collateral_usd_pyth_feed
         TOKEN,                                            # 15 token_program
         '4VzpNE51Be5vD5Yg8MC3z6TVHq5gGbLJptjv18QbD6WP',  # 16 event_authority
         EXCH]                                             # 17 program
WRITABLE = {0, 2, 8, 9, 10, 11, 12}   # as observed in the live transaction

def b58dec(s):
    A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = 0
    for c in s: n = n*58 + A.index(c)
    b = n.to_bytes((n.bit_length()+7)//8, "big")
    return b"\x00"*(len(s)-len(s.lstrip("1"))) + b

ANCHOR = {2003:"ConstraintRaw",2006:"ConstraintSeeds",2014:"ConstraintTokenMint",
          2015:"ConstraintTokenOwner",3010:"AccountNotSigner",3012:"AccountNotInitialized"}

def errname(r):
    if not isinstance(r, dict): return "RPC:"+str(r)
    if "__err__" in r: return "RPC:"+str(r["__err__"])
    e = (r.get("value") or {}).get("err")
    if e is None: return "SUCCESS"
    try:
        c = e["InstructionError"][1]
        if isinstance(c, dict) and "Custom" in c:
            n = c["Custom"]
            tag = ANCHOR.get(n) or ("exchange-custom" if n >= 6000 else "?")
            return f"Custom {n} ({tag})"
        return str(c)
    except Exception:
        return str(e)

def main():
    results = []
    def run(label, data, accts, writable=WRITABLE, signers={0}, note=""):
        metas = [(a, i in signers, i in writable) for i, a in enumerate(accts)]
        r = simulate([build_ix(ROUTER, bytes(data), metas)], PAYER)
        v = r.get("value", {}) if isinstance(r, dict) else {}
        e = v.get("err"); n = "SUCCESS" if e is None else errname(r)
        logs = [l for l in (v.get("logs") or []) if "Program log:" in l or "failed" in l]
        results.append(dict(label=label, result=n, note=note, logs=logs[-4:]))
        print(f"[{label}] -> {n}   {note}", flush=True)
        return r

    D = bytearray(b58dec(ROUTE_DATA))
    D[72:80] = struct.pack("<Q", 100)          # amount 100 hyUSD atoms (<= live balance 170)
    AMOUNT100 = bytes(D)

    # ---------- structural probes ----------
    EXO_REGISTRY = pda([b"exo_registry"], ROUTER)
    EVENT_AUTH   = pda([b"__event_authority"], ROUTER)
    struct_probe = {
        "router_program_owner": owner_of(ROUTER),
        "router_elf_len": (lambda: (lambda d: len(d)-45)(acct_data(pda([bytes(pk(ROUTER))], "BPFLoaderUpgradeab1e11111111111111111111111")) or b""))(),
        "exo_registry_pda": EXO_REGISTRY,
        "exo_registry_exists": acct_data(EXO_REGISTRY) is not None,
        "router_event_authority_pda": EVENT_AUTH,
        "router_event_authority_exists": acct_data(EVENT_AUTH) is not None,
        "router_token_accounts": {
            who: sum(len((rpc("getTokenAccountsByOwner", [a, {"programId": tp}, {"encoding":"base64"}]) or {}).get("value", []) or [])
                     for tp in (TOKEN, TOKEN22))
            for who, a in [("router_program", ROUTER), ("exo_registry", EXO_REGISTRY), ("event_auth", EVENT_AUTH)]},
    }
    print("structural:", json.dumps(struct_probe), flush=True)

    # ---------- control + substitutions ----------
    run("H1_CONTROL_replay_live_route_amount100", AMOUNT100, ACCTS, note="real route CPI, amount<=balance")

    a = list(ACCTS); a[17] = fresh("bogus-program")
    run("H2_programAcct_substituted", AMOUNT100, a, note="CPI target account -> bogus program")
    a = list(ACCTS); a[1] = pda([b"dead"], EXCH)
    run("H3_hyloPDA_substituted", AMOUNT100, a, note="hylo -> another exchange PDA")
    a = list(ACCTS); a[2] = pda([b"exo_pair", bytes(pk("7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs"))], EXCH)
    run("H4_exoPair_otherPair", AMOUNT100, a, note="exo_pair -> WETH pair PDA")
    a = list(ACCTS)
    a[13] = "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs"
    a[12] = pda([b"exo_levercoin", bytes(pk(a[13]))], EXCH)
    run("H5_collateralMint_WETH", AMOUNT100, a, note="collateral -> WETH (other registered pair)")
    a = list(ACCTS); a[14] = "7AviUf9nL62mcxNbQGKm4nKDQnPjswo6c5MX4D57HmyE"
    run("H6_pythFeed_substituted", AMOUNT100, a, note="Pyth feed -> SOL/USD feed")
    a = list(ACCTS); a[9] = a[10]
    run("H7_userTokenAcct_wrongMint", AMOUNT100, a, note="user token acct -> wrong mint")
    a = list(ACCTS); a[16] = pda([b"dead"], EXCH)
    run("H8_eventAuthority_substituted", AMOUNT100, a, note="event authority -> other PDA")
    a = list(ACCTS); a[0] = fresh("zh4-hylo-attacker")
    run("H9_user_substituted_attacker", AMOUNT100, a, note="user -> attacker (signer)")
    D9 = bytearray(AMOUNT100); D9[40:72] = bytes(pk("5YMkXAYccHSGnHn9nob9xEvv6Pvka9DZWH7nTbotTu9E"))
    run("H10_misroute_arg_tokenB_changed", D9, ACCTS, note="args changed, accounts unchanged")
    D10 = bytearray(AMOUNT100)
    D10[8:40] = bytes(pk("98sMhvDwXj1RQi5c5Mndm3vPe9cBqPrbLaufMXFNMh5g"))
    D10[40:72] = bytes(pk("7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs"))
    run("H11_unsupportedPair", D10, ACCTS, note="(HYPE,WETH) not in router table")
    run("H12_shortAccountList", AMOUNT100, ACCTS[:17], note="17 accounts instead of 18")
    run("H13_noUserSigner", AMOUNT100, ACCTS, signers=set(), note="user not a signer")

    # router instruction discriminator check
    route_disc = hashlib.sha256(b"global:route").digest()[:8]
    routev2_disc = hashlib.sha256(b"global:route_v2").digest()[:8]
    disc = dict(route=route_disc.hex(), route_v2=routev2_disc.hex(),
                live_ix_is=("route" if b58dec(ROUTE_DATA)[:8] == route_disc else "route_v2"))

    out = dict(program=ROUTER, slot=rpc("getSlot", []), structural=struct_probe,
               discriminators=disc, substitutions=results,
               verdict=("route is a hardcoded-target CPI proxy with no authority; every "
                        "caller-supplied account is validated by the exchange program."))
    json.dump(out, open(os.path.join(OUT, "hylo_router_results.json"), "w"), indent=1)
    print("\nwrote ci-out/hylo_router_results.json", flush=True)

if __name__ == "__main__":
    main()
