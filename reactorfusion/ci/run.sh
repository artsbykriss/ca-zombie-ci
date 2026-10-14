#!/usr/bin/env bash
# CI heavy job for the ReactorFusion deep-dive (GitHub Actions, read-only).
# Working directory: the finding folder (reactorfusion/).
# Writes results to ci-out/ (uploaded as artifacts). Never prints or stores secrets.
set -uo pipefail

echo "=== ReactorFusion CI job $(date -u +%FT%TZ) ==="
python3 --version || true
echo "RPC: keyless public endpoints by default; keyed endpoint built from env at runtime (redacted)"

# --- 0. python deps for the ABI helper (rpclib.py) ---------------------------
pip3 install --quiet --break-system-packages eth-abi pycryptodome 2>/dev/null \
  || pip3 install --quiet eth-abi pycryptodome 2>/dev/null \
  || echo "WARN: pip install failed"
python3 -c "import eth_abi, Crypto; print('python deps ok')" || echo "WARN: eth_abi missing"

# --- 1. live verification harness (zkSync Era) -------------------------------
echo "--- ci/live_verify.py (zkSync Era) ---"
LIVE_VERIFY_MAX_ACCOUNTS="${LIVE_VERIFY_MAX_ACCOUNTS:-12}" timeout 5400 python3 -u ci/live_verify.py || echo "WARN: live_verify.py exited non-zero"

# --- 2. Telos key-state re-read (keyless) ------------------------------------
echo "--- Telos state re-read ---"
timeout 900 python3 -u - <<'PY' || echo "WARN: telos probe failed"
import json, sys, os
sys.path.insert(0, os.path.join(os.getcwd(), 'analysis'))
from rpclib import RPC, default_urls, calldata, dec
rpc = RPC(default_urls('telos'), 'telos')
C = "0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494"
ORACLE = "0x0fa9de8362e662d6659a05ad284a2f454f49a8e2"
markets = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}
blk = rpc.block_number()
out = {"block": blk, "markets": {}, "params": {}}
calls, keys = [], []
for n, m in markets.items():
    calls.append((m, calldata("getCash()", (), ()))); keys.append((n, "cash"))
    calls.append((ORACLE, calldata("getUnderlyingPrice(address)", ["address"], [m]))); keys.append((n, "price"))
calls.append((C, calldata("closeFactorMantissa()", (), ()))); keys.append(("params", "closeFactor"))
calls.append((C, calldata("liquidationIncentiveMantissa()", (), ()))); keys.append(("params", "liqIncentive"))
calls.append((C, calldata("admin()", (), ()))); keys.append(("params", "admin"))
res = rpc.try_calls(calls)
for (n, tag), (raw, err) in zip(keys, res):
    e = out["params"] if n == "params" else out["markets"].setdefault(n, {})
    if raw is None:
        e[tag] = None
        e[tag + "_err"] = err
    else:
        try:
            e[tag] = str(dec(["address"] if tag == "admin" else ["uint256"], raw)[0])
        except Exception:
            e[tag] = None
os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/telos-verification.json", "w"), indent=1)
print(json.dumps(out, indent=1)[:1500])
PY

# --- 3. Era state re-read via a single batched pass (belt & braces) ----------
echo "--- Era quick state re-read ---"
timeout 1200 python3 -u - <<'PY' || echo "WARN: era quick probe failed"
import json, sys, os
sys.path.insert(0, os.path.join(os.getcwd(), 'analysis'))
from rpclib import RPC, default_urls, calldata, dec
rpc = RPC(default_urls('era'), 'era')
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
ORACLE = "0x1d54DD49218333125C858c0239bbdA424db55C43"
markets = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH": "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC": "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT": "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK": "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDCz": "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
blk = rpc.block_number()
out = {"block": blk, "markets": {}, "params": {}}
calls, keys = [], []
for n, m in markets.items():
    calls.append((m, calldata("getCash()", (), ()))); keys.append((n, "cash"))
    calls.append((m, calldata("totalBorrows()", (), ()))); keys.append((n, "borrows"))
    calls.append((ORACLE, calldata("getUnderlyingPrice(address)", ["address"], [m]))); keys.append((n, "price"))
calls.append((C, calldata("closeFactorMantissa()", (), ()))); keys.append(("params", "closeFactor"))
calls.append((C, calldata("liquidationIncentiveMantissa()", (), ()))); keys.append(("params", "liqIncentive"))
calls.append((C, calldata("admin()", (), ()))); keys.append(("params", "admin"))
calls.append((ORACLE, calldata("owner()", (), ()))); keys.append(("params", "oracleOwner"))
res = rpc.try_calls(calls)
for (n, tag), (raw, err) in zip(keys, res):
    e = out["params"] if n == "params" else out["markets"].setdefault(n, {})
    if raw is None:
        e[tag] = None
        e[tag + "_err"] = err
    else:
        try:
            e[tag] = str(dec(["address"] if tag in ("admin", "oracleOwner") else ["uint256"], raw)[0])
        except Exception:
            e[tag] = None
os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/era-verification.json", "w"), indent=1)
print(json.dumps(out, indent=1)[:1500])
PY

echo "=== done; artifacts in ci-out/ ==="
ls -la ci-out/ || true
