#!/usr/bin/env python3
import json, sys, base64, time
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
import rpc as R
from solders.transaction import VersionedTransaction

# use both public endpoints, slow
R.ENDPOINTS = ["https://api.mainnet.solana.com", "https://solana-rpc.publicnode.com"]
USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
ATA = "6RZNNde77Gsmr51B7LaddEdSXUD5adPbE4jMc16TNUZC"  # deposit_authority USDC ATA
DEP = "CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE"
PROGNAME = {
 "KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD": "Kamino Lend",
 "jup3YeL8QhtSx1e253b2FDvsMNC87fDrgQZivbrndc9": "JupiterLend",
 "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4": "JupiterAgg",
 "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV": "Exceed",
 "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA": "SPLToken",
 "11111111111111111111111111111111": "System",
 "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL": "ATA",
 "ComputeBudget111111111111111111111111111111": "CB",
 "rec5EKMGg6MxZYaMdyBfgwp4d5rB9T1VQH5pJv5LtFJ": "PythRecv",
 "TokExjvjJmhKaRBShsBAsbSvEWMA1AgUNK7ps4SAc2p": "PythPush",
 "sSo1iU21jBrU9VaJ8PJib1MtobkvgPptaNiBb41X7B9": "SPLStakePool",
}
sigs = R.call("getSignaturesForAddress", [ATA, {"limit": 30}])["result"]
print("ATA sigs:", len(sigs))
progs = {}
flows = []
for s in sigs:
    r = R.call("getTransaction", [s["signature"], {"encoding":"base64","maxSupportedTransactionVersion":0}])["result"]
    if not r: continue
    try: vtx = VersionedTransaction.from_bytes(base64.b64decode(r["transaction"][0]))
    except Exception: continue
    keys = [str(k) for k in vtx.message.account_keys]
    for ix in vtx.message.instructions:
        pid = keys[ix.program_id_index]
        progs[PROGNAME.get(pid, pid)] = progs.get(PROGNAME.get(pid, pid), 0) + 1
    meta = r["meta"]
    for b in (meta.get("postTokenBalances") or []):
        if b.get("mint") == USDC:
            ai = b["accountIndex"]
            pre = next((p for p in (meta.get("preTokenBalances") or []) if p["accountIndex"]==ai), None)
            pa = float(pre["uiTokenAmount"]["uiAmountString"]) if pre else 0.0
            po = float(b["uiTokenAmount"]["uiAmountString"])
            if abs(po-pa) > 0.001:
                flows.append((s["signature"], pa, po, keys[0], b.get("owner")))
    time.sleep(0.5)
print("programs:", json.dumps(progs, indent=1))
print("USDC ATA deltas:")
for f in flows: print("  ", f)
