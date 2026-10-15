#!/usr/bin/env python3
"""On-chain evidence: the router's USDT jetton wallet only ever receives transfer
INSTRUCTIONS (0xf8a7ea5) from its owner, the STON.fi v1 router. The wallet's code is a
type-2 exotic library cell (shared Tether USDT wallet implementation), which @ton/sandbox
cannot resolve, so this behavioural check substitutes for a local TVM PoC.

Read-only, keyless endpoints. Writes analysis/usdt_wallet_senders.json.
"""
import json
import sys
import time
from collections import Counter

sys.path.insert(0, "/home/heisenberg/CA/stonfi-v1/analysis")
from ton_client import _get  # noqa

USDT_WALLET = "EQBO7JIbnU1WoNlGdgFtScJrObHXkBp-FT5mAz8UagiG9KQR"
ROUTER_RAW = "0:779dcc815138d9500e449c5291e7f12738c23d575b5310000f6a253bd607384e"


def main():
    senders = Counter()
    ops = Counter()
    total = 0
    pages = 4
    for i in range(pages):
        d = _get(f"https://tonapi.io/v2/blockchain/accounts/{USDT_WALLET}/transactions?limit=100&offset={i*100}")
        for t in d.get("transactions", []):
            im = t.get("in_msg") or {}
            op = im.get("op_code")
            src = (im.get("source") or {}).get("address") or "none"
            if op:
                ops[op] += 1
                total += 1
                senders[(op, src)] += 1
        time.sleep(1)
    transfer_senders = {src: n for (op, src), n in senders.items() if op == "0x0f8a7ea5"}
    out = {
        "usdt_wallet": USDT_WALLET,
        "tx_sample": total,
        "op_distribution": dict(ops),
        "transfer_instruction_senders": transfer_senders,
        "all_transfer_instructions_from_router": set(transfer_senders.keys()) == {ROUTER_RAW},
        "note": "0xf8a7ea5 = jetton transfer instruction (only valid from the wallet owner); "
                "0x178d4519 = incoming internal_transfer (real USDT deposits).",
    }
    print(json.dumps(out, indent=2))
    json.dump(out, open("/home/heisenberg/CA/stonfi-v1/analysis/usdt_wallet_senders.json", "w"), indent=2)


if __name__ == "__main__":
    main()
