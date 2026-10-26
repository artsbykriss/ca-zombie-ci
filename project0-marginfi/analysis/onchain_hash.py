#!/usr/bin/env python3
"""Reproduce the solana-verify on-chain program hash from raw programdata (read-only).

The solana-verify "program hash" is sha256 of the deployed ELF with trailing zero padding
removed. This lets us independently corroborate the OtterSec registry's `on_chain_hash`.
"""
import sys, os, base64, hashlib, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_account_info, get_slot

PROG = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
PROGRAMDATA = "4Q8u2ny8YYgytJEncwZQfVWbd5axZtfgDxYKHehvPQR7"
OSEK_HASH = "eb7618369bec08691a7a4003e04f8fb34d95e7301e2b3b0c5439528e2b38cdab"

def main():
    pv = get_account_info(PROGRAMDATA)
    raw = base64.b64decode(pv["data"][0])
    elf = raw[45:]                                   # strip UpgradeableLoaderState::ProgramData metadata
    h = hashlib.sha256(elf.rstrip(b"\x00")).hexdigest()
    out = {"slot": get_slot(), "program": PROG, "programdata": PROGRAMDATA,
           "programdata_space": pv.get("space"), "elf_len": len(elf),
           "computed_onchain_hash": h, "osec_registry_hash": OSEK_HASH,
           "match": h == OSEK_HASH}
    print(json.dumps(out, indent=1))
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           "onchain_hash.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
