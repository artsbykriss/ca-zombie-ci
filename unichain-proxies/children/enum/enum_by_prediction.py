#!/usr/bin/env python3
"""Cross-check clone enumeration by predicting CREATE2 vault addresses from IntentPublished logs.
READ-ONLY. Outputs ci-out/intents.json and ci-out/predicted.json
"""
import json, os, collections
from web3 import Web3
from eth_abi import encode
from eth_abi.packed import encode_packed

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ci-out")

def keccak(b):
    return Web3.keccak(b)

def load_logs(portal):
    return json.load(open(os.path.join(OUT, f"logs_{portal}.json")))

def parse_intent(log):
    p = {x["name"]: x["value"] for x in log["decoded"]["parameters"]}
    ih = bytes.fromhex(p["intentHash"][2:])
    destination = int(p["destination"])
    route = bytes.fromhex(p["route"][2:])
    creator = p["creator"]
    prover = p["prover"]
    deadline = int(p["rewardDeadline"])
    native = int(p["rewardNativeAmount"])
    tokens = [(t[0], int(t[1])) for t in p["rewardTokens"]]
    return dict(intentHash=p["intentHash"], destination=destination, route=route.hex(),
                creator=creator, prover=prover, deadline=deadline, native=native,
                tokens=tokens, block=log["block_number"], tx=log["transaction_hash"])

def reward_hash(deadline, creator, prover, native, tokens):
    # Reward = (uint64 deadline, address creator, address prover, uint256 nativeAmount, TokenAmount[] tokens)
    r = (deadline, Web3.to_checksum_address(creator), Web3.to_checksum_address(prover), native,
         [(Web3.to_checksum_address(t), a) for t, a in tokens])
    return keccak(encode(['(uint64,address,address,uint256,(address,uint256)[])'], [r]))

def main():
    clones = json.load(open(os.path.join(OUT, "clones_raw.json")))
    # creation code per impl (full init code incl. 32-byte arg)
    impl2cc = {}
    for c in clones:
        ca = c.get("constructor_args") or ""
        impl = ("0x" + ca[-40:]).lower() if len(ca) >= 40 else None
        cb = c.get("creation_bytecode")
        if impl and cb:
            impl2cc.setdefault(impl, cb)
    print("impl->creationcode:", {k: len(v) // 2 for k, v in impl2cc.items()})

    portals = {
        "0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97": "0x3fd339e58769a56d08dcd2683f9012e881287476",
        "0xEC000064576f9C95a8623Bc0eff3db6d296ea6df": "0x9f70b0c839fe2d7190a09ae87ed658b6d1cba4f9",
    }
    clone_set = set(c["address"].lower() for c in clones)
    intents = []
    predicted = {}
    ok_hash = 0
    bad_hash = 0
    matched = 0
    for portal, impl in portals.items():
        cc = impl2cc.get(impl)
        if not cc:
            print("no creation code for impl", impl)
            continue
        cc_bytes = bytes.fromhex(cc[2:])
        cc_hash = keccak(cc_bytes)
        for log in load_logs(portal):
            it = parse_intent(log)
            rh = reward_hash(it["deadline"], it["creator"], it["prover"], it["native"], it["tokens"])
            route_hash = keccak(bytes.fromhex(it["route"]))
            ih2 = keccak(encode_packed(['uint64', 'bytes32', 'bytes32'], [it["destination"], route_hash, rh]))
            it["hash_ok"] = (bytes(ih2).hex() == it["intentHash"][2:])
            if it["hash_ok"]:
                ok_hash += 1
            else:
                bad_hash += 1
            it["portal"] = portal
            it["impl"] = impl
            # predicted vault
            pred = keccak(b'\xff' + bytes.fromhex(portal[2:]) + bytes.fromhex(it["intentHash"][2:]) + cc_hash)[12:]
            it["predicted_vault"] = "0x" + bytes(pred).hex()
            predicted[it["predicted_vault"].lower()] = it["intentHash"]
            if it["predicted_vault"].lower() in clone_set:
                matched += 1
            intents.append(it)
    json.dump(intents, open(os.path.join(OUT, "intents.json"), "w"))
    json.dump({"unique_predicted": len(predicted),
               "intents": len(intents),
               "hash_ok": ok_hash, "hash_bad": bad_hash,
               "predicted_matches_verified_clone": matched,
               "verified_clones": len(clone_set)},
              open(os.path.join(OUT, "predicted.json"), "w"), indent=1)
    print("intents", len(intents), "hash_ok", ok_hash, "hash_bad", bad_hash)
    print("unique predicted vaults", len(predicted))
    print("predicted match verified clones", matched, "/", len(clone_set))
    # predicted addresses not among verified clones
    missing = [a for a in predicted if a not in clone_set]
    print("predicted not in verified clone set:", len(missing))

if __name__ == "__main__":
    main()
