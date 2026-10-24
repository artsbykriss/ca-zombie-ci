#!/usr/bin/env python3
"""Read-only live-state reader for TOPS (BSC). Uses only keyless public RPCs.
No secrets. Requires browser User-Agent (public nodes 403 otherwise)."""
import json, sys, urllib.request

RPC = sys.argv[1] if len(sys.argv) > 1 else "https://bsc-rpc.publicnode.com"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0 Safari/537.36")

TOKEN = "0x842b1bfa825cf6673fd2d98e573fdd267c3fd588"
PAIR  = "0xbedebac3788171dc769893242a53b881041edf29"

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","method":method,"params":params,"id":1}).encode()
    req = urllib.request.Request(RPC, data=body,
        headers={"Content-Type":"application/json","User-Agent":UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())["result"]

def call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])

def pad(addr):
    return addr.lower().replace("0x","").rjust(64,"0")

def dec_uint(hexstr):
    return int(hexstr,16) if hexstr and hexstr != "0x" else 0

def dec_string(hexstr):
    if not hexstr or hexstr == "0x": return None
    b = bytes.fromhex(hexstr[2:])
    try:
        if len(b) >= 64:
            off = int.from_bytes(b[0:32],"big")
            ln = int.from_bytes(b[off:off+32],"big")
            return b[off+32:off+32+ln].decode("utf-8","replace")
        return b.rstrip(b"\x00").decode("utf-8","replace")
    except Exception:
        return None

def main():
    bn = dec_uint(rpc("eth_blockNumber", []))
    print(f"RPC={RPC}  latest_block={bn}")
    out = {"rpc": RPC, "latest_block": bn, "token": TOKEN, "pair": PAIR}

    t0 = call(PAIR, "0x0dfe1681")
    t1 = call(PAIR, "0xd21220a7")
    res = call(PAIR, "0x0902f1ac")
    out["token0"] = "0x"+t0[-40:]
    out["token1"] = "0x"+t1[-40:]
    if res and len(res) >= 2+192:
        r = res[2:]
        out["reserve0"] = dec_uint("0x"+r[0:64])
        out["reserve1"] = dec_uint("0x"+r[64:128])
        out["blockTimestampLast"] = dec_uint("0x"+r[128:192])

    out["token_totalSupply"] = dec_uint(call(TOKEN, "0x18160ddd"))
    out["token_balanceOf_pair"] = dec_uint(call(TOKEN, "0x70a08231"+pad(PAIR)))
    out["token_name"] = dec_string(call(TOKEN, "0x06fdde03"))
    out["token_symbol"] = dec_string(call(TOKEN, "0x95d89b41"))
    out["token_decimals"] = dec_uint(call(TOKEN, "0x313ce567"))
    out["pair_totalSupply"] = dec_uint(call(PAIR, "0x18160ddd"))

    # roles / admin probes (ignore reverts)
    for name, sel in [("owner","0x8da5cb5b"),("admin","0xf851a440"),
                      ("getOwner","0x893d20e8"),("guardian","0x452a9320"),
                      ("controller","0xf77c4791")]:
        try:
            v = call(TOKEN, sel)
            out[f"token_{name}"] = "0x"+v[-40:] if v and len(v)>=42 else None
        except Exception as e:
            out[f"token_{name}"] = f"revert/err"

    # pair factory
    try:
        f = call(PAIR, "0xc45a0155")
        out["pair_factory"] = "0x"+f[-40:]
    except Exception:
        out["pair_factory"] = None

    # token code size
    code = rpc("eth_getCode", [TOKEN, "latest"])
    out["token_code_size"] = (len(code)-2)//2
    pcode = rpc("eth_getCode", [PAIR, "latest"])
    out["pair_code_size"] = (len(pcode)-2)//2

    # selector presence in token runtime bytecode
    sels = {"sync()":"fff6cae9","skim(address)":"bc25cf77","getReserves()":"0902f1ac",
            "recycle(uint256)":"dd1c35bc","flushLpSellRecycle()":"bbafc98c",
            "burnFromPool(uint256)":"87ed238a","flush()":"6b9f96ea"}
    out["token_selector_presence"] = {k: (v in code.lower()) for k,v in sels.items()}

    print(json.dumps(out, indent=2))
    with open("/home/heisenberg/CA/tops/analysis/livestate.json","w") as fh:
        json.dump(out, fh, indent=2)

main()
