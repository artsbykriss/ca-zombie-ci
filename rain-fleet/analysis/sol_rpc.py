#!/usr/bin/env python3
"""Read-only Solana RPC helper. NEVER prints RPC URLs (keys are env-only)."""
import json, os, sys, time, urllib.request

def _rpc_urls():
    urls = []
    for k in ("SOLANA_RPC_URL", "ALCHEMY_SOLANA_RPC_URL"):
        v = os.environ.get(k)
        if v:
            urls.append(v)
    # keyless public endpoints (safe to log)
    urls += [
        "https://api.mainnet-beta.solana.com",
        "https://solana-rpc.publicnode.com",
        "https://api.mainnet-beta.solana.com",
    ]
    return urls

_URLS = _rpc_urls()
_IDX = 0

def rpc(method, params, retries=6):
    global _IDX
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        url = _URLS[_IDX % len(_URLS)]
        try:
            req = urllib.request.Request(url, data=payload, headers={
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (research; read-only)"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read().decode())
            if "error" in out:
                last = out["error"]
                if out["error"].get("code") == -32602:  # bad params -> don't retry
                    raise RuntimeError(out["error"])
                _IDX += 1
                time.sleep(1.5 * (attempt + 1))
                continue
            return out["result"]
        except Exception as e:  # noqa
            last = str(e)
            _IDX += 1
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"RPC failed after {retries}: {last}")

def b58decode(s):
    A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = 0
    for c in s:
        n = n * 58 + A.index(c)
    pad = len(s) - len(s.lstrip("1"))
    b = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    return b"\x00" * pad + b

def b58encode(b):
    A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big")
    out = ""
    while n:
        n, r = divmod(n, 58)
        out = A[r] + out
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + (out or "")

BPF_UPGRADEABLE = "BPFLoaderUpgradeab1e11111111111111111111111"

def program_data_addr(program_id: str) -> str:
    prog = b58decode(program_id)
    pda, _ = find_pda([prog], BPF_UPGRADEABLE)
    return pda

def find_pda(seeds, program_id: str):
    """Standard Solana PDA (find_program_address): bump 255..0, on-curve check (dalek semantics)."""
    import hashlib
    p = 2**255 - 19
    d = (-121665 * pow(121666, p-2, p)) % p
    def on_curve(b):
        y = int.from_bytes(b, "little") & ((1 << 255) - 1)
        if y >= p:
            return False
        y2 = (y*y) % p
        x2 = (((y2 - 1) % p) * pow((d*y2 + 1) % p, p-2, p)) % p
        if x2 == 0:
            return True
        return pow(x2, (p-1)//2, p) == 1
    for bump in range(255, -1, -1):
        data = b"".join(seeds) + bytes([bump]) + b58decode(program_id) + b"ProgramDerivedAddress"
        h = hashlib.sha256(data).digest()
        if not on_curve(h):
            return b58encode(h), bump
    return None, None

def get_account(addr: str, encoding="base64"):
    return rpc("getAccountInfo", [addr, {"encoding": encoding}])

def parse_program_account(data_b64: str):
    import base64
    raw = base64.b64decode(data_b64)
    variant = int.from_bytes(raw[:4], "little")
    if variant == 2 and len(raw) >= 36:
        return {"variant": 2, "programdata": b58encode(raw[4:36])}
    return {"variant": variant, "raw_len": len(raw)}

def parse_programdata_account(data_b64: str):
    import base64
    raw = base64.b64decode(data_b64)
    variant = int.from_bytes(raw[:4], "little")
    slot = int.from_bytes(raw[4:12], "little")   # bincode: variant u32 @0, slot u64 @4
    tag = raw[12]
    auth = b58encode(raw[13:45]) if tag == 1 and len(raw) >= 45 else None
    return {"variant": variant, "last_deploy_slot": slot, "authority": auth, "len": len(raw)}

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "prog":
        for pid in sys.argv[2:]:
            a = get_account(pid)
            if not a or not a.get("value"):
                print(pid, "NOT FOUND")
                continue
            v = a["value"]
            info = {"owner": v["owner"], "executable": v["executable"], "lamports": v["lamports"], "data_len": len(v["data"][0])}
            if v["owner"] == BPF_UPGRADEABLE:
                info.update(parse_program_account(v["data"][0]))
                if "programdata" in info:
                    pd = get_account(info["programdata"])
                    if pd and pd.get("value"):
                        info["programdata_info"] = parse_programdata_account(pd["value"]["data"][0])
            print(json.dumps({pid: info}, indent=1))
    elif cmd == "slot":
        print(rpc("getSlot", [{"commitment": "finalized"}]))
    elif cmd == "sig":
        print(json.dumps(rpc("getSignaturesForAddress", [sys.argv[2], {"limit": int(sys.argv[3]) if len(sys.argv) > 3 else 10}]), indent=1))
