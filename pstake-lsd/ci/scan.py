#!/usr/bin/env python3
"""
Independent CI re-verification of the pSTAKE stkBNB StakePool live state.

Re-scans ALL Withdraw events from the pool (deploy block 20,155,830) to head,
derives the complete set of users who ever created a claim request, then reads
`getClaimRequestCount` + `getPaginatedClaimRequests` for each user at head and
sums the outstanding (unclaimed) weiToReturn. Also snapshots the pool's live
accounting. Writes JSON to ci-out/ (uploaded as a CI artifact).

RPC comes from $BSC_RPC (set by ci/run.sh). No secrets are written to disk.
"""
import json
import os
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = os.environ["BSC_RPC"]
POOL = "0xC228CefDF841dEfDbD5B3a18dFD414cC0dbfa0D8"
STKBNB = "0xc2E9d07F66A89c44062459A47a0D2Dc038E4fb16"
DEPLOY = 20155830
TOPIC_WITHDRAW = "0x02f25270a4d87bea75db541cdfe559334a275b4a233520ed6c0a2429667cca94"
SEL_COUNT = "0x8be78083"  # getClaimRequestCount(address)
SEL_PAGE = "0x75ccc37a"   # getPaginatedClaimRequests(address,uint256,uint256)
SEL_EXCHANGE_RATE = "0x3ba0b9a9"  # exchangeRate()
SEL_CLAIM_RESERVE = "0x3fe5f054"  # claimReserve()
SEL_BNB_TO_UNBOND = "0x5d97914c"  # bnbToUnbond()
SEL_TOTAL_SUPPLY = "0x18160ddd"   # totalSupply()
CHUNK = 1000000


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json"})
    last = None
    for attempt in range(10):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                d = json.loads(r.read())
            if "error" in d:
                msg = str(d["error"])
                last = msg
                if any(s in msg.lower() for s in ["rate", "limit", "busy", "timeout", "try again"]):
                    time.sleep(2 * (attempt + 1))
                    continue
                raise RuntimeError(msg)
            return d["result"]
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 * (attempt + 1))
    raise RuntimeError(f"rpc failed: {last}")


def enc_addr(a):
    return "0x" + "0" * 24 + a.lower().replace("0x", "")


def call(data, to=POOL, blk="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, blk])


def count(u):
    r = call(SEL_COUNT + enc_addr(u)[2:])
    return int(r, 16) if r and r != "0x" else 0


def page(u, frm, to):
    return call(SEL_PAGE + enc_addr(u)[2:] + format(frm, "064x") + format(to, "064x"))


def to_signed(v):
    if v is None:
        return None
    return v - (1 << 256) if v >= (1 << 255) else v


def main():
    latest = int(rpc("eth_blockNumber", []), 16)
    users = set()
    frm = DEPLOY
    n_logs = 0
    while frm <= latest:
        to = min(frm + CHUNK - 1, latest)
        logs = rpc(
            "eth_getLogs",
            [{"address": POOL, "fromBlock": hex(frm), "toBlock": hex(to), "topics": [TOPIC_WITHDRAW]}],
        )
        for l in logs:
            users.add("0x" + l["topics"][1][-40:])
        n_logs += len(logs)
        frm = to + 1
        time.sleep(0.1)
    users = sorted(users)
    print(f"[scan] withdraw logs={n_logs} unique_users={len(users)} head={latest}", flush=True)

    counts = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        for u, c in zip(users, ex.map(count, users)):
            counts[u] = c
    pend = {u: c for u, c in counts.items() if c and c > 0}
    print(f"[scan] users_with_pending_requests={len(pend)} entries={sum(pend.values())}", flush=True)

    def get_reqs(u):
        n = pend[u]
        rs = []
        frm = 0
        while frm < n:
            to = min(frm + 20, n)
            raw = page(u, frm, to)[2:]
            off = int(raw[0:64], 16)
            ln = int(raw[off * 2 : off * 2 + 64], 16)
            base = off * 2 + 64
            for i in range(ln):
                a = int(raw[base + i * 128 : base + i * 128 + 64], 16)
                b = int(raw[base + i * 128 + 64 : base + i * 128 + 128], 16)
                rs.append((a, b))
            frm = to
        return rs

    reqs = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        for u, rs in zip(pend.keys(), ex.map(get_reqs, pend.keys())):
            reqs[u] = rs
    total_pending = sum(w for rs in reqs.values() for w, _ in rs)

    er = call(SEL_EXCHANGE_RATE)[2:]
    total_wei = int(er[0:64], 16)
    supply = int(er[64:128], 16)
    bal = int(rpc("eth_getBalance", [POOL, "latest"]), 16)
    reserve = int(call(SEL_CLAIM_RESERVE), 16)
    btu = to_signed(int(call(SEL_BNB_TO_UNBOND), 16))
    stk_supply = int(call(SEL_TOTAL_SUPPLY, to=STKBNB), 16)

    out = {
        "head_block": latest,
        "pool": POOL,
        "pool_balance_wei": bal,
        "claim_reserve_wei": reserve,
        "bnb_to_unbond": btu,
        "exchange_rate_total_wei": total_wei,
        "exchange_rate_supply": supply,
        "stkbnb_total_supply": stk_supply,
        "withdraw_log_count": n_logs,
        "unique_withdraw_users": len(users),
        "pending_request_users": len(pend),
        "pending_request_entries": sum(pend.values()),
        "pending_claims_wei_total": total_pending,
        "pending_claims_bnb": total_pending / 1e18,
    }
    os.makedirs("ci-out", exist_ok=True)
    json.dump(out, open("ci-out/ci_state.json", "w"), indent=1)
    json.dump(reqs, open("ci-out/pending_claims.json", "w"), indent=1)
    print(json.dumps(out, indent=1), flush=True)


if __name__ == "__main__":
    main()
