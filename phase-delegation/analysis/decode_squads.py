#!/usr/bin/env python3
"""Decode the Squads v4 multisig behind the Phase Delegation pool's manager vault.

Multisig layout (squads-protocol v4):
  discriminator u8, create_key Pubkey, config_authority Pubkey, threshold u16,
  time_lock u32, transaction_index u64, stale_transaction_index u64,
  rent_collector Option<Pubkey>, bump u8, members Vec<Member{Pubkey, Permissions u8}>
Vault PDA = find_program_address(["multisig", multisig, "vault", index_u8], SQDS4ep65...)
"""
import base64, hashlib, sys
sys.path.insert(0, '.')
from rpc import rpc, b58enc

SQDS = "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf"
MULTISIG = "DttWaMuVvTiduZRnguLF7jNxTgiMBZ1hyAumKUiL2KRL"
MANAGER = "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1"

P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P
def is_on_curve(b):
    y = int.from_bytes(b, 'little') & ((1 << 255) - 1)
    if y >= P: return False
    yy = y * y % P
    u = (yy - 1) % P; v = (D * yy + 1) % P
    w = u * pow(v, P - 2, P) % P
    return w == 0 or pow(w, (P - 1) // 2, P) == 1
def cpa(seeds, program):
    return hashlib.sha256(b''.join(seeds) + program + b'ProgramDerivedAddress').digest()
def find_pda(seeds, program):
    for bump in range(255, -1, -1):
        a = cpa(list(seeds) + [bytes([bump])], program)
        if not is_on_curve(a): return a, bump
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58dec(s):
    n = 0
    for ch in s: n = n * 58 + B58.index(ch)
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + n.to_bytes((n.bit_length() + 7) // 8, "big")

res = rpc("getAccountInfo", [MULTISIG, {"encoding": "base64"}])
v = res["value"]
print("multisig account owner:", v["owner"], "space:", v["space"], "lamports:", v["lamports"])
raw = base64.b64decode(v["data"][0])
o = 0
disc = raw[o]; o += 1
create_key = b58enc(raw[o:o+32]); o += 32
config_auth = b58enc(raw[o:o+32]); o += 32
threshold = int.from_bytes(raw[o:o+2], "little"); o += 2
time_lock = int.from_bytes(raw[o:o+4], "little"); o += 4
tx_index = int.from_bytes(raw[o:o+8], "little"); o += 8
stale_index = int.from_bytes(raw[o:o+8], "little"); o += 8
rc_tag = raw[o]; o += 1
rent_collector = b58enc(raw[o:o+32]) if rc_tag else None
if rc_tag: o += 32
bump = raw[o]; o += 1
n_members = int.from_bytes(raw[o:o+4], "little"); o += 4
members = []
for i in range(n_members):
    key = b58enc(raw[o:o+32]); perm = raw[o+32]
    members.append((key, perm)); o += 33
print(f"discriminator={disc} threshold={threshold}/{n_members} time_lock={time_lock}s")
print("create_key:", create_key)
print("config_authority:", config_auth)
print("rent_collector:", rent_collector, "bump:", bump)
print("tx_index:", tx_index, "stale:", stale_index)
for k, p in members:
    perm_str = ("Initiate" if p & 1 else "") + ("|Vote" if p & 2 else "") + ("|Execute" if p & 4 else "")
    print(f"  member {k} perms=0x{p:02x} ({perm_str})")
print("decoded", o, "of", len(raw), "bytes")

# find vault index for the manager
sq = b58dec(SQDS); ms = b58dec(MULTISIG)
for idx in range(256):
    a, b = find_pda([b"multisig", ms, b"vault", bytes([idx])], sq)
    if b58enc(a) == MANAGER:
        print(f"\nMANAGER IS Squads vault index {idx} of multisig {MULTISIG} (bump {b})")
        break
else:
    print("\nmanager is NOT a vault PDA of this multisig (check derivation)")
