#!/usr/bin/env python3
"""DexFi Aggregator Vault V2 scanner (read-only eth_call).

For each chain's DexFiVaultFactory enumerate vaults and, per vault, record:
  publishData, totalSupply, native balance, owner
  per farm: beacon, percent, connector, stakingToken, tokenId,
            token-farm liquidity/balance, NFT position (token0/token1/liq/owed)
            and the pool sqrtPriceX96 used to value the position.

RPC from env (BASE_RPC_URL, ...) or keyless public fallback. No secrets written.
"""
import json, os, sys, time, urllib.request

RPC = {
    "base":     os.environ.get("BASE_RPC_URL") or "https://mainnet.base.org",
    "arbitrum": os.environ.get("ARB_RPC_URL") or "https://arb1.arbitrum.io/rpc",
    "ethereum": os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com",
    "bsc":      os.environ.get("BSC_RPC_URL") or "https://bsc-dataseed.binance.org",
    "avax":     os.environ.get("AVAX_RPC_URL") or "https://api.avax.network/ext/bc/C/rpc",
    "sonic":    os.environ.get("SONIC_RPC_URL") or "https://rpc.soniclabs.com",
}
FACTORY = {
    "base":     "0xcb34f261a5284554bb9fea8aa12a0578c4ba3fc6",
    "arbitrum": "0x061f8132b344cb2a32d3895eb3ebc2ff87455f79",
    "ethereum": "0x4c1a8a04577286ce58d0723b1a90160f380e550a",
    "bsc":      "0xc9dc65aed28bdb016726d32d0f8c2cd5c9461961",
    "avax":     "0x5764dad2fd4b6918949c6ae86081819ca8c19749",
    "sonic":    "0x095d35c49d2d0ea2eba3e2f9e377966db35af7e2",
}
FALLBACKS = {
    "base":     ["https://mainnet.base.org", "https://base-rpc.publicnode.com", "https://base.llamarpc.com"],
    "arbitrum": ["https://arb1.arbitrum.io/rpc", "https://arbitrum-rpc.publicnode.com"],
    "ethereum": ["https://ethereum-rpc.publicnode.com", "https://eth.llamarpc.com", "https://rpc.ankr.com/eth"],
    "bsc":      ["https://bsc-dataseed.binance.org", "https://bsc-rpc.publicnode.com", "https://binance.llamarpc.com"],
    "avax":     ["https://api.avax.network/ext/bc/C/rpc", "https://avalanche-rpc.publicnode.com"],
    "sonic":    ["https://rpc.soniclabs.com", "https://sonic-rpc.publicnode.com"],
}
def working_rpc(chain, probe_to, probe_data):
    """Return the first RPC (env first, then public fallbacks) that answers a probe call."""
    cands = [RPC.get(chain)] + FALLBACKS.get(chain, [])
    seen = set()
    for u in cands:
        if not u or u in seen: continue
        seen.add(u)
        try:
            h = call_one(u, probe_to, probe_data)
            if h is not None:
                return u
        except Exception:
            continue
    return RPC.get(chain)

NATIVE = {
    "base": "0x4200000000000000000000000000000000000006",
    "arbitrum": "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    "ethereum": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    "bsc": "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
    "avax": "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
    "sonic": "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38",
}

# ---------------- keccak256 (pure python) ----------------
_RC=[0x0000000000000001,0x0000000000008082,0x800000000000808a,0x8000000080008000,0x000000000000808b,0x0000000080000001,0x8000000080008081,0x8000000000008009,0x000000000000008a,0x0000000000000088,0x0000000080008009,0x000000008000000a,0x000000008000808b,0x800000000000008b,0x8000000000008089,0x8000000000008003,0x8000000000008002,0x8000000000000080,0x000000000000800a,0x800000008000000a,0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
_R=[[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
_M=(1<<64)-1
def _rotl(x,n): return ((x<<n)|(x>>(64-n)))&_M
def _f(A):
    for rnd in range(24):
        C=[A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4] for x in range(5)]
        D=[C[(x-1)%5]^_rotl(C[(x+1)%5],1) for x in range(5)]
        for x in range(5):
            for y in range(5): A[x][y]^=D[x]
        B=[[0]*5 for _ in range(5)]
        for x in range(5):
            for y in range(5): B[y][(2*x+3*y)%5]=_rotl(A[x][y],_R[x][y])
        for x in range(5):
            for y in range(5): A[x][y]=B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y])&_M
        A[0][0]^=_RC[rnd]
    return A
def keccak(data):
    rate=136; P=bytearray(data); P.append(0x01)
    while len(P)%rate!=0: P.append(0)
    P[-1]^=0x80
    A=[[0]*5 for _ in range(5)]
    for off in range(0,len(P),rate):
        blk=P[off:off+rate]
        for i in range(rate//8):
            lane=int.from_bytes(blk[i*8:i*8+8],'little')
            A[i%5][i//5]^=lane
        A=_f(A)
    out=b""
    for i in range(4):
        out+=A[i%5][i//5].to_bytes(8,'little')
    return out
def selector(sig): return keccak(sig.encode())[:4].hex()
def enc_uint(x): return f"{int(x):064x}"
def enc_addr(a): return "0"*24 + a.lower().replace("0x","")
def dec_addr(h):
    if not h or len(h)<42: return None
    return "0x"+h[-40:]
def dec_uint(h):
    if not h or h=="0x": return None
    return int(h,16)

def rpc_batch(url, calls, retries=5):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]}
             for i,(t,d) in enumerate(calls)]
    body=json.dumps(payload).encode()
    for a in range(retries):
        try:
            req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req,timeout=120) as r:
                res=json.loads(r.read())
            if isinstance(res,dict): res=[res]
            out=[None]*len(calls)
            for item in res:
                i=item.get("id")
                if i is not None and "result" in item: out[i]=item["result"]
            return out
        except Exception:
            if a==retries-1: raise
            time.sleep(1.0*(a+1))
def call_one(url,to,data): return rpc_batch(url,[(to,data)])[0]

SEL = {n: selector(s) for n,s in {
    "vaultsCount":"vaultsCount()","vaults":"vaults(uint256)","owner":"owner()",
    "totalSupply":"totalSupply()","farmsCount":"farmsCount()","farms":"farms(uint256)",
    "farmConnector":"farmConnector(address)","publishData":"publishData()",
    "balanceOf":"balanceOf(address)","stakingToken":"stakingToken()","tokenId":"tokenId()",
    "positions":"positions(uint256)","liquidity":"liquidity(address)","slot0":"slot0()",
    "stakingTokenData":"stakingTokenData()","convertlessDepositRatio":"convertlessDepositRatio()",
}.items()}

def get_vault_addrs(url, fac, n):
    addrs=[None]*n
    for i in range(0,n,50):
        calls=[(fac,"0x"+SEL["vaults"]+enc_uint(j)) for j in range(i,min(i+50,n))]
        res=rpc_batch(url,calls)
        for k,h in enumerate(res):
            if i+k<n: addrs[i+k]=dec_addr(h)
    return addrs

def scan_vaults(chain, url, fac, addrs, tag):
    nat=NATIVE[chain]
    out=[]
    for idx,v in enumerate(addrs):
        if not v: continue
        rec={"vault":v}
        try:
            b=rpc_batch(url,[(v,"0x"+SEL["publishData"]),(v,"0x"+SEL["totalSupply"]),
                              (nat,"0x"+SEL["balanceOf"]+enc_addr(v)),(v,"0x"+SEL["farmsCount"]),
                              (v,"0x"+SEL["owner"])])
            pd=b[0]
            if pd and len(pd)>=130:
                rec["published"]=int(pd[2:66],16)!=0; rec["publisher"]=dec_addr("0x"+pd[90:130])
            rec["supply"]=dec_uint(b[1]); rec["nativeBal"]=dec_uint(b[2]); rec["owner"]=dec_addr(b[4])
            fc=dec_uint(b[3]) or 0; rec["farmsCount"]=fc
            farms=[]
            for j in range(fc):
                h=call_one(url,v,"0x"+SEL["farms"]+enc_uint(j))
                if not h or len(h)<194: continue
                beacon="0x"+h[2+64+24:2+128]; percent=int(h[2+128:2+192],16)
                conn=dec_addr(call_one(url,v,"0x"+SEL["farmConnector"]+enc_addr(beacon)))
                f={"beacon":beacon,"percent":percent,"connector":conn}
                if conn:
                    bb=rpc_batch(url,[(conn,"0x"+SEL["stakingToken"]),(conn,"0x"+SEL["tokenId"])])
                    f["stakingToken"]=dec_addr(bb[0]); f["tokenId"]=dec_uint(bb[1])
                    if f["tokenId"] and f["tokenId"]>0 and f["stakingToken"]:
                        pos=call_one(url,f["stakingToken"],"0x"+SEL["positions"]+enc_uint(f["tokenId"]))
                        if pos and len(pos)>=2+64*12:
                            def w(k): return pos[2+64*k:2+64*(k+1)]
                            f["pos_token0"]=dec_addr("0x"+w(2)); f["pos_token1"]=dec_addr("0x"+w(3))
                            f["pos_fee"]=int(w(4),16); f["pos_tickLower"]=int(w(5),16)
                            f["pos_tickUpper"]=int(w(6),16); f["pos_liq"]=int(w(7),16)
                            f["pos_owed0"]=int(w(10),16); f["pos_owed1"]=int(w(11),16)
                        # pool from stakingTokenData (struct w/ leading offset; pool=word2)
                        sd=call_one(url,conn,"0x"+SEL["stakingTokenData"])
                        if sd and len(sd)>=2+64*6:
                            pool=dec_addr("0x"+sd[2+128:2+192])
                            f["pool"]=pool
                            if pool:
                                s0=call_one(url,pool,"0x"+SEL["slot0"])
                                if s0 and len(s0)>=66: f["sqrtPriceX96"]=int(s0[2:66],16)
                    else:
                        if f["stakingToken"]:
                            f["liq"]=dec_uint(call_one(url,conn,"0x"+SEL["liquidity"]+enc_addr(conn)))
                            f["balance"]=dec_uint(call_one(url,f["stakingToken"],"0x"+SEL["balanceOf"]+enc_addr(conn)))
                farms.append(f)
            rec["farms"]=farms
        except Exception as e:
            rec["error"]=str(e)
        out.append(rec)
        if idx%50==0: print(f"[{chain}] {idx}/{len(addrs)}",flush=True)
    return out

if __name__=="__main__":
    chain=sys.argv[1] if len(sys.argv)>1 else "base"
    limit=int(sys.argv[2]) if len(sys.argv)>2 else None
    start=int(sys.argv[3]) if len(sys.argv)>3 else 0
    url=RPC[chain]; fac=FACTORY[chain]
    n=dec_uint(call_one(url,fac,"0x"+SEL["vaultsCount()"] if False else "0x"+SEL["vaultsCount"]))
    print(f"[{chain}] vaultsCount={n}",flush=True)
    addrs=get_vault_addrs(url,fac,n)
    addrs=addrs[start:(start+limit) if limit else n]
    out=scan_vaults(chain,url,fac,addrs,f"{start}_{limit}")
    od=os.environ.get("CI_OUT","ci-out")
    os.makedirs(od, exist_ok=True)
    fn=os.path.join(od,f"scan_{chain}.json")
    json.dump({"chain":chain,"vaultsCount":n,"records":out},open(fn,"w"),indent=1)
    print("wrote",fn,"records",len(out))
