"""Minimal keyless Solana JSON-RPC + PDA + transaction-simulation toolkit.
READ-ONLY: only getAccountInfo / getMultipleAccounts / getProgramAccounts /
getSignaturesForAddress / getTransaction / simulateTransaction(sigVerify=false).
No keys, no signing, no broadcast. Public endpoints only.
"""
import json, urllib.request, time, base64, hashlib, struct
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

EPS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
TOKEN   = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
ATA_PROG= "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
SYS     = "11111111111111111111111111111111"

def rpc(method, params):
    last = None
    for e in EPS:
        for _ in range(3):
            try:
                req = urllib.request.Request(
                    e, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                    headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
                r = json.load(urllib.request.urlopen(req, timeout=45))
                if "error" in r: last = r; break
                return r.get("result")
            except Exception as ex:
                last = str(ex); time.sleep(1.2)
    return {"__err__": last}

def pk(s): return Pubkey.from_string(s)
def pda(seeds, program): return str(Pubkey.find_program_address(seeds, pk(program))[0])
def ata(auth, mint, tp=TOKEN):
    return str(Pubkey.find_program_address([bytes(pk(auth)), bytes(pk(tp)), bytes(pk(mint))], pk(ATA_PROG))[0])
def acct_data(a):
    r = rpc("getAccountInfo", [a, {"encoding":"base64"}])
    v = r.get("value") if isinstance(r, dict) else None
    return base64.b64decode(v["data"][0]) if v and v.get("data") else None
def owner_of(a):
    r = rpc("getAccountInfo", [a, {"encoding":"base64"}])
    v = r.get("value") if isinstance(r, dict) else None
    return v["owner"] if v else None
def build_ix(program, data, accounts):
    return Instruction(program_id=pk(program), data=data,
        accounts=[AccountMeta(pubkey=pk(a), is_signer=s, is_writable=w) for a,s,w in accounts])
def simulate(instructions, fee_payer):
    msg = Message.new_with_blockhash(instructions, pk(fee_payer), Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    return rpc("simulateTransaction", [raw, {"encoding":"base64","sigVerify":False,
                                              "replaceRecentBlockhash":True,"commitment":"processed"}])
def fresh(seed): return str(Pubkey.from_bytes(hashlib.sha256(seed.encode()).digest()))
