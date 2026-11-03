#!/usr/bin/env python3
"""Read-only live checks for the TAC JettonProxy target (TAC chain + TON).

No keys, no state-changing calls. Writes JSON to stdout.
"""
import json
import subprocess
import time

TAC_RPC = "https://rpc-public.tac.build"
CCL = "0x9fee01e948353E0897968A3ea955815aaA49f58d"
CONSENSUS = "0xae635de674cfe4afd179cde441abbe6504a20a98"


def rpc(method, params):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    last = None
    for _ in range(4):
        out = subprocess.run(
            ["curl", "-s", "-m", "25", "-X", "POST", TAC_RPC,
             "-H", "content-type: application/json", "-d", payload],
            capture_output=True, text=True,
        ).stdout
        try:
            j = json.loads(out)
            if "result" in j:
                return j["result"]
            last = j
        except Exception as e:
            last = str(e)
        time.sleep(1)
    raise RuntimeError(f"rpc failed: {last}")


def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def enc_u256(v):
    return hex(v)[2:].rjust(64, "0")


def get_uint(to, selector):
    r = call(to, selector)
    return int(r, 16) if r and r != "0x" else None


def main():
    block = int(rpc("eth_blockNumber", []), 16)
    ts = int(rpc("eth_getBlockByNumber", [hex(block), False])["timestamp"], 16)
    out = {"block": block, "timestamp": ts, "calls": {}}

    # CCL storage: slot 0 _tokenUtils, slot 1 _consensus, slot 5 _simulationMode
    out["ccl_token_utils"] = rpc("eth_getStorageAt", [CCL, "0x0", "latest"])
    out["ccl_consensus"] = rpc("eth_getStorageAt", [CCL, "0x1", "latest"])
    out["ccl_simulation_mode_slot5"] = rpc("eth_getStorageAt", [CCL, "0x5", "latest"])

    # Consensus: totalVoters, totalGroups, groups, epoch info
    out["total_voters"] = get_uint(CONSENSUS, "0x5f5300ff")
    out["total_groups"] = get_uint(CONSENSUS, "0xc75f2893")
    groups_raw = call(CONSENSUS, "0xc72b5176")
    out["groups_raw"] = groups_raw
    out["epoch_info_raw"] = call(CONSENSUS, "0xbabc394f")

    # current root from epoch info (first 32 bytes of the tuple)
    if out["epoch_info_raw"] and len(out["epoch_info_raw"]) > 66:
        root = out["epoch_info_raw"][2:66]
        out["current_root"] = "0x" + root
        out["current_root_expiry"] = get_uint(CONSENSUS, "0x26678e5d" + root)
        out["current_root_check"] = get_uint(CONSENSUS, "0x814964f0" + root)

    # A forged receiveMessage must revert InvalidMerkleProof() (0xb05e92fa).
    forged = "0xabe13ef7000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000002123400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    try:
        out["forged_receiveMessage"] = rpc("eth_call", [
            {"from": "0x1111111111111111111111111111111111111111", "to": CCL, "data": forged},
            "latest",
        ])
    except Exception as e:
        out["forged_receiveMessage_error"] = str(e)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
