#!/usr/bin/env python3
"""Derive SPL Stake Pool PDAs (pure python, no deps) and verify the Phase Delegation
pool's authority topology on-chain:

  withdraw authority  = PDA(["withdraw", pool], SPoo1)
  deposit authority   = PDA(["deposit", pool], SPoo1)   (pool uses explicit 4Y6X... instead)
  stake account       = PDA(["stake", vote, pool], SPoo1)          per validator
  transient stake     = PDA(["stake", vote, pool, seed_le], SPoo1) per validator
  reserve             = PDA(["stake", pool], SPoo1)
"""
import hashlib, json, sys
sys.path.insert(0, '.')
from rpc import rpc, b58enc

P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P

def is_on_curve(b):
    y = int.from_bytes(b, 'little') & ((1 << 255) - 1)
    if y >= P: return False
    yy = y * y % P
    u = (yy - 1) % P
    v = (D * yy + 1) % P
    w = u * pow(v, P - 2, P) % P
    if w == 0: return True
    return pow(w, (P - 1) // 2, P) == 1

def create_program_address(seeds, program):
    return hashlib.sha256(b''.join(seeds) + program + b'ProgramDerivedAddress').digest()

def find_program_address(seeds, program):
    for bump in range(255, -1, -1):
        a = create_program_address(list(seeds) + [bytes([bump])], program)
        if not is_on_curve(a):
            return a, bump
    raise RuntimeError("no bump")

SPOO1 = bytes.fromhex("")  # set below
def b58dec(s):
    B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = 0
    for ch in s: n = n * 58 + B58.index(ch)
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + n.to_bytes((n.bit_length() + 7) // 8, "big")

PROGRAM = b58dec("SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy")
POOL = b58dec("aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6")

wd, wd_bump = find_program_address([b"withdraw", POOL], PROGRAM)
dep, dep_bump = find_program_address([b"deposit", POOL], PROGRAM)
reserve, r_bump = find_program_address([b"stake", POOL], PROGRAM)
print("withdraw authority PDA:", b58enc(wd), "bump", wd_bump)
print("deposit  authority PDA:", b58enc(dep), "bump", dep_bump)
print("reserve stake PDA:      ", b58enc(reserve), "bump", r_bump)
print("stored stake_withdraw_bump_seed: 255")

vlist = json.load(open('vlist_decoded.json'))
derived = []
for v in vlist:
    vote = b58dec(v['vote_account_address'])
    sa, sb = find_program_address([b"stake", vote, POOL], PROGRAM)
    ts, tb = find_program_address([b"stake", vote, POOL, v['transient_seed_suffix'].to_bytes(8, 'little')], PROGRAM)
    derived.append({"vote": v['vote_account_address'], "stake_account": b58enc(sa),
                    "transient": b58enc(ts), "listed_active": v['active_stake_lamports']})
json.dump(derived, open('derived_stake_accounts.json', 'w'), indent=1)
print("derived", len(derived), "stake account PDAs; sample:", derived[0])
