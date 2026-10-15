#!/usr/bin/env python3
"""
READ-ONLY behavioral probes of the live Serum Swap program (SwaPpA9...) via
simulateTransaction with sigVerify=false.

NOTHING is signed and NOTHING is sent. simulateTransaction only executes against
a throwaway bank. Two kinds of probes:

  1. GATE PROBES  - the "attacker" uses only accounts it legitimately controls
     (its own fresh ATAs, created inside the simulation). Proves that withdrawal
     without LP tokens fails at the LP burn CPI.

  2. BEHAVIOR PROBES - used ONLY to fingerprint which program version is deployed:
     the LP source account is a 3rd party's account which is MARKED as signer in
     the simulated message (possible because sigVerify=false). This is explicitly
     NOT an attack - it only reads the program's internal math (LP burned for a
     given exact-out withdrawal), and it cannot move anything on-chain.

Uses only the keyless public RPC endpoint.
"""
import base64
import json
import struct
import sys
import time
import urllib.request

PROGRAM_ID = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8"
TOKEN_PROGRAM = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA_PROGRAM = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
SYSTEM_PROGRAM = "11111111111111111111111111111111"
RPC = "https://api.mainnet-beta.solana.com"

from solders.pubkey import Pubkey            # noqa: E402
from solders.instruction import Instruction, AccountMeta   # noqa: E402
from solders.message import Message          # noqa: E402
from solders.transaction import Transaction  # noqa: E402
from solders.hash import Hash                # noqa: E402
from solders.signature import Signature      # noqa: E402


def rpc(method, params, retries=3):
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "research/1.0"},
            )
            with urllib.request.urlopen(req, timeout=120) as r:
                d = json.load(r)
            if "error" in d:
                raise RuntimeError(d["error"])
            return d
        except Exception as e:
            last = e
            time.sleep(1 + i)
    raise RuntimeError(f"{method}: {last}")


def ata(wallet: Pubkey, mint: Pubkey) -> Pubkey:
    pda, _ = Pubkey.find_program_address(
        [bytes(wallet), bytes(Pubkey.from_string(TOKEN_PROGRAM)), bytes(mint)],
        Pubkey.from_string(ATA_PROGRAM),
    )
    return pda


def ix_create_ata_idempotent(payer: Pubkey, wallet: Pubkey, mint: Pubkey) -> Instruction:
    metas = [
        AccountMeta(pubkey=payer, is_signer=True, is_writable=True),
        AccountMeta(pubkey=ata(wallet, mint), is_signer=False, is_writable=True),
        AccountMeta(pubkey=wallet, is_signer=False, is_writable=False),
        AccountMeta(pubkey=mint, is_signer=False, is_writable=False),
        AccountMeta(pubkey=Pubkey.from_string(SYSTEM_PROGRAM), is_signer=False, is_writable=False),
        AccountMeta(pubkey=Pubkey.from_string(TOKEN_PROGRAM), is_signer=False, is_writable=False),
    ]
    return Instruction(Pubkey.from_string(ATA_PROGRAM), b"\x01", metas)  # 1 = CreateIdempotent


def ix_withdraw_all(swap: Pubkey, authority: Pubkey, user: Pubkey, pool_mint: Pubkey, lp_src: Pubkey,
                    vault_a: Pubkey, vault_b: Pubkey, dst_a: Pubkey, dst_b: Pubkey,
                    fee_account: Pubkey, pool_token_amount: int, min_a: int = 0, min_b: int = 0) -> Instruction:
    data = b"\x03" + struct.pack("<QQQ", pool_token_amount, min_a, min_b)
    metas = [
        AccountMeta(swap, False, False),
        AccountMeta(authority, False, False),
        AccountMeta(user, True, False),
        AccountMeta(pool_mint, False, True),
        AccountMeta(lp_src, False, True),
        AccountMeta(vault_a, False, True),
        AccountMeta(vault_b, False, True),
        AccountMeta(dst_a, False, True),
        AccountMeta(dst_b, False, True),
        AccountMeta(fee_account, False, True),
        AccountMeta(Pubkey.from_string(TOKEN_PROGRAM), False, False),
    ]
    return Instruction(Pubkey.from_string(PROGRAM_ID), data, metas)


def ix_withdraw_single(swap: Pubkey, authority: Pubkey, user: Pubkey, pool_mint: Pubkey, lp_src: Pubkey,
                       vault_a: Pubkey, vault_b: Pubkey, dst: Pubkey, fee_account: Pubkey,
                       destination_token_amount: int, max_pool_token_amount: int) -> Instruction:
    data = b"\x05" + struct.pack("<QQ", destination_token_amount, max_pool_token_amount)
    metas = [
        AccountMeta(swap, False, False),
        AccountMeta(authority, False, False),
        AccountMeta(user, True, False),
        AccountMeta(pool_mint, False, True),
        AccountMeta(lp_src, False, True),
        AccountMeta(vault_a, False, True),
        AccountMeta(vault_b, False, True),
        AccountMeta(dst, False, True),
        AccountMeta(fee_account, False, True),
        AccountMeta(Pubkey.from_string(TOKEN_PROGRAM), False, False),
    ]
    return Instruction(Pubkey.from_string(PROGRAM_ID), data, metas)


def simulate(instructions, signers, watch_accounts, label):
    msg = Message.new_with_blockhash(
        instructions,
        signers[0],
        Hash.default(),
    )
    tx = Transaction.populate(msg, [Signature.default()] * len(signers))
    tx_b64 = base64.b64encode(bytes(tx)).decode()
    params = [
        tx_b64,
        {
            "sigVerify": False,
            "replaceRecentBlockhash": True,
            "encoding": "base64",
            "commitment": "processed",
            "accounts": {"encoding": "base64", "addresses": watch_accounts},
        },
    ]
    d = rpc("simulateTransaction", params)
    v = d["result"]["value"]
    out = {
        "label": label,
        "instructions": [{"program": str(i.program_id), "data_hex": i.data.hex(),
                          "n_accounts": len(i.accounts)} for i in instructions],
        "signers": [str(s) for s in signers],
        "err": v.get("err"),
        "logs": v.get("logs"),
        "unitsConsumed": v.get("unitsConsumed"),
        "accounts_after": {},
    }
    for a in (v.get("accounts") or []):
        if a and a.get("data"):
            data = base64.b64decode(a["data"][0])
            out["accounts_after"][str(a.get("pubkey") or a.get("address") or "?")] = {
                "len": len(data), "hex_head": data[:8].hex(),
                "owner": a.get("owner"),
            }
    return out


def main():
    cfg = json.load(open(sys.argv[1]))
    results = []
    for probe in cfg["probes"]:
        swap = Pubkey.from_string(probe["swap"])
        authority = Pubkey.from_string(probe["authority"])
        pool_mint = Pubkey.from_string(probe["pool_mint"])
        vault_a = Pubkey.from_string(probe["vault_a"])
        vault_b = Pubkey.from_string(probe["vault_b"])
        mint_a = Pubkey.from_string(probe["mint_a"])
        mint_b = Pubkey.from_string(probe["mint_b"])
        fee_acc = Pubkey.from_string(probe["fee_account"])
        payer = Pubkey.from_string(probe["payer"])
        user = Pubkey.from_string(probe.get("user", probe["payer"]))
        lp_src = Pubkey.from_string(probe.get("lp_src", probe["fee_account"]))
        lp_owner = Pubkey.from_string(probe.get("lp_owner", probe["payer"]))
        lp_src = Pubkey.from_string(probe.get("lp_src") or str(ata(user, pool_mint)))
        lp_owner = Pubkey.from_string(probe.get("lp_owner") or str(user))
        ixs = []
        if probe.get("create_atas"):
            ixs.append(ix_create_ata_idempotent(payer, user, mint_a))
            ixs.append(ix_create_ata_idempotent(payer, user, mint_b))
        if probe.get("create_lp_ata"):
            ixs.append(ix_create_ata_idempotent(payer, user, pool_mint))
        if probe["kind"] == "withdraw_all":
            ixs.append(ix_withdraw_all(swap, authority, lp_owner, pool_mint, lp_src, vault_a, vault_b,
                                       ata(user, mint_a), ata(user, mint_b), fee_acc,
                                       probe["pool_token_amount"], 0, 0))
        elif probe["kind"] == "withdraw_single":
            ixs.append(ix_withdraw_single(swap, authority, lp_owner, pool_mint, lp_src, vault_a, vault_b,
                                          ata(user, mint_a if probe["dest_side"] == "a" else mint_b),
                                          fee_acc, probe["destination_token_amount"], probe["max_pool_token_amount"]))
        watch = [str(x) for x in [swap, vault_a, vault_b, pool_mint, fee_acc, lp_src, ata(user, mint_a), ata(user, mint_b)]]
        signers = [payer]
        for extra in (user, lp_owner):
            if extra != payer and extra not in signers:
                signers.append(extra)
        res = simulate(ixs, signers, watch, probe["label"])
        results.append(res)
        json.dump(results, open(cfg["out"], "w"), indent=1)  # incremental, survives crashes
        print(json.dumps({k: res[k] for k in ("label", "err", "unitsConsumed")}, indent=1))
        time.sleep(0.6)
    json.dump(results, open(cfg["out"], "w"), indent=1)


if __name__ == "__main__":
    main()
