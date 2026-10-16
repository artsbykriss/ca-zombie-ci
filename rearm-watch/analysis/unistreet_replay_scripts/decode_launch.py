#!/usr/bin/env python3
"""Decode a Unistreet LaunchpadFactoryAuto.launch(...) tx input into a JSON blob.

Usage: python3 decode_launch.py <tx_json_file> <out_json>
The tx json must be an Etherscan proxy eth_getTransactionByHash response.
"""
import json
import sys

from eth_abi import decode, encode
from eth_utils import keccak, to_checksum_address

SELECTOR_LAUNCH = keccak(text="launch((string,string,uint256,address,uint256,bytes32,string,string,string,string,bool),bytes,bytes,(address,uint256,bytes,bytes[],uint128[],address[]))")[:4].hex()
SELECTOR_INIT_POOL = keccak(text="initializePool((address,address,uint24,int24,address),uint160)")[:4].hex()
SELECTOR_MODIFY_LIQ = keccak(text="modifyLiquidities(bytes,uint256)")[:4].hex()

PARAMS_TYPES = ["string", "string", "uint256", "address", "uint256", "bytes32",
                "string", "string", "string", "string", "bool"]
SEEDBUYS_TYPES = ["address", "uint256", "bytes", "bytes[]", "uint128[]", "address[]"]
POOLKEY_TYPES = "(address,address,uint24,int24,address)"
POOLKEY_FLAT = ["address", "address", "uint24", "int24", "address"]
MINT_TYPES = POOLKEY_FLAT + ["int24", "int24", "uint256", "uint128", "uint128", "address", "bytes"]
SETTLE_PAIR_TYPES = ["address", "address"]
TAKE_PAIR_TYPES = ["address", "address", "address"]

ACTIONS = {
    0x00: ("INCREASE_LIQUIDITY", None),
    0x01: ("DECREASE_LIQUIDITY", None),
    0x02: ("MINT_POSITION", MINT_TYPES),
    0x03: ("BURN_POSITION", None),
    0x04: ("INCREASE_LIQUIDITY_FROM_DELTAS", None),
    0x05: ("MINT_POSITION_FROM_DELTAS", MINT_TYPES),
    0x06: ("SWAP_EXACT_IN_SINGLE", None),
    0x07: ("SWAP_EXACT_IN", None),
    0x08: ("SWAP_EXACT_OUT_SINGLE", None),
    0x09: ("SWAP_EXACT_OUT", None),
    0x0B: ("SETTLE", None),
    0x0C: ("SETTLE_ALL", None),
    0x0D: ("SETTLE_PAIR", SETTLE_PAIR_TYPES),
    0x0E: ("TAKE", None),
    0x0F: ("TAKE_ALL", None),
    0x10: ("TAKE_PORTION", None),
    0x11: ("TAKE_PAIR", TAKE_PAIR_TYPES),
    0x12: ("CLOSE_CURRENCY", None),
    0x13: ("CLEAR_OR_TAKE", None),
    0x14: ("SWEEP", None),
    0x15: ("WRAP", None),
    0x16: ("UNWRAP", None),
}


def h(b):
    return "0x" + b.hex()


def dec(types, data):
    """decode hex string data (without selector) with given types."""
    if isinstance(data, str):
        data = bytes.fromhex(data[2:] if data.startswith("0x") else data)
    return list(decode(types, data))


def poolkey_to_dict(pk):
    return {
        "currency0": to_checksum_address(pk[0]),
        "currency1": to_checksum_address(pk[1]),
        "fee": int(pk[2]),
        "tickSpacing": int(pk[3]),
        "hooks": to_checksum_address(pk[4]),
    }


def decode_init_calldata(raw_hex):
    b = bytes.fromhex(raw_hex[2:])
    sel = b[:4].hex()
    out = {"raw": raw_hex, "selector": "0x" + sel}
    if sel == SELECTOR_INIT_POOL:
        c0, c1, fee, spacing, hooks, sqrt_price = decode(POOLKEY_FLAT + ["uint160"], b[4:])
        pk = (c0, c1, fee, spacing, hooks)
        out["function"] = "initializePool((address,address,uint24,int24,address),uint160)"
        out["poolKey"] = poolkey_to_dict(pk)
        out["sqrtPriceX96"] = str(sqrt_price)
        out["decoded_types"] = "(PoolKey,uint160)"
    else:
        out["function"] = "UNKNOWN"
    return out


def decode_modify_calldata(raw_hex):
    b = bytes.fromhex(raw_hex[2:])
    sel = b[:4].hex()
    out = {"raw": raw_hex, "selector": "0x" + sel}
    if sel != SELECTOR_MODIFY_LIQ:
        out["function"] = "UNKNOWN"
        return out
    unlock_data, deadline = decode(["bytes", "uint256"], b[4:])
    actions, params_arr = decode(["bytes", "bytes[]"], unlock_data)
    actions_hex = actions.hex()
    parsed = []
    for i in range(0, len(actions), 1):
        a = actions[i]
        name, types = ACTIONS.get(a, ("UNKNOWN_0x%02x" % a, None))
        p = {"action": "0x%02x" % a, "name": name}
        if i < len(params_arr) and types:
            try:
                vals = decode(types, params_arr[i])
                if name in ("MINT_POSITION", "MINT_POSITION_FROM_DELTAS"):
                    c0, c1, fee, spacing, hooks, tick_lower, tick_upper, liquidity, amt0_max, amt1_max, owner, hook_data = vals
                    pk = (c0, c1, fee, spacing, hooks)
                    p["params"] = {
                        "poolKey": poolkey_to_dict(pk),
                        "tickLower": str(tick_lower),
                        "tickUpper": str(tick_upper),
                        "liquidity": str(liquidity),
                        "amount0Max": str(amt0_max),
                        "amount1Max": str(amt1_max),
                        "owner": to_checksum_address(owner),
                        "hookData": h(hook_data),
                    }
                elif name == "SETTLE_PAIR":
                    c0, c1 = vals
                    p["params"] = {"currency0": to_checksum_address(c0), "currency1": to_checksum_address(c1)}
                elif name == "TAKE_PAIR":
                    c0, c1, rcpt = vals
                    p["params"] = {"currency0": to_checksum_address(c0), "currency1": to_checksum_address(c1),
                                   "recipient": to_checksum_address(rcpt)}
                else:
                    p["params"] = [str(v) if isinstance(v, int) else h(v) if isinstance(v, bytes) else v for v in vals]
            except Exception as e:  # noqa
                p["decode_error"] = str(e)
                p["raw_params"] = h(params_arr[i]) if i < len(params_arr) else None
        parsed.append(p)
    out["function"] = "modifyLiquidities(bytes,uint256)"
    out["unlockData"] = {
        "raw": h(unlock_data),
        "actions_hex": "0x" + actions_hex,
        "actions": parsed,
    }
    out["deadline"] = str(deadline)
    return out


def main():
    tx_json_path, out_path = sys.argv[1], sys.argv[2]
    with open(tx_json_path) as f:
        tx = json.load(f)["result"]
    data = tx["input"]
    b = bytes.fromhex(data[2:])
    sel = b[:4].hex()
    assert sel == SELECTOR_LAUNCH, f"unexpected selector 0x{sel}, expected 0x{SELECTOR_LAUNCH}"
    p, init_calldata, modify_calldata, sb = decode(["(string,string,uint256,address,uint256,bytes32,string,string,string,string,bool)", "bytes", "bytes", "(address,uint256,bytes,bytes[],uint128[],address[])"], b[4:])

    name, symbol, supply, paired, seed_amount, salt, desc, image, website, twitter, holders_share = p
    pay_asset, total_pay_in, pre_commands, pre_inputs, amounts, recipients = sb

    # decode preInputs assuming UniversalRouter V3_SWAP_EXACT_IN
    pre_decoded = []
    for inp in pre_inputs:
        entry = {"raw": h(inp)}
        try:
            vals = decode(["(address,uint256,uint256,bytes,bool)"], inp)[0]
            entry["decoded"] = {
                "as": "(address recipient,uint256 amountIn,uint256 amountOutMin,bytes path,bool payerIsUser)",
                "recipient": to_checksum_address(vals[0]),
                "amountIn": str(vals[1]),
                "amountOutMin": str(vals[2]),
                "path": h(vals[3]),
                "payerIsUser": vals[4],
            }
        except Exception as e:
            entry["decode_error"] = str(e)
        pre_decoded.append(entry)

    out = {
        "srcTx": tx["hash"],
        "blockNumber": int(tx["blockNumber"], 16),
        "caller": to_checksum_address(tx["from"]),
        "value_wei": str(int(tx["value"], 16)),
        "selector": "0x" + sel,
        "params": {
            "name": name,
            "symbol": symbol,
            "supply": str(supply),
            "pairedStock": to_checksum_address(paired),
            "seedAmount": str(seed_amount),
            "salt": salt.hex() if isinstance(salt, bytes) else salt,
            "description": desc,
            "image": image,
            "website": website,
            "twitter": twitter,
            "holdersShare": holders_share,
        },
        "initCalldata": decode_init_calldata(h(init_calldata)),
        "modifyCalldata": decode_modify_calldata(h(modify_calldata)),
        "seedBuys": {
            "payAsset": to_checksum_address(pay_asset),
            "totalPayIn": str(total_pay_in),
            "preCommands": h(pre_commands),
            "preInputs": pre_decoded,
            "amounts": [str(a) for a in amounts],
            "recipients": [to_checksum_address(r) for r in recipients],
        },
    }
    with open(out_path, "w") as f:
        json.dump(out, f, indent=2)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
