#!/usr/bin/env python3
"""Reflect Tranches — robust read-only authorization probe.

For a real on-chain transaction that invokes the RLP or Proxy program, we replay the SAME
instruction (same program, same account list, same data) under `simulateTransaction` with
sigVerify=false, twice:

  (A) CONTROL  : the real accounts as-is  -> must succeed (proves the replay is faithful)
  (B) UNPRIV   : the real signer's pubkey replaced by an existing UNPRIVILEGED third-party
                 account that holds no Reflect role -> must fail if the instruction is gated

Nothing is signed for broadcast and nothing is sent. Keyless public RPC only.
"""
import base64, json, sys, time, urllib.request
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

RPCS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
# existing system-owned, funded, role-less third parties (verified at runtime)
UNPRIV = ["5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9",
          "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
          "GJRs4FwHtreJRoRSFhVtM4bVD6pBSw5PVddZLPzZAh2Z"]
SYS = "11111111111111111111111111111111"
RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"

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

def pick_unpriv():
    for c in UNPRIV:
        v = rpc("getAccountInfo", [c, {"encoding": "base64"}])["result"]["value"]
        if v and v["owner"] == SYS and v["lamports"] > 1_000_000:
            return c
    raise SystemExit("no unprivileged payer")

def get_tx(sig):
    return rpc("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])["result"]

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n = 0
    for ch in s:
        n = n * 58 + ALPH.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + b

def sim(ixs, payer, label):
    msg = Message.new_with_blockhash(ixs, Pubkey.from_string(payer), Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = (r.get("result") or {}).get("value") or {}
    err = v.get("err")
    print(f"\n  [{label}] err = {err}")
    for l in (v.get("logs") or []):
        if any(k in l for k in ("Error", "error", "failed", "Instruction:", "Program log")):
            print("     ", l[:200])
    return v

def replay(sig, program, fresh, label, transform=None):
    tx = get_tx(sig)
    msg = tx["transaction"]["message"]
    keys = msg["accountKeys"]  # list of dicts with pubkey/signer/writable/source
    # find the top-level instruction for `program`
    for ix in msg["instructions"]:
        if "programId" in ix:
            pid = ix["programId"]
        else:
            pid = keys[ix["programIdIndex"]]["pubkey"]
        if pid != program:
            continue
        metas = []
        kmap = {k["pubkey"]: k for k in keys}
        accts = ix["accounts"]
        if accts and isinstance(accts[0], int):
            accts = [keys[i] for i in accts]
        for k in accts:
            if isinstance(k, str):
                k = kmap[k]
            metas.append((k["pubkey"], k["signer"], k["writable"]))
        d = ix.get("data")
        data = b58d(d) if isinstance(d, str) else base64.b64decode(d)
        print(f"\n===== {label} =====\n  sig {sig}\n  program {program}  accounts {len(metas)}  data {data.hex()[:40]}")
        for i, m in enumerate(metas):
            print(f"   {i:2d} {m[0]} {'S' if m[1] else ' '}{'W' if m[2] else ' '}")
        def build(sub):
            out = []
            for pk, s, w in metas:
                out.append(AccountMeta(Pubkey.from_string(sub.get(pk, pk)), s, w))
            return [Instruction(Pubkey.from_string(program), data, out)]
        # control: real accounts as-is (sigVerify=false)
        ctl_payer = next(pk for pk, s, w in metas if s)
        sim(build({}), ctl_payer, "A CONTROL (real signer)")
        # unprivileged: substitute the signer(s)
        sub = {pk: fresh for pk, s, w in metas if s}
        unpriv = [Instruction(Pubkey.from_string(program), data,
                              [AccountMeta(Pubkey.from_string(sub.get(pk, pk)), s, w) for pk, s, w in metas])]
        sim(unpriv, fresh, "B UNPRIVILEGED signer")
        return

if __name__ == "__main__":
    fresh = pick_unpriv()
    print("unprivileged substitute signer:", fresh)
    sig_rlp = sys.argv[1] if len(sys.argv) > 1 else "4nqAfX3kcW8ZiAcdTFnnJt7k2KKzkniyUw9AW5JtxcH7xPJhEe5kVJt3LFTW8JjLMaBaMkpZXt8WUSuLTpCGLZcQ"
    sig_proxy = sys.argv[2] if len(sys.argv) > 2 else "4jvxMJ9fUSpcS57r8rWeaGKXTiQZUyN4sZWLPnEtYa7LMymVz5m8MQp1UfFXFTKWHs9SxJCVTpDCN6kujGpH6GzL"
    replay(sig_rlp, RLP, fresh, "RLP Withdraw (real tx 460429494)")
    replay(sig_proxy, PROXY, fresh, "Proxy Claim Fees (real tx 460231056)")
