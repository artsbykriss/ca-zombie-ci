#!/usr/bin/env python3
"""Fetch missing sources (retry-friendly). Reads sources-index.json, retries failures + extra addrs."""
import json, os, time, urllib.request

KEY = os.environ["ETHERSCANV2_API_KEY"]
OUT = "sources"
os.makedirs(OUT, exist_ok=True)

EXTRA = [
    "0x2841052140b4eca63c8ef0bd52c4818eefd5146b",  # Issuer
    "0x4ceb5c49d7e8ad212f19b8e5ea4a5f48c01630fb",  # SynthetixBridgeToOptimism
    "0x53f6de83746d04578de1755e5866819de66d664a",  # SynthetixBridgeEscrow
    "0x5bcdb40000347ad047008c9295fedbeda7487ad2",  # Liquidations
    "0x6376e713cc5ffcda68bcd28bbaa632201c6b68f4",  # DappMaintenance
    "0x691d8959adc7c9ba04c92d3211082d4a0579f54a",  # FeePoolEternalStorage
    "0x730a8bcf69dd92e84e85ff21bbbf1ac5f3f5d822",  # DebtCache
    "0x867e8a6f1238780fcc0a3d06e59bbf3d52f6b05b",  # Exchanger
    "0x95a49608f30e8e7ac4adc5565a206e2b874b9763",  # ExchangeRates
    "0x9657a0fd98e88464e1159d98b517a4945dbfbfc8",  # DelegateApprovals
    "0x9b957b4a90287ebb33faad9c15199ed9c17d114d",  # Depot
    "0xa7833a8ef8c582aa788a8dbeef4318f877dc64b4",  # CollateralManager
    "0xade751b28a4b5b2d8342719521a2ed2bd621090f",  # CollateralUtil
    "0xb80f834ff243cb66a48f2fe9e37064db0cd9d6fd",  # FeePool
    "0xc7938c1f716e2424915685920f4e8bc4ff7bafb8",  # CollateralManagerState
    "0xceb4976140994bfb83f29dfbb80bb2d9fc719dac",  # RewardsDistribution
    "0xde6446197cd1ae02e1c5b7191a626fb0c1757377",  # FlexibleStorage
    "0xe21e39c383abdce3edf13b7233ad1ad5fee42099",  # RewardEscrowV2Frozen
    "0xf1f5f738a11197ca8065435e0f19816e00ea5407",  # ExchangeState
    "0xf71eccf3821737ef005c662c235215f9d89a956b",  # SynthetixState
    "0xa1771dcfb7822c8853d7e64b86e58f7f1eb5e33e",  # StakingRewards PHB
    "0x67d5a94f444df4bba254645065a4137fc665bf98",  # StakingRewards HZN
    "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8",  # StakingRewards HZN-BNB LP
    "0x5646aa2f9408c7c2ee1dc7db813c8b687a959a85",  # StakingRewards zUSD-BUSD LP
    "0xdc9a574b9b341d4a98ce29005b614e1e27430e74",  # Cake LP
    "0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf",  # Cake LP
]

def already(a):
    import glob
    return len(glob.glob(f"{OUT}/{a}-*")) > 0

def fetch(a):
    url = ("https://api.etherscan.io/v2/api?chainid=56&module=contract&action=getsourcecode"
           f"&address={a}&apikey={KEY}")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=25) as r:
        d = json.loads(r.read())
    if d.get("status") != "1":
        return {"addr": a, "error": d.get("result")}
    x = d["result"][0]
    name = (x.get("ContractName") or "Unknown").replace("/", "_")
    src = x.get("SourceCode") or ""
    abi = x.get("ABI") or "[]"
    if src:
        with open(f"{OUT}/{a}-{name}.sol", "w") as f:
            f.write(src)
    if abi and abi != "Contract source code not verified":
        with open(f"abis/{a}-{name}.json", "w") as f:
            f.write(abi)
    return {"addr": a, "name": name, "src_len": len(src), "proxy": x.get("Proxy"),
            "impl": x.get("Implementation")}

todo = [a for a in EXTRA if not already(a)]
print("todo:", len(todo))
for a in todo:
    for attempt in range(3):
        try:
            r = fetch(a)
            print(json.dumps(r), flush=True)
            break
        except Exception as e:
            print(json.dumps({"addr": a, "attempt": attempt, "error": str(e)}), flush=True)
            time.sleep(3)
    time.sleep(0.3)
print("done")
