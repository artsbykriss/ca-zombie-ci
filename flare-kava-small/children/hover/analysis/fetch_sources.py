#!/usr/bin/env python3
"""Fetch verified sources/ABI from Sourcify v2 for the Hover contracts. Read-only."""
import json, os, sys, urllib.request

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sources")
os.makedirs(OUT, exist_ok=True)

ADDRS = {
    "comptroller": "0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC",
    "hKAVA": "0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636",
    "hATOM": "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd",
    "hUSDT": "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961",
    "impl_5c59": "0x5c59874128dc86e386973dd0b877f796d152b9ea",
    "impl_39c1": "0x39c18a98d1d5e432a9f7469009f65f1da0c706b4",
    "uATOM": "0x15932E26f5BD4923d46a2b205191C4b5d5f43FE3",
    "uUSDT": "0x919C1c267BC06a7039e03fcc2eF738525769109c",
}

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())

for name, a in ADDRS.items():
    try:
        d = get(f"https://sourcify.dev/server/v2/contract/2222/{a}?fields=all")
        with open(os.path.join(OUT, f"{name}.json"), "w") as f:
            json.dump(d, f, indent=1)
        src = (d.get("sources") or {})
        comp = d.get("compilation") or {}
        abi = d.get("abi") or []
        dep = d.get("deployment") or {}
        print(f"{name} {a}: sources={len(src)} abi_items={len(abi)} name={comp.get('name')} compiler={comp.get('compilerVersion')} deployBlock={dep.get('blockNumber')} tx={dep.get('transactionHash')}")
    except Exception as e:
        print(f"{name} {a}: ERR {e}")
