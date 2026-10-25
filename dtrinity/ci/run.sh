#!/usr/bin/env bash
# dTRINITY dLEND — live-state + code-evidence dump (runs on CI runner).
# Read-only. Public RPCs only. Writes results to ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out

SONIC_RPC="${SONIC_RPC_URL:-https://rpc.soniclabs.com}"
ETH_RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
FRAX_RPC="${FRAXTAL_RPC_URL:-https://rpc.frax.com}"

cat > /tmp/dump_state.py <<'PYEOF'
import json,sys,urllib.request,time
def rpc(url,method,params):
    for a in range(6):
        try:
            req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            return json.load(urllib.request.urlopen(req,timeout=30))["result"]
        except Exception: time.sleep(1.5*(a+1))
    raise RuntimeError("rpc fail "+url)
def call(url,to,data,blk="latest"):
    return rpc(url,"eth_call",[{"to":to,"data":data},blk])
def keccak(data_hex):
    # keccak256 via eth
    return None
SEL_LIST="0xd1946dbc"; SEL_RD="0x35ea6a75"; SEL_SYM="0x95d89b41"; SEL_DEC="0x313ce567"
SEL_TS="0x18160ddd"; SEL_BAL="0x70a08231"; SEL_FLASH="0xf32b9b9b"
url,pool,label=sys.argv[1],sys.argv[2],sys.argv[3]
blk=rpc(url,"eth_blockNumber",[])
out={"chain":label,"block":int(blk,16),"pool":pool,"reserves":[]}
rl=call(url,pool,SEL_LIST,blk); body=rl[2:]
off=int(body[0:64],16)*2; n=int(body[off:off+64],16)
addrs=["0x"+body[off+64+i*64:off+64+(i+1)*64][-40:] for i in range(n)]
for a in addrs:
    rd=call(url,pool,SEL_RD+a[2:].rjust(64,'0'),blk); b=rd[2:]
    w=lambda i:b[i*64:(i+1)*64]
    conf=int(w(0),16); li=int(w(1),16); at="0x"+w(8)[-40:]; vd="0x"+w(10)[-40:]
    def u256(t,sel=SEL_TS):
        try: return int(call(url,t,sel,blk),16)
        except Exception: return -1
    def bal(owner):
        try: return int(call(url,a,SEL_BAL+owner[2:].rjust(64,'0'),blk),16)
        except Exception: return -1
    try:
        sy=call(url,a,SEL_SYM,blk); raw=bytes.fromhex(sy[2:]); sl=int.from_bytes(raw[32:64],'big'); sym=raw[64:64+sl].decode('utf8','replace')
    except Exception: sym="?"
    try: dec=int(call(url,a,SEL_DEC,blk),16)
    except Exception: dec=-1
    out["reserves"].append({"asset":a,"symbol":sym,"decimals":dec,"config":conf,
      "LTV":conf&0xFFFF,"liqThreshold":(conf>>16)&0xFFFF,"active":(conf>>56)&1,"frozen":(conf>>57)&1,
      "borrowingEnabled":(conf>>58)&1,"paused":(conf>>60)&1,"flashloanEnabled":(conf>>63)&1,
      "liquidityIndex":li,"aToken":at,"aTokenTotalSupply":u256(at),"varDebt":vd,"varDebtTotalSupply":u256(vd),
      "underlyingTotalSupply":u256(a),"aTokenCash":bal(at)})
print(json.dumps(out,indent=1))
PYEOF

echo "== dumping live reserve state =="
python3 /tmp/dump_state.py "$SONIC_RPC" 0xEdC3cfB1aa36c570cc1D374876268bDda2D460CC sonic   > ci-out/sonic_reserves.json 2>ci-out/sonic_err.txt || cat ci-out/sonic_err.txt
python3 /tmp/dump_state.py "$FRAX_RPC"  0xD76C827Ee2Ce1E37c37Fc2ce91376812d3c9BCE2 fraxtal > ci-out/fraxtal_reserves.json 2>ci-out/fraxtal_err.txt || cat ci-out/fraxtal_err.txt
python3 /tmp/dump_state.py "$ETH_RPC"   0x6598DaD18Bda89A0E58A1F427c8CeBc0dE90F153 ethereum > ci-out/ethereum_reserves.json 2>ci-out/ethereum_err.txt || cat ci-out/ethereum_err.txt

echo "== deployed impl + code keccak =="
{
  echo "chain,pool,impl_slot_value,impl_code_keccak"
  for spec in "sonic|$SONIC_RPC|0xEdC3cfB1aa36c570cc1D374876268bDda2D460CC" \
              "fraxtal|$FRAX_RPC|0xD76C827Ee2Ce1E37c37Fc2ce91376812d3c9BCE2" \
              "ethereum|$ETH_RPC|0x6598DaD18Bda89A0E58A1F427c8CeBc0dE90F153"; do
    ch=$(echo "$spec"|cut -d'|' -f1); rp=$(echo "$spec"|cut -d'|' -f2); pl=$(echo "$spec"|cut -d'|' -f3)
    impl=$(cast storage "$pl" 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$rp" 2>/dev/null | sed 's/^0x0*\([0-9a-fA-F]\{40\}\)$/0x\1/')
    impl=$(echo "$impl" | sed 's/0x000000000000000000000000/0x/')
    codek=$(cast keccak "$(cast code "$pl" --rpc-url "$rp" 2>/dev/null)" 2>/dev/null)
    implcodek=$(cast keccak "$(cast code "$impl" --rpc-url "$rp" 2>/dev/null)" 2>/dev/null)
    echo "$ch,$pl,$impl,$implcodek"
  done
} > ci-out/impl_hashes.csv 2>&1
cat ci-out/impl_hashes.csv

echo "== done =="
ls -la ci-out/
