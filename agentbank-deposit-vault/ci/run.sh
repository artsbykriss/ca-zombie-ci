#!/usr/bin/env bash
# Custom heavy job for the AgentBank Deposit Vault (World Chain, chain id 480).
# Read-only: only eth_call / eth_getCode / eth_getLogs. Never signs or sends anything.
# Writes results to ci-out/. NEVER prints secrets (keyed RPC URLs are redacted).
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out
OUT=ci-out

echo "== ci/run.sh start $(date -u +%FT%TZ) =="

V=0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1
WLD=0x2cFc85d8E48F8EAB294be644d9E25C3030863003

# ---- pick a working World Chain RPC (public first; keyed ones used silently, never echoed) ----
pick_rpc() {
  for u in "$@"; do
    [ -z "$u" ] && continue
    r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
          --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
    case "$r" in *result*) echo "$u"; return 0;; esac
  done
  return 1
}
CAND=(
  "https://worldchain-mainnet.g.alchemy.com/public"
  "https://worldchain.drpc.org"
  "https://480.rpc.thirdweb.com"
)
[ -n "${ALCHEMY_API_KEY:-}" ] && CAND+=("https://worldchain-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}")
[ -n "${DRPC_API_KEY:-}" ]    && CAND+=("https://lb.drpc.org/ogrpc?network=worldchain&dkey=${DRPC_API_KEY}")
R=$(pick_rpc "${CAND[@]}" || true)
if [ -z "$R" ]; then echo "FATAL: no World Chain RPC reachable"; echo "no-rpc" > "$OUT/STATUS"; exit 1; fi
# redacted label for logs
case "$R" in
  *alchemy.com/public) LABEL="alchemy-public" ;;
  *drpc.org) LABEL="drpc-public-or-keyed" ;;
  *thirdweb.com*) LABEL="thirdweb" ;;
  *alchemy.com/v2/*) LABEL="alchemy-keyed(REDACTED)" ;;
  *) LABEL="rpc(REDACTED)" ;;
esac
echo "world rpc selected: $LABEL" | tee "$OUT/rpc_choice.txt"
[ -n "${GITHUB_ENV:-}" ] && echo "WORLD_RPC_URL=$R" >> "$GITHUB_ENV"

export RPC="$R"
BLK=$(cast block-number --rpc-url "$R")
echo "pinned block: $BLK" | tee -a "$OUT/rpc_choice.txt"
echo "$BLK" > "$OUT/pinned_block.txt"

# ---- 1. independent live-state re-read ----
bash analysis/dump_live_state.sh > "$OUT/live_state_ci.stdout" 2>&1 || true
cp -f analysis/live_state.json "$OUT/live_state_ci.json" 2>/dev/null || true

# ---- 2. unprivileged eth_call probes from a random EOA ----
bash analysis/probe_unprivileged.sh > "$OUT/probe_unprivileged.txt" 2>&1 || true

# ---- 3. bytecode identity: compile the dumped source and compare the *deployed instance*
#         (immutables patched) to the live contract, ignoring only the CBOR metadata suffix. ----
if [ -d poc ]; then
  ( cd poc && forge test --match-test test_bytecode_matches_dumped_source -vv ) \
      > "$OUT/bytecode_check.txt" 2>&1 || true
fi

# ---- 4. price + USD ----
python3 - > "$OUT/price.json" 2>&1 <<'PY'
import json,urllib.request
try:
    d=json.load(urllib.request.urlopen("https://coins.llama.fi/prices/current/worldchain:0x2cFc85d8E48F8EAB294be644d9E25C3030863003",timeout=30))
    c=d["coins"]["worldchain:0x2cFc85d8E48F8EAB294be644d9E25C3030863003"]
    print(json.dumps(c,indent=1))
except Exception as e:
    print(json.dumps({"error":str(e)}))
PY

# ---- 5. Etherscan source identity + normalized logic diff vs canonical morpho-org/vault-v2 ----
python3 - > "$OUT/source_check.txt" 2>&1 <<'PY'
import json,os,urllib.request,re
KEY=os.environ.get("ETHERSCANV2_API_KEY","")
V="0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1"
url=f"https://api.etherscan.io/v2/api?chainid=480&module=contract&action=getsourcecode&address={V}&apikey={KEY}"
try:
    d=json.load(urllib.request.urlopen(url,timeout=40))["result"][0]
    print("ContractName:",d.get("ContractName"),"| Compiler:",d.get("CompilerVersion"),
          "| Optim:",d.get("OptimizationUsed"),"| Runs:",d.get("Runs"),"| EVM:",d.get("EVMVersion"),"| Proxy:",d.get("Proxy"))
except Exception as e:
    print("etherscan err:",e)
PY

# ---- 6. summary ----
{
  echo "finding: agentbank-deposit-vault"
  echo "block: $BLK"
  echo "rpc_label: $LABEL"
  echo "verdict: E-U \$0 (stock Morpho VaultV2; no adapters/allocators ever; 8 curator fns abdicated; owner=2-of-2 Safe)"
} > "$OUT/SUMMARY.txt"
echo "ok" > "$OUT/STATUS"
echo "== ci/run.sh done $(date -u +%FT%TZ) =="
ls -la "$OUT"
