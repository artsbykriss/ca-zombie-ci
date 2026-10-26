"""Build & simulate attacker messages against the Oro core program (read-only).
simulateTransaction with sigVerify:false + replaceRecentBlockhash:true.
Nothing is signed or sent.

Account layout is the INSTRUCTION account order recovered from the real Sell tx
3nq25Ab8H92cZWZpvNtBo5yACpkwdppaPVFJLN1HvijorMtinQS6SrBTJHsRaE1kjUYcpZ1A7vY1BgagBmVpZKqv (slot 441901540).
"""
import sys, json, base64
sys.path.insert(0, '.')
import rpc2
from solders.pubkey import Pubkey
from solders.hash import Hash
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import VersionedTransaction
from solders.signature import Signature

PID = Pubkey.from_string("iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop")

# (name, is_signer, is_writable)
SELL = [
    ("seller",         True,  True),
    ("mint_a",         False, False),   # GOLD mint
    ("mint_b",         False, False),   # USDC mint
    ("seller_ata_a",   False, True),    # seller GOLD ATA
    ("seller_ata_b",   False, True),    # seller USDC ATA
    ("authority",      False, True),    # == seller (duplicate)
    ("whitelist",      False, False),   # whitelist PDA of seller
    ("price_account",  False, True),    # Price PDA / mint authority
    ("pyth_price",     False, False),   # PriceUpdateV2
    ("vault_a",        False, True),    # GOLD vault
    ("vault_b",        False, True),    # USDC vault
    ("integrator",     False, False),   # IntegratorV2
    ("integrator_ata", False, True),    # USDC ata owned by integrator
    ("ata_program",    False, False),
    ("token_program",  False, False),
    ("system_program", False, False),
]
SELL_DEFAULT = {
    "seller":         "22PtRWdqEfo68WRtE11isZcxVVifYjTSVdsWoyYB8Tnk",
    "mint_a":         "GoLDppdjB1vDTPSGxyMJFqdnj134yH6Prg9eqsGDiw6A",
    "mint_b":         "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "seller_ata_a":   "A6tUMqAtyhHg3vgCkY77UCqywmexbuDKACSq21FH8NgD",
    "seller_ata_b":   "RHprvisJEt9aYzQcnbH7unxpcAtBZHKbBsTbLErpTQc",
    "authority":      "22PtRWdqEfo68WRtE11isZcxVVifYjTSVdsWoyYB8Tnk",
    "whitelist":      "CUVdjuDifxq1Ynh1MF1JFjZfAmYMMejVoXN3b5whf3Ng",
    "price_account":  "HKMT2i4kGzktb4AVo4fKkHK4AmpxVyvGEAfotVX3tML4",
    "pyth_price":     "2uPQGpm8X4ZkxMHxrAW1QuhXcse1AHEgPih6Xp9NuEWW",
    "vault_a":        "BTfWpVQahbeUyhtwN7ATFjmBdv1wfdVPR5K6oYAnWHrx",
    "vault_b":        "Gy2cgMANTP4HuS9XrogE6jheenETY4Mo3mb2PreraxaY",
    "integrator":     "EviXeqoPLpyP5iusYyAotjjc3QVNnfcySPH732KVrzT3",
    "integrator_ata": "EmukLyLZvSzU8ruiN5jZnKSKnME6kydo65mqjR7duL3z",
    "ata_program":    "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
    "token_program":  "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
    "system_program": "11111111111111111111111111111111",
}
# real sell instruction data: disc + u128 amount + u128 min_amount_out
SELL_DATA = bytes.fromhex("33e685a4017f83ad"
                          "d9000000000000000000000000000000"
                          "aaca0e00000000000000000000000000")


def build(order, vals, data):
    metas = [AccountMeta(Pubkey.from_string(vals[n]), s, w) for n, s, w in order]
    ix = Instruction(PID, data, metas)
    payer = Pubkey.from_string(vals[order[0][0]])
    msg = Message.new_with_blockhash([ix], payer, Hash.default())
    tx = VersionedTransaction.populate(
        msg, [Signature.default()] * msg.header.num_required_signatures)
    return base64.b64encode(bytes(tx)).decode()


def simulate(b64, accounts=None):
    cfg = {"encoding": "base64", "sigVerify": False,
           "replaceRecentBlockhash": True, "commitment": "processed"}
    if accounts:
        cfg["accounts"] = accounts
    return rpc2.call("simulateTransaction", [b64, cfg])


def show(res, label=""):
    v = res["value"]
    print("== %s\n   err=%s units=%s" % (label, v.get("err"), v.get("unitsConsumed")))
    for l in (v.get("logs") or []):
        print("    ", l)
    return v


if __name__ == "__main__":
    vals = dict(SELL_DEFAULT)
    for kv in sys.argv[1:]:
        k, v = kv.split("=", 1)
        vals[k] = v
    diff = {k: v for k, v in vals.items() if v != SELL_DEFAULT.get(k)}
    b = build(SELL, vals, SELL_DATA)
    show(simulate(b), "sell " + json.dumps(diff))
