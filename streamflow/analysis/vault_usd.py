#!/usr/bin/env python3
"""Light targeted quantification: USD held in the stake-program vaults and the
reward-program vaults (batched getMultipleAccounts). Writes analysis/vault_usd.json."""
import sys, os, json, base64, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_program_accounts, get_multiple, get_slot, b58enc

STAKE = "STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH"
REWARD = "RWRDdfRbi3339VgKxTAXg4cjyniF7cbhNbMxZWiSKmj"
REWARD_DYN = "RWRDyfZa6Rk9UYi85yjYYfGmoUqffLqjo6vZdFawEez"
STREAM = "STREAMribRwybYpMmSYoCsQUdr6MZNXEqHgm7p1gu9M"
import hashlib
def adisc(n): return hashlib.sha256(("account:" + n).encode()).digest()[:8]
def pk(raw, o): return b58enc(raw[o:o+32])

def pools(pid, disc):
    accs = get_program_accounts(pid, encoding="base64", dataSlice={"offset": 0, "length": 300},
                                filters=[{"memcmp": {"offset": 0, "bytes": b58enc(disc)}}])
    out = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        out.append((a["pubkey"], raw))
    return out

def balances(keys):
    out = {}
    for i in range(0, len(keys), 100):
        vals = get_multiple(keys[i:i+100], encoding="base64")
        if not isinstance(vals, list): continue
        for k, v in zip(keys[i:i+100], vals):
            if v:
                raw = base64.b64decode(v["data"][0])
                out[k] = {"mint": pk(raw, 0), "amount": int.from_bytes(raw[64:72], "little")}
        time.sleep(0.1)
    return out

def prices(mints):
    mints = sorted(set(m for m in mints if m)); res = {}
    for i in range(0, len(mints), 50):
        url = "https://coins.llama.fi/prices/current/" + ",".join("solana:" + m for m in mints[i:i+50])
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "audit/1.0"})
            d = json.loads(urllib.request.urlopen(req, timeout=45).read())
            for k, v in (d.get("coins") or {}).items():
                res[k.split(":", 1)[1]] = v
        except Exception as e: print("price err", e)
        time.sleep(0.2)
    return res

def main():
    out = {"slot": get_slot()}
    sp = pools(STAKE, adisc("StakePool"))
    rp = pools(REWARD, adisc("RewardPool")) + pools(REWARD_DYN, adisc("RewardPool"))
    out["stake_pools"] = len(sp); out["reward_pools"] = len(rp)
    stake_vaults = {pk(raw, 139): pk(raw, 10) for _, raw in sp}       # vault -> mint (stake pool)
    reward_vaults = {}
    for _, raw in rp:
        # fixed: vault at 187, mint at 42 ; dynamic: vault 187, mint 74
        reward_vaults[pk(raw, 187)] = None
    bal = balances(list(stake_vaults) + list(reward_vaults))
    mints = set(b["mint"] for b in bal.values())
    pr = prices(mints)

    def agg(keys):
        d = {}
        for k in keys:
            b = bal.get(k)
            if not b: continue
            info = pr.get(b["mint"]) or {}
            dec = info.get("decimals") or 9
            amt = b["amount"] / 10 ** dec
            price = info.get("price") or 0
            e = d.setdefault(b["mint"], {"ui": 0.0, "usd": 0.0, "n": 0, "symbol": info.get("symbol")})
            e["ui"] += amt; e["usd"] += amt * price; e["n"] += 1
        return d

    sa = agg(stake_vaults); ra = agg(reward_vaults)
    out["stake_vaults"] = {"total_usd": sum(v["usd"] for v in sa.values()),
                           "per_mint": dict(sorted(sa.items(), key=lambda kv: -kv[1]["usd"])[:40]),
                           "stream_only_usd": sa.get(STREAM, {}).get("usd", 0.0)}
    out["reward_vaults"] = {"total_usd": sum(v["usd"] for v in ra.values()),
                            "per_mint": dict(sorted(ra.items(), key=lambda kv: -kv[1]["usd"])[:40])}
    out["prices"] = pr
    json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "vault_usd.json"), "w"), indent=1)
    print("stake vaults USD  =", out["stake_vaults"]["total_usd"], " (STREAM only:", out["stake_vaults"]["stream_only_usd"], ")")
    print("reward vaults USD =", out["reward_vaults"]["total_usd"])
    print("priced mints:", sum(1 for v in pr.values() if v.get("price")), "of", len(pr))

if __name__ == "__main__":
    main()
