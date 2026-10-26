#!/usr/bin/env python3
"""Identify accounts: owner, len, discriminator/type. Read-only."""
import sys, json, time, base64
from rpc import call
from b58 import b58dec, b58enc
from disc import ACC_BY_DISC

ADDRS = [
 "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47",
 "dbrv6zgi9hP8iDwtWNfCpMfk4h2s6BxgeCfhmDxkJm9",
 "3gYqUE7bBeWDUgn6qs49eFX97EkSVhdAYMUdE38gXq46",
 "9jfktqKRQASH8gYyiaLoFnG6u5RG8NsK99qPWVYfmPZ4",
 "9WaDMCXisKv1TXB395DJX6HFy2Mtoy4giab2mh6gNed8",
 "BMFZkqyBDds1BWDN8YvQjN7KycQcLvMH7UtkGc3qjxRt",
 "GUAujt5S2yvnY4HVj5ysiiHfskmLXPkcbVfxcgLVd1is",
 "Cdm5DHZZyhAxUzXbiNzHdWexzHknnz5oQ6AwrDCm6dLi",
 "2WpgSwhTXohXDxxCMmdaKgdaiuD62H6XreDMvu3PykLS",
 "779z6J7LDEXTR94SeEXTRjnaXHMAv9tkiWqnsth69AW9",
 "5C5TeQcD1ks9GdrM1dveuQsL6K3Ag1terHNrGLWVX2VT",
 "E3N2TD2WnuhRDqARrvaynXNFZ1yJ2sWfxAJE4nMY54er",
 "8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4",
 "6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2",
 "9ayXbTyhkJ49WtG6DA2PCN6EAKtM8DCneMzhJPTMRWcj",
]

def main():
    r = call("getMultipleAccounts", [ADDRS, {"encoding": "base64"}])
    for addr, v in zip(ADDRS, r["value"]):
        if v is None:
            print(f"{addr}  -> NULL"); continue
        raw = base64.b64decode(v["data"][0]) if v.get("data") else b""
        disc = raw[:8].hex() if len(raw) >= 8 else ""
        typ = ACC_BY_DISC.get(raw[:8], "?") if len(raw) >= 8 else ""
        print(f"{addr}  owner={v['owner']} len={len(raw)} lamports={v['lamports']} disc={disc} type={typ}")
        if typ == "Custody":
            print("     full:", raw.hex())

if __name__ == "__main__":
    main()
