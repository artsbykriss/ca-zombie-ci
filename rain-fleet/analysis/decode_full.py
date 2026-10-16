#!/usr/bin/env python3
"""Full decoder for Rain exploit txs + Anchor discriminator matching."""
import sys, json, hashlib, struct
import sol_rpc as S

def rawdata(ix):
    d = ix.get("data", "")
    if isinstance(d, list):
        return bytes(d)
    try:
        return bytes.fromhex(d)
    except Exception:
        return S.b58decode(d) if d else b""

def disc(name, kind="global"):
    return hashlib.sha256(f"{kind}:{name}".encode()).digest()[:8]

CANDIDATES = [
    "submit_signatures", "add_collateral_admin", "withdraw_collateral_asset",
    "remove_collateral_admin", "submit_old_collateral_signatures",
    "create_collateral", "make_payment_from_collateral", "update_collateral_admin_threshold",
    "increase_funds_nonce", "close_stale_collateral_admin_signatures",
    "request_permissionless_withdrawal", "process_permissionless_withdrawal",
    "transfer_collateral_team", "migrate_collateral_info", "liquidate_assets",
    "publish_statement", "mark_statement_paid", "withdraw_single_signer_collateral_asset",
    "update_statement", "create_single_signer_collateral", "make_payment_from_user_account",
]
DISC_MAP = {disc(n).hex(): n for n in CANDIDATES}
# account discriminators
ACC = ["Collateral", "Signatures", "Coordinator", "Statement", "WithdrawalRequest", "CollateralInfo", "UserAccount"]
ACC_MAP = {disc(n, "account").hex(): n for n in ACC}

def decode(sig, verbose=True):
    t = S.rpc("getTransaction", [sig, {"encoding": "json", "maxSupportedTransactionVersion": 0, "commitment": "finalized"}])
    if not t:
        print(sig, "NOT FOUND"); return None
    msg = t["transaction"]["message"]; keys = msg["accountKeys"]; meta = t["meta"]
    print(f"\n===== {sig[:20]}… slot={t.get('slot')} err={meta.get('err')} =====")
    for i, ix in enumerate(msg["instructions"]):
        pid = keys[ix["programIdIndex"]]
        raw = rawdata(ix)
        if pid.startswith("Ed25519"):
            n = raw[0]
            entries = []
            off = 2
            for e in range(n):
                so, si, po, pi, mo, ms, mi = struct.unpack_from("<HHHHHHH", raw, off); off += 14
                entries.append(f"sig(off={so},ix={si}) pk(off={po},ix={pi}) msg(off={mo},sz={ms},ix={mi})")
            print(f"  [{i}] ED25519 n={n} :: " + " | ".join(entries))
            # resolve payloads against instruction 0..k
            allraw = [rawdata(x) for x in msg["instructions"]]
            for e in range(n):
                so, si, po, pi, mo, ms, mi = struct.unpack_from("<HHHHHHH", raw, 2 + 14*e)
                def grab(off, ln, idx):
                    src = allraw[idx] if idx < len(allraw) else b""
                    return src[off:off+ln]
                print(f"      e{e}: sig={grab(so,64,si).hex()[:32]}… pk={grab(po,32,pi).hex()[:32]}… msg={grab(mo,ms,mi).hex()}")
        elif pid == "ComputeBudget111111111111111111111111111111":
            pass
        elif pid == "11111111111111111111111111111111":
            print(f"  [{i}] SYSTEM transfer len={len(raw)}")
        else:
            d = raw[:8].hex()
            name = DISC_MAP.get(d, ACC_MAP.get(d, "?"))
            print(f"  [{i}] PROGRAM {pid} disc={d} -> {name} args={raw[8:].hex()}")
            accs = [keys[a] for a in ix.get("accounts", [])]
            for j, a in enumerate(accs):
                print(f"       acc[{j}] = {a}")
    if verbose and meta:
        for l in (meta.get("logMessages") or [])[:40]:
            if "Program log" in l or "failed" in l or "Error" in l:
                print("      log:", l[:160])
    return t

if __name__ == "__main__":
    if sys.argv[1] == "d":
        for s in sys.argv[2:]:
            decode(s)
    elif sys.argv[1] == "discs":
        for n in CANDIDATES:
            print(disc(n).hex(), n)
