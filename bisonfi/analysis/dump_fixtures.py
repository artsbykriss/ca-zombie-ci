#!/usr/bin/env python3
"""Dump LiteSVM fixtures (accounts) to poc/fixtures/accounts.json. Read-only.
Uses public RPC; falls back to api.mainnet-beta on failure."""
import base64, json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # bisonfi/
FIX = os.path.join(OUT, "poc", "fixtures")
os.makedirs(FIX, exist_ok=True)

ACCOUNTS = {
    "pool_state_cur": "8FnX3xo2yYw3EUE6w3nQA4GfXGS9wpK6oj3veJpbFzLo",
    "vault_wsol_cur": "ATRsNGv2nDw7hSMfkUTBoVUDsFDwN7po7KbecyiGWNB4",
    "vault_usdc_cur": "2Y7HATmn9aJBcxCskE5V2U2epmjvkZmB51zTJBbhj4cU",
    "mint_wsol": "So11111111111111111111111111111111111111112",
    "mint_usdc": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "vote_account": "J1to1yufRnoWn81KYg1XkTWzmKjnYSnmE2VY8DGUJ9Qv",
    "pool_state_old": "51FQwjrvo8J8zXUaKyAznJ5NYpoiTCuqAqCu3HAMB9NZ",
    "vault_wsol_old": "FxGiN5NkigicwrnFshZEAUH9C13yrBALmgYxA9x8sfnQ",
    "vault_usdc_old": "6DMF4t6Ks8yXhG8K3rrTAeNYrqNrr1DwewHvBmH3a3FX",
    "oracle_sol_usdc": "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3",
    "goonfi_pool": "GMCJvYGf5Ex2ARiMquaBDqU6iKM8uiEQkB8jCnoNfHpC",
    "goonfi_vault_wsol": "8ncU5YW1CQwvr4gs7buH57bW58e86TDau4STrCJBuz8z",
    "goonfi_vault_usdc": "EunHLeqeJKvxnCPQSytnBP63HJVk2fbHceiKKpngyAo8",
    "goonfi_quote_blob": "BNrK9LpEn65QA4TyBLVSMdngW3XHj3xLfFPwGdCBv8wV",
    "goonfi_authority": "GMCJvYGf5Ex2ARiMquaBDqU6iKM8uiEQkB8jCnoNfHpC",
}

def fetch(a):
    for attempt in range(6):
        r = rpc("getAccountInfo", [a, {"encoding": "base64", "commitment": "confirmed"}])
        v = (r.get("result") or {}).get("value")
        if v is not None:
            return {"owner": v["owner"], "lamports": v["lamports"], "executable": v["executable"],
                    "data_b64": v["data"][0], "rentEpoch": v.get("rentEpoch", 0)}
        time.sleep(1.5*(attempt+1))
    return None

out = {}
for name, addr in ACCOUNTS.items():
    acc = fetch(addr)
    if acc is None:
        print("FAILED", name, addr)
        continue
    out[name] = {"address": addr, **acc}
    print(f"ok {name}: {addr} owner={acc['owner'][:20]} lamports={acc['lamports']} len={len(base64.b64decode(acc['data_b64']))}")
json.dump(out, open(os.path.join(FIX, "accounts.json"), "w"), indent=1)
print("saved", os.path.join(FIX, "accounts.json"))

# also copy the program ELF
import shutil
elf_src = os.path.join(OUT, "analysis", "bisonfi-live.elf")
elf_dst = os.path.join(FIX, "bisonfi.elf")
shutil.copyfile(elf_src, elf_dst)
print("copied ELF ->", elf_dst, os.path.getsize(elf_dst), "bytes")
orc_src = os.path.join(OUT, "analysis", "oracle-program.elf")
shutil.copyfile(orc_src, os.path.join(FIX, "dijkbk-oracle.elf"))
print("copied oracle ELF")
