#!/usr/bin/env bash
curl -s -m 60 -X POST https://graphql.mainnet.sui.io/graphql -H 'Content-Type: application/json' --data-binary "$(jq -nc --arg q "$1" '{query:$q}')"
