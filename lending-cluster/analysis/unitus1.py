import requests,subprocess
from eth_abi import decode,encode
RPC="https://evm.confluxrpc.com"
s=requests.Session(); s.headers.update({"Content-Type":"application/json","User-Agent":"research"})
def call(to,data):
    r=s.post(RPC,json={"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]},timeout=30).json()
    return r.get("result"),r.get("error")
def sel(x): return subprocess.check_output(["cast","sig",x]).decode().strip()
U="0xA377eCF53253275125D0a150aF195186271f6a56"
for name in ["comptrollerImplementation()","admin()","pendingAdmin()","oracle()","closeFactorMantissa()","liquidationIncentiveMantissa()","getAllMarkets()","getAlliTokens()","seizePaused()","transferPaused()","mintPaused(address)","borrowPaused(address)"]:
    d=sel(name)
    if "address" in name and "(" in name and name not in ("getAllMarkets()","getAlliTokens()"): pass
    res,err=call(U,d)
    print(name, res if res else err)
