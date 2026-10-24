#!/usr/bin/env python3
"""ZH4-PASS5 Rujira FIN live re-check (read-only).

Answers, against THORChain LCD at the moment of the run:
  * did the v3.21.0 upgrade execute? (current version + height vs 28,366,100)
  * is the wasm layer still halted? (HALTWASMGLOBAL + FIN-specific halt keys)
  * are the 59 rujira-fin pairs still on code 196 (hash 5CC7E136..E071) or migrated?
  * any active node Mimir votes to lift HALTWASMGLOBAL?

Writes ci-out/live-recheck.json. No secrets, no transactions.
"""
import base64, json, time, urllib.request
from collections import Counter

BASE = "https://gateway.liquify.com/chain/thorchain_api"
UPGRADE_HEIGHT = 28366100
OUT = "ci-out/live-recheck.json"
FIN_CODE = 196
FIN_HASH = "5CC7E1368AEE0E5A7877502CA6A090CA7AA4DFB10CAF3453AADCD035E1F2E071"


def get(path, tries=4):
    last = None
    for _ in range(tries):
        try:
            r = urllib.request.Request(BASE + path, headers={"User-Agent": "Mozilla/5.0"})
            return json.load(urllib.request.urlopen(r, timeout=40))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5)
    raise last


def recheck_upgrade_executed(version, height):
    return height >= UPGRADE_HEIGHT and version.get("current") == "3.21.0"


def classify(halted, code_unchanged, mimir):
    if halted:
        return "E-U-conditional (still halted, unpatched code)"
    if code_unchanged:
        gc = str(mimir.get("HALTWASMCONTRACT-27DUYT")) == "1"
        return ("E-U UNVERIFIABLE: wasm UNHALTED + FIN still on unpatched code 196; "
                "the v3.21 fix is a private base-layer binary (not publicly verifiable). "
                "Not demonstrably exploitable; ghost-credit path %s."
                % ("still halted" if gc else "LIVE"))
    return "CHECK: wasm unhalted and FIN code changed -> re-verify"


def main():
    mimir = get("/thorchain/mimir")
    version = get("/thorchain/version")
    block = get("/thorchain/block")
    height = int(block["header"]["height"])
    btime = block["header"]["time"]
    upgrade = get("/thorchain/upgrade_proposals") or []
    contracts = get("/thorchain/contracts")

    up = next((x for x in upgrade if str(x.get("name", "")).startswith("3.21")), {})
    fin = [x["address"] for x in contracts.get("infos", []) if x.get("contract") == "rujira-fin"]

    codes = Counter()
    for a in fin:
        ci = get("/cosmwasm/wasm/v1/contract/%s" % a)["contract_info"]
        codes[str(ci["code_id"])] += 1

    code_hash = {}
    for cid in sorted(codes):
        try:
            code_hash[cid] = get("/cosmwasm/wasm/v1/code/%s" % cid)["code_info"]["data_hash"]
        except Exception as e:  # noqa: BLE001
            code_hash[cid] = "ERR:%s" % str(e)[:40]

    # node mimir votes touching the wasm halt
    nodes = get("/thorchain/mimir/nodes_all").get("mimirs", [])
    halt_votes = Counter()
    for m in nodes:
        k = m.get("key", "").upper()
        if "HALTWASM" in k or k == "HALTWASMGLOBAL":
            halt_votes["%s=%s" % (m.get("key"), m.get("value"))] += 1

    halted = str(mimir.get("HALTWASMGLOBAL")) == "1"
    fin_pairs_on_196 = codes.get("196", 0)
    code_unchanged = fin_pairs_on_196 == 58 and code_hash.get("196") == FIN_HASH

    recheck = {
        "chain": "thorchain-1",
        "height": height,
        "block_time_utc": btime,
        "upgrade_height": UPGRADE_HEIGHT,
        "blocks_to_upgrade": UPGRADE_HEIGHT - height,
        "upgrade_executed": height >= UPGRADE_HEIGHT and version.get("current") == "3.21.0",
        "version": version,
        "upgrade_proposal": up,
        "halt": {
            "HALTWASMGLOBAL": mimir.get("HALTWASMGLOBAL"),
            "HALTTHORCHAIN": mimir.get("HALTTHORCHAIN"),
            "HALTTRADING": mimir.get("HALTTRADING"),
            "HALTWASMCONTRACT-YEVLEC_fin": mimir.get("HALTWASMCONTRACT-YEVLEC"),
            "HALTWASMCONTRACT-JY3TQX_brune": mimir.get("HALTWASMCONTRACT-JY3TQX"),
            "HALTWASMCONTRACT-27DUYT_ghost_credit": mimir.get("HALTWASMCONTRACT-27DUYT"),
            "wasm_halted": halted,
        },
        "fin": {
            "pairs": len(fin),
            "code_id_histogram": dict(codes),
            "code_196_data_hash": code_hash.get("196"),
            "code_194_data_hash": code_hash.get("194"),
            "code_unchanged_vs_v2_2_2": code_unchanged,
        },
        "node_mimir_wasm_halt_votes": dict(halt_votes),
        "verdict": {
            "wasm_halted": halted,
            "upgrade_executed": recheck_upgrade_executed(version, height),
            "fin_pairs_on_196": fin_pairs_on_196,
            "code_unchanged_vs_v2_2_2": code_unchanged,
            "ghost_credit_halted": str(mimir.get("HALTWASMCONTRACT-27DUYT")) == "1",
            "classification": classify(halted, code_unchanged, mimir),
        },
    }
    json.dump(recheck, open(OUT, "w"), indent=1)
    print("height", height, btime)
    print("version", version.get("current"), "upgrade 3.21.0 @", UPGRADE_HEIGHT,
          "blocks_to_upgrade", UPGRADE_HEIGHT - height, "executed", recheck["upgrade_executed"])
    print("HALTWASMGLOBAL", mimir.get("HALTWASMGLOBAL"), "wasm_halted", halted)
    print("FIN pairs", len(fin), "code_ids", dict(codes), "unchanged_vs_v2.2.2", code_unchanged)
    print("node HALTWASM* votes", dict(halt_votes) or "(none)")
    print("classification", recheck["verdict"]["classification"])


if __name__ == "__main__":
    main()
