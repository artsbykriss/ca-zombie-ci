#!/usr/bin/env python3
"""Independent Hylo router verification (Task B). READ-ONLY: simulateTransaction + reads."""
import json, base64, hashlib
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
from rpc import rpc, b58decode

ROUTER = Pubkey.from_string("hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f")
EXCH = Pubkey.from_string("HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn")
TOKENKEG = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
TOKEN2022 = Pubkey.from_string("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb")
PAYER = Pubkey.from_string("AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw")

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

def fresh(tag): return Pubkey.from_bytes(hashlib.sha256(tag.encode()).digest())
def pda(seeds, program): return Pubkey.find_program_address(seeds, program)[0]

def acct_exists(pk):
    r = rpc("getAccountInfo", [str(pk), {"encoding": "base64"}])
    v = r.get("value") if isinstance(r, dict) else None
    return (v is not None, (v or {}).get("owner"), len(base64.b64decode(v["data"][0])) if v else 0)

def token_accounts_owned(owner, program):
    r = rpc("getTokenAccountsByOwner", [str(owner), {"programId": str(program)}, {"encoding": "base64"}])
    if isinstance(r, dict) and "value" in r:
        return len(r["value"]), r["value"]
    return None, r

def structural():
    out = {}
    print("=== Part 1: structural ===")
    ex, own, ln = acct_exists(ROUTER)
    print("router program exists:", ex, "owner:", own, "len:", ln)
    out["router"] = {"exists": ex, "owner": own, "len": ln}

    er = pda([b"exo_registry"], ROUTER)
    ea = pda([b"__event_authority"], ROUTER)
    pdas = {"EXO_REGISTRY": er, "EVENT_AUTH": ea}
    out["router_pdas"] = {}
    for name, pk in pdas.items():
        ex, own, ln = acct_exists(pk)
        t1, _ = token_accounts_owned(pk, TOKENKEG)
        t2, _ = token_accounts_owned(pk, TOKEN2022)
        print(f"{name} {pk} exists={ex} owner={own} len={ln} token_accts(Token)={t1} token_accts(T22)={t2}")
        out["router_pdas"][name] = {"pda": str(pk), "exists": ex, "owner": own, "len": ln,
                                    "token_accounts_classic": t1, "token_accounts_2022": t2}
    # router program itself
    t1, _ = token_accounts_owned(ROUTER, TOKENKEG)
    t2, _ = token_accounts_owned(ROUTER, TOKEN2022)
    print("router program token accounts:", t1, t2)
    out["router"]["token_accounts_classic"] = t1
    out["router"]["token_accounts_2022"] = t2

    # are router PDAs authority of the vaults used by the live route?
    A = [Pubkey.from_string(a) for a in ACCOUNTS]
    for label, idx in [("collateral_vault", 7), ("fee_vault", 8)]:
        r = rpc("getAccountInfo", [str(A[idx]), {"encoding": "jsonParsed"}])
        v = r.get("value") if isinstance(r, dict) else None
        info = v.get("data", {}).get("parsed", {}).get("info", {}) if v else {}
        print(f"{label} {A[idx]} owner_field={info.get('owner')} mint={info.get('mint')}")
        out.setdefault("vaults", {})[label] = {"addr": str(A[idx]), "owner": info.get("owner"), "mint": info.get("mint")}

    # Is any router PDA equal to an exchange PDA or a vault authority?
    out["router_pda_equals_exchange_pda"] = False
    return out

def sim(ixs, label, results):
    msg = Message.new_with_blockhash(ixs, PAYER, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    res = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                            "replaceRecentBlockhash": True, "commitment": "processed"}])
    e = {"label": label}
    if isinstance(res, dict) and "value" in res:
        v = res["value"]
        e["err"] = v.get("err"); e["unitsConsumed"] = v.get("unitsConsumed"); e["logs"] = v.get("logs")
    else:
        e["rpc_error"] = res
    results.append(e)
    print(f"\n== {label}\n   err={json.dumps(e.get('err', e.get('rpc_error')))}")
    for l in (e.get("logs") or [])[-6:]:
        print("   ", l)
    return e

def route_ix(accounts, data):
    metas = [AccountMeta(accounts[i], i in SIGNER, i in WRITABLE) for i in range(len(accounts))]
    return Instruction(ROUTER, data, metas)

def substitutions():
    print("\n=== Part 3: substitution sims ===")
    raw = b58decode(DATA_B58)
    data = bytearray(raw)
    data[72:80] = (100).to_bytes(8, "little")   # amount = 100
    data = bytes(data)
    base = [Pubkey.from_string(a) for a in ACCOUNTS]
    R = []
    # (a) control as-is
    sim([route_ix(base, data)], "a) CONTROL as-is amount=100", R)
    # (b) idx17 exchange program -> bogus
    b2 = list(base); b2[17] = fresh("hylo-verify-bogus-program")
    sim([route_ix(b2, data)], "b) idx17 exchange-program -> bogus", R)
    # (c) idx0 user -> fresh signer
    c2 = list(base); c2[0] = fresh("hylo-verify-attacker-user")
    sim([route_ix(c2, data)], "c) idx0 user -> fresh signer", R)
    return R

def main():
    out = {"structural": structural(), "substitutions": substitutions()}
    json.dump(out, open("hylo_results.json", "w"), indent=2)
    print("\nwrote hylo_results.json")

if __name__ == "__main__":
    main()
