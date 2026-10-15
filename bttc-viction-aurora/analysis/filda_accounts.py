#!/usr/bin/env python3
"""FilDA BTTC: borrower universe + account snapshots + on-chain liquidity. Read-only."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, pad32, dec_uint, dec_addr

C = "0xe52792e024697a6be770e5d6f1c455550265b2cd"
MARKETS = {
 "fBTT":  "0x65019969b8308f062548d25b1483add15c582d5b",
 "fUSDT": "0x590052be9ad26e51f2f1382d29338fcc4c04bfbf",
 "fTRX":  "0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e",
 "fUSDC": "0xaee67519049092ab91efd033f7d350d62b9f166b",
 "fETH":  "0xa258bffd5f6814303a718d2b9d34b40e14c66289",
}
SNAP = "0xc37f68e2"  # getAccountSnapshot(address)
LIQ  = "0x5ec88c79"  # getAccountLiquidity(address)

def addr_from_topic(t):
    return "0x" + t[-40:]

def borrower_of(lg):
    # Borrow(address borrower, ...) - non-indexed in this fork: borrower is first word of data
    if len(lg.get("topics", [])) > 1:
        return addr_from_topic(lg["topics"][1])
    d = lg.get("data","0x")[2:]
    if len(d) >= 64:
        return "0x" + d[24:64]
    return None

def main():
    blk = block_number("bttc")
    ev = json.load(open("filda_events.json"))
    borrowers = {}
    for mkt, d in ev.items():
        for lg in d.get("Borrow", []):
            b = borrower_of(lg)
            if b: borrowers.setdefault(b, set()).add(mkt)
    blkhex = hex(blk)
    out = {"block": blk, "n_borrowers": len(borrowers), "accounts": {}}
    addrs = sorted(borrowers)
    # chunked batches: per account 5 snapshots + 1 liquidity = 6 calls; batch of 10 -> 60 accounts per round
    for i in range(0, len(addrs), 60):
        chunk = addrs[i:i+60]
        calls = []
        for a in chunk:
            for mkt, maddr in MARKETS.items():
                calls.append(("eth_call", [{"to": maddr, "data": SNAP + pad32(a)}, blkhex]))
            calls.append(("eth_call", [{"to": C, "data": LIQ + pad32(a)}, blkhex]))
        res = batch("bttc", calls)
        j = 0
        for a in chunk:
            e = {"markets": {}, "borrow_in": sorted(borrowers[a])}
            for mkt in MARKETS:
                r = res[j]; j += 1
                if r and r != "0x":
                    h = r[2:]
                    e["markets"][mkt] = {"err": int(h[0:64],16), "cBal": int(h[64:128],16), "borrow": int(h[128:192],16), "er": int(h[192:256],16)}
            r = res[j]; j += 1
            if r and r != "0x":
                h = r[2:]
                e["liquidity"] = {"err": int(h[0:64],16), "liq": int(h[64:128],16), "shortfall": int(h[128:192],16)}
            out["accounts"][a] = e
        print("done", i+len(chunk), "/", len(addrs), file=sys.stderr)
    json.dump(out, open("filda_accounts.json","w"), indent=1)
    # summary
    open_bor = [a for a,e in out["accounts"].items() if any(v.get("borrow",0)>0 for v in e["markets"].values())]
    under = [(a, e["liquidity"]) for a,e in out["accounts"].items() if e.get("liquidity",{}).get("shortfall",0)>0]
    print("accounts with open borrows:", len(open_bor))
    print("accounts with shortfall>0:", len(under))
    for a, l in under:
        print("UNDERWATER", a, l)

if __name__ == "__main__":
    main()
