#!/usr/bin/env python3
"""Read-only live-state reader for Ledgity Yield vaults (no secrets; public RPCs only).
Writes analysis/live_state.json. Uses eth_call via JSON-RPC; no keys embedded."""
import json, urllib.request, concurrent.futures, time

RPCS = {
    "ethereum": ["https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"],
    "base":     ["https://base-rpc.publicnode.com", "https://base.drpc.org", "https://1rpc.io/base", "https://mainnet.base.org"],
    "arbitrum": ["https://arbitrum-one-rpc.publicnode.com", "https://arb1.arbitrum.io/rpc", "https://1rpc.io/arb"],
    "linea":    ["https://rpc.linea.build", "https://linea-rpc.publicnode.com"],
    "sonic":    ["https://rpc.soniclabs.com"],
}

VAULTS = {
    "ethereum_lyUSD": ("ethereum", "0x3C769d0e8D21d380228dFB7918c6933bb6ecB6D4"),
    "ethereum_lyEUR": ("ethereum", "0x20968165B7d2cDF33aF632aAB3e0539848d44BC8"),
    "base_lyUSD":     ("base",     "0x916f179D5D9B7d8Ad815AC2f8570aabF0C6a6e38"),
    "base_lyEUR":     ("base",     "0xFaA1e3720e6Ef8cC76A800DB7B3dF8944833b134"),
    "arbitrum_lyUSD": ("arbitrum", "0x283F35b6406a0e19a786ed119869eF2c0fE157Ee"),
    "linea_lyUSD":    ("linea",    "0x43b3c64dbc95F9eD83795E051fc00014059e698F"),
    "sonic_lyUSD":    ("sonic",    "0x65f75c675Cc76474662DfBF7B6e8683764223001"),
}

SIGS = {
    "asset": "asset()(address)",
    "decimals": "decimals()(uint8)",
    "totalAssets": "totalAssets()(uint256)",
    "totalSupply": "totalSupply()(uint256)",
    "managementFeeRate": "managementFeeRate()(uint256)",
    "performanceFeeRate": "performanceFeeRate()(uint256)",
    "withdrawalFeeRate": "withdrawalFeeRate()(uint256)",
    "yieldAPR": "yieldAPR()(uint256)",
    "lastFeeTime": "lastFeeTime()(uint256)",
    "lastCompoundTime": "lastCompoundTime()(uint256)",
    "highWaterMark": "highWaterMark()(uint256)",
    "paused": "paused()(bool)",
    "owner": "owner()(address)",
    "liquidityManager": "liquidityManager()(address)",
    "feeRecipient": "feeRecipient()(address)",
    "hasBufferStrategy": "hasBufferStrategy()(bool)",
    "aToken": "aToken()(address)",
    "liquidityBufferRate": "liquidityBufferRate()(uint256)",
    "stakeForInstantWithdrawal": "stakeForInstantWithdrawal()(uint256)",
    "withdrawalRequestCount": "getWithdrawalRequestCount()(uint256)",
}
SELECTORS = {
    "asset": "0x38d52e0f", "decimals": "0x313ce567", "totalAssets": "0x01e1d114",
    "totalSupply": "0x18160ddd", "managementFeeRate": "0x2e9d1b2a",
    "performanceFeeRate": "0x", "withdrawalFeeRate": "0x", "yieldAPR": "0x",
    "lastFeeTime": "0x", "lastCompoundTime": "0x", "highWaterMark": "0x",
    "paused": "0x5c975abb", "owner": "0x8da5cb5b", "liquidityManager": "0x",
    "feeRecipient": "0x", "hasBufferStrategy": "0x", "aToken": "0x",
    "liquidityBufferRate": "0x", "stakeForInstantWithdrawal": "0x",
    "withdrawalRequestCount": "0x",
}
# selector for balanceOf(address)
BALANCEOF = "0x70a08231"

def rpc(url, method, params, tries=3):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, data=payload,
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1)
    raise last

def pick(urls):
    for u in urls:
        try:
            r = rpc(u, "eth_blockNumber", [])
            if "result" in r:
                return u
        except Exception:
            continue
    return None

def selector(sig):
    import hashlib
    name = sig.split("(")[0]
    params = sig[sig.index("("):sig.index(")")+1]
    h = hashlib.sha3_256 if False else None
    # keccak via eth_hash not available; use precomputed cast-like approach: call cast? No. Use simple keccak implementation.
    return "0x" + keccak(name + params)[:4].hex()

# minimal keccak256 (pure python) to avoid deps
def keccak(data: bytes) -> bytes:
    RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
          0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
          0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
          0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
          0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
          0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
    r = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
    def rol(x,n): return ((x<<n)|(x>>(64-n)))&0xFFFFFFFFFFFFFFFF
    rate=136
    data=bytearray(data)
    data.append(0x01)
    while len(data)%rate!=0: data.append(0)
    data[-1]|=0x80
    A=[[0]*5 for _ in range(5)]
    for off in range(0,len(data),rate):
        block=data[off:off+rate]
        for i in range(rate//8):
            x,y=i%5,i//5
            A[x][y]^=int.from_bytes(block[i*8:i*8+8],'little')
        for rnd in range(24):
            C=[A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4] for x in range(5)]
            D=[C[(x-1)%5]^rol(C[(x+1)%5],1) for x in range(5)]
            for x in range(5):
                for y in range(5): A[x][y]^=D[x]
            B=[[0]*5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2*x+3*y)%5]=rol(A[x][y],r[x][y])
            for x in range(5):
                for y in range(5):
                    A[x][y]=B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y])
            A[0][0]^=RC[rnd]
    out=b''
    for i in range(4):
        x,y=i%5,i//5
        out+=A[x][y].to_bytes(8,'little')
    return out

def sel(sig):
    return "0x"+keccak(sig.encode()).hex()[:8]

def main():
    out={"generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "chains": {}, "vaults": {}}
    rpc_by_chain={}
    for chain,urls in RPCS.items():
        u=pick(urls)
        rpc_by_chain[chain]=u
        if u:
            bn=int(rpc(u,"eth_blockNumber",[])["result"],16)
            out["chains"][chain]={"rpc_host": u.split("//")[1].split("/")[0], "block": bn}
    def call(chain, to, sig):
        u=rpc_by_chain[chain]
        data=sel(sig)
        r=rpc(u,"eth_call",[{"to":to,"data":data},"latest"])
        return r.get("result")
    def call_data(chain,to,data):
        u=rpc_by_chain[chain]
        r=rpc(u,"eth_call",[{"to":to,"data":data},"latest"])
        return r.get("result")

    for name,(chain,addr) in VAULTS.items():
        rec={"chain":chain,"address":addr}
        for k,sig in SIGS.items():
            try:
                rec[k]=call(chain,addr,sig)
            except Exception as e:
                rec[k]="ERR:"+str(e)
        # fee data
        try:
            rec["getFeeData"]=call_data(chain,addr,sel("getFeeData()"))
        except Exception as e:
            rec["getFeeData"]="ERR:"+str(e)
        # vault asset balance + aToken balance
        try:
            asset=rec.get("asset")
            if asset and asset!="ERR" and isinstance(asset,str):
                rec["vault_asset_balance"]=call_data(chain,asset,BALANCEOF+addr[2:].rjust(64,'0'))
            at=rec.get("aToken")
            if at and isinstance(at,str) and int(at,16)!=0:
                rec["vault_atoken_balance"]=call_data(chain,at,BALANCEOF+addr[2:].rjust(64,'0'))
        except Exception as e:
            rec["balance_err"]=str(e)
        out["vaults"][name]=rec
        print(name, "totalAssets=", rec.get("totalAssets"), "asset=", rec.get("asset"), "mgmtFee=", rec.get("managementFeeRate"), "lastFeeTime=", rec.get("lastFeeTime"))
    json.dump(out, open("ledgity/analysis/live_state.json","w"), indent=2)
    print("written ledgity/analysis/live_state.json")

if __name__=="__main__":
    main()
