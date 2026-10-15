#!/usr/bin/env python3
"""Read-only batch eth_call helper with retries. No keys, no signing."""
import json, urllib.request, time, sys

RPC = "https://filecoin.blockscout.com/api/eth-rpc"
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, tries=4):
    last = None
    for i in range(tries):
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(RPC, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read().decode())
            return out.get("result", out.get("error"))
        except Exception as e:
            last = str(e)
            time.sleep(2 + i * 2)
    return "RPCFAIL: " + str(last)

def call(to, selector, arg=None, block="latest"):
    return rpc("eth_call", [{"to": to, "data": selector + (arg or "")}, block])

def pad(addr):
    return addr.lower().replace("0x", "").rjust(64, "0")

def main():
    POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
    WFIL = "0x60E1773636CF5E4A227d9AC24F20fEca034ee25A"
    STFIL = "0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8"
    SEL = {
        "name": "0x06fdde03", "symbol": "0x95d89b41", "decimals": "0x313ce567",
        "totalSupply": "0x18160ddd", "getCash": "0x3b1d21a2", "totalBorrows": "0x47bd3718",
        "totalReserves": "0x8f840ddd", "exchangeRateStored": "0x182df0f5",
        "accrualBlockNumber": "0x6c540baf", "underlying": "0x6f307dc3",
        "comptroller": "0xf77c4791", "interestRateModel": "0xf3fdb15a",
        "admin": "0xf851a440", "reserveFactorMantissa": "0x173b9904",
        "exchangeRateCurrent": "0xbd6d894d", "pendingAdmin": "0x26782247",
        "owner": "0x8da5cb5b", "borrowRatePerBlock": "0xf8f9da28",
    }
    out = {"block": rpc("eth_blockNumber", []), "calls": {}}
    for k, s in SEL.items():
        out["calls"][k] = call(POOL, s)
        sys.stderr.write(k + " done\n"); sys.stderr.flush()
    for h in ["0x037BC5D2998Fa68ea24b96D110dFe5eb2b2331C9",
              "0x92Fbb9Fc50074ACAb80554ccF4b19646bFDB8f00",
              "0xDC465DB89Dc7ACc3DA000480c060afE934ccBf5E"]:
        out["calls"]["balanceOf_" + h] = call(POOL, "0x70a08231", pad(h))
    out["eip1967_impl_slot"] = rpc("eth_getStorageAt", [POOL, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])
    out["eip1967_admin_slot"] = rpc("eth_getStorageAt", [POOL, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103", "latest"])
    out["wfil_balanceOf_pool"] = call(WFIL, "0x70a08231", pad(POOL))
    out["stfil_balanceOf_pool"] = call(STFIL, "0x70a08231", pad(POOL))
    out["stfil_totalSupply"] = call(STFIL, "0x18160ddd")
    out["stfil_name"] = call(STFIL, "0x06fdde03")
    out["stfil_symbol"] = call(STFIL, "0x95d89b41")
    out["stfil_decimals"] = call(STFIL, "0x313ce567")
    out["stfil_impl_slot"] = rpc("eth_getStorageAt", [STFIL, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])
    out["stfil_admin_slot"] = rpc("eth_getStorageAt", [STFIL, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103", "latest"])
    out["pool_balance"] = rpc("eth_getBalance", [POOL, "latest"])
    for a in ["0xFA33F3866e7eF32F79734BCC5e011d767F8E574b",
              "0xcf89b3a29499229e35d4fe71dfe54bec2c1eba48",
              "0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81",
              "0x06A4c6527fD462c4fD55664861437bC6D417FFA3"]:
        out["balance_" + a] = rpc("eth_getBalance", [a, "latest"])
        code = rpc("eth_getCode", [a, "latest"])
        out["code_len_" + a] = (len(code) - 2) // 2 if isinstance(code, str) and code.startswith("0x") else code
    json.dump(out, open("batch_calls_out.json", "w"), indent=1)
    print("DONE block", out["block"])

if __name__ == "__main__":
    main()
