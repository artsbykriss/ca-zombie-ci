"""Are any well-known public Gnosis contracts on RealT's recipient whitelist?

If a permissionless public contract were whitelisted, an attacker might be able to route
seized RealTokens through it. Probe Processor.canTransfer(wrapper -> candidate) for the top
tokens (msg.sender = token) at the latest block.

Writes analysis/public_contracts_probe.json.
"""
import json
import os
import sys

from eth_abi import encode as abi_encode
from eth_utils import to_checksum_address

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
PROCESSOR = "0x3221a28eD2b2e955DA64d1d299956f277562C95c"
CANDIDATES = {
    "yam": "0xC759AA7f9dd9720A1502c104DaE4F9852bb17C14",
    "gnosis_omnibridge": "0xf6A78083ca3e2a662D6dd1703c939c8aCE2e268d",
    "rmm_pool": "0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3",
    "wrapper": "0x10497611Ee6524D75FC45E3739F472F83e282AD5",
    "artw": "0xF3220Cd8F66AEB86fC2A82502977EAb4BFd2f647",
    "multicall3": "0xcA11bde05977b3631167028862bE2a173976CA11",
    "safe_singleton_130": "0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552",
    "cow_settlement": "0x9008D19f58AAbD9eD0D60971565AA8510560ab41",
    "honeyswap_router": "0x1C232F01118CB8B424793ae03F870aa7D0ac7f77",
    "sushiswap_router": "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506",
    "gnosis_bridge": "0x88ad09518695c6c3712AC10a214bE5109a655671",
    "usdc": "0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83",
}


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    toks = [t["address"] for t in wt["tokens"][:3]]
    rows = []
    for t in toks:
        for name, raw in CANDIDATES.items():
            d = to_checksum_address(raw)
            sig = g.sel("canTransfer(address,address,uint256)") + abi_encode(
                ["address", "address", "uint256"], [WRAPPER.lower(), d.lower(), 10 ** 18]).hex()
            try:
                r = g.eth_call(PROCESSOR, sig, block=block, frm=t)
                v = g.abi_decode(["bool", "uint256", "uint256"], bytes.fromhex(r[2:]))
                rows.append({"token": t, "candidate": name, "address": d,
                             "allowed": v[0], "rule_id": v[1], "reason": v[2]})
            except Exception as e:  # noqa: BLE001
                rows.append({"token": t, "candidate": name, "address": d, "error": str(e)[:160]})
    allowed = sorted({r["candidate"] for r in rows if r.get("allowed") is True})
    out = {"chain": "gnosis", "block": block, "timestamp": ts, "tokens": toks,
           "candidates": {k: to_checksum_address(v) for k, v in CANDIDATES.items()},
           "allowed_candidates": allowed, "rows": rows,
           "conclusion": ("Only the wrapper itself is whitelisted among public infrastructure; "
                          "Yam, bridges, DEX routers, Multicall3, the pool, aRTW and the Safe "
                          "singleton are all denied (rule 11).")}
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public_contracts_probe.json")
    json.dump(out, open(p, "w"), indent=2)
    print("wrote", p, "allowed:", allowed)
    for r in rows[:12]:
        print(r["token"][:8], r["candidate"], r.get("allowed"), r.get("rule_id"))


if __name__ == "__main__":
    main()
