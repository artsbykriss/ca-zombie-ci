import json, urllib.request
RPC="https://ethereum-rpc.publicnode.com"
def rpc(method, params):
    req=urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(), headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=40))
def call(to,data):
    j=rpc("eth_call",[{"to":to,"data":data},"latest"])
    if "error" in j: return None
    return int(j["result"],16) if j["result"]!="0x" else 0
def bal(tok,who):
    return call(tok,"0x70a08231"+who[2:].rjust(64,"0"))
toks={"USDT":"0xdAC17F958D2ee523a2206206994597C13D831ec7","USDC":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","DAI":"0x6B175474E89094C44Da98b954EedeAC495271d0F","LINK":"0x514910771AF9Ca656af840dff83E8264EcF986CA","WETH":"0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","BIFI":"0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"}
whos={"TM":"0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5","etherH":"0x13000C4a215EfE7E414bB329b2F11c39BCF92D78","usdtH":"0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3","daiH":"0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3","linkH":"0x25567603eb61A4A49f27e433652B5B8940D10682","usdcH":"0x128647690C7733593aA3Dd149EeBC5e256E79217","owner":"0xf357a08C8D4A385Cebddb517a44b210A0F6b3393"}
for wn,w in whos.items():
    row={"who":wn,"addr":w,"eth":int(rpc("eth_getBalance",[w,"latest"])["result"],16)}
    for tn,t in toks.items(): row[tn]=bal(t,w)
    print(json.dumps(row))
