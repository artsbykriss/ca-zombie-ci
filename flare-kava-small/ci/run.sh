#!/usr/bin/env bash
# Heavy job for the flare-kava-small finding: live read-only evidence + state dump for the
# Enosys Governance Stake Managers on Songbird (chain 19). Public keyless RPC only; no secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT=ci-out
mkdir -p "$OUT"
RPC="${SONGBIRD_RPC_URL:-https://songbird-api.flare.network/ext/C/rpc}"
MGR=0xc4D89F8f593F215f3636793E3353A36C196Cf87A
SFIN_MGR=0xA83E90337e2711b1c84df0AD7428403dBd0ce730
EXFI=0xC348F894d0E939FE72c467156E6d7DcbD6f16e21
WSGB=0x02f0826ef6aD107Cfc861152B32B52fD11BaB9ED
SFIN=0x0D94e59332732D18CF3a3D457A8886A2AE29eA1B
FRESH=0x1111111111111111111111111111111111111111
FARM=0xb78ebd4b13a2202068618bf98f952c0271159107

c() { cast call "$1" "$2" ${3:+$3} --rpc-url "$RPC" 2>/dev/null | head -1; }
cfrom() { cast call "$1" "$2" ${3:+$3} --from "$4" --rpc-url "$RPC" 2>&1 | head -1 | sed 's/^Error: execution reverted: //; s/^Error: execution reverted$//'; }
n() { v=$(printf "%s" "$1" | awk '{print $1}'); echo "${v:-0}"; }

BLOCK=$(cast block-number --rpc-url "$RPC")
CUR=$(n "$(c $MGR 'getCurrentEpoch()(uint256)')")
LATEST=$(n "$(c $MGR 'getLatestEpochForRewards()(uint256)')")
TS=$(c $MGR 'totalSupply()(uint256)' | awk '{print $1}')
EXFI_BAL=$(c $EXFI 'balanceOf(address)(uint256)' $MGR | awk '{print $1}')

PASS=0; FAIL=0
check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1 (expected=$2 actual=$3)"; fi
}

echo "== live evidence @ block $BLOCK (epoch $CUR, latestRewardEpoch $LATEST)"
echo "manager EXFI balance $EXFI_BAL ; totalSupply $TS"

# 1) fresh unprivileged account has zero historical balance and zero claimable rewards
for e in 0 1 10 100 200 300 $((CUR-1)); do
  check "fresh balanceOfEpoch($e)==0" 0 "$(n "$(c $MGR 'balanceOfEpoch(address,uint256)(uint256)' "$FRESH $e")")"
done
UNCLAIMED=$(c $MGR 'getAllUnclaimedRewards(address)(uint256[])' $FRESH)
check "fresh unclaimed rewards all zero" "true" "$(echo "$UNCLAIMED" | grep -qE '^\[(0, )*0\]$' && echo true || echo false)"
check "fresh canClaimRewards==false" "false" "$(n "$(c $MGR 'canClaimRewards(address)(bool)' $FRESH)")"

# 2) accounting identity on real stakers: getAllUnclaimedRewards == sum(balanceOfEpoch*rate/1e18)
python3 - "$RPC" "$MGR" <<'PY'
import json,urllib.request,sys
from Crypto.Hash import keccak
RPC,MGR=sys.argv[1],sys.argv[2]
def sel(sig):
    h=keccak.new(digest_bits=256); h.update(sig.encode()); return h.hexdigest()[:8]
def w(x): return format(x,'064x')
def waddr(a): return a.lower().replace('0x','').rjust(64,'0')
def batch(calls, tos=None):
    out={}
    for i in range(0,len(calls),25):
        chunk=calls[i:i+25]
        req=[{"jsonrpc":"2.0","id":i+j,"method":"eth_call","params":[{"to":(MGR if tos is None else tos[i+j]),"data":d},"latest"]} for j,d in enumerate(chunk)]
        for attempt in range(4):
            try:
                r=urllib.request.Request(RPC,data=json.dumps(req).encode(),headers={"content-type":"application/json"})
                resp=json.loads(urllib.request.urlopen(r,timeout=60).read())
                if isinstance(resp,dict): resp=[resp]
                for x in resp:
                    if isinstance(x,dict) and "id" in x: out[x["id"]]=x.get("result")
            except Exception as ex:
                print("warn batch retry:",ex)
            if all((i+j) in out for j in range(len(chunk))): break
            import time; time.sleep(1)
    return [out.get(i) for i in range(len(calls))]
def safe_uint(r):
    return 0 if not r else int(r,16)
def safe_uarr(r):
    return [] if not r else dec_uarr(r)
def safe_aarr(r):
    return [] if not r else dec_aarr(r)
def dec_uint(res): return int(res,16)
def dec_uarr(res):
    b=res[2:]; off=int(b[:64],16)*2
    ln=int(b[off:off+64],16); off+=64
    return [int(b[off+64*i:off+64*(i+1)],16) for i in range(ln)]
def dec_aarr(res):
    b=res[2:]; off=int(b[:64],16)*2
    ln=int(b[off:off+64],16); off+=64
    return ["0x"+b[off+64*i+24:off+64*(i+1)] for i in range(ln)]
latest=safe_uint(batch(["0x"+sel("getLatestEpochForRewards()")])[0])
tokens=safe_aarr(batch(["0x"+sel("getRewardTokens()")])[0])
dec_res=batch(["0x"+sel("decimals()") for t in tokens], tos=tokens)
decimals=[safe_uint(r) for r in dec_res]
scale=[10**(18-d) if d<18 else 1 for d in decimals]
users=["0xEe4B5af1703aD363C3467D51f344429f2d87C4F0","0xfA3E877f4B14EFa4a7B452Cb89B54bd0b70D7467","0xB70F78d17d6D5bae09bbdD83FfD46dd858fb09c9","0x1111111111111111111111111111111111111111"]
# fetch last-claim epochs + unclaimed arrays in one batch
calls=[]
for u in users:
    calls.append("0x"+sel("userLastRewardClaimEpoch(address)")+waddr(u))
    calls.append("0x"+sel("getAllUnclaimedRewards(address)")+waddr(u))
res=batch(calls)
rows=[]
for i,u in enumerate(users):
    last=safe_uint(res[2*i]); un=safe_uarr(res[2*i+1]); rows.append((u,last,un))
# fetch balances and rates for the claim window in one batch
calls=[]; meta=[]
for u,last,un in rows:
    for e in range(last+1,latest+1):
        calls.append("0x"+sel("balanceOfEpoch(address,uint256)")+waddr(u)+w(e)); meta.append(("bal",u,e))
        for t in tokens:
            calls.append("0x"+sel("epochRewardRate(uint256,address)")+w(e)+waddr(t)); meta.append(("rate",t,e))
res=batch(calls)
bal={}; rate={}
for m,r in zip(meta,res):
    if m[0]=="bal": bal[(m[1],m[2])]=safe_uint(r)
    else: rate[(m[1],m[2])]=safe_uint(r)
ok=True
for u,last,un in rows:
    calc=[0]*len(tokens)
    for e in range(last+1,latest+1):
        b=bal.get((u,e),0)
        if b==0: continue
        for i,t in enumerate(tokens): calc[i]+=b*rate.get((t,e),0)//10**18//scale[i]
    match = (un==calc); ok = ok and match
    print(f"{'PASS' if match else 'FAIL'}  formula identity {u}: unclaimed={un} calc={calc}")
print("FORMULA_IDENTITY", "PASS" if ok else "FAIL")
PY

# 3) privileged paths gated for unprivileged caller
check "updateRewardAmountByToken gated" "EnosysGovernanceStakeManager: Not allowed reward notifier" "$(cfrom $MGR 'updateRewardAmountByToken(address,uint256)' "$EXFI 1000000000000000000" $FRESH)"
check "addVoting gated" "EnosysGovernanceStakeManager: Not a governor" "$(cfrom $MGR 'addVoting(uint256,uint256)' "1 100" $FRESH)"
check "updateApyCloudVault owner-only" "Ownable: caller is not the owner" "$(cfrom $MGR 'updateApyCloudVault(address)' "$FRESH" $FRESH)"
check "updateRewardTokensAdd owner-only" "Ownable: caller is not the owner" "$(cfrom $MGR 'updateRewardTokensAdd(address)' "$FRESH" $FRESH)"
check "updateGovernor owner-only" "Ownable: caller is not the owner" "$(cfrom $MGR 'updateGovernor(address,bool)' "$FRESH true" $FRESH)"
check "updateTotalSupplyAggregationRange owner-only" "Ownable: caller is not the owner" "$(cfrom $MGR 'updateTotalSupplyAggregationRange(uint256)' "1" $FRESH)"
check "withdrawReturnedFees no pending fees" "EnosysGovernanceStakeManager: No pending fees" "$(cfrom $MGR 'withdrawReturnedFees(bool)' "true" $FRESH)"
check "fresh claimRewards no rewards" "EnosysGovernanceStakeManager: No any rewards" "$(cfrom $MGR 'claimRewards()' "" $FRESH)"

# 4) permissionless epoch-total finaliser is idempotent (stored == returned)
EPAST=$((CUR-2))
STORED=$(n "$(c $MGR 'totalSupplyByEpoch(uint256)(int256)' $EPAST)")
RET=$(cfrom $MGR 'updateTotalSupplyByEpochIfNeeded(uint256)' "$EPAST" $FRESH | head -1)
RETD=$(python3 -c "print(int('$RET',16))" 2>/dev/null || echo err)
check "updateTotalSupplyByEpochIfNeeded idempotent (epoch $EPAST)" "$STORED" "$RETD"
check "updateTotalSupplyByEpochIfNeeded rejects current epoch" "EnosysGovernanceStakeManager: Cannot update total supply for the current or next epoch" "$(cfrom $MGR 'updateTotalSupplyByEpochIfNeeded(uint256)' "$CUR" $FRESH)"

# 5) farming pool (EXFI->SFIN, expired 2025-01): third-party 'For' functions gated
check "FarmingPool withdrawFor gated (onlyAllowedCaller)" "StaticPool: Not allowed caller" "$(cfrom $FARM 'withdrawFor(uint256,address)' "1 $FRESH" $FRESH)"
check "FarmingPool rescueUnclaimedTokens owner-only" "Ownable: caller is not the owner" "$(cfrom $FARM 'rescueUnclaimedTokens(address,uint256)' "$FRESH 1" $FRESH)"

# 6) state dump
{
  echo "{"
  echo "  \"block\": $BLOCK,"
  echo "  \"manager\": \"$MGR\","
  echo "  \"currentEpoch\": $CUR,"
  echo "  \"latestEpochForRewards\": $LATEST,"
  echo "  \"totalSupply_wei\": \"$TS\","
  echo "  \"exfi_balance_wei\": \"$EXFI_BAL\","
  echo "  \"surplus_unclaimed_exfi_wei\": \"$(python3 -c "print($EXFI_BAL-$TS)")\","
  echo "  \"wsgb_balance_wei\": \"$(n "$(c $WSGB 'balanceOf(address)(uint256)' $MGR)")\","
  echo "  \"sfin_balance_wei\": \"$(n "$(c $SFIN 'balanceOf(address)(uint256)' $MGR)")\","
  echo "  \"owner\": \"$(c $MGR 'owner()(address)')\","
  echo "  \"notifier_apyCloud\": \"$(c $MGR 'a5032f3c')\","
  echo "  \"apyCloudVault\": \"$(c $MGR 'apyCloudVault()(address)')\","
  echo "  \"sfinManager\": \"$SFIN_MGR\","
  echo "  \"sfinManager_exfi_wei\": \"$(n "$(c $EXFI 'balanceOf(address)(uint256)' $SFIN_MGR)")\","
  echo "  \"sfinManager_sfin_wei\": \"$(n "$(c $SFIN 'balanceOf(address)(uint256)' $SFIN_MGR)")\","
  echo "  \"sfinManager_wsgb_wei\": \"$(n "$(c $WSGB 'balanceOf(address)(uint256)' $SFIN_MGR)")\","
  echo "  \"farmingPool\": \"$FARM\","
  echo "  \"farmingPool_exfi_wei\": \"$(n "$(c $EXFI 'balanceOf(address)(uint256)' $FARM)")\","
  echo "  \"epochs\": ["
  FIRST=1
  for e in $(seq $((CUR-6)) $CUR); do
    SNAP=$(n "$(c $MGR "epochSnapshotBlock(uint256)(uint256)" $e)")
    IV=$(cast call $MGR "epochInterval(uint256)(uint256,uint256)" $e --rpc-url "$RPC" 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')
    RATE=$(n "$(c $MGR "epochRewardRate(uint256,address)(uint256)" "$e $EXFI")")
    TSE=$(n "$(c $MGR "totalSupplyByEpoch(uint256)(int256)" $e)")
    [ "$FIRST" -eq 0 ] && printf ",\n"
    FIRST=0
    printf '    {"epoch": %s, "snapshotBlock": %s, "interval": "%s", "rateExfi": %s, "totalSupplyByEpoch": %s}' "$e" "$SNAP" "$IV" "$RATE" "$TSE"
  done
  printf "\n  ],\n"
  echo "  \"checks\": {\"passed\": $PASS, \"failed\": $FAIL}"
  echo "}"
} > "$OUT/exfi-state.json" 2>&1

echo
echo "== summary: $PASS passed, $FAIL failed"
tail -c 900 "$OUT/exfi-state.json"
[ "$FAIL" -eq 0 ] || exit 1
