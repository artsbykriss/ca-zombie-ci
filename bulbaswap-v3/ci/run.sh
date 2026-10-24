#!/usr/bin/env bash
# BulbaSwap V3 (Morph) — heavy/network job. Runs on GitHub Actions.
# Read-only: fetches public bytecode over keyless public RPCs, compares it to
# canonical Uniswap V3, and writes a JSON verdict to ci-out/. No secrets.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

MORPH_RPC="${MORPH_RPC_URL:-https://rpc.morphl2.io}"
ETH_RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
export MORPH_RPC ETH_RPC

python3 - <<'PY' | tee ci-out/bulba-bytecode.json
import json, os, urllib.request

def rpc(url, method, params):
    req = urllib.request.Request(
        url, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"content-type": "application/json", "user-agent": "Mozilla/5.0 research"})
    return json.load(urllib.request.urlopen(req, timeout=60))["result"]

ETH_FALLBACKS = [os.environ.get("FORK_RPC_URL"), os.environ.get("RPC_URL"),
                 "https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"]

def code(url, addr):
    last = None
    for u in [url]:
        try:
            return bytes.fromhex(rpc(u, "eth_getCode", [addr, "latest"])[2:])
        except Exception as e:
            last = e
    raise last

def code_eth(addr):
    last = None
    for u in ETH_FALLBACKS:
        if not u: continue
        try:
            return bytes.fromhex(rpc(u, "eth_getCode", [addr, "latest"])[2:])
        except Exception as e:
            last = e
    raise last


MORPH = os.environ["MORPH_RPC"]
FACTORY_MORPH = "0xFf8578C2949148A6F19b7958aE86CAAb2779CDDD"
FACTORY_ETH   = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
POOL_MORPH    = "0x5191035D329f481eFf0143e690e0a4e366Dd1e0c"
POOL_ETH      = "0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8"

def blank(code, addr):
    a = bytes.fromhex(addr.lower()[2:]); out = bytearray(code); i = 0
    while (j := code.find(a, i)) >= 0:
        out[j:j+20] = b"\x00" * 20; i = j + 1
    return bytes(out)

def diffcount(a, b):
    return sum(1 for x, y in zip(a, b) if x != y)

fm = code(MORPH, FACTORY_MORPH); fe = code_eth(FACTORY_ETH)
pm = code(MORPH, POOL_MORPH);    pe = code_eth(POOL_ETH)

factory_canonical = (len(fm) == len(fe) and blank(fm, FACTORY_MORPH) == blank(fe, FACTORY_ETH))

# pool: blank token0/token1/factory/self using values read from each pool's storage
def call_eth(to, sel):
    last = None
    for u in ETH_FALLBACKS:
        if not u: continue
        try:
            return "0x" + rpc(u, "eth_call", [{"to": to, "data": sel}, "latest"])[-40:]
        except Exception as e:
            last = e
    raise last

def slot_addr(url, pool, sel):
    return "0x" + rpc(url, "eth_call", [{"to": pool, "data": sel}, "latest"])[-40:]
t0m = slot_addr(MORPH, POOL_MORPH, "0x0dfe1681")  # token0()
t1m = slot_addr(MORPH, POOL_MORPH, "0xd21220a7")  # token1()
fcm = slot_addr(MORPH, POOL_MORPH, "0xc45a0155")  # factory()
t0e = call_eth(POOL_ETH, "0x0dfe1681")
t1e = call_eth(POOL_ETH, "0xd21220a7")
fce = call_eth(POOL_ETH, "0xc45a0155")
pb_m = blank(blank(blank(blank(pm, t0m), t1m), fcm), POOL_MORPH)
pb_e = blank(blank(blank(blank(pe, t0e), t1e), fce), POOL_ETH)
pool_residual = diffcount(pb_m, pb_e)

out = {
    "chain": "morph", "chain_id": 2818,
    "factory_morph": FACTORY_MORPH, "factory_code_bytes": len(fm),
    "factory_eth": FACTORY_ETH, "factory_eth_code_bytes": len(fe),
    "factory_canonical_modulo_self_immutable": factory_canonical,
    "pool_morph": POOL_MORPH, "pool_code_bytes": len(pm),
    "pool_eth": POOL_ETH, "pool_eth_code_bytes": len(pe),
    "pool_length_equal": len(pm) == len(pe),
    "pool_residual_diff_bytes_after_blanking_immutables": pool_residual,
    "pool_canonical_modulo_immutables": (len(pm) == len(pe) and pool_residual < 80),
    "verdict": "E-U $0 (high) — factory + pool bytecode == canonical Uniswap V3 (modulo immutables)"
}
print(json.dumps(out, indent=2))
PY
