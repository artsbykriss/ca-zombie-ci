#!/usr/bin/env python3
"""Read-only sims: fresh-signer stake replay, swap round-trip, rate re-base."""
import base64, json, sys, hashlib, struct
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

P = Pubkey.from_string("par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV")
def disc(n): return hashlib.sha256(f"global:{n}".encode()).digest()[:8]

def run(ixs, payer, label, extra_accounts=None):
    bh = Hash.from_string(call("getLatestBlockhash",[{"commitment":"confirmed"}])["result"]["value"]["blockhash"])
    msg = Message.new_with_blockhash(ixs, payer, bh)
    tx = Transaction.populate(msg, [Signature.default()]*msg.header.num_required_signatures)
    r = call("simulateTransaction",[base64.b64encode(bytes(tx)).decode(),
             {"sigVerify":False,"replaceRecentBlockhash":True,"encoding":"base64","commitment":"confirmed"}])
    val = r.get("result",{})
    if "value" in val: val = val["value"]
    print(f"\n##### {label}\n   err = {json.dumps(val.get('err'))}  units={val.get('unitsConsumed')}")
    for l in (val.get("logs") or []):
        if "Program log:" in l or "failed" in l or "success" in l:
            print("   ", l)
    return val

# --- replay the real stake tx (non-authority staker 5RfcgB1...) with fresh price feed ---
def stake_ix():
    keys = ["fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe",
            "HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop",
            "So11111111111111111111111111111111111111112",
            "FBdMBWTmnKdGp3oRX52Esiu48FeqAzhpDGYRS6GhUYw",
            "8H5kdi2JWh4CurrFiSLBXittynARfgmBWxKBzNoHxPvG",
            "HbUDmPG886BWdoNeenQGdpo2yxCdUXJVRn9Z3DcVJXd5",
            "4J93x2zCNMrL4Qq8Nuvjk9yNLNkf1Vmqz14UxtcM4uny",
            "EcAKJY91yf4ekXqe1y6g8CsSxSxaeA74Q1kHN44pdyxV",
            "7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE",
            "5RfcgB1KUeoUjxph7bLqLTdJ1DwbwazXQHGMeoDHoaen",
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
            "11111111111111111111111111111111"]
    w = {1:True, 2:True, 3:True, 4:True, 5:True, 6:True, 7:True, 9:True}
    metas = [AccountMeta(Pubkey.from_string(k), k=="5RfcgB1KUeoUjxph7bLqLTdJ1DwbwazXQHGMeoDHoaen", w.get(i,False)) for i,k in enumerate(keys)]
    data = disc("stake") + (121000066560).to_bytes(8,"little") + b"\x00"
    return Instruction(P, data, metas)

staker = Pubkey.from_string("5RfcgB1KUeoUjxph7bLqLTdJ1DwbwazXQHGMeoDHoaen")
run([stake_ix()], staker, "REPLAY real stake (non-authority staker 5RfcgB1...) fresh price feed")

# --- swap_lst round trip pikUSDC -> figUSDC -> pikUSDC ---
PIK = Pubkey.from_string("EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7")
PIK_LST = Pubkey.from_string("8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z")
PIK_FEE = Pubkey.from_string("Bw4N68gHwCJGewLdaBfQToHtKhVcMBRvNhkRxa5ZPV17")
FIG = Pubkey.from_string("7H59KP2prV63CEbVs37LBbiVFuMBjtNxvXc96wk4Dh4X")
FIG_LST = Pubkey.from_string("31uoq7em4R2LW5sPX4wbRWoYkNSUQYgrvQqmycuxzFTU")
FIG_FEE = Pubkey.from_string("AgCDRjZ6g4HkCp51koSYuaRy2eBaZKdRDLN2aNEzb11v")
AC = Pubkey.from_string("fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe")
PF = Pubkey.from_string("7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE")
TOK = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYS = Pubkey.from_string("11111111111111111111111111111111")
ORD = Pubkey.from_string("5RfcgB1KUeoUjxph7bLqLTdJ1DwbwazXQHGMeoDHoaen")

def swap_ix(src_pair, src_lst, src_user, dst_pair, dst_lst, dst_user, src_fee, dst_fee, user, amt):
    data = disc("swap_lst") + amt.to_bytes(8,"little") + b"\x00"
    metas = [AccountMeta(src_pair,False,True), AccountMeta(src_lst,False,True), AccountMeta(src_user,True,False),
             AccountMeta(dst_pair,False,True), AccountMeta(dst_lst,False,True), AccountMeta(dst_user,True,True),
             AccountMeta(src_fee,True,False), AccountMeta(dst_fee,True,False), AccountMeta(user,True,True),
             AccountMeta(AC,False,False), AccountMeta(PF,False,False), AccountMeta(TOK,False,False),
             AccountMeta(ATA,False,False), AccountMeta(SYS,False,False)]
    return Instruction(P, data, metas)

# The real swap tx used pikSOL->exSOL. We can't know ORD's figUSDC ATA. So just replay the real swap tx accounts.
rows = json.load(open("tx-mix.json"))
sw = [x for x in rows if x["ix"]=="swap_lst"][0]
tx = call("getTransaction",[sw["sig"],{"encoding":"base64","maxSupportedTransactionVersion":0}])["result"]
from solders.transaction import VersionedTransaction
vtx = VersionedTransaction.from_bytes(base64.b64decode(tx["transaction"][0]))
msg = vtx.message; keys=[str(k) for k in msg.account_keys]
for ix in msg.instructions:
    if keys[ix.program_id_index]==str(P):
        metas=[AccountMeta(Pubkey.from_string(keys[a]), keys[a] in [str(Pubkey.from_string(keys[x])) for x in ix.accounts[:2]], True) for a in ix.accounts]
        ix2 = Instruction(P, bytes(ix.data), metas)
        run([ix2], Pubkey.from_string(keys[ix.accounts[8]]), f"REPLAY real swap_lst tx ({sw['sig'][:16]}...)")
        break
