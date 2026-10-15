#!/usr/bin/env python3
"""
Serum Swap (SPL token-swap) live-state fetcher/decoder.

READ-ONLY. Uses only keyless public Solana RPC endpoints. No keys, no transactions.

Program under analysis : SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8
Verified build         : solana-labs/solana-program-library @ 9281b6e82899 (2021-04-14,
                         "feat: adjust fee constraints (#1596)"), token-swap crate 2.1.0
Account layout (324 B) : [0] version=1  [1] is_initialized  [2] nonce
                         [3:35] token_program_id   [35:67] token_a       [67:99] token_b
                         [99:131] pool_mint      [131:163] token_a_mint  [163:195] token_b_mint
                         [195:227] pool_fee_account
                         [227:291] fees = 8 x u64
                             trade_fee_num, trade_fee_den, owner_trade_fee_num, owner_trade_fee_den,
                             owner_withdraw_fee_num, owner_withdraw_fee_den, host_fee_num, host_fee_den
                         [291:324] swap_curve = 1 byte curve type + 32 bytes params
                             curve type 0=ConstantProduct, 1=ConstantPrice, 2=Stable, 3=Offset
"""
import base64
import json
import os
import struct
import sys
import time
import urllib.request

PROGRAM_ID = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8"
PROGRAMDATA = "FV9WWFWYzWHDpAc8oxiFKV1LmFUyWw7HGdo4GK19MiZW"
UPGRADE_AUTHORITY_DECODED = "DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn"  # decoded from programdata 2026-10-15
UPGRADE_AUTHORITY_CLAIMED_BY_PARENT = "7orsQE9oBJfD73N4sBekkJmcZuAAxH1siWa2R2qzZuD"
RPC_URLS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]
OUT = os.path.dirname(os.path.abspath(__file__))

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58enc(x: bytes) -> str:
    n = int.from_bytes(x, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = ALPH[r] + s
    pad = 0
    for c in x:
        if c == 0:
            pad += 1
        else:
            break
    return "1" * pad + s


def rpc(method, params, url=None, retries=3):
    urls = [url] if url else RPC_URLS
    last = None
    for attempt in range(retries):
        for u in urls:
            try:
                req = urllib.request.Request(
                    u,
                    data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                    headers={"Content-Type": "application/json", "User-Agent": "research/1.0"},
                )
                with urllib.request.urlopen(req, timeout=120) as r:
                    d = json.load(r)
                if "error" in d:
                    raise RuntimeError(f"{method} rpc error: {d['error']}")
                return d
            except Exception as e:  # noqa
                last = e
                time.sleep(1.0 + attempt)
    raise RuntimeError(f"{method} failed: {last}")


def get_program_accounts():
    d = rpc("getProgramAccounts", [PROGRAM_ID, {"encoding": "base64", "commitment": "finalized"}])
    return d["result"], d["context"]["slot"] if "context" in d else None


def get_multiple(addresses):
    out = []
    for i in range(0, len(addresses), 100):
        chunk = addresses[i:i + 100]
        d = rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "finalized"}])
        out.extend(zip(chunk, d["result"]["value"]))
        time.sleep(0.35)
    return out


def decode_mint(data: bytes):
    return {
        "mint_authority": b58enc(data[4:36]) if data[0] == 1 else None,
        "supply": struct.unpack("<Q", data[36:44])[0],
        "decimals": data[44],
        "is_initialized": data[45] == 1,
        "freeze_authority": b58enc(data[46:78]) if data[46] == 1 else None,
    }


def decode_token_account(data: bytes):
    return {
        "mint": b58enc(data[0:32]),
        "owner": b58enc(data[32:64]),
        "amount": struct.unpack("<Q", data[64:72])[0],
        "delegate": b58enc(data[72:104]) if data[72] == 1 else None,
        "state": data[108],
        "close_authority": b58enc(data[129:161]) if data[129] == 1 else None,
    }


def pdas(pool: str, nonce: int):
    """Derive the swap authority PDA for a pool using solders (independent derivation)."""
    try:
        from solders.pubkey import Pubkey
        k = Pubkey.from_string(pool)
        pda, bump = Pubkey.find_program_address([bytes(k)], Pubkey.from_string(PROGRAM_ID))
        created = Pubkey.create_program_address([bytes(k), bytes([nonce])], Pubkey.from_string(PROGRAM_ID))
        return str(pda), bump, str(created)
    except Exception as e:
        return None, None, f"ERR {e}"


def main():
    accounts, slot = get_program_accounts()
    print(f"[fetch] getProgramAccounts -> {len(accounts)} accounts at slot {slot}")
    json.dump({"slot": slot, "accounts": accounts}, open(os.path.join(OUT, "raw-program-accounts.json"), "w"))

    pools = []
    for it in accounts:
        raw = base64.b64decode(it["account"]["data"][0])
        rec = {"pool": it["pubkey"], "lamports": it["account"]["lamports"], "data_len": len(raw)}
        if len(raw) not in (323, 324):
            rec["kind"] = "non-swap-account"
            pools.append(rec)
            continue
        rec["version"] = raw[0]
        if len(raw) == 324:
            rec["is_initialized"] = raw[1] == 1
            rec["nonce"] = raw[2]
            off = 3
        else:  # 323-byte account: pre-version layout
            rec["is_initialized"] = raw[0] == 1
            rec["nonce"] = raw[1]
            off = 2
        if not rec["is_initialized"] or len(raw) != 324:
            pools.append(rec)
            continue
        rec["token_program_id"] = b58enc(raw[off:off + 32]); off += 32
        rec["token_a"] = b58enc(raw[off:off + 32]); off += 32
        rec["token_b"] = b58enc(raw[off:off + 32]); off += 32
        rec["pool_mint"] = b58enc(raw[off:off + 32]); off += 32
        rec["token_a_mint"] = b58enc(raw[off:off + 32]); off += 32
        rec["token_b_mint"] = b58enc(raw[off:off + 32]); off += 32
        rec["pool_fee_account"] = b58enc(raw[off:off + 32]); off += 32
        rec["fees"] = {
            "trade_fee_num": struct.unpack("<Q", raw[off:off + 8])[0],
            "trade_fee_den": struct.unpack("<Q", raw[off + 8:off + 16])[0],
            "owner_trade_fee_num": struct.unpack("<Q", raw[off + 16:off + 24])[0],
            "owner_trade_fee_den": struct.unpack("<Q", raw[off + 24:off + 32])[0],
            "owner_withdraw_fee_num": struct.unpack("<Q", raw[off + 32:off + 40])[0],
            "owner_withdraw_fee_den": struct.unpack("<Q", raw[off + 40:off + 48])[0],
            "host_fee_num": struct.unpack("<Q", raw[off + 48:off + 56])[0],
            "host_fee_den": struct.unpack("<Q", raw[off + 56:off + 64])[0],
        }
        off += 64
        rec["curve_type"] = {0: "ConstantProduct", 1: "ConstantPrice", 2: "Stable", 3: "Offset"}.get(raw[off], f"UNKNOWN({raw[off]})")
        rec["curve_params_hex"] = raw[off + 1:off + 33].hex()
        rec["curve_param_u64"] = struct.unpack("<Q", raw[off + 1:off + 9])[0]
        pools.append(rec)

    init_pools = [p for p in pools if p.get("is_initialized")]
    print(f"[decode] initialized pools: {len(init_pools)}  uninitialized: {sum(1 for p in pools if 'is_initialized' in p and not p['is_initialized'])}")

    # gather referenced accounts
    refs = set()
    for p in init_pools:
        for f in ("token_a", "token_b", "pool_mint", "token_a_mint", "token_b_mint", "pool_fee_account"):
            refs.add(p[f])
    refs = sorted(refs)
    print(f"[fetch] referenced accounts: {len(refs)}")
    fetched = get_multiple(refs)
    info = {}
    for addr, v in fetched:
        if v is None:
            info[addr] = None
            continue
        data = base64.b64decode(v["data"][0])
        d = {"owner": v["owner"], "lamports": v["lamports"], "space": v["space"]}
        if v["owner"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA":
            if v["space"] == 82:
                d.update(decode_mint(data))
                d["kind"] = "mint"
            elif v["space"] == 165:
                d.update(decode_token_account(data))
                d["kind"] = "token_account"
            else:
                d["kind"] = "token_other"
        else:
            d["kind"] = "other"
        info[addr] = d

    # per-pool enrichment
    for p in init_pools:
        p["refs"] = {f: info.get(p[f]) for f in ("token_a", "token_b", "pool_mint", "token_a_mint", "token_b_mint", "pool_fee_account")}
        pda, bump, created = pdas(p["pool"], p["nonce"])
        p["authority_pda"] = pda
        p["authority_bump"] = bump
        p["authority_from_stored_nonce"] = created
        va = p["refs"]["token_a"]
        vb = p["refs"]["token_b"]
        p["vault_a_owner_is_pda"] = bool(va and va.get("owner") == pda)
        p["vault_b_owner_is_pda"] = bool(vb and vb.get("owner") == pda)
        pm = p["refs"]["pool_mint"]
        p["pool_mint_authority_is_pda"] = bool(pm and pm.get("mint_authority") == pda)
        p["reserve_a"] = va["amount"] if va and va.get("kind") == "token_account" else None
        p["reserve_b"] = vb["amount"] if vb and vb.get("kind") == "token_account" else None
        p["decimals_a"] = p["refs"]["token_a_mint"]["decimals"] if p["refs"]["token_a_mint"] else None
        p["decimals_b"] = p["refs"]["token_b_mint"]["decimals"] if p["refs"]["token_b_mint"] else None
        p["lp_supply"] = pm["supply"] if pm else None
        fa = p["refs"]["pool_fee_account"]
        p["fee_account_amount"] = fa["amount"] if fa and fa.get("kind") == "token_account" else None

    out = {
        "program_id": PROGRAM_ID,
        "programdata": PROGRAMDATA,
        "slot": slot,
        "fetched_at_unix": int(time.time()),
        "total_accounts": len(accounts),
        "initialized_pools": len(init_pools),
        "referenced_accounts": info,
        "pools": pools,
    }
    json.dump(out, open(os.path.join(OUT, "pools-raw.json"), "w"), indent=1)
    print("[write] pools-raw.json")

    # console summary
    for p in init_pools:
        print(f"  {p['pool']} curve={p['curve_type']} A={p['token_a_mint'][:8]}..({p['decimals_a']}d) resA={p['reserve_a']} "
              f"B={p['token_b_mint'][:8]}..({p['decimals_b']}d) resB={p['reserve_b']} lp={p['lp_supply']} "
              f"pdaOK={p['vault_a_owner_is_pda'] and p['vault_b_owner_is_pda']} fees={p['fees']['trade_fee_num']}/{p['fees']['trade_fee_den']}")


if __name__ == "__main__":
    main()
