#!/usr/bin/env python3
"""eth_call gate probes from a random unprivileged EOA (no tx sent).
Random EOA: 0x00000000000000000000000000000000DeaDBeef
"""
import json, urllib.request, time, os, sys

RPC = os.environ.get("BSC_PUBLIC_RPC", "https://bsc-rpc.publicnode.com")
ATTACKER = "0x00000000000000000000000000000000DeaDBeef"


def call(m, p, tries=5):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    last = None
    for i in range(tries):
        try:
            r = urllib.request.Request(RPC, data=b, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            return json.loads(urllib.request.urlopen(r, timeout=40).read())
        except Exception as e:
            last = e
            time.sleep(1.5 * (i + 1))
    return {"error": str(last)}


def probe(name, to, data, frm=ATTACKER):
    d = call("eth_call", [{"from": frm, "to": to, "data": data}, "latest"])
    if "result" in d:
        res = d["result"]
        print(f"{name}: OK -> {res[:74]}")
        return ("ok", res)
    err = d.get("error", {})
    print(f"{name}: REVERT -> {json.dumps(err)[:220]}")
    return ("revert", err)


def enc_addr(a):
    return "0" * 24 + a[2:]


def enc_u(x):
    return hex(x)[2:].rjust(64, "0")


if __name__ == "__main__":
    bn = int(call("eth_blockNumber", [])["result"], 16)
    print("block", bn, "attacker", ATTACKER)
    NS = "0x33f1c4fbb7e4e040f4f4e6bc492e4fedf750fd41"
    DMD = "0x939df4a5a5022037bb33102c6489e774e063b160"
    BT = "0xb1939843fb9220719d13076dceefb0aeaef06666"
    PAIR_BT = "0x3cc292bb0011951f3151eb998816c31680a2ce87"
    ROUTER = "0x10ed43c718714eb63d5aa57b78b54704e256024e"
    WBNB = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
    WBTC = "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c"

    # NS: burnNsFromPair(uint256) 0x29150a1e  -- gated by pairBurnOperator
    probe("NS.burnNsFromPair(500)", NS, "0x29150a1e" + enc_u(500))
    probe("NS.burnNsFromPair(1)", NS, "0x29150a1e" + enc_u(1))
    # NS: public burn(uint256) 0x42966c68 -- caller-only burn (permissionless but self-burn)
    probe("NS.burn(1e18)", NS, "0x42966c68" + enc_u(10**18))
    # NS: setPairBurnOperator(address) 0x... onlyGovernance
    print("setPairBurnOperator sig", )

    # DMD: burnFromMainPair() 0xa9292e84 -- onlyAdmin
    probe("DMD.burnFromMainPair()", DMD, "0xa9292e84")
    # DMD: setAdmin(address) onlyOwner
    # DMD: injectLiquidity() onlyOwner

    # BT: buy via router (swapExactETHForTokens) -> expect T0 revert on pair->buyer transfer
    path = enc_addr(WBNB) + enc_addr(BT)
    data = ("0x7ff36ab5"  # swapExactETHForTokens
            + enc_u(0) + enc_u(32) + enc_addr(ATTACKER) + enc_u(10**17))
    # correct ABI: swapExactETHForTokens(uint amountOutMin, address[] path, address to, uint deadline)
    data = ("0x7ff36ab5" + enc_u(0) + enc_u(128) + enc_addr(ATTACKER) + enc_u(2**32)
            + enc_u(2) + enc_addr(WBNB) + enc_addr(BT))
    d = call("eth_call", [{"from": ATTACKER, "to": ROUTER, "data": data, "value": hex(10**17)}, "latest"])
    print("BT router swapExactETHForTokens (buy):", json.dumps(d)[:300])
