#!/usr/bin/env bash
# Heavy CI job for the Infrared (iBERA, Berachain 80094) finding.
# Runs from the finding folder (infrared/) on the GitHub Actions runner.
#
#  1. fresh live-state snapshot + per-selector unprivileged probes   -> ci-out/
#  2. byte-exact source-identity proof of the implementation bytecode -> ci-out/
#
# Read-only: only eth_call / eth_getCode / eth_getBalance against the keyless
# public RPC. No transaction is ever signed or sent. No secrets are printed.
set -uo pipefail
cd "$(dirname "$0")/.."          # -> infrared/
mkdir -p ci-out

RPC="${BERA_RPC:-https://rpc.berachain.com}"
IMPL="0xC0654903c7d76F7FE63f9AD2F01618c3B55D9DcF"
PROXY="0x9b6761bf2397Bb5a6624a856cC84A3A14Dcd3fe5"
SOLC_URL="https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.8.26+commit.8a97fa7a"
SOLC="/tmp/solc-0.8.26"

echo "== [1/2] live-state snapshot =="
python3 analysis/probe.py           > ci-out/live_state_ci.json       2>&1 || echo "probe.py failed"
python3 analysis/probe_selectors.py > ci-out/selector_probe_ci.json   2>&1 || echo "probe_selectors.py failed"
python3 - <<'PY' > ci-out/summary_ci.txt 2>&1 || true
import json
d=json.load(open("ci-out/live_state_ci.json"))
v=d.get("views",{})
print("block:", d.get("latest_block_dec"))
print("name/symbol:", v.get("name"), v.get("symbol"))
print("totalSupply:", v.get("totalSupply"))
print("totalAssets/deposits:", v.get("totalAssets"))
print("asset:", v.get("asset"), " withdrawalsEnabled:", v.get("withdrawalsEnabled"), " paused:", v.get("paused"))
print("impl:", d.get("eip1967_impl_slot"), " admin_slot:", d.get("eip1967_admin_slot"))
print("depositor:", v.get("depositor"), " withdrawor:", v.get("withdrawor"), " receivor:", v.get("receivor"))
PY
echo "--- ci-out/summary_ci.txt ---"; cat ci-out/summary_ci.txt || true

echo "== [2/2] byte-exact source-identity proof of the implementation =="
if [ ! -x "$SOLC" ]; then
  curl -sSL -o "$SOLC" "$SOLC_URL" && chmod +x "$SOLC" || echo "WARN: could not download solc"
fi
"$SOLC" --version || true
set +e
python3 analysis/bytecode_identity.py \
    analysis/verified/ibera_impl.json "$IMPL" "$RPC" "$SOLC" \
    | tee ci-out/bytecode_identity.json
RC=${PIPESTATUS[0]}
set -e 2>/dev/null || true
if [ "${RC:-1}" = "0" ]; then
  echo "RESULT: deployed implementation bytecode == recompiled verified source (byte-exact)."
else
  echo "RESULT: bytecode identity check FAILED (rc=$RC) -- see ci-out/bytecode_identity.json"
fi
echo "== done =="
exit "${RC:-1}"
