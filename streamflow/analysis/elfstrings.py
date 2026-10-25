#!/usr/bin/env python3
"""Fetch deployed ELF for a program (via programdata) and extract printable strings.
Read-only. Usage: elfstrings.py <program_id> <outfile>"""
import sys, os, base64, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_account_info, b58enc

def elf_of(prog):
    v = get_account_info(prog)
    raw = base64.b64decode(v["data"][0])
    pd = b58enc(raw[4:36])
    pv = get_account_info(pd)
    praw = base64.b64decode(pv["data"][0])
    return praw[45:]

def strings(b, minlen=5):
    return re.findall(rb"[\x20-\x7e]{%d,}" % minlen, b)

if __name__ == "__main__":
    prog = sys.argv[1]
    out = sys.argv[2]
    b = elf_of(prog)
    ss = [s.decode() for s in strings(b)]
    with open(out, "w") as f:
        f.write("\n".join(ss))
    print(prog, "elf bytes", len(b), "strings", len(ss), "->", out)
