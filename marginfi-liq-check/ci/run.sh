#!/usr/bin/env bash
# marginfi-liq-check custom CI job: LiteSVM liquidation harness against cloned mainnet state.
# Runs from the finding folder on the CI runner. Results -> ci-out/.
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
mkdir -p ci-out

run_job() {
  echo "== marginfi-liq-check PoC =="
  date -u
  rustc --version || true
  cargo --version || true

  if ! command -v cargo >/dev/null 2>&1; then
    echo "[ci] installing Rust toolchain..."
    curl -sSfL https://sh.rustup.rs | sh -s -- -y --profile minimal || return 1
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi

  cd "$ROOT/poc"
  echo "[ci] running LiteSVM harness..."
  cargo test --release -- --nocapture --test-threads=1
  local rc=$?
  echo "[ci] harness exit=$rc"
  ls -la "$ROOT/ci-out/" || true
  return $rc
}

run_job 2>&1 | tee "$ROOT/ci-out/poc-run.log"
RC=${PIPESTATUS[0]}
echo "[ci] exit code: $RC"
exit "$RC"
