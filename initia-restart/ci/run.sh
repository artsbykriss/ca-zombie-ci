#!/usr/bin/env bash
# initia-restart — read-only CI verification job.
# No secrets, no keyed RPC URLs, no state-changing calls.
# Writes results to ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
OUT=ci-out
mkdir -p "$OUT"

REST=https://rest.initia.xyz
RPCL1=https://rpc-initia.keplr.app
ETHRPC=https://ethereum-rpc.publicnode.com
NOBLE=https://rest.cosmos.directory/noble

echo "[1] L1 node_info / params / status"
curl -sS -m 30 "$REST/cosmos/base/tendermint/v1beta1/node_info" -o "$OUT/l1_node_info.json"
curl -sS -m 30 "$REST/initia/move/v1/params"            -o "$OUT/l1_move_params.json"
curl -sS -m 30 "$RPCL1/status"                          -o "$OUT/l1_status.json"
python3 - "$OUT" <<'PY'
import json,sys
o=sys.argv[1]
ni=json.load(open(f"{o}/l1_node_info.json"))["application_version"]
mv=[x for x in ni["build_deps"] if x["path"]=="github.com/initia-labs/movevm"]
p=json.load(open(f"{o}/l1_move_params.json"))["params"]
st=json.load(open(f"{o}/l1_status.json"))["result"]["sync_info"]
summary={"app_version":ni["version"],"git_commit":ni["git_commit"],
         "movevm_dep":mv,"script_enabled":p["script_enabled"],
         "allowed_publishers":p["allowed_publishers"],
         "height":st["latest_block_height"],"time":st["latest_block_time"]}
json.dump(summary,open(f"{o}/l1_summary.json","w"),indent=1)
print(json.dumps(summary,indent=1))
PY

echo "[2] Minitia status"
python3 - "$OUT" <<'PY'
import json,subprocess,sys,time
o=sys.argv[1]
chains={"cabal-1":"https://rpc-cabal-1.anvil.asia-southeast.initia.xyz",
        "civitia-1":"https://rpc-civitia-1.anvil.asia-southeast.initia.xyz",
        "echelon-1":"https://rpc-echelon-1.anvil.asia-southeast.initia.xyz",
        "yominet-1":"https://rpc-yominet-1.anvil.asia-southeast.initia.xyz",
        "inertia-2":"https://rpc.inrt.fi",
        "strat-1":"https://rpc-strat-1.anvil.asia-northeast.initia.xyz"}
out={}
for n,u in chains.items():
    rec={"rpc":u,"live":False}
    for _ in range(3):
        r=subprocess.run(["curl","-sS","-m","12",u+"/status"],capture_output=True,text=True)
        try:
            s=json.loads(r.stdout)["result"]["sync_info"]
            rec={"rpc":u,"live":True,"height":s["latest_block_height"],"time":s["latest_block_time"]}
            break
        except Exception as e:
            rec["error"]=str(e)[:40]
        time.sleep(2)
    out[n]=rec
json.dump(out,open(f"{o}/minitia_status.json","w"),indent=1); print(json.dumps(out,indent=1))
PY

echo "[3] Ethereum lockboxes"
python3 - "$OUT" "$ETHRPC" <<'PY'
import json,subprocess,sys
o,rpc=sys.argv[1],sys.argv[2]
def post(m,p):
    return json.loads(subprocess.run(["curl","-sS","-m","15","-X","POST","-H","content-type: application/json",
        "--data",json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}),rpc],capture_output=True,text=True).stdout)["result"]
blk=int(post("eth_blockNumber",[]),16)
AUSD="0x38b8b7ca28e672018a299b20565aca8cf200c844"
ETH="0x66a503a1060ab3f2b1aaabed613fe30babbc1bde"
def call(to,data): return post("eth_call",[{"to":to,"data":data},hex(blk)])
peer="0xbb0b6a53"+f"{30326:064x}"
ausd=int(call("0x00000000efe302beaa2b3e6e1b18d08d69a9012a","0x70a08231"+"0"*24+AUSD[2:]),16)/1e6
eth=int(post("eth_getBalance",[ETH,hex(blk)]),16)/1e18
out={"block":blk,
     "ausd_adapter":{"address":AUSD,"balance":ausd,"token":call(AUSD,"0xfc0c546a"),"peer_eid30326":call(AUSD,peer)},
     "eth_adapter":{"address":ETH,"balance":eth,"peer_eid30326":call(ETH,peer)},
     "ausd_usd":round(ausd*0.9985860234987998,2),"eth_usd":round(eth*2278.0706823,2)}
out["total_usd"]=round(out["ausd_usd"]+out["eth_usd"],2)
json.dump(out,open(f"{o}/eth_lockboxes.json","w"),indent=1); print(json.dumps(out,indent=1))
PY

echo "[4] Noble escrow for Initia channel-3 (counterparty of channel-3 = noble channel-129)"
python3 - "$OUT" "$NOBLE" <<'PY'
import hashlib,json,sys,urllib.request
o,base=sys.argv[1],sys.argv[2]
CH="qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def pm(v):
    G=[0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]; c=1
    for x in v:
        b=c>>25; c=(c&0x1ffffff)<<5 ^ x
        for i in range(5): c^=G[i] if (b>>i)&1 else 0
    return c
def he(h): return [ord(x)>>5 for x in h]+[0]+[ord(x)&31 for x in h]
def enc(h,d):
    v=he(h)+d; p=pm(v+[0]*6)^1
    cs=[(p>>5*(5-i))&31 for i in range(6)]
    return h+"1"+"".join(CH[x] for x in d+cs)
def cb(data,f,t):
    a=0;b=0;r=[]
    for x in data:
        a=(a<<f)|x;b+=f
        while b>=t: b-=t;r.append((a>>b)&((1<<t)-1))
    if b: r.append((a<<(t-b))&((1<<t)-1))
    return r
key=("ics20-1"+chr(0)+"transfer/channel-129").encode()
addr=enc("noble",cb(hashlib.sha256(key).digest()[:20],8,5))
req=urllib.request.Request(f"{base}/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=50",headers={"User-Agent":"research"})
d=json.load(urllib.request.urlopen(req,timeout=30))
out={"escrow_address":addr,"balanced":d.get("balances",[])}
json.dump(out,open(f"{o}/noble_escrow_ch129.json","w"),indent=1); print(json.dumps(out,indent=1))
PY

echo "[5] Public v1.4.11 vs v1.4.10 binary build-info + MoveVM symbol diff"
mkdir -p /tmp/ib
curl -sSL -m 300 -o /tmp/ib/v1411.tgz "https://github.com/initia-labs/initia-binaries/releases/download/v1.4.11/initia_v1.4.11_Linux_x86_64.tar.gz"
curl -sSL -m 300 -o /tmp/ib/v1410.tgz "https://github.com/initia-labs/initia/releases/download/v1.4.10/initia_v1.4.10_Linux_x86_64.tar.gz"
mkdir -p /tmp/ib/11 /tmp/ib/10
tar xzf /tmp/ib/v1411.tgz -C /tmp/ib/11
tar xzf /tmp/ib/v1410.tgz -C /tmp/ib/10
( cd /tmp/ib/11 && LD_LIBRARY_PATH=. ./initiad version --long --output json > "$ROOT/$OUT/buildinfo_v1411.json" 2>&1 )
( cd /tmp/ib/10 && LD_LIBRARY_PATH=. ./initiad version --long --output json > "$ROOT/$OUT/buildinfo_v1410.json" 2>&1 )
{
  echo "== v1.4.11 movevm dep"
  python3 -c "import json;d=json.load(open('$OUT/buildinfo_v1411.json'));print([x for x in d['build_deps'] if 'movevm' in x])"
  echo "== v1.4.10 movevm dep"
  python3 -c "import json;d=json.load(open('$OUT/buildinfo_v1410.json'));print([x for x in d['build_deps'] if 'movevm' in x])"
  echo "== new symbols in v1.4.11 libmovevm (script/cache/verifier)"
  nm -C --defined-only /tmp/ib/11/libmovevm.x86_64.so | grep -iE "reject_legacy|load_script|new_caches|record_verified|verified_here|fetch_checksum" || true
} | tee "$OUT/movevm_symbols.txt"
nm -C --defined-only /tmp/ib/10/libmovevm.x86_64.so > /tmp/ib/s10.txt 2>/dev/null
nm -C --defined-only /tmp/ib/11/libmovevm.x86_64.so > /tmp/ib/s11.txt 2>/dev/null
comm -13 <(sed 's/17h[0-9a-f]\{16\}E//' /tmp/ib/s10.txt | sort -u) \
         <(sed 's/17h[0-9a-f]\{16\}E//' /tmp/ib/s11.txt | sort -u) \
  | grep -iE "script|cache|verif|legacy" > "$OUT/movevm_new_symbols.txt" || true

echo "[6] checksums"
sha256sum /tmp/ib/v1411.tgz /tmp/ib/v1410.tgz | tee "$OUT/tarball_sha256.txt"

echo "[done]"
