#!/usr/bin/env python3
"""L2-27 live screen: residual balances of exploited BSC victims (read-only)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr

CHAIN = "bsc"

# (label, token address or None for native, holder address)
TARGETS = [
    # LPBonus incident
    ("LPBonus contract: MSN bal", "0xd8b3ef86afce18edba91fed481abe22f173597c1", "0x52272524a22f941f5489c1233732797314bb054b"),
    ("LPBonus contract: FIST bal", "0xc9882dEF23bc42D53895b8361D0b1EDC7570Bc6A", "0x52272524a22f941f5489c1233732797314bb054b"),
    ("LPBonus contract: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0x52272524a22f941f5489c1233732797314bb054b"),
    ("LPBonus contract: native", None, "0x52272524a22f941f5489c1233732797314bb054b"),
    ("MSN token: FIST bal", "0xc9882dEF23bc42D53895b8361D0b1EDC7570Bc6A", "0xd8b3ef86afce18edba91fed481abe22f173597c1"),
    ("MSN token: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0xd8b3ef86afce18edba91fed481abe22f173597c1"),
    # PositionManager incident
    ("PositionManager: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0x7cedB2e5d7791c7D46c5C9d35EaC4775bc887F00"),
    ("PositionManager: BTCB bal", "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", "0x7cedB2e5d7791c7D46c5C9d35EaC4775bc887F00"),
    ("PositionManager: native", None, "0x7cedB2e5d7791c7D46c5C9d35EaC4775bc887F00"),
    # GDC incident
    ("GDC token: WBNB bal", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822"),
    ("GDC token: native", None, "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822"),
    ("GDC pair: WBNB bal", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c"),
    ("GDC pair: GDC bal", "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822", "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c"),
    # BeatXswap incident
    ("BeatXswap vest1: BTX bal", "0xAa242a47F4cC074E59cbC7D65309B1F21202AaA3", "0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D"),
    ("BeatXswap vest1: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0x1e647FAADb05f2124BFCcFC003EDc06D1A90bf5D"),
    ("BeatXswap vest2: BTX bal", "0xAa242a47F4cC074E59cbC7D65309B1F21202AaA3", "0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F"),
    ("BeatXswap vest2: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0x9a7A92240FBAc4030b65A6E61239928d6Bcc716F"),
    ("BTX token: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0xAa242a47F4cC074E59cbC7D65309B1F21202AaA3"),
    # DHC incident
    ("DHC proxy: DHC token bal", "0x743F15f4d2481774d970f286f0EbAD9C3Daed6E9", "0xe2a047aaDbac51b0116Af1cE91EbdAe4b4202094"),
    ("DHC proxy: USDT bal", "0x55d398326f99059fF775485246999027B3197955", "0xe2a047aaDbac51b0116Af1cE91EbdAe4b4202094"),
    ("DHC proxy: native", None, "0xe2a047aaDbac51b0116Af1cE91EbdAe4b4202094"),
    # Unifi incident
    ("Unifi mgr: UP bal", "0x36F20660b9947929Ab3edd8727B5Af60260333A7", "0x5D8aA15505aFEc01Bab0dE21F9377673B5246EAE"),
    ("Unifi mgr: WBNB bal", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0x5D8aA15505aFEc01Bab0dE21F9377673B5246EAE"),
    ("Unifi mgr: native", None, "0x5D8aA15505aFEc01Bab0dE21F9377673B5246EAE"),
    ("Unifi redeemer: UP bal", "0x36F20660b9947929Ab3edd8727B5Af60260333A7", "0x1b8c6808b48C7A9b6997b6dAEF6401307B2B419A"),
    ("Unifi redeemer: WBNB bal", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0x1b8c6808b48C7A9b6997b6dAEF6401307B2B419A"),
    ("Unifi redeemer: native", None, "0x1b8c6808b48C7A9b6997b6dAEF6401307B2B419A"),
]

BAL_SEL = sel("balanceOf(address)")

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("BSC block:", int(blk, 16) if isinstance(blk, str) else blk)
    calls, meta = [], []
    for label, token, holder in TARGETS:
        if token is None:
            calls.append(("eth_getBalance", [holder, "latest"]))
        else:
            calls.append(("eth_call", [{"to": token, "data": BAL_SEL + enc_addr(holder)}, "latest"]))
        meta.append((label, token, holder))
    res = batch(CHAIN, calls, chunk=10)
    out = []
    for (label, token, holder), r in zip(meta, res):
        if isinstance(r, str) and r.startswith("0x"):
            val = int(r, 16)
        else:
            val = None
        out.append({"label": label, "holder": holder, "token": token, "raw": r if val is None else str(val)})
        print(f"{label:38s} {holder[:10]}.. raw={out[-1]['raw']}")
    json.dump({"block": int(blk, 16), "balances": out}, open("/home/heisenberg/CA/aurora-dust/analysis/l2-27-bsc-balances.json", "w"), indent=1)

if __name__ == "__main__":
    main()
