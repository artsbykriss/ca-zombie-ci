#!/usr/bin/env python3
"""Horizon Protocol live-state dump v2 (threaded single calls). Public RPC.
Output: state-dump.json + printed report."""
import json, time
import rpcmulti as R

A = {
    "SS": "0x344b085489f41fe9a60c6f4b3727b12447d64209",
    "SSET": "0x39989d410137c6eeac8f62369db666836e6cbdba",
    "ER": "0x95a49608f30e8e7ac4adc5565a206e2b874b9763",
    "SCHED": "0x45151b3b1fff51d404e7fcdb2a4067ed50165a55",
    "SNX": "0x0110bcbeb89a43ec47e62d1980e29e0683745ffc",
    "REDEEMER": "0x05af42bfccd27b0db5697c4a34b8d1aa73f4f186",
    "ISSUER": "0x2841052140b4eca63c8ef0bd52c4818eefd5146b",
    "LIQ": "0x2a7b78b705ea48d278d673e80c880d7eb479f44c",
    "FEEPOOL": "0xb80f834ff243cb66a48f2fe9e37064db0cd9d6fd",
    "CM": "0xa7833a8ef8c582aa788a8dbeef4318f877dc64b4",
    "CMS": "0xc7938c1f716e2424915685920f4e8bc4ff7bafb8",
    "DEPOT": "0x9b957b4a90287ebb33faad9c15199ed9c17d114d",
    "DM": "0x6376e713cc5ffcda68bcd28bbaa632201c6b68f4",
    "DC": "0x730a8bcf69dd92e84e85ff21bbbf1ac5f3f5d822",
    "REWD": "0xceb4976140994bfb83f29dfbb80bb2d9fc719dac",
    "ESCROW2": "0x41b9784e0541bf9d5324b3f265cfcd1170490474",
    "ESCROWBRIDGE": "0x53f6de83746d04578de1755e5866819de66d664a",
    "BRIDGE": "0x4ceb5c49d7e8ad212f19b8e5ea4a5f48c01630fb",
    "ZUSD": "0x7f11125a2f22e1dcc19213475267d2dd2f838ff5",
}
STAKING = {
    "PHB_staking": "0xa1771dcfb7822c8853d7e64b86e58f7f1eb5e33e",
    "HZN_staking": "0x67d5a94f444df4bba254645065a4137fc665bf98",
    "HZNBNB_lp_staking": "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8",
    "ZUSDBUSD_lp_staking": "0x5646aa2f9408c7c2ee1dc7db813c8b687a959a85",
}

def enc_name(n): return n.encode().hex().ljust(64, "0")
def enc_addr(a): return a[2:].rjust(64, "0")
def enc_uint(i): return hex(i)[2:].rjust(64, "0")

def main():
    synths = json.load(open("synth-enum.json"))["synths"]
    keys = [v["currencyKey"] for v in synths.values()]
    calls = []
    def add(tag, to, data): calls.append({"tag": tag, "to": to, "data": data})

    add("SS.systemSuspended", A["SS"], "0xc0eee443")
    add("SS.issuanceSuspended", A["SS"], "0x0b3670e1")
    add("SS.exchangeSuspended", A["SS"], "0x962a39b7")
    add("SS.owner", A["SS"], "0x8da5cb5b")
    add("SSET.rateStalePeriod", A["SSET"], "0x0ee4951b")
    add("SSET.exchangeFeeRate", A["SSET"], "0x0f9b4955")
    add("SSET.issuanceRatio", A["SSET"], "0xb410a034")
    add("SSET.owner", A["SSET"], "0x8da5cb5b")
    for k in ["HZN"] + keys:
        add(f"ER.rate:{k}", A["ER"], "0xac82f608" + enc_name(k))
        add(f"ER.updated:{k}", A["ER"], "0xce8480ea" + enc_name(k))
        add(f"ER.stale:{k}", A["ER"], "0x2528f0fe" + enc_name(k))
    add("ER.owner", A["ER"], "0x8da5cb5b")
    for fn, sel in [("lastMintEvent", "0xbe801f01"), ("weekCounter", "0xd3bd4bde"),
                    ("minterReward", "0x9bdd7ac7"), ("mintableSupply", "0xcc5c095c"),
                    ("isMintable", "0x46b45af7"), ("weeksSinceLastIssuance", "0xdbd3a6a7"),
                    ("synthetixProxy", "0xbdd12482"), ("owner", "0x8da5cb5b")]:
        add(f"SCHED.{fn}", A["SCHED"], sel)
    add("SNX.totalSupply", A["SNX"], "0x18160ddd")
    add("SNX.owner", A["SNX"], "0x8da5cb5b")
    add("SNX.nominatedOwner", A["SNX"], "0x53a47bb7")
    add("SNX.bal_REWD", A["SNX"], "0x70a08231" + enc_addr(A["REWD"]))
    add("SNX.bal_ESCROW2", A["SNX"], "0x70a08231" + enc_addr(A["ESCROW2"]))
    for a in synths:
        add(f"SNX.purgeable:{a}", A["SNX"], "0xe054aca2" + enc_addr(a))
        add(f"REDEEMER.redemptions:{a}", A["REDEEMER"], "0x9bc3f269" + enc_addr(a))
    add("REDEEMER.zusdBal", A["ZUSD"], "0x70a08231" + enc_addr(A["REDEEMER"]))
    add("ISSUER.totalIssued_zUSD", A["ISSUER"], "0x83d625d4" + enc_name("zUSD") + enc_uint(0))
    add("ISSUER.totalIssued_zUSD_ex", A["ISSUER"], "0x83d625d4" + enc_name("zUSD") + enc_uint(1))
    add("ISSUER.owner", A["ISSUER"], "0x8da5cb5b")
    for fn, sel in [("flagReward", "0x8074b372"), ("liquidateReward", "0x31e4e030"),
                    ("liquidationRatio", "0x1775765f"), ("liquidationDelay", "0xa0cf7451"),
                    ("liquidationPenalty", "0x23f5589a"), ("selfLiquidationPenalty", "0x1710940c")]:
        add(f"LIQ.{fn}", A["LIQ"], sel)
    add("LIQ.owner", A["LIQ"], "0x8da5cb5b")
    add("FEEPOOL.feePeriodDuration", A["FEEPOOL"], "0x22425fa4")
    for i in range(3):
        add(f"FEEPOOL.recentFeePeriods:{i}", A["FEEPOOL"], "0x3fcd2240" + enc_uint(i))
    add("FEEPOOL.totalFeesAvailable", A["FEEPOOL"], "0x569249d0")
    add("FEEPOOL.totalRewardsAvailable", A["FEEPOOL"], "0x6de813f1")
    add("FEEPOOL.owner", A["FEEPOOL"], "0x8da5cb5b")
    add("CM.paused", A["CM"], "0x5c975abb")
    add("CM.owner", A["CM"], "0x8da5cb5b")
    add("CMS.totalLoans", A["CMS"], "0xcc952b57")
    for fn, sel in [("paused", "0x5c975abb"), ("totalSellableDeposits", "0x4d0387fb"),
                    ("depositStartIndex", "0x6d5ab4a9"), ("depositEndIndex", "0xfd12167f"),
                    ("fundsWallet", "0x2194f3a2"), ("maxEthPurchase", "0xb1338cc4"),
                    ("owner", "0x8da5cb5b")]:
        add(f"DEPOT.{fn}", A["DEPOT"], sel)
    add("DM.isPausedStaking", A["DM"], "0xc65a0ea2")
    add("DM.owner", A["DM"], "0x8da5cb5b")
    add("DC.cachedDebt", A["DC"], "0x05393262")
    add("DC.debtSnapshotStale", A["DC"], "0xf520a2f5")
    add("DC.owner", A["DC"], "0x8da5cb5b")
    for fn, sel in [("distributionsLength", "0x060ca250"), ("authority", "0xbf7e214f"),
                    ("rewardEscrow", "0xa430be6c"), ("feePoolProxy", "0xc9e9cc4d"),
                    ("synthetixProxy", "0xbdd12482"), ("owner", "0x8da5cb5b")]:
        add(f"REWD.{fn}", A["REWD"], sel)
    for i in range(6):
        add(f"REWD.dist:{i}", A["REWD"], "0x4487d3df" + enc_uint(i))
    add("ESCROWBRIDGE.owner", A["ESCROWBRIDGE"], "0x8da5cb5b")
    for name, addr in STAKING.items():
        for fn, sel in [("rewardsToken", "0xd1af0c7d"), ("stakingToken", "0x72f702f3"),
                        ("rewardRate", "0x7b0a47ee"), ("periodFinish", "0xebe2b12b"),
                        ("totalSupply", "0x18160ddd"), ("owner", "0x8da5cb5b"),
                        ("rewardsDistribution", "0x3fc6df6e"), ("withdrawRate", "0x0dcf1417"),
                        ("paused", "0x5c975abb"), ("lockDownDuration", "0x65781329"),
                        ("feeCollector", "0xc415b95c"), ("rewardsDuration", "0x386a9525"),
                        ("lastUpdateTime", "0xc8f33c91")]:
            add(f"{name}.{fn}", addr, sel)

    fns = [(lambda c=c: R.call(c["to"], c["data"])) for c in calls]
    res = R.multi(fns, workers=10)
    out = {c["tag"]: (res[i] if isinstance(res[i], str) else res[i]) for i, c in enumerate(calls)}
    json.dump(out, open("state-dump.json", "w"), indent=1, sort_keys=True)

    def i_(t):
        v = out.get(t)
        return int(v, 16) if isinstance(v, str) and v.startswith("0x") else None
    def a_(t):
        v = out.get(t)
        return "0x" + v[-40:] if isinstance(v, str) and v.startswith("0x") else str(v)

    print("== SystemStatus ==")
    print("systemSuspended =", i_("SS.systemSuspended") != 0,
          "| issuanceSuspended =", i_("SS.issuanceSuspended") != 0,
          "| exchangeSuspended =", i_("SS.exchangeSuspended") != 0)
    print("owner =", a_("SS.owner"))
    print("== SystemSettings ==")
    print("rateStalePeriod =", i_("SSET.rateStalePeriod"), "sec | exchangeFeeRate =",
          i_("SSET.exchangeFeeRate") / 1e18 if i_("SSET.exchangeFeeRate") else None,
          "| issuanceRatio =", i_("SSET.issuanceRatio") / 1e18 if i_("SSET.issuanceRatio") else None)
    print("== ExchangeRates ==")
    now = int(time.time())
    for k in ["HZN"] + keys:
        rr, uu, ss = i_(f"ER.rate:{k}"), i_(f"ER.updated:{k}"), i_(f"ER.stale:{k}")
        age = (now - uu) if uu else None
        print(f"  {k:8s} rate={rr}  updated={uu} (age {age}s)  invalid={ss}")
    print("== SupplySchedule ==")
    for t in ["SCHED.lastMintEvent", "SCHED.weekCounter", "SCHED.minterReward",
              "SCHED.mintableSupply", "SCHED.isMintable", "SCHED.weeksSinceLastIssuance"]:
        print(f"  {t} = {i_(t)}")
    print("  synthetixProxy =", a_("SCHED.synthetixProxy"), "| owner =", a_("SCHED.owner"))
    print("== Synthetix ==")
    print("totalSupply =", i_("SNX.totalSupply") / 1e18 if i_("SNX.totalSupply") else None)
    print("owner =", a_("SNX.owner"), "| nominated =", a_("SNX.nominatedOwner"))
    print("bal RewardsDistribution =", i_("SNX.bal_REWD") / 1e18 if i_("SNX.bal_REWD") else None)
    print("bal RewardEscrowV2 =", i_("SNX.bal_ESCROW2") / 1e18 if i_("SNX.bal_ESCROW2") else None)
    for a in synths:
        if i_(f"SNX.purgeable:{a}"):
            print("  PURGEABLE:", synths[a]["currencyKey"], a)
    print("== SynthRedeemer ==")
    for a in synths:
        v = i_(f"REDEEMER.redemptions:{a}")
        if v:
            print("  redeemable:", synths[a]["currencyKey"], a, v)
    print("  zUSD balance =", i_("REDEEMER.zusdBal") / 1e18 if i_("REDEEMER.zusdBal") else 0)
    print("== Issuer ==")
    print("totalIssued zUSD =", i_("ISSUER.totalIssued_zUSD") / 1e18 if i_("ISSUER.totalIssued_zUSD") else None,
          "| excl =", i_("ISSUER.totalIssued_zUSD_ex") / 1e18 if i_("ISSUER.totalIssued_zUSD_ex") else None)
    print("== Liquidator ==")
    for t in ["LIQ.flagReward", "LIQ.liquidateReward", "LIQ.liquidationRatio",
              "LIQ.liquidationDelay", "LIQ.liquidationPenalty", "LIQ.selfLiquidationPenalty"]:
        print(f"  {t} = {i_(t)}")
    print("== FeePool ==")
    print("feePeriodDuration =", i_("FEEPOOL.feePeriodDuration"))
    for j in range(3):
        print(f"  recentFeePeriods[{j}] =", out.get(f"FEEPOOL.recentFeePeriods:{j}"))
    print("totalFeesAvailable =", i_("FEEPOOL.totalFeesAvailable") / 1e18 if i_("FEEPOOL.totalFeesAvailable") else 0)
    print("totalRewardsAvailable =", i_("FEEPOOL.totalRewardsAvailable") / 1e18 if i_("FEEPOOL.totalRewardsAvailable") else 0)
    print("== CollateralManager ==")
    print("paused =", i_("CM.paused") != 0, "| totalLoans =", i_("CMS.totalLoans"))
    print("== Depot ==")
    print("paused =", i_("DEPOT.paused") != 0, "| totalSellableDeposits =",
          i_("DEPOT.totalSellableDeposits") / 1e18 if i_("DEPOT.totalSellableDeposits") else 0,
          "| idx", i_("DEPOT.depositStartIndex"), "->", i_("DEPOT.depositEndIndex"))
    print("== DappMaintenance ==")
    print("isPausedStaking =", i_("DM.isPausedStaking") != 0)
    print("== DebtCache ==")
    print("cachedDebt =", i_("DC.cachedDebt") / 1e18 if i_("DC.cachedDebt") else None,
          "| stale =", i_("DC.debtSnapshotStale") != 0)
    print("== RewardsDistribution ==")
    print("len =", i_("REWD.distributionsLength"), "| authority =", a_("REWD.authority"),
          "| escrow =", a_("REWD.rewardEscrow"), "| feePool =", a_("REWD.feePoolProxy"))
    for j in range(6):
        v = out.get(f"REWD.dist:{j}")
        if isinstance(v, str) and v != "0x" + "0" * 64:
            print(f"  dist[{j}] = {v}")
    print("== Staking ==")
    for name in STAKING:
        print(f"-- {name}")
        for fn in ["rewardsToken", "stakingToken", "rewardRate", "periodFinish", "totalSupply",
                   "owner", "rewardsDistribution", "withdrawRate", "paused", "lockDownDuration",
                   "feeCollector", "rewardsDuration", "lastUpdateTime"]:
            v = out.get(f"{name}.{fn}")
            if isinstance(v, str):
                if fn in ("rewardsToken", "stakingToken", "owner", "rewardsDistribution", "feeCollector"):
                    print(f"   {fn} = 0x{v[-40:]}")
                else:
                    print(f"   {fn} = {int(v,16)}")

if __name__ == "__main__":
    main()
