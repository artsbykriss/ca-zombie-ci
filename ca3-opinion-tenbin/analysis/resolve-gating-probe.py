#!/usr/bin/env python3
"""Read-only eth_call with storage overrides to test whether OPINION v5 resolve() is
permissionless on a Disputed resolution. No transactions are sent."""
import json, subprocess
from eth_utils import keccak

RPC = "https://bsc-rpc.publicnode.com"
RESOLVER = "0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4"
Q = "0xb49e409ccddbb9ab2b01d2e2d7ff4a05427b7554f7d71b2c17f97a6a63a6ed3e"
ATTACKER = "0x000000000000000000000000000000000000a11c"

def rpc(method, params):
    out = subprocess.run(["curl","-s","--max-time","30","-X","POST","-H","Content-Type: application/json",
                          "--data",json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}),RPC],
                         capture_output=True,text=True).stdout
    return json.loads(out)

blk = rpc("eth_getBlockByNumber", ["latest", False])["result"]
ts = int(blk["timestamp"], 16)
base = int.from_bytes(keccak(bytes.fromhex(Q[2:]) + (0x161).to_bytes(32, "big")), "big")
W = lambda x: "0x%064x" % x
state = {"stateDiff": {
    W(base + 5): W(1),                       # status = Disputed
    W(base + 8): W(ts + 3600),               # reVoteDeadline in future
    W(base + 9): "0x" + "00"*12 + ATTACKER[2:],  # disputor = attacker
    W(base + 12): W(1000 * 10**18),          # stakedAmount
}}

def enc_resolve(q, arr):
    return ("0xb388b7e7" + q[2:] + (64).to_bytes(32, "big").hex()
            + len(arr).to_bytes(32, "big").hex()
            + "".join(x.to_bytes(32, "big").hex() for x in arr))

data = enc_resolve(Q, [0, 1])
out = {}
for addr, name in [(ATTACKER, "attacker_disputor"),
                   ("0x1111111111111111111111111111111111111111", "random"),
                   ("0xBE39f18621a478354BcA521D89B71770085Fc14e", "operator_eoa")]:
    out[name] = rpc("eth_call", [{"from": addr, "to": RESOLVER, "data": data}, "latest", {RESOLVER: state}])
json.dump(out, open("resolve-gating-result.json", "w"), indent=1)
print(json.dumps(out, indent=1))
