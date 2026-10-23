#!/usr/bin/env bash
# read-only: full state dump for hook#1 Spot pools + FRLM#1
set -u
U=${UNI_RPC:-https://mainnet.unichain.org}
FRLM=0xa7b3e2306a0B46dbdE3B533c4e2C3Be6a24352a3
HOOK=0x88C9fF9FC0B22cCa42265d3f1D1C2C39E41cDACC
PM=0x1F98400000000000000000000000000000000004
B=$(cast block-number --rpc-url $U); echo "block=$B"
out=state_hook1.json
echo "[]" > $out
python3 - "$U" "$FRLM" "$HOOK" "$PM" "$B" <<'PY'
import sys,json,subprocess
U,FRLM,HOOK,PM,B=sys.argv[1:6]
rows=[]
def call(to,sig,*args):
    r=subprocess.run(["cast","call",to,sig,*[str(a) for a in args],"--rpc-url",U],capture_output=True,text=True)
    return r.stdout.strip() or ("ERR:"+r.stderr.strip().replace("\n"," ")[:120])
keys=open("keys1.txt").read().strip().split("\n")
# token symbols/decimals cache
syms={}
def tok(a):
    a=a.lower()
    if a not in syms:
        syms[a]=(call(a,"symbol()(string)"),call(a,"decimals()(uint8)") if a!="0x0000000000000000000000000000000000000000" else "18")
    return syms[a]
for ln in keys:
    p=ln.split()
    if len(p)<7: continue
    pid,c0,c1,fee,ts,hooks,sq=p[0],p[1],p[2],p[3],p[4],p[5],p[6]
    try:
        sqi=int(sq)
    except: sqi=0
    liq=call(PM,"getLiquidity(bytes32)(uint128)",pid)
    slot0=call(PM,"getSlot0(bytes32)(uint160,int24,uint24,uint24)",pid)
    pf=call(FRLM,"getPendingFees(bytes32)(uint256,uint256)",pid)
    poi=call(FRLM,"getProtocolOwnedLiquidity(bytes32)(uint256,uint256,uint256)",pid)
    pos=call(FRLM,"getPositionInfo(bytes32)(uint256,uint128,uint256,uint256)",pid)
    rows.append(dict(poolId=pid,c0=c0,c1=c1,fee=fee,tickSpacing=ts,sqrtPriceInit=sq,liquidity=liq,slot0=slot0,pendingFees=pf,protocolOwned=poi,position=pos))
json.dump(rows,open("state_hook1.json","w"),indent=1)
print("pools",len(rows))
# token info
addrs=set()
for r in rows:
    addrs.add(r["c0"]); addrs.add(r["c1"])
for a in sorted(addrs):
    s,d=tok(a)
    print(a,s,d)
PY
echo "--- FRLM#1 balances"
for a in 0x078d782b760474a361dda0af3839290b0ef57ad6 0x0555e30da8f98308edb960aa94c0db47230d2b9c 0x4200000000000000000000000000000000000006; do
 echo -n "$a bal="; cast call $a "balanceOf(address)(uint256)" $FRLM --rpc-url $U 2>&1
 echo -n "  ERC6909(PM)="; cast call $PM "balanceOf(address,uint256)(uint256)" $FRLM $(cast to-uint256 $a) --rpc-url $U 2>&1
 echo -n "  accountedBalances="; cast call $FRLM "accountedBalances(address)(uint256)" $a --rpc-url $U 2>&1
 echo -n "  accountedERC6909Balances="; cast call $FRLM "accountedERC6909Balances(address)(uint256)" $a --rpc-url $U 2>&1
done