#!/usr/bin/env python3
"""Fingerprint Aurora Rose contracts by selector presence in bytecode. Read-only, keyless RPC."""
import json, urllib.request, sys

RPC = "https://mainnet.aurora.dev"

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))["result"]

SIGS = {
 "0xbb7b8b80":"get_virtual_price()", "0x0c46b72a":"virtual_price()",
 "0x3df02124":"exchange(int128,int128,uint256,uint256)", "0x5b41b908":"exchange(uint256,uint256,uint256,uint256)",
 "0xc6610657":"coins(uint256)", "0x4903b0d1":"balances(uint256)", "0xf446c1d0":"A()", "0xddca3f43":"fee()",
 "0xfee3f7f9":"admin_fee()", "0x524c3901":"donate_admin_fees()", "0xe3698853":"kill_me()", "0x3046f972":"unkill_me()",
 "0xe9333fab":"set_admin(address)", "0x8da5cb5b":"owner()", "0xfc0c546a":"token()", "0xf851a440":"admin()",
 "0x86fc88d3":"price_oracle()", "0xb9e8c9fd":"price_scale()", "0xa3f7cdd5":"price_scale(uint256)", "0x59189017":"last_prices(uint256)",
 "0xc93f49e8":"claim_admin_fees()", "0x30c54085":"withdraw_admin_fees()", "0x7b0a47ee":"rewardRate()", "0xebe2b12b":"periodFinish()",
 "0x72f702f3":"stakingToken()", "0xf7c618c1":"rewardToken()", "0xb6b55f25":"deposit(uint256)", "0x2e1a7d4d":"withdraw(uint256)",
 "0x3d18b912":"getReward()", "0x4641257d":"harvest()", "0xe20ccec3":"pending()", "0x1526fe27":"poolInfo(uint256)",
 "0x93f1a40b":"userInfo(uint256,address)", "0x18160ddd":"totalSupply()", "0xa0712d68":"mint(uint256)", "0x42966c68":"burn(uint256)",
 "0x40c10f19":"mint(address,uint256)", "0xdb2e21bc":"emergencyWithdraw()", "0xc8796572":"collectFees()", "0xfff6cae9":"sync()",
 "0xbc25cf77":"skim(address)", "0x022c0d9f":"swap(uint256,uint256,address,bytes)", "0x5e0d443f":"get_dy(int128,int128,uint256)",
 "0x556d6e9f":"get_dy(uint256,uint256,uint256)", "0x3883e119":"calc_token_amount(uint256[3],bool)",
 "0x4515cef3":"add_liquidity(uint256[3],uint256)", "0x1a4d01d2":"remove_liquidity_one_coin(uint256,int128,uint256)",
 "0x095ea7b3":"approve(address,uint256)", "0xa9059cbb":"transfer(address,uint256)", "0x70a08231":"balanceOf(address)",
 "0x313ce567":"decimals()", "0x06fdde03":"name()", "0x95d89b41":"symbol()", "0xdd62ed3e":"allowance(address,address)",
 "0x2f4f21e2":"mint(address,uint256,uint256)", "0x276f6228":"claim(uint256)", "0x4e71d92d":"claim()",
 "0x2e1a7d4d":"withdraw(uint256)", "0x9d8b6d3b":"notifyRewardAmount(uint256)", "0x1c4b774b":"getReward(uint256)",
 "0x2d5b2ef8":"deposit(uint256,uint256)", "0x441a3e70":"withdraw(uint256,uint256)", "0x09e2a8ba":"getReward(address)",
 "0x8b876347":"userRewardPerTokenPaid(address)", "0xdf136d65":"lastUpdateTime()", "0xcd3daf9d":"rewardPerToken()",
 "0x7e6e21b5":"stake(uint256)", "0xa694fc3a":"stake(uint256)", "0x2e17de78":"unstake(uint256)",
 "0x7b0a47ee":"rewardRate()", "0x1c1f78d0":"updateReward(address)",
 "0x2a5bd0f1":"swapExactTokensForTokens", "0x38ed1739":"swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
 "0xd0e30db0":"deposit()", "0x2e1a7d4d":"withdraw(uint256)", "0x205c2878":"withdraw(address,uint256)",
 "0x4f1ef286":"upgradeToAndCall(address,bytes)", "0x3659cfe6":"upgradeTo(address)", "0x5c60da1b":"implementation()",
 "0x6e9960c3":"getAdmin()", "0xec44acf2":"getImplementation()", "0x8456cb59":"pause()", "0x3f4ba83a":"unpause()",
 "0x5c975abb":"paused()", "0x1f2dc5ef":"get_virtual_price(uint256)", "0x0bd3cb8b":"redeem(uint256)",
 "0x6e26b9f3":"borrowerOperationsAddress()", "0x7a307d97":"cdpManagerAddress()", "0x8f2e9b3b":"getBorrowingFee()",
 "0x1e0f5e5f":"getRedemptionPrice()", "0x2e35a5cd":"getPrice()", "0x79b5f39b":"setWhitelist(address)",
 "0xc4076876":"whitelist(address)", "0x3c5e3e3d":"whitelisted(address)", "0x15b5d3c5":"updatePrice()",
 "0x82661b5d":"totalStaked()", "0xa2e62045":"update()", "0x8ef7e7f8":"garden(uint256)",
}
CONTRACTS = {
 "0xc90dB0d8713414d78523436dC347419164544A3f":"rose-pool-A(3 stables)",
 "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF":"rose-pool-B(crypto pool)",
 "0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8":"holder-8fe4",
 "0xa34315F1ef49392387Dd143f4578083A9Bd33E94":"holder-a343",
 "0x65a761136815B45A9d78d9781d22d47247B49D23":"holder-65a7",
 "0xe23d2289FBca7De725DC21a13fC096787A85e16F":"stROSE staking",
}
out = {}
for addr, label in CONTRACTS.items():
    code = rpc("eth_getCode", [addr, "latest"]).lower()
    found = {sig: name for sig, name in SIGS.items() if sig in code}
    out[addr] = {"label": label, "len": (len(code)-2)//2, "sigs": found}
    print(f"=== {addr} {label} codelen={(len(code)-2)//2}")
    print("   ", ", ".join(f"{name}" for name in found.values()))
json.dump(out, open("fingerprint.json","w"), indent=1)
