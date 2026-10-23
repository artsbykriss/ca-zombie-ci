#!/usr/bin/env python3
"""Loopscale/Exponent strategy-vaults — fresh-signer auth probe.
READ-ONLY: uses simulateTransaction with sigVerify=false + replaceRecentBlockhash.
No transaction is signed for broadcast and none is sent to the network.
"""
import base64, json, urllib.request, sys, time, struct
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.keypair import Keypair
from solders.signature import Signature

RPCS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
PROG = Pubkey.from_string("sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD")
EXP_ADMIN_PROG = Pubkey.from_string("3D6ojc8vBfDteLBDTTRznZbZRh7bkEGQaYqNkudoTCBQ")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
TOKEN22 = Pubkey.from_string("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb")
SYS = Pubkey.from_string("11111111111111111111111111111111")
VAULT = Pubkey.from_string(sys.argv[1] if len(sys.argv) > 1 else "EsTx9ToYW2k1DsTw6ccpmP3RrXQriod114hcM7U5ZKaR")

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for url in RPCS:
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, data=body,
                                             headers={"Content-Type": "application/json", "User-Agent": "research"})
                return json.load(urllib.request.urlopen(req, timeout=90))
            except Exception as e:
                last = e; time.sleep(1.5 * (attempt + 1))
    raise last

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58e(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0: n, r = divmod(n, 58); out = ALPH[r] + out
    return "1" * (len(b) - len(b.lstrip(b"\x00"))) + out

def pda(seed, prog=PROG):
    return Pubkey.find_program_address([seed.encode()], prog)[0]

EXPONENT_PRICES = pda("exponent_prices")
EVENT_AUTH = pda("__event_authority")
ADMIN_ACCOUNT = pda("admin", EXP_ADMIN_PROG)

class C:
    def __init__(s, d): s.d = d; s.o = 0
    def u8(s): v = s.d[s.o]; s.o += 1; return v
    def u16(s): v = struct.unpack_from("<H", s.d, s.o)[0]; s.o += 2; return v
    def u32(s): v = struct.unpack_from("<I", s.d, s.o)[0]; s.o += 4; return v
    def u64(s): v = struct.unpack_from("<Q", s.d, s.o)[0]; s.o += 8; return v
    def skip(s, n): s.o += n
    def pk(s): v = b58e(s.d[s.o:s.o+32]); s.o += 32; return v
    def vec(s, fn): return [fn() for _ in range(s.u32())]

def price_id(c):
    k = c.u8()
    if k == 0: c.skip(8)
    elif k == 1: c.skip(c.u32() * 8)
    else: raise ValueError("PriceId")

def strat_pos(c):
    k = c.u8()
    if k == 0: c.skip(32+4+32); c.skip(c.u32()*4); price_id(c); price_id(c); c.skip(32)
    elif k == 1: c.skip(32); c.vec(lambda: (c.skip(32), price_id(c), c.skip(8)))
    elif k == 2: c.skip(1); c.skip(32+32); price_id(c); c.vec(lambda: (c.skip(32), price_id(c))); c.skip(c.u32()*65); c.skip(1)
    elif k in (3,4): c.skip(32+32); price_id(c); price_id(c)
    elif k in (5,6,8): c.skip(32)
    elif k == 7: c.skip(32+32)
    elif k == 9: c.skip(32+8)
    return k

def decode_vault(data):
    c = C(data); c.o = 8
    c.skip(32+32+32)
    c.vec(lambda: (c.skip(32), price_id(c), c.skip(32+32+8), c.skip(c.u32()*8)))
    underlying = c.pk()
    mint_lp = c.pk(); token_lp_escrow = c.pk()
    cut = c.u16(); fee_treasury = c.pk(); self_addr = c.pk(); c.skip(1)
    status = c.u8()
    lp_balance = c.u64(); aum = c.u64() + c.u64()
    c.skip(72)
    positions = c.vec(lambda: strat_pos(c))
    c.skip(16)
    managers = c.vec(lambda: c.pk())
    curators = c.vec(lambda: c.pk())
    return dict(underlying=underlying, mint_lp=mint_lp, token_lp_escrow=token_lp_escrow,
                cut=cut, fee_treasury=fee_treasury, self_address=self_addr, status=status,
                lp_balance=lp_balance, aum=aum, positions=positions, managers=managers, curators=curators)

def simulate(name, ixs):
    msg = Message.new_with_blockhash(ixs, PAYER, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    res = rpc("simulateTransaction", [base64.b64encode(bytes(tx)).decode(),
             {"sigVerify": False, "replaceRecentBlockhash": True, "encoding": "base64", "commitment": "processed"}])
    v = res.get("result", {}).get("value", {})
    print(f"\n### {name}\n  err = {v.get('err')}")
    for l in (v.get("logs") or []):
        if "Error" in l or "failed:" in l:
            print("   ", l)

if __name__ == "__main__":
    fresh = Keypair()
    for cand in ["5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9", "1nc1nerator11111111111111111111111111111111"]:
        info = rpc("getAccountInfo", [cand, {"encoding": "base64"}])["result"]["value"]
        if info and info["owner"] == str(SYS) and info["lamports"] > 5000:
            PAYER = Pubkey.from_string(cand); break
    print("fresh signer:", fresh.pubkey(), "| unverified fee payer:", PAYER)
    print("exponentPrices:", EXPONENT_PRICES, "| eventAuthority:", EVENT_AUTH, "| adminAccount:", ADMIN_ACCOUNT)

    vinfo = rpc("getAccountInfo", [str(VAULT), {"encoding": "base64"}])["result"]["value"]
    v = decode_vault(base64.b64decode(vinfo["data"][0]))
    print("\nvault", VAULT, json.dumps({k: v[k] for k in ("underlying","mint_lp","token_lp_escrow","cut","status","lp_balance","aum","managers","curators")}, indent=1))

    # A) sentinelSetVaultFlags with a fresh signer in the sentinel role slot
    simulate("A) sentinelSetVaultFlags(fresh signer)", [Instruction(PROG, bytes([0x0a, 0x00, 0x01]), [
        AccountMeta(fresh.pubkey(), True, False), AccountMeta(VAULT, False, True),
        AccountMeta(ADMIN_ACCOUNT, False, False), AccountMeta(EVENT_AUTH, False, False),
        AccountMeta(PROG, False, False)])])

    # B) manageVaultSettings with a fresh signer in the manager role slot
    simulate("B) manageVaultSettings(fresh signer, [] actions)", [Instruction(PROG, bytes([0x16, 0, 0, 0, 0]), [
        AccountMeta(fresh.pubkey(), True, True), AccountMeta(VAULT, False, True),
        AccountMeta(EXPONENT_PRICES, False, True), AccountMeta(SYS, False, False)])])

    # C) executeWithdrawal with a fresh signer as owner (has no LP / no withdrawal account)
    from solders.pubkey import Pubkey as Pk
    ata, _ = Pk.find_program_address([bytes(fresh.pubkey()), bytes(TOKEN), bytes(Pk.from_string(v["mint_lp"]))],
                                     Pk.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"))
    wd = Pk.create_with_seed(fresh.pubkey(), "withdrawal", PROG)
    simulate("C) executeWithdrawal(fresh signer as owner)", [Instruction(PROG, bytes([0x06, 0x00]), [
        AccountMeta(VAULT, False, True), AccountMeta(EXPONENT_PRICES, False, False),
        AccountMeta(fresh.pubkey(), True, True), AccountMeta(wd, False, True),
        AccountMeta(ata, False, True), AccountMeta(Pk.from_string(v["token_lp_escrow"]), False, True),
        AccountMeta(Pk.from_string(v["mint_lp"]), False, True), AccountMeta(TOKEN, False, False),
        AccountMeta(TOKEN22, False, False), AccountMeta(EVENT_AUTH, False, False),
        AccountMeta(PROG, False, False)])])

    # D) depositLiquidity with a fresh signer (permissionless) — should be debited-only / no extraction
    simulate("D) depositLiquidity(fresh signer, 1 unit)", [Instruction(PROG, bytes([0x01]) + struct.pack("<QQ", 1, 0), [
        AccountMeta(fresh.pubkey(), True, True), AccountMeta(VAULT, False, True),
        AccountMeta(EXPONENT_PRICES, False, False), AccountMeta(Pk.from_string(v["underlying"]), False, False),
        AccountMeta(ata, False, True), AccountMeta(Pk.from_string(v["token_lp_escrow"]), False, True),
        AccountMeta(ata, False, True), AccountMeta(Pk.from_string(v["mint_lp"]), False, True),
        AccountMeta(TOKEN, False, False), AccountMeta(TOKEN22, False, False),
        AccountMeta(EVENT_AUTH, False, False), AccountMeta(PROG, False, False)])])

    # E) initializePrices (global singleton registry) with a fresh signer — takeover attempt (ADV-08/09)
    simulate("E) initializePrices(fresh signer)", [Instruction(PROG, bytes([0x18]), [
        AccountMeta(fresh.pubkey(), True, True), AccountMeta(ADMIN_ACCOUNT, False, False),
        AccountMeta(EXPONENT_PRICES, False, True), AccountMeta(SYS, False, False)])])

    # F) managePrices with a fresh signer (price-manager role)
    simulate("F) managePrices(fresh signer, [] actions)", [Instruction(PROG, bytes([0x19, 0, 0, 0, 0]), [
        AccountMeta(fresh.pubkey(), True, True), AccountMeta(ADMIN_ACCOUNT, False, False),
        AccountMeta(EXPONENT_PRICES, False, True), AccountMeta(SYS, False, False)])])

    # F2) managePrices with a non-empty action (RemovePrice priceId=1) as a fresh signer
    data = bytes([0x19, 1, 0, 0, 0, 1]) + struct.pack("<Q", 1)
    simulate("F2) managePrices(fresh signer, [RemovePrice])", [Instruction(PROG, data, [
        AccountMeta(fresh.pubkey(), True, True), AccountMeta(ADMIN_ACCOUNT, False, False),
        AccountMeta(EXPONENT_PRICES, False, True), AccountMeta(SYS, False, False)])])
