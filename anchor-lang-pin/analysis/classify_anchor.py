#!/usr/bin/env python3
"""Classify a deployed Solana program ELF's anchor-lang family by matching
verified version-discriminating marker strings (see analysis/verify_markers.py).

Decision:
  ANCHOR_1_0_X      -> ELF contains a marker present only in anchor-lang 1.0.0..1.0.3
  NOT_1_0_X (0.3x)  -> ELF contains a marker present only in <=0.32.2 and absent in 1.0.x
  INDETERMINATE     -> neither set matched (dead-code elimination / stripped)
"""
import re, sys, json, os

M_1_0_X = [
    "A duplicate mutable account constraint was violated",
    "Account is already migrated",
    "Account must be migrated before exiting",
    "Cannot deref to From: account is already migrated.",
    "Use `UncheckedAccount` instead of `AccountInfo` for safer unchecked accounts.",
]
M_LE_0_32 = [
    "IDL account must be empty in order to resize, try closing first",
    "The program was compiled without idl instructions",
    "interface-instructions",
    "Use `solana-sdk-ids` crate instead",
    "Use `solana-sysvar` crate instead",
]
M_0_31_PLUS = ["Instruction discriminator not provided"]
M_LE_0_30 = ["8 byte instruction identifier not provided"]

def extract_strings(path, minlen=6):
    data = open(path, "rb").read()
    return data, set(re.findall(rb"[\x20-\x7e]{%d,}" % minlen, data))

def classify(path):
    data, strs = extract_strings(path)
    text = data  # byte-level search
    def has(s): return s.encode() in text
    hits10 = [m for m in M_1_0_X if has(m)]
    hits032 = [m for m in M_LE_0_32 if has(m)]
    hits031 = [m for m in M_0_31_PLUS if has(m)]
    hits030 = [m for m in M_LE_0_30 if has(m)]
    if hits10:
        fam = "ANCHOR_1_0_X"
    elif hits032:
        fam = "ANCHOR_0_30_0_32"
    else:
        fam = "INDETERMINATE"
    # toolchain era from embedded registry path
    reg = set(re.findall(rb"index\.crates\.io-[0-9a-f]{16}", data))
    hb = set(re.findall(rb"hashbrown-[0-9.]+", data))
    return {
        "elf": os.path.basename(path),
        "elf_bytes": len(data),
        "anchor_family": fam,
        "markers_1_0_x": hits10,
        "markers_le_0_32": hits032,
        "marker_0_31_plus": hits031,
        "marker_le_0_30": hits030,
        "registry_hashes": sorted(x.decode() for x in reg),
        "hashbrown": sorted(x.decode() for x in hb),
    }

if __name__ == "__main__":
    out = [classify(p) for p in sys.argv[1:]]
    print(json.dumps(out, indent=2))
