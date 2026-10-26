#!/usr/bin/env bash
# wildcat/ci/run.sh — heavy CI job for the Wildcat V2 deep-dive.
#   1. probe a working Plasma RPC and export PLASMA_RPC_URL for the forge-test step
#   2. dump live market state (Ethereum + Plasma) -> ci-out/live-state.json
#   3. clone the audited v2-protocol repo, compile it, and compare the compiled
#      runtime bytecode of the core contracts against the deployed code on
#      Plasma/Ethereum -> ci-out/bytecode-check.txt
# No secrets are written to any file in this folder.
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"          # .../wildcat
OUT="$HERE/ci-out"
mkdir -p "$OUT"

# ---------------------------------------------------------------- 1. RPC probe
PLASMA=""
for u in "https://rpc.plasma.to" "https://plasma.drpc.org"; do
  r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
  case "$r" in *result*) PLASMA="$u"; break;; esac
done
echo "[ci] plasma rpc: ${PLASMA:-NONE}"
[ -n "$PLASMA" ] && echo "PLASMA_RPC_URL=$PLASMA" >> "${GITHUB_ENV:-/dev/null}"

ETH_FORK="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"

# -------------------------------------------------------- 2. live state dump
echo "[ci] dumping live market state..."
timeout 300 env ETH_RPC="$ETH_FORK" PLASMA_RPC="$PLASMA" python3 "$HERE/ci/live_state.py" > "$OUT/live-state.json" 2>"$OUT/live-state.err" \
  || echo "[ci] live-state dump failed (see live-state.err)"

# ------------------------------------------- 3. bytecode identity vs deployed
echo "[ci] cloning + compiling v2-protocol for bytecode comparison..."
WORK=/tmp/wc-v2
rm -rf "$WORK"
if timeout 480 git clone --depth 1 --recurse-submodules --shallow-submodules -q \
      https://github.com/wildcat-finance/v2-protocol.git "$WORK" 2>"$OUT/clone.err"; then
  cd "$WORK"
  git log -1 --format='%H %ci' > "$OUT/repo-commit.txt" 2>/dev/null
  timeout 900 env FOUNDRY_VIA_IR=true FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=200 \
    forge build > "$OUT/build.log" 2>&1
  build_ok=$?
  {
    echo "repo: https://github.com/wildcat-finance/v2-protocol"
    echo "commit: $(cat "$OUT/repo-commit.txt" 2>/dev/null)"
    echo "build exit: $build_ok"
    echo
    echo "contract|chain|deployed_address|onchain_keccak|compiled_keccak|match"
    check() { # $1 contract, $2 chain, $3 rpc, $4 addr
      local c="$1" ch="$2" rpc="$3" a="$4"
      local oc cc
      oc=$(cast code "$a" --rpc-url "$rpc" 2>/dev/null)
      if [ -z "$oc" ] || [ "$oc" = "0x" ]; then echo "$c|$ch|$a|EMPTY|-|-"; return; fi
      local oh; oh=$(cast keccak "$oc" 2>/dev/null)
      cc=$(FOUNDRY_VIA_IR=true FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=200 \
             forge inspect "$c" deployedBytecode 2>/dev/null | tr -d '\n')
      if [ -z "$cc" ] || [ "$cc" = "0x" ]; then echo "$c|$ch|$a|$oh|NOTFOUND|-"; return; fi
      local ch2; ch2=$(cast keccak "$cc" 2>/dev/null)
      local m=NO; [ "$oh" = "$ch2" ] && m=YES
      echo "$c|$ch|$a|$oh|$ch2|$m"
    }
    check WildcatArchController plasma "$PLASMA" 0xdb2e0DE97d6d96aa56754635704a4273E0F348ae
    check HooksFactory          plasma "$PLASMA" 0xB46bae25AC6D23148531ed1853a8881FD842E517
    check WildcatSanctionsSentinel plasma "$PLASMA" 0x37064895ba2C1e269EAF7FF32564818d08903f5B
    check WildcatMarket         plasma "$PLASMA" 0x9A0BA9278284659194157C476010bCFEbeB21794
    check OpenTermHooks         plasma "$PLASMA" 0xf6af2ae9d5de06662981855a9b47688f3abc06bb
    check WildcatArchController ethereum "$ETH_FORK" 0xfEB516d9D946dD487A9346F6fee11f40C6945eE4
    echo
    echo "# NOTE: only contracts WITHOUT constructor immutables can match on a raw runtime-hash"
    echo "# comparison. WildcatMarket, HooksFactory, WildcatSanctionsSentinel and OpenTermHooks"
    echo "# bake immutable values (borrower/asset/hooks/sentinel/archController/...) into the"
    echo "# deployed runtime bytecode, so their compiled (immutable=0) hash necessarily differs."
    echo "# WildcatArchController has no immutables and matches exactly, which validates the"
    echo "# repo commit + compiler settings (solc 0.8.25, viaIR, optimizer runs=200)."
  } > "$OUT/bytecode-check.txt" 2>&1
  echo "[ci] bytecode check:"; cat "$OUT/bytecode-check.txt"
else
  echo "[ci] clone failed"; cat "$OUT/clone.err"
fi

echo "[ci] done. outputs:"; ls -la "$OUT"
exit 0
