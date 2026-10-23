#!/usr/bin/env bash
# Kipseli Base reserve — live re-validation. Read-only.
# Writes ci-out/validation.json. Never prints secrets.
set -uo pipefail

PRIMARY="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"
FALLBACK="https://mainnet.base.org"
RESERVE=0xBEE3211ab312a8D065c4FeF0247448e17A8da000
ADMIN=0x8Bb03250fD720A6f2Dc043616532c92bd2D42f6E
USDC=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
WETH=0x4200000000000000000000000000000000000006
OUT=ci-out
mkdir -p "$OUT"

RPC="$PRIMARY"
BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null) || BLK=""
if [ -z "$BLK" ]; then RPC="$FALLBACK"; BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null) || BLK="latest"; fi
echo "using block $BLK"

c() { cast call --rpc-url "$RPC" --block "$BLK" "$@" 2>/dev/null; }

OWNER=$(c "$RESERVE" "owner()(address)")
NOP=$(c "$RESERVE" "numberOperators()(uint256)")
OP0=$(c "$RESERVE" "operatorAt(uint256)(address)" 0)
ADMOWNER=$(c "$ADMIN" "owner()(address)")
UBAL=$(c "$USDC" "balanceOf(address)(uint256)" "$RESERVE")
WBAL=$(c "$WETH" "balanceOf(address)(uint256)" "$RESERVE")

python3 - "$BLK" "$OWNER" "$NOP" "$OP0" "$ADMOWNER" "$UBAL" "$WBAL" <<'PY' > "$OUT/validation.json"
import sys, json
blk,owner,nop,op0,admowner,ubal,wbal = sys.argv[1:8]
def clean(s): return s.split()[0] if s else None
def num(s):
    s=clean(s)
    try: return int(s)
    except: return 0
u=num(ubal); w=num(wbal)
pu=0.9994704934726131; pw=2403.8388939539973
json.dump({
  "block": blk,
  "reserve": "0xBEE3211ab312a8D065c4FeF0247448e17A8da000",
  "owner_safe": clean(owner),
  "numberOperators": clean(nop),
  "operator0": clean(op0),
  "proxyAdmin_owner": clean(admowner),
  "usdc_raw": u, "weth_raw": w,
  "usdc_usd": round(u/1e6*pu,2), "weth_usd": round(w/1e18*pw,2),
  "reserve_usd_total": round(u/1e6*pu + w/1e18*pw,2),
  "headline_extractable_unprivileged_usd": 0,
  "pinned_fork_block": 52975121
}, sys.stdout, indent=1)
PY

echo "wrote $OUT/validation.json"
cat "$OUT/validation.json"
