#!/usr/bin/env python3
"""Enumerate Saber stable-swap pools (SwapInfo dataSize=395) and their live state.

Read-only. Public RPC endpoints only (no keys). Writes JSON to analysis/.
"""
import json, base64, hashlib, sys, time, urllib.request, os

RPC = os.environ.get("SOL_RPC", "https://api.mainnet-beta.solana.com")
SWAP_PROGRAM = "SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ"
HERE = os.path.dirname(os.path.abspath(__file__))

def rpc(method, params, retries=5):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read())
            if "error" in d:
                raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            if i == retries - 1:
                raise
            time.sleep(2 * (i + 1))

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big"); s = ""
    while n:
        n, r = divmod(n, 58); s = ALPH[r] + s
    for c in b:
        if c == 0: s = "1" + s
        else: break
    return s or "1"

def b58decode(s: str) -> bytes:
    n = 0
    for c in s: n = n * 58 + ALPH.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = len(s) - len(s.lstrip("1"))
    return b"\x00" * pad + b

def pda(seeds, program_id: bytes) -> bytes:
    h = hashlib.sha256()
    for s in seeds: h.update(s)
    h.update(program_id)
    h.update(b"ProgramDerivedAddress")
    return h.digest()

def decode_swap(key: str, data: bytes):
    u64 = lambda o: int.from_bytes(data[o:o+8], "little")
    pk = lambda o: b58encode(data[o:o+32])
    return {
        "swap": key,
        "is_initialized": data[0],
        "is_paused": data[1],
        "nonce": data[2],
        "initial_amp": u64(3), "target_amp": u64(11),
        "start_ramp_ts": u64(19), "stop_ramp_ts": u64(27),
        "future_admin_deadline": u64(35),
        "future_admin_key": pk(43), "admin_key": pk(75),
        "reserves_a": pk(107), "reserves_b": pk(139),
        "pool_mint": pk(171),
        "mint_a": pk(203), "mint_b": pk(235),
        "admin_fees_a": pk(267), "admin_fees_b": pk(299),
        "fees": {
            "admin_trade_fee_num": u64(331), "admin_trade_fee_den": u64(339),
            "admin_withdraw_fee_num": u64(347), "admin_withdraw_fee_den": u64(355),
            "trade_fee_num": u64(363), "trade_fee_den": u64(371),
            "withdraw_fee_num": u64(379), "withdraw_fee_den": u64(387),
        },
    }

def main():
    prog = b58decode(SWAP_PROGRAM)
    # 1) all SwapInfo accounts
    accs = rpc("getProgramAccounts", [SWAP_PROGRAM, {"encoding": "base64", "filters": [{"dataSize": 395}]}])
    pools = []
    for a in accs:
        data = base64.b64decode(a["account"]["data"][0])
        if len(data) != 395 or data[0] != 1:
            continue
        p = decode_swap(a["pubkey"], data)
        p["_lamports"] = a["account"]["lamports"]
        pools.append(p)
    print(f"SwapInfo accounts (initialized): {len(pools)}")
    slot = rpc("getSlot", [{"commitment": "finalized"}])
    print("slot:", slot)

    # 2) derive expected authority for each pool
    for p in pools:
        p["expected_authority"] = b58encode(pda([b58decode(p["swap"]), bytes([p["nonce"]])], prog))

    # 3) fetch vault accounts + mints + fee accounts in batches
    want = []
    for p in pools:
        want += [p["reserves_a"], p["reserves_b"], p["pool_mint"], p["mint_a"], p["mint_b"], p["admin_fees_a"], p["admin_fees_b"]]
    want = sorted(set(want))
    info = {}
    for i in range(0, len(want), 100):
        batch = want[i:i+100]
        res = rpc("getMultipleAccounts", [batch, {"encoding": "base64"}])
        for k, v in zip(batch, res["value"]):
            if v is None:
                info[k] = None
            else:
                info[k] = {"owner": v["owner"], "lamports": v["lamports"], "data": base64.b64decode(v["data"][0])}
        print(f"fetched {min(i+100,len(want))}/{len(want)}")

    def token_account(k):
        v = info.get(k)
        if not v or len(v["data"]) != 165: return None
        d = v["data"]
        delegate = b58encode(d[76:108]) if int.from_bytes(d[72:76], "little") == 1 else None
        close = b58encode(d[133:165]) if int.from_bytes(d[129:133], "little") == 1 else None
        return {"owner_prog": v["owner"], "mint": b58encode(d[0:32]),
                "authority": b58encode(d[32:64]), "amount": int.from_bytes(d[64:72], "little"),
                "delegate": delegate, "state": d[108], "close_authority": close}

    def mint_info(k):
        v = info.get(k)
        if not v or len(v["data"]) != 82: return None
        d = v["data"]
        return {"owner_prog": v["owner"], "mint_authority": b58encode(d[0:32]), "supply": int.from_bytes(d[36:44], "little"),
                "decimals": d[44], "initialized": d[45], "freeze_authority": b58encode(d[46:78])}

    for p in pools:
        p["vault_a"] = token_account(p["reserves_a"])
        p["vault_b"] = token_account(p["reserves_b"])
        p["lp_mint"] = mint_info(p["pool_mint"])
        p["mint_a_info"] = mint_info(p["mint_a"])
        p["mint_b_info"] = mint_info(p["mint_b"])
        p["admin_fees_a_info"] = token_account(p["admin_fees_a"])
        p["admin_fees_b_info"] = token_account(p["admin_fees_b"])

    with open(os.path.join(HERE, "pools_raw.json"), "w") as f:
        json.dump({"slot": slot, "rpc": RPC, "pools": pools, "accounts": {k: ({"owner": v["owner"], "lamports": v["lamports"], "data_b64": base64.b64encode(v["data"]).decode()} if v else None) for k, v in info.items()}}, f)
    print("wrote pools_raw.json")

if __name__ == "__main__":
    main()
