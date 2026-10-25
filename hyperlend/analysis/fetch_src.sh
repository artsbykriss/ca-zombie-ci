#!/usr/bin/env bash
# Fetch verified sources from Etherscan V2 (chainid configurable). Read-only.
set -u
cd "$(dirname "$0")"
KEY=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
CHAIN=${CHAIN:-999}
mkdir -p src
fetch(){
  local addr="$1" name="$2"
  curl -s -m 40 "https://api.etherscan.io/v2/api?chainid=$CHAIN&module=contract&action=getsourcecode&address=$addr&apikey=$KEY" \
   | python3 -c "
import sys,json
d=json.load(sys.stdin)
r=d.get('result')
if not r or not r[0].get('SourceCode'):
    print('NO SOURCE'); sys.exit(1)
sc=r[0]['SourceCode']
open('src/$name.raw','w').write(sc)
print('$name', r[0]['ContractName'], r[0]['CompilerVersion'], len(sc))
"
}
fetch "$1" "$2"
