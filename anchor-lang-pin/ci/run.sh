#!/usr/bin/env bash
# anchor-lang-pin custom heavy CI job.
# 1) host-side anchor-lang validation PoC across versions
# 2) OtterSec verified-programs breadth scan (which verified programs pin 1.0.0/1.0.1)
# 3) SBF build + LiteSVM end-to-end PoC (control)   [best-effort, non-fatal]
set -uo pipefail
cd "$(dirname "$0")/.."   # finding folder
mkdir -p ci-out
echo "=== anchor-lang-pin CI @ $(date -u +%FT%TZ) ===" | tee ci-out/ci-summary.txt
python3 --version | tee -a ci-out/ci-summary.txt

# ---------- 1) host PoC ----------
echo; echo "### 1) host-side validation PoC ###" | tee -a ci-out/ci-summary.txt
VERS="1.0.0 1.0.1 1.0.2 1.0.3" bash poc/host/run.sh "$PWD/ci-out" 2>&1 | tee -a ci-out/ci-summary.txt || true

# ---------- 2) breadth scan ----------
echo; echo "### 2) verified-programs breadth scan ###" | tee -a ci-out/ci-summary.txt
python3 analysis/verified_scan.py --workers 12 --out ci-out/verified-programs-anchor.json 2>&1 | tee -a ci-out/ci-summary.txt || true

# ---------- 3) SBF + LiteSVM control PoC ----------
echo; echo "### 3) SBF + LiteSVM end-to-end PoC (control) ###" | tee -a ci-out/ci-summary.txt
if ! command -v cargo-build-sbf >/dev/null 2>&1; then
  echo "[i] installing solana (agave) toolchain ..." | tee -a ci-out/ci-summary.txt
  curl -sSfL https://release.anza.xyz/stable/install -o /tmp/solana-install.sh 2>/dev/null \
    && sh /tmp/solana-install.sh >/tmp/solana-install.log 2>&1 || echo "[w] solana install failed" | tee -a ci-out/ci-summary.txt
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
if command -v cargo-build-sbf >/dev/null 2>&1; then
  set +e
  ( cd poc/sbf/noop && cargo build-sbf >/tmp/noop-build.log 2>&1 ) \
    && echo "[ok] noop built" | tee -a ci-out/ci-summary.txt \
    || { echo "[w] noop build failed" | tee -a ci-out/ci-summary.txt; tail -30 /tmp/noop-build.log | tee -a ci-out/ci-summary.txt; }
  for v in 1.0.1 1.0.2; do
    sed -i "s/version = \"=[0-9.]*\"/version = \"=$v\"/" poc/sbf/victim/Cargo.toml
    ( cd poc/sbf/victim && cargo build-sbf >/tmp/victim-$v-build.log 2>&1 ) \
      && echo "[ok] victim $v built" | tee -a ci-out/ci-summary.txt \
      || { echo "[w] victim $v build failed" | tee -a ci-out/ci-summary.txt; tail -30 /tmp/victim-$v-build.log | tee -a ci-out/ci-summary.txt; }
    find poc/sbf/victim/target -name '*.so' 2>/dev/null | head -3
    cp "$(find poc/sbf/victim/target -name 'victim.so' 2>/dev/null | head -1)" "ci-out/victim-$v.so" 2>/dev/null \
      || cp "$(find poc/sbf/victim/target -name '*.so' 2>/dev/null | head -1)" "ci-out/victim-$v.so" 2>/dev/null
  done
  NOOP=$(find poc/sbf/noop/target -name '*.so' 2>/dev/null | head -1)
  echo "noop so: $NOOP" | tee -a ci-out/ci-summary.txt
  if [ -n "$NOOP" ] && [ -f ci-out/victim-1.0.1.so ] && [ -f ci-out/victim-1.0.2.so ]; then
    ( cd poc/litesvm && cargo build --release >/tmp/litesvm-build.log 2>&1 ) \
      && echo "[ok] litesvm poc built" | tee -a ci-out/ci-summary.txt \
      || { echo "[w] litesvm poc build failed" | tee -a ci-out/ci-summary.txt; tail -40 /tmp/litesvm-build.log | tee -a ci-out/ci-summary.txt; }
    BIN=poc/litesvm/target/release/poc
    if [ -x "$BIN" ]; then
      echo "--- victim 1.0.1 (expect vulnerable) ---" | tee -a ci-out/litesvm-poc.txt
      "$BIN" "$PWD/ci-out/victim-1.0.1.so" "$PWD/$NOOP" vulnerable 2>&1 | tee -a ci-out/litesvm-poc.txt
      echo "--- victim 1.0.2 (expect patched) ---" | tee -a ci-out/litesvm-poc.txt
      "$BIN" "$PWD/ci-out/victim-1.0.2.so" "$PWD/$NOOP" patched 2>&1 | tee -a ci-out/litesvm-poc.txt
    fi
  else
    echo "[w] SBF artifacts missing; skipped LiteSVM PoC" | tee -a ci-out/ci-summary.txt
  fi
  set -e
else
  echo "[w] cargo-build-sbf unavailable; skipped SBF/LiteSVM PoC" | tee -a ci-out/ci-summary.txt
fi

echo; echo "=== ci-out contents ===" | tee -a ci-out/ci-summary.txt
ls -la ci-out | tee -a ci-out/ci-summary.txt
exit 0
