#!/usr/bin/env python3
"""Sweep ALL GoonFi markets (2048-byte states) + their vaults + oracles.
Outputs analysis/market-sweep.json + a printed table. Read-only RPC."""
import json, os, sys, base64, struct, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"


def b58e(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = B58[r] + s
    for byte in b:
        if byte == 0:
            s = "1" + s
        else:
            break
    return s


def gpa(size):
    # mainnet-beta is the only keyless endpoint that serves getProgramAccounts here
    r = rpc("getProgramAccounts", ["goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE", {
        "encoding": "base64", "filters": [{"dataSize": size}], "commitment": "finalized"}],
        url="https://api.mainnet-beta.solana.com")
    return r.get("result", [])


def decode_market(raw):
    return {
        "version": struct.unpack("<Q", raw[0:8])[0],
        "capacity_a": struct.unpack("<Q", raw[8:16])[0],
        "capacity_b": struct.unpack("<Q", raw[16:24])[0],
        "u24": struct.unpack("<Q", raw[24:32])[0],
        "last_slot_a": struct.unpack("<Q", raw[32:40])[0],
        "last_slot_b": struct.unpack("<Q", raw[40:48])[0],
        "updater": b58e(raw[48:80]),
        "mint_a": b58e(raw[80:112]),
        "mint_b": b58e(raw[112:144]),
        "vault_a": b58e(raw[144:176]),
        "vault_b": b58e(raw[176:208]),
        "oracle": b58e(raw[208:240]),
        "p240": struct.unpack("<Q", raw[240:248])[0],
        "p248": struct.unpack("<Q", raw[248:256])[0],
        "paused_byte": raw[2047],
    }


def token_info(addr):
    r = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
    v = r.get("result", {}).get("value")
    if not v:
        return None
    raw = base64.b64decode(v["data"][0])
    if len(raw) != 165:
        return {"owner_prog": v["owner"], "len": len(raw)}
    return {
        "mint": b58e(raw[0:32]),
        "owner": b58e(raw[32:64]),
        "amount": struct.unpack("<Q", raw[64:72])[0],
        "is_native": struct.unpack("<Q", raw[113:121])[0],
    }


def mint_decimals(addr):
    r = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
    v = r.get("result", {}).get("value")
    if not v:
        return None
    raw = base64.b64decode(v["data"][0])
    return {"decimals": raw[44], "supply": struct.unpack("<Q", raw[36:44])[0]}


def main():
    states = gpa(2048)
    print("markets found:", len(states))
    out = []
    oracle_cache = {}
    for item in states:
        pk = item["pubkey"]
        raw = base64.b64decode(item["account"]["data"][0])
        m = decode_market(raw)
        m["pool"] = pk
        m["lamports"] = item["account"]["lamports"]
        # vault balances
        for side in ("a", "b"):
            t = token_info(m[f"vault_{side}"])
            m[f"vault_{side}_info"] = t
        # mint decimals
        for side in ("a", "b"):
            if m[f"mint_{side}"] not in oracle_cache:
                oracle_cache[m[f"mint_{side}"]] = mint_decimals(m[f"mint_{side}"])
            m[f"mint_{side}_info"] = oracle_cache[m[f"mint_{side}"]]
        # oracle content
        o = m["oracle"]
        if o not in oracle_cache:
            r = rpc("getAccountInfo", [o, {"encoding": "base64"}])
            v = r.get("result", {}).get("value")
            if v:
                oraw = base64.b64decode(v["data"][0])
                oracle_cache[o] = {
                    "owner": v["owner"], "len": len(oraw),
                    "P1": struct.unpack("<Q", oraw[0:8])[0] if len(oraw) >= 8 else None,
                    "P2": struct.unpack("<Q", oraw[8:16])[0] if len(oraw) >= 16 else None,
                    "slot": struct.unpack("<I", oraw[16:20])[0] if len(oraw) >= 20 else None,
                    "denom": struct.unpack("<I", oraw[20:24])[0] if len(oraw) >= 24 else None,
                    "ts": struct.unpack("<Q", oraw[24:32])[0] if len(oraw) >= 32 else None,
                }
            else:
                oracle_cache[o] = None
        m["oracle_info"] = oracle_cache[o]
        out.append(m)
        time.sleep(0.05)
    with open(os.path.join(OUT, "market-sweep.json"), "w") as f:
        json.dump({"markets": out, "oracles": oracle_cache}, f, indent=1)
    # print table
    print(f"{'pool':44s} {'mintA':10s} {'mintB':10s} {'vaultA':>16s} {'vaultB':>16s} {'P1':>12s} {'P2':>12s} {'denom':>7s} {'o.slot':>10s} {'ts':>14s}")
    for m in out:
        va = m["vault_a_info"]["amount"] if m["vault_a_info"] and "amount" in m["vault_a_info"] else -1
        vb = m["vault_b_info"]["amount"] if m["vault_b_info"] and "amount" in m["vault_b_info"] else -1
        oi = m["oracle_info"] or {}
        print(f"{m['pool']:44s} {m['mint_a'][:8]:10s} {m['mint_b'][:8]:10s} {va:>16d} {vb:>16d} {oi.get('P1',0):>12d} {oi.get('P2',0):>12d} {oi.get('denom',0):>7d} {oi.get('slot',0):>10d} {oi.get('ts',0):>14d}")
    # distinct oracles
    print("\ndistinct oracles:", len(oracle_cache))
    for o, oi in oracle_cache.items():
        if isinstance(oi, dict) and "P1" in oi:
            print(f"  {o} P1={oi['P1']} P2={oi['P2']} slot={oi['slot']} denom={oi['denom']} ts={oi['ts']} owner={oi['owner'][:12]}")


if __name__ == "__main__":
    main()
