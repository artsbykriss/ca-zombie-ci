#!/usr/bin/env python3
"""Dump strings to files + fetch anchor:idl PDA contents for programs."""
import sys, json, base64, re, hashlib
import sol_rpc as S

def code_of(pd_addr):
    a = S.get_account(pd_addr)
    raw = base64.b64decode(a["value"]["data"][0])
    return raw[45:]

def strings(code, minlen=4):
    return [s.decode(errors="replace") for s in re.findall(rb"[\x20-\x7e]{%d,}" % minlen, code)]

def idl_pda(program_id):
    pda, _ = S.find_pda([b"anchor:idl"], program_id)
    return pda

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "dump":
        pd, outfile = sys.argv[2], sys.argv[3]
        code = code_of(pd)
        ss = strings(code)
        open(outfile, "w").write("\n".join(ss))
        print(f"{pd} -> {outfile}: {len(ss)} strings")
    elif cmd == "idl":
        for pid in sys.argv[2:]:
            pda = idl_pda(pid)
            a = S.get_account(pda)
            if a and a.get("value"):
                raw = base64.b64decode(a["value"]["data"][0])
                print(pid, "IDL PDA", pda, "len", len(raw), "head:", raw[:80])
                open(f"idl_{pid[:8]}.bin", "wb").write(raw)
            else:
                print(pid, "IDL PDA", pda, "NOT FOUND")
