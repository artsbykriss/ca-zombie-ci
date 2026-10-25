#!/usr/bin/env python3
"""Full read-only enumeration + USD quantification of Streamflow's Solana programs.

Enumerates:
  - stake program  STAKEvGq... : StakePool accounts -> mint, authority, vault, stake_mint
  - reward program RWRDdf...   : RewardPool accounts -> mint, authority, vault
  - reward dyn     RWRDyf...   : RewardPool accounts -> mint, authority, vault
  - vesting/stream strmRq...   : stream contracts -> mint, escrow_tokens, recipient
Then batch-reads every vault / escrow token balance and prices the mints with DefiLlama.

Writes analysis/live_state.json (never contains secrets; keyless public RPC only).
"""
import json, os, sys, base64, time, urllib.request, urllib.error
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import (get_program_accounts, get_multiple, get_slot, b58enc, result)

HERE = os.path.dirname(os.path.abspath(__file__))

STAKE = "STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH"
REWARD = "RWRDdfRbi3339VgKxTAXg4cjyniF7cbhNbMxZWiSKmj"
REWARD_DYN = "RWRDyfZa6Rk9UYi85yjYYfGmoUqffLqjo6vZdFawEez"
VESTING = "strmRqUCoQUgGUan5YhzUZa6KqdzwX5L6FpUxfmKg5m"

DISC = {
    "stake_pool":   b"\x1b\x8b\xa1\x2f\x93\xd5\xaa\x67",   # computed below
}
import hashlib
def adisc(name):
    return hashlib.sha256(("account:" + name).encode()).digest()[:8]

STAKE_POOL_D = adisc("StakePool")
STAKE_ENTRY_D = adisc("StakeEntry")
REWARD_POOL_D = adisc("RewardPool")
REWARD_ENTRY_D = adisc("RewardEntry")

def pk(raw, off):
    return b58enc(raw[off:off + 32])

def u64(raw, off):
    return int.from_bytes(raw[off:off + 8], "little")

def u128(raw, off):
    return int.from_bytes(raw[off:off + 16], "little")

def lamports_to_ui(amount, decimals):
    return amount / (10 ** decimals)

# ---- fetch helpers -------------------------------------------------------
def fetch_program(pid, length, disc=None, label=""):
    filt = [{"memcmp": {"offset": 0, "bytes": b58enc(disc)}}] if disc else None
    r = get_program_accounts(pid, encoding="base64", dataSlice={"offset": 0, "length": length},
                             filters=filt)
    if not isinstance(r, list):
        print("  !! fetch_program error", label, str(r)[:200])
        return []
    print("  %s -> %d accounts" % (label, len(r)))
    return r

def balances(keys):
    """Return {pubkey: {amount, mint, owner}} for SPL token accounts."""
    out = {}
    keys = list(keys)
    for i in range(0, len(keys), 100):
        chunk = keys[i:i + 100]
        vals = get_multiple(chunk, encoding="base64")
        if not isinstance(vals, list):
            continue
        for k, v in zip(chunk, vals):
            if not v:
                out[k] = None
                continue
            raw = base64.b64decode(v["data"][0])
            if len(raw) < 72:
                out[k] = None
                continue
            out[k] = {"mint": pk(raw, 0), "owner": pk(raw, 32), "amount": u64(raw, 64),
                      "state": raw[108] if len(raw) > 108 else None}
        time.sleep(0.15)
    return out

def prices(mints):
    mints = sorted(set(m for m in mints if m))
    res = {}
    for i in range(0, len(mints), 50):
        chunk = mints[i:i + 50]
        url = "https://coins.llama.fi/prices/current/" + ",".join("solana:" + m for m in chunk)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "audit/1.0"})
            d = json.loads(urllib.request.urlopen(req, timeout=45).read())
            for k, v in (d.get("coins") or {}).items():
                res[k.split(":", 1)[1]] = {"price": v.get("price"), "symbol": v.get("symbol"),
                                           "decimals": v.get("decimals"), "confidence": v.get("confidence")}
        except Exception as e:
            print("  price err", e)
        time.sleep(0.3)
    return res

# ---- main ----------------------------------------------------------------
def main():
    out = {"slot": get_slot(), "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    print("slot", out["slot"])

    # --- stake pools
    print("[stake]")
    accs = fetch_program(STAKE, 300, STAKE_POOL_D, "StakePool")
    pools = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        if len(raw) < 203:
            continue
        pools.append({
            "pubkey": a["pubkey"], "mint": pk(raw, 10), "creator": pk(raw, 42),
            "authority": pk(raw, 74), "permissionless": bool(raw[138]),
            "vault": pk(raw, 139), "stake_mint": pk(raw, 171),
            "total_stake": u64(raw, 203), "total_effective_stake": u128(raw, 211),
            "unstake_period": u64(raw, 228) if len(raw) > 236 else None,
            "expiry_ts": u64(raw, 245) if len(raw) > 253 else None,
            "auto_unstake": bool(raw[253]) if len(raw) > 253 else None,
        })
    out["stake_pools"] = pools
    print("  pools", len(pools))

    # --- reward pools (fixed + dynamic)
    for label, pid in (("reward_fixed", REWARD), ("reward_dynamic", REWARD_DYN)):
        print("[%s]" % label)
        accs = fetch_program(pid, 300, REWARD_POOL_D, label)
        rp = []
        dyn = (label == "reward_dynamic")
        for a in accs:
            raw = base64.b64decode(a["account"]["data"][0])
            if dyn:
                if len(raw) < 219:
                    continue
                rp.append({"pubkey": a["pubkey"], "stake_pool": pk(raw, 10), "governor": pk(raw, 42),
                           "mint": pk(raw, 74), "authority": pk(raw, 138),
                           "permissionless": bool(raw[170]), "vault": pk(raw, 187),
                           "funded_amount": u64(raw, 219), "claimed_amount": u64(raw, 227)})
            else:
                if len(raw) < 219:
                    continue
                rp.append({"pubkey": a["pubkey"], "stake_pool": pk(raw, 10), "mint": pk(raw, 42),
                           "authority": pk(raw, 106), "reward_amount": u64(raw, 138),
                           "reward_period": u64(raw, 146), "permissionless": bool(raw[154]),
                           "vault": pk(raw, 187), "funded_amount": u64(raw, 219),
                           "claimed_amount": u64(raw, 227)})
        out[label] = rp
        print("  pools", len(rp))

    # --- vesting / stream
    print("[vesting]")
    try:
        accs = fetch_program(VESTING, 241, None, "stream-contracts")
    except Exception as e:
        print("  vesting fetch failed:", e)
        accs = []
    streams = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        if len(raw) < 241:
            continue
        streams.append({"pubkey": a["pubkey"], "kind": u64(raw, 0), "version": raw[8],
                        "sender": pk(raw, 49), "recipient": pk(raw, 113),
                        "mint": pk(raw, 177), "escrow": pk(raw, 209)})
    out["streams_count"] = len(streams)
    out["streams_sample"] = streams[:5000]
    print("  streams", len(streams))

    # --- balances
    vault_keys = set(p["vault"] for p in out["stake_pools"])
    for k in ("reward_fixed", "reward_dynamic"):
        vault_keys |= set(p["vault"] for p in out[k])
    escrow_keys = set(s["escrow"] for s in streams)
    all_keys = vault_keys | escrow_keys
    print("[balances] %d token accounts" % len(all_keys))
    bal = balances(all_keys)
    out["token_balances"] = bal

    # --- aggregate per mint
    def agg(keys):
        d = {}
        for k in keys:
            b = bal.get(k)
            if not b:
                continue
            d.setdefault(b["mint"], {"amount": 0, "accounts": 0})
            d[b["mint"]]["amount"] += b["amount"]
            d[b["mint"]]["accounts"] += 1
        return d

    stake_agg = agg(p["vault"] for p in out["stake_pools"])
    reward_agg = agg(p["vault"] for k in ("reward_fixed", "reward_dynamic") for p in out[k])
    escrow_agg = agg(s["escrow"] for s in streams)
    out["agg"] = {"stake_vaults": stake_agg, "reward_vaults": reward_agg, "vesting_escrows": escrow_agg}

    # --- prices
    all_mints = set(stake_agg) | set(reward_agg) | set(escrow_agg)
    pr = prices(all_mints)
    out["prices"] = pr

    def usd(agg):
        tot = 0.0
        per = {}
        for mint, v in agg.items():
            info = pr.get(mint) or {}
            dec = info.get("decimals")
            if dec is None:
                dec = 9
            amt = lamports_to_ui(v["amount"], dec)
            p = info.get("price") or 0
            per[mint] = {"ui_amount": amt, "price": p, "usd": amt * p,
                         "symbol": info.get("symbol"), "accounts": v["accounts"],
                         "priced": bool(p)}
            tot += amt * p
        return tot, per

    for name, agg_ in (("stake_vaults", stake_agg), ("reward_vaults", reward_agg),
                       ("vesting_escrows", escrow_agg)):
        t, per = usd(agg_)
        out.setdefault("usd", {})[name] = {"total": t, "per_mint": per}
        print("[usd] %s = $%.2f" % (name, t))

    with open(os.path.join(HERE, "live_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote live_state.json")

if __name__ == "__main__":
    main()
