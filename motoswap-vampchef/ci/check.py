#!/usr/bin/env python3
"""CI re-validation for Motoswap / VampChef (public Ethereum RPC only)."""
import json, os, urllib.request

RPC = "https://ethereum-rpc.publicnode.com"
CHEF = "0x51e648f08a9a08A724591938d9cbc483C809aCA4"
STAKING = "0xCE88F2C6B49EfBb92555eE5475311f0e250C2528"
MOTO = "0xBd965230588EAA536dE6aA45E8ebbc01638535e0"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
FACTORY = "0x81c9cbc47d700da1777abd831d8da3f526dfae24"

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        j = json.load(r)
    if "error" in j:
        raise RuntimeError(j["error"])
    return j["result"]

def call(to, data):
    return rpc("eth_call", [{"to":to,"data":data}, "latest"])

def w(h):
    return int(h, 16) if h and h != "0x" else 0

block = int(rpc("eth_blockNumber", []), 16)
pool_length = w(call(CHEF, "0x081e3eda"))
reward_budget = w(call(CHEF, "0x044c9060"))
emission_end = w(call(CHEF, "0x8368909c"))
credited = w(call(CHEF, "0x067b23c3"))
harvested = w(call(CHEF, "0x23dc1142"))
available = w(call(CHEF, "0x4ad84b34"))
staked_reward = w(call(CHEF, "0x89d2125e"))
recoverable = w(call(CHEF, "0x79ad8e90"))
eff = w(call(STAKING, "0xbd8b26f9"))
moto_bal = w(call(MOTO, "0x70a08231" + "%064x"%int(STAKING,16)))
weth_owed = w(call(STAKING, "0x99eabeb9" + "%064x"%int(WETH,16)))
weth_pending = w(call(STAKING, "0xca78533d" + "%064x"%int(WETH,16)))
pairs = w(call(FACTORY, "0x574f2ba3"))
swap_fee = w(call(FACTORY, "0x2ffdaf89"))
fee_to = "0x" + call(FACTORY, "0x017e7e58")[-40:]

out = {
  "chain": "ethereum", "block": block,
  "vampchef": {"address": CHEF, "poolLength": pool_length,
               "rewardBudget": reward_budget, "emissionEnd": emission_end,
               "totalCredited": credited, "totalHarvested": harvested,
               "availableReward": available, "totalStakedRewardToken": staked_reward,
               "recoverableReward": recoverable},
  "motostaking": {"address": STAKING, "motoBalance": moto_bal,
                  "totalEffectiveStake": eff, "rewardOwedWETH": weth_owed,
                  "pendingClaimsWETH": weth_pending},
  "motoswap": {"factory": FACTORY, "allPairsLength": pairs, "swapFeeBps": swap_fee, "feeTo": fee_to},
  "checks": {
    "vamp_pools": pool_length > 0,
    "budget_300m": reward_budget == 300_000_000 * 10**18,
    "emission_ended": emission_end > 0,
    "staked_reward_nonzero": staked_reward > 0,
    "staking_moto_nonzero": moto_bal > 0,
    "effective_nonzero": eff > 0,
    "weth_owed_nonzero": weth_owed > 0,
    "pairs_20": pairs == 20,
    "fee_30bps": swap_fee == 30,
    "fee_to_zero": fee_to == "0x"+"0"*40
  }
}
out["all_passed"] = all(out["checks"].values())
os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/validation.json","w"), indent=1)
print(json.dumps(out, indent=1))
if not out["all_passed"]:
    raise SystemExit(1)
