#!/usr/bin/env bash
# Kuru (Monad) — independent live-state + auth-probe job.
# Keyless public RPC only. Writes JSON to ci-out/. No secrets.
set -uo pipefail
R="${MONAD_RPC_URL:-https://rpc.monad.xyz}"
OUT="ci-out"
mkdir -p "$OUT"

rpc() { # $1 = method, $2 = params-json
  curl -s -m 20 -H 'content-type: application/json' -H 'User-Agent: Mozilla/5.0' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":$2}" "$R"
}

BN=$(rpc eth_blockNumber '[]' | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"])')
AC=0x264123a9B96Cc1193944cC25C188f1bD3dFa670e
MA=0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5
NATIVE=0000000000000000000000000000000000000000
ATTACKER=1111111111111111111111111111111111111111

ACBAL=$(rpc eth_getBalance "[\"$AC\",\"latest\"]" | python3 -c 'import sys,json;print(int(json.load(sys.stdin)["result"],16))')
MABAL=$(rpc eth_getBalance "[\"$MA\",\"latest\"]" | python3 -c 'import sys,json;print(int(json.load(sys.stdin)["result"],16))')
ACSZ=$(rpc eth_getCode "[\"$AC\",\"latest\"]" | python3 -c 'import sys,json;print((len(json.load(sys.stdin)["result"])-2)//2)')

# AccountCore.withdraw(26, native, 1e18, attacker) from a fresh address -> expect Unauthorized()
WITHDRAW_DATA=0x67f3e6c3$(printf '%064x' 26)000000000000000000000000$NATIVE$(printf '%064x' 1000000000000000000)000000000000000000000000$ATTACKER
AC_ATTACK=$(rpc eth_call "[{\"to\":\"$AC\",\"from\":\"0x$ATTACKER\",\"data\":\"$WITHDRAW_DATA\"},\"latest\"]" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("error",{}).get("data","OK"))')
# MarginAccount.withdraw(1e18, native) from a fresh address -> expect InsufficientBalance()
MA_DATA=0x00f714ce$(printf '%064x' 1000000000000000000)000000000000000000000000$NATIVE
MA_ATTACK=$(rpc eth_call "[{\"to\":\"$MA\",\"from\":\"0x$ATTACKER\",\"data\":\"$MA_DATA\"},\"latest\"]" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("error",{}).get("data","OK"))')

python3 - "$BN" "$ACBAL" "$MABAL" "$ACSZ" "$AC_ATTACK" "$MA_ATTACK" <<'PY' > "$OUT/kuru_ci_probe.json"
import json,sys
bn,acb,mab,acsz,aca,maa = sys.argv[1:]
print(json.dumps({
  "chain": "monad", "chain_id": 143, "rpc": "https://rpc.monad.xyz",
  "block": int(bn,16),
  "account_core": {"address":"0x264123a9B96Cc1193944cC25C188f1bD3dFa670e","proxy_code_bytes":int(acsz),"native_wei":int(acb),"native_mon":int(acb)/1e18},
  "margin_account": {"address":"0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5","native_wei":int(mab),"native_mon":int(mab)/1e18},
  "fresh_caller_probes": {
    "AccountCore.withdraw(26,native,1e18,attacker)": aca,
    "MarginAccount.withdraw(1e18,native)": maa
  },
  "expected": {"AccountCore":"0x82b42900 Unauthorized()","MarginAccount":"0xf4d678b8 InsufficientBalance()"}
}, indent=2))
PY

echo "=== ci-out/kuru_ci_probe.json ==="
cat "$OUT/kuru_ci_probe.json"
if [ "$AC_ATTACK" != "0x82b42900" ] || [ "$MA_ATTACK" != "0xf4d678b8" ]; then
  echo "RESULT: UNEXPECTED — the gate did NOT revert as expected"; exit 1
fi
echo "RESULT: gates hold on live Monad state (AccountCore Unauthorized, MarginAccount InsufficientBalance)"
