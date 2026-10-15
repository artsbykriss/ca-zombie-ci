#!/usr/bin/env python3
"""Dump ASCII strings from key contract code via ankr. Read-only."""
import json, urllib.request, re, time

EPS = ["https://rpc.ankr.com/filecoin", "https://api.chain.love/rpc/v1", "https://api.node.glif.io/rpc/v1"]
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, tries=6):
    last = None
    for i in range(tries):
        ep = EPS[i % len(EPS)]
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read().decode())
            res = out.get("result")
            if res is None:
                last = str(out.get("error"))[:90]; time.sleep(1.5); continue
            return res
        except Exception as e:
            last = str(e)[:90]; time.sleep(2)
    return None

ADDRS = {
    "controllerImpl_D3A8": "0xD3A8DCbada627FBE5E21eF224486Af4412c80aDF",
    "IRM_E1DA": "0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81",
    "newImpl_8f468C": "0x8f468C3e8A124376272F4042858a302c1634D5bc",
    "proxyAdmin_13ce": "0x13ce9eB145a40b14B721570F0A91fc97656807DC",
    "proxyAdmin_45D000": "0x45D000319ac5BcBbf4C76799FbFd3045EBBE9b09",
    "WFIL_60E1": "0x60E1773636CF5E4A227d9AC24F20fEca034ee25A",
    "stFILImpl_F1ec": "0xF1eca87AC159a1132554124A89f4778100cc0ecc",
    "stake_980Ce3": "0x980Ce3B4160bBF030E436B006634e4Da963Be72F",
    "e0Fd99": "0xe0Fd99db9Fc427344c80B4d7a548b5fE2E788d0b",
    "358Cc9": "0x358Cc936fc3035A49E02d670Ec9b8E0061E97979",
}

def main():
    out = {}
    for name, a in ADDRS.items():
        c = rpc("eth_getCode", [a, "latest"])
        if isinstance(c, str) and c.startswith("0x") and len(c) > 2:
            b = bytes.fromhex(c[2:])
            strs = [m.group().decode(errors="replace") for m in re.finditer(rb"[ -~]{5,}", b)]
            out[name] = {"addr": a, "code_bytes": len(b), "strings": strs}
        else:
            out[name] = {"addr": a, "code": str(c)[:60]}
        json.dump(out, open("strings_dump.json", "w"), indent=1)
        print(name, a, out[name].get("code_bytes"), flush=True)
        time.sleep(1)

if __name__ == "__main__":
    main()
