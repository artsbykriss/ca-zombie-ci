#!/usr/bin/env python3
"""Read-only Solana JSON-RPC helper (keyless public endpoints, no secrets).

Used by the Project 0 / marginfi-v2 residual deep-dive.
Only read methods: getAccountInfo, getProgramAccounts, getSignaturesForAddress,
getTransaction, getSlot, simulateTransaction(sigVerify=false).
"""
import json, sys, time, urllib.request, urllib.error

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]
_state = {"i": 0}

def _post(endpoint, payload, timeout=45):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(endpoint, data=data,
        headers={"Content-Type": "application/json", "User-Agent": "audit-readonly/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(method, params=None, retries=4, endpoints=None):
    eps = endpoints or ENDPOINTS
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params or []}
    last = None
    for attempt in range(retries):
        for ep in eps:
            try:
                out = _post(ep, payload)
                return out
            except urllib.error.HTTPError as e:
                last = f"HTTP {e.code} on {ep}"
                if e.code == 429:
                    time.sleep(2); continue
            except Exception as e:
                last = f"{type(e).__name__}: {e} on {ep}"
        time.sleep(1.5)
    raise RuntimeError(f"rpc failed {method}: {last}")

def result(method, params=None, **kw):
    out = rpc(method, params, **kw)
    if isinstance(out, dict) and out.get("error"):
        return out
    return out.get("result")

def get_account_info(pubkey, encoding="base64"):
    r = result("getAccountInfo", [pubkey, {"encoding": encoding, "commitment": "confirmed"}])
    if isinstance(r, dict) and "value" in r:
        return r["value"]
    return r

def get_multiple(keys, encoding="base64"):
    r = result("getMultipleAccounts", [keys, {"encoding": encoding, "commitment": "confirmed"}])
    if isinstance(r, dict) and "value" in r:
        return r["value"]
    return r

def get_program_accounts(program_id, filters=None, encoding="base64", dataSlice=None, extra=None):
    cfg = {"encoding": encoding, "commitment": "confirmed"}
    if filters: cfg["filters"] = filters
    if dataSlice: cfg["dataSlice"] = dataSlice
    if extra: cfg.update(extra)
    return result("getProgramAccounts", [program_id, cfg])

def get_signatures(address, limit=100, before=None, until=None):
    opts = {"limit": limit}
    if before: opts["before"] = before
    if until: opts["until"] = until
    best = None
    for ep in ENDPOINTS:
        try:
            out = _post(ep, {"jsonrpc":"2.0","id":1,"method":"getSignaturesForAddress",
                             "params":[address, opts]})
            res = out.get("result")
            if res is not None and (best is None or len(res) > len(best.get("result") or [])):
                best = out
        except Exception:
            continue
    return best or {"result": []}

def get_transaction(sig, encoding="jsonParsed"):
    for ep in ENDPOINTS:
        try:
            out = _post(ep, {"jsonrpc":"2.0","id":1,"method":"getTransaction",
                             "params":[sig, {"encoding": encoding,
                                             "maxSupportedTransactionVersion": 0,
                                             "commitment": "confirmed"}]})
            if out.get("result"):
                return out
        except Exception:
            continue
    return {"result": None}

def get_slot():
    return result("getSlot", [{"commitment": "confirmed"}])

def simulate(tx_b64, sig_verify=False, replace_blockhash=True):
    cfg = {"encoding": "base64", "sigVerify": sig_verify,
           "replaceRecentBlockhash": replace_blockhash, "commitment": "confirmed"}
    return result("simulateTransaction", [tx_b64, cfg])

# ---- base58 ----
_A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58dec(s):
    n = 0
    for c in s:
        n = n * 58 + _A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for c in s:
        if c == "1": pad += 1
        else: break
    return b"\x00" * pad + b

def b58enc(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n > 0:
        n, r = divmod(n, 58)
        s = _A[r] + s
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (s or "")

# ---- PDA ----
def _sha256(data):
    import hashlib
    return hashlib.sha256(data).digest()

_ED25519_P = 2**255 - 19
_ED25519_D = (-121665 * pow(121666, _ED25519_P - 2, _ED25519_P)) % _ED25519_P
_I = pow(2, (_ED25519_P - 1) // 4, _ED25519_P)

def _recover_x(y, sign):
    xx = (y*y - 1) * pow(_ED25519_D*y*y + 1, _ED25519_P - 2, _ED25519_P)
    x = pow(xx, (_ED25519_P + 3) // 8, _ED25519_P)
    if (x*x - xx) % _ED25519_P != 0:
        x = (x * _I) % _ED25519_P
    if (x*x - xx) % _ED25519_P != 0:
        return None
    if x % 2 != sign:
        x = _ED25519_P - x
    return x

_B = (15112221349535400772501151409588531511454012693041857206046113283949847762202,
      46316835694926478169428394003475163141307993866256225615783033603165251855960)

def _edwards_add(P, Q):
    x1, y1 = P; x2, y2 = Q
    x3 = (x1*y2 + x2*y1) * pow(1 + _ED25519_D*x1*x2*y1*y2, _ED25519_P - 2, _ED25519_P) % _ED25519_P
    y3 = (y1*y2 + x1*x2) * pow(1 - _ED25519_D*x1*x2*y1*y2, _ED25519_P - 2, _ED25519_P) % _ED25519_P
    return (x3, y3)

def _edwards_mul(P, e):
    R = (0, 1)
    while e > 0:
        if e & 1: R = _edwards_add(R, P)
        P = _edwards_add(P, P)
        e >>= 1
    return R

def _is_on_curve(pk):
    if len(pk) != 32: return False
    y = int.from_bytes(pk, "little") & ((1 << 255) - 1)
    if y >= _ED25519_P: return False
    sign = pk[31] >> 7
    return _recover_x(y, sign) is not None

def find_program_address(seeds, program_id):
    pid = b58dec(program_id)
    for bump in range(255, -1, -1):
        h = _sha256(b"".join(seeds) + bytes([bump]) + pid + b"ProgramDerivedAddress")
        if not _is_on_curve(h):
            return b58enc(h), bump
    raise RuntimeError("no PDA")

def create_program_address(seeds, program_id):
    pid = b58dec(program_id)
    h = _sha256(b"".join(seeds) + pid + b"ProgramDerivedAddress")
    return b58enc(h)

def is_on_curve_b58(pk):
    return _is_on_curve(b58dec(pk))

# ---- upgrade authority ----
def upgrade_authority(prog):
    v = get_account_info(prog)
    if not v: return None
    raw = __import__("base64").b64decode(v["data"][0])
    progdata = b58enc(raw[4:36]) if len(raw) >= 36 else None
    auth = None; slot = None; size = v.get("space")
    if progdata:
        pv = get_account_info(progdata)
        if pv:
            praw = __import__("base64").b64decode(pv["data"][0])
            slot = int.from_bytes(praw[4:12], "little")
            opt = praw[12]
            auth = b58enc(praw[13:45]) if opt == 1 else "NONE (immutable)"
    return {"programdata": progdata, "upgrade_authority": auth,
            "last_deploy_slot": slot, "elf_size": size, "owner": v.get("owner")}

if __name__ == "__main__":
    for a in sys.argv[1:]:
        print(a, json.dumps(upgrade_authority(a)))
