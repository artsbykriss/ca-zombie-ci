#!/usr/bin/env bash
# ci/run.sh — read-only live-state snapshot for SaucerSwap V2 (Hedera mainnet, chainId 295).
# Keyless public endpoints only. Best-effort: never fails the CI job.
# Writes results to ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.." 2>/dev/null || true
OUT="ci-out"
mkdir -p "$OUT"

RPC="https://mainnet.hashio.io/api"                 # keyless Hedera JSON-RPC
MIRROR="https://mainnet-public.mirrornode.hedera.com/api/v1"
FACTORY_EVM="0x00000000000000000000000000000000003c3951"
FACTORY_ID="0.0.3946833"
NFPM_EVM="0x00000000000000000000000000000000003ddbb9"
POOL_TOPIC="0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118"

echo "[run] $(date -u +%FT%TZ) SaucerSwap V2 live-state snapshot" | tee "$OUT/summary.txt"

# chainId + block
CHAIN=$(curl -s -m 20 -X POST "$RPC" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' | sed 's/.*result":"//;s/".*//')
BLOCK=$(curl -s -m 20 -X POST "$RPC" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' | sed 's/.*result":"//;s/".*//')
echo "chainId=$CHAIN block=$BLOCK" | tee -a "$OUT/summary.txt"

# factory state
for fn in "owner()(address)" "rentPayer()(address)" "mintFee()(uint256)" "poolCreateFee()(uint256)"; do
  v=$(cast call "$FACTORY_EVM" "$fn" --rpc-url "$RPC" 2>/dev/null)
  echo "factory $fn = $v" | tee -a "$OUT/summary.txt"
done

# pool enumeration via mirror-node logs (paginate)
python3 - "$MIRROR" "$FACTORY_ID" "$POOL_TOPIC" "$OUT" <<'PY'
import json,sys,urllib.request,time
mirror,fid,topic,out=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
url=f"{mirror}/contracts/{fid}/results/logs?limit=100"
rows=[];pages=0
while url and pages<50:
    d=None
    for _ in range(4):
        try:
            with urllib.request.urlopen(url,timeout=30) as r: d=json.load(r); break
        except Exception: time.sleep(2)
    if d is None: break
    for lg in d.get('logs',[]):
        if lg['topics'] and lg['topics'][0]==topic:
            t0='0x'+lg['topics'][1][-40:]; t1='0x'+lg['topics'][2][-40:]
            fee=int(lg['topics'][3],16); data=lg['data'][2:]
            ts=int(data[:64],16)
            if ts>=2**23: ts-=2**24
            pool='0x'+data[64+24:128]
            rows.append(dict(block=lg['block_number'],ts=lg['timestamp'],token0=t0,token1=t1,fee=fee,tickSpacing=ts,pool=pool))
    nxt=d.get('links',{}).get('next')
    url=(mirror+nxt) if nxt else None
    pages+=1
json.dump(rows,open(f"{out}/pools.json","w"),indent=1)
print(f"POOLS {len(rows)} (unique {len(set(r['pool'] for r in rows))})")
PY

echo "[run] done" | tee -a "$OUT/summary.txt"
exit 0
