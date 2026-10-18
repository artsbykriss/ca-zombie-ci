#!/usr/bin/env python3
"""Consolidate Faiyah numbers from CI outputs into analysis/quant.json.

Inputs (produced by ci/run.sh):
  ci-out/claims_4142.json   - full enumeration of #41/#42 (claimable now + accrued)
  ci-out/claims_locked.json - #33/#37/#44/#45/#21 (locked accrued)
  ci-out/pools_state_v2.json - all-pool state
Price: DefiLlama XEF at 2026-10-18T00:xxZ (recorded in output).
"""
import json, os

XEF_USD = 0.0045238599273544336      # coins.llama.fi, ts 1792281184 (2026-10-18)
XEF_TS = 1792281184
USDT_USD = 0.9991443413527454
USDC_USD = 0.9998057232791859


def load(p, default=None):
    try:
        return json.load(open(p))
    except Exception:
        return default


def main():
    c4142 = load('ci-out/claims_4142.json', load('analysis/claims_4142.json', {'pools': {}}))
    clock = load('ci-out/claims_locked.json', load('analysis/claims_small.json', {'pools': {}}))
    state = load('ci-out/pools_state_v2.json', load('analysis/pools_state_v2.json', {'pools': {}}))
    out = {'block': state.get('block') or c4142.get('block'), 'timestamp': state.get('timestamp'),
           'xef_usd': XEF_USD, 'xef_price_ts': XEF_TS}

    def pool_state(i):
        i = int(i)
        direct = state.get('pools', {}).get(str(i)) or state.get('pools', {}).get(i)
        if direct:
            return direct
        for e in state.get('pools', {}).values():
            if e.get('idx') == i:
                return e
        return None

    # realized deficits (already paid out of principal)
    realized = {}
    for i, sym, dec, px in [(41, 'XEF', 18, XEF_USD), (42, 'XEF', 18, XEF_USD),
                            (9, 'USDT', 8, USDT_USD), (32, 'USDC', 6, USDC_USD)]:
        e = pool_state(i)
        if not e:
            continue
        deficit = e['deficit'] / 10 ** dec
        if i == 42:  # 650 XEF direct donation offsets part of the deficit
            deficit = max(0, deficit - 650.0)
        realized[i] = {'symbol': sym, 'amount': deficit, 'usd': deficit * px}

    # claimable now (H-O, entitled first movers)
    claim_now = {}
    for i in ('41', '42'):
        p = c4142.get('pools', {}).get(i)
        if p:
            claim_now[i] = {'xef': p['claimableNow'] / 1e18,
                            'usd': p['claimableNow'] / 1e18 * XEF_USD,
                            'count': p['claimableNowCount'],
                            'accruedTotal': p['accruedTotal'] / 1e18}

    # locked 2027 XEF pot
    locked = {}
    pot_xef = 0.0
    for i in ('33', '37', '44', '45'):
        p = clock.get('pools', {}).get(i)
        if p:
            amt = p['accruedTotal'] / 1e18
            locked[i] = {'xef': amt, 'usd': amt * XEF_USD}
            pot_xef += amt
    buffer33 = 200_000.0  # direct XEF balance above principal in #33 (funded buffer)
    net_unfunded = pot_xef - buffer33
    locked_total = {'xef': pot_xef, 'usd': pot_xef * XEF_USD,
                    'funded_buffer': buffer33,
                    'net_unfunded_xef': net_unfunded,
                    'net_unfunded_usd': net_unfunded * XEF_USD,
                    'note': 'CURRENT accrued snapshot (not claimable yet; locks run to 2027)'}

    # At each stake's 2027 unlock (stime + 1yr), interestTime=31,536,000 caps accrual at exactly
    # one year => accrued = principal * apr / 1e4 = 10% of principal for #33/#37/#44/#45.
    projected_xef = 0.0
    for i in ('33', '37', '44', '45'):
        e = pool_state(i)
        if e:
            projected_xef += e['totalStaked'] / 1e18 * e['apr'] / 1e4
    projected_net = projected_xef - buffer33
    projected = {'xef': projected_xef, 'usd': projected_xef * XEF_USD,
                 'net_unfunded_xef': projected_net, 'net_unfunded_usd': projected_net * XEF_USD,
                 'note': 'AT-UNLOCK projection: each stake accrues the full 1-year cap (10%); locks proven enforced (claim/unstake revert InvalidTimeRange until stime+delay)'}

    # annual accrual on the same pools
    accrual = {}
    total_yr = 0.0
    for i in ('33', '37', '44', '45', '41', '42'):
        e = pool_state(i)
        if e:
            rate = e['totalStaked'] / 1e18 * e['apr'] / 1e4
            accrual[i] = {'xef_per_year': rate, 'usd_per_year': rate * XEF_USD}
            total_yr += rate
    acc_total = {'xef_per_year': total_yr, 'usd_per_year': total_yr * XEF_USD}

    # RWA4 (#21): accrued but price unavailable
    p21 = clock.get('pools', {}).get('21')
    rwa4 = {'accrued': p21['accruedTotal'] / 1e18 if p21 else None,
            'buffer': 1_000_000.0, 'usd': None,
            'note': 'RWA4 has no observable USD price (Tamsa/DefiLlama); excluded from USD totals'}

    extractable_now = sum(v['usd'] for v in claim_now.values())
    out.update({
        'realized_deficits': realized,
        'realized_deficit_usd': sum(v['usd'] for v in realized.values()),
        'claimable_now': claim_now,
        'claimable_now_usd': extractable_now,
        'locked_2027_pot': locked,
        'locked_2027_current': locked_total,
        'locked_2027_projected_at_unlock': projected,
        'accrual_per_year': accrual,
        'accrual_total': acc_total,
        'rwa4_pool21': rwa4,
        'h_o_total_usd': extractable_now + projected['net_unfunded_usd'],
        'e_u_usd': 0.0,
        's_usd': 0.0,
        'p_note': 'owner EOAs can emergencyWithdraw; #9/#32/#10 belong to them (P, not S)',
    })
    json.dump(out, open('analysis/quant.json', 'w'), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == '__main__':
    main()
