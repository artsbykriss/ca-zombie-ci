#!/usr/bin/env python3
"""MUSD live state + redemption math. Read-only."""
import json, urllib.request

RPCS = ["https://blast-rpc.publicnode.com", "https://rpc.blast.io"]
MUSD = "0x837fe561e9c5dfa73f607fda679295dbc2be5e40"

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last=None
    for u in RPCS:
        for a in range(3):
            try:
                req = urllib.request.Request(u, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=25) as r:
                    d=json.loads(r.read())
                if "result" in d: return d["result"]
                last=d.get("error")
            except Exception as e: last=e
    raise RuntimeError(str(last))

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def u(h): return int(h,16) if h and h!="0x" else None
def addr(h): return "0x"+h[-40:] if h and len(h)>=42 else None
def dec_str(h):
    b=bytes.fromhex(h[2:]); off=int.from_bytes(b[0:32],'big'); ln=int.from_bytes(b[off:off+32],'big')
    return b[off+32:off+32+ln].decode()

SEL = {"totalSupply()":"0x18160ddd","usdb()":"0x006f7d00","mono()":"0xde72f107","monoswapRouter()":"0x1b9c7533",
       "path(uint256)":"0xaf6d1fe4","treasureFee()":"0xbf8f31df","burnMonoFee()":"0x9f2423b1","burnMonoFeeTo()":"0xf4072af7",
       "paused()":"0x5c975abb","hasRole(bytes32,address)":"0x91d14854","getReserves()":"0x0902f1ac",
       "balanceOf(address)":"0x70a08231","owner()":"0x8da5cb5b","blast()":"0xfbf10809"}

res={}
for k,sel in SEL.items():
    if k=="hasRole(bytes32,address)": continue
    try: res[k]=call(MUSD, sel)
    except Exception as e: res[k]=None
out={}
out["totalSupply"]=u(res["totalSupply()"])
out["usdb"]=addr(res["usdb()"]) if res["usdb()"] else None
out["mono"]=addr(res["mono()"]) if res["mono()"] else None
out["monoswapRouter"]=addr(res["monoswapRouter()"]) if res["monoswapRouter()"] else None
out["treasureFee"]=u(res["treasureFee()"])
out["burnMonoFee"]=u(res["burnMonoFee()"])
out["burnMonoFeeTo"]=addr(res["burnMonoFeeTo()"]) if res["burnMonoFeeTo()"] else None
out["paused"]=bool(u(res["paused()"]))
out["getReserves_raw"]=res["getReserves()"]
if out["usdb"]:
    out["usdb_balance_of_musd"]=u(call(out["usdb"], SEL["balanceOf(address)"]+"000000000000000000000000"+MUSD[2:]))
# path array
path=[]
for i in range(4):
    try:
        h=call(MUSD, SEL["path(uint256)"]+hex(i)[2:].rjust(64,"0"))
        a=addr(h)
        if a and int(a,16)!=0: path.append(a)
        else: break
    except Exception: break
out["path"]=path
# roles
ROLES={"DEFAULT_ADMIN_ROLE":"0x00"+"00"*31,"PAUSER_ROLE":None}
try:
    from Crypto.Hash import keccak as _k
    def keccak256(b):
        h=_k.new(digest_bits=256); h.update(b); return h.digest().hex()
    pauser="0x"+keccak256(b"PAUSER_ROLE")
except Exception:
    pauser=None
candidates = ["0x13060d08ea8eb04a5cf554b59b138e84c1c07cde","0x90a30f6a76d05cbe5dad714838e0b38d53d7f310",
              "0x48d0f09710794313f33619c95147f34458bf7c3b","0x0000000000000000000000000000000000000000"]
roles={}
if pauser:
    for c in candidates:
        for rname,r in (("ADMIN","0x"+"00"*32),("PAUSER",pauser)):
            try:
                h=call(MUSD, SEL["hasRole(bytes32,address)"]+r[2:]+"000000000000000000000000"+c[2:])
                if u(h): roles[f"{rname}:{c}"]=True
            except Exception: pass
out["roles_true"]=roles
json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/musd_state.json","w"), indent=1)
print(json.dumps(out, indent=1))
EOF_MARKER = None
