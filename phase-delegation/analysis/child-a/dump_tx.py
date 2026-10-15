#!/usr/bin/env python3
"""READ-ONLY: full account/balance dump of one transaction."""
import sys, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from rpc import rpc, b58dec  # noqa

SPOO1 = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"


def main():
    sig = sys.argv[1]
    tx = rpc("getTransaction", [sig, {"encoding": "json", "commitment": "confirmed",
                                     "maxSupportedTransactionVersion": 0}])
    msg = tx["transaction"]["message"]
    keys = list(msg["accountKeys"])
    loaded = tx["meta"].get("loadedAddresses") or {}
    n_static = len(keys)
    keys += list(loaded.get("writable", [])) + list(loaded.get("readonly", []))
    pre = list(tx["meta"]["preBalances"]) + [0] * (len(keys) - len(tx["meta"]["preBalances"]))
    post = list(tx["meta"]["postBalances"]) + [0] * (len(keys) - len(tx["meta"]["postBalances"]))
    print(f"slot={tx['slot']} err={tx['meta'].get('err')}")
    print("D_lamports (deltas):")
    for i, k in enumerate(keys):
        d = (post[i] or 0) - (pre[i] or 0)
        if d:
            tag = " [SIGNER]" if i < msg["header"]["numRequiredSignatures"] else ""
            print(f"   {k}  pre={pre[i]} post={post[i]} delta={d}{tag}")
    print("\nall accounts:", len(keys))
    for i, ix in enumerate(msg["instructions"]):
        pid = ix.get("programId") or keys[ix["programIdIndex"]]
        print(f"\nix{i} {pid} data={b58dec(ix['data']).hex() if ix.get('data') else ''}")
        for a in ix["accounts"]:
            print(f"      {keys[a]}")
    for grp in (tx["meta"].get("innerInstructions") or []):
        for ix in grp["instructions"]:
            pid = ix.get("programId") or keys[ix["programIdIndex"]]
            d = b58dec(ix["data"]) if ix.get("data") else b""
            print(f"\ninner[{grp['index']}] {pid} data({len(d)})={d[:80].hex()}")
            for a in ix["accounts"]:
                print(f"      {keys[a]}")


main()
