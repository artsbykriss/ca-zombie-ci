from rpc import call,code,rpc
import json
POOL="0x3c3987a310ee13f7b8cbbe21d97d4436ba5e4b5f"
PROV="0x73a35ca19da0357651296c40805c31585f19f741"
def c(to,data,ch="soneium"):
    r=call(ch,to,data)
    return r.get("result") or r
print("pool code bytes", len(code("soneium",POOL).get("result","0x"))//2-1)
print("provider code bytes", len(code("soneium",PROV).get("result","0x"))//2-1)
print("ADDRESSES_PROVIDER",c(POOL,"0x0542975c"))
print("provider getPriceOracle",c(PROV,"0xfca513a8"))
print("provider getPriceOracleSentinel",c(PROV,cast_sig:=__import__('subprocess').check_output(["cast","sig","getPriceOracleSentinel()"]).decode().strip()))
print("reservesList",c(POOL,"0xd1946dbc"))
