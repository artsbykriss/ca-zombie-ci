#!/usr/bin/env bash
# p7-open-unvtail heavy job: fork-probe the unverified-impl proxy tail.
# READ-ONLY. Fork-only. No mainnet tx. No secrets. Results -> ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."           # folder root
mkdir -p ci-out

echo "=== env sanity (names only) ==="
for v in OP_RPC_URL POLYGON_RPC_URL BSC_RPC_URL FORK_RPC_URL; do
  if [ -n "${!v:-}" ]; then echo "$v=set"; else echo "$v=UNSET"; fi
done

echo "=== foundry test ==="
cd poc
forge test -vvv > ../ci-out/forge-test.txt 2>&1
rc=$?
tail -c 20000 ../ci-out/forge-test.txt
echo "forge exit=$rc" | tee -a ../ci-out/forge-test.txt
cd ..

echo "=== validation + secret scan ==="
python3 ci/check.py 2>&1 | tee ci-out/validation.txt
vrc=${PIPESTATUS[0]}
echo "validation exit=$vrc"
exit 0
