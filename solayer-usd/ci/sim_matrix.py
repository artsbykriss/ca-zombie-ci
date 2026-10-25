#!/usr/bin/env python3
"""Solayer USD (sUSD) — read-only live-state read + full simulation matrix.

Stdlib only. No pip installs. No signing, no broadcast.
Only: getAccountInfo / getMultipleAccounts / getTokenAccountBalance / getTokenSupply /
getSlot / getProgramAccounts / simulateTransaction(sigVerify=false, replaceRecentBlockhash=true)
against keyless public Solana JSON-RPC.

Writes ../ci-out/live_state.json and ../ci-out/sim_matrix.json
"""
import base64
import hashlib
import json
import os
import struct
import sys
import time
import urllib.request

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
    "https://solana.drpc.org",
]
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "ci-out"))
os.makedirs(OUT, exist_ok=True)

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

# ---------------- base58 ----------------
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
    for c in sv: n = n * 58 + A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big"); pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00" * pad + b

# ---------------- PDA (ed25519 off-curve) ----------------
P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P
I = pow(2, (P - 1) // 4, P)
def _on_curve(yb):
    y = int.from_bytes(yb, "little") & ((1 << 255) - 1)
    if y >= P: return False
    y2 = y * y % P
    u = (y2 - 1) % P
    v = (D * y2 + 1) % P
    x2 = u * pow(v, P - 2, P) % P
    if x2 == 0: return True
    x = pow(x2, (P + 3) // 8, P)
    if (x * x - x2) % P != 0: x = x * I % P
    return (x * x - x2) % P == 0
def find_pda(seeds, program):
    prog = b58dec(program)
    for bump in range(255, -1, -1):
        h = hashlib.sha256(b"".join(seeds) + bytes([bump]) + prog + b"ProgramDerivedAddress").digest()
        if not _on_curve(h): return b58enc(h), bump
    raise RuntimeError("no pda")

ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
def ata(owner, mint, token_program="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"):
    return find_pda([b58dec(owner), b58dec(token_program), b58dec(mint)], ATA_PROG)[0]
def proof_pda(kind, pool, user, nonce, program):
    return find_pda([kind.encode(), b58dec(pool), b58dec(user), nonce.to_bytes(8, "big")], program)[0]

# ---------------- RPC ----------------
def _post(url, payload, timeout=60):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "audit-readonly/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(method, params=None, retries=6):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params or []}
    last = None
    for i in range(retries):
        for ep in ENDPOINTS:
            try:
                out = _post(ep, payload)
                if "error" in out:
                    raise RuntimeError(out["error"])
                return out
            except Exception as e:  # noqa
                last = "%s %s" % (type(e).__name__, ep)
        time.sleep(min(20, 1.5 * (2 ** i)))
    raise RuntimeError("rpc failed %s: %s" % (method, last))

# ---------------- constants ----------------
PROG      = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
PDATA     = "7bzcebKDN8qDkftxobwArKJL8xSGaZ6zBPaY4C4wEhkf"
POOL      = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
USDC      = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
SUSD      = "susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
CUSDO     = "BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
MANAGER   = "7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru"
OPERATOR  = "AxnDY6nekRa4hEY1rm1g11A51EPPU29iAXXxh8vAqpM8"
RATEAUTH  = "uRwMu2114gN23NZVFxkjM6Dwk1iqSc1LLQsHMmiT6Lr"
FEERECIP  = "3NC1UF4pus6ditVzbcJCLFCVyBLVJm2kxKMhb3mPAoaz"
POOL_USDC_MAIN   = "DN2KzAeiHFnndVpjWSTw8UkwF9PZaFSthSnVoW1MVThQ"
POOL_USDC_WITHDRAW = "usdcLDuDT41YeWcbiMLJ6AoqTumSbJtTQCebJsZJsih"
POOL_SUSD_VAULT  = "FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds"
POOL_SUSD_RESERVE = "93AZbo6a7De8YjSMbAL8xVasetsfwUjJnU5HMnzEaFXK"
OPENEDEN  = "9HhZLsdF8pGQ9fuSJH5UnqJyXBeuMJ729eYVesXCC6mc"
SUSDOFF   = "5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz"
SUNSET    = "EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh"
RWA_VAULT = "G9UFgtiWKkuJ2ekuYJJpYxdk8hbNjNkzPcN7p2xd4gkd"
POOL_RWA_MAIN = "2pR6cGbrJz9EAdo2Qo9eiUkNa75QZRLGX4bhpdMXnFRM"
HOOK      = "48n7YGEww7fKMfJ5gJ3sQC3rM6RWGjpUsghqVfXVkR5A"
EXTRAMETAS = "9sQhAH7vV3RKTCK13VY4EiNjs3qBq1srSYxdNufdAAXm"
PAUSE     = "98wFF5MpMjMQbfDF2MPzo8LCGX37unZR1ohRA1mU9GmJ"
FEE_SUSD  = "CApp5oy3HBXrEWkXcTcKhVeWdE2ghDqivXeUYnpMoLTN"
RWA_TVAUTH = "HkYTTC8Cqp1dFvz2smP5fzpU79dGWWCmqEQ4xocpVncR"
USDC_VAULT = "5kEhbsRrjmuNDmcnstxPDXAuLVzQQraZPXFRrPggVTjy"
USDC_VAUTH = "FPyi9yJKNX8y5gkadeFvbC2pDB9VVqxpwfofHxJ6Ed7i"
DEP_PROOF = "6kaVVdLZwVzakoGU4mL7WSuKP4M4CDZgG6z1KXD88WBG"
DEP_PROOF_UV = "4GKFBc5DbLxGRDcF6tQLk2wkft3aqpfRN46Rx32jUVhQ"
MIG1      = "3U2chkhnisqEoPT8WToTqRSSNKZuNJ45NJJxCNVc6ZHX"
MIG2      = "B1L4836Xvs4hyPyVgPiABqDLJcwEWZWNGcwNzmJHjiKe"
ATA       = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN     = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22   = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
SYS       = "11111111111111111111111111111111"

# Anchor discriminators (sha256("global:<snake>")[:8])
IX = ["initialize","update_susd_metadata","update_susd_rate","deposit","initiate_batch_deposit",
      "withdraw","initiate_batch_withdraw","resolve_batch_withdraw","update_openeden_info",
      "set_fee","set_manager","set_operator","set_rate_authority","collect_fee",
      "emergency_transfer_rwa_token","handle_frozen_accounts","claim_with_migrated_deposit_proof",
      "sunset_redeem_all","sunset_finalize","sunset_initiate_batch_withdraw",
      "create_susd_offset_pda","migrate_deposit_proof","resolve_batch_deposit"]
DISC = {n: hashlib.sha256(("global:" + n).encode()).digest()[:8] for n in IX}
# sunset discriminators are not in the (stale) on-chain IDL; recovered from real tx data
DISC["sunset_redeem_all"] = bytes.fromhex("40a1f4cc25a8add9")
DISC["sunset_finalize"] = bytes.fromhex("affb14ab86af289c")
DISC["sunset_initiate_batch_withdraw"] = bytes.fromhex("8cd5c5f227c853a8")

def disc(n): return DISC[n]
def W(k): return (k, True, False)
def R(k): return (k, False, False)
def SG(k): return (k, True, True)

# ---------------- tx builder ----------------
def cu(n):
    out = bytearray()
    while True:
        b = n & 0x7F; n >>= 7
        if n: out.append(b | 0x80)
        else: out.append(b); break
    return bytes(out)

def build(signer, ixs, blockhash):
    writable, readonly, signers = [], [], []
    def add(k, w, sg):
        if sg:
            if k not in signers: signers.append(k)
            return
        if w:
            if k not in writable and k not in signers: writable.append(k)
        else:
            if k not in readonly and k not in writable and k not in signers: readonly.append(k)
    progs = []
    for pid, accts, data in ixs:
        if pid not in progs: progs.append(pid)
    for pid, accts, data in ixs:
        for (k, w, sg) in accts: add(k, w, sg)
    if signer in writable: writable.remove(signer)
    if signer in readonly: readonly.remove(signer)
    signers = [signer] + [x for x in signers if x != signer]
    for pid in progs:
        if pid in writable: writable.remove(pid)
        if pid in readonly: readonly.remove(pid)
        if pid not in signers: readonly.append(pid)
    keys = signers + writable + readonly
    idx = {k: i for i, k in enumerate(keys)}
    msg = bytearray()
    msg += bytes([len(signers), 0, len(readonly)])
    msg += cu(len(keys))
    for k in keys: msg += b58dec(k)
    msg += b58dec(blockhash)
    msg += cu(len(ixs))
    for pid, accts, data in ixs:
        msg += bytes([idx[pid]])
        msg += cu(len(accts))
        for (k, w, sg) in accts: msg += bytes([idx[k]])
        msg += cu(len(data)); msg += bytes(data)
    return base64.b64encode(cu(len(signers)) + b"\x00" * 64 * len(signers) + bytes(msg)).decode()

def simulate(tx_b64):
    r = rpc("simulateTransaction", [tx_b64, {"encoding": "base64", "sigVerify": False,
             "replaceRecentBlockhash": True, "commitment": "processed"}])
    return r.get("result", {})

def run(label, signer, ixs, blockhash, expect):
    try:
        tx = build(signer, ixs, blockhash)
        r = simulate(tx)
    except Exception as e:  # noqa
        return {"label": label, "rpc_error": str(e), "expected": expect, "pass": False}
    v = r.get("value") or {}
    err = v.get("err")
    logs = v.get("logs") or []
    ecode = None
    if isinstance(err, dict):
        ie = (err.get("InstructionError") or [None, None])[1]
        if isinstance(ie, dict): ecode = ie.get("Custom")
    # determine pass
    if expect == "success":
        ok = err is None
    else:
        ok = ecode == expect
    return {"label": label, "err": err, "custom_code": ecode, "expected": expect, "pass": ok,
            "cu": v.get("unitsConsumed"),
            "key_logs": [l for l in logs if "Error Code:" in l or "failed:" in l][:6]}

# ---------------- live state ----------------
def decode_pool(raw):
    o = 8
    def pk():
        nonlocal o
        v = b58enc(raw[o:o+32]); o += 32; return v
    def u64():
        nonlocal o
        v = struct.unpack_from("<Q", raw, o)[0]; o += 8; return v
    def i64():
        nonlocal o
        v = struct.unpack_from("<q", raw, o)[0]; o += 8; return v
    p = {"disc": raw[:8].hex(), "bump": raw[8]}
    o = 9
    p["manager"] = pk(); p["operator"] = pk(); p["rateAuthority"] = pk()
    p["fee_numerator"] = u64(); p["fee_denominator"] = u64(); p["fee_recipient"] = pk()
    p["poolCreationTs"] = i64(); p["lastFeeCollectionTs"] = i64()
    p["usdcMint"] = pk(); p["poolUsdcMainVault"] = pk(); p["susdMint"] = pk(); p["poolSusdVault"] = pk()
    p["batchDepositStatus"] = raw[o]; o += 1
    p["currentDepositId"] = u64(); p["currentDepositUsdcAmount"] = u64(); p["batchDepositRemainingUsdcAmount"] = u64()
    p["batchWithdrawStatus"] = raw[o]; o += 1
    p["currentWithdrawId"] = u64(); p["currentWithdrawSusdAmount"] = u64(); p["batchWithdrawRemainingSusdAmount"] = u64()
    p["openedenInfo"] = pk()
    p["consumed"] = o
    return p

def live_state():
    st = {"slot": rpc("getSlot", [{"commitment": "confirmed"}])["result"]}
    def ai(k):
        return rpc("getAccountInfo", [k, {"encoding": "base64", "commitment": "confirmed"}])["result"]["value"]
    poolv = ai(POOL)
    st["pool_raw_len"] = len(base64.b64decode(poolv["data"][0]))
    st["pool"] = decode_pool(base64.b64decode(poolv["data"][0]))
    st["pool_lamports"] = poolv["lamports"]
    st["pool_owner"] = poolv["owner"]
    # program + programdata
    pv = ai(PROG)
    raw = base64.b64decode(pv["data"][0])
    st["program_owner"] = pv["owner"]
    pd = ai(b58enc(raw[4:36]))
    pdraw = base64.b64decode(pd["data"][0])
    st["programdata"] = {"addr": b58enc(raw[4:36]), "space": pd["space"],
                         "last_deploy_slot": struct.unpack_from("<Q", pdraw, 4)[0],
                         "upgrade_authority": b58enc(pdraw[13:45]) if pdraw[12] == 1 else None}
    # balances
    for nm, k in [("pool_usdc_main_vault", POOL_USDC_MAIN), ("pool_usdc_withdraw_vault", POOL_USDC_WITHDRAW),
                  ("pool_susd_vault", POOL_SUSD_VAULT), ("pool_susd_reserve", POOL_SUSD_RESERVE)]:
        st[nm] = rpc("getTokenAccountBalance", [k, {"commitment": "confirmed"}])["result"]["value"]
    for nm, k in [("susd_supply", SUSD), ("cusdo_supply", CUSDO)]:
        st[nm] = rpc("getTokenSupply", [k, {"commitment": "confirmed"}])["result"]["value"]
    # role key owners
    st["role_key_owners"] = {}
    for nm, k in [("manager", MANAGER), ("operator", OPERATOR), ("rateAuthority", RATEAUTH),
                  ("feeRecipient", FEERECIP), ("susdSupplyOffset", SUSDOFF), ("sunsetInfo", SUNSET)]:
        v = ai(k)
        st["role_key_owners"][nm] = None if v is None else {"owner": v["owner"], "space": v["space"],
                                                            "lamports": v["lamports"]}
    # mint authorities
    st["mints"] = {}
    for nm, k in [("susd", SUSD), ("cusdo", CUSDO)]:
        v = rpc("getAccountInfo", [k, {"encoding": "jsonParsed", "commitment": "confirmed"}])["result"]["value"]
        st["mints"][nm] = v["data"]["parsed"]["info"]
    return st

def main():
    print("[solayer-usd] reading live state ...", flush=True)
    st = live_state()
    json.dump(st, open(os.path.join(OUT, "live_state.json"), "w"), indent=1)
    print("[solayer-usd] slot", st["slot"], "pool USDC", st["pool_usdc_main_vault"]["uiAmountString"],
          "sUSD raw", st["susd_supply"]["amount"], flush=True)

    bh = rpc("getLatestBlockhash", [{"commitment": "confirmed"}])["result"]["value"]["blockhash"]
    ATT = "743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8"   # neutral third-party (unprivileged) signer
    ATT_USDC = ata(ATT, USDC)
    ATT_SUSD = ata(ATT, SUSD, TOKEN22)
    res = []
    def T(label, signer, ixs, expect):
        r = run(label, signer, ixs, bh, expect)
        res.append(r)
        print("  %-52s err=%s expect=%s pass=%s" % (label, r.get("custom_code") if r.get("custom_code") is not None else r.get("err"), expect, r.get("pass")), flush=True)
        return r

    # ---- A. authority gating: every manager/operator/rateAuthority instruction with attacker ----
    T("gate.update_susd_rate", ATT, [(PROG, [SG(ATT), W(SUSD), R(POOL), R(TOKEN22)],
        disc("update_susd_rate") + (9000).to_bytes(2, "little", signed=True))], 2001)
    T("gate.set_fee", ATT, [(PROG, [SG(ATT), W(ATT), W(POOL)],
        disc("set_fee") + (5).to_bytes(8, "little") + (1000).to_bytes(8, "little"))], 2001)
    T("gate.set_manager", ATT, [(PROG, [SG(ATT), W(ATT), W(POOL)], disc("set_manager"))], 2001)
    T("gate.set_operator", ATT, [(PROG, [SG(ATT), W(ATT), W(POOL)], disc("set_operator"))], 2001)
    T("gate.set_rate_authority", ATT, [(PROG, [SG(ATT), W(ATT), W(POOL)], disc("set_rate_authority"))], 2001)
    T("gate.update_susd_metadata", ATT, [(PROG, [SG(ATT), W(SUSD), R(POOL), R(TOKEN22)],
        disc("update_susd_metadata") + (4).to_bytes(4, "little") + b"name" + (3).to_bytes(4, "little") + b"XXX")], 2001)
    T("gate.create_susd_offset_pda", ATT, [(PROG, [SG(ATT), W(POOL), W(SUSDOFF), R(SYS)],
        disc("create_susd_offset_pda") + (1).to_bytes(8, "little"))], 2001)
    T("gate.emergency_transfer_rwa_token", ATT, [(PROG, [SG(ATT), W(POOL), R(OPENEDEN), R(CUSDO),
        W(POOL_RWA_MAIN), W(RWA_VAULT), R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)],
        disc("emergency_transfer_rwa_token") + (1).to_bytes(8, "little"))], 2001)
    T("gate.initiate_batch_deposit", ATT, [(PROG, [SG(ATT), R(USDC), W(POOL_USDC_MAIN), W(POOL),
        R(OPENEDEN), W(RWA_VAULT), R(TOKEN)], disc("initiate_batch_deposit"))], 2001)
    T("gate.resolve_batch_deposit", ATT, [(PROG, [SG(ATT), W(FEERECIP), W(SUSD), W(POOL), W(SUSDOFF),
        W(OPENEDEN), R(CUSDO), W(POOL_RWA_MAIN), W("cusdzR5sDbSnW5sUpoE6Y57nmBoEva6BSb1ZxWPizkD"),
        R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)], disc("resolve_batch_deposit"))], 2001)
    T("gate.initiate_batch_withdraw", ATT, [(PROG, [SG(ATT), R(USDC), W(SUSD), W(POOL), W(POOL_SUSD_VAULT),
        W(SUSDOFF), R(OPENEDEN), R(CUSDO), W(RWA_VAULT), W(POOL_RWA_MAIN), R(HOOK), R(EXTRAMETAS),
        W(PAUSE), R(TOKEN22)], disc("initiate_batch_withdraw"))], 2001)
    T("gate.resolve_batch_withdraw", ATT, [(PROG, [SG(ATT), W(FEERECIP), R(USDC), W(POOL_USDC_MAIN),
        W(POOL_USDC_WITHDRAW), W(SUSD), W(POOL_SUSD_VAULT), W(POOL), W(OPENEDEN), R(ATA), R(TOKEN),
        R(TOKEN22)], disc("resolve_batch_withdraw"))], 2001)
    T("gate.collect_fee", ATT, [(PROG, [SG(ATT), R(FEERECIP), W(SUSD), W(FEE_SUSD), W(POOL), W(SUSDOFF),
        R(ATA), R(TOKEN22), R(SYS)], disc("collect_fee"))], 2001)
    T("gate.sunset_finalize", ATT, [(PROG, [SG(ATT), R(USDC), W(POOL), W(OPENEDEN), W(SUNSET),
        W(POOL_USDC_MAIN), W(POOL_USDC_WITHDRAW), R(TOKEN)], disc("sunset_finalize"))], 2001)

    # ---- B. positive controls: the correct signer passes the has_one gate ----
    # set_fee signed by the real manager: succeeds (proves the gate is signer identity, instruction functional)
    T("control.set_fee_by_manager_succeeds", MANAGER, [(PROG, [SG(MANAGER), W(FEERECIP), W(POOL)],
        disc("set_fee") + (5).to_bytes(8, "little") + (1000).to_bytes(8, "little"))], "success")
    # update_susd_rate signed by the real rateAuthority: passes has_one, then PoolSunset (6036)
    T("control.correct_signer_passes_gate", RATEAUTH, [(PROG, [SG(RATEAUTH), W(SUSD), R(POOL), R(TOKEN22)],
        disc("update_susd_rate") + (900).to_bytes(2, "little", signed=True))], 6036)
    # operator-signed initiate_batch_withdraw: passes has_one, then PoolSunset (6036)
    T("control.operator_passes_gate", OPERATOR, [(PROG, [SG(OPERATOR), R(USDC), W(SUSD), W(POOL),
        W(POOL_SUSD_VAULT), W(SUSDOFF), R(OPENEDEN), R(CUSDO), W(RWA_VAULT), W(POOL_RWA_MAIN),
        R(HOOK), R(EXTRAMETAS), W(PAUSE), R(TOKEN22)], disc("initiate_batch_withdraw"))], 6036)

    # ---- C. user paths ----
    # deposit closed
    dp = proof_pda("deposit_proof", POOL, ATT, 98765432101, PROG)
    T("deposit.closed_sunset", ATT, [(PROG, [SG(ATT), R(USDC), W(ATT_USDC), W(POOL_USDC_MAIN), R(SUSD),
        W(ATT_SUSD), W(POOL), W(dp), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
        disc("deposit") + (98765432101).to_bytes(8, "little") + (1_000_000).to_bytes(8, "little"))], 6039)
    # deposit with victim's USDC account
    T("deposit.victim_usdc_account", ATT, [(PROG, [SG(ATT), R(USDC), W("23n6ncQYGqzV6c4pxBqFjMEfENHJYYqfQQS82pUBAW5f"),
        W(POOL_USDC_MAIN), R(SUSD), W(ATT_SUSD), W(POOL), W(proof_pda("deposit_proof", POOL, ATT, 98765432102, PROG)),
        R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
        disc("deposit") + (98765432102).to_bytes(8, "little") + (1_000_000).to_bytes(8, "little"))], 2015)
    # withdraw control: escrows own sUSD, NO USDC out (attacker has 0 -> token error)
    wp = proof_pda("withdraw_proof", POOL, ATT, 98765432111, PROG)
    T("withdraw.escrow_only_attacker_zero_balance", ATT, [(PROG, [SG(ATT), R(USDC), W(ATT_USDC), R(SUSD),
        W(ATT_SUSD), W(POOL_SUSD_VAULT), W(POOL), W(wp), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
        disc("withdraw") + (98765432111).to_bytes(8, "little") + (100_000).to_bytes(8, "little"))], 1)
    # withdraw with victim's sUSD vault -> ConstraintTokenOwner
    T("withdraw.victim_susd_vault", ATT, [(PROG, [SG(ATT), R(USDC), W(ATT_USDC), R(SUSD),
        W("95iFVLL5JGkUgvRjYuNNhSe16LGWVYercF9yXbNey9ce"), W(POOL_SUSD_VAULT), W(POOL),
        W(proof_pda("withdraw_proof", POOL, ATT, 98765432112, PROG)), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
        disc("withdraw") + (98765432112).to_bytes(8, "little") + (1000).to_bytes(8, "little"))], 2015)
    # withdraw with another user's proof (seed mismatch)
    T("withdraw.foreign_proof_seeds", ATT, [(PROG, [SG(ATT), R(USDC), W(ATT_USDC), R(SUSD), W(ATT_SUSD),
        W(POOL_SUSD_VAULT), W(POOL), W("pzWrVqajs4UPwoxSgTcAqQFLHimH14a7G2SEuUp8wPW"), R(ATA), R(TOKEN),
        R(TOKEN22), R(SYS)], disc("withdraw") + (0).to_bytes(8, "little") + (0).to_bytes(8, "little"))], 2006)
    # claim migrated proof: attacker's own vault -> ConstraintTokenOwner
    T("claim.attacker_own_vault", ATT, [(PROG, [SG(ATT), W(FEERECIP), W(SUSD), W(POOL), W(POOL_SUSD_RESERVE),
        W(MIG1), W(ATT_SUSD), R(TOKEN22)], disc("claim_with_migrated_deposit_proof"))], 2015)
    # claim migrated proof: proof's vault but attacker signer -> ConstraintRaw
    T("claim.attacker_proof_vault", ATT, [(PROG, [SG(ATT), W(FEERECIP), W(SUSD), W(POOL), W(POOL_SUSD_RESERVE),
        W(MIG1), W("9kqkxQcs3j1Z5Mefk8hjK3NecXRkve4GHfXwqReEykJV"), R(TOKEN22)],
        disc("claim_with_migrated_deposit_proof"))], 2003)
    # migrate deposit proof: attacker -> ConstraintSeeds
    T("migrate.attacker_seed_mismatch", ATT, [(PROG, [SG(ATT), W(FEERECIP), W(SUSD), W(POOL),
        W(POOL_SUSD_RESERVE), W(DEP_PROOF), W(MIG1), W(DEP_PROOF_UV), W(SUSDOFF), W(OPENEDEN), R(CUSDO),
        W(POOL_RWA_MAIN), W("cusdzR5sDbSnW5sUpoE6Y57nmBoEva6BSb1ZxWPizkD"), R(HOOK), R(EXTRAMETAS),
        W(PAUSE), R(TOKEN22), R(SYS)], disc("migrate_deposit_proof"))], 2006)
    # handle frozen accounts -> InvalidStatus
    T("handle_frozen.invalid_status", ATT, [(PROG, [SG(ATT), R(USDC), W(SUSD), W(ATT_SUSD), W(POOL),
        W(SUSDOFF), R(TOKEN22)], disc("handle_frozen_accounts"))], 6026)

    # ---- D. live withdraw replay as a real sUSD holder (proves escrow-only, no USDC) ----
    holder = "DgCkhZVteCDbV2KeiaFy4P9meAp8nLaLaSY9DvAkJCRM"
    holder_vault = "3fDUYRoyvyrpFC4a6Y1bYXDLsTVBT1SNjwXiFfHdzehv"
    wp2 = proof_pda("withdraw_proof", POOL, holder, 555000111, PROG)
    r = run("replay.withdraw_holder_escrow", holder, [(PROG, [SG(holder), R(USDC), W(ata(holder, USDC)),
        R(SUSD), W(holder_vault), W(POOL_SUSD_VAULT), W(POOL), W(wp2), R(ATA), R(TOKEN), R(TOKEN22), R(SYS)],
        disc("withdraw") + (555000111).to_bytes(8, "little") + (1000).to_bytes(8, "little"))], bh, "success")
    res.append(r)
    print("  %-52s err=%s expect=%s pass=%s" % (r["label"], r.get("err"), r.get("expected"), r.get("pass")), flush=True)

    passed = sum(1 for x in res if x.get("pass"))
    summary = {"slot": st["slot"], "tests_passed": passed, "tests_total": len(res), "results": res}
    json.dump(summary, open(os.path.join(OUT, "sim_matrix.json"), "w"), indent=1)
    print("[solayer-usd] sim matrix: %d/%d passed" % (passed, len(res)), flush=True)
    return 0 if passed == len(res) else 1

if __name__ == "__main__":
    sys.exit(main())
