#!/usr/bin/env python3
"""Read-only Solana simulateTransaction harness for the Solstice eUSX YieldVault.

Builds UNSIGNED legacy transactions (sigVerify:false, replaceRecentBlockhash:true) and
submits them to simulateTransaction. No transaction is ever signed or sent.
Keyed RPC URLs are read from env SOLANA_RPC only; never written to disk.
"""
import sys, json, time, struct, hashlib, base64, urllib.request, os

URL = os.environ.get("SOLANA_RPC", "https://api.mainnet-beta.solana.com")
URLS = [u for u in URL.split(",") if u]
ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def rpc(method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        for url in URLS:
            try:
                req = urllib.request.Request(url, data=body,
                      headers={"Content-Type": "application/json", "User-Agent": "research"})
                return json.load(urllib.request.urlopen(req, timeout=60))
            except Exception as e:
                last = e
        time.sleep(1.5 * (i + 1))
    raise last

def b58dec(s):
    n = 0
    for c in s:
        n = n * 58 + ALPH.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, 'big')
    pad = len(s) - len(s.lstrip('1'))
    return b'\x00' * pad + b

def b58enc(b):
    n = int.from_bytes(b, 'big'); s = ''
    while n:
        n, r = divmod(n, 58); s = ALPH[r] + s
    for c in b:
        if c == 0: s = '1' + s
        else: break
    return s or '1'

def disc(name):
    return hashlib.sha256(("global:%s" % name).encode()).digest()[:8]

def evdisc(name):
    return hashlib.sha256(("event:%s" % name).encode()).digest()[:8]

def u64le(n): return struct.pack('<Q', n)

# ---- fixed addresses ----
PROGRAM   = "eUSXyKoZ6aGejYVbnp3wtWQ1E8zuokLAJPecPxxtgG3"
CONTROLLER= "2aHdm37djj4c21ztMRBmmo4my6RtzN5Nn58Y39rpWbRM"
VESTING   = "FCA4A8W8qzcXGDyBaQ8fiSqr2VowSihiz2bJKN9LcLwb"
YIELDPOOL = "2rjmJdxZeBLKjUjKjrSdtSqshgXbLEcPbjiJZ2vLNcCT"
ASSETVAULT= "2SGicAhchh23nsrtWrur7zPAdb4hHtnyThQVPfza8CHA"
SHARE_MINT= "3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC"
ASSET_MINT= "6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG"
TOKEN     = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
SYSTEM    = "11111111111111111111111111111111"

def pda(seeds, program=PROGRAM):
    for bump in range(255, -1, -1):
        h = hashlib.sha256(bytes(seeds) + bytes([bump]) + b58dec(program) + b"ProgramDerivedAddress").digest()
        # on-curve check via ed25519 decompression is non-trivial; for our PDAs the first bump found is correct
        return b58enc(h), bump
    return None

def find_pda(seeds, program=PROGRAM):
    # proper ed25519 off-curve check
    p = b58dec(program)
    for bump in range(255, -1, -1):
        h = hashlib.sha256(b"".join(seeds) + bytes([bump]) + p + b"ProgramDerivedAddress").digest()
        if not on_curve(h):
            return b58enc(h), bump
    return None, None

# ed25519 point on-curve check
_p = 2**255 - 19
_d = (-121665 * pow(121666, _p - 2, _p)) % _p
_I = pow(2, (_p - 1) // 4, _p)

def _xrecover(y):
    xx = (y * y - 1) * pow(_d * y * y + 1, _p - 2, _p)
    x = pow(xx, (_p + 3) // 8, _p)
    if (x * x - xx) % _p != 0:
        x = (x * _I) % _p
    if x % 2 != 0:
        x = _p - x
    return x

def on_curve(b):
    if len(b) != 32:
        return False
    y = int.from_bytes(b, 'little') & ((1 << 255) - 1)
    if y >= _p:
        return False
    xx = (y * y - 1) * pow(_d * y * y + 1, _p - 2, _p)
    x = pow(xx, (_p + 3) // 8, _p)
    if (x * x - xx) % _p != 0:
        x = (x * _I) % _p
    return (x * x - xx) % _p == 0

class Account:
    __slots__ = ("pubkey", "signer", "writable")
    def __init__(self, pubkey, signer=False, writable=False):
        self.pubkey = pubkey; self.signer = signer; self.writable = writable

def compile_message(ixs, blockhash):
    """ixs: list of (program_id_str, [Account,...], data_bytes). Returns base64 legacy message."""
    order = []
    idx = {}
    def add(a):
        if a.pubkey in idx:
            e = order[idx[a.pubkey]]
            e.signer = e.signer or a.signer
            e.writable = e.writable or a.writable
        else:
            idx[a.pubkey] = len(order); order.append(a)
    # program ids are readonly non-signers
    for pid, accts, data in ixs:
        for a in accts: add(a)
        add(Account(pid))
    # sort: signers-writable, signers-readonly, non-signer-writable, non-signer-readonly
    def key(a):
        if a.signer and a.writable: return 0
        if a.signer: return 1
        if a.writable: return 2
        return 3
    order.sort(key=key)
    idx = {a.pubkey: i for i, a in enumerate(order)}
    nsig = sum(1 for a in order if a.signer)
    nros = sum(1 for a in order if a.signer and not a.writable)
    nrou = sum(1 for a in order if not a.signer and not a.writable)
    header = bytes([nsig, nros, nrou])
    keys = b"".join(b58dec(a.pubkey) for a in order)
    bh = b58dec(blockhash)
    msg = header + bytes([len(order)]) + keys + bh + bytes([len(ixs)])
    for pid, accts, data in ixs:
        msg += bytes([idx[pid]])
        msg += bytes([len(accts)])
        msg += bytes(idx[a.pubkey] for a in accts)
        msg += bytes([len(data)]) + data
    # wrap as a legacy Transaction: shortvec(nsig) + nsig*64 zero signatures + message
    tx = bytes([nsig]) + b"\x00" * (64 * nsig) + msg
    return base64.b64encode(tx).decode()

def simulate(ixs, ret_accounts, blockhash=None):
    if blockhash is None:
        blockhash = b58enc(b58dec(rpc("getLatestBlockhash", [{"commitment": "processed"}])["result"]["value"]["blockhash"]))
    msg = compile_message(ixs, blockhash)
    cfg = {"encoding": "base64", "sigVerify": False, "replaceRecentBlockhash": True,
           "commitment": "processed", "innerInstructions": True}
    if ret_accounts:
        cfg["accounts"] = {"encoding": "base64", "addresses": ret_accounts}
    res = rpc("simulateTransaction", [msg, cfg])
    if "result" in res and isinstance(res["result"], dict) and "value" in res["result"]:
        return res["result"]["value"]
    return res

def parse_events(logs):
    out = []
    for lg in logs or []:
        if lg.startswith("Program data: "):
            try:
                raw = base64.b64decode(lg[len("Program data: "):])
            except Exception:
                continue
            out.append(raw)
    return out

EV = {"LockEvent": evdisc("LockEvent"), "UnlockEvent": evdisc("UnlockEvent"),
      "WithdrawEvent": evdisc("WithdrawEvent"), "TransferInYieldEvent": evdisc("TransferInYieldEvent"),
      "InitializeYieldPoolEvent": evdisc("InitializeYieldPoolEvent")}

def decode_event(raw):
    for name, d in EV.items():
        if raw[:8] == d:
            return name, raw[8:]
    return "unknown:%s" % raw[:8].hex(), raw[8:]
