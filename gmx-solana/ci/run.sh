#!/usr/bin/env bash
# CI heavy job for the GMX-Solana (GMTrade) residual-extraction study.
#
# Goal: independently verify the deployed store program's instruction surface by *building* the
# open-source repo at the audit commit (8af1e70) with the pinned toolchain (Solana 2.1.21 /
# Anchor 0.31.1) and comparing the resulting SBF ELF against the deployed program bytecode.
#
# Results are written to ci-out/ and uploaded as artifacts. No secrets are used here.
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/ci-out"
mkdir -p "$OUT"
echo "[ci] start $(date -u +%FT%TZ)"

SOLANA_VERSION="2.1.21"
AUDIT_COMMIT="8af1e70"
HEAD_COMMIT="f102501"

# --- 1. toolchain ------------------------------------------------------------------------------
if ! command -v cargo-build-sbf >/dev/null 2>&1; then
  echo "[ci] installing Solana $SOLANA_VERSION"
  sh -c "$(curl -sSfL "https://release.anza.xyz/v${SOLANA_VERSION}/install")" || \
  sh -c "$(curl -sSfL "https://release.solana.com/v${SOLANA_VERSION}/install")" || true
  export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo "[ci] rustc: $(rustc --version 2>&1)"
echo "[ci] cargo-build-sbf: $(command -v cargo-build-sbf || echo MISSING)"

# --- 2. source ---------------------------------------------------------------------------------
WORK="$HERE/ci-work"
rm -rf "$WORK"
git clone --quiet https://github.com/gmsol-labs/gmx-solana.git "$WORK" || { echo "clone failed"; exit 1; }
cd "$WORK"

build_commit() {
  local commit="$1" tag="$2"
  echo "[ci] === building $tag ($commit) ==="
  git checkout --quiet "$commit" || { echo "checkout $commit failed"; return 1; }
  rm -rf target/verifiable
  # Build only the on-chain program crates (the workspace also contains a CLI/SDK whose deps need a
  # newer rustc than the SBF toolchain provides). cargo-build-sbf's *artifact-copy* step still
  # enumerates every workspace cdylib (including the SDK), so we ignore its exit status and take the
  # compiled gmsol_store.so straight from the target directory.
  cargo build-sbf --sbf-out-dir target/verifiable -- \
    -p gmsol-store -p gmsol-treasury -p gmsol-timelock -p gmsol-callback \
    -p gmsol-competition -p gmsol-liquidity-provider -p gmsol-gt-incentive \
    -p gmsol-mock-chainlink-verifier 2>&1 | tail -12
  echo "[ci] candidate .so files:"; find target -name 'gmsol_store*.so' -printf '%s %p\n' 2>/dev/null | sort -rn | head
  # cargo-build-sbf may leave a small placeholder in the out-dir; take the largest real artifact.
  local so
  so="$(find target -name 'gmsol_store.so' -size +1M -printf '%s %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
  [ -n "$so" ] || so="$(find target -name 'gmsol_store.so' -printf '%s %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
  if [ -n "$so" ] && [ -f "$so" ]; then
    cp "$so" "$OUT/gmsol_store_${tag}.so"
    echo "[ci] $tag sha256: $(sha256sum "$so" | cut -d' ' -f1)  size: $(stat -c%s "$so")"
  else
    echo "[ci] $tag BUILD FAILED (no .so)"
  fi
}

build_commit "$AUDIT_COMMIT" "8af1e70"
build_commit "$HEAD_COMMIT" "f102501"

# --- 3. analyse built ELFs ---------------------------------------------------------------------
python3 "$HERE/ci/compare.py" "$OUT" | tee "$OUT/compare.txt"

echo "[ci] done $(date -u +%FT%TZ)"
