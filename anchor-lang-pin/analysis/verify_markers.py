#!/usr/bin/env python3
"""Verify candidate version-discriminating marker strings across anchor-lang versions
(directly against crate sources), then classify a deployed ELF's strings."""
import os, re, sys, subprocess

SRC = "/tmp/opencode/anchor-src"
VERS = ["0.29.0","0.30.1","0.31.0","0.31.1","0.31.2","0.32.0","0.32.2","1.0.0","1.0.1","1.0.2","1.0.3","1.2.1"]

def read_all(d):
    buf = []
    for root, _, files in os.walk(d):
        if "/tests/" in root:
            continue
        for fn in files:
            if fn.endswith(".rs"):
                try:
                    buf.append(open(os.path.join(root, fn), encoding="utf-8", errors="replace").read())
                except Exception:
                    pass
    return "\n".join(buf)

CORPUS = {v: read_all(os.path.join(SRC, f"anchor-lang-{v}")) for v in VERS if os.path.isdir(os.path.join(SRC, f"anchor-lang-{v}"))}

MARKERS = {
    # candidate, direction
    "A duplicate mutable account constraint was violated": "1.0x",
    "Account is already migrated": "1.0x",
    "Account must be migrated before exiting": "1.0x",
    "Cannot deref to From: account is already migrated.": "1.0x",
    "Use `UncheckedAccount` instead of `AccountInfo` for safer unchecked accounts.": "1.0x",
    "8 byte instruction identifier not provided": "pre0.31",
    "Instruction discriminator not provided": "0.31+",
    "IDL account must be empty in order to resize, try closing first": "?",
    "The program was compiled without idl instructions": "?",
    "anchor:idl": "?",
    "Use `solana-sysvar` crate instead": "?",
    "Use solana-sdk-ids crate instead": "?",
    "interface-instructions": "?",
    "Program account is not executable": "?",
}

print("marker presence per version (raw source substring):")
hdr = "marker".ljust(70) + "".join(v.rjust(9) for v in CORPUS)
print(hdr)
for m in MARKERS:
    row = m[:68].ljust(70)
    for v in CORPUS:
        row += ("YES" if m in CORPUS[v] else "-").rjust(9)
    print(row)
