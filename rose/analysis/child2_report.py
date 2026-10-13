#!/usr/bin/env python3
"""child2_report.py - generate child2-holders.md from all collected data."""
import json

A = "/home/heisenberg/CA/rose/analysis"
raw = json.load(open(f"{A}/child2_holders_raw.json"))
vase = json.load(open(f"{A}/child2_vase_full.json"))
fees = json.load(open(f"{A}/child2_fees.json"))
cls = json.load(open(f"{A}/child2_classified.json"))

PR = fees["prices"]  # DAI/USDC/USDT 1.0, WETH 2507, WBTC 83108, WNEAR 5.02, FRAX .9904, MAI .9962,
                     # UST_aurora .0363, UST_global .0053, RUSD .31, ROSE .000021
USTP = PR["UST_aurora"]

def hx(a): return "0x"+a[-40:].lower()
def fmt_usd(v):
    if v is None: return "-"
    if abs(v) >= 1: return f"${v:,.2f}"
    return f"${v:,.4f}"
def fmt_amt(v, dec):
    return f"{v:,.{min(dec,8)}f}"

# unit prices for LPs computed from accounted balances (decimals normalized)
pools = fees["pools"]
def accval(name, i):
    c = pools[name]["coins"][i]
    return int(c["accounted"])/10**c["dec"]
sup3 = int(pools["3pool"]["lpTotalSupply"])/1e18
price3 = (accval("3pool",0)*1.0 + accval("3pool",1)*1.0 + accval("3pool",2)*1.0) / sup3
def pool_price(name, prices):
    p = pools[name]; s = int(p["lpTotalSupply"])/1e18
    val = sum(accval(name,i)*prices[i] for i in range(len(p["coins"])))
    return val/s
price_metaUST = pool_price("metaUST", [USTP, price3])
price_metaFRAX = pool_price("metaFRAX", [PR["FRAX"], price3])
price_metaMAI = pool_price("metaMAI", [PR["MAI"], price3])
price_RUSD = pool_price("RUSDpool", [PR["RUSD"], price3])
strose = fees["stRose"]
strose_price = int(strose["roseBalance"])/1e18*PR["ROSE"]/(int(strose["totalSupply"])/1e18)
UNIT = {
 "3pool-LP": price3, "metaUST-LP": price_metaUST, "metaFRAX-LP": price_metaFRAX,
 "metaMAI-LP": price_metaMAI, "RUSD-LP": price_RUSD, "stROSE": strose_price,
 "ROSE": PR["ROSE"], "RUSD": PR["RUSD"], "WBTC": PR["WBTC"], "UST": USTP, "USDC": 1.0,
 "USDT": 1.0, "WNEAR": PR["WNEAR"], "WETH": PR["WETH"], "DAI": 1.0, "FRAX": PR["FRAX"], "MAI": PR["MAI"],
}

FARMS = {
 hx("0x52caca9a2d52b27b28767d3649565774a3b991f3"): "Rose farm (stakes 3pool-LP; owner 0x6adf…)",
 hx("0x56de5e2c25828040330cef45258f3ffbc090777c"): "Rose farm (stakes metaUST-LP; owner 0x6adf…)",
 hx("0xb9d873cdc15e462f5414ccdfe618a679a47831b4"): "Rose farm (stakes metaFRAX-LP; owner 0x6adf…)",
 hx("0x9286d58c1c8d434be809221923cf4575f7a4d058"): "Rose farm (stakes RUSD-LP; owner 0x6adf…)",
 hx("0x226991aadeefde03bf557ef067da95fc613abffc"): "Rose farm (stakes metaMAI-LP; owner 0x6adf…)",
 hx("0xd6cb7bb7d63f636d1ca72a1d3ed6f7f67678068a"): "team contract (owner 0x6adf…)",
 hx("0xd812cc1fc1e0a56560796c746b1247e2bd4f31f2"): "team contract (owner 0x6adf…)",
 hx("0xff84ba26ba108d1de17291f95443aeb0b0dd5ab5"): "fee-recipient contract #1 (63 shares; owner 0x9fb0…)",
 hx("0x296bea2b562888497dd46236f3d3580ff07ff694"): "fee-recipient contract #2 (30 shares; owner 0x9fb0…)",
 hx("0x28d24cd683b67511e9701ff0b71fe890314d8d92"): "fee-recipient contract #3 (7 shares; owner 0x9fb0…)",
 hx("0x19917c01653558c1efa8fcd419fa7bc15b9e9bde"): "StrategyRoseLP (Beefy-style vault; strategist 0x2d04…)",
 hx("0x3820feddeaba00564166e68a73babdae5740394f"): "protocol treasury EOA (nonce 297)",
}
VEST = {hx(x):"ROSE vesting contract (owner 0xf9c4…)" for x in [
 "0x0483606d3b7a2917f70ec6b86b7701083aae40f9","0x9f9d73b478c2e1495d20cf9e3371f68f12d5b750",
 "0x28815638559bded4d74dccf3e32d57e652cf1b2d","0x2d44f9e943535c9cc9507af039d4bc83a3cf8743",
 "0x70637de674b02ebb082b441876ab5af8ca49e801","0xcdbcdbd3668a9bdf9a9f61802b0b2ccc78f3910d",
 "0xe4ff40a4c5c1a0dba232a08d54296e06bd162553","0xcc7a83e5555dcf1744033485646d7ce61331a031",
 "0xa02d45731c7eacfc6126353bd07bc51c4ad82206","0xe55a5170d6fb9cda3b6abb46cb907f6d9a9ef0dd",
 "0x24f029f6c284888b30b38648004dc7280e601a7c","0x9f9d73b478c2e1495d20cf9e3371f68f12d5b750"]}

def note(addr):
    a = hx(addr)
    if a in FARMS: return FARMS[a]
    if a in VEST: return VEST[a]
    EXTRA = {
      "0x6ba5b45149996597d96e6db19e4e1efa81a6df97": "additional Garden market clone (master 0x857050ef…); holds its users' collateral",
      "0xf7ad847c2524b1021045bbd2765a41123c9a9233": "team EOA — beneficiary of the 66.67M ROSE vesting contract",
      "0x25dddc42dbcf3b018515523d08db69b528e60a92": "team EOA — beneficiary of the 33.33M ROSE vesting contract",
    }
    if a in EXTRA: return EXTRA[a]
    c = cls.get(a, {})
    if c.get("known"): return c["known"]
    if c.get("name"): return c["name"]
    return ""

def kind(addr):
    c = cls.get(hx(addr))
    if not c: return "?"
    return "contract" if c.get("isContract") else "EOA"

def dead(addr):
    c = cls.get(hx(addr), {})
    if c.get("isContract"): return "no"
    if c.get("nonce") == 0: return "**YES (nonce 0)**"
    return "no"

L = []
w = L.append

w("# Rose (Aurora) — Holder & Value-Ownership Map (child2)")
w("")
w(f"Snapshot: LP/stROSE/ROSE holder state at block **{raw['block']}**; VASE state at block **{vase['block']}** "
  f"(fetch block {raw['block']}; RPC `https://mainnet.aurora.dev`, chain 1313161554). All data read-only.")
w("")
w("**Method.** LP-token and stROSE balances netted from genesis `Transfer` logs (all sums reconcile exactly with "
  "`totalSupply`); VASE balances netted from the full set of `LogTransfer` + `LogDeposit` + `LogWithdraw` events "
  "(this BentoBox fork emits deposits/withdrawals without `LogTransfer`; all 7 share sums equal `totals(token).base` "
  "exactly) and top holders verified with `balanceOf(token,addr)`. ROSE holders from the Blockscout holder API "
  "(top 500) and verified on-chain. Admin-fee excess = actual token balance − accounted balance.")
w("")
w("**Prices used (as provided):** DAI/USDC/USDT $1.00, FRAX $0.9904, MAI $0.9962, UST $0.0363 (Aurora DEX; global $0.0053), "
  "RUSD $0.31, WETH $2,507, WBTC $83,108, WNEAR $5.02, ROSE $0.000021. "
  "⚠️ All ROSE/stROSE values scale ×1000 if the intended ROSE price was $0.021. "
  "⚠️ At current pool composition the DEX-implied prices differ materially for UST (≈$0.0050), MAI (≈$0.041) and RUSD (≈$0.022); "
  "using the provided prices overstates metaMAI-LP/RUSD-LP value. See §6.")
w("")

def table(title, rows, header):
    w(f"### {title}")
    w("")
    w("| " + " | ".join(header) + " |")
    w("|" + "|".join(["---"]*len(header)) + "|")
    for r in rows: w("| " + " | ".join(str(x) for x in r) + " |")
    w("")

# ---- LP tokens ----
w("## 1. Curve-style LP tokens — holders")
w("")
w("All five LP tokens reconcile: Σ(holder balances) == `totalSupply` exactly (2021-2024 era activity; no missing mints).")
w("")
LPMAX = {"3pool-LP":20,"metaUST-LP":12,"metaFRAX-LP":12,"metaMAI-LP":10,"RUSD-LP":10}
for sym, t in raw["lp"].items():
    dec = t["decimals"]; supply = int(t["totalSupply"])/10**dec; up = UNIT[sym]
    rows = []
    for v in t["top"][:LPMAX[sym]]:
        amt = int(v["onchain"])/10**dec
        rows.append((v["addr"], fmt_amt(amt, dec), f"{amt/supply*100:.3f}%", kind(v["addr"]),
                     dead(v["addr"]), fmt_usd(amt*up), note(v["addr"])))
    table(f"{sym} — supply {supply:,.4f} ({t['holders']} holders; unit ≈ ${up:,.6f}; total ≈ "
          f"{fmt_usd(supply*up)})", rows, ["holder","amount","% of supply","EOA/C","dead?","USD","notes"])
w("")

# ---- stROSE ----
t = raw["stRose"]; dec = t["decimals"]; supply = int(t["totalSupply"])/10**dec
rows=[]
for v in t["top"][:20]:
    amt = int(v["onchain"])/10**dec
    rows.append((v["addr"], fmt_amt(amt,2), f"{amt/supply*100:.3f}%", kind(v["addr"]), dead(v["addr"]),
                 fmt_usd(amt*UNIT["stROSE"]), note(v["addr"])))
table(f"stROSE vault (0xe23d…e16F) — supply {supply:,.2f}; vault holds {int(strose['roseBalance'])/1e18:,.2f} ROSE "
      f"(backing {int(strose['roseBalance'])/1e18/supply:.6f} ROSE per stROSE); unit ≈ ${UNIT['stROSE']:.8f}; "
      f"total ≈ {fmt_usd(supply*UNIT['stROSE'])}", rows, ["holder","amount","% of supply","EOA/C","dead?","USD","notes"])

# ---- ROSE ----
t = raw["rose"]; supply = int(t["totalSupply"])/1e18
rows=[]
for v in t["top"][:30]:
    amt = int(v["onchain"])/1e18
    rows.append((v["addr"], f"{amt:,.2f}", f"{amt/supply*100:.3f}%", kind(v["addr"]), dead(v["addr"]),
                 fmt_usd(amt*UNIT["ROSE"]), note(v["addr"])))
table(f"ROSE ERC-20 (0xdcd6…f970) — supply {supply:,.0f} ROSE (explorer scan: top 500 holders; unit ${UNIT['ROSE']}; "
      f"total ≈ {fmt_usd(supply*UNIT['ROSE'])})", rows, ["holder","amount","% of supply","EOA/C","dead?","USD","notes"])

# ---- VASE ----
w("## 2. VASE (BentoBox) share holders")
w("")
w("Shares/amounts: `balanceOf` verified for every listed holder. `totals(token)` reconciles exactly (Σ shares == base). "
  "`token.balanceOf(VASE) − totals.elastic == 0` for all 7 tokens → **no unaccounted surplus**.")
w("")
for sym, t in vase["tokens"].items():
    dec = t["decimals"]; bal = int(t["vaseTokenBalance"])/10**dec; up = UNIT[sym]
    rows=[]
    for v in t["top"]:
        amt = int(v["amount_prop"])/10**dec
        rows.append((v["addr"], fmt_amt(amt, dec), f"{amt/bal*100:.3f}%", kind(v["addr"]), dead(v["addr"]),
                     fmt_usd(amt*up), note(v["addr"])))
    table(f"VASE {sym} — VASE balance {bal:,.8f}; unit ${up}; total {fmt_usd(bal*up)}", rows,
          ["holder (share acct)","amount","% of VASE balance","EOA/C","dead?","USD","notes"])
w("")

# ---- admin fee excess ----
w("## 3. Unclaimed admin-fee excess (pool actual balance − accounted balance)")
w("")
w("For the Curve-style pools `balances(i)` excludes accrued admin fees; the difference is claimable **only by the pool owner "
  "(EOA 0x6adf…) via `withdraw_admin_fees`, paid to fee receiver 0xf042…**. For VASE the excess is token balance − `totals.elastic`.")
w("")
rows=[]
tot_ex = 0.0
POOL_LP = {hx("0xff79d5bff48e1c01b722560d6ffdfce9fc883587"): "3pool-LP", hx("0x19cc40283b057d6608c22f1d20f17e16c245642e"): "RUSD"}
for name, p in pools.items():
    for c in p["coins"]:
        ex = int(c["excess"])/10**c["dec"] if c["excess"] is not None else 0
        coin = hx(c["coin"])
        if coin in POOL_LP:
            up = price3 if POOL_LP[coin]=="3pool-LP" else PR["RUSD"]
            usd = ex*up
        else:
            usd = ex*UNIT.get({"0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc":"UST",
                               "0xda2585430fef327ad8ee44af8f1f989a2a91a3d2":"FRAX",
                               "0xdfa46478f9e5ea86d57387849598dbfb2e964b02":"MAI"}.get(coin,""),1.0)
        tot_ex += usd
        rows.append((name, c["coin"][:10]+"…", fmt_amt(ex,c["dec"]), fmt_usd(usd)))
rows.append(("VASE (all 7 tokens)", "—", "0", "$0.00"))
table("Admin-fee excess by pool", rows, ["pool","coin","excess (token units)","USD"])
w(f"Total unclaimed admin-fee excess ≈ **{fmt_usd(tot_ex)}** — owner-claimable only (privileged pot).")
w("")

# ---- splitter ----
w("## 4. Fee receiver 0xf042… (`PaymentSplitter`, ERC-20 variant)")
w("")
sp = fees["splitter"]
w(f"`totalShares()=100`, `totalReleased()` (ETH path) = 0 (nothing ever released in ETH). "
  f"3 payees; ERC-20 releases already executed are shown from `released(token,payee)` calls. "
  f"The splitter still holds **68.5586 UST** (unreleased) plus 1-2 wei dust; "
  f"`release(token,payee)` is callable by anyone (funds go to the payee).")
w("")
rows=[]
for p in sp["payees_raw"]:
    if not p.get("payee"): continue
    a=p["payee"]; tb={k:v for k,v in sp["tokenBalances"][a].items() if v}
    tbstr=", ".join(f"{k} {v/10**({'USDC':6,'USDT':6}.get(k,18)):,.4f}" for k,v in tb.items())
    rows.append((a, p["shares"], f"{p['shares']}%", tbstr or "—"))
table("PaymentSplitter payees (all three are unverified contracts owned by EOA 0x9fb0af8f…)", rows,
      ["payee","shares","pct","current token balances (from §2 data)"])
w("")
w("Cumulative `released()` (token, payee) — the admin fees already distributed historically:")
w("")
rel_rows=[]; tot_rel=0
RELS = {  # hand-collected from released() calls
 "UST": [9345.657082819761851585, 4450.312896580838976945, 1038.406342535529094620],
 "3pool-LP": [11651.935180650896801513, 5548.540562214712762625, 1294.659464516766311279],
 "USDC": [16090.375434, 7662.083540, 1787.819492],
 "USDT": [12884.149640, 6135.309352, 1431.572182],
 "DAI": [5639.355034486842113464, 2685.407159279448625459, 626.595003831871345940],
 "FRAX": [2364.289850492286324119, 1125.852309758231582914, 262.698872276920702679],
}
for tok, vals in RELS.items():
    usd = sum(vals)*UNIT.get(tok, 1.0)
    tot_rel += usd
    rel_rows.append((tok, *[f"{v:,.4f}" for v in vals], fmt_usd(usd)))
table("released(token,payee) cumulative", rel_rows, ["token","payee#1 (63%)","payee#2 (30%)","payee#3 (7%)","USD"])
w(f"Historically distributed admin fees ≈ **{fmt_usd(tot_rel)}** (already paid to team-controlled payee contracts).")
w("")

# ---- protocol-held vs user-held per LP ----
FARM_ADDRS = ["0x52caca9a2d52b27b28767d3649565774a3b991f3","0x56de5e2c25828040330cef45258f3ffbc090777c",
 "0xb9d873cdc15e462f5414ccdfe618a679a47831b4","0x9286d58c1c8d434be809221923cf4575f7a4d058",
 "0x226991aadeefde03bf557ef067da95fc613abffc"]
PROTO_PER_LP = {
 "3pool-LP": FARM_ADDRS[:1]+["0xff84ba26ba108d1de17291f95443aeb0b0dd5ab5","0x296bea2b562888497dd46236f3d3580ff07ff694","0x28d24cd683b67511e9701ff0b71fe890314d8d92",
   "0xa34315f1ef49392387dd143f4578083a9bd33e94","0x79b0a67a4045a7a8dc04b17456f4fe15339cba34","0x8fe44f5cce02d5be44e3446bbc2e8132958d22b8","0x65a761136815b45a9d78d9781d22d47247b49d23",
   "0xd6cb7bb7d63f636d1ca72a1d3ed6f7f67678068a","0xd812cc1fc1e0a56560796c746b1247e2bd4f31f2"],
 "metaUST-LP":[FARM_ADDRS[1]],
 "metaFRAX-LP":[FARM_ADDRS[2]],
 "metaMAI-LP":[FARM_ADDRS[4],"0x19917c01653558c1efa8fcd419fa7bc15b9e9bde"],
 "RUSD-LP":[FARM_ADDRS[3]],
}
user_held = {}
for sym,t in raw["lp"].items():
    dec=t["decimals"]; supply=int(t["totalSupply"])
    prot=0
    for a in PROTO_PER_LP[sym]:
        prot += int(t["allBalances"].get(hx(a),"0"))
    user_held[sym]=(supply-prot)/10**dec
# farm ROSE inventories (on-chain, block latest)
import requests as _rq
_S=_rq.Session()
def _rosebal(a):
    r=_S.post("https://mainnet.aurora.dev",json={"jsonrpc":"2.0","id":1,"method":"eth_call",
        "params":[{"to":"0xdcd6d4e2b3e1d1e1e6fa8c21c8a323dcbecff970","data":"0x70a08231"+a[2:].lower().rjust(64,"0")},"latest"]},timeout=60).json()
    return int(r["result"],16)/1e18
farm_rose = {a: _rosebal(a) for a in FARM_ADDRS}
vest_rose = sum(_rosebal(a) for a in set(VEST.keys()))

# ---- value summary ----
sum_rows=[]; tot_all=0.0
for sym,t in raw["lp"].items():
    supply=int(t["totalSupply"])/10**t["decimals"]; tval=supply*UNIT[sym]
    uval=user_held[sym]*UNIT[sym]; tot_all+=tval
    sum_rows.append((sym, fmt_usd(tval), fmt_usd(tval-uval), fmt_usd(uval)))
vase_total=sum(int(t["vaseTokenBalance"])/10**t["decimals"]*UNIT[sym] for sym,t in vase["tokens"].items())
treasury_vase=(391565.96376041*PR["RUSD"] + 0.40436325*PR["WBTC"] + 1800.45165875*USTP + 0.0)
tot_all+=vase_total
sum_rows.append(("VASE shares (7 tokens)", fmt_usd(vase_total), fmt_usd(treasury_vase)+" treasury EOA", fmt_usd(vase_total-treasury_vase)+" gardens/other"))
strose_total=int(strose["totalSupply"])/1e18*UNIT["stROSE"]; tot_all+=strose_total
sum_rows.append(("stROSE", fmt_usd(strose_total), "—", fmt_usd(strose_total)+" (all user)"))
rose_total=int(raw["rose"]["totalSupply"])/1e18*UNIT["ROSE"]; tot_all+=rose_total
sum_rows.append(("ROSE ERC-20", fmt_usd(rose_total), "vesting/team (see §5b)", "float + dead EOAs"))
sum_rows.append(("Admin-fee excess (unclaimed)", fmt_usd(tot_ex), fmt_usd(tot_ex)+" owner-claimable", "—"))
tot_all+=tot_ex
w("## 5. Ownership interpretation")
w("")
w("### 5.0 Value summary at provided prices")
w("")
w("| asset | total USD | protocol/team-held | user-held |")
w("|---|---|---|---|")
for r in sum_rows: w("| "+" | ".join(r)+" |")
w("")
w(f"**Grand total ≈ {fmt_usd(tot_all)}** at the provided prices. All ROSE/stROSE/ROSE-denominated parts are ×1000 "
  f"if the intended ROSE price was $0.021; metaMAI/RUSD pots shrink if DEX-implied coin prices are used instead. "
  f"Note: family-level overlaps exist (the treasury EOA's VASE RUSD/WBTC/UST ≈ $155.1k is the single largest unclassified pot).")
w("")
w("**(a) User-owned (H-O).**")
w(f"- LP tokens staked in the Rose farms (`0x52caca9a`, `0x56de5e2c`, `0xb9d873cd`, `0x9286d58c`, `0x226991aa`): "
  f"17,444 / 36,075 / 5,718 / 8,758 / 77 LP units ≈ **$27.9k**, withdrawable by stakers (farms are unverified; "
  f"owner 0x6adf… could in principle interfere — flag for the audit).")
w(f"- LP tokens NOT in protocol contracts (directly held by EOAs/other users): "
  f"3pool-LP {user_held['3pool-LP']:,.2f} (${user_held['3pool-LP']*price3:,.0f}), "
  f"metaUST-LP {user_held['metaUST-LP']:,.2f} (${user_held['metaUST-LP']*price_metaUST:,.0f}), "
  f"metaFRAX-LP {user_held['metaFRAX-LP']:,.2f} (${user_held['metaFRAX-LP']*price_metaFRAX:,.0f}), "
  f"metaMAI-LP {user_held['metaMAI-LP']:,.4f} (${user_held['metaMAI-LP']*price_metaMAI:,.2f}), "
  f"RUSD-LP {user_held['RUSD-LP']:,.2f} (${user_held['RUSD-LP']*price_RUSD:,.0f}).")
w(f"- stROSE shares (~$316 at $0.000021; $316k at $0.021): redeemable against the vault's 15.04M ROSE.")
w(f"- VASE shares held by the 6 Garden CDP clones ≈ **$27.7k** (USDC 8.7k + WETH 18.6k + WNEAR/UST/RUSD/WBTC dust): "
  f"user collateral, but encumbered by outstanding market borrows; only net equity is user-owned.")
w(f"- VASE RUSD/WBTC/UST of treasury EOA 0x3820… ≈ **$155.1k** (99.7% of RUSD, 100% of WBTC in VASE): "
  f"on-chain looks like protocol treasury/DAO funds (nonce 297). Classify after key-role review — "
  f"if that key belongs to the team this pot is P/H-O; if it is a user, H-O.")
w("")
w("**(b) Team-owned / privileged (P; team H-O).**")
w(f"- Fee-recipient contracts #1-3 (owner 0x9fb0af8f…): currently hold ≈ $11.65k + $23.3k + $5.4k in stables and 3pool-LP "
  f"(≈$40.4k total; no ROSE). They have already received ≈ $78k of historic admin fees.")
w(f"- ROSE vesting contracts (11 unique, owner 0xf9c4…, beneficiaries are team EOAs incl. 0xf7ad847c (123.9M ROSE) and "
  f"0x25dddc42 (60.8M)): {vest_rose:,.0f} ROSE still inside (${vest_rose*PR['ROSE']:,.0f} at the given price; ×1000 at $0.021), "
  f"fully vested (start Dec-2022, 365-day duration); claimable by beneficiaries.")
w(f"- Farms' ROSE reward inventory: {sum(farm_rose.values()):,.2f} ROSE total (0x52caca9a {farm_rose[FARM_ADDRS[0]]:,.0f}, "
  f"0x9286d58c {farm_rose[FARM_ADDRS[3]]:,.0f}, 0xb9d873cd {farm_rose[FARM_ADDRS[2]]:,.0f} …) — farm-owner-controlled.")
w("- Two team contracts `0xd6cb7bb7`/`0xd812cc1f` (owner 0x6adf…) hold 1,249 3pool-LP ≈ $1.25k.")
w("- Unclaimed pool admin fees ≈ **$2.92k** — owner-only claim."
  " VASE owner 0x0e2a05ca… can whitelist master contracts (BentoBox admin surface; no direct share seizure).")
w("")
w("**(c) Stuck / dead (S).**")
w("- EOA `0xc25ad0b2…` holds **12,155,133.8 ROSE ($255 at $0.000021; $255k at $0.021)**; EOA `0x13890ab8…` holds "
  "400,000 ROSE ($8.40 / $8.4k). Both have **nonce 0 — they have never sent a transaction**. If keys are lost, value is stuck; "
  "if cold allocations, they are unclaimed H-O/P. Prime candidates for the 'unclaimed pot' list.")
w("- 6th Garden market clone `0x6ba5b451…` (same master 0x857050ef…) holds 0.000192 WBTC + 32.27 RUSD in VASE with tiny "
  "outstanding borrows — an additional, previously uncatalogued market; collateral belongs to its position owner.")
w("- Nothing else looks stuck: the PaymentSplitter's 68.56 UST is **claimable by anyone** via `release(UST,payee)` "
  "(funds flow to the payees, not the caller).")
w("")

# pool-implied prices
w("**(d) Potentially attacker-reachable (E-U).** No holder-map pot is directly attacker-extractable: every large balance is "
  "either owner-gated (admin fees, farms' admin functions), user-gated (LP/stROSE/VASE shares), or permissionless-forward with "
  "funds going to a fixed payee (splitter). Any E-U in this protocol will come from logic bugs in the Garden/farm/stROSE/VASE "
  "code (parent's audit), not from idle balances.")
w("")
w("## 6. Sanity / valuation caveats")
w("")
w("Pool composition implies very different marginal prices for the depegged meta-pool coins (A=100, 50/50 intent):")
w("")
w("| pool | coin0 balance | coin1 (3pool-LP) balance | implied coin0 price | provided price |")
w("| --- | --- | --- | --- | --- |")
for name, coin, pidx in [("metaUST","UST",0),("metaFRAX","FRAX",0),("metaMAI","MAI",0),("RUSDpool","RUSD",0)]:
    b0 = accval(name,0); b1 = accval(name,1)
    implied = b1/b0*price3
    given = {"metaUST":PR["UST_aurora"],"metaFRAX":PR["FRAX"],"metaMAI":PR["MAI"],"RUSDpool":PR["RUSD"]}[name]
    w(f"| {name} | {b0:,.4f} {coin} | {b1:,.4f} | ${implied:,.6f} | ${given} |")
w("")
w("Computed LP unit values used in §1: 3pool-LP $1.000003, metaUST-LP $%.6f, metaFRAX-LP $%.6f, metaMAI-LP $%.6f, RUSD-LP $%.6f." %
  (price_metaUST, price_metaFRAX, price_metaMAI, price_RUSD))
w("")
w("Raw artefacts: `child2_holders_raw.json` (LP/stROSE/ROSE), `child2_vase_full.json` + `child2_vase_all_logs.json` (VASE), "
  "`child2_fees.json` (splitter + excess), `child2_classified.json` (EOA/contract/nonce/owner/name), scripts `child2_*.py` "
  "(working fetchers: `child2_fetch_holders2.py`, `child2_fetch_vase.py`, `child2_vase_recount.py`, `child2_fees.py`, "
  "`child2_classify.py`, `child2_report.py`). Stripped logs for the small LPs are `child2_raw_<LP>.json`; the 3pool-LP "
  "raw log (81 MB, 207,239 events) is kept at `/tmp/opencode/child2_raw_3pool-LP.json` only.")

open(f"{A}/child2-holders.md","w").write("\n".join(L)+"\n")
print("written child2-holders.md,", len(L), "lines")
