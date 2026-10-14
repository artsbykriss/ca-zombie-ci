#!/usr/bin/env python3
"""Extract PUSH4 selectors from EVM bytecode and look them up (openchain + local map)."""
import re, sys, json, subprocess

KNOWN = {
    # ERC20
    "06fdde03":"name()","95d89b41":"symbol()","313ce567":"decimals()","18160ddd":"totalSupply()",
    "70a08231":"balanceOf(address)","a9059cbb":"transfer(address,uint256)","095ea7b3":"approve(address,uint256)",
    "23b872dd":"transferFrom(address,address,uint256)","dd62ed3e":"allowance(address,address)",
    # ownership / admin
    "8da5cb5b":"owner()","f851a440":"admin()","5aa6e675":"governance()","e30c3978":"pendingOwner()",
    "f2fde38b":"transferOwnership(address)","715018a6":"renounceOwnership()","5c975abb":"paused()",
    "8456cb59":"pause()","3f4ba83a":"unpause()","3659cfe6":"upgradeTo(address)","4f1ef286":"upgradeToAndCall(address,bytes)",
    "8f283970":"changeAdmin(address)","5c60da1b":"implementation()","204e1c7a":"proxyAdmin()",
    # vault-ish
    "b69ef8a8":"balance()","01e1d114":"totalAssets()","6f307dc3":"underlying()","ce7c2ac2":"share()",
    "77c7b8fc":"getPricePerFullShare()","2e1a7d4d":"withdraw(uint256)","b6b55f25":"deposit(uint256)",
    "d0e30db0":"deposit()","e2bbb158":"deposit(uint256,uint256)","441a3e70":"withdraw(uint256,uint256)",
    "2f9b3453":"depositToken()","964b6a72":"lpToken()","72f702f3":"stakingToken()","f7c618c1":"rewardToken()",
    "bab4ca3b":"stakingContract()","4cf088d9":"staking()","6f5f9e6b":"rewardPool()","fbfa77cf":"vault()",
    "1f1fcd51":"want()","a8c62d78":"strategy()","4b1e3a3c":"harvest()","a0712d68":"mint(uint256)",
    "db006a75":"redeem(uint256)","ba087652":"redeem(uint256,address,address)","6e553f65":"deposit(uint256,address)",
    "01b60c7f":"withdraw(uint256,address)","8b4183a4":"withdraw(uint256,address,uint256)",
    # curve v1
    "f446c1d0":"A()","ddca3f43":"fee()","bb7b8b80":"get_virtual_price()","c6610657":"coins(uint256)",
    "4903b0d1":"balances(uint256)","3df02124":"exchange(int128,int128,uint256,uint256)",
    "0b4c7e4d":"add_liquidity(uint256[2],uint256)","4515cef3":"add_liquidity(uint256[3],uint256)",
    "5b36389c":"remove_liquidity(uint256,uint256[2])","ecb586a5":"remove_liquidity(uint256,uint256[3])",
    "1a4d01d2":"remove_liquidity_one_coin(uint256,int128,uint256)","5e0d443f":"get_dy(int128,int128,uint256)",
    "556d6e9f":"get_dy_underlying(int128,int128,uint256)","07211ef7":"get_dy(uint256,uint256,uint256)",
    "e3103273":"get_dy_underlying(uint256,uint256,uint256)","a7cd63b7":"exchange_underlying(int128,int128,uint256,uint256)",
    "0f6ba8e0":"exchange_underlying(uint256,uint256,uint256,uint256)","f3db1e31":"calc_token_amount(uint256[2],bool)",
    "ed8e84f3":"calc_token_amount(uint256[3],bool)","9d26d3b7":"calc_withdraw_one_coin(uint256,int128)",
    "556d6e9f":"get_dy_underlying(int128,int128,uint256)","d8a31c91":"donate_admin_fees()",
    "e3d0aa53":"withdraw_admin_fees()","23746dc7":"ramp_A(uint256,uint256)","42d6f7c0":"stop_ramp_A()",
    "e5e97d11":"commit_new_fee(uint256,uint256)","72b399a1":"apply_new_fee()","39b35759":"revert_new_parameters()",
    "1f8f1a48":"admin_balances(uint256)","dde3e9e0":"admin_fee()","5d1a3b82":"kill_me()","b02f0e91":"unkill_me()",
    "7b6c42e6":"set_admin(address)","3ccfd60b":"withdraw()",
    # masterchef
    "1526fe27":"poolInfo(uint256)","93f1a40b":"userInfo(uint256,address)","e2bbb158":"deposit(uint256,uint256)",
    "5312ea8e":"emergencyWithdraw(uint256)","c7e3b1d6":"pendingEKL(uint256,address)","b9b1f4e0":"updatePool(uint256)",
    "b88a802f":"claimReward()","379607f5":"claim(uint256)","6fc9d4ee":"claimRewards()",
    "2f940c70":"withdraw(uint256)","1959a002":"userInfo(address)","f77c4791":"controller()",
    "570ca735":"operator()","893d20e8":"getOwner()","6e26b5c6":"addPool(uint256,address)",
}

def extract_selectors(hexcode):
    b = bytes.fromhex(hexcode[2:] if hexcode.startswith("0x") else hexcode)
    sels = set()
    for i in range(len(b) - 4):
        if b[i] == 0x63:  # PUSH4
            sels.add(b[i+1:i+5].hex())
    return sels

def openchain_lookup(sels):
    out = {}
    try:
        r = subprocess.run(["curl","-s","-m","30","-X","POST","-H","Content-Type: application/json",
                            "-d", json.dumps({"function": list(sels)[:400]}),
                            "https://api.openchain.xyz/signature-database/v1/lookup?filter=true"],
                           capture_output=True, text=True, timeout=60)
        d = json.loads(r.stdout)
        for s, v in d.get("result", {}).get("function", {}).items():
            if v: out[s] = v[0]["name"]
    except Exception as e:
        print("openchain failed:", e, file=sys.stderr)
    return out

if __name__ == "__main__":
    path = sys.argv[1]
    raw = open(path).read().strip()
    hexcode = json.loads(raw).get("result") if raw.startswith("{") else raw
    sels = sorted(extract_selectors(hexcode))
    print(f"{len(sels)} unique PUSH4 constants")
    named = {s: KNOWN[s] for s in sels if s in KNOWN}
    unknown = [s for s in sels if s not in KNOWN]
    print("== known ==")
    for s, n in sorted(named.items(), key=lambda x: x[1]):
        print(f"  0x{s} {n}")
    if unknown:
        print(f"== looking up {len(unknown)} unknown via openchain ==")
        oc = openchain_lookup(unknown)
        for s in unknown:
            print(f"  0x{s} {oc.get(s, '(unknown)')}")
