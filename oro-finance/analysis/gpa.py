import sys, json, base64
sys.path.insert(0,'.')
from rpc import call
PID="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
def gpa(size=None, memcmp=None):
    f=[]
    if size: f.append({"dataSize":size})
    if memcmp: f.append({"memcmp":memcmp})
    return call("getProgramAccounts",[PID,{"encoding":"base64","filters":f}])
if __name__=="__main__":
    sizes=[10,27,45,107,108]
    out={}
    for s in sizes:
        try:
            r=gpa(s)
            out[s]=[{"pubkey":a["pubkey"],"lamports":a["account"]["lamports"],
                     "data":base64.b64encode(base64.b64decode(a["account"]["data"][0])).decode(),
                     "data_b58":None} for a in r]
            print(s, len(r))
        except Exception as e:
            print(s,"ERR",e)
    json.dump(out,open("progaccts.json","w"),indent=1)
