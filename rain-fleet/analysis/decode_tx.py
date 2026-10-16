#!/usr/bin/env python3
"""Decode exploit txs: raw instruction data, ed25519 fields, account layouts."""
import sys, json, base64, struct
import sol_rpc as S

ED25519 = "Ed25519SigVerify111111111111111111111111111"

def parse_ed25519(data_b64):
    b = base64.b64decode(data_b64)
    if len(b) < 2:
        return {"raw_len": len(b)}
    n = b[0]
    out = {"num_sigs": n, "entries": []}
    off = 2
    for i in range(n):
        if off + 14 > len(b):
            break
        sig_off, sig_ix, pk_off, pk_ix, msg_off, msg_sz, msg_ix = struct.unpack_from("<HHHHHHH", b, off)
        out["entries"].append({
            "sig_off": sig_off, "sig_ix": sig_ix, "pk_off": pk_off, "pk_ix": pk_ix,
            "msg_off": msg_off, "msg_size": msg_sz, "msg_ix": msg_ix,
            "sig": b[sig_off:sig_off+64].hex() if sig_ix == 0xFFFF and sig_off+64 <= len(b) else None,
            "pk": b[pk_off:pk_off+32].hex() if pk_ix == 0xFFFF and pk_off+32 <= len(b) else None,
            "msg": b[msg_off:msg_off+msg_sz].hex() if msg_ix == 0xFFFF and msg_off+msg_sz <= len(b) else None,
        })
        off += 14
    return out

def decode_tx(sig):
    t = S.rpc("getTransaction", [sig, {"encoding": "json", "maxSupportedTransactionVersion": 0, "commitment": "finalized"}])
    if not t:
        return None
    tx = t["transaction"]; meta = t.get("meta") or {}
    msg = tx["message"]
    keys = msg["accountKeys"]
    print(f"\n===== TX {sig} =====")
    print("slot", t.get("slot"), "err", meta.get("err"))
    print("feePayer", keys[0])
    for i, ix in enumerate(msg["instructions"]):
        if "programId" in ix:
            pid = ix["programId"]
            accs = ix.get("accounts", [])
        else:
            pid = keys[ix["programIdIndex"]]
            accs = ix.get("accounts", [])
        data = ix.get("data", "")
        if isinstance(data, list):
            data = base64.b64encode(bytes(data)).decode()
        info = ""
        if pid == ED25519:
            info = json.dumps(parse_ed25519(data))
        elif pid not in ("ComputeBudget111111111111111111111111111111", "11111111111111111111111111111111"):
            raw = base64.b64decode(data) if data else b""
            info = f"disc={raw[:8].hex()} datalen={len(raw)}"
        print(f"[{i}] pid={pid} nacc={len(accs)} {info}")
        if pid not in ("ComputeBudget111111111111111111111111111111", ED25519):
            for j, a in enumerate(accs):
                print(f"     acc[{j}] {keys[a] if isinstance(a,int) else a}")
    return t

if __name__ == "__main__":
    for sig in sys.argv[1:]:
        decode_tx(sig)
