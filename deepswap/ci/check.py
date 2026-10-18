#!/usr/bin/env python3
"""CI re-validation for DeepSwap (public Solana RPC only)."""
import base64, json, os, struct, urllib.request

RPC = "https://api.mainnet-beta.solana.com"
POOL = "F3fSrURu58o7n5iNqGRyPgzZPo5VfMtVrWggMD2TeFdp"
LP_MINT = "8biCLkwhPXfs2Wkw1NFAKjaVMGbFU1fdivdUeqEH5DyA"
VAULT0 = "F4dgCnntQ6pdCmNPAf7F8hB7qNFHueQ3thfyA3KGcrCy"
VAULT1 = "2cUjCeH5uzZGFnjBmnAE8mFP8GuqZEFFi3ZHvJ63zXCH"
AUTHORITY = "4vEQmhpGxVJNiLaYz16NVaYQqcp7GbZMwd5TR3cZtQqu"
MULTISIG = "yYb55Wc4wE6jvjBMmWANKoFHMGs49seZ71GFetcXzWr"
SQUADS_PROGRAM = "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf"

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        j = json.load(r)
    if "error" in j:
        raise RuntimeError(j["error"])
    return j["result"]

slot = rpc("getSlot", [])
acc = rpc("getAccountInfo", [POOL, {"encoding":"base64"}])["value"]
data = base64.b64decode(acc["data"][0])
o = 8 + 10*32 + 5
lp_supply = struct.unpack_from("<Q", data, o)[0]
o += 7*8
creator_fee_on = data[o]; o += 1
enable_creator_fee = data[o]; o += 1
o += 6
creator_fees_0 = struct.unpack_from("<Q", data, o)[0]
creator_fees_1 = struct.unpack_from("<Q", data, o+8)[0]
o += 16
fee_model = data[o]; o += 1
reward_model = data[o]; o += 1
o += 6
reward_rate = struct.unpack_from("<Q", data, o)[0]
token_0_mint = data[8+5*32:8+6*32].hex()
token_1_mint = data[8+6*32:8+7*32].hex()

lp_supply_res = rpc("getTokenSupply", [LP_MINT])["value"]
v0 = rpc("getTokenAccountBalance", [VAULT0])["value"]
v1 = rpc("getTokenAccountBalance", [VAULT1])["value"]
auth = rpc("getAccountInfo", [AUTHORITY, {"encoding":"base64"}])["value"]
ms = rpc("getAccountInfo", [MULTISIG, {"encoding":"base64"}])["value"]
ms_data = base64.b64decode(ms["data"][0])
ms_threshold = int.from_bytes(ms_data[72:74], "little")
ms_timelock = int.from_bytes(ms_data[74:78], "little")

out = {
  "chain": "solana", "slot": slot,
  "pool": POOL,
  "program": "HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP",
  "pool_state": {
    "lp_supply_raw": lp_supply,
    "creator_fee_on": creator_fee_on,
    "enable_creator_fee": enable_creator_fee,
    "creator_fees_token_0": creator_fees_0,
    "creator_fees_token_1": creator_fees_1,
    "fee_model": fee_model,
    "reward_model": reward_model,
    "reward_rate_snapshot": reward_rate,
    "token_0_mint_hex": token_0_mint,
    "token_1_mint_hex": token_1_mint
  },
  "lp_mint": {"address": LP_MINT, "supply": lp_supply_res["amount"], "decimals": lp_supply_res["decimals"]},
  "vaults": {
    "token_0": {"address": VAULT0, "amount": v0["amount"], "decimals": v0["decimals"]},
    "token_1": {"address": VAULT1, "amount": v1["amount"], "decimals": v1["decimals"]}
  },
  "upgrade_authority": {"address": AUTHORITY, "owner": auth["owner"], "space": auth["space"], "lamports": auth["lamports"]},
  "squads_multisig": {"address": MULTISIG, "owner": ms["owner"], "space": ms["space"], "threshold": ms_threshold, "time_lock": ms_timelock},
  "checks": {
    "lp_mint_supply_zero": lp_supply_res["amount"] == "0",
    "pool_state_phantom_lp": lp_supply > 0,
    "withdraw_impossible": lp_supply_res["amount"] == "0",
    "authority_is_system_owned": auth["owner"] == "11111111111111111111111111111111",
    "multisig_owner_squads": ms["owner"] == SQUADS_PROGRAM,
    "multisig_threshold_2": ms_threshold == 2,
    "multisig_timelock_48h": ms_timelock == 172800,
    "vault0_nonzero": int(v0["amount"]) > 0,
    "vault1_nonzero": int(v1["amount"]) > 0
  }
}
out["all_passed"] = all(out["checks"].values())
os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/validation.json","w"), indent=1)
print(json.dumps(out, indent=1))
if not out["all_passed"]:
    raise SystemExit(1)
