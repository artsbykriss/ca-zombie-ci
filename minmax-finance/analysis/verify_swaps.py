#!/usr/bin/env python3
"""
End-to-end verification that each MinMax pool's swap() executes live (not paused/gated),
by eth_call-ing the real swap() with a state override that grants the simulated caller
an allowance to the pool (read-only; nothing persists).

Approach:
  1. locate the ERC20 allowance storage slot empirically from a known allowance,
  2. stateDiff the allowance[donor][pool] slot to 2^255-1,
  3. eth_call pool.swap(i, j, dx, 0, deadline) from the donor,
  4. compare the returned dy with calculateSwap(i,j,dx).
"""
import json, sys, time, urllib.request

RPC = "https://babel-api.mainnet.iotex.io"
PIN_BLOCK = "latest"

def rpc(method, params, retries=3):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.4)
    return {}

def call(to, data, frm=None, override=None):
    p = {"to": to, "data": data}
    if frm: p["from"] = frm
    params = [p, PIN_BLOCK]
    if override is not None:
        params.append(override)
    return rpc("eth_call", params)

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

def keccak(data: bytes) -> bytes:
    # minimal keccak256 (pure python) for storage slot computation
    import struct
    RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
          0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
          0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
          0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
          0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
          0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
    R = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
    MASK = (1 << 64) - 1
    rate = 136
    data = bytearray(data)
    data.append(0x01)
    while len(data) % rate != 0:
        data.append(0x00)
    data[-1] |= 0x80
    state = [[0] * 5 for _ in range(5)]
    for off in range(0, len(data), rate):
        block = data[off:off + rate]
        for i in range(rate // 8):
            v = struct.unpack_from("<Q", block, i * 8)[0]
            state[i % 5][i // 5] ^= v
        for rnd in range(24):
            C = [state[x][0] ^ state[x][1] ^ state[x][2] ^ state[x][3] ^ state[x][4] for x in range(5)]
            D = [C[(x - 1) % 5] ^ (((C[(x + 1) % 5] << 1) | (C[(x + 1) % 5] >> 63)) & MASK) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    state[x][y] ^= D[x]
            B = [[0] * 5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2 * x + 3 * y) % 5] = ((state[x][y] << R[x][y]) | (state[x][y] >> (64 - R[x][y]))) & MASK
            for x in range(5):
                for y in range(5):
                    state[x][y] = B[x][y] ^ ((~B[(x + 1) % 5][y]) & B[(x + 2) % 5][y] & MASK)
            state[0][0] ^= RC[rnd]
    out = b""
    for i in range(4):
        out += struct.pack("<Q", state[i % 5][i // 5])
    return out

def slot_balance(holder: str, slot: int) -> str:
    h = holder.lower().replace("0x", "").rjust(64, "0")
    key = bytes.fromhex(h + f"{slot:064x}")
    return "0x" + keccak(key).hex()

def slot_allowance(owner: str, spender: str, slot: int) -> str:
    inner = slot_balance(owner, slot)
    key = bytes.fromhex(spender.lower().replace("0x", "").rjust(64, "0") + inner[2:])
    return "0x" + keccak(key).hex()

def get_storage(tok, slot_hex):
    d = rpc("eth_getStorageAt", [tok, slot_hex, PIN_BLOCK])
    return d.get("result")

CASES = [
 ("P1_E4", "0x89963FCD25Cd3b369A2e0642521BCA7Cf0B9d547", "0x6fbcdc1169b5130c59e72e51ed68a84841c98cd1", 2, 1, 1000000),
 ("P1_E4", "0x89963FCD25Cd3b369A2e0642521BCA7Cf0B9d547", "0x3b2bf2b523f54c4e454f08aa286d03115aff326c", 1, 2, 1000000),
 ("P5_B3", "0x09A1B7d922BcfECa097b06498Bc992A83b0BCc42", "0x42c9255d5e522e83b16ea11a3ba04c2d3afca079", 2, 0, 10**18),
 ("P9_M3", "0xdab7B4D2CA330dde50ce611E2177271fD3Eb3F5F", "0x3cdb7c48e70b854ed2fa392e21687501d84b3afc", 1, 0, 1000000),
 ("P7_USDT", "0x074ec23e80bd1fd26b822305614fb10b97847a35", "0x6fbcdc1169b5130c59e72e51ed68a84841c98cd1", 0, 1, 1000000),
 ("P2_XIM", "0x2c1B1DE747043f7C7c8e0896EB33b09eD9ED55c5", "0x3b2bf2b523f54c4e454f08aa286d03115aff326c", 2, 1, 1000000),
 ("P6_XIM", "0xe409587F043f74e47eFB0C10aAf40808D4e037cE", "0x42c9255d5e522e83b16ea11a3ba04c2d3afca079", 3, 1, 10**18),
 ("P11_XIM", "0x73541e9ffb9F4B8d13C2E5621b1Cede1981aD0d9", "0x3cdb7c48e70b854ed2fa392e21687501d84b3afc", 2, 1, 1000000),
 ("A8D_io3", "0xA8D60c3574f2A3f32bA6226939Df15092DD03617", "0x6fbcdc1169b5130c59e72e51ed68a84841c98cd1", 2, 1, 1000000),
 ("P4_META_paused", "0x8360D306Be83f9A992b1657Ad68fe08Ca6f2757A", "0xec690cdd448e3cbb51ed135df72301c3265a8f80", 0, 1, 10**18),
]

if __name__ == "__main__":
    bn = rpc("eth_blockNumber", {})
    PIN_BLOCK = bn.get("result", "latest")
    DONOR = "0x1111111111111111111111111111111111111111"
    # locate allowance slot for the first token using an existing allowance is hard; instead try slots 1..4
    out = {"block": PIN_BLOCK, "cases": []}
    for name, pool, token, i, j, dx in CASES:
        # find allowance slot: try slots 0..4 and check that overriding balanceOf works for the pool's own balance
        # we test the allowance slot by simulating swap and seeing whether it stops reverting
        rec = {"case": name, "pool": pool, "token": token, "i": i, "j": j, "dx": str(dx), "attempts": []}
        calc = call(pool, "0xa95b089f" + f"{i:064x}" + f"{j:064x}" + f"{dx:064x}")
        calc_val = words(calc.get("result", "0x"))[0] if calc.get("result") else None
        rec["calculateSwap"] = str(calc_val)
        deadline = 0xffffffff
        swap_data = "0xae40f61f" + f"{i:064x}" + f"{j:064x}" + f"{dx:064x}" + f"{0:064x}" + f"{deadline:064x}"
        done = False
        for slot in range(0, 5):
            bal_slot = slot_balance(DONOR, slot)          # guess balanceOf slot
            alw_slot = slot_allowance(DONOR, pool, slot + 1) if False else None
            # We override BOTH: give donor balance in slot 'slot' and allowance in slot 'slot+1'
            bal_key = slot_balance(DONOR, slot)
            alw_key = slot_allowance(DONOR, pool, slot + 1)
            override = {token: {"stateDiff": {bal_key: "0x" + f"{10**30:064x}", alw_key: "0x" + "f" * 64}}}
            sw = call(pool, swap_data, frm=DONOR, override=override)
            if sw.get("result"):
                rec["attempts"].append({"slot": slot, "swap_return": str(words(sw["result"])[0])})
                rec["match"] = (calc_val is not None and words(sw["result"])[0] == calc_val)
                rec["slot_used"] = slot
                done = True
                break
            else:
                rec["attempts"].append({"slot": slot, "error": str(sw.get("error"))[:80]})
        if not done:
            rec["match"] = False
            rec["note"] = "all slot guesses reverted"
        out["cases"].append(rec)
        print(f"{name:16s} i={i} j={j} calc={calc_val} -> {'MATCH' if rec.get('match') else rec.get('note','no')}", flush=True)
    json.dump(out, open(sys.argv[1] if len(sys.argv) > 1 else "verify_swaps.json", "w"), indent=1)
    print("saved")
