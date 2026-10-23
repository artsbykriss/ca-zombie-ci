#!/usr/bin/env python3
"""Read-only live-state dump for the CapyFi access-control angle.
Uses ONLY a keyless public RPC. No secrets. Parallelised cast calls.
Writes analysis/live-state.json next to this script's parent."""
import subprocess, sys, json, concurrent.futures as cf, os

RPC = os.environ.get("PUBLIC_RPC", "https://ethereum-rpc.publicnode.com")
UNIT = "0x0b9af1fd73885aD52680A1aeAa7A3f17AC702afA"
ORA  = "0xfbA2712d3bbcf32c6E0178a21955b61FE1FF424A"
WL   = "0x302a893B1AC44fed29Cdf3e3a0a083d1Df3ce54E"
WLR  = "0x8429d542926e6695b59ac6fbdcd9b37e8b1aeb757afab06ab60b1bb5878c3b49"

markets = {
 "caUXD": "0x98Ac8AC56d833bD69d34F909Ac15226772FAc9aa",
 "caETH_legacy": "0xbaA6bc4E24686d710B9318B49b0Bb16ec7C46bFA",
 "caLAC": "0x0568F6cb5A0E84FACa107D02f81ddEB1803f3B50",
 "caWBTC": "0xDa5928d59ECE82808Af2cbBE4f2872FeA8E12CD6",
 "caUSDT": "0x0f864A3e50D1070adDE5100fd848446C0567362B",
 "caUSDC": "0xc3aD34De18B59A24BD0877e454Fb924181F09C8f",
 "caETH": "0x37DE57183491Fa9745d8Fa5DCd950f0c3a4645c9",
 "caRPC": "0xF61159B4a0EE5b1615c9Afb3dA38111043344c32",
 "caWARS": "0xf80eeec09f417Fa7FCc4A848Ef03af9dF2658d7B",
 "caWBRL": "0x93d9DdEeBf3B5DBF7D7dFC04D3804Ce5450987C8",
 "caWMXN": "0x59B8022F431C7f00eF4894895c2F6bB1986f9acC",
 "caWCOP": "0xe9b369ee5a75a71d2981E5Fcb4b5011293Cf8fdB",
 "caUSDAR": "0x2437E33631327b2437170972f753E15Cb9Fd1806",
}

def call(addr, sig, *args):
    cmd = ["cast", "call", addr, sig, *[str(a) for a in args], "--rpc-url", RPC]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return r.stdout.strip().split()[0] if r.stdout.strip() else None

jobs = []  # (key, addr, sig, args)
for n, a in markets.items():
    for f, sig in [("cash_raw","getCash()(uint256)"),("totalBorrows_raw","totalBorrows()(uint256)"),
                   ("totalReserves_raw","totalReserves()(uint256)"),("totalSupply_raw","totalSupply()(uint256)"),
                   ("exchangeRate","exchangeRateStored()(uint256)"),("whitelist","whitelist()(address)"),
                   ("ctoken_decimals","decimals()(uint8)")]:
        jobs.append(((n,f), a, sig, ()))
    jobs.append(((n,"oracle_price"), ORA, "getUnderlyingPrice(address)(uint256)", (a,)))
    jobs.append(((n,"mintPaused"), UNIT, "mintGuardianPaused(address)(bool)", (a,)))
    jobs.append(((n,"borrowPaused"), UNIT, "borrowGuardianPaused(address)(bool)", (a,)))
    jobs.append(((n,"markets_tuple"), UNIT, "markets(address)(bool,uint256,uint256)", (a,)))

extra = {
 ("comptroller","admin"): (UNIT,"admin()(address)",()),
 ("comptroller","oracle"): (UNIT,"oracle()(address)",()),
 ("comptroller","closeFactor"): (UNIT,"closeFactorMantissa()(uint256)",()),
 ("comptroller","liqIncentive"): (UNIT,"liquidationIncentiveMantissa()(uint256)",()),
 ("comptroller","pauseGuardian"): (UNIT,"pauseGuardian()(address)",()),
 ("comptroller","borrowCapGuardian"): (UNIT,"borrowCapGuardian()(address)",()),
 ("whitelist","active"): (WL,"isActive()(bool)",()),
 ("whitelist","member0"): (WL,"getRoleMember(bytes32,uint256)(address)",(WLR,0)),
 ("whitelist","member1"): (WL,"getRoleMember(bytes32,uint256)(address)",(WLR,1)),
 ("whitelist","member2"): (WL,"getRoleMember(bytes32,uint256)(address)",(WLR,2)),
 ("bad_debt_7cca","liquidity"): (UNIT,"getAccountLiquidity(address)(uint256,uint256,uint256)",("0x7cca923387a3ce8d1f36354f8385aa9045798d51",)),
 ("bad_debt_492d","liquidity"): (UNIT,"getAccountLiquidity(address)(uint256,uint256,uint256)",("0x492d255234c83f2ddc5aa904d8a9db6743e9f046",)),
}
for k,(a,s,ar) in extra.items():
    jobs.append((k,a,s,ar))

res = {}
with cf.ThreadPoolExecutor(max_workers=12) as ex:
    futs = {ex.submit(call, a, s, *ar): k for k,a,s,ar in jobs}
    for fu in cf.as_completed(futs):
        res[futs[fu]] = fu.result()

out = {"block": int(call(UNIT,"getBlockNumber()(uint256)") or 0), "rpc": "publicnode (keyless)",
       "markets": {}, "comptroller": {}, "whitelist": {}, "bad_debt": {}}
for n in markets:
    out["markets"][n] = {"addr": markets[n]}
    for f in ["cash_raw","totalBorrows_raw","totalReserves_raw","totalSupply_raw","exchangeRate",
              "whitelist","ctoken_decimals","oracle_price","mintPaused","borrowPaused","markets_tuple"]:
        out["markets"][n][f] = res.get((n,f))
for (grp,f) in [("comptroller","admin"),("comptroller","oracle"),("comptroller","closeFactor"),
                ("comptroller","liqIncentive"),("comptroller","pauseGuardian"),("comptroller","borrowCapGuardian")]:
    out["comptroller"][f] = res.get((grp,f))
for f in ["active","member0","member1","member2"]:
    out["whitelist"][f] = res.get(("whitelist",f))
for f in ["liquidity"]:
    out["bad_debt"]["7cca"] = res.get(("bad_debt_7cca",f))
    out["bad_debt"]["492d"] = res.get(("bad_debt_492d",f))

p = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "analysis", "live-state.json")
with open(p, "w") as fh:
    json.dump(out, fh, indent=1)
print("wrote", p, "block", out["block"])
