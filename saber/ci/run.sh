#!/usr/bin/env bash
# C2-40 Saber PoC — custom CI job (runs from the finding folder on the CI runner).
#
# 1) builds the attacker "fake token program" to SBF bytecode (cargo-build-sbf)
# 2) runs the LiteSVM harness against the REAL deployed Saber + SPL Token bytecode
#    and the cloned mainnet USDC/USDT pool state
# 3) writes results to ci-out/ (uploaded as artifact)
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
mkdir -p ci-out

run_job() {
  echo "== Saber C2-40 PoC =="
  date -u
  echo "pwd: $ROOT"
  rustc --version || true
  cargo --version || true

  # ---- toolchain for SBF ----
  if ! command -v cargo-build-sbf >/dev/null 2>&1; then
    echo "[ci] installing Solana/Anza toolchain (for cargo-build-sbf)..."
    curl -sSfL https://release.anza.xyz/stable/install | sh || \
      curl -sSfL https://release.solana.com/stable/install | sh
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
  fi
  cargo-build-sbf --version || true

  cd "$ROOT/poc"

  echo "[ci] building malicious token program (SBF)..."
  cargo build-sbf --manifest-path malicious/Cargo.toml
  ls -la target/deploy/ || true

  MAL_SO="$ROOT/poc/target/deploy/malicious_token_program.so"
  if [ ! -f "$MAL_SO" ]; then
    echo "[ci] ERROR: malicious .so not found at $MAL_SO"
    return 1
  fi
  export MALICIOUS_SO="$MAL_SO"

  echo "[ci] running LiteSVM harness..."
  cargo test --release -p saber-poc-harness -- --nocapture --test-threads=1 || return 1
  echo "[ci] harness finished OK"
  ls -la "$ROOT/ci-out/" || true
  return 0
}

run_job 2>&1 | tee "$ROOT/ci-out/poc-run.log"
RC=${PIPESTATUS[0]}
echo "[ci] exit code: $RC"
exit "$RC"
