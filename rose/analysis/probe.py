#!/usr/bin/env python3
"""Comprehensive on-chain probe of Rose (Aurora). Read-only, keyless RPC."""
import json, urllib.request, time, sys

RPC = "https://mainnet.aurora.dev"
def rpc(method, params, retries=3):
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                         headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=30))
            if "result" in r: return r["result"]
            print("RPCERR", r, file=sys.stderr)
        except Exception as e:
            print("ERR", e, file=sys.stderr); time.sleep(1)
    return None

def call(to, data, block="latest"):
    return rpc("eth_call", [{"to":to, "data":data}, block])

def u(x): return int(x,16) if x and x!="0x" else None
def addr(x): return "0x"+x[-40:] if x and len(x)>=42 else None

def word(x, i):  # i-th 32-byte word
    if not x or len(x) < 2+64*(i+1): return None
    return x[2+64*i:2+64*(i+1)]

SEL = {
 "name":"0x06fdde03","symbol":"0x95d89b41","decimals":"0x313ce567","totalSupply":"0x18160ddd",
 "balanceOf":"0x70a08231","coins":"0xc6610657","balances":"0x4903b0d1","A":"0xf446c1d0","A_precise":"0x76a2f0f0",
 "fee":"0xddca3f43","admin_fee":"0xfee3f7f9","owner":"0x8da5cb5b","admin":"0xf851a440",
 "lp_token":"0x82c63066","fee_receiver":"0xcab4d3db","token":"0xfc0c546a","get_virtual_price":"0xbb7b8b80",
 "base_pool":"0x6d5b0d0b","base_coins":"0x87cb4f57","base_virtual_price":"0x95ccc02f",
 "future_owner":"0x1ec0cdc1","future_A":"0xb4b577ad","initial_A":"0x5409491a","future_fee":"0x58680d0b",
 "admin_actions_deadline":"0x405e28f8","transfer_ownership_deadline":"0xe0a0b586",
 "kill_me":"0xe3698853","unkill_me":"0x3046f972","paused":"0x5c975abb",
 "price_oracle":"0x86fc88d3","price_scale":"0xb9e8c9fd","last_prices":"0x59189017",
 "rewardRate":"0x7b0a47ee","periodFinish":"0xebe2b12b","stakingToken":"0x72f702f3","rewardToken":"0xf7c618c1",
 "pendingOwner":"0xe30c3978","implementation":"0x5c60da1b",
 # bentobox
 "masterContractOf":"0xbafe4f14","whitelistedMasterContracts":"0x12a90c8a","totals":"0x4ffe34db",
 "strategy":"0x228bfd9f","pendingStrategy":"0x5108a558","toAmount":"0x56623118","toShare":"0xda5139ca",
 "registeredProtocol":"0x","users":"0xa87430ba","userRewardPerTokenPaid":"0x8b876347",
}
ZERO = "0x"+"0"*64
ONE = "0x"+"0"*63+"1"

def call_u(to, sel, arg=None):
    d = SEL[sel] + (arg[2:] if arg and arg.startswith("0x") else (arg or ""))
    return u(call(to, d))

def call_a(to, sel, arg=None):
    d = SEL[sel] + (arg[2:] if arg and arg.startswith("0x") else (arg or ""))
    return addr(call(to, d))

def call_str(to, sel):
    r = call(to, SEL[sel])
    if not r or len(r) < 130: return None
    try:
        if r[2:66] == "0"*64:  # dynamic string
            ln = int(r[66:130],16); return bytes.fromhex(r[130:130+ln*2]).decode('utf8','replace')
        else:
            return bytes.fromhex(r[2:66].rstrip('0')).decode('utf8','replace')
    except Exception:
        return None

block = u(rpc("eth_blockNumber", []))
print("AURORA BLOCK:", block)
tokens = {
 "0xb12bfca5a55806aaf64e99521918a4bf0fc40802":"USDC?",
 "0x4988a896b1227218e4a686fde5eabdcabd91571f":"USDT?",
 "0xe3520349F477A5F6EB06107066048508498A291b":"DAI?",
 "0xc42c30ac6cc15fac9bd938618bcaa1a1fae8501d":"WNEAR?",
 "0xc9bdeed33cd01541e1eed10f90519d2c06fe3feb":"WETH?",
 "0xf4eb217ba2454613b15dbdea6e5f22276410e89e":"WBTC?",
 "0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC":"tok5ce9?",
 "0xda2585430fef327ad8ee44af8f1f989a2a91a3d2":"tokda25?",
 "0xdfa46478f9e5ea86d57387849598dbfb2e964b02":"tokdfa4?",
 "0xdcd6d4e2b3e1d1e1e6fa8c21c8a323dcbecff970":"tokdcd6?",
}
print("\n=== TOKENS ===")
for t, lab in tokens.items():
    print(f"{t} {lab}: name={call_str(t,'name')!r} symbol={call_str(t,'symbol')!r} dec={call_u(t,'decimals')} supply={call_u(t,'totalSupply')}")
json.dump({"block":block}, open("probe_block.json","w"))
