#!/usr/bin/env bash
# Fetch creation info + source/verification for the EtherVista historical routers.
# READ-ONLY. Requires ETHERSCANV2_API_KEY in env:  source /home/heisenberg/CA/.env
# Never prints the key.
set -u
cd "$(dirname "$0")"
: "${ETHERSCANV2_API_KEY:?run: source /home/heisenberg/CA/.env first}"
BASE="https://api.etherscan.io/v2/api?chainid=1"
mkdir -p raw

ADDRS=(
0xeaaa41CB2a64b11FE761D41e747C032cdd60CACe
0xEad811d798020c635CF8DD4DDF31BDc5595b09f3
0xCEDd366065A146A039b92Db35756ecd7688Fcc77
0x25B929E4dC4248858f4a874d076961070D88de04
0x13f2632393Ad736C8aAB9EEcCbbD8BcFE5bB5371
0xA03626f924F550f615EbBbb6F024C250F9F0f3d4
0x2a27e4e1d2b97C5b8a2460df5342E0e9293D4fdf
0xB7c6c50d6DFc478E7b40906f582E14575E7D895A
0xDBF723f9Ee663fb643fB08F86829727f8140B2D6
0x9Bd63c5D44Ff28390DF1eAAFd4EB4Bd73E94A72A
0xBC3902178A02939BA53a18C8Dd374a3Fc17F9c5C
0x469424b628A9D2036e41496E814dB500d683b120
)

for a in "${ADDRS[@]}"; do
  curl -sS "$BASE&module=contract&action=getcontractcreation&contractaddresses=$a&apikey=$ETHERSCANV2_API_KEY" -o "raw/creation_${a}.json"
  sleep 0.3
  curl -sS "$BASE&module=contract&action=getsourcecode&address=$a&apikey=$ETHERSCANV2_API_KEY" -o "raw/source_${a}.json"
  sleep 0.3
done
echo "fetched creation+source for ${#ADDRS[@]} addresses"
