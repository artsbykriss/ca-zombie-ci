#!/usr/bin/env bash
# Heavy CI job for gimo-st0g (0G chain, chainId 16661).
# 1) re-verify the deployed bytecode against the explorer-published source
# 2) pin-block state + era cadence + claim enumeration + JIT economics
# Everything is read-only: eth_call / eth_getLogs / eth_getBalance only.
set -euo pipefail
cd "$(dirname "$0")/.."

export OG_RPC_URL="${OG_RPC_URL:-https://evmrpc.0g.ai}"
export PIN_BLOCK="${PIN_BLOCK:-47841263}"
export OUT_DIR="ci-out"
mkdir -p "$OUT_DIR"

echo "::group::source verification (solc 0.8.19, opt=1 runs=200)"
python3 ci/verify_source.py | tee "$OUT_DIR/source_verify.log"
echo "::endgroup::"

echo "::group::pin-block snapshot / era cadence / claims / economics"
python3 ci/snapshot.py | tee "$OUT_DIR/snapshot.log"
echo "::endgroup::"

echo "::group::summary"
python3 - <<'PY'
import json
s=json.load(open('ci-out/live_state.json'))
e=s['economics']; c=s['claims']; st=s['state']
print(f"block {s['block']} ts {s['block_timestamp']}")
print(f"rate {st['rate']/1e18}  supply {st['totalSupply']/1e18}  active {st['poolInfo']['active']/1e18}")
print(f"price ${e['price_0g_usd']}  TVL ${e['tvl_usd']:,.0f}")
print(f"era reward {e['era_reward_0g']:.2f} 0G (${e['era_reward_usd']:.2f}) -> NAV yield {e['annualised_nav_yield_pct']:.2f}%/yr")
print(f"claims outstanding {c['outstanding_0g']:.2f} 0G, matured {c['outstanding_matured_0g']:.2f} 0G, pool liquid {c['pool_liquid_0g']:.2f} 0G")
print(f"rateChangeLimit {st['rateChangeLimit']}  unbondingDuration {st['unbondingDuration']} eras")
ev=s['newera_events']
if ev:
    dt=[x['dt_s'] for x in ev if x['dt_s']]
    late=[x['late_s'] for x in ev if x['late_s'] is not None]
    print(f"newEra events {len(ev)} eras {ev[0]['era']}..{ev[-1]['era']}; dt min/max {min(dt)}/{max(dt)}s; late min/max {min(late)}/{max(late)}s")
PY
echo "::endgroup::"

ls -la "$OUT_DIR"
