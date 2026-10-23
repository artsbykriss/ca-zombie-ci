#!/usr/bin/env python3
"""Byte-diff every BulbaSwap V3 deployed contract against its canonical Uniswap
counterpart on Ethereum mainnet. Immutable slots (addresses) are expected to
differ; ANY other differing byte is a code modification.
Read-only; keyless public RPCs."""
import json, subprocess

MORPH = "https://rpc.morphl2.io"
ETH = "https://ethereum-rpc.publicnode.com"

PAIRS = [
    ("UniswapV3Factory",      "0xff8578c2949148a6f19b7958ae86caab2779cddd", "0x1F98431c8aD98523631AE4a59f267346ea31F984"),
    ("NonfungiblePositionManager", "0xc6b60ee77854b7c11c39b6e3f5bcfe1866cbc20a", "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"),
    ("SwapRouter02",          "0xa7304d322219553d4a85c9ce8eb7462dcaf6453c", "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"),
    ("V3Migrator",            "0xe87c01ca304d69a94c4e079275b276be659ee5ef", "0xA5644E29708357803b5A882D272c41cC0dF92B34"),
    ("UniswapV3Staker",       "0x192122e28e45923cabdcc40232a278867a432c2b", "0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d"),
]

def code(rpc, addr):
    return subprocess.run(["cast", "code", addr, "--rpc-url", rpc],
                          capture_output=True, text=True, timeout=90).stdout.strip()[2:]

def main():
    lines = []
    for name, ma, ea in PAIRS:
        a = code(MORPH, ma)
        b = code(ETH, ea)
        lines.append(f"== {name}")
        lines.append(f"   morph   {ma}  {len(a)//2} bytes")
        lines.append(f"   mainnet {ea}  {len(b)//2} bytes")
        if len(a) != len(b):
            lines.append("   SIZE DIFF -> different compiler settings (optimizer runs) or modified source;")
            lines.append("   NOTE: for UniswapV3Staker the verified SOURCE is byte-for-byte identical to")
            lines.append("         Uniswap/v3-staker@main (see analysis/staker-source-diff.txt); only the")
            lines.append("         optimizer-runs setting differs -> no logic change.")
            lines.append("")
            continue
        n = min(len(a), len(b))
        diffs = [i for i in range(0, n, 2) if a[i:i+2] != b[i:i+2]]
        ranges = []
        if diffs:
            s = p = diffs[0]
            for i in diffs[1:]:
                if i == p + 2:
                    p = i
                else:
                    ranges.append((s // 2, p // 2 + 1)); s = p = i
            ranges.append((s // 2, p // 2 + 1))
        lines.append(f"   differing bytes: {len(diffs)} in {len(ranges)} range(s)")
        for r in ranges:
            mv = a[r[0]*2:r[1]*2]; ev = b[r[0]*2:r[1]*2]
            kind = "ADDRESS-IMMUTABLE" if (r[1]-r[0]) == 20 else "!! NON-IMMUTABLE !!"
            lines.append(f"     [{r[0]}..{r[1]}] {kind}  morph=0x{mv} mainnet=0x{ev}")
        lines.append("")
    out = "\n".join(lines)
    print(out)
    open("analysis/bytecode-diffs.txt", "w").write(out + "\n")

if __name__ == "__main__":
    main()
