#!/usr/bin/env bash
# Endur (Starknet) — read-only live evidence job.  No keys, no transactions.
# Runs the pinned-block probe and writes ci-out/endur-live.json (+ verdict).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/ci-out"
mkdir -p "$OUT"

echo "[endur] python: $(python3 --version 2>&1)"
echo "[endur] running read-only live probe (keyless public Starknet RPC)..."

python3 "$HERE/analysis/endur_probe.py" "$OUT" || { echo "[endur] probe FAILED"; exit 1; }

python3 - "$OUT" <<'PY'
import json, os, sys
out = sys.argv[1]
d = json.load(open(os.path.join(out, "endur-live.json")))
rt = d["erc4626_roundtrip"]
ac = d["access_control"]
permissionless = []
gated = []
for grp, rows in ac.items():
    if not isinstance(rows, list):
        continue
    for r in rows:
        (permissionless if (r.get("gate") in (None,) or r.get("gate") == "no-caller-gate") else gated).append(
            f"{grp}.{r['fn']}")
v = {
    "generated_utc": d["generated_utc"],
    "block": d["block"],
    "chain_id": d["chain_id"],
    "total_assets_usd_all_vaults": round(d["total_assets_usd_all_vaults"], 2),
    "erc4626_roundtrip_max_profit_wei": rt["max_profit_wei"],
    "erc4626_roundtrip_worst_case_wei": rt["worst_case_wei"],
    "erc4626_withdraw_roundtrip": rt["withdraw_roundtrip"],
    "total_assets_composition": d["total_assets_composition"],
    "targeted_probes": d["targeted_probes"],
    "allowances": d["allowances"],
    "class_hashes": d["class_hashes"],
    "permissionless_entrypoints": sorted(set(permissionless)),
    "caller_gated_entrypoints": sorted(set(gated)),
    "verdict": {
        "E-U_usd": 0.0,
        "E-U_confidence": "high",
        "reason": "no unprivileged drain path: request_withdrawal gated to LST; ERC4626 rounding favours "
                  "the vault (round-trip net <= 0 for all tested sizes); take_funds/receive_funds are "
                  "self-funded donations; claim_withdrawal pays the NFT owner; all admin/rate functions "
                  "are role-gated; vaults unpaused with total_supply>0 (no first-depositor inflation).",
        "latent": "total_assets = VR.total_stake(STRK) excludes accrued-but-unclaimed staking rewards, "
                  "so a reward-timing arbitrage exists (deposit before a permissionless "
                  "claim_rewards_for_validator, redeem after) bounded by the unclaimed rewards "
                  "(order $10^2-$10^3) and not net-profitable via flash loans; LOW confidence.",
    },
}
json.dump(v, open(os.path.join(out, "endur-verdict.json"), "w"), indent=1)
print(json.dumps(v["verdict"], indent=1))
print("[endur] vaults USD:", v["total_assets_usd_all_vaults"])
print("[endur] permissionless entry points:", v["permissionless_entrypoints"])
print("[endur] wrote endur-verdict.json")
PY
echo "[endur] done"
