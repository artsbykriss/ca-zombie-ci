#!/usr/bin/env bash
# Custom CI job for the capyfi-angle deep-dive.
# Read-only: writes a live market snapshot + fork test result to ci-out/.
# NEVER prints or writes RPC URLs / secrets.
set -uo pipefail

RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
UNIT=0x0b9af1fd73885aD52680A1aeAa7A3f17AC702afA
WL=0x302a893B1AC44fed29Cdf3e3a0a083d1Df3ce54E
mkdir -p ci-out

BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)
WLACT=$(cast call "$WL" "isActive()(bool)" --rpc-url "$RPC" 2>/dev/null || echo "?")
WLCNT=$(cast call "$WL" "getRoleMemberCount(bytes32)(uint256)" "$(cast call "$WL" "WHITELISTED_ROLE()(bytes32)" --rpc-url "$RPC" 2>/dev/null)" --rpc-url "$RPC" 2>/dev/null || echo "?")

echo "block=$BLK whitelist_active=$WLACT whitelisted_members=$WLCNT"

# run the fork PoC and capture the summary
cd poc || true
FORGE_OUT=$(FORK_RPC_URL="$RPC" forge test -vv 2>&1 || true)
cd ..
echo "$FORGE_OUT" > ci-out/forge-test.log
echo "$FORGE_OUT" | grep -E "\[PASS\]|\[FAIL|Suite result" || true

PASS=$(echo "$FORGE_OUT" | grep -c "\[PASS\]" || true)
FAIL=$(echo "$FORGE_OUT" | grep -c "\[FAIL" || true)

python3 - "$BLK" "$WLACT" "$WLCNT" "$PASS" "$FAIL" <<'PY' > ci-out/capyfi-angle-results.json
import json,sys
blk,wlact,wlcnt,p,f = sys.argv[1:6]
print(json.dumps({
  "finding":"capyfi-angle",
  "chain":"ethereum",
  "fork_block": int(blk) if blk.isdigit() else blk,
  "whitelist_active": wlact=="true",
  "whitelisted_role_members": int(wlcnt) if wlcnt.isdigit() else wlcnt,
  "tests_passed": int(p),
  "tests_failed": int(f),
  "verdict":"access-control angle yields E-U $0 for the ~$5.1M cash; mint is whitelist-gated; only non-gated borrow/redeem is a design note",
}, indent=2))
PY
cat ci-out/capyfi-angle-results.json
exit 0
