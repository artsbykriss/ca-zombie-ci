#!/usr/bin/env bash
set -euo pipefail
mkdir -p ci-out
cd poc
forge test --match-test "test_H08|test_guard" -vvv 2>&1 | tee ../ci-out/poc.log
