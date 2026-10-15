#!/usr/bin/env python3
"""Profile recent activity touching the Phase Delegation pool account:
- identify the dominant non-SPoo1 program (bot) that references the pool
- count real SPoo1 instruction usage (cranks, deposits, withdrawals) in a sample
Read-only. Writes activity_profile.json.
"""
import base64, json, re, sys, time, urllib.request
sys.path.insert(0, '.')
from rpc import b58dec, b58enc

def rpc_at(url, method, params, timeout=40):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "zombie/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r: return json.loads(r.read().decode())

URL = "https://api.mainnet-beta.solana.com"
NAMES = {0:"Initialize",1:"AddValidatorToPool",2:"RemoveValidatorFromPool",3:"DecreaseValidatorStake",
         4:"IncreaseValidatorStake",5:"SetPreferredValidator",6:"UpdateValidatorListBalance",
         7:"UpdateStakePoolBalance",8:"CleanupRemovedValidatorEntries",9:"DepositStake",10:"WithdrawStake",
         11:"SetManager",12:"SetFee",13:"SetStaker",14:"DepositSol",15:"WithdrawSol",
         16:"CreateTokenMetadata",17:"UpdateTokenMetadata",18:"IncreaseAdditionalValidatorStake",
         19:"DecreaseAdditionalValidatorStake",20:"DecreaseValidatorStakeWithReserve",21:"Redelegate",
         22:"DepositStakeWithSlippage",23:"WithdrawStakeWithSlippage",24:"DepositSolWithSlippage",25:"WithdrawSolWithSlippage"}
POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"

out = {"pool": POOL}
sigs = rpc_at(URL, "getSignaturesForAddress", [POOL, {"limit": 500}])["result"]
out["sig_window"] = {"count": len(sigs), "newest_slot": sigs[0]["slot"], "oldest_slot": sigs[-1]["slot"]}
counts, other, n_spoo1_txs, errs = {}, {}, 0, 0
sample = sigs[:250]
for s in sample:
    try:
        tx = rpc_at(URL, "getTransaction", [s["signature"], {"encoding": "json", "maxSupportedTransactionVersion": 0}])["result"]
    except Exception:
        continue
    if tx is None: continue
    if tx["meta"].get("err"): errs += 1
    keys = tx["transaction"]["message"]["accountKeys"]
    la = tx["meta"].get("loadedAddresses") or {"writable": [], "readonly": []}
    allk = keys + la["writable"] + la["readonly"]
    found = False
    for grp in [tx["transaction"]["message"]] + [{"instructions": g["instructions"]} for g in (tx["meta"].get("innerInstructions") or [])]:
        for ix in grp["instructions"]:
            pidx = ix.get("programIdIndex")
            pid = allk[pidx] if isinstance(pidx, int) and pidx < len(allk) else str(pidx)
            d = b58dec(ix["data"]) if ix.get("data") else b""
            if str(pid).startswith("SPoo1") and d:
                n = NAMES.get(d[0], f"disc{d[0]}")
                counts[n] = counts.get(n, 0) + 1; found = True
            elif d and not str(pid).startswith("ComputeBudget"):
                other[str(pid)] = other.get(str(pid), 0) + 1
    if found: n_spoo1_txs += 1
    time.sleep(0.08)
out["sampled"] = len(sample)
out["failed"] = errs
out["spoo1_txs"] = n_spoo1_txs
out["spoo1_instruction_counts"] = counts
out["top_other_programs"] = sorted(other.items(), key=lambda x: -x[1])[:8]
# identify the dominant non-SPoo1 program
if out["top_other_programs"]:
    prog = out["top_other_programs"][0][0]
    try:
        v = rpc_at(URL, "getAccountInfo", [prog, {"encoding": "base64"}])["result"]["value"]
        if v and v["owner"] == "BPFLoaderUpgradeab1e11111111111111111111111":
            pd = b58enc(base64.b64decode(v["data"][0])[4:36])
            pv = rpc_at(URL, "getAccountInfo", [pd, {"encoding": "base64"}])["result"]["value"]
            data = base64.b64decode(pv["data"][0])[45:]
            strs = [s.decode(errors="ignore") for s in re.findall(rb"[ -~]{8,80}", data)]
            uniq = []
            for t in strs:
                if t not in uniq and re.search(r"[A-Za-z]{5}", t): uniq.append(t)
            out["top_other_program_id"] = prog
            out["top_other_program_strings"] = uniq[:12]
    except Exception as e:
        out["top_other_program_id_err"] = str(e)[:120]
json.dump(out, open('activity_profile.json', 'w'), indent=1)
print(json.dumps(out, indent=1)[:2500])
