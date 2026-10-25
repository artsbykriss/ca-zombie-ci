#!/usr/bin/env python3
"""Find anchor:idl PDA (batched) and brute-force unknown account discriminators."""
import json, base64, sys, os, hashlib, zlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s
HERE = os.path.dirname(os.path.abspath(__file__))
A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")
def b58dec(sv):
    n = 0
    for c in sv: n = n*58 + A.index(c)
    b = n.to_bytes((n.bit_length()+7)//8, "big"); pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00"*pad + b

PROG = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
out = {}
seed = b"anchor:idl"
cands = []
for bump in range(255, -1, -1):
    h = hashlib.sha256(seed + bytes([bump]) + b58dec(PROG) + b"ProgramDerivedAddress").digest()
    cands.append((bump, b58enc(h)))
keys = [c[1] for c in cands]
vals = []
for i in range(0, len(keys), 100):
    rr = s.get_multiple_accounts(keys[i:i+100])
    vals += rr["result"]["value"]
found = []
for (bump, k), v in zip(cands, vals):
    if v is not None:
        found.append({"addr": k, "bump": bump, "owner": v["owner"], "space": v["space"],
                      "lamports": v["lamports"]})
out["idl_pda"] = found
print("idl pda candidates:", found, flush=True)

target = {"184662bf3a907b9e"}
names = ["UserSusdVault","RwaProtocol","RwaProtocolInfo","GlobalConfig","Config","PoolConfig",
         "AdapterConfig","BatchDeposit","BatchWithdraw","Batch","Vault","SusdVault","Susd","Pool",
         "UserVault","SusdUserVault","UserState","SusdSupplyOffset","OpenedenInfo","SunsetInfo",
         "DepositProof","WithdrawProof","MigratedDepositProof","ProtocolInfo","RwaInfo","RwaProtocols",
         "PoolState","State","Global","Admin","TokenConfig","RewardConfig","WithdrawBatch","DepositBatch",
         "SusdMintConfig","MintConfig","PoolConfigAccount","Protocol","RwaProtocolConfig","BatchDepositProof"]
def dd(n): return hashlib.sha256(("account:"+n).encode()).digest()[:8].hex()
matches = [n for n in names if dd(n) in target]
print("account name matches:", matches, flush=True)
out["brute_matches"] = matches
out["brute"] = {dd(n): n for n in names}
json.dump(out, open(os.path.join(HERE, "idl_find.json"), "w"), indent=1)

elf = open(os.path.join(HERE, "solayer_susd.so"), "rb").read()
cands2 = []
start = 0
while True:
    i = elf.find(b'\x78\x9c', start)
    if i < 0: break
    try:
        d2 = zlib.decompress(elf[i:i+400000])
        if b'"instructions"' in d2 or b'"accounts"' in d2:
            cands2.append({"off": i, "len": len(d2), "head": d2[:120].decode('utf8','replace')})
    except Exception:
        pass
    start = i+1
print("zlib idl candidates:", cands2[:5], flush=True)
out["zlib_candidates"] = cands2
json.dump(out, open(os.path.join(HERE, "idl_find.json"), "w"), indent=1)
print("done", flush=True)
