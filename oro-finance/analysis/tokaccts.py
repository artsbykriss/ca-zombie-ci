import sys,json,base64
sys.path.insert(0,'.')
import rpc2
from b58 import b58enc
def run(owner):
    for prog in ["TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"]:
        r=rpc2.call("getTokenAccountsByOwner",[owner,{"programId":prog},{"encoding":"jsonParsed"}])
        print("owner",owner,"count",len(r["value"]))
        for v in r["value"]:
            info=v["account"]["data"]["parsed"]["info"]
            print("  ",v["pubkey"],info["mint"],"amt",info["tokenAmount"]["amount"],info["tokenAmount"]["uiAmountString"],"state",info.get("state"))
if __name__=="__main__": run(sys.argv[1])
