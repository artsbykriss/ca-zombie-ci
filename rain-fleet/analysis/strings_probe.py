#!/usr/bin/env python3
"""Extract printable strings from program ELF code, filter for interesting tokens."""
import sys, json, base64, re, hashlib
import sol_rpc as S

def code_of(pd_addr):
    a = S.get_account(pd_addr)
    raw = base64.b64decode(a["value"]["data"][0])
    return raw[45:]

def strings(code, minlen=4):
    return re.findall(rb"[\x20-\x7e]{%d,}" % minlen, code)

if __name__ == "__main__":
    pd = sys.argv[1]
    pats = sys.argv[2] if len(sys.argv) > 2 else "Signature|Collateral|Admin|Withdraw|Submit|instruction|Instruction|error|Error|ed25519|Ed25519"
    code = code_of(pd)
    ss = [s.decode() for s in strings(code)]
    rx = re.compile(pats)
    hits = [s for s in ss if rx.search(s)]
    print(json.dumps({"pd": pd, "code_size": len(code), "n_strings": len(ss), "n_hits": len(hits)}, indent=0))
    for s in hits:
        print("  ", s[:200])
