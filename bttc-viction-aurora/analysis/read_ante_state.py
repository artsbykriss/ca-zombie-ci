#!/usr/bin/env python3
"""Read live state of the Aurora Ante pool using the real v0.5 ABI. Read-only."""
import sys, json, subprocess
sys.path.insert(0, '/home/heisenberg/CA/bttc-viction-aurora/analysis')
from rpclib import *

POOL = "0xa32046e096fac0ad197089f22103d6c76dc9b684"
FACTORY = "0xb4FD0Ce108e196d0C9844c48174d4C32Cd42F7bC"

def keccak(sig):
    return subprocess.run(["cast", "keccak", sig], capture_output=True, text=True).stdout.strip()

ABI = json.load(open('/tmp/opencode/ante/AntePoolV2.json'))
SELS = {}
for e in ABI:
    if e.get('type') == 'function':
        ins = ",".join(i['type'] for i in e.get('inputs', []))
        sig = f"{e['name']}({ins})"
        SELS[e['name']] = keccak(sig)[:10]

def call(name, args=()):
    data = SELS[name] + "".join(pad32(a) for a in args)
    try:
        return eth_call("aurora", POOL, data)
    except Exception as e:
        return f"ERR:{str(e)[:100]}"

if __name__ == "__main__":
    bn = block_number("aurora")
    print("aurora block:", bn)
    out = {"block": bn, "pool": POOL}
    simple = ["anteTest", "factory", "pendingFailure", "numTimesVerified", "failedBlock",
              "lastVerifiedBlock", "verifier", "numPaidOut", "totalPaidOut",
              "getTotalStaked", "getTotalChallengerStaked", "getTotalPendingWithdraw",
              "getTotalChallengerEligibleBalance", "getVerifierBounty", "lastUpdateBlock"]
    for name in simple:
        r = call(name)
        out[name] = r
        if isinstance(r, str) and r.startswith("0x") and len(r) == 66:
            v = int(r, 16)
            print(f"{name:38s} = {v}  (0x{v:x})")
            if name in ("anteTest", "verifier", "factory"):
                print(f"{'':38s}   addr {dec_addr(r)}")
        else:
            print(f"{name:38s} = {r}")
    # struct getters
    r = call("stakingInfo")
    if isinstance(r, str) and r.startswith("0x"):
        words = [int(r[2+i*64:2+(i+1)*64], 16) for i in range(len(r[2:])//64)]
        print("stakingInfo:", words)
        out["stakingInfo"] = words
    r = call("challengerInfo")
    if isinstance(r, str) and r.startswith("0x"):
        words = [int(r[2+i*64:2+(i+1)*64], 16) for i in range(len(r[2:])//64)]
        print("challengerInfo:", words)
        out["challengerInfo"] = words
    r = call("eligibilityInfo")
    if isinstance(r, str) and r.startswith("0x"):
        words = [int(r[2+i*64:2+(i+1)*64], 16) for i in range(len(r[2:])//64)]
        print("eligibilityInfo:", words)
        out["eligibilityInfo"] = words
    out["pool_balance_wei"] = get_balance("aurora", POOL)
    print("pool ETH balance:", out["pool_balance_wei"] / 1e18)
    # check the test
    test = dec_addr(out["anteTest"]) if isinstance(out["anteTest"], str) else None
    if test:
        print("test contract:", test)
        code = get_code("aurora", test)
        print("test code len:", len(code or "0x"))
        try:
            r = eth_call("aurora", test, keccak("checkTestPasses()")[:10])
            print("checkTestPasses() ->", r)
            out["checkTestPasses_raw"] = r
            out["checkTestPasses"] = bool(int(r, 16)) if r and r != "0x" else None
        except Exception as e:
            print("checkTestPasses() REVERTS ->", str(e)[:120])
            out["checkTestPasses"] = "REVERT"
        try:
            r = eth_call("aurora", test, keccak("testName()")[:10])
            print("testName() ->", r[:200])
            out["testName_raw"] = r
        except Exception as e:
            print("testName() ERR", str(e)[:100])
    json.dump(out, open('/home/heisenberg/CA/bttc-viction-aurora/analysis/aurora_ante_state.json', 'w'), indent=2)
