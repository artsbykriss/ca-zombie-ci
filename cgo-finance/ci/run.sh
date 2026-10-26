#!/usr/bin/env bash
# cgo-finance / ci/run.sh — light live-state dump for the CGO Finance (Cronos) farm.
# Writes ci-out/live_state.json (+ a human log).  No secrets, keyless public RPC only.
set -uo pipefail

FOLDER="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$FOLDER/ci-out"
mkdir -p "$OUT"

RPC="${CRONOS_RPC_URL:-https://evm.cronos.org}"

python3 - "$RPC" "$OUT" <<'PY'
import json, sys, urllib.request

RPC, OUT = sys.argv[1], sys.argv[2]
FARM = "0x5795BE23A2C330209849e0D1D19cc05755E23Ca2"
CGO  = "0x869c3e35ef9e5f50003d9a2a80f1d61d670d4cb6"
WCRO = "0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23"
USDC = "0xc21223249CA28397B4B6541dfFaEcC539BfF0c59"
PAIRS = {
  "CGO/USDC(cougar)": "0x0803a4686800e30f0b4e310fCa1c6500953e1617",
  "CGO/WCRO(cougar)": "0xC794a7d974E5e8064FE59d4aabf78EA70F66c9c4",
  "CGO/USDT(cougar)": "0xF78D712E8cAc8c3A03119420C056940Ea0BEF447",
  "CGO/USDC(vvs)":    "0xF06abc17073c23b90b76Fa95Dd3D4f1373248ffa",
  "CGO/USDC(crona)":  "0xDF949c0434Bd58A6A99B1dCBc63951Fb4aeE3307",
}

def batch(calls):
    out = {}
    for s in range(0, len(calls), 10):
        ch = calls[s:s+10]
        p = [{"jsonrpc":"2.0","id":s+i,"method":"eth_call",
              "params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(ch)]
        req = urllib.request.Request(RPC, data=json.dumps(p).encode(),
              headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        for it in json.loads(urllib.request.urlopen(req, timeout=90).read()):
            out[it["id"]] = it.get("result") if "result" in it else None
    return [out.get(i) for i in range(len(calls))]

def num(x): return int(x,16) if x and x != "0x" else None
def adr(x): return "0x"+x[-40:] if x and len(x) >= 42 else None

res = {"rpc": "<cronos rpc>", "farm": FARM, "cgo": CGO}

# block number
req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}).encode(),
      headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
res["block"] = int(json.loads(urllib.request.urlopen(req, timeout=60).read())["result"], 16)

# globals
g = batch([(FARM,"0x081e3eda"),(FARM,"0x17caf6f1"),(FARM,"0x8da5cb5b"),(FARM,"0x766a6c7d"),
           (FARM,"0xaa67c4de"),(FARM,"0x48cd4cb1"),(FARM,"0xfafc8d7e"),(CGO,"0x18160ddd"),
           (CGO,"0x70a08231"+"0"*24+FARM[2:].lower()), (CGO,"0x8da5cb5b")])
res["globals"] = dict(poolLength=num(g[0]), totalAllocPoint=num(g[1]), owner=adr(g[2]),
    CGOPerBlock=num(g[3]), CGOToken=adr(g[4]), startBlock=num(g[5]), ownerCGOReward=num(g[6]),
    cgoTotalSupply=num(g[7]), cgoBalanceOfFarm=num(g[8]), cgoOwner=adr(g[9]))

# pools
n = res["globals"]["poolLength"] or 0
pi = batch([(FARM,"0x1526fe27"+format(i,"064x")) for i in range(n)])
pools = []
for i,r in enumerate(pi):
    if not r or len(r) < 322: continue
    w = r[2:]
    pools.append(dict(pid=i, lp="0x"+w[24:64], allocPoint=int(w[64:128],16),
        lastRewardBlock=int(w[128:192],16), accCGOPerShare=int(w[192:256],16),
        strat="0x"+w[280:320]))
res["pools"] = pools

# strategies
calls, idx = [], []
for p in pools:
    s = p["strat"]
    idx.append((p["pid"],"want",len(calls)));        calls.append((s,"0xeb33ef84"))
    idx.append((p["pid"],"sharesTotal",len(calls))); calls.append((s,"0x44a3955e"))
    idx.append((p["pid"],"wantLockedTotal",len(calls))); calls.append((s,"0x42da4eb3"))
    idx.append((p["pid"],"owner",len(calls)));       calls.append((s,"0x8da5cb5b"))
    idx.append((p["pid"],"paused",len(calls)));      calls.append((s,"0x5c975abb"))
sr = batch(calls)
smap = {}
for pid,label,i in idx: smap.setdefault(pid,{})[label] = sr[i]
for p in pools:
    d = smap.get(p["pid"],{})
    p["stratInfo"] = dict(want=adr(d.get("want")), sharesTotal=num(d.get("sharesTotal")),
        wantLockedTotal=num(d.get("wantLockedTotal")), owner=adr(d.get("owner")),
        paused=(d.get("paused")=="0x"+"0"*63+"1"))
    p["farmWantBalance"] = num(batch([(p["lp"],"0x70a08231"+"0"*24+FARM[2:].lower())])[0])

# pairs
pairs = {}
for name,addr in PAIRS.items():
    r = batch([(addr,"0x0dfe1681"),(addr,"0xd21220a7"),(addr,"0x0902f1ac"),
               (CGO,"0x70a08231"+"0"*24+addr[2:].lower())])
    t0, t1 = adr(r[0]), adr(r[1])
    resv = r[2][2:] if r[2] else ""
    pairs[name] = dict(address=addr, token0=t0, token1=t1,
        reserve0=int(resv[0:64],16) if resv else None,
        reserve1=int(resv[64:128],16) if resv else None,
        cgoBalance=num(r[3]))
res["pairs"] = pairs

json.dump(res, open(OUT+"/live_state.json","w"), indent=1)
print("wrote", OUT+"/live_state.json", "block", res["block"])
print("CGO totalSupply", res["globals"]["cgoTotalSupply"], "farm CGO", res["globals"]["cgoBalanceOfFarm"])
for name,p in pairs.items():
    print(name, p["reserve0"], p["reserve1"], "cgo", p["cgoBalance"])
PY

echo "ci-out/live_state.json written"
