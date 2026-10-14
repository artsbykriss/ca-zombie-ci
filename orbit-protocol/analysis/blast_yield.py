"""Blast yield/gas claimable state for Orbit Protocol contracts (Blast).

Reads IBlast predeploy (0x4300...0002) claimable yield + gas params and the
USDB/WETH rebasing-token claimable amounts for every market and comptroller.
Writes ci-out/blast_yield.json. Read-only.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from enumerate_live2 import batch, u  # noqa: E402

OUTDIR = os.environ.get("CI_OUT", HERE)
BLAST = "0x4300000000000000000000000000000000000002"
USDB = "0x4300000000000000000000000000000000000003"
WETH = "0x4300000000000000000000000000000000000004"

SEL = {
    "readClaimableYield": "0xec3278e8",
    "readGasParams": "0xdde798a4",
    "getClaimableAmount": "0xe12f3a61",
}

COMPTROLLERS = [
    "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
    "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
]

MARKETS = [
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec", "0xd847b486fe612c51900f1da1a045741820dd5fa0",
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87", "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389",
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0", "0x8c415331761063e5d6b1c8e700f996b13603fc2e",
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e", "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2",
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d", "0xafabd582e82042f4a8574f75c36409abea916ac5",
    "0x9bbba6322fe5f3968c1f27c8b860727d683194c8", "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782",
    "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b", "0xa3135b76c28b3971b703a5e6cd451531b187eb5a",
    "0x4adf85e2e760c9211894482df74ba535bcae50a4", "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408",
    "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853", "0x586abb06179535de9eb6c6d968a355128dd74511",
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa", "0xe9391d8e1d5c970f7648852ffeda1a9f42833857",
    "0x7878c119f08052789f84cf4fdd3c3642fa291257",
]


def w(a):
    return a[2:].rjust(64, "0")


def main():
    addrs = COMPTROLLERS + MARKETS
    items, keys = [], []
    for a in addrs:
        items.append((BLAST, SEL["readClaimableYield"] + w(a))); keys.append((a, "claimable_yield"))
        items.append((BLAST, SEL["readGasParams"] + w(a))); keys.append((a, "gas_params"))
        items.append((USDB, SEL["getClaimableAmount"] + w(a))); keys.append((a, "usdb_claimable"))
        items.append((WETH, SEL["getClaimableAmount"] + w(a))); keys.append((a, "weth_claimable"))
    r = batch(items, "latest")
    out = {"contracts": {}}
    for (a, k), h in zip(keys, r):
        c = out["contracts"].setdefault(a, {})
        if k == "gas_params" and h and h != "__REVERT__":
            from enumerate_live2 import words
            ws = words(h)
            if len(ws) >= 4:
                c[k] = {"etherSeconds": u("0x" + ws[0]), "etherBalance": u("0x" + ws[1]),
                        "lastUpdated": u("0x" + ws[2]), "gasMode": u("0x" + ws[3])}
            else:
                c[k] = h
        else:
            c[k] = u(h) if h and h != "__REVERT__" else h
    os.makedirs(OUTDIR, exist_ok=True)
    with open(os.path.join(OUTDIR, "blast_yield.json"), "w") as f:
        json.dump(out, f, indent=1)
    tot_usdb = sum((c.get("usdb_claimable") or 0) for c in out["contracts"].values())
    tot_weth = sum((c.get("weth_claimable") or 0) for c in out["contracts"].values())
    tot_yield = sum((c.get("claimable_yield") or 0) for c in out["contracts"].values())
    print(f"claimable: yield_wei={tot_yield} usdb={tot_usdb} weth={tot_weth}", flush=True)
    print("wrote blast_yield.json", flush=True)


if __name__ == "__main__":
    main()
