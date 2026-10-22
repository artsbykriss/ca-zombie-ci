#!/usr/bin/env python3
"""Read-only live-state probe of the Infrared iBERA proxy (Berachain 80094).
Keyless public RPC only. No secrets. No transactions."""
import json, sys, urllib.request, os, time

RPC = os.environ.get("BERA_RPC", "https://rpc.berachain.com")
PROXY = "0x9b6761bf2397Bb5a6624a856cC84A3A14Dcd3fe5"
FRESH = "0x00000000000000000000000000000000DeaDBeef"
ID = 0

def rpc(method, params):
    global ID
    ID += 1
    body = json.dumps({"jsonrpc":"2.0","id":ID,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "content-type":"application/json",
        "user-agent":"Mozilla/5.0 (research; read-only)"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            if attempt == 3: return {"error":{"message":str(e)}}
            time.sleep(1.5)

def call(to, data, frm=None, value=None, block="latest"):
    tx = {"to":to, "data":data}
    if frm: tx["from"] = frm
    if value is not None: tx["value"] = hex(value)
    r = rpc("eth_call", [tx, block])
    if "error" in r:
        return "ERR:"+str(r["error"].get("message",r["error"]))[:160]
    return r.get("result")

def bal(addr, block="latest"):
    r = rpc("eth_getBalance",[addr, block])
    return r.get("result")

def code(addr):
    r = rpc("eth_getCode",[addr,"latest"])
    return r.get("result")

def storage(addr, slot):
    r = rpc("eth_getStorageAt",[addr, slot, "latest"])
    return r.get("result")

def dec(h):
    try: return int(h,16)
    except: return None

def main():
    out = {}
    blk = rpc("eth_blockNumber",[])["result"]
    out["latest_block"] = blk
    out["latest_block_dec"] = dec(blk)
    reads = {
        "name":"0x06fdde03","symbol":"0x95d89b41","decimals":"0x313ce567",
        "totalSupply":"0x18160ddd","totalAssets":"0x01e1d114","deposits":"0x323a5e0b",
        "asset":"0x38d52e0f","withdrawalsEnabled":"0xd0dbcd24","burnFee":"0xfce589d8",
        "proofTimestampBuffer":"0x329836c9","rateProvider":"0x949db658",
        "infrared":"0x21f96c65","depositor":"0xc7c4ff46","withdrawor":"0xc6326541",
        "receivor":"0x5147a19f","paused":"0x5c975abb",
        "currentImplementation":"0xd8bd5c29","implementation":"0x5c60da1b",
        "proxiableUUID":"0x52d1902d","UPGRADE_INTERFACE_VERSION":"0xad3cb1cc",
        "DEFAULT_ADMIN_ROLE":"0xa217fddf","PAUSER_ROLE":"0xe63ab1e9",
        "KEEPER_ROLE":"0x364bc15a","GOVERNANCE_ROLE":"0xf36c8f5c",
        "pending":"0xe20ccec3","confirmed":"0xa968991b",
        "maxDeposit(fresh)":"0x402d267d"+"0"*24+FRESH[2:].lower(),
        "maxWithdraw(fresh)":"0xce96cb77"+"0"*24+FRESH[2:].lower(),
        "maxRedeem(fresh)":"0xd905777e"+"0"*24+FRESH[2:].lower(),
        "convertToAssets(1e18)":"0x07a2d13a"+"0"*63+"1" if False else "0x07a2d13a0000000000000000000000000000000000000000000000000de0b6b3a7640000",
        "convertToShares(1e18)":"0xc6e6f5920000000000000000000000000000000000000000000000000de0b6b3a7640000",
        "previewBurn(1e18)":"0xdd5626cf0000000000000000000000000000000000000000000000000de0b6b3a7640000",
        "previewMint(1e18)":"0xb3d7f6b90000000000000000000000000000000000000000000000000de0b6b3a7640000",
        "balanceOf(fresh)":"0x70a08231"+"0"*24+FRESH[2:].lower(),
        "balanceOf(proxy)":"0x70a08231"+"0"*24+PROXY[2:].lower(),
    }
    out["views"] = {}
    for k,d in reads.items():
        out["views"][k] = call(PROXY, d)

    # unknown selector probe
    out["sel_fafe94a8"] = call(PROXY, "0xfafe94a8"+"0"*64)
    out["sel_297b1cc0"] = call(PROXY, "0x297b1cc0"+"0"*64)

    # storage slots
    out["eip1967_impl_slot"] = storage(PROXY,"0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")
    out["eip1967_admin_slot"] = storage(PROXY,"0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")
    out["eip1967_beacon_slot"] = storage(PROXY,"0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50")
    # OZ v5 initializable version? slot depends; try slot 0 and 1
    out["slot0"] = storage(PROXY,"0x0")
    out["slot1"] = storage(PROXY,"0x1")

    # native balances
    out["balances"] = {
        "proxy_native": bal(PROXY),
        "fresh_native": bal(FRESH),
    }

    # code sizes
    impl = out["eip1967_impl_slot"]
    if impl and impl != "0x"+"0"*64:
        impl_addr = "0x"+impl[-40:]
        out["impl_addr"] = impl_addr
        c = code(impl_addr)
        out["impl_code_size"] = (len(c)-2)//2 if c and c!="0x" else 0
    pc = code(PROXY)
    out["proxy_code_size"] = (len(pc)-2)//2 if pc and pc!="0x" else 0

    # getCode for candidate protocol contracts
    cands = {
        "depositor_0x04CddC538ea65908106416986aDaeCeFD4CAB7D7":"0x04CddC538ea65908106416986aDaeCeFD4CAB7D7",
        "factory_proxy_0xb71b3DaEA39012Fb0f2B14D2a9C86da9292fC126":"0xb71b3DaEA39012Fb0f2B14D2a9C86da9292fC126",
    }
    out["cand_code_sizes"] = {}
    out["cand_native"] = {}
    for k,a in cands.items():
        c = code(a)
        out["cand_code_sizes"][k] = (len(c)-2)//2 if c and c!="0x" else 0
        out["cand_native"][k] = bal(a)

    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
