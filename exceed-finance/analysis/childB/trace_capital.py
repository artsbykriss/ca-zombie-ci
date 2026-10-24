#!/usr/bin/env python3
import json, sys, base64, time
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.transaction import VersionedTransaction

WHO = {
 "CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE": "deposit_authority",
 "WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ": "vault/pair_authority",
}
PROGNAME = {
 "KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD": "Kamino Lend",
 "jup3YeL8QhtSx1e253b2FDvsMNC87fDrgQZivbrndc9": "Jupiter Lend?",
 "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4": "Jupiter Agg",
 "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV": "Exceed",
 "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA": "SPL Token",
 "11111111111111111111111111111111": "System",
 "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL": "ATA",
 "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb": "Token2022",
 "ComputeBudget111111111111111111111111111111": "ComputeBudget",
 "rec5EKMGg6MxZYaMdyBfgwp4d5rB9T1VQH5pJv5LtFJ": "Pyth Receiver",
 "TokExjvjJmhKaRBShsBAsbSvEWMA1AgUNK7ps4SAc2p": "Pyth Push",
 "sSo1iU21jBrU9VaJ8PJib1MtobkvgPptaNiBb41X7B9": "SPL StakePool?",
 "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P": "pump?",
}
USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
DEP_USDC_ATA = "6RZNNde77Gsmr51B7LaddEdSXUD5adPbE4jMc16TNUZC"

def analyze(addr, label):
    print(f"\n########## {label} {addr} ##########")
    sigs = call("getSignaturesForAddress", [addr, {"limit": 40}])["result"]
    print("sigs:", len(sigs))
    progs = {}
    token_flows = {}
    for s in sigs:
        r = call("getTransaction", [s["signature"], {"encoding":"base64","maxSupportedTransactionVersion":0}])["result"]
        if not r: continue
        try:
            vtx = VersionedTransaction.from_bytes(base64.b64decode(r["transaction"][0]))
        except Exception:
            continue
        keys = [str(k) for k in vtx.message.account_keys]
        for ix in vtx.message.instructions:
            pid = keys[ix.program_id_index]
            progs[PROGNAME.get(pid, pid)] = progs.get(PROGNAME.get(pid, pid), 0) + 1
        # token balance deltas for the dep USDC ata
        meta = r["meta"]
        for bal in (meta.get("postTokenBalances") or []):
            if bal.get("mint") == USDC and bal.get("owner") == addr:
                pre = next((p for p in (meta.get("preTokenBalances") or []) if p["accountIndex"]==bal["accountIndex"]), None)
                pre_amt = float(pre["uiTokenAmount"]["uiAmountString"]) if pre else 0.0
                post_amt = float(bal["uiTokenAmount"]["uiAmountString"])
                token_flows[s["signature"]] = (pre_amt, post_amt)
        time.sleep(0.1)
    print("programs interacted with:")
    for k, v in sorted(progs.items(), key=lambda x:-x[1]):
        print(f"   {k:26s} {v}")
    print("USDC ata balance changes (pre->post):")
    for sig, (a, b) in list(token_flows.items())[:20]:
        print(f"   {sig[:16]} {a:,.2f} -> {b:,.2f}")

analyze("CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE", "deposit_authority")
