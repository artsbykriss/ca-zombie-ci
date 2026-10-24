#!/usr/bin/env python3
"""Reflect Tranches — robust read-only authorization probe (v2).

Replays WHOLE real on-chain transactions under simulateTransaction (sigVerify=false):
  (A) CONTROL : all instructions with the real signer(s) -> must succeed (faithful replay)
  (B) UNPRIV  : the signer(s) of the TARGET program's instruction substituted by an existing
                role-less third-party account -> must fail if the instruction is gated.
Nothing is signed for broadcast; nothing is sent. Keyless public RPC only.
"""
import base64, json, sys, time, urllib.request
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

RPCS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
UNPRIV = ["5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9",
          "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"]
RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for url in RPCS:
        for a in range(3):
            try:
                req = urllib.request.Request(url, data=body,
                                             headers={"Content-Type": "application/json", "User-Agent": "research"})
                return json.load(urllib.request.urlopen(req, timeout=90))
            except Exception as e:
                last = e; time.sleep(1.5 * (a + 1))
    raise last

def b58d(s):
    n = 0
    for ch in s:
        n = n * 58 + ALPH.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + b

def pick_unpriv():
    for c in UNPRIV:
        v = rpc("getAccountInfo", [c, {"encoding": "base64"}])["result"]["value"]
        if v and v["owner"] == "11111111111111111111111111111111" and v["lamports"] > 1_000_000:
            return c
    raise SystemExit("no unprivileged payer")

def tx_ixs(sig):
    tx = rpc("getTransaction", [sig, {"encoding": "json", "maxSupportedTransactionVersion": 0}])["result"]
    msg = tx["transaction"]["message"]
    static = msg["accountKeys"]
    loaded = (tx.get("meta") or {}).get("loadedAddresses") or {}
    lw = loaded.get("writable", []) or []
    lr = loaded.get("readonly", []) or []
    keys = static + lw + lr
    h = msg["header"]
    nreq, nros, nrou, n = h["numRequiredSignatures"], h["numReadonlySignedAccounts"], h["numReadonlyUnsignedAccounts"], len(static)
    def flags(i):
        if i < n:
            signer = i < nreq
            writable = (i < nreq - nros) if signer else (i < n - nrou)
            return signer, writable
        return False, i < n + len(lw)
    out = []
    for ix in msg["instructions"]:
        pid = keys[ix["programIdIndex"]]
        metas = [(keys[ai],) + flags(ai) for ai in ix["accounts"]]
        out.append((pid, metas, b58d(ix["data"])))
    return out, [static[i] for i in range(nreq)]

def sim(ixs, payer, label):
    msg = Message.new_with_blockhash(ixs, Pubkey.from_string(payer), Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = (r.get("result") or {}).get("value") or {}
    print(f"  [{label}] err = {v.get('err')}")
    for l in (v.get("logs") or []):
        if any(k in l for k in ("Error", "error", "failed", "Instruction:")):
            print("      ", l[:190])
    return v

def replay_whole(sig, target_prog, fresh, label):
    ixs, signers = tx_ixs(sig)
    real_signer = signers[0]
    print(f"\n===== {label} =====\n  sig {sig}  top-level ixs {len(ixs)}  signers {signers}")
    for pid, metas, data in ixs:
        print(f"   - {pid[:14]}  accounts {len(metas)}  data {data.hex()[:24]}")

    def build(sub_map):
        out = []
        for pid, metas, data in ixs:
            ms = []
            for pk, s, w in metas:
                if pid == target_prog and pk in sub_map:
                    ms.append(AccountMeta(Pubkey.from_string(sub_map[pk]), True, w))
                else:
                    ms.append(AccountMeta(Pubkey.from_string(pk), s, w))
            out.append(Instruction(Pubkey.from_string(pid), data, ms))
        return out

    sim(build({}), real_signer, "A CONTROL (real signer)")
    tgt = {pk for pid, metas, data in ixs if pid == target_prog for pk, s, w in metas if pk == real_signer}
    sub = {pk: fresh for pk in tgt}
    sim(build(sub), real_signer, f"B UNPRIV signer on {target_prog[:10]}")

if __name__ == "__main__":
    fresh = pick_unpriv()
    print("unprivileged substitute signer:", fresh)
    if len(sys.argv) > 1:
        replay_whole(sys.argv[1], sys.argv[2], fresh, sys.argv[3] if len(sys.argv) > 3 else "tx")
    else:
        replay_whole("4nqAfX3kcW8ZiAcdTFnnJt7k2KKzkniyUw9AW5JtxcH7xPJhEe5kVJt3LFTW8JjLMaBaMkpZXt8WUSuLTpCGLZcQ",
                     RLP, fresh, "RLP Withdraw (real tx 460429494)")
        replay_whole("4jvxMJ9fUSpcS57r8rWeaGKXTiQZUyN4sZWLPnEtYa7LMymVz5m8MQp1UfFXFTKWHs9SxJCVTpDCN6kujGpH6GzL",
                     PROXY, fresh, "Proxy Claim Fees (real tx 460231056)")
