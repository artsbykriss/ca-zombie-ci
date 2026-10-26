"""Iterative Anchor account-layout discovery by simulation.

Pass a long list of placeholder accounts for a given instruction discriminator and read the
Anchor error: the first failing account name tells us the layout position by position.
Read-only (simulateTransaction only).
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
ATTACKER = "7orgFWEBNCsqspUTX8AZurjRfHrgRYZiswm4ewqJmH9E"
SYS = "11111111111111111111111111111111"


def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8]


def run(ix_name, accounts, data_extra=b"", payer=ATTACKER):
    """accounts: list of (pubkey, is_signer, is_writable)"""
    metas = [AccountMeta(Pubkey.from_string(p), s, w) for p, s, w in accounts]
    ix = Instruction(PID, disc(ix_name) + data_extra, metas)
    msg = Message.new_with_blockhash([ix], Pubkey.from_string(payer), Hash.default())
    tx = VersionedTransaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    b64 = base64.b64encode(bytes(tx)).decode()
    r = rpc2.call("simulateTransaction", [b64, {"encoding": "base64", "sigVerify": False,
                  "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = r["value"]
    print("== %s (%d accts) err=%s units=%s" % (ix_name, len(accounts), v.get("err"), v.get("unitsConsumed")))
    for l in (v.get("logs") or []):
        print("    ", l)
    return v


if __name__ == "__main__":
    name = sys.argv[1]
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    extra = bytes.fromhex(sys.argv[3]) if len(sys.argv) > 3 else b""
    accts = [(ATTACKER, True, True)] + [(ATTACKER, False, True)] * n
    run(name, accts, extra)
