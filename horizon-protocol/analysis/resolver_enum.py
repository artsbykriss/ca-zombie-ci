#!/usr/bin/env python3
"""Enumerate Horizon Protocol AddressResolver entries by candidate name.
Public RPC only (rotating). Writes resolver-enum.json (no secrets)."""
import json, sys, time, urllib.request, os

RPCS = [
    "https://bsc-rpc.publicnode.com",
    "https://bsc.publicnode.com",
    "https://bsc-mainnet.public.blastapi.io",
    "https://bsc-dataseed1.ninicoin.io",
]
RESOLVER = "0xF505bfdB669412ef8543cC76798F497D011F2300"
SEL_GETADDRESS = "0x21f8a721"  # getAddress(bytes32)

def enc_name(name: str) -> str:
    b = name.encode()
    assert len(b) <= 32
    return b.hex().ljust(64, "0")

def rpc_call(to, data, retries=6):
    last = None
    for i in range(retries):
        rpc = RPCS[i % len(RPCS)]
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                           "params": [{"to": to, "data": data}, "latest"]}).encode()
        try:
            req = urllib.request.Request(rpc, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                d = json.loads(r.read())
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = e
        time.sleep(1 + i)
    raise RuntimeError(f"rpc failed: {last}")

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

def main():
    out = {}
    for n in NAMES:
        r = rpc_call(RESOLVER, SEL_GETADDRESS + enc_name(n))
        if r and r != "0x" + "0" * 64:
            out[n] = "0x" + r[-40:]
            print(f"{n:28s} -> {out[n]}", flush=True)
        time.sleep(0.15)
    with open("resolver-enum.json", "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    print(f"\n{len(out)}/{len(NAMES)} names resolved")

if __name__ == "__main__":
    main()
