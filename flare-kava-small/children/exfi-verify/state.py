"""Final fresh live-state snapshot for the report (read-only)."""
import json
from lib import *

MGR = "0xc4D89F8f593F215f3636793E3353A36C196Cf87A"
SFIN_MGR = "0xA83E90337e2711b1c84df0AD7428403dBd0ce730"
FARM = "0xb78ebd4b13a2202068618bf98f952c0271159107"
EXFI = "0xC348F894d0E939FE72c467156E6d7DcbD6f16e21"
TOKENS = ["0x02f0826ef6ad107cfc861152b32b52fd11bab9ed", "0xc348f894d0e939fe72c467156e6d7dcbd6f16e21",
          "0x0d94e59332732d18cf3a3d457a8886a2ae29ea1b", "0xc54de96302981f87a6f80e4607593681b44d670c",
          "0xf9a84f4ec903f4eab117a9c1098bec078ba7027d", "0x36b84a93820175c02f57e5c87a7ea33df58e5c94",
          "0x1a7b46656b2b8b29b1694229e122d066020503d0", "0x4a771cc1a39fdd8aa08b8ea51f7fd412e73b3d2b"]
SYM = ["WSGB", "EXFI", "SFIN", "exXDC", "FXRP", "exETH", "exUSDT", "USDX"]
ALLOWED = ["0x9EbF96373f24A8836d3899C9ff17451F802E8c72", "0x43fc122D6dDa2c07301ee131Fa2afa8Bf5854A07"]

blk = int(rpc("eth_blockNumber", []), 16)
out = {"block": blk}
calls = []
def C(to, data, tag):
    calls.append({"to": to, "data": data, "_tag": tag})

C(MGR, sel("getCurrentEpoch()"), "cur")
C(MGR, sel("getNextEpoch()"), "next")
C(MGR, sel("getLatestEpochForRewards()"), "latestReward")
C(MGR, sel("totalSupply()"), "mgr_totalSupply")
C(MGR, sel("owner()"), "mgr_owner")
C(MGR, "0xa5032f3c", "notifier")
C(MGR, sel("apyCloudVault()"), "vault")
C(MGR, sel("getRewardTokens()"), "tokens")
C(SFIN_MGR, sel("totalSupply()"), "sfin_totalSupply")
C(SFIN_MGR, sel("getCurrentEpoch()"), "sfin_cur")
C(FARM, sel("totalSupply()"), "farm_totalSupply")
C(FARM, sel("periodFinish()"), "farm_periodFinish")
C(FARM, sel("rewardRate()"), "farm_rewardRate")
C(FARM, sel("owner()"), "farm_owner")
C(FARM, sel("stakingToken()"), "farm_stakingToken")
C(FARM, sel("rewardToken()"), "farm_rewardToken")
for a in ALLOWED:
    C(FARM, sel("allowedCaller(address)") + addr(a), "allowed_" + a)
    C(a, "0x", "code_" + a)
for i, t in enumerate(TOKENS):
    C(t, sel("symbol()"), f"sym_{i}")
    C(t, sel("balanceOf(address)") + addr(MGR), f"mgrbal_{i}")
    C(t, sel("balanceOf(address)") + addr(SFIN_MGR), f"sfinbal_{i}")
    C(t, sel("balanceOf(address)") + addr(FARM), f"farmbal_{i}")

res = batch_eth_call([{k: v for k, v in c.items() if not k.startswith("_")} for c in calls])
vals = {}
for c, r in zip(calls, res):
    vals[c["_tag"]] = r
out["cur"] = dec_uint(vals["cur"])
out["next"] = dec_uint(vals["next"])
out["latestReward"] = dec_uint(vals["latestReward"])
out["mgr_totalSupply"] = dec_uint(vals["mgr_totalSupply"])
out["mgr_owner"] = dec_addr(vals["mgr_owner"])
out["notifier"] = dec_addr(vals["notifier"])
out["vault"] = dec_addr(vals["vault"])
out["sfin_totalSupply"] = dec_uint(vals["sfin_totalSupply"])
out["sfin_cur"] = dec_uint(vals["sfin_cur"])
out["farm_totalSupply"] = dec_uint(vals["farm_totalSupply"])
out["farm_periodFinish"] = dec_uint(vals["farm_periodFinish"])
out["farm_rewardRate"] = dec_uint(vals["farm_rewardRate"])
out["farm_owner"] = dec_addr(vals["farm_owner"])
out["farm_stakingToken"] = dec_addr(vals["farm_stakingToken"])
out["farm_rewardToken"] = dec_addr(vals["farm_rewardToken"])
out["allowedCallers"] = {a: bool(int(vals["allowed_" + a], 16)) for a in ALLOWED}
out["allowedCaller_codesize_bytes"] = {a: (len(vals["code_" + a]) - 2) // 2 for a in ALLOWED}
out["balances"] = {
    SYM[i]: {"mgr": dec_uint(vals[f"mgrbal_{i}"]), "sfin_mgr": dec_uint(vals[f"sfinbal_{i}"]), "farm": dec_uint(vals[f"farmbal_{i}"])}
    for i in range(8)
}
out["surplus_exfi_mgr"] = out["balances"]["EXFI"]["mgr"] - out["mgr_totalSupply"]
json.dump(out, open("state.json", "w"), indent=1)
print(json.dumps(out, indent=1))
