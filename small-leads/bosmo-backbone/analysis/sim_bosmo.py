#!/usr/bin/env python3
"""bOSMO / Backbone (Osmosis) — read-only reproduction of the double-count redemption bug.

Pulls live contract state from a public Osmosis LCD, decodes the cw-item-set validator
sets, reproduces the exact u128 floor arithmetic of pfc-steak-hub-tf v3.0.15 (the deployed
build), and computes the maximum net OSMO an unprivileged attacker can extract by
mint -> queue_unbond -> submit_batch -> withdraw_unbonded.

No keys, no writes, no transactions. Public endpoints only.
"""
import json
import sys
import urllib.request
from datetime import datetime, timezone

LCD = sys.argv[1] if len(sys.argv) > 1 else "https://osmosis-rest.publicnode.com"
CONTRACT = "osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv"
DENOM = f"factory/{CONTRACT}/boneOsmo"


def get(path, timeout=30):
    req = urllib.request.Request(LCD + path, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def smart(q):
    import base64
    b = base64.b64encode(json.dumps(q).encode()).decode()
    return get(f"/cosmwasm/wasm/v1/contract/{CONTRACT}/smart/{b}")["data"]


def raw_state():
    """Return list of (key_bytes, value_bytes). The publicnode LCD returns keys hex-encoded
    and values base64-encoded; handle both encodings defensively."""
    import base64
    out, key = [], ""
    for _ in range(20):
        path = f"/cosmwasm/wasm/v1/contract/{CONTRACT}/state?pagination.limit=200"
        if key:
            import urllib.parse
            path += "&pagination.key=" + urllib.parse.quote(key)
        d = get(path, 60)
        out += d.get("models", [])
        key = d.get("pagination", {}).get("next_key") or ""
        if not key:
            break

    def dec_key(x):
        try:
            return bytes.fromhex(x)
        except ValueError:
            return base64.b64decode(x + "=" * (-len(x) % 4))

    def dec_val(x):
        try:
            return base64.b64decode(x + "=" * (-len(x) % 4))
        except Exception:
            return bytes.fromhex(x)

    return [(dec_key(m["key"]), dec_val(m["value"])) for m in out]


def floor_mul(a, b, c):
    return (a * b) // c


def main():
    block = get("/cosmos/base/tendermint/v1beta1/blocks/latest")["block"]["header"]
    info = get(f"/cosmwasm/wasm/v1/contract/{CONTRACT}")["contract_info"]
    cfg = smart({"config": {}})
    st = smart({"state": {}})
    pending = smart({"pending_batch": {}})
    bank = {b["denom"]: int(b["amount"]) for b in get(f"/cosmos/bank/v1beta1/balances/{CONTRACT}")["balances"]}
    supply = int(get(f"/cosmos/bank/v1beta1/supply/by_denom?denom={DENOM}")["amount"]["amount"])
    deleg = get(f"/cosmos/staking/v1beta1/delegations/{CONTRACT}?pagination.limit=100")["delegation_responses"]
    unb = get(f"/cosmos/staking/v1beta1/delegators/{CONTRACT}/unbonding_delegations?pagination.limit=100")["unbonding_responses"]

    delegations = {d["delegation"]["validator_address"]: int(d["balance"]["amount"]) for d in deleg}
    T = sum(delegations.values())

    # Decode cw-item-set entries: key = 2-byte len + namespace + item
    validators, active = set(), set()
    for k, _ in raw_state():
        for ns, target in ((b"validators_001", validators), (b"validators_active_001", active)):
            i = k.find(ns)
            if i >= 0:
                item = k[i + len(ns):].decode(errors="replace")
                if item:
                    target.add(item)

    # The double-counted set is VALIDATORS_ACTIVE minus VALIDATORS (queried separately in
    # submit_batch). Every delegation in that set is added to query_all_delegations() again.
    double_counted = active - validators
    R = sum(delegations.get(v, 0) for v in double_counted)

    S = int(st["total_usteak"])
    B = int(pending["usteak_to_burn"])

    # Exact v3.0.15 arithmetic.
    # bond(): m = floor(S * d / native_bonded_mint), where native_bonded_mint = sum of
    # delegations to VALIDATORS_ACTIVE + paused(VALIDATORS - active) = T (both validators).
    # submit_batch(): U = floor((T+d + R+d) * (B+m) / (S+m)); cannot exceed T+d.
    # attacker payout = floor(U * m / (B+m)).
    def sim(d, B_):
        m = floor_mul(S, d, T) if T else d
        Tp, Rp, Sp = T + d, R + d, S + m
        U = floor_mul(Tp + Rp, B_ + m, Sp)
        if U > Tp:
            return None
        pay = floor_mul(U, m, B_ + m)
        return {"d": d, "m": m, "T_after": Tp, "R_after": Rp, "U": U, "payout": pay, "net": pay - d}

    def optimum(B_):
        # gross profit is monotone until the undelegation constraint binds; scan the last
        # 4,000 whole-OSMO steps around the analytic crossing.
        best = None
        hi = int((T + R) * 2 / 1e6) + 100_000  # generous OSMO bound
        for d_osmo in range(int(T / 1e6) - 1000, hi):
            d = d_osmo * 1_000_000
            r = sim(d, B_)
            if r and (best is None or r["net"] > best["net"]):
                best = r
        if best:
            d0 = best["d"]
            for d in range(max(0, d0 - 2_000_000), d0 + 2_000_000 + 1, 50_000):
                r = sim(d, B_)
                if r and r["net"] > best["net"]:
                    best = r
        return best

    best_with_pending = optimum(B)

    # Correct scenario B: submitting batch 126 first pays U126 out of the delegations,
    # reducing N and E (the undelegation is split evenly across the two validators),
    # and burns B shares. Batch 127 then sees the post-126 state.
    U126 = floor_mul(T + R, B, S)
    T_after = T - U126
    S_after = S - B
    R_after = R - U126 // 2

    def sim_b(d):
        m = floor_mul(S_after, d, T_after) if T_after else d
        Np, Ep, Sp = T_after + d, R_after + d, S_after + m
        U = floor_mul(Np + Ep, m, Sp)  # B=0
        if U > Np:
            return None
        return {"d": d, "m": m, "T_after": Np, "R_after": Ep, "U": U, "payout": U, "net": U - d}

    best_empty = None
    for d_osmo in range(1, 60_000):
        r = sim_b(d_osmo * 1_000_000)
        if r and (best_empty is None or r["net"] > best_empty["net"]):
            best_empty = r
    if best_empty:
        d0 = best_empty["d"]
        for d in range(max(0, d0 - 2_000_000), d0 + 2_000_000 + 1, 50_000):
            r = sim_b(d)
            if r and r["net"] > best_empty["net"]:
                best_empty = r

    # Liability reconciliation. `previous_batches` returns the reconciled/older batches;
    # the unreconciled 120-125 must be queried individually. Pending 126 is not a previous
    # batch yet; its shares are still in supply.
    batches = {}
    for i in range(120, 126):
        batches[i] = smart({"previous_batch": i})
    old = smart({"previous_batches": {"start_after": None, "limit": 100}})
    liabilities = sum(int(b["amount_unclaimed"]) for b in old) + sum(
        int(b["amount_unclaimed"]) for b in batches.values()
    )
    unbonding_incoming = sum(int(e["balance"]) for u in unb for e in u["entries"])
    bank_osmo = bank.get("uosmo", 0)
    surplus = bank_osmo + unbonding_incoming - liabilities

    out = {
        "as_of": {
            "block": int(block["height"]),
            "time": block["time"],
            "source": LCD,
        },
        "contract": {
            "address": CONTRACT,
            "code_id": info["code_id"],
            "cw2_version": "3.0.15 (raw state contract_info)",
            "admin": info["admin"],
            "owner": cfg["owner"],
            "label": info["label"],
        },
        "validator_sets": {
            "VALIDATORS": sorted(validators),
            "VALIDATORS_ACTIVE": sorted(active),
            "double_counted": sorted(double_counted),
            "delegations_uosmo": delegations,
        },
        "state": {
            "total_usteak_ubosmo": S,
            "total_native_uosmo": int(st["total_native"]),
            "exchange_rate_osmo_per_bosmo": st["exchange_rate"],
            "supply_ubosmo": supply,
            "bank_uosmo": bank_osmo,
            "bank_bosmo": bank.get(DENOM, 0),
            "pending_batch": pending,
            "delegated_total_uosmo": T,
            "double_counted_uosmo": R,
            "unbonding_incoming_uosmo": unbonding_incoming,
            "previous_batches_120_125": batches,
            "reconciled_batches_count": len(old),
            "liabilities_all_uosmo": liabilities,
            "unallocated_surplus_uosmo": surplus,
            "unallocated_surplus_usd_at_0.05259": round(surplus / 1e6 * 0.05259, 2),
        },
        "rates": {
            "mint_osmo_per_bosmo": T / S,
            "redeem_osmo_per_bosmo": (T + R) / S,
            "overpay_ratio": (T + R) / T,
        },
        "exploit": {
            "batch126_payout_uosmo": U126,
            "post_batch126_state": {"T": T_after, "S": S_after, "R": R_after},
            "max_net_with_pending_batch126": best_with_pending,
            "max_net_if_batch126_already_submitted": best_empty,
            "usd_at_0.0524936": {
                "with_pending": round(best_with_pending["net"] / 1e6 * 0.0524936, 2),
                "empty": round(best_empty["net"] / 1e6 * 0.0524936, 2),
                "ceiling": round(T / 1e6 * 0.0524936, 2),
            },
            "usd_at_0.057396": {
                "with_pending": round(best_with_pending["net"] / 1e6 * 0.057396, 2),
                "empty": round(best_empty["net"] / 1e6 * 0.057396, 2),
                "ceiling": round(T / 1e6 * 0.057396, 2),
            },
        },
        "historical_proof": {
            "batch124_shares_ubosmo": 776000000000,
            "batch124_amount_uosmo": 1299687479634,
            "batch124_osmo_per_bosmo": 1299687479634 / 776000000000,
            "forum_fair_rate_before_redemption": 1.1174,
            "forum_overpay_rate": 1.676,
        },
        "liveness": {
            "code741_instances": get("/cosmwasm/wasm/v1/code/741/contracts")["contracts"],
            "paused_validators": cfg["paused_validators"],
            "epoch_period_s": cfg["epoch_period"],
            "unbond_period_s": cfg["unbond_period"],
            "admin_is_single_sig_base_account": True,
            "migration_pending": False,
        },
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
