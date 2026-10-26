#!/usr/bin/env python3
"""Enumerate live GMX-Solana store accounts (read-only getProgramAccounts)."""
import hashlib, json, os, sys, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_program_accounts, b58enc, b58dec

STORE = "Gmso1uvJnLbawvw7yezdfCDcPydwW2s2iqG3w6MDucLo"
HERE = os.path.dirname(os.path.abspath(__file__))

def disc(prefix, name):
    return list(hashlib.sha256((prefix + name).encode()).digest()[:8])

ACCTS = ["Store", "TokenMap", "Market", "Oracle", "UserHeader", "Position", "Order",
         "Deposit", "Withdrawal", "Shift", "GtExchangeVault", "GtExchange", "Glv",
         "GlvDeposit", "GlvWithdrawal", "MarketConfigBuffer", "CallbackAuthority",
         "VirtualInventory", "TradeData", "FeatureFlag"]

def main():
    out = {}
    for name in ACCTS:
        d = disc("account:", name)
        try:
            res = get_program_accounts(STORE, filters=[{"memcmp": {"offset": 0, "bytes": b58enc(bytes(d))}}],
                                       encoding="base64", dataSlice={"offset": 0, "length": 0})
            if isinstance(res, dict) and res.get("error"):
                out[name] = {"error": str(res["error"])[:120]}
                continue
            accts = res or []
            out[name] = {"count": len(accts),
                         "sample": [a["pubkey"] for a in accts[:5]]}
            print(f"{name:22s} {len(accts):6d}  {out[name]['sample']}")
        except Exception as e:
            out[name] = {"error": f"{type(e).__name__}: {e}"}
            print(f"{name:22s} ERR {e}")
    with open(os.path.join(HERE, "store_accounts.json"), "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
