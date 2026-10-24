#!/usr/bin/env python3
"""
Bytecode-level identity analysis of KolanHook vs LaunchHook (Ethereum mainnet).
Read-only: eth_getCode + local disassembly. No keys, public RPC only.

Method:
 1. Fetch runtime bytecode of the main KolanHook and of a launchpad LaunchHook.
 2. Locate the Solidity selector dispatcher entry for accept(uint256) (0x19b05f49):
    pattern PUSH4 0x19b05f49 (63 19b05f49) ; EQ (14) ; PUSH2 <dest> (61 xxxx) ; JUMPI (57).
 3. Extract the function body starting at <dest> (JUMPDEST) up to the next
    top-level dispatch target / end of body.
 4. Normalize: replace every PUSH32 (0x7f) 32-byte immediate that equals a known
    per-contract immutable (immutables are compiled inline as PUSH32) with a
    placeholder, and mask the immutable byte ranges, so the two bodies can be
    compared without per-instance constant noise.
 5. Report normalized body hash + a full-code common-subsequence/diff summary.
"""
import json, urllib.request, sys, hashlib, time

RPC = "https://ethereum-rpc.publicnode.com"
MAIN = "0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC"
LAUNCH0 = "0xc75059b9e101483ca3261ca3fdd65bf85a1528ec"   # hook[0], windowCount=1
LAUNCH1 = "0x02f6bc027e5bca0c733b08711e1378c13cdaa8ec"   # hook[1], windowCount=0
ACCEPT_SEL = bytes.fromhex("19b05f49")

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body,
                                 headers={"Content-Type": "application/json", "User-Agent": "zh4/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.load(r)
            if "result" in d:
                return d["result"]
            return {"__error__": d.get("error")}
        except Exception as e:
            time.sleep(1 + a)
    return {"__error__": "rpc-fail"}

def get_code(addr, block):
    c = rpc("eth_getCode", [addr, hex(block)])
    if not isinstance(c, str) or not c.startswith("0x"):
        raise RuntimeError(f"eth_getCode {addr} failed: {c}")
    return bytes.fromhex(c[2:])

def find_dispatch(code, sel):
    """Find PUSH4 sel ; EQ ; PUSH2 dest ; JUMPI. Return (dest, offsets)."""
    hits = []
    pat = bytes([0x63]) + sel
    i = 0
    while True:
        j = code.find(pat, i)
        if j < 0:
            break
        hits.append(j)
        i = j + 1
    out = []
    for j in hits:
        k = j + 5
        # optional DUP/SWAP noise then EQ
        seg = code[k:k + 12]
        if 0x14 in seg:  # EQ present shortly after
            e = k + seg.index(0x14)
            # PUSH2 dest right after EQ
            if code[e + 1] == 0x61:
                dest = (code[e + 2] << 8) | code[e + 3]
                if code[e + 4] == 0x57:  # JUMPI
                    out.append({"push4_at": j, "eq_at": e, "dest": dest})
    return out

def disasm_len(code, pc, maxins=400):
    """Walk instructions from pc until a terminal JUMP (0x56)/STOP/RETURN/Revert
    that returns to the dispatcher, or maxins. Returns end pc."""
    n = len(code)
    p = pc
    cnt = 0
    while p < n and cnt < maxins:
        op = code[p]
        if op == 0x7f:  # PUSH32
            p += 33
        elif 0x60 <= op <= 0x7f:
            p += op - 0x5f + 1
        else:
            p += 1
            if op in (0x56, 0x00, 0xf3, 0xfd):  # JUMP, STOP, RETURN, REVERT
                return p
        cnt += 1
    return p

def norm(body, imm32):
    """Replace 32-byte PUSH32 immediates that are known immutables with a tag."""
    out = bytearray(body)
    for off in range(len(out) - 32):
        if out[off] == 0x7f:
            val = bytes(out[off + 1:off + 33])
            for name, iv in imm32.items():
                if val == iv:
                    out[off + 1:off + 33] = b"\x00" * 32
    return bytes(out)

def imm_values(code):
    """Heuristically collect PUSH32 32-byte immediates (candidate immutables)."""
    vals = {}
    p = 0
    while p < len(code):
        op = code[p]
        if op == 0x7f:
            vals[code[p + 1:p + 33].hex()] = p
            p += 33
        elif 0x60 <= op <= 0x7f:
            p += op - 0x5f + 1
        else:
            p += 1
    return vals

def main():
    block = int(rpc("eth_blockNumber", []), 16)
    res = {"rpc": RPC, "block": block, "targets": {}}
    codes = {}
    for name, addr in [("main_KolanHook", MAIN), ("launch_hook0", LAUNCH0), ("launch_hook1", LAUNCH1)]:
        code = get_code(addr, block)
        codes[name] = code
        disp = find_dispatch(code, ACCEPT_SEL)
        entry = {"address": addr, "code_size": len(code),
                 "code_keccak": "0x" + hashlib.sha3_256(code).hexdigest() if False else None,
                 "accept_selector_present": ACCEPT_SEL in code,
                 "dispatch_hits": disp}
        if disp:
            d = disp[0]["dest"]
            body = code[d:disasm_len(code, d)]
            entry["accept_entry_pc"] = d
            entry["accept_body_len"] = len(body)
            entry["accept_body_sha256"] = "0x" + hashlib.sha256(body).hexdigest()
        res["targets"][name] = entry

    # normalize accept bodies using union of immutable-like PUSH32 values
    imm = {}
    for name, code in codes.items():
        for h, p in imm_values(code).items():
            imm[h] = bytes.fromhex(h)
    bodies = {}
    for name, code in codes.items():
        disp = res["targets"][name]["dispatch_hits"]
        if disp:
            d = disp[0]["dest"]
            body = code[d:disasm_len(code, d)]
            bodies[name] = body
            res["targets"][name]["accept_body_norm_sha256"] = \
                "0x" + hashlib.sha256(norm(body, imm)).hexdigest()
    res["immutable_like_push32_count"] = len(imm)
    print(json.dumps(res, indent=1))
    open("/home/heisenberg/CA/kolan-hooks/analysis/bytecode_compare.json", "w").write(json.dumps(res, indent=1))

if __name__ == "__main__":
    main()
