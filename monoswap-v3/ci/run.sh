#!/usr/bin/env bash
# MonoSwap V3 (Blast) — CI heavy job.
# 1) probe a working keyless Blast RPC and export BLAST_RPC_URL for the forge step
# 2) dump live state (pool balances, claimable yield) into ci-out/
# No secrets. Read-only. No transactions.
set -uo pipefail

FOLDER="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$FOLDER/ci-out"
mkdir -p "$OUT"

echo "[monoswap-v3] probing public Blast RPCs..."
PICK=""
for u in "https://rpc.blast.io" "https://blast-rpc.publicnode.com" "https://blast.drpc.org"; do
  r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
  case "$r" in *result*)
    PICK="$u"
    echo "[monoswap-v3] selected RPC: $u"
    break;;
  esac
done
if [ -z "$PICK" ]; then
  echo "[monoswap-v3] WARNING: no working Blast RPC found"
else
  echo "BLAST_RPC_URL=$PICK" >> "${GITHUB_ENV:-/dev/null}"
fi

python3 - <<'PY' || true
import json, urllib.request, os
rpcs=["https://rpc.blast.io","https://blast-rpc.publicnode.com","https://blast.drpc.org"]
def call(to,data):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]}).encode()
    for u in rpcs:
        try:
            req=urllib.request.Request(u,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req,timeout=20) as r:
                d=json.loads(r.read())
            if "result" in d: return d["result"]
        except Exception: continue
    return None
def block():
    for u in rpcs:
        try:
            body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}).encode()
            req=urllib.request.Request(u,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req,timeout=20) as r:
                return int(json.loads(r.read())["result"],16)
        except Exception: continue
    return None
bn=block()
pools={
 "main_usdb_weth":"0x0d44f3f22f917cc57368a6d30ba18d5801789cd9",
 "usdb_musd_A":"0x77e149741b4aa14511324e4b554845063ed038bd",
 "usdb_musd_B":"0x52b3b26541e5347ba22c17334a12ca759f221d8f",
 "weth_musd":"0xfb45661dffa7e768c1d03b5aa9cd9e7f55032c1c",
}
USDB="0x4300000000000000000000000000000000000003"
WETH="0x4300000000000000000000000000000000000004"
MUSD="0x837fe561e9c5dfa73f607fda679295dbc2be5e40"
out={"block":bn,"pools":{}}
for name,p in pools.items():
    rec={}
    for tok,tname in ((USDB,"usdb"),(WETH,"weth"),(MUSD,"musd")):
        h=call(tok,"0x70a08231"+"000000000000000000000000"+p[2:])
        rec[tname]=str(int(h,16)) if h else None
    h=call(USDB,"0xe12f3a61"+"000000000000000000000000"+p[2:])
    rec["claimable_usdb"]=str(int(h,16)) if h else None
    h=call(WETH,"0xe12f3a61"+"000000000000000000000000"+p[2:])
    rec["claimable_weth"]=str(int(h,16)) if h else None
    out["pools"][name]=rec
# MUSD contract reserves
h=call(MUSD,"0x0902f1ac")
if h:
    out["musd_reserves"]={"usdb":str(int(h[2:66],16)),"musd":str(int(h[2+64:2+128],16))}
open(os.path.join(os.environ.get("OUT_DIR","./ci-out"),"state_dump.json"),"w").write(json.dumps(out,indent=1))
print(json.dumps(out,indent=1))
PY
