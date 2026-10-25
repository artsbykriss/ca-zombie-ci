#!/usr/bin/env bash
# CI heavy job for pass6-open-tail: fork tests for O11 (Ink) and O12 (Ronin)
# plus a fork-free high-volume fuzz of the BondingCurveManager curve math.
# Runs on the public runner. No secrets are used or printed: the fork RPCs are keyless
# public endpoints (overridable by env; defaults hardcoded in the test files).
set -uo pipefail
cd "$(dirname "$0")/.."           # -> folder root
mkdir -p ci-out

# Keyless public fork endpoints (no API key, safe to appear in the public repo/logs).
export RONIN_RPC_URL="${RONIN_RPC_URL:-https://ronin.drpc.org}"
export INK_RPC_URL="${INK_RPC_URL:-https://rpc-gel.inkonchain.com}"

echo "[pass6-open-tail] forge test (fork: Ink + Ronin; fuzz: replica math)"
cd poc
forge test -vv --rpc-url "$RONIN_RPC_URL" --fork-retries 10 --fork-retry-backoff 2000 2>&1 \
  | tee ../ci-out/forge-test.log
rc=${PIPESTATUS[0]}
cd ..
printf '{"forge_test_exit": %s}\n' "$rc" > ci-out/ci_result.json

# --- Best-effort: reproduce the read-only Solana attacker-substitution sims (O13-O21) ---
# Light JSON-RPC only (simulateTransaction, sigVerify:false). Keyless public endpoints.
# Non-fatal: a flaky public RPC must not fail the fork-test job.
echo "[pass6-open-tail] Solana read-only sims (best-effort)"
{
  echo "== O13/O14/O15 =="
  ( cd analysis/o13-o15 && python3 run_sims.py O13 && python3 run_sims.py O14 && python3 run_sims.py O15 ) 2>&1 | tail -40
  echo "== O16-O21 =="
  ( cd analysis/o16-o21 && python3 scan_sim.py ) 2>&1 | tail -60
} > ci-out/solana-sims.log 2>&1 || echo "solana sims step returned non-zero (non-fatal)"
echo "done"
cat > ci-out/summary.txt <<'EOF'
O11 ChimeraQuoteHook404 (Ink): hook has no registered pools; hook/router/launch-liquidity hold
  0 native and 0 WETH; distributeQuotrons is a permissionless no-op for unregistered ids;
  configuration paths are platform/installer/creator-gated; fabricated-pool swap reverts.
O12 BondingCurveManager (Ronin): RONKE sits in the curve for graduation; the only way value
  leaves (sell) requires a prior buy (boughtFromCurve provenance); buy->sell round trip is
  never profitable incl. the partial-fill/Ceil branch; buyFor/closeCurve/registerLaunch are
  factory/graduationManager-gated; admin paths are Ownable-gated.
EOF
exit $rc
