#!/usr/bin/env bash
# Heavy CI job: independent reproducible build of marginfi-v2 @ c5d440f6 and hash comparison
# against the live on-chain program hash. Read-only: no mainnet tx, no secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
OUT="$ROOT/ci-out"; mkdir -p "$OUT"
RPC="${SOLANA_RPC:-https://api.mainnet-beta.solana.com}"
PROG="MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
COMMIT="c5d440f62365de503c89cf6ec39fb6673494cc7c"
EXPECT_ONCHAIN="eb7618369bec08691a7a4003e04f8fb34d95e7301e2b3b0c5439528e2b38cdab"

echo "=== [1/6] env ===" | tee "$OUT/00-env.txt"
{ uname -a; rustc --version || true; docker --version || true; nproc; free -h; } | tee -a "$OUT/00-env.txt"

echo "=== [2/6] install solana-verify ===" | tee -a "$OUT/00-env.txt"
if ! command -v solana-verify >/dev/null; then
  cargo install solana-verify --locked --quiet 2>&1 | tail -5 || true
fi
solana-verify --version 2>&1 | tee -a "$OUT/00-env.txt" || true

echo "=== [3/6] live on-chain hash (read-only RPC) ===" | tee -a "$OUT/00-env.txt"
solana-verify get-program-hash -u "$RPC" "$PROG" 2>&1 | tee "$OUT/10-onchain-hash.txt" || true

echo "=== [4/6] clone repo @ $COMMIT ===" | tee -a "$OUT/00-env.txt"
rm -rf /tmp/mfi-build
git clone --quiet https://github.com/0dotxyz/marginfi-v2 /tmp/mfi-build
cd /tmp/mfi-build && git checkout --quiet "$COMMIT" && git log -1 --format='%H %ci %s' | tee "$OUT/20-commit.txt"

echo "=== [5/6] solana-verify build (Docker, pinned toolchain) ===" | tee -a "$OUT/00-env.txt"
# [workspace.metadata.cli] pins solana = 3.1.13; solana-verify picks the matching image.
if solana-verify build --library-name marginfi -- --features mainnet-beta,custom-heap >"$OUT/30-build.log" 2>&1; then
  echo "BUILD OK" | tee -a "$OUT/30-build.log"
else
  echo "BUILD FAILED (see 30-build.log)" | tee -a "$OUT/30-build.log"
fi
tail -25 "$OUT/30-build.log"

echo "=== [6/6] local executable hash vs on-chain ===" | tee -a "$OUT/00-env.txt"
if [ -f target/deploy/marginfi.so ]; then
  LOCAL=$(solana-verify get-executable-hash target/deploy/marginfi.so 2>/dev/null | tail -1)
  echo "local_executable_hash=$LOCAL" | tee "$OUT/40-hash-compare.txt"
  echo "expected_onchain_hash=$EXPECT_ONCHAIN" | tee -a "$OUT/40-hash-compare.txt"
  if [ "$LOCAL" = "$EXPECT_ONCHAIN" ]; then
    echo "RESULT=MATCH  (deployed ELF == reproducible build of $COMMIT)" | tee -a "$OUT/40-hash-compare.txt"
  else
    echo "RESULT=MISMATCH" | tee -a "$OUT/40-hash-compare.txt"
  fi
  sha256sum target/deploy/marginfi.so | tee -a "$OUT/40-hash-compare.txt"
else
  echo "RESULT=NO_ARTIFACT" | tee -a "$OUT/40-hash-compare.txt"
fi
echo "done"
