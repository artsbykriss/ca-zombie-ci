#!/usr/bin/env python3
import solrpc as s, json, hashlib, base64
try:
    import base58 as b58
except Exception:
    import b58
PROG="sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD"

def disc(name): return hashlib.sha256(("global:"+name).encode()).digest()[:8]
names="""ActivateProposal AddPolicy AppendProposalActions CancelProposal CancelWithdrawal CollectManagementFee
DepositLiquidity ExecuteProposal ExecuteWithdrawal FillWithdrawal FinalizeProposal InitProposal
InitializeLpMetadata InitializePrices InitializeVault MakeSentinelManagerLower ManagePrices
ManageVaultSettings ManagerUpdatePosition MigrateOnycPricing MigrateVaultLayout QueueWithdrawal
RefreshAum RemovePolicy SentinelSetVaultFlags StakeVote SyncPolicyAuthorities
UnblockNavAumCircuitBreakerInstruction UnstakeVoteInstruction UpdatePolicy
UpdatePolicyManagerInvalid UpdateTwapPrice ValidateInteractionHook WrapperAddPolicy
WrapperExecuteWithdrawal WrapperRemovePolicy WrapperUpdatePolicyInsufficient""".split()
# snake_case variants
def snake(n): 
    out=""
    for i,c in enumerate(n):
        if c.isupper() and i>0: out+="_"
        out+=c.lower()
    return out
M={}
for n in names:
    for cand in (snake(n), n.lower()):
        M[disc(cand)]=cand
# also raw byte discriminator directly from ELF anchor idl? just use map

sigs=s.get_signatures(PROG, limit=60).get("result",[])
print("recent program sigs:",len(sigs))
seen={}
for sg in sigs:
    if sg.get("err"): continue
    tx=s.get_transaction(sg["signature"], encoding="jsonParsed").get("result")
    if not tx: continue
    m=tx["transaction"]["message"]
    signers={k["pubkey"] for k in m["accountKeys"] if k.get("signer")}
    for ix in m["instructions"]:
        if ix.get("programId")!=PROG or not ix.get("data"): continue
        try: raw=b58.b58decode(ix["data"])
        except Exception: continue
        d8=bytes(raw[:8])
        nm=M.get(d8, d8.hex())
        key=nm
        if key not in seen:
            seen[key]={"count":0,"sig":sg["signature"],"accounts":ix["accounts"],"data":raw,"signers":signers}
        seen[key]["count"]+=1
for k,v in sorted(seen.items(), key=lambda x:-x[1]["count"]):
    print(f"  {k:40s} count={v['count']} nsigners={len(v['signers'])}")
json.dump({k:{"count":v["count"],"sig":v["sig"],"accounts":v["accounts"],"data":v["data"].hex(),"signers":list(v["signers"])} for k,v in seen.items()},
          open("exponent_recent_ix.json","w"),indent=1)
