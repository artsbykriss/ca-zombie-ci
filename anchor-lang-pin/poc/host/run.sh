#!/usr/bin/env bash
# Host-side anchor-lang validation PoC across versions.
# Builds the same probe against each anchor-lang version (separate crates, because
# cargo cannot hold two semver-compatible copies of one crate).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$HERE/../../ci-out}"
mkdir -p "$OUT"
VERS="${VERS:-1.0.0 1.0.1 1.0.2 1.0.3 1.2.1}"
: > "$OUT/host-poc.txt"
for v in $VERS; do
  d="$(mktemp -d)"
  mkdir -p "$d/src"
  cp "$HERE/src/main.rs" "$d/src/main.rs"
  cat > "$d/Cargo.toml" <<EOF
[package]
name = "anchor-pin-probe"
version = "$v"
edition = "2021"

[dependencies]
anchor-lang = "=$v"

[[bin]]
name = "probe"
path = "src/main.rs"
EOF
  echo "=== anchor-lang $v ===" | tee -a "$OUT/host-poc.txt"
  ( cd "$d" && cargo run --release --quiet 2>&1 ) | tee -a "$OUT/host-poc.txt"
  rm -rf "$d"
done
echo "wrote $OUT/host-poc.txt"
