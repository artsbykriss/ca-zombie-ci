#!/usr/bin/env bash
# etherfi-borrowing — read-only live-state capture (Optimism).
# Keyless public RPC by default; optionally uses $OP_RPC_URL if provided by CI.
# NEVER prints or stores RPC URLs / secrets. Writes ci-out/etherfi-borrowing-live.json.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[etherfi-borrowing] start $(date -u +%FT%TZ)"

python3 - <<'PY'
import json, os, urllib.request, time

RPC = os.environ.get("OP_RPC_URL") or "https://optimism.gateway.tenderly.co"

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research)"})
    for _ in range(3):
        try:
            return json.load(urllib.request.urlopen(req, timeout=30)).get("result")
        except Exception:
            time.sleep(2)
    return None

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def call_raw(from_addr, to, data):
    """Returns the full JSON-RPC response (so reverts/errors are captured)."""
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"from": from_addr, "to": to, "data": data}, "latest"]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (research)"})
    for _ in range(3):
        try:
            return json.load(urllib.request.urlopen(req, timeout=30))
        except Exception:
            time.sleep(2)
    return {"error": "unreachable"}

def selector(sig):
    # keccak256 via eth? compute with hashlib-free minimal keccak
    import hashlib
    # use eth_call keccak? simplest: shell-out not available; implement keccak256
    return _keccak(sig.encode())[:4]

# --- minimal keccak256 (for selectors only) ---
_KECCAK_RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,0x000000000000008A,
0x0000000000000088,0x0000000080008009,0x000000008000000A,0x000000008000808B,0x800000000000008B,
0x8000000000008089,0x8000000000008003,0x8000000000008002,0x8000000000000080,0x000000000000800A,
0x800000008000000A,0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
_KECCAK_R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
def _rol(x,n): n%=64; return ((x<<n)|(x>>(64-n)))&0xFFFFFFFFFFFFFFFF
def _keccak(data):
    rate=136; data=bytearray(data); data.append(0x01)
    while len(data)%rate!=0: data.append(0x00)
    data[-1]|=0x80
    st=[[0]*5 for _ in range(5)]
    for off in range(0,len(data),rate):
        blk=data[off:off+rate]
        for i in range(rate//8):
            lane=int.from_bytes(blk[i*8:i*8+8],'little')
            st[i%5][i//5]^=lane
        for rnd in range(24):
            C=[st[x][0]^st[x][1]^st[x][2]^st[x][3]^st[x][4] for x in range(5)]
            D=[C[(x-1)%5]^_rol(C[(x+1)%5],1) for x in range(5)]
            for x in range(5):
                for y in range(5): st[x][y]^=D[x]
            B=[[0]*5 for _ in range(5)]
            for x in range(5):
                for y in range(5): B[y][(2*x+3*y)%5]=_rol(st[x][y],_KECCAK_R[x][y])
            for x in range(5):
                for y in range(5): st[x][y]=B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y])
            st[0][0]^=_KECCAK_RC[rnd]
    out=b''
    for i in range(4):
        out+=st[i%5][i//5].to_bytes(8,'little')
    return out

def enc_addr(a): return a.lower().replace('0x','').rjust(64,'0')
def enc_uint(n): return hex(n)[2:].rjust(64,'0')

SPOKE="0xdffcC3536D932eb51Df51a7F5FA407c4270d5308"
HUB="0x66753c4e3fC84f1eD0e3C267C927284E9d90C572"
ORACLE="0xe8cbd37210bF1E29436dAe183d7b9fe45E886fA8"
DP="0xDC515Cb479a64552c5A11a57109C314E40A1A778"
FACTORY="0xF4e147Db314947fC1275a8CbB6Cde48c510cd8CF"
LG="0x01f8cdfb1694ea8fe4ed6c38a0fd78d1188e03f4"
SINK="0x7cb68ddc781153d9417E08bAf6A64e801e398d42"
IWSPYX_FEED="0x8b44f7Acf288ea79795223dDfd5F872f51d33fb9"
ATTACKER="0x1111111111111111111111111111111111111111"

out={"rpc_kind":"keyless-or-env","block":None,"chain_id":None,"gate":{},"reserves":[],"feeds":{},"hub":{},"positions":{}}
out["chain_id"]=int(rpc("eth_chainId",[]),16) if rpc("eth_chainId",[]) else None
bn=rpc("eth_blockNumber",[]); out["block"]=int(bn,16) if bn else None

def sel(sig): return "0x"+selector(sig).hex()

# gate: isEtherFiSafe(attacker) and borrow revert
ise="0x"+selector("isEtherFiSafe(address)").hex()
r=call(DP, ise+enc_addr(ATTACKER)); out["gate"]["isEtherFiSafe_attacker"]= (int(r,16)!=0) if r else None
r=call(DP, ise+enc_addr("0x0fcda4d56ce5ade64031a66c2838401f3448e1a9")); out["gate"]["isEtherFiSafe_known_safe"]= (int(r,16)!=0) if r else None
# borrow(0, 1e6, attacker) from attacker -> revert OnlyEtherFiSafe(address)
borrow_data="0x"+selector("borrow(uint256,uint256,address)").hex()+enc_uint(0)+enc_uint(1000000)+enc_addr(ATTACKER)
res=rpc("eth_call",[{"from":ATTACKER,"to":SPOKE,"data":borrow_data},"latest"])
out["gate"]["borrow_call"]=res if isinstance(res,dict) else res
out["gate"]["borrow_call_raw"]=call_raw(ATTACKER, SPOKE, borrow_data).get("error")
# LendGateway.borrow(known_safe, USDC, 1e6, attacker) -> OnlyDriver()
lg_data="0x"+selector("borrow(address,address,uint256,address)").hex()+enc_addr("0x0fcda4d56ce5ade64031a66c2838401f3448e1a9")+enc_addr("0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85")+enc_uint(1000000)+enc_addr(ATTACKER)
res2=rpc("eth_call",[{"from":ATTACKER,"to":LG,"data":lg_data},"latest"])
out["gate"]["lendgateway_borrow_call"]=res2 if isinstance(res2,dict) else res2
out["gate"]["lendgateway_borrow_call_raw"]=call_raw(ATTACKER, LG, lg_data).get("error")
# position manager active checks
pm="0x"+selector("isPositionManagerActive(address)").hex()
r=call(SPOKE, pm+enc_addr(LG)); out["gate"]["pm_active_lendgateway"]=(int(r,16)!=0) if r else None
r=call(SPOKE, pm+enc_addr(ATTACKER)); out["gate"]["pm_active_attacker"]=(int(r,16)!=0) if r else None
r=call(LG, "0x"+selector("isDriver(address)").hex()+enc_addr(ATTACKER)); out["gate"]["lg_isDriver_attacker"]=(int(r,16)!=0) if r else None

# reserves
rc=call(SPOKE,"0x"+selector("getReserveCount()").hex())
n=int(rc,16) if rc else 0
out["reserve_count"]=n
gr="0x"+selector("getReserve(uint256)").hex()
for i in range(n):
    raw=call(SPOKE, gr+enc_uint(i))
    price=call(ORACLE, "0x"+selector("getReservePrice(uint256)").hex()+enc_uint(i))
    src=call(ORACLE, "0x"+selector("getReserveSource(uint256)").hex()+enc_uint(i))
    entry={"reserveId":i}
    if raw and len(raw)>=2+64*7:
        b=raw[2:]
        entry["underlying"]="0x"+b[24:64]
        entry["decimals"]=int(b[64*3+62:64*4],16)
    if price: entry["price_8dp"]=int(price,16)
    if src: entry["priceSource"]="0x"+src[-40:]
    out["reserves"].append(entry)

# feeds
def feed_info(addr):
    d={}
    for name in ["sink()","token()","rateMaxStaleness()","underlyingUsdFeed()","latestAnswer()","description()","rateFeed()","decimals()"]:
        r=call(addr,"0x"+selector(name).hex())
        if r is None: continue
        if name in ("latestAnswer()",):
            d["latestAnswer"]=int(r,16) if r not in ("0x","") else None
        elif name.endswith(")"):
            d[name[:-2]]=r
    return d
out["feeds"]["iwSPYx"]=feed_info(IWSPYX_FEED)
out["feeds"]["iPAXG"]=feed_info("0xaC28d7fe39d16aa0d35CDCc8cE939125cB3f091b")
# sink peer/paused
r=call(SINK,"0x"+selector("peers(uint32)").hex()+enc_uint(30101)); out["feeds"]["sink_peer_30101"]=r
r=call(SINK,"0x"+selector("paused()").hex()); out["feeds"]["sink_paused"]=r

# hub
r=call(HUB,"0x"+selector("getSpokeCount(uint256)").hex()+enc_uint(0)); out["hub"]["spokeCount_asset0"]=int(r,16) if r else None
gs="0x"+selector("getSpokeAddress(uint256,uint256)").hex()
sp=[]
if out["hub"]["spokeCount_asset0"]:
    for j in range(out["hub"]["spokeCount_asset0"]):
        rr=call(HUB, gs+enc_uint(0)+enc_uint(j))
        if rr: sp.append("0x"+rr[-40:])
out["hub"]["spokes_asset0"]=sp

# sample position
gad="0x"+selector("getUserAccountData(address)").hex()+enc_addr("0x0fcda4d56ce5ade64031a66c2838401f3448e1a9")
r=call(SPOKE, gad)
out["positions"]["rwa_user_account_data_raw"]=r

json.dump(out, open("ci-out/etherfi-borrowing-live.json","w"), indent=2)
print(json.dumps({k:out[k] for k in ["chain_id","block","reserve_count","gate"]}, indent=2))
print("[etherfi-borrowing] wrote ci-out/etherfi-borrowing-live.json")
PY
echo "[etherfi-borrowing] done $(date -u +%FT%TZ)"
