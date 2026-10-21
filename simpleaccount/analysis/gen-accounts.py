#!/usr/bin/env python3
"""Generate poc/test/Accounts.sol from analysis/census.json (1,036 factory accounts)."""
import json, os
from eth_utils import to_checksum_address

HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, "census.json")))
proxies = sorted(a for a, v in d["contracts"].items() if v["state"])
out = ["// SPDX-License-Identifier: MIT",
       "pragma solidity 0.8.24;",
       "// AUTO-GENERATED from analysis/census.json (factory 0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885).",
       f"// {len(proxies)} ERC1967Proxy accounts created by SimpleAccountFactory (2025-08-16 .. 2025-08-29).",
       "library Accounts {",
       f"    uint256 internal constant COUNT = {len(proxies)};",
       "    function all() internal pure returns (address[] memory a) {",
       f"        a = new address[]({len(proxies)});"]
for i, a in enumerate(proxies):
    out.append(f"        a[{i}] = {to_checksum_address(a)};")
out += ["    }", "}", ""]
open(os.path.join(HERE, "..", "poc", "test", "Accounts.sol"), "w").write("\n".join(out))
print("wrote", len(proxies), "accounts")
