#!/usr/bin/env python3
"""Decode viewer tokenInfoDetail/farmInfos responses. Read-only."""
import json, urllib.request, sys

RPC = "https://klaytn.drpc.org"
V = "0x2B16648ddD1559fc86e0c0617213Ab5dd2Ea01B9"

def call(data, to=V, tries=5):
    body = json.dumps({"jsonrpc": "2.0", "method": "eth_call", "params": [{"to": to, "data": data}, "latest"], "id": 1}).encode()
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as r:
                d = json.loads(r.read().decode())
            if "result" in d:
                return d["result"]
            err = d.get("error", {})
            if "reverted" in str(err):
                raise RuntimeError("reverted")
        except RuntimeError:
            raise
        except Exception:
            pass
    raise RuntimeError("rpc fail")

def sel(sig):
    import subprocess
    return subprocess.run(["cast", "sig", sig], capture_output=True, text=True).stdout.strip()

def word(x):
    return hex(x)[2:].rjust(64, "0")

def rd_str(h, off):
    """read dynamic string at byte offset off (hex chars)"""
    ln = int(h[off:off+64], 16)
    data = h[off+64:off+64+ln*2]
    return bytes.fromhex(data).decode("utf-8", "ignore")

def decode_token_info_detail(h):
    h = h[2:]
    info_off = int(h[0:64], 16) * 2
    price = int(h[64:128], 16)
    # tuple at info_off: (address token, string name, string symbol, uint8 decimals, uint256 totalSupply)
    token = "0x" + h[info_off+24:info_off+64]
    name_off = info_off + int(h[info_off+64:info_off+128], 16) * 2
    sym_off = info_off + int(h[info_off+128:info_off+192], 16) * 2
    decimals = int(h[info_off+192:info_off+256], 16)
    total = int(h[info_off+256:info_off+320], 16)
    return {"token": token, "name": rd_str(h, name_off), "symbol": rd_str(h, sym_off),
            "decimals": decimals, "totalSupply": total, "price_raw": price, "price": price / 1e18}

def decode_farm_infos(h):
    h = h[2:]
    list_off = int(h[0:64], 16) * 2
    cfg_off = int(h[64:128], 16) * 2
    n = int(h[list_off:list_off+64], 16)
    rows = []
    for i in range(n):
        o = list_off + 64 + i * 5 * 64
        rows.append({"pool": "0x" + h[o+24:o+64], "totalLP": int(h[o+64:o+128], 16),
                     "allocPoint": int(h[o+128:o+192], 16), "lastRewardBlock": int(h[o+192:o+256], 16),
                     "accRewardPerShare": int(h[o+256:o+320], 16)})
    cfg = {}
    names = ["attenTotalAllocPoint", "attenFarmStartBlock", "attenFarmEndBlock", "attenPerBlock",
             "attenBonusMultiplier", "palaTotalAllocPoint", "palaFarmStartBlock", "palaPerBlock", "palaBonusMultiplier"]
    for i, nm in enumerate(names):
        cfg[nm] = int(h[cfg_off+i*64:cfg_off+(i+1)*64], 16)
    return {"n_pools": n, "pools": rows, "config": cfg}

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "token":
        for a in sys.argv[2:]:
            try:
                r = decode_token_info_detail(call(sel("tokenInfoDetail(address)") + word(int(a, 16))))
                print(json.dumps(r))
            except Exception as e:
                print(json.dumps({"token": a, "error": str(e)}))
    elif cmd == "farm":
        for a in sys.argv[2:]:
            try:
                r = decode_farm_infos(call(sel("farmInfos(address)") + word(int(a, 16))))
                print(json.dumps(r))
            except Exception as e:
                print(json.dumps({"farm": a, "error": str(e)}))
    elif cmd == "raw":
        print(call(sys.argv[2]))
