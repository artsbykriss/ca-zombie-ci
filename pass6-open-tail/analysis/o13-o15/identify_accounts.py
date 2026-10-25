#!/usr/bin/env python3
"""Identify account types per program by 8-byte discriminator; fetch llama prices."""
import json, hashlib, urllib.request
from collections import Counter
from sol_rpc import get_program_accounts

def adisc(name):
    return hashlib.sha256(("account:" + name).encode()).digest()[:8]

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent":"audit/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())

# Candidate account names
CAND = {
 "O13": ["Vault","Index","Manager","Treasury","PlatformFee","Deposit","Withdrawal","VaultConfig",
         "IndexState","GlobalConfig","Config","User","DepositRecord","WithdrawalRecord","VaultAccount",
         "IndexConfig","ManagerAccount","TreasuryAccount","FeeAccount","DepositAccount","WithdrawalAccount"],
 "O14": ["GlobalConfig","WrapperVault","WrapperConfig","ProtocolData","Vault","Config","Wrapper","CreatorFees"],
 "O15": ["MarginfiGroup","MarginfiAccount","Bank","Group","LendingPool","FeeState","StakedSettings",
         "PairwiseRiskRegistry","LpWitnessCache","LpWitnessStaging","GlobalFeeState","BankMetadata"],
}

PROGS = {"O13":("3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",[246,74,1064]),
         "O14":("WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",[558,150]),
         "O15":("zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ",[2312,1912,520,59956,264,7175,1064])}

# build disc map
dmap = {}
for k,names in CAND.items():
    for n in names:
        dmap[adisc(n).hex()] = f"{k}:{n}"

out = {}
for k,(pid,sizes) in PROGS.items():
    print(f"\n=== {k} {pid} ===")
    out[k] = {}
    for size in sizes:
        r = get_program_accounts(pid, filters=[{"dataSize":size}],
                                 encoding="base64", dataSlice={"offset":0,"length":8})
        res = r.get("result") or []
        c = Counter()
        for acc in res:
            d = acc["account"]["data"]
            b = d[0] if isinstance(d,list) else d
            import base64
            raw = base64.b64decode(b) if b else b""
            disc = raw[:8].hex() if len(raw)>=8 else "(short)"
            c[disc] += 1
        out[k][size] = {"count":len(res), "discs":dict(c)}
        for disc,cnt in c.most_common():
            print(f"  size={size:6d} n={cnt:5d} disc={disc} -> {dmap.get(disc,'?')}")
        # sample pubkey
        if res:
            print(f"    sample pubkey: {res[0]['pubkey']}")

with open("account_types.json","w") as f:
    json.dump(out,f,indent=2)

print("\n=== LLAMA PRICES ===")
mints = {
 "USDC":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
 "SOL":"So11111111111111111111111111111111111111112",
 "USDT":"Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
 "JitoSOL":"J1toso1uCk3RLmjorhTtrVwY9HJ7X8V9yYac6Y7kGCPn",
}
try:
    url = "https://coins.llama.fi/prices/current/" + ",".join(f"solana:{m}" for m in mints.values())
    pj = fetch(url)
    for sym,m in mints.items():
        key=f"solana:{m}"
        print(sym, m, pj.get("coins",{}).get(key))
except Exception as e:
    print("price fetch failed", e)
