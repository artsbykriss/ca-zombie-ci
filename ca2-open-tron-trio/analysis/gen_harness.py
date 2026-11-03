#!/usr/bin/env python3
"""Generate poc/src/Runtimes.sol with the TVM-patched runtime bytecode constants."""
import os

OUT = os.path.dirname(os.path.abspath(__file__))
POC = os.path.abspath(os.path.join(OUT, "..", "poc", "src"))
os.makedirs(POC, exist_ok=True)
parts = []
for name, var in [("CherryPool", "CHERRY"), ("PokerGame", "POKER"), ("FireFull", "FIRE")]:
    h = open(f"{OUT}/{name}_runtime_evm.hex").read().strip()
    parts.append(f'    bytes internal constant {var} =\n        hex"{h}";')
sol = """// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice TVM-patched runtimes of the three Tron contracts, fetched on-chain via
/// TronGrid wallet/getcontract and patched only at CALLTOKENID/CALLTOKENVALUE
/// (0xd3/0xd2 -> PUSH0) so TRX-only paths execute on the EVM. Length-preserving.
library Runtimes {
%s
}
""" % "\n\n".join(parts)
open(os.path.join(POC, "Runtimes.sol"), "w").write(sol)
print("wrote", os.path.join(POC, "Runtimes.sol"), len(sol), "bytes")
