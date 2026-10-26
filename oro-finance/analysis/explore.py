"""Anchor account-layout discovery driver.

Usage:
  python3 explore.py <ix_name> <arg_hex> <pk1[,s][,w]> <pk2,...> ...
Each pk may be suffixed with :s (signer) and :w (writable). Default: not signer, writable.
"""
import sys, json, base64, hashlib
sys.path.insert(0, '.')
import rpc2
from solders.pubkey import Pubkey
from solders.hash import Hash
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import VersionedTransaction
from solders.signature import Signature

PID = Pubkey.from_string("iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop")


def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8]


def parse(spec):
    parts = spec.split(",")
    pk = parts[0]
    signer = "s" in parts[1:]
    writable = "w" in parts[1:] or not signer
    return pk, signer, writable


def run(ix_name, arg_hex, accts, payer=None, verbose=True):
    metas = [AccountMeta(Pubkey.from_string(p), s, w) for p, s, w in accts]
    data = disc(ix_name) + (bytes.fromhex(arg_hex) if arg_hex else b"")
    ix = Instruction(PID, data, metas)
    payer = payer or accts[0][0]
    msg = Message.new_with_blockhash([ix], Pubkey.from_string(payer), Hash.default())
    tx = VersionedTransaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    b64 = base64.b64encode(bytes(tx)).decode()
    r = rpc2.call("simulateTransaction", [b64, {"encoding": "base64", "sigVerify": False,
                  "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = r["value"]
    if verbose:
        print("== %s (%d accts) err=%s units=%s" % (ix_name, len(accts), v.get("err"), v.get("unitsConsumed")))
        for l in (v.get("logs") or []):
            print("    ", l)
    return v


if __name__ == "__main__":
    name = sys.argv[1]
    arg = sys.argv[2]
    accts = [parse(x) for x in sys.argv[3:]]
    run(name, arg, accts)
