#!/usr/bin/env python3
"""Extract and split concatenated base58 pubkeys from ELF strings; identify known program IDs."""
import re
ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPH.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    pad=len(s)-len(s.lstrip('1'))
    return b'\x00'*pad+b
def b58e(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,rem=divmod(n,58); s=ALPH[rem]+s
    for by in b:
        if by==0: s='1'+s
        else: break
    return s or '1'

KNOWN = {
 "11111111111111111111111111111111":"System Program",
 "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA":"SPL Token",
 "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb":"Token-2022",
 "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL":"ATA Program",
 "BPFLoaderUpgradeab1e11111111111111111111111":"BPF Loader Upgradeable",
 "ComputeBudget111111111111111111111111111111":"ComputeBudget",
 "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8":"Raydium AMM v4",
 "srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX":"Serum v3 DEX",
 "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin":"Serum v3 (alt)",
 "PythC7GKct16toaWJKPFC9bZ1prNyb3DYbC2wbKuJ4s":"Pyth old?",
 "FsJ3A3u2vn5cTVofAjvy6y5kwABJAqYWpe4975bi2epH":"Pyth legacy",
 "H6ARHf6YXhGYeQfUzQNGk6rDNnLBQKrenN712K4AQJEG":"Pyth SOL/USD price acct (old)",
 "JBu1AL4obBcCMqKBBxWQxhHsjJ1uUbyBMBMWryeCy4F":"Pyth?",
 "Dpw1EAVrSB1ibqooin1ed8v1wyeBvjJZWnAydmV2Lrcz":"Pyth?",
 "So11111111111111111111111111111111111111112":"wSOL",
 "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":"USDC",
 "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB":"USDT",
 "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So":"mSOL",
 "7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj":"stSOL",
 "J1toso1uCk3RLmjorhTtrVwY9HJ7X8V9yYac6Y7kGCPn":"JitoSOL",
 "Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk":"01 Program (zo)",
 "Zo1ThtSHMh9tZGECwBDL81WJRL6s3QTHf733Tyko7KQ":"ZeroOne(01.xyz)",
 "ZDx8a8jBqGmJyxi1whFxxCo5vG6Q9t4hTzW2GSixMKK":"01 Dex",
 "L2TExMFKdjpN9kozasaurPirfHy9P8sbXoAN1qA3S95":"L2TEx program",
 "HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ":"01 USDC vault PDA",
 "71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv":"zo global state (config.rs)",
 "Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt":"zo vault config?",
 "6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon":"zo acct[2]",
 "3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp":"vault USDC token acct",
 "DtCyZQSP9AjdasXJPs5m5Q8dovo73UJvUG1ieosofDwX":"zo upgrade authority",
}

txt=open("analysis/01_program_strings.txt").read()
runs=set(re.findall(r'[1-9A-HJ-NP-Za-km-z]{30,}', txt))
found={}
for run in runs:
    # try to split into 32-byte pubkeys greedily
    parts=[]
    i=0
    while i < len(run):
        matched=False
        for L in (44,43,42,41,40,39,38,37,36,35,34,33,32):
            if i+L<=len(run):
                try:
                    b=b58d(run[i:i+L])
                except Exception:
                    continue
                if len(b)==32:
                    parts.append(run[i:i+L]); i+=L; matched=True; break
        if not matched:
            break
    for p in parts:
        found.setdefault(p, run)
print(f"decoded {len(found)} pubkey candidates:")
for p in sorted(found):
    label=KNOWN.get(p)
    print(f"  {p}  {'== '+label if label else ''}")
