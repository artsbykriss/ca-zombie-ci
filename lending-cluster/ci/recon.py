#!/usr/bin/env python3
"""ZH4 Wave B2 lending-cluster recon (public RPCs only; read-only).
Writes ci-out/recon.json with the live-state facts behind the report.
"""
import json, subprocess, sys, time
import requests
from eth_abi import encode, decode

T = json.load(open("analysis/targets.json"))
S = requests.Session(); S.headers.update({"Content-Type":"application/json","User-Agent":"zh4-b2-research"})
MC = "0xcA11bde05977b3631167028862bE2a173976CA11"
RPCS = {"soneium": T["sake"]["rpc"], "conflux": T["unitus"]["rpc"], "fuse": T["voltage"]["rpc"], "monad": T["neverland"]["rpc"]}

def rpcc(chain, method, params, timeout=40):
    rpc = RPCS.get(chain, chain)
    for attempt in range(3):
        try:
            r = S.post(rpc, json={"jsonrpc":"2.0","id":1,"method":method,"params":params}, timeout=timeout).json()
            if "error" in r: raise RuntimeError(str(r["error"])[:200])
            return r["result"]
        except Exception as e:
            if attempt == 2: raise
            time.sleep(1)
    raise RuntimeError("rpc failed")

def block(chain):
    return int(rpcc(chain, "eth_blockNumber", []), 16)

def mc(chain, calls, chunk=250):
    """calls: [(target, calldata_hex)] -> [(ok, bytes_hex)]"""
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i+chunk]
        payload = [(t, True, bytes.fromhex(d[2:])) for t, d in part]
        data = "0x82ad56cb" + encode(["(address,bool,bytes)[]"], [payload]).hex()
        res = rpcc(chain, "eth_call", [{"to": MC, "data": data}, "latest"])
        out += [(ok, "0x"+b.hex()) for ok, b in decode(["(bool,bytes)[]"], bytes.fromhex(res[2:]))[0]]
        time.sleep(0.05)
    return out

def word(a): return a[2:].rjust(64, '0')
def dec1(res, typ="uint256"):
    return decode([typ], bytes.fromhex(res[2:]))[0]
def addr(res): return decode(["address"], bytes.fromhex(res[2:]))[0]

def main():
    out = {"generated_at": int(time.time())}
    print("start", flush=True)
    sel = lambda s: subprocess.check_output(["cast","sig",s]).decode().strip()

    # ---------------- SakeFinance (Soneium) ----------------
    s = T["sake"]; ch = "sake" if False else s["chain"]
    out["blocks"] = {"soneium": block("soneium"), "conflux": block("conflux"), "fuse": block("fuse"), "monad": block("monad")}
    calls = []
    for a in s["assets"]:
        calls += [(s["pool"], sel("getReserveData(address)")+word(a)),
                  (a, sel("symbol()")), (a, sel("decimals()")),
                  (s["oracle"], sel("getAssetPrice(address)")+word(a)),
                  (s["oracle"], sel("getSourceOfAsset(address)")+word(a))]
    res = mc("soneium", calls); k = 0; sake = []
    for a in s["assets"]:
        rd = decode(["uint256"]+["uint128"]*5+["uint40","uint16","address","address","address","address","uint128","uint128","uint128"], bytes.fromhex(res[k][1][2:])); k += 1
        cfg = rd[0]; ltv = cfg & 0xffff; lq = (cfg>>16)&0xffff; bonus = (cfg>>32)&0xffff
        sym = "?"
        if res[k][0]:
            try: sym = decode(["string"], bytes.fromhex(res[k][1][2:]))[0]
            except: pass
        k += 1
        decm = dec1(res[k][1], "uint8") if res[k][0] else 0; k += 1
        price = dec1(res[k][1])/1e8 if res[k][0] else None; k += 1
        src = "0x"+res[k][1][-40:] if res[k][0] else None; k += 1
        sake.append(dict(asset=a, symbol=sym, decimals=decm, ltv=ltv/100, liqth=lq/100, bonus=bonus/1e4, price=price, source=src, aToken=rd[8], vToken=rd[10]))
    # HF scan of all vToken holders
    holders = s["debtHolders"]; Ch = 300; hf = {}; under = 0; bad = 0.0; min_hf = None; min_hf_addr = None
    for i in range(0, len(holders), Ch):
        part = holders[i:i+Ch]
        rr = mc("soneium", [(s["pool"], sel("getUserAccountData(address)")+word(a)) for a in part], chunk=200)
        for a, (ok, d) in zip(part, rr):
            if not ok: continue
            v = decode(["uint256"]*6, bytes.fromhex(d[2:])); coll = v[0]/1e8; debt = v[1]/1e8; h = v[5]/1e18
            if debt > 0 and (min_hf is None or h < min_hf): min_hf, min_hf_addr = h, a
            if h < 1 and debt > 0:
                if coll > 0: under += 1
                else: bad += debt
    print("sake done", flush=True)
    out["sake"] = dict(reserves=sake, debtHolders=len(holders), hf_lt1_with_collateral=under, zero_collateral_bad_debt_usd=round(bad,2), min_hf_with_debt=min_hf, min_hf_addr=min_hf_addr)

    # ---------------- Kyo (Soneium) ----------------
    kk = T["kyo"]; calls = []
    for p in kk["pools"]:
        calls += [(p["pool"], sel("liquidityStaked()")), (p["pool"], sel("liquidity()")),
                  (p["pool"], sel("rewardToken()")),
                  (p["factory"], sel("collectableAmount(address,address)")+word(p["rewardToken"])+word(p["pool"]))]
    res = mc("soneium", calls); staked = 0; pending = 0; pend_sum = 0; i = 0; reward_tokens = {}
    for p in kk["pools"]:
        ls = dec1(res[i][1]) if res[i][0] else 0; i += 1
        liq = dec1(res[i][1]) if res[i][0] else 0; i += 1
        rt = addr(res[i][1]) if res[i][0] else None; i += 1
        rwd = decode(["uint128"], bytes.fromhex(res[i][1][2:]))[0] if res[i][0] else 0; i += 1
        reward_tokens[rt] = reward_tokens.get(rt, 0) + 1
        if ls > 0: staked += 1
        if rwd > 0: pending += 1; pend_sum += rwd
    r = mc("soneium", [(kk["voter"], sel("getTotalWeight()")), (kk["vault"], sel("totalAssets()")), (kk["vault"], sel("totalSupply()")), (kk["vault"], sel("pendingRewards()")), (kk["rewardToken"], sel("balanceOf(address)")+word(kk["emitter"]))])
    print("kyo done", flush=True)
    out["kyo"] = dict(pools=len(kk["pools"]), pools_with_staked_liquidity=staked, pools_with_pending_rewards=pending, pending_raw=pend_sum,
                      voter_total_weight=dec1(r[0][1]) if r[0][0] else None, vault_total_assets=dec1(r[1][1])/1e18, vault_total_supply=dec1(r[2][1])/1e18,
                      vault_pending=dec1(r[3][1]) if r[3][0] else None, emitter_reward_balance=dec1(r[4][1])/1e18 if r[4][0] else None,
                      reward_tokens=reward_tokens)

    # ---------------- Unitus (Conflux) ----------------
    u = T["unitus"]; calls = [(u["controller"], sel("closeFactorMantissa()")), (u["controller"], sel("liquidationIncentiveMantissa()")), (u["controller"], sel("getSModeLength()"))]
    for m in u["markets"]:
        calls += [(m, sel("totalSupply()")), (m, sel("totalBorrows()")), (m, sel("getCash()")), (m, sel("exchangeRateStored()")), (m, sel("totalReserves()")), (m, sel("reserveRatio()")), (m, sel("underlying()")), (m, sel("decimals()")), (u["controller"], sel("marketsV2(address)")+word(m)), (u["oracle"], sel("getUnderlyingPrice(address)")+word(m))]
    res = mc("conflux", calls); k = 0
    close = dec1(res[0][1])/1e18; inc = dec1(res[1][1])/1e18; smodes = dec1(res[2][1]); k = 3
    mkts = []; debt_usd = 0
    for m in u["markets"]:
        def g(): 
            nonlocal k
            v = res[k]; k += 1; return v
        ts = dec1(g()[1]); tb = dec1(g()[1]); cash = dec1(g()[1]); exr = dec1(g()[1]); reserves = dec1(g()[1]); rr = dec1(g()[1]); und = addr(g()[1])
        decm = dec1(g()[1], "uint8")
        mv = decode(["uint256","uint256","uint256","uint256","bool","bool","bool","uint8","bool","uint256","uint256"], bytes.fromhex(g()[1][2:]))
        raw_price = dec1(g()[1]); price = raw_price / (10 ** (36 - decm))
        tb_tok = tb / (10 ** decm)
        debt_usd += tb_tok * price
        mkts.append(dict(market=m, decimals=decm, totalSupply=ts/(10**decm), totalBorrows=tb_tok, cash=cash/(10**decm), exchangeRate=exr/1e18, reserves=reserves/(10**decm), reserveRatio=rr/1e18, underlying=und, cf=mv[0]/1e18, borrowPaused=mv[6], price=price))
    r = mc("conflux", [(u["controller"], sel("calcAccountEquityWithEffectV2(address,address,uint256,uint256,bool)")+word(u["topAccount"])+word("0x"+"0"*40)+word("0")+word("0")+word("1")),
                       (u["markets"][7], sel("TOTAL_SUPPLY_THRESHOLD()"))])
    eq = decode(["uint256"]*4, bytes.fromhex(r[0][1][2:])) if r[0][0] else None
    print("unitus done", flush=True)
    out["unitus"] = dict(closeFactor=close, liquidationIncentive=inc, sModes=smodes, markets=mkts, totalDebtUsd=round(debt_usd,2), topAccount=u["topAccount"],
                         topSurplusUsd=eq[0]/1e18 if eq else None, topShortfallUsd=eq[1]/1e18 if eq else None, topCollateralUsd=eq[2]/1e18 if eq else None, topBorrowUsd=eq[3]/1e18 if eq else None,
                         totalSupplyThreshold=dec1(r[1][1]) if r[1][0] else None)

    # ---------------- Voltage (Fuse) ----------------
    v = T["voltage"]; calls = []
    for a in v["accounts"]:
        calls.append((v["pool"], sel("getUserAccountData(address)")+word(a)))
    res = mc("fuse", calls); accts = []; real = []
    for a, (ok, d) in zip(v["accounts"], res):
        if not ok: continue
        x = decode(["uint256"]*6, bytes.fromhex(d[2:])); coll = x[0]/1e8; debt = x[1]/1e8; h = x[5]/1e18
        accts.append(dict(account=a, collateral=coll, debt=debt, hf=h))
        if h < 1 and coll > 1 and coll > debt * 0.1: real.append(dict(account=a, collateral=coll, debt=debt, hf=h, gross_bonus_usd=round(0.5*debt*0.05,2)))
    print("voltage done", flush=True)
    out["voltage"] = dict(accounts=accts, hf_lt1=sum(1 for x in accts if x["hf"]<1), real_liquidatable=real, gross_bonus_total=round(sum(x["gross_bonus_usd"] for x in real),2))

    # ---------------- Neverland (Monad) ----------------
    n = T["neverland"]; calls = []
    for a in n["debtHolders"]:
        calls += [(n["isolated"], sel("getUserAccountData(address)")+word(a)), (n["canonical"], sel("getUserAccountData(address)")+word(a))]
    res = mc("monad", calls); iso = []; can = []
    for i, a in enumerate(n["debtHolders"]):
        for lst, off in ((iso, 0), (can, 1)):
            ok, d = res[2*i+off]
            if not ok: continue
            x = decode(["uint256"]*6, bytes.fromhex(d[2:])); lst.append(dict(account=a, coll=x[0]/1e8, debt=x[1]/1e8, hf=x[5]/1e18))
    r = mc("monad", [(n["vDebt"], sel("totalSupply()")), (n["aUsd"], sel("totalSupply()")), (n["ausd"], sel("balanceOf(address)")+word(n["aUsd"])),
                     (n["canonical"], sel("getUserAccountData(address)")+word("0x5aed44c1a3d0851ba630c17cf186c36a01027a21")),
                     (n["canonical"], sel("getUserAccountData(address)")+word("0xc853e78877c758cc43ad152726cb593f03d23030")),
                     (n["canonical"], sel("getUserAccountData(address)")+word("0xf4db2e9d49817ee4d1b89c214a0dd76b603f9c33"))])
    vd = dec1(r[0][1])/1e6; aTot = dec1(r[1][1])/1e6; aCash = dec1(r[2][1])/1e6
    canon_watch = []
    for name, (ok, d) in zip(["0x5aed", "0xc853", "0xf4db"], r[3:]):
        if ok:
            x = decode(["uint256"]*6, bytes.fromhex(d[2:])); canon_watch.append(dict(account=name, coll=x[0]/1e8, debt=x[1]/1e8, hf=x[5]/1e18, gross_bonus_at_5pct=round(0.5*x[1]/1e8*0.05,2)))
    # self-repay vaults: sum USDC
    vaults = n["vaults"]; vtot = 0; vnz = 0
    for i in range(0, len(vaults), 200):
        part = vaults[i:i+200]
        rr = mc("monad", [(n["usdc"], sel("balanceOf(address)")+word(a)) for a in part], chunk=200)
        for ok, d in rr:
            if ok:
                b = dec1(d)
                if b > 0: vnz += 1; vtot += b
    print("neverland done", flush=True)
    out["neverland"] = dict(isolated=iso, canonical_of_debt_holders=can, isolated_debt_usd=round(sum(x["debt"] for x in iso),2),
                            isolated_min_hf=min([x["hf"] for x in iso if x["debt"]>0] or [None]),
                            canonical_watch=canon_watch, vDebt_total_supply_usd=round(vd,2), aUSD_aToken_total_supply_usd=round(aTot,2), aUSD_cash_usd=round(aCash,2),
                            self_repay_vaults=len(vaults), vaults_with_usdc=vnz, vault_usdc_total=round(vtot/1e6,6))

    json.dump(out, open("ci-out/recon.json","w"), indent=1)
    print(json.dumps({k: (v if not isinstance(v, dict) else {kk: vv for kk, vv in v.items() if kk not in ("reserves","markets","isolated","canonical_of_debt_holders","accounts")}) for k, v in out.items()}, indent=1))
    return out

if __name__ == "__main__":
    main()
