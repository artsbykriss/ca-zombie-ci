#!/usr/bin/env python3
"""Read-only negative security tests against live Enosys V3 (Flare). Saves exact calls/results."""
import json, time
import rpc

CH = 14
FACTORY = "0x17aa157ac8c54034381b840cb8f6bf7fc355f0de"
NPM = "0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657"
POOL = "0x3c2a7b76795e58829faaa034486d417dd0155162"
DUST = "0xf15f6790031d2916a6a00ff59fcaeba012a06c0d"
TRACKER = "0x5646f8f757ed7238f28ae930ab7e1d806413df36"
FTSO = "0x5a0BfF8Ff1AF1DF28619Fce57d07E3bBb7BAF3d7"
ATT = "0x000000000000000000000000000000000000dEaD"
OWNER1 = "0x2417c9a1cebb33046fb0cdef5c1a8992c2622093"
MAX128 = (1 << 128) - 1


def enc_bytes(h):
    h = h[2:] if h.startswith("0x") else h
    pad = (64 - (len(h) % 64)) % 64
    return f"{32:064x}" + f"{len(h)//2:064x}" + h + "0" * pad


def enc_arr(vals):
    return f"{32:064x}" + f"{len(vals):064x}" + "".join(f"{v:064x}" for v in vals)


def try_call(name, to, data, frm=ATT):
    try:
        r = rpc.rpc(CH, "eth_call", [{"to": to, "data": data, "from": frm, "gas": "0x5f5e100"}, "latest"])
        return {"test": name, "to": to, "from": frm, "data": data, "result": "success", "return": r[:200]}
    except Exception as e:
        msg = str(e)
        reason = None
        if "data': '0x08c379a0" in msg:
            try:
                hx = msg.split("data': '0x08c379a0")[1].split("'")[0]
                ln = int(hx[64:128], 16)
                reason = bytes.fromhex(hx[128:128 + ln * 2]).decode()
            except Exception:
                pass
        custom = None
        if "data': '0x" in msg and reason is None:
            custom = msg.split("data': '")[1][:10]
        return {"test": name, "to": to, "from": frm, "data": data, "result": "revert",
                "reason": reason, "custom_error": custom, "raw": msg[:300]}


out = {"read_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "chain": CH, "tests": []}
blk = rpc.block(CH)
out["block"] = blk

# pool mint with no callback payment (EOA caller; callback call to EOA "succeeds", balance check must fail)
# mint(recipient, tickLower=-600, tickUpper=600, liquidity=1e18, data="")
data = "0x3c8a7d8d" + f"{int(ATT,16):064x}" + f"{(1<<256)-600:064x}" + f"{600:064x}" + f"{10**18:064x}" + f"{160:064x}" + "0"*64
out["tests"].append(try_call("pool.mint no callback payment", POOL, data))

# swap exact-output 1e6 token0, zeroForOne, limit MIN+1
data = "0x128acb08" + f"{int(ATT,16):064x}" + f"{1:064x}" + f"{(1<<256)-10**6:064x}" + f"{4295128740:064x}" + f"{160:064x}" + "0"*64
out["tests"].append(try_call("pool.swap no callback payment", POOL, data))

# flash 1e6 token0, no repayment
data = "0x490e6cbc" + f"{int(ATT,16):064x}" + f"{10**6:064x}" + f"{0:064x}" + f"{128:064x}" + "0"*64
out["tests"].append(try_call("pool.flash no repayment", POOL, data))

# collectProtocol from non-factory
data = "0x85b66729" + f"{int(ATT,16):064x}" + f"{MAX128:064x}" + f"{MAX128:064x}"
out["tests"].append(try_call("pool.collectProtocol unauthorized", POOL, data))

# setFeeProtocol from non-factory
data = "0x8206a4d1" + f"{10:064x}" + f"{10:064x}"
out["tests"].append(try_call("pool.setFeeProtocol unauthorized", POOL, data))

# resetupDelegations from non-factory
out["tests"].append(try_call("pool.resetupDelegations unauthorized", POOL, "0xdbb9a17f"))

# NPM collect token 1 from non-owner
data = "0xfc6f7865" + f"{1:064x}" + f"{int(ATT,16):064x}" + f"{MAX128:064x}" + f"{MAX128:064x}"
out["tests"].append(try_call("NPM.collect non-owner", NPM, data))

# NPM collect token 1 from owner (control)
out["tests"].append(try_call("NPM.collect owner control", NPM, data, OWNER1))

# NPM burn token 1 from non-owner
out["tests"].append(try_call("NPM.burn non-owner", NPM, "0x42966c68" + f"{1:064x}"))

# factory admin from non-owner
out["tests"].append(try_call("factory.setPoolImplementation unauthorized", FACTORY, "0xd6f74898" + f"{int(ATT,16):064x}"))
out["tests"].append(try_call("factory.transferOwnership unauthorized", FACTORY, "0xf2fde38b" + f"{int(ATT,16):064x}"))
out["tests"].append(try_call("factory.setGovernor unauthorized", FACTORY, "0xc42cf535" + f"{int(ATT,16):064x}"))

# permissionless protocol fee collection (fixed receiver)
out["tests"].append(try_call("factory.collectProtocolFeesAll permissionless", FACTORY, "0xfcd5bbe8"))

# tracker write from non-role
data = "0x75b2e9d8" + f"{1:064x}" + f"{10**30:064x}" + "0"*64 + "0"*64
out["tests"].append(try_call("tracker.updateLiquiditySnapshots non-role", TRACKER, data))

# FTSO claim for token 1 from non-owner
data = "0x8c574b48" + enc_arr([1]) + f"{int(ATT,16):064x}"
out["tests"].append(try_call("FTSO.claim non-owner", FTSO, data))
out["tests"].append(try_call("FTSO.claim owner control", FTSO, data, OWNER1))

# dust pool initialize(price=1) by anyone
data = "0xf637731d" + f"{2**96:064x}"
out["tests"].append(try_call("dust pool initialize(1.0) permissionless", DUST, data))

# public delegate() is harmless re-delegation
out["tests"].append(try_call("pool.delegate permissionless", POOL, "0xc89e4361"))

json.dump(out, open("security_tests.json", "w"), indent=1)
print("block", blk)
for t in out["tests"]:
    print(t["test"], "->", t["result"], t.get("reason") or t.get("custom_error") or "")
