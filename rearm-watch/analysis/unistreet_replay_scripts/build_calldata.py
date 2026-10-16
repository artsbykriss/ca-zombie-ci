#!/usr/bin/env python3
"""Build full factory.launch(...) calldata.

Usage:
  python3 build_calldata.py original <decoded.json> <orig_tx.json>   # roundtrip vs on-chain input
  python3 build_calldata.py replay <replay.json> <out_hex_file>      # replay blob
"""
import json
import sys

from eth_abi import encode
from eth_utils import keccak

SEL = "0x" + keccak(text="launch((string,string,uint256,address,uint256,bytes32,string,string,string,string,bool),bytes,bytes,(address,uint256,bytes,bytes[],uint128[],address[]))")[:4].hex()

PARAMS_FLAT = ["string", "string", "uint256", "address", "uint256", "bytes32",
               "string", "string", "string", "string", "bool"]
SEED_FLAT = ["address", "uint256", "bytes", "bytes[]", "uint128[]", "address[]"]


def word(n: int) -> bytes:
    return n.to_bytes(32, "big")


def enc_bytes(x: bytes) -> bytes:
    pad = b"\x00" * ((32 - len(x) % 32) % 32)
    return word(len(x)) + x + pad


def build(params: dict, init_calldata: str, modify_calldata: str, seed_buys: dict) -> str:
    salt = bytes.fromhex(params["salt"][2:] if params["salt"].startswith("0x") else params["salt"])
    params_enc = encode(PARAMS_FLAT, [
        params["name"], params["symbol"], int(params["supply"]), params["pairedStock"],
        int(params["seedAmount"]), salt, params["description"], params["image"],
        params["website"], params["twitter"], bool(params["holdersShare"]),
    ])
    init_b = enc_bytes(bytes.fromhex(init_calldata[2:]))
    mod_b = enc_bytes(bytes.fromhex(modify_calldata[2:]))
    pre_inputs = [bytes.fromhex(p["raw"][2:]) for p in seed_buys["preInputs"]]
    sb_enc = encode(SEED_FLAT, [
        seed_buys["payAsset"], int(seed_buys["totalPayIn"]),
        bytes.fromhex(seed_buys["preCommands"][2:]),
        pre_inputs,
        [int(a) for a in seed_buys["amounts"]],
        seed_buys["recipients"],
    ])
    head_len = 4 * 32
    o1 = head_len
    o2 = o1 + len(params_enc)
    o3 = o2 + len(init_b)
    o4 = o3 + len(mod_b)
    head = word(o1) + word(o2) + word(o3) + word(o4)
    return SEL + (head + params_enc + init_b + mod_b + sb_enc).hex()


def main():
    mode = sys.argv[1]
    if mode == "original":
        decoded = json.load(open(sys.argv[2]))
        orig = json.load(open(sys.argv[3]))["result"]["input"]
        data = build(decoded["params"], decoded["initCalldata"]["raw"],
                     decoded["modifyCalldata"]["raw"], decoded["seedBuys"])
        ok = data.lower() == orig.lower()
        print("original calldata roundtrip:", "OK (byte-identical)" if ok else "MISMATCH")
        if not ok:
            print("  built len:", len(data), "orig len:", len(orig))
            for i in range(0, min(len(data), len(orig))):
                if data[i] != orig[i]:
                    print(f"  first diff at char {i}: built={data[i:i+40]} orig={orig[i:i+40]}")
                    break
        sys.exit(0 if ok else 1)
    elif mode == "replay":
        replay = json.load(open(sys.argv[2]))
        data = build(replay["params"], replay["initCalldata"], replay["modifyCalldata"], replay["seedBuys"])
        open(sys.argv[3], "w").write(data)
        print(f"replay calldata: {len(data)//2-1} bytes -> {sys.argv[3]}")
    else:
        raise SystemExit("mode must be original|replay")


if __name__ == "__main__":
    main()
