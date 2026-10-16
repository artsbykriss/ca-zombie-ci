#!/usr/bin/env python3
"""Re-encode Unistreet launch calldata for a fork replay with a fresh salt.

Reads a decoded launch JSON (from decode_launch.py), generates a fresh salt so that
the predicted clone address preserves the original currency ordering, swaps the token
address into initCalldata/modifyCalldata, and outputs replay-ready hex blobs.

Usage: python3 reencode_launch.py <decoded.json> <out.json> [nbytes_salt]
"""
import json
import secrets
import sys

from eth_abi import encode
from eth_utils import keccak, to_checksum_address

FACTORY = "0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825"
IMPLEMENTATION = "0x40f8727fC5686B6f3af581F3cE551Bd0278CC0e0"  # factory.implementation()
POSM = "0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e"

NEW_DEADLINE = 4102444800  # 2100-01-01, safe for any fork timestamp


def predict_clone(salt: bytes, impl: str = IMPLEMENTATION, deployer: str = FACTORY) -> str:
    """OZ Clones.predictDeterministicAddress: CREATE2 over the EIP-1167 minimal proxy initcode."""
    init_code = (
        bytes.fromhex("3d602d80600a3d3981f3363d3d373d3d3d363d73")
        + bytes.fromhex(impl[2:])
        + bytes.fromhex("5af43d82803e903d91602b57fd5bf3")
    )
    digest = keccak(
        b"\xff" + bytes.fromhex(deployer[2:]) + salt + keccak(init_code)
    )
    return to_checksum_address("0x" + digest[12:].hex())


def sel(sig: str) -> str:
    return "0x" + keccak(text=sig)[:4].hex()


SEL_INIT = sel("initializePool((address,address,uint24,int24,address),uint160)")
SEL_MODIFY = sel("modifyLiquidities(bytes,uint256)")


def encode_init(pool_key, sqrt_price_x96: int) -> str:
    data = encode(
        ["address", "address", "uint24", "int24", "address", "uint160"],
        [pool_key["currency0"], pool_key["currency1"], pool_key["fee"],
         pool_key["tickSpacing"], pool_key["hooks"], sqrt_price_x96],
    )
    return SEL_INIT + data.hex()


def encode_modify(pool_key, mint_params, settle_pair, deadline: int) -> str:
    mint = encode(
        ["address", "address", "uint24", "int24", "address",
         "int24", "int24", "uint256", "uint128", "uint128", "address", "bytes"],
        [pool_key["currency0"], pool_key["currency1"], pool_key["fee"],
         pool_key["tickSpacing"], pool_key["hooks"],
         int(mint_params["tickLower"]), int(mint_params["tickUpper"]),
         int(mint_params["liquidity"]), int(mint_params["amount0Max"]),
         int(mint_params["amount1Max"]), mint_params["owner"],
         bytes.fromhex(mint_params["hookData"][2:]) if mint_params["hookData"] != "0x" else b""],
    )
    settle = encode(["address", "address"], [settle_pair["currency0"], settle_pair["currency1"]])
    actions = bytes([0x02, 0x0D])
    unlock = encode(["bytes", "bytes[]"], [actions, [mint, settle]])
    data = encode(["bytes", "uint256"], [unlock, deadline])
    return SEL_MODIFY + data.hex()


def roundtrip_check(decoded) -> None:
    """Re-encode the ORIGINAL token-address calldata and compare with the raw input."""
    pk = decoded["initCalldata"]["poolKey"]
    enc = encode_init(pk, int(decoded["initCalldata"]["sqrtPriceX96"]))
    assert enc.lower() == decoded["initCalldata"]["raw"].lower(), "initCalldata roundtrip FAILED"

    u = decoded["modifyCalldata"]["unlockData"]
    mint = None
    settle = None
    for a in u["actions"]:
        if a["name"] == "MINT_POSITION":
            mint = a["params"]
        elif a["name"] == "SETTLE_PAIR":
            settle = a["params"]
    enc = encode_modify(pk, mint, settle, int(decoded["modifyCalldata"]["deadline"]))
    assert enc.lower() == decoded["modifyCalldata"]["raw"].lower(), "modifyCalldata roundtrip FAILED"
    print("  roundtrip check: OK (both blobs byte-identical)")


def main():
    decoded_path, out_path = sys.argv[1], sys.argv[2]
    decoded = json.load(open(decoded_path))
    name = decoded["params"]["name"]
    print(f"== {name} ({decoded['srcTx']}) ==")
    roundtrip_check(decoded)

    token_old = decoded["initCalldata"]["poolKey"]["currency1"] \
        if decoded["initCalldata"]["poolKey"]["currency1"].lower() != decoded["params"]["pairedStock"].lower() \
        else decoded["initCalldata"]["poolKey"]["currency0"]
    paired = decoded["params"]["pairedStock"]
    old_c0_is_token = decoded["initCalldata"]["poolKey"]["currency0"].lower() == token_old.lower()

    # generate fresh salt until currency ordering matches the original
    attempts = 0
    while True:
        attempts += 1
        salt = secrets.token_bytes(32)
        new_token = predict_clone(salt)
        c0_is_token = int(new_token, 16) < int(paired, 16)
        if c0_is_token == old_c0_is_token:
            break

    pk = dict(decoded["initCalldata"]["poolKey"])
    if old_c0_is_token:
        pk["currency0"], pk["currency1"] = new_token, paired
    else:
        pk["currency0"], pk["currency1"] = paired, new_token
    assert (pk["currency0"].lower() < pk["currency1"].lower()), "currency ordering invalid"

    init_calldata = encode_init(pk, int(decoded["initCalldata"]["sqrtPriceX96"]))

    u = decoded["modifyCalldata"]["unlockData"]
    mint = next(a["params"] for a in u["actions"] if a["name"] == "MINT_POSITION")
    settle = next(a["params"] for a in u["actions"] if a["name"] == "SETTLE_PAIR")
    mint = dict(mint, poolKey=pk)
    settle = {"currency0": pk["currency0"], "currency1": pk["currency1"]}
    modify_calldata = encode_modify(pk, mint, settle, NEW_DEADLINE)

    out = {
        "source": {
            "tx": decoded["srcTx"],
            "block": decoded["blockNumber"],
            "name": decoded["params"]["name"],
            "symbol": decoded["params"]["symbol"],
        },
        "salt": salt.hex(),
        "saltAttempts": attempts,
        "predictedToken": new_token,
        "params": dict(decoded["params"], salt=salt.hex()),
        "initCalldata": init_calldata,
        "modifyCalldata": modify_calldata,
        "seedBuys": decoded["seedBuys"],
        "value_wei": decoded["value_wei"],
        # extras for the doc/verification
        "decodedReference": {
            "poolKey": pk,
            "sqrtPriceX96": decoded["initCalldata"]["sqrtPriceX96"],
            "mintPosition": {k: v for k, v in mint.items() if k != "poolKey"},
            "deadline": NEW_DEADLINE,
            "actions": "0x" + u["actions_hex"],
        },
    }
    with open(out_path, "w") as f:
        json.dump(out, f, indent=2)
    print(f"  fresh salt (attempt {attempts}): 0x{salt.hex()}")
    print(f"  predicted token: {new_token}")
    print(f"  initCalldata  len={len(init_calldata)//2-1} bytes")
    print(f"  modifyCalldata len={len(modify_calldata)//2-1} bytes")
    print(f"  wrote {out_path}")


if __name__ == "__main__":
    main()
