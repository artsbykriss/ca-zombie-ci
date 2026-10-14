#!/usr/bin/env python3
"""Check vaults referenced by the Safe's non-factory modules: owner + rough value.
Read-only. RPC from env (BRIL_RPC or publicnode or DRPC). Output analysis/extra_modules_vaults.json
"""
import json, os, re, subprocess, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SAFE = "0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12"

def pick():
    v = os.environ.get("BRIL_RPC", "")
    if v: return v
    env = open("/home/heisenberg/CA/.env").read()
    m = re.search(r"^DRPC_API_KEY=(.*)$", env, re.M)
    if m:
        k = m.group(1).strip().strip('"')
        return f"https://lb.drpc.org/ogrpc?network=bsc&dkey={k}"
    return "https://bsc-rpc.publicnode.com"

RPC = pick()

def sel(sig): return subprocess.check_output(["cast", "sig", sig], text=True).strip()

def call(to, sig, args=()):
    import sys
    data = sel(sig) + "".join(str(a).lower().replace("0x", "").rjust(64, "0") for a in args)
    payload = {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]}
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    for _ in range(3):
        try:
            d = json.load(urllib.request.urlopen(req, timeout=20))
            return d.get("result") if "error" not in d else None
        except Exception:
            time.sleep(0.5)
    return None

def main():
    # module -> vault mapping from the earlier partial scan output (re-derive live)
    mods = json.load(open("/tmp/opencode/safe_modules.json"))
    _ls = json.load(open(os.path.join(HERE, "live_state.json")))
    _strs = _ls["strategies"] if isinstance(_ls, dict) else _ls
    factory_strategies = set(s["strategy"].lower() for s in _strs)
    extra = [m for m in mods if m.lower() not in factory_strategies]
    vaults = {}
    for m in extra:
        v = call(m, "vault()(address)")
        if v and v != "0x" + "0" * 40:
            vaults["0x" + v[-40:]] = vaults.get("0x" + v[-40:], [])
            vaults["0x" + v[-40:]].append(m)
    print("extra modules:", len(extra), "extra vaults:", len(vaults), flush=True)
    out = {}
    for v, ms in vaults.items():
        owner = call(v, "owner()(address)")
        ts = call(v, "totalSupply()(uint256)")
        t0 = call(v, "token0()(address)")
        t1 = call(v, "token1()(address)")
        out[v] = {"modules": ms, "owner": ("0x" + owner[-40:]) if owner else None,
                  "totalSupply": int(ts, 16) if ts else None,
                  "token0": ("0x" + t0[-40:]) if t0 else None, "token1": ("0x" + t1[-40:]) if t1 else None}
        print(v, out[v]["owner"], out[v]["totalSupply"], flush=True)
    json.dump(out, open(os.path.join(HERE, "extra_modules_vaults.json"), "w"), indent=1)

if __name__ == "__main__":
    main()
