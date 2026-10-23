#!/usr/bin/env python3
"""Per-chain live-state probe for the legacy Rabby Swap router family.

For every (chain, router) in analysis/chains.json, read the deployed runtime code
(size + keccak256 hash) and call the known getters paused()/owner()/feeRatio().
Also reads the router's native balance. Records which chains are dead / RPC-less.

Read-only. RPC URLs come from env vars only; never written to disk.
"""
import json, os, sys, hashlib, urllib.request

SEL_PAUSED = "5c975abb"
SEL_OWNER = "8da5cb5b"
SEL_FEERATIO = "41744dd4"


def rpc(url, method, params, timeout=60):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def try_call(url, to, data):
    """Return the raw JSON-RPC response dict, or None if the HTTP request failed."""
    try:
        return rpc(url, "eth_call", [{"to": to, "data": data}, "latest"])
    except Exception:
        return None


def call_result(resp):
    """Extract a hex result from a raw response, or None (revert/error)."""
    if not isinstance(resp, dict):
        return None
    return resp.get("result")


def decode_addr(hexstr):
    if not hexstr or len(hexstr) < 42:
        return None
    a = "0x" + hexstr[-40:]
    if a == "0x" + "0" * 40:
        return None
    return a


def probe(chain):
    name = chain["name"]
    router = chain["router"]
    rpcs = [os.environ.get(e, "") for e in chain.get("rpc_env", [])] + chain.get("rpc_default", [])
    rec = {"chain": name, "chainId": chain["chainId"], "router": router}
    last_err = None
    for url in rpcs:
        if not url:
            continue
        try:
            code = rpc(url, "eth_getCode", [router, "latest"]).get("result", "0x")
            # some RPCs whitelist methods; require eth_call to be served at all
            paused_resp = try_call(url, router, "0x" + SEL_PAUSED)
            if paused_resp is None:
                raise RuntimeError("eth_call not available on this rpc")
            if not code or code == "0x":
                rec.update({"rpc_ok": True, "has_code": False, "code_size": 0})
                return rec
            raw = bytes.fromhex(code[2:])
            rec.update({
                "rpc_ok": True,
                "has_code": True,
                "code_size": len(raw),
            })
            rec["code_keccak"] = keccak256_hex(raw)
            rec["paused"] = call_result(paused_resp)
            rec["owner"] = decode_addr(call_result(try_call(url, router, "0x" + SEL_OWNER)))
            rec["feeRatio"] = call_result(try_call(url, router, "0x" + SEL_FEERATIO))
            try:
                rec["native_balance_wei"] = int(rpc(url, "eth_getBalance", [router, "latest"]).get("result", "0x0"), 16)
            except Exception:
                rec["native_balance_wei"] = None
            return rec
        except Exception as e:
            last_err = str(e)
    rec.update({"rpc_ok": False, "error": last_err})
    return rec


# --- minimal keccak-256 (Ethereum) -------------------------------------------
def _rotl64(x, n):
    return ((x << n) | (x >> (64 - n))) & 0xFFFFFFFFFFFFFFFF


_KECCAK_RC = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
    0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
]
_KECCAK_R = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]


def _keccak_f(state):
    for rnd in range(24):
        c = [state[x][0] ^ state[x][1] ^ state[x][2] ^ state[x][3] ^ state[x][4] for x in range(5)]
        d = [c[(x - 1) % 5] ^ _rotl64(c[(x + 1) % 5], 1) for x in range(5)]
        for x in range(5):
            for y in range(5):
                state[x][y] ^= d[x]
        b = [[0] * 5 for _ in range(5)]
        for x in range(5):
            for y in range(5):
                b[y][(2 * x + 3 * y) % 5] = _rotl64(state[x][y], _KECCAK_R[x][y])
        for x in range(5):
            for y in range(5):
                state[x][y] = b[x][y] ^ ((~b[(x + 1) % 5][y]) & b[(x + 2) % 5][y])
        state[0][0] ^= _KECCAK_RC[rnd]
    return state


def keccak256(data: bytes) -> bytes:
    rate = 136
    state = [[0] * 5 for _ in range(5)]
    msg = bytearray(data)
    msg.append(0x01)
    while len(msg) % rate != 0:
        msg.append(0x00)
    msg[-1] ^= 0x80
    for off in range(0, len(msg), rate):
        block = msg[off:off + rate]
        for i in range(rate // 8):
            lane = int.from_bytes(block[i * 8:i * 8 + 8], "little")
            state[i % 5][i // 5] ^= lane
        state = _keccak_f(state)
    out = bytearray()
    for i in range(4):
        out += state[i % 5][i // 5].to_bytes(8, "little")
    return bytes(out)


def keccak256_hex(data: bytes) -> str:
    return "0x" + keccak256(data).hex()


if __name__ == "__main__":
    cfg = json.load(open(sys.argv[1]))
    outdir = sys.argv[2] if len(sys.argv) > 2 else "analysis/raw"
    os.makedirs(outdir, exist_ok=True)
    all_recs = []
    for c in cfg:
        rec = probe(c)
        all_recs.append(rec)
        print(f"[{rec['chain']}] {json.dumps(rec)}", flush=True)
    with open(os.path.join(outdir, "live_state_all.json"), "w") as f:
        json.dump(all_recs, f, indent=1)
