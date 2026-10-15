#!/usr/bin/env python3
"""Fetch code bytes of related contracts and scan for protocol strings. Read-only."""
import json, urllib.request, time, re

ENDPOINTS = ["https://api.node.glif.io/rpc/v1", "https://filecoin.chainup.net/rpc/v1",
             "https://filecoin.blockscout.com/api/eth-rpc"]
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, tries=4):
    last = None
    for i in range(tries):
        ep = ENDPOINTS[min(i, len(ENDPOINTS) - 1)]
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read().decode())
            if "error" in out:
                last = out["error"]; time.sleep(1); continue
            return out.get("result")
        except Exception as e:
            last = str(e); time.sleep(2 + 2 * i)
    return "RPCFAIL:" + str(last)

ADDRS = {
    "comptroller_proxy_FA33": "0xFA33F3866e7eF32F79734BCC5e011d767F8E574b",
    "FA33_impl_D3A8": "0xD3A8DCbada627FBE5E21eF224486Af4412c80aDF",
    "FA33_prev_impl_13ce": "0x13ce9eB145a40b14B721570F0A91fc97656807DC",
    "arg4_E1DA": "0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81",
    "controller_10D81c": "0x10D81c7a15da6218F475b82eBFD638CFC3Cf36a5",
    "unknown_980Ce3": "0x980Ce3B4160bBF030E436B006634e4Da963Be72F",
    "upgradeTarget_45D000": "0x45D000319ac5BcBbf4C76799FbFd3045EBBE9b09",
    "new_8f468C": "0x8f468C3e8A124376272F4042858a302c1634D5bc",
    "created_e0Fd99": "0xe0Fd99db9Fc427344c80B4d7a548b5fE2E788d0b",
    "owner_7E1cE9": "0x7E1cE9e8be1E372280B23D4635F38293E5bdDAF2",
    "wfIL_60E1": "0x60E1773636CF5E4A227d9AC24F20fEca034ee25A",
    "stFIL_3C35": "0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8",
}

def main():
    res = {}
    for name, a in ADDRS.items():
        code = rpc("eth_getCode", [a, "latest"])
        if isinstance(code, str) and code.startswith("0x") and len(code) > 2:
            b = bytes.fromhex(code[2:])
            strs = [m.group().decode(errors="replace") for m in re.finditer(rb"[ -~]{6,}", b)]
            hits = [s for s in strs if re.search(r"HashMix|hashmix|stFIL|cWFIL|hsm|FIL|Stake|stake|ERC20", s)]
            res[name] = {"addr": a, "code_bytes": len(b), "strings_hits": hits[:40], "n_strings": len(strs)}
        else:
            res[name] = {"addr": a, "code": str(code)[:80]}
        json.dump(res, open("related_contracts_code_scan.json", "w"), indent=1)
        print(name, a, res[name].get("code_bytes"), "->", res[name].get("strings_hits", res[name].get("code")), flush=True)
        time.sleep(2)

if __name__ == "__main__":
    main()
