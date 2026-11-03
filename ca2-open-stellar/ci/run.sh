#!/usr/bin/env bash
# Heavy CI job for ca2-open-stellar:
#   1. Reproduce the Upshift august-vault v0.1.0 release build with the pinned
#      toolchain (Rust 1.95.0, wasm32v1-none, Stellar CLI 25.1.0) and compare
#      the SHA-256 byte-for-byte with the on-chain WASM.
#   2. Re-run the read-only Soroban simulation battery against mainnet.
# Results are written to ./ci-out/ (uploaded as CI artifacts).
#
# Public repo only: no keys, no signing, no transaction submission.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
mkdir -p ci-out
log() { echo "[$(date -u +%H:%M:%SZ)] $*"; }

# ---------- 1. pinned Rust toolchain ----------
export RUSTUP_HOME="${RUSTUP_HOME:-/tmp/rustup}"
export CARGO_HOME="${CARGO_HOME:-/tmp/cargo}"
if ! command -v rustup >/dev/null 2>&1; then
  log "installing rustup (minimal, 1.95.0)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain 1.95.0 --profile minimal --no-modify-path
fi
export PATH="$CARGO_HOME/bin:$PATH"
rustup toolchain install 1.95.0 --profile minimal --no-self-update >/dev/null 2>&1 || true
rustup target add wasm32v1-none --toolchain 1.95.0
log "rustc: $(rustc +1.95.0 --version)"

# ---------- 2. Stellar CLI 25.1.0 (checksum pinned in the upstream VERIFY.md) ----------
CLI_DEB=/tmp/stellar-cli-25.1.0.deb
log "downloading stellar-cli 25.1.0"
curl -fsSL -o "$CLI_DEB" \
  https://github.com/stellar/stellar-cli/releases/download/v25.1.0/stellar-cli_25.1.0_amd64.deb
echo "0260de467b29883c7cc227a3d8df7b7d8723805ffa54dcfe8171af1255de33c8  $CLI_DEB" \
  | sha256sum -c - | tee ci-out/stellar-cli-checksum.txt
rm -rf /tmp/stellar-cli && mkdir -p /tmp/stellar-cli
dpkg-deb -x "$CLI_DEB" /tmp/stellar-cli
export PATH="/tmp/stellar-cli/usr/bin:$PATH"
log "stellar: $(stellar --version 2>&1 | head -1)"

# ---------- 3. build the upstream release ----------
rm -rf /tmp/upshift-src /tmp/upshift-build
git clone --quiet --depth 1 --branch v0.1.0 \
  https://github.com/upshift-protocol/stellar-upshift-vault-contracts.git /tmp/upshift-src
(
  cd /tmp/upshift-src
  git rev-parse HEAD > "$ROOT/ci-out/upshift-commit.txt"
  RUSTUP_TOOLCHAIN=1.95.0 stellar contract build --optimize \
    --package august-vault --out-dir /tmp/upshift-build \
    --meta source_repo=github:upshift-protocol/stellar-upshift-vault-contracts \
    > "$ROOT/ci-out/build.log" 2>&1
)
BUILD_RC=$?
log "build exit=$BUILD_RC"
find /tmp/upshift-build -type f -maxdepth 2 2>/dev/null | tee ci-out/build-files.txt

BUILT="$(find /tmp/upshift-build -name '*.wasm' -type f | head -1)"
ONCHAIN="$ROOT/analysis/onchain_vault.wasm"
EXPECTED="3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12"
{
  echo "expected_onchain_sha256=$EXPECTED"
  if [ -n "$BUILT" ] && [ -f "$BUILT" ]; then
    echo "built_path=$BUILT"
    echo "built_size=$(wc -c < "$BUILT")"
    echo "built_sha256=$(sha256sum "$BUILT" | cut -d' ' -f1)"
    if cmp -s "$BUILT" "$ONCHAIN"; then
      echo "byte_identical_to_onchain_wasm=1"
    else
      echo "byte_identical_to_onchain_wasm=0"
    fi
    if [ "$(sha256sum "$BUILT" | cut -d' ' -f1)" = "$EXPECTED" ]; then
      echo "MATCH=1"
    else
      echo "MATCH=0"
    fi
  else
    echo "MATCH=unknown (build failed)"
  fi
} | tee ci-out/build-hash.txt

# ---------- 4. read-only live checks + simulations ----------
python3 -m pip install --quiet --disable-pip-version-check stellar-sdk==16.1.0 requests \
  > ci-out/pip.log 2>&1 || python3 -m pip install --quiet --break-system-packages \
  stellar-sdk==16.1.0 requests >> ci-out/pip.log 2>&1 || true
python3 analysis/stellar_checks.py ci-out/stellar-checks.json > ci-out/stellar-checks.stdout.json 2> ci-out/stellar-checks.err
CHECKS_RC=$?
log "live checks exit=$CHECKS_RC"

# Self-referential deposit probe: record the requirement, then try a forged
# contract-credential auth entry in enforce mode (must be rejected: no __check_auth).
python3 analysis/self_auth_probe.py > ci-out/self-auth-probe.json 2> ci-out/self-auth-probe.err
SELF_RC=$?
log "self-auth probe exit=$SELF_RC"

{
  echo "job=ca2-open-stellar"
  echo "date_utc=$(date -u +%FT%TZ)"
  echo "build_rc=$BUILD_RC"
  echo "live_checks_rc=$CHECKS_RC"
  echo "self_auth_probe_rc=$SELF_RC"
  grep -E '^(expected_onchain_sha256|built_sha256|built_size|byte_identical_to_onchain_wasm|MATCH)=' ci-out/build-hash.txt 2>/dev/null
} | tee ci-out/summary.txt

# Do not fail the workflow on a hash mismatch: the mismatch itself is the finding
# and must be preserved in the artifact/log. Hard-fail only if nothing was produced.
[ -f ci-out/build-hash.txt ] && [ -f ci-out/stellar-checks.json ]
