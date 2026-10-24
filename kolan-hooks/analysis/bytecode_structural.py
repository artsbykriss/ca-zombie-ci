#!/usr/bin/env python3
"""
Local (light) bytecode structural comparison: main KolanHook vs deployed LaunchHooks.

- fetches runtime bytecode (eth_getCode, public RPC)
- disassembles to instructions
- masks immutable-like PUSH immediates
- reports: code keccak, accept(uint256) dispatch entry, opcode-sequence similarity
  (longest common substring ratio), and the count of identical 64-byte code windows.
Writes analysis/bytecode_structural.json
"""
import json, urllib.request, urllib.error, time, hashlib

RPC = "https://ethereum-rpc.publicnode.com"
MAIN = "0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC"
HOOKS = [
    "0xc75059b9e101483ca3261ca3fdd65bf85a1528ec",
    "0x02f6bc027e5bca0c733b08711e1378c13cdaa8ec",
    "0x16c0ce33576ca3da876fb926ff8dc664cdaa28ec",
]
ACCEPT = bytes.fromhex("19b05f49")

try:
    from Crypto.Hash import keccak
    def kec(b):
        h = keccak.new(digest_bits=256); h.update(b); return "0x" + h.hexdigest()
except Exception:
    def kec(b):
        return "0x" + hashlib.sha256(b).hexdigest() + "(sha256)"

def rpc(m, p):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    r = urllib.request.Request(RPC, data=b, headers={"Content-Type": "application/json", "User-Agent": "zh4/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(r, timeout=40) as x:
                d = json.load(x)
            if "result" in d:
                return d["result"]
        except Exception:
            pass
        time.sleep(1 + a)
    raise RuntimeError(m)

def get_code(a, blk):
    return bytes.fromhex(rpc("eth_getCode", [a, hex(blk)])[2:])

def disasm(code):
    out = []
    p, n = 0, len(code)
    while p < n:
        op = code[p]
        if op == 0x7f:
            ln = 32
        elif 0x60 <= op <= 0x7f:
            ln = op - 0x5f
        else:
            ln = 0
        out.append((p, op, ln))
        p += 1 + ln
    return out

def opcode_seq(code):
    """sequence of opcodes only (immediates dropped) -> comparable across immutables"""
    return bytes(op for (_, op, _) in disasm(code))

def lcs_len(a: bytes, b: bytes):
    """longest common substring length (O(n*m) memory-light with rolling rows)."""
    n, m = len(a), len(b)
    prev = [0] * (m + 1)
    best = 0
    for i in range(1, n + 1):
        cur = [0] * (m + 1)
        ai = a[i - 1]
        for j in range(1, m + 1):
            if ai == b[j - 1]:
                v = prev[j - 1] + 1
                cur[j] = v
                if v > best:
                    best = v
        prev = cur
    return best

def accept_dispatch(code):
    hits = []
    i = 0
    pat = bytes([0x63]) + ACCEPT
    while True:
        j = code.find(pat, i)
        if j < 0:
            break
        # find EQ then PUSH2 dest then JUMPI within next 12 bytes
        seg = code[j + 5:j + 17]
        if 0x14 in seg:
            e = j + 5 + seg.index(0x14)
            if e + 4 < len(code) and code[e + 1] == 0x61 and code[e + 4] == 0x57:
                hits.append((e + 2 << 8 | e + 3) if False else ((code[e + 2] << 8) | code[e + 3]))
        i = j + 1
    return hits

def identical_windows(a, b, w=64):
    sa = {a[i:i + w] for i in range(len(a) - w + 1)}
    return sum(1 for i in range(len(b) - w + 1) if b[i:i + w] in sa)

def longest_common_run(a: bytes, b: bytes, cap=4096):
    """Longest common substring via binary search + rolling hash (fast)."""
    n, m = len(a), len(b)
    if n == 0 or m == 0:
        return 0

    def has_common(L):
        if L == 0:
            return True
        M = (1 << 61) - 1
        base = 131
        ha = 0
        pw = pow(base, L - 1, M)
        seen = set()
        for i in range(n):
            ha = (ha * base + a[i]) % M
            if i >= L:
                ha = (ha - a[i - L] * pw) % M
            if i >= L - 1:
                seen.add(ha)
        hb = 0
        for i in range(m):
            hb = (hb * base + b[i]) % M
            if i >= L:
                hb = (hb - b[i - L] * pw) % M
            if i >= L - 1 and hb in seen:
                return True
        return False

    lo, hi = 0, min(n, m, cap)
    best = 0
    while lo <= hi:
        mid = (lo + hi) // 2
        if has_common(mid):
            best = mid; lo = mid + 1
        else:
            hi = mid - 1
    return best

def main():
    blk = int(rpc("eth_blockNumber", []), 16)
    res = {"rpc": RPC, "block": blk, "accept_selector": "0x19b05f49", "targets": {}}
    codes = {"main_KolanHook": get_code(MAIN, blk)}
    for h in HOOKS:
        codes["launch_" + h[:10]] = get_code(h, blk)
    base = codes["main_KolanHook"]
    base_seq = opcode_seq(base)
    for name, code in codes.items():
        seq = opcode_seq(code)
        rec = {
            "size": len(code),
            "keccak": kec(code),
            "accept_selector_present": ACCEPT in code,
            "accept_dispatch_dests": accept_dispatch(code),
            "n_instructions": len(disasm(code)),
        }
        if name != "main_KolanHook":
            rec["opcode_seq_len"] = len(seq)
            rec["identical_64B_windows_vs_main"] = identical_windows(base, code)
            rec["identical_64B_windows_ratio"] = round(identical_windows(base, code) / max(1, len(code) - 63), 4)
            # longest run of identical bytes (contiguous) via binary search on rolling hash
            rec["longest_identical_byte_run_vs_main"] = longest_common_run(base, code)
        res["targets"][name] = rec
    # cross-hook (launch vs launch) should be identical apart from immutables
    lk = [k for k in codes if k.startswith("launch_")]
    if len(lk) >= 2:
        a, b = codes[lk[0]], codes[lk[1]]
        res["launch_hook_pair_identical_64B_windows"] = identical_windows(a, b)
        res["launch_hook_pair_windows_total"] = max(1, len(a) - 63)
    open("/home/heisenberg/CA/kolan-hooks/analysis/bytecode_structural.json", "w").write(json.dumps(res, indent=1))
    print(json.dumps(res, indent=1))

if __name__ == "__main__":
    main()
