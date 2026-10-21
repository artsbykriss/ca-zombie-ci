import json,urllib.request,sys
def mk(rpc):
    def rpcall(m,p):
        req=urllib.request.Request(rpc,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        return json.load(urllib.request.urlopen(req,timeout=40))
    return rpcall
rpcs={"eth":mk("https://ethereum-rpc.publicnode.com"),"avax":mk("https://api.avax.network/ext/bc/C/rpc"),"kaia":mk("https://public-en.node.kaia.io")}
checks=[("eth","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3"),
        ("avax","0xE893233515b7D02dD4e3D888162d4C87Dc837943"),
        ("kaia","0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11")]
for chain,h in checks:
    print("==",chain,h)
    for s in range(0,10):
        r=rpcs[chain]("eth_getStorageAt",[h,hex(s),"latest"])["result"]
        print(s,r)
