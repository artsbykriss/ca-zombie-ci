#!/usr/bin/env bash
# Build the Singlepass drift harness against the two released 7.x versions and run the upstream
# regression shape. Vulnerable builds are expected to leak 8 native-stack bytes per iteration and
# fault; fixed builds must return normally.
#
# Local compiler test only: no network, no chain access, no state change.
set -uo pipefail
cd "$(dirname "$0")/../poc" || exit 1
ORIG="$(cat Cargo.toml)"
trap 'printf "%s\n" "$ORIG" > Cargo.toml' EXIT

run_case() {
  local ver="$1" name="$2"; shift 2
  local out rc
  out=$(./target/release/sp-drift-poc "$@" 2>&1)
  rc=$?
  out=$(printf '%s' "$out" | tr '\n' ' ')
  printf 'VERSION=%s CASE=%-16s EXIT=%-4s %s\n' "$ver" "$name" "$rc" "$out"
}

for ver in 7.4.2 7.5.0; do
  echo "===== wasmer $ver ====="
  sed -i "s|^wasmer = .*|wasmer = { version = \"=$ver\", default-features = false, features = [\"singlepass\", \"sys\"] }|" Cargo.toml
  if ! cargo build --release --quiet 2>build-$ver.err; then
    echo "BUILD_FAILED version=$ver"
    tail -40 build-$ver.err
    continue
  fi
  echo "build_ok version=$ver"
  run_case "$ver" spill31        --params 2 --prefix 31 --cond 0 --iters 400000
  run_case "$ver" spill32        --params 2 --prefix 32 --cond 0 --iters 400000
  run_case "$ver" oneparam       --params 1 --prefix 31 --cond 0 --iters 400000
  run_case "$ver" true_arm       --params 2 --prefix 31 --cond 1 --iters 400000
  run_case "$ver" no_spill       --params 2 --prefix 0  --cond 0 --iters 400000
  run_case "$ver" no_params      --params 0 --prefix 0  --cond 0 --iters 400000
  run_case "$ver" short_1k       --params 2 --prefix 31 --cond 0 --iters 1000
  run_case "$ver" explicit_else  --params 2 --prefix 31 --cond 0 --iters 400000 --body replace --explicit-else 1
  run_case "$ver" unreachable    --params 2 --prefix 31 --cond 0 --iters 400000 --body unreachable
  echo
done
