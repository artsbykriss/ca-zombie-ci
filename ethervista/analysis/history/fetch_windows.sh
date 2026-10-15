#!/usr/bin/env bash
# Fetch target pair token transfers inside the router-flip windows (Mar/Apr 2026 + Oct 9 attack window).
# READ-ONLY. Requires ETHERSCANV2_API_KEY:  source /home/heisenberg/CA/.env
set -u
cd "$(dirname "$0")"
: "${ETHERSCANV2_API_KEY:?source /home/heisenberg/CA/.env first}"
BASE="https://api.etherscan.io/v2/api?chainid=1"
PAIR=0xfdd05552F1377aA488AFed744c8024358AF02041
mkdir -p raw

fetch_block() { # $1=epoch -> block number (closest before)
  curl -sS "$BASE&module=block&action=getblocknobytime&timestamp=$1&closest=before&apikey=$ETHERSCANV2_API_KEY" | jq -r '.result'
  sleep 0.3
}

W() { # $1=label $2=start-utc $3=end-utc
  local label=$1 s e bs be
  s=$(date -u -d "$2" +%s); e=$(date -u -d "$3" +%s)
  bs=$(fetch_block "$s"); be=$(fetch_block "$e")
  curl -sS "$BASE&module=account&action=tokentx&address=$PAIR&startblock=$bs&endblock=$be&sort=asc&apikey=$ETHERSCANV2_API_KEY" -o "raw/pair_tokentx_${label}.json"
  sleep 0.3
  echo "$label | start=$2 ($s) block=$bs | end=$3 ($e) block=$be"
}

W w1_mar07     "2026-03-07 01:00:00 UTC" "2026-03-07 02:30:00 UTC"
W w2_apr07_08  "2026-04-07 18:00:00 UTC" "2026-04-08 12:00:00 UTC"
W w3_apr21     "2026-04-21 02:45:00 UTC" "2026-04-21 04:00:00 UTC"
W w4_oct09     "2026-10-09 03:30:00 UTC" "2026-10-09 04:30:00 UTC"
echo "done"
