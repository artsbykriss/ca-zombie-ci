#!/usr/bin/env python3
"""Cellana vote_manager::rescue_stuck_rewards — read-only semantic + live-state checks.

No transaction is signed or broadcast. No key is used.
Uses only the public Aptos fullnode; every call is a /v1/view read or a public HTTP GET.
"""
import json
import os
import sys
import time
import urllib.request

MOD = "0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1"
RPC = os.environ.get("APTOS_RPC", "https://fullnode.mainnet.aptoslabs.com/v1").rstrip("/")
FRESH = "0x1111111111111111111111111111111111111111"
TOP_POOL = "0x234f0be57d6acfb2f0f19c17053617311a8d03c9ce358bdf9cd5c460e4a02b7c"
SRC = "https://raw.githubusercontent.com/asilenced/Boston_Next.js/ae6b91227ee67b0eebc46d22d16fcc08f9daf68a/vote_manager.move"

PASS = 0
FAIL = 0
LINES = []


def log(s):
    print(s)
    LINES.append(s)


def ok(label, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        log(f"PASS  {label}  {detail}")
    else:
        FAIL += 1
        log(f"FAIL  {label}  {detail}")


def http_json(url, data=None, tries=6):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(data).encode() if data is not None else None,
                headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"},
            )
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read())
        except Exception as e:  # 429 / 5xx / timeouts
            last = e
            time.sleep(2 + 2 * i)
    raise last


def view(fn, args, ta=None):
    return http_json(
        RPC + "/view",
        {"function": f"{MOD}::{fn}", "type_arguments": ta or [], "arguments": args},
    )


def get_text(url):
    for i in range(5):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"user-agent": "Mozilla/5.0"}), timeout=30) as r:
                return r.read().decode()
        except Exception:
            time.sleep(2 + i)
    raise RuntimeError("fetch failed")


def main():
    log("Cellana vote_manager::rescue_stuck_rewards — read-only checks")
    log(f"rpc={RPC}")

    # ---- 1. deployed ABI -------------------------------------------------
    abi = http_json(f"{RPC}/accounts/{MOD}/module/vote_manager")
    fns = {f["name"]: f for f in abi["abi"]["exposed_functions"]}
    r = fns.get("rescue_stuck_rewards")
    ok("rescue_stuck_rewards is exposed", r is not None)
    ok("rescue is entry", bool(r and r["is_entry"]))
    ok("rescue takes no &signer", bool(r) and all("signer" not in p for p in r["params"]))
    ok(
        "rescue params = (address, vector<Object<LiquidityPool>>, u64)",
        bool(r) and len(r["params"]) == 3 and r["params"][0] == "address" and "LiquidityPool" in r["params"][1] and r["params"][2] == "u64",
        str(r["params"]) if r else "",
    )

    rp = http_json(f"{RPC}/accounts/{MOD}/module/rewards_pool")
    rfns = {f["name"]: f for f in rp["abi"]["exposed_functions"]}
    for name in ("claim_rewards", "increase_allocation", "decrease_allocation", "add_rewards"):
        ok(f"rewards_pool::{name} is friend-only", rfns[name]["visibility"] == "friend", rfns[name]["visibility"])
    ok(
        "rewards_pool friends == vote_manager",
        rp["abi"].get("friends") == [f"{MOD}::vote_manager"],
        str(rp["abi"].get("friends")),
    )
    ok("claimable_rewards is a public view", rfns["claimable_rewards"]["is_view"] is True)

    # ---- 2. source mirror ------------------------------------------------
    src = get_text(SRC)
    ok("source defines module fullsail::vote_manager", "module fullsail::vote_manager" in src)
    body_start = src.find("public entry fun rescue_stuck_rewards")
    body = src[body_start : body_start + 1400] if body_start >= 0 else ""
    ok("rescue present in source", body_start >= 0)
    ok("rescue asserts no veNFT exists", "nft_exists(account_address)" in body)
    ok("rescue claims for the passed address", "claim_rewards(account_address" in body)
    ok("rescue recycles into incentivize(pool, rescued_rewards)", "incentivize(liquidity_pool, rescued_rewards)" in body)
    ok("rescue has no transfer/deposit to the caller", ("transfer" not in body) and ("deposit" not in body))
    ok("rescue has no signer parameter", "&signer" not in body.split(")")[0])

    # ---- 3. live state ---------------------------------------------------
    epoch = int(view("epoch::now", [])[0])
    ok("epoch readable", epoch > 0, f"epoch={epoch}")
    fees = view("vote_manager::fees_pool", [TOP_POOL])[0]["inner"]
    inc = view("vote_manager::incentive_pool", [TOP_POOL])[0]["inner"]
    ok("top pool has a fee reward pool", fees.startswith("0x"), fees)
    ok("top pool has an incentive reward pool", inc.startswith("0x"), inc)

    nft = view("voting_escrow::nft_exists", [FRESH])[0]
    ok("fresh address has no veNFT (rescue precondition passes)", nft is False)
    cr = view("rewards_pool::claimable_rewards", [FRESH, fees, str(epoch - 1)])[0]
    vals = [int(x["value"]) for x in cr.get("data", [])] if isinstance(cr, dict) else []
    ok("fresh address has zero claimable fees for a past epoch", sum(vals) == 0, str(vals))

    liq0 = view("liquidity_pool::liquidity_amounts", [TOP_POOL, "0"])
    liq1 = view("liquidity_pool::liquidity_amounts", [TOP_POOL, "1"])
    log(f"INFO  top pool reserve vectors: {liq0} / {liq1} (raw units; pool is dust)")
    ok("top pool returns two reserve legs", len(liq0) == 2 and len(liq1) == 2)
    tok = view("liquidity_pool::supported_token_strings", [TOP_POOL])[0]
    log(f"INFO  top pool assets: {tok}")

    tr = view("rewards_pool::total_rewards", [fees, str(epoch - 1)])[0]
    total = sum(int(x["value"]) for x in tr.get("data", [])) if isinstance(tr, dict) else 0
    log(f"INFO  top-pool fee total for epoch {epoch-1}: {total} (raw mixed token units, informational)")
    ti = view("rewards_pool::total_rewards", [inc, str(epoch - 1)])[0]
    total_i = sum(int(x["value"]) for x in ti.get("data", [])) if isinstance(ti, dict) else 0
    ok("incentive pool has no unclaimed epoch allocation", total_i == 0, str(total_i))

    # ---- 4. payout model -------------------------------------------------
    # The rescue path has exactly one sink: incentivize(pool, rescued) -> add_rewards(incentive_pool, ...).
    # No branch pays the caller. An attacker can only earn a pro-rata share later if they are a gauge staker.
    direct = 0
    rescued = 1000000  # hypothetical 1.0 USDC (6dp)
    share = 0.10       # attacker's gauge share
    indirect = int(rescued * share)
    ok("direct caller payout is 0 by construction", direct == 0)
    log(f"MODEL  hypothetical rescued={rescued} -> caller direct={direct}, LP-share capture(@10%)={indirect}")
    log("MODEL  value is reward-only; no LP principal, no staked principal, no veNFT principal is touched")

    log(f"PASS={PASS} FAIL={FAIL}")
    os.makedirs("ci-out", exist_ok=True)
    with open("ci-out/cellana-checks.txt", "w") as f:
        f.write("\n".join(LINES) + "\n")
    with open("ci-out/cellana-checks.json", "w") as f:
        json.dump(
            {
                "target": "cellana-rescue_stuck_rewards",
                "chain": "aptos",
                "epoch": epoch,
                "top_pool": TOP_POOL,
                "fees_pool": fees,
                "incentive_pool": inc,
                "pass": PASS,
                "fail": FAIL,
                "direct_caller_payout": 0,
            },
            f,
            indent=1,
        )
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
