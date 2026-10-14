#!/usr/bin/env python3
"""Token + farm metadata reads (read-only)."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

JOBS = [
    # (chain, label, address)
    ("op_bnb", "LEET_opbnb", "0xf2f41fe10d53e15ba34e410987eb0f986ec7509f"),
    ("manta", "LEET_manta", "0xe650686a3b474c01fbb5ad3b07ecc44093356090"),
    ("linea", "LEET_linea", "0xff98dcf88d1ae42c7ebb835133ab57481d16076e"),
    ("op_bnb", "WBNB", "0x4200000000000000000000000000000000000006"),
    ("manta", "WETH", "0x0dc808adce2099a9f62aa87d9670745aba741746"),
    ("shibarium", "TOK_a289", "0xa2899c776baaf9925d432f83c950d5054a6cf59c"),
    ("shibarium", "BONE?", "0xa2899c776baaf9925d432f83c950d5054a6cf59c"),
]
SELS = {
    "symbol": "0x95d89b41", "name": "0x06fdde03", "decimals": "0x313ce567",
    "totalSupply": "0x18160ddd", "owner": "0x8da5cb5b",
    "paused": "0x5c975abb", "getOwner": "0x893d20e8", "minter": "0x07546172",
    "isMinter(address)": "0xaa271e1a",
}
out = {}
for chain, label, addr in JOBS:
    row = {}
    try:
        calls = [("eth_call", [{"to": addr, "data": s}, "latest"]) for s in SELS.values()]
        calls.append(("eth_getCode", [addr, "latest"]))
        r = B.batch(chain, calls)
        for (name, sel), rr in zip(SELS.items(), r[:-1]):
            if rr is None or rr == "0x":
                row[name] = None
            elif name in ("symbol", "name"):
                row[name] = B.dec_str(rr)
            elif name == "isMinter(address)":
                row[name] = bool(B.dec_uint(B.words(rr)[0]))
            elif name in ("owner", "getOwner", "minter"):
                row[name] = B.dec_addr(B.words(rr)[0])
            else:
                row[name] = B.dec_uint(B.words(rr)[0])
        row["code_size"] = len(r[-1] or "0x") // 2
    except Exception as e:
        row["err"] = str(e)[:150]
    out[f"{chain}:{label}"] = row
    print(chain, label, json.dumps(row)[:300], flush=True)
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "token-meta.json"), "w"), indent=1)
print("saved token-meta.json")
