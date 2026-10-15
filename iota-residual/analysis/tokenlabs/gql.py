import json, urllib.request, sys
URL="https://graphql.mainnet.iota.cafe"
def gql(q, variables=None):
    req=urllib.request.Request(URL, data=json.dumps({"query":q,"variables":variables or {}}).encode(), headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)
if __name__=="__main__":
    q='{ events(first: 5, filter: {eventType: "0xe4abf8b6183c106282addbfb8483a043e1a60f1fd3dd91fb727fa284306a27fd::native_pool::StakedEvent"}) { nodes { timestamp sender { address } data transactionBlock { digest } } } }'
    print(json.dumps(gql(q), indent=1)[:3000])
