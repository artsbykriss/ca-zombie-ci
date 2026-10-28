#!/usr/bin/env bash
# run.sh — CWA-2026-006 cross-chain feasibility enumeration + Desmos calibration (CI).
# READ-ONLY: public HTTPS GETs + release-binary downloads + static fingerprinting.
#
# The registry/live/binary enumeration (Phases A/B/C/D/E) is already captured in
# crosschain/ci-artifacts/; set ENUM=1 to re-run it. The Desmos-specific
# calibration (crosschain/desmos/ci/run.sh) always runs.
set -uo pipefail
cd "$(dirname "$0")/.."          # -> crosschain/
ROOT="$PWD"
mkdir -p "$ROOT/ci-out"

if [ "${ENUM:-0}" = "1" ]; then
  echo "=== env ==="
  python3 --version; (go version || true); (readelf --version | head -1 || true)

  echo "=== Phase A/B: chain-registry metadata + source go.mod ==="
  python3 ci/enumerate.py 2>&1 | tee "$ROOT/ci-out/phaseAB.log"

  echo "=== Phase D: read-only public LCD reads (node_info / wasm params / validators / height) ==="
  python3 ci/live.py 2>&1 | tee "$ROOT/ci-out/phaseD.log"

  echo "=== Phase C: release-binary fingerprint (PIE/stripped/Go/deps/wasmvm strings) ==="
  python3 ci/binfp.py 2>&1 | tee "$ROOT/ci-out/phaseC.log"

  echo "=== Phase E: pclntab symbol inventory ==="
  bash ci/symbols.sh 2>&1 | tee "$ROOT/ci-out/phaseE.log"
else
  echo "=== enumeration skipped (ENUM=1 to re-run); using preserved ci-artifacts/ ==="
fi

echo "=== Desmos-specific calibration (crosschain/desmos) ==="
if [ -f "$ROOT/desmos/ci/run.sh" ]; then
  bash "$ROOT/desmos/ci/run.sh" 2>&1 | tee "$ROOT/ci-out/desmos-phase.log"
else
  echo "no desmos/ci/run.sh"
fi

echo "=== summary ==="
ls -la "$ROOT/ci-out"
ls -la "$ROOT/ci-out/desmos" 2>/dev/null || true
