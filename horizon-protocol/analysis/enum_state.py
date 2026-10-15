#!/usr/bin/env python3
"""Horizon Protocol (BSC) live-state enumeration. Public RPC only, no secrets.
Outputs synth-enum.json and resolver-enum.json in cwd."""
import json, time
import bsc

SNX = "0x0110bcbeb89a43ec47e62d1980e29e0683745ffc"
RESOLVER = "0xF505bfdB669412ef8543cC76798F497D011F2300"

def enc_name(n):
    b = n.encode()
    return b.hex().ljust(64, "0")

def enc_uint(i):
    return hex(i)[2:].rjust(64, "0")

def main():
    # 1) synth count
    calls = [{"to": SNX, "data": "0xdbf63340", "tag": "count"}]
    r = bsc.batch(calls)
    cnt = int(r[0], 16)
    print("availableSynthCount =", cnt)

    # 2) synth addresses
    calls = [{"to": SNX, "data": "0x835e119c" + enc_uint(i), "tag": f"s{i}"} for i in range(cnt)]
    r = bsc.batch(calls)
    synths = []
    for i in range(cnt):
        addr = "0x" + r[i][-40:]
        synths.append(addr)
    print("synths:", synths)

    # 3) per-synth: currencyKey, symbol, totalSupply
    calls = []
    tags = []
    for a in synths:
        calls.append({"to": a, "data": "0xdbd06c85", "tag": f"key:{a}"})
        calls.append({"to": a, "data": "0x18160ddd", "tag": f"supply:{a}"})
    r = bsc.batch(calls)
    out = {}
    for i, a in enumerate(synths):
        key = r[2*i]
        sup = r[2*i+1]
        k = bytes.fromhex(key[2:]).decode("utf8", "ignore").strip("\x00") if isinstance(key, str) and key.startswith("0x") else key
        s = int(sup, 16) if isinstance(sup, str) and sup.startswith("0x") else sup
        out[a] = {"currencyKey": k, "totalSupply_wei": str(s)}
        print(a, k, s)
    json.dump({"count": cnt, "synths": out}, open("synth-enum.json", "w"), indent=1)

    # 4) resolver enumeration (full candidate list)
    NAMES = """Synthetix SynthetixState SynthetixEscrow SynthetixBridgeToOptimism SynthetixBridgeToBase
ExchangeRates Exchanger ExchangeState Issuer FeePool FeePoolState FeePoolEternalStorage
SystemSettings SystemStatus SupplySchedule RewardEscrow RewardEscrowV2 RewardEscrowV2Frozen
RewardsDistribution Liquidator LiquidatorRewards Liquidations DebtCache DebtMigratorOnEthereum
DebtMigratorOnOptimism Depot DappMaintenance EtherCollateral EtherCollateralsUSD CollateralManager
CollateralManagerState CollateralUtil SynthRedeemer TokenState ProxyERC20 LegacyMarket V3LegacyMarket
SynthsUSD SynthsBNB SynthsBTC SynthsETH SynthsLINK SynthsDOT SynthsADA SynthsXRP SynthsLTC SynthsBCH
SynthsXTZ SynthsEOS SynthsTRX SynthsUNI SynthsAAVE SynthsMKR SynthsCOMP SynthsDEFI SynthsFIL SynthsDASH
SynthsZEC SynthsETC SynthsCAKE SynthsXAU SynthsXAG SynthsEUR SynthsJPY SynthsAUD SynthsGBP
SynthsCHF SynthsINR SynthsKRW SynthsTRY SynthsBRL SynthsRUB SynthsPLN SynthsSEK SynthsNOK SynthsILS
SynthsNZD SynthsSGD SynthsHKD SynthsCNY SynthsPHP SynthsIDR SynthsMYR SynthsTHB SynthsVND SynthsZAR
zUSD zBNB zBTC zETH zLINK zDOT zADA zXRP zLTC zBCH zXTZ zEOS zTRX zUNI zAAVE zMKR zCOMP zDEFI zFIL
DelegateApprovals FlexibleStorage EscrowChecker AtomicSwap PurgeableSynth SynthRouter MultiCollateral
HorizonProtocol HZN PHB PhoenixDao BridgeEscrow SynthetixBridgeEscrow
BaseSynthetixBridge OptimismSynthetixBridge SynthUtil DebtMigrator
FeePoolStateL2 ExchangerL2 IssuerL2 FeePoolL2 RewardEscrowL2
""".split()
    calls = [{"to": RESOLVER, "data": "0x21f8a721" + enc_name(n), "tag": n} for n in NAMES]
    r = bsc.batch(calls)
    res = {}
    for i, n in enumerate(NAMES):
        v = r[i]
        if isinstance(v, str) and v.startswith("0x") and v != "0x" + "0"*64:
            res[n] = "0x" + v[-40:]
    json.dump(res, open("resolver-enum.json", "w"), indent=1, sort_keys=True)
    print("resolver names:", len(res))
    for k, v in sorted(res.items()):
        print(f"  {k:26s} {v}")

if __name__ == "__main__":
    main()
