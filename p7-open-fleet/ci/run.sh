#!/usr/bin/env bash
# p7-open-fleet — CI helper for the FleetCommander donation-NAV-inflation PoC.
#
# Why this exists:
#   The workflow's "select ETH fork RPC" step only probes `eth_blockNumber`, so it happily picks
#   https://ethereum-rpc.publicnode.com, which does NOT serve archive state. Our tests fork at
#   historical blocks (Ethereum 25,471,347 / Arbitrum 518,241,570) and would fail. This script
#   probes candidates with a real `eth_call` at the target block and exports archive-capable
#   endpoints (FORK_RPC_URL / ARB_RPC_URL) into $GITHUB_ENV for the subsequent `forge test` step.
#
# It also runs the Foundry suite once and captures the -vvv log into ci-out/ (uploaded artifact),
# but always exits 0 so the workflow's own `forge test -vvv` step still runs and carries the
# pass/fail signal.
#
# Read-only: only `eth_call`. No secrets are printed or written to any repository file.

set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

ETH_BLOCK="0x184a973"   # 25,471,347
ARB_BLOCK="0x1ee4a86"   # 518,241,570
ETH_FLEET="0x98C49e13bf99D7CAd8069faa2A370933EC9EcF17"
ARB_FLEET="0x4F63cfEa7458221CB3a0EEE2F31F7424Ad34bb58"
TOTAL_ASSETS="0x01e1d114"

# probe_archive <url> <block> <to>  -> 0 when eth_call at <block> returns a result.
probe_archive() {
  local url="$1" block="$2" to="$3" r
  [ -z "$url" ] && return 1
  r=$(curl -s -m 25 -X POST -H 'Content-Type: application/json' \
        --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\",\"params\":[{\"to\":\"$to\",\"data\":\"$TOTAL_ASSETS\"},\"$block\"]}" \
        "$url" 2>/dev/null)
  case "$r" in *'"result"'*) return 0 ;; *) return 1 ;; esac
}

pick() { # pick <block> <to> <candidate...>  -> echoes a working URL, or nothing
  local block="$1" to="$2"; shift 2
  local i=0 u
  for u in "$@"; do
    i=$((i + 1))
    if probe_archive "$u" "$block" "$to"; then
      echo "[p7-open-fleet] archive candidate #$i OK for block $block" >&2
      echo "$u"; return 0
    fi
    echo "[p7-open-fleet] archive candidate #$i unavailable" >&2
  done
  return 1
}

echo "[p7-open-fleet] start $(date -u +%FT%TZ)"

ETH_ARCHIVE=$(pick "$ETH_BLOCK" "$ETH_FLEET" \
  "https://rpc.ankr.com/eth/${ANKR_API_KEY:-}" \
  "${NODEREAL_ETH_RPC_URL:-}" \
  "https://eth-mainnet.infura.io/v3/${INFURA_API_KEY:-}" \
  "https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY:-}" \
  "${RPC_URL:-}" \
  "${BLOCKPI_RPC_URL:-}" \
  "https://eth.drpc.org" \
  "https://rpc.payload.de" || true)

ARB_ARCHIVE=$(pick "$ARB_BLOCK" "$ARB_FLEET" \
  "https://rpc.ankr.com/arbitrum/${ANKR_API_KEY:-}" \
  "https://arbitrum-mainnet.infura.io/v3/${INFURA_API_KEY:-}" \
  "${ARB_RPC_URL:-}" \
  "https://1rpc.io/arb" \
  "https://arb1.arbitrum.io/rpc" || true)

# export for the following workflow steps
if [ -n "${GITHUB_ENV:-}" ]; then
  [ -n "$ETH_ARCHIVE" ] && echo "FORK_RPC_URL=$ETH_ARCHIVE" >>"$GITHUB_ENV"
  [ -n "$ARB_ARCHIVE" ] && echo "ARB_RPC_URL=$ARB_ARCHIVE" >>"$GITHUB_ENV"
fi

cat >ci-out/rpc-selection.json <<EOF
{
  "finding": "p7-open-fleet",
  "eth": { "block": "$ETH_BLOCK", "archive_rpc_found": $([ -n "$ETH_ARCHIVE" ] && echo true || echo false) },
  "arb": { "block": "$ARB_BLOCK", "archive_rpc_found": $([ -n "$ARB_ARCHIVE" ] && echo true || echo false) }
}
EOF

[ -n "$ETH_ARCHIVE" ] && export FORK_RPC_URL="$ETH_ARCHIVE"
[ -n "$ARB_ARCHIVE" ] && export ARB_RPC_URL="$ARB_ARCHIVE"

# Run the suite once for the artifact (non-fatal: the workflow's own step carries pass/fail).
if command -v forge >/dev/null 2>&1; then
  echo "[p7-open-fleet] running forge test (log -> ci-out/forge-test.log)"
  (cd poc && forge test -vvv) >ci-out/forge-test.log 2>&1 || true
  tail -n 5 ci-out/forge-test.log || true
else
  echo "[p7-open-fleet] forge not found; skipping local test run"
fi

echo "[p7-open-fleet] done $(date -u +%FT%TZ)"
exit 0
