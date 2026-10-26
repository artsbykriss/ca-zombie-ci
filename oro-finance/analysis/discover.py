"""Automated Anchor account-layout discovery.

At each step the current Anchor error names a failing account; we find the message index whose
substitution with the right real account clears/advances the error, fix it, and repeat.

Read-only (simulateTransaction only).
"""
import sys, json, re, time
sys.path.insert(0, '.')
from explore import run

A = "7orgFWEBNCsqspUTX8AZurjRfHrgRYZiswm4ewqJmH9E"
GOLD = "GoLDppdjB1vDTPSGxyMJFqdnj134yH6Prg9eqsGDiw6A"
USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
HKMT = "HKMT2i4kGzktb4AVo4fKkHK4AmpxVyvGEAfotVX3tML4"
PYTH = "2uPQGpm8X4ZkxMHxrAW1QuhXcse1AHEgPih6Xp9NuEWW"
WHIT = "CUVdjuDifxq1Ynh1MF1JFjZfAmYMMejVoXN3b5whf3Ng"
ATA = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
SYS = "11111111111111111111111111111111"
VAULT_GOLD = "BTfWpVQahbeUyhtwN7ATFjmBdv1wfdVPR5K6oYAnWHrx"
VAULT_USDC = "Gy2cgMANTP4HuS9XrogE6jheenETY4Mo3mb2PreraxaY"
INT_V2 = "EviXeqoPLpyP5iusYyAotjjc3QVNnfcySPH732KVrzT3"

CAND = {
    "gold_mint": [(GOLD, False, False)],
    "mint": [(GOLD, False, False), (USDC, False, False)],
    "mint_a": [(GOLD, False, False)],
    "mint_b": [(USDC, False, False)],
    "price_account": [(HKMT, False, True)],
    "price": [(HKMT, False, True)],
    "pyth_price": [(PYTH, False, False)],
    "whitelist": [(WHIT, False, False), ("Hy5PQMwoTu3oKo6BYAcLxiMmDDUFS5cDXv7PNe4RtrMj", False, True)],
    "autorized": [("7f2i7o1j9RZcnZPhLnFqdeGxf3bxiZcK1HpTbniEoTtD", False, True)],
    "autorized_pda": [("7f2i7o1j9RZcnZPhLnFqdeGxf3bxiZcK1HpTbniEoTtD", False, True)],
    "whitelisted_wallet": [(WHIT, False, False)],
    "vault_a": [(VAULT_GOLD, False, True)],
    "vault_b": [(VAULT_USDC, False, True)],
    "vault": [(VAULT_USDC, False, True)],
    "integrator": [(INT_V2, False, False)],
    "token_program": [(TOKEN, False, False)],
    "associated_token_program": [(ATA, False, False)],
    "ata_program": [(ATA, False, False)],
    "system_program": [(SYS, False, False)],
    "user": [(A, False, False)],
    "seller": [(A, True, True)],
    "buyer": [(A, True, True)],
    "authority": [(A, True, True)],
}


def errname(v):
    for l in v.get("logs") or []:
        m = re.search(r"AnchorError caused by account: ([A-Za-z0-9_]+)", l)
        if m:
            return m.group(1), l
    for l in v.get("logs") or []:
        if "Error Code:" in l:
            return None, l
    return None, str(v.get("err"))


def discover(ix, arg_hex, n=14, max_steps=16):
    accts = [(A, True, True)] + [(A, False, True)] * n
    fixed = {0: (A, True, True)}
    for step in range(max_steps):
        v = run(ix, arg_hex, accts, verbose=False)
        name, line = errname(v)
        print("step %d: err=%s name=%s" % (step, v.get("err"), name))
        if name is None:
            print("   final:", line)
            break
        cands = CAND.get(name)
        if not cands:
            print("   no candidate for", name, "->", line)
            break
        placed = False
        for c in cands:
            for i in range(1, len(accts)):
                if i in fixed:
                    continue
                trial = list(accts)
                trial[i] = c
                v2 = run(ix, arg_hex, trial, verbose=False)
                n2, l2 = errname(v2)
                if n2 != name:
                    print("   index %d := %s  (new error %s / %s)" % (i, c[0], n2, v2.get("err")))
                    accts = trial
                    fixed[i] = c
                    placed = True
                    break
            if placed:
                break
        if not placed:
            print("   could not advance for", name)
            break
    print("FINAL ACCOUNTS:")
    for i, a in enumerate(accts):
        print("  %2d %s signer=%s writable=%s" % (i, a[0], a[1], a[2]))
    return accts


if __name__ == "__main__":
    ix = sys.argv[1]
    arg = sys.argv[2]
    discover(ix, arg, int(sys.argv[3]) if len(sys.argv) > 3 else 14)
