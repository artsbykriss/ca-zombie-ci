#!/usr/bin/env python3
"""Read-only IOTA RPC helper for Pools Finance investigation."""
import json, sys, urllib.request, urllib.error

RPC = "https://api.mainnet.iota.cafe"
PKG = "0xc0d0341970ed92ff0d72f7419b8a812d9a98708dd8078dcc6f9d26c1b9c62332"

def rpc(method, params=None, rpc_url=RPC):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params or []}).encode()
    req = urllib.request.Request(rpc_url, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode())

def events(move_event_type, limit=50, cursor=None, descending=False, rpc_url=RPC):
    p = {"query":{"MoveEventType":move_event_type},"limit":limit,"descending":descending}
    if cursor: p["cursor"]=cursor
    return rpc("iotax_queryEvents",[p],rpc_url)

def txblocks(digests, rpc_url=RPC):
    return rpc("iota_multiGetTransactionBlocks",[digests,{"showInput":True,"showEffects":True,"showEvents":False,"showObjectChanges":True}],rpc_url)

def obj(oid, rpc_url=RPC):
    return rpc("iota_getObject",[oid,{"showType":True,"showOwner":True,"showContent":True}],rpc_url)

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "events":
        print(json.dumps(events(sys.argv[2], limit=int(sys.argv[3]) if len(sys.argv)>3 else 50), indent=1)[:4000])
