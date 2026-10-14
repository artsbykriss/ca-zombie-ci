#!/usr/bin/env bash
# Fetch verified source for an address from Etherscan V2. Reads key from env (never written to files).
# Usage: ETHERSCANV2_API_KEY=... bash fetch_source.sh <address> <outfile>
set -euo pipefail
ADDR="$1"; OUT="$2"
curl -s --max-time 60 "https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address=${ADDR}&apikey=${ETHERSCANV2_API_KEY}" -o "$OUT"
python3 - "$OUT" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p))
r=d.get('result')
if isinstance(r,list) and r:
    x=r[0]
    print("ContractName:", x.get('ContractName'))
    print("Compiler:", x.get('CompilerVersion'), "Proxy:", x.get('Proxy'), "Impl:", x.get('Implementation'))
    src=x.get('SourceCode') or ''
    print("SourceCode length:", len(src))
else:
    print("result:", str(r)[:300])
PY
