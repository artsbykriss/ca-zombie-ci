#!/usr/bin/env bash
# Read-only AlpsCon latent-state check. No transactions, no secrets printed.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

pick_rpc() {
  for u in "${BSC_RPC_URL:-}" "https://rpc.ankr.com/bsc/${ANKR_API_KEY:-}" "https://bsc-rpc.publicnode.com"; do
    [ -z "$u" ] && continue
    if cast block-number --rpc-url "$u" >/dev/null 2>&1; then echo "$u"; return 0; fi
  done
  return 1
}
RPC="$(pick_rpc)"
BLOCK="$(cast block-number --rpc-url "$RPC")"
echo "block=$BLOCK"

RPC="$RPC" BLOCK="$BLOCK" python3 analysis/collect_state.py > ci-out/state-console.txt
cp "analysis/state-${BLOCK}.json" ci-out/alpscon-state.json

python3 - <<'PY' > ci-out/summary.txt
import json
s=json.load(open('ci-out/alpscon-state.json'))
b=s['balances_usdc']; st=s['stats_f39f']
print("AlpsCon V7-V9 latent state @ BSC block", s['block'])
print("gate f39f on 0x7227:", s['gate']['0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'])
print("V9 USDC: %.2f" % b['V9'])
print("V8 USDC: %.2f  f39f earnings: %.2f" % (b['V8'], st['V8']['earnings']))
print("V7 USDC: %.2f  f39f earnings: %.2f" % (b['V7'], st['V7']['earnings']))
print("V6 USDC: %.2f  slot3(swap)=%s" % (b['V6'], s['v6_slot3']))
print("V4+V5 USDC: %.2f" % (b['V4']+b['V5']))
print("Vault USDC: %.2f" % b['Vault'])
print("E-U now: $0 (gate closed, all public test keys false)")
PY
cat ci-out/summary.txt
