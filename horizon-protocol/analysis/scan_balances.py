#!/usr/bin/env python3
"""Focused balance scan (threaded). Output: balances.json"""
import json
import rpcmulti as R

BASE = {
    "WBNB": "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
    "BUSD": "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    "USDT": "0x55d398326f99059ff775485246999027b3197955",
    "USDC": "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
    "BTCB": "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
    "ETH": "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
    "CAKE": "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
    "HZN": "0xc0eff7749b125444953ef89682201fb8c6a917cd",
    "PHB": "0x0409633a72d846fc5bbe2f98d88564d35987904d",
    "zUSD": "0x7f11125a2f22e1dcc19213475267d2dd2f838ff5",
}
SYNTH_CUSTODY = {
    "FEEPOOL": "0xb80f834ff243cb66a48f2fe9e37064db0cd9d6fd",
    "DEPOT": "0x9b957b4a90287ebb33faad9c15199ed9c17d114d",
    "REDEEMER": "0x05af42bfccd27b0db5697c4a34b8d1aa73f4f186",
    "LIQREWARDS": "0x05178294edd61ba3f6a78ef419165ad4d0124362",
    "ESCROW2": "0x41b9784e0541bf9d5324b3f265cfcd1170490474",
    "ESCROW1": "0x0c5db2579aab8c56d1e395082a1c870a7d28f3da",
    "SynthetixEscrow": "0x073c0c427e677aab733dbd4bd2de02951fd329cc",
    "BRIDGEESCROW": "0x53f6de83746d04578de1755e5866819de66d664a",
    "BRIDGE": "0x4ceb5c49d7e8ad212f19b8e5ea4a5f48c01630fb",
}

def main():
    synths = json.load(open("synth-enum.json"))["synths"]
    res = json.load(open("resolver-enum.json"))
    addrs = sorted(set(list(res.values()) + [
        "0xa1771dcfb7822c8853d7e64b86e58f7f1eb5e33e",
        "0x67d5a94f444df4bba254645065a4137fc665bf98",
        "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8",
        "0x5646aa2f9408c7c2ee1dc7db813c8b687a959a85",
        "0xdc9a574b9b341d4a98ce29005b614e1e27430e74",
        "0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf",
        "0x81752bc7d54a45bdb9005223d61d2cbd33d04857",
        "0x6a6677a979a0fd7f3edd8c87aa5d6884f7f6b5fb",
        "0x26356cb66f8fd62c03f569ec3691b6f00173eb02",
    ]))
    out = {a: {} for a in addrs}

    fns = []
    meta = []
    for a in addrs:
        fns.append(lambda a=a: R.native(a))
        meta.append((a, "BNB"))
        for sym, tok in BASE.items():
            fns.append(lambda tok=tok, a=a: R.call(tok, "0x70a08231" + a[2:].rjust(64, "0")))
            meta.append((a, sym))
    # synth balances for custody contracts only
    for name, a in SYNTH_CUSTODY.items():
        for sa, sv in synths.items():
            fns.append(lambda sa=sa, a=a: R.call(sa, "0x70a08231" + a[2:].rjust(64, "0")))
            meta.append((a, sv["currencyKey"]))

    print(f"total calls: {len(fns)}", flush=True)
    res2 = R.multi(fns, workers=10)
    for (a, sym), v in zip(meta, res2):
        if isinstance(v, str) and v.startswith("0x"):
            out[a][sym] = str(int(v, 16))
    json.dump(out, open("balances.json", "w"), indent=1, sort_keys=True)
    for a, toks in sorted(out.items()):
        nz = {k: v for k, v in toks.items() if int(v) > 0}
        if nz:
            print(a, json.dumps(nz), flush=True)

if __name__ == "__main__":
    main()
