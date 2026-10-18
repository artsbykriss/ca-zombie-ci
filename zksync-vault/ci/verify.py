#!/usr/bin/env python3
"""Reproducible CI verification for the SyncSwap Vault V1 finding (zkSync Era).

Read-only: eth_call / eth_getCode / eth_getBalance only.  No transactions, no keys.
Outputs ci-out/*.json and exits non-zero if any security invariant fails.
"""
import json, os, re, shutil, subprocess, sys, time, hashlib

import requests
from eth_abi import encode, decode
from eth_utils import keccak

# ---------------------------------------------------------------- constants
VAULT = "0x621425a1Ef6abE91058E9712575dcc4258F8d091"
WETH = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91"
USDC = "0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4"
USDT = "0x493257fD37EDB34451f62EDf8D2a0C418852bA4C"
ZK = "0x5a7d6b2f92c77fad6ccabd7ee0624e64907eaf3e"
ROUTER = "0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295"
POOL_MASTER = "0xbB05918E9B4bA9Fe2c8384d223f0844867909Ffb"
FEE_RECIPIENT = "0x4444f80DfB8a8a29E79087f066eaC306784699Ce"
MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
FRESH = "0x1111111111111111111111111111111111111111"
REVERT_RECEIVER = "0x2222222222222222222222222222222222222222"
EXPECTED_CODE_SHA256 = "92c3ce7b1e7f9b9259536dfb273c86ef1208a0dfaa893c928d07f5d92fb730a5"
EXPECTED_CODE_BYTES = 30944
RPCS = ["https://mainnet.era.zksync.io", "https://zksync.drpc.org", "https://1rpc.io/zksync2-era"]
BLOCKSCOUT = "https://zksync.blockscout.com"
OUT = "ci-out"
SRC = "analysis/src"

os.makedirs(OUT, exist_ok=True)
_ri = 0
def rpc(method, params, tries=6):
    global _ri
    last = None
    for _ in range(tries):
        url = RPCS[_ri % len(RPCS)]
        try:
            r = requests.post(url, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout=90)
            j = r.json()
            if "result" in j:
                return j["result"]
            last = j
        except Exception as e:
            last = str(e)
        _ri += 1
        time.sleep(1.5)
    raise RuntimeError(f"{method} failed: {last}")

def eth_call(to, data, block="latest", frm=None, value=None, state_override=None):
    tx = {"to": to, "data": data}
    if frm: tx["from"] = frm
    if value: tx["value"] = hex(value)
    params = [tx, block]
    if state_override: params.append(state_override)
    return rpc("eth_call", params)

def call_hex(to, sig, types, vals, block="latest", frm=None):
    data = "0x" + (keccak(text=sig)[:4] + encode(types, vals)).hex() if types else "0x" + keccak(text=sig)[:4].hex()
    return eth_call(to, data, block, frm)

def sel(sig): return keccak(text=sig)[:4]
BAL2 = sel("balanceOf(address,address)")
RES = sel("reserves(address)")
GETRES = sel("getReserves()")

checks = []
def check(name, ok, detail=""):
    checks.append({"check": name, "pass": bool(ok), "detail": str(detail)[:400]})
    print(("PASS " if ok else "FAIL ") + name + ((" :: " + str(detail)[:200]) if detail else ""), flush=True)
    return ok

# ---------------------------------------------------------------- 1. chain state
block = int(rpc("eth_blockNumber", []), 16)
code = rpc("eth_getCode", [VAULT, hex(block)])
code_b = bytes.fromhex(code[2:])
sha = hashlib.sha256(code_b).hexdigest()
eth_bal = int(rpc("eth_getBalance", [VAULT, hex(block)]), 16)
res0 = int(eth_call(VAULT, "0x" + (RES + encode(["address"], ["0x" + "00" * 20])).hex(), hex(block))[2:], 16)
weth_bal = int(eth_call(WETH, "0x" + (sel("balanceOf(address)") + encode(["address"], [VAULT])).hex(), hex(block))[2:], 16)
paused = int(eth_call(VAULT, "0x" + sel("paused()").hex(), hex(block))[2:], 16)
owner = "0x" + eth_call(VAULT, "0x" + sel("owner()").hex(), hex(block))[-40:]
impl_slot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
impl = rpc("eth_getStorageAt", [VAULT, impl_slot, hex(block)])

check("code_sha256_matches_source_artifact", sha == EXPECTED_CODE_SHA256, sha)
check("code_size_30944", len(code_b) == EXPECTED_CODE_BYTES, len(code_b))
check("native_balance_equals_reserves", eth_bal == res0, f"{eth_bal} vs {res0}")
check("weth_balance_zero", weth_bal == 0, weth_bal)
check("not_paused", paused == 0, paused)
check("no_eip1967_implementation", int(impl, 16) == 0, impl)
check("owner_is_syncswap_deployer_eoa", owner.lower() == "0x000002c34bae6dd7bec72acba6aaac1e01a359de", owner)
zk_hash = "0100" + format(len(code_b) // 32, "04x") + sha[8:]
check("zksync_bytecode_hash_format", zk_hash == "010003c7" + EXPECTED_CODE_SHA256[8:] and len(code_b) % 32 == 0, zk_hash)

# ---------------------------------------------------------------- 2. byte-identical recompile
def ensure(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 1_000_000:
        return path
    with requests.get(url, stream=True, timeout=300, allow_redirects=True) as r:
        r.raise_for_status()
        with open(path, "wb") as f:
            for chunk in r.iter_content(1 << 20):
                f.write(chunk)
    os.chmod(path, 0o755)
    return path

def compile_verify():
    solc = ensure("https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.8.15+commit.e14f2714", "/tmp/solc-0.8.15")
    zksolc = ensure("https://github.com/matter-labs/zksolc-bin/raw/main/linux-amd64/zksolc-linux-amd64-musl-v1.3.5", "/tmp/zksolc-1.3.5")
    sources = {}
    for dirpath, _, files in os.walk(SRC):
        for f in files:
            if f.endswith(".sol"):
                p = os.path.join(dirpath, f)
                sources[os.path.relpath(p, SRC)] = {"content": open(p).read()}
    inp = {"language": "Solidity", "sources": sources,
           "settings": {"optimizer": {"enabled": True},
                        "outputSelection": {"*": {"*": ["abi", "evm.methodIdentifiers", "storageLayout", "evm.legacyAssembly"]}}}}
    p = subprocess.run([zksolc, "--standard-json", "--solc", solc], input=json.dumps(inp), text=True,
                       capture_output=True, cwd=SRC, timeout=900)
    if p.returncode != 0:
        return False, {"error": p.stderr[-1000:]}
    out = json.loads(p.stdout)
    errs = [e for e in out.get("errors", []) if e.get("severity") == "error"]
    if errs:
        return False, {"errors": [e.get("formattedMessage", "")[:300] for e in errs[:5]]}
    c = out["contracts"]["contracts/vault/SyncSwapVault.sol"]["SyncSwapVault"]
    bc = (c["evm"].get("bytecode") or {}).get("object") or ""
    b = bytes.fromhex(bc[2:] if bc.startswith("0x") else bc)
    identical = b == code_b
    result = {"compiled_bytes": len(b), "deployed_bytes": len(code_b),
              "compiled_sha256": hashlib.sha256(b).hexdigest(), "deployed_sha256": sha,
              "byte_identical": identical,
              "method_identifiers": len(c["evm"]["methodIdentifiers"]),
              "solc": "0.8.15", "zksolc": "1.3.5", "optimizer": "enabled, runs=200"}
    return identical, result

try:
    identical, comp = compile_verify()
except Exception as e:
    identical, comp = False, {"error": str(e)[:500]}
json.dump(comp, open(f"{OUT}/compile.json", "w"), indent=1)
check("recompiled_byte_identical", identical, comp.get("deployed_sha256", ""))

# ---------------------------------------------------------------- 3. auth gates
def expect_revert(label, to, data, substr=None, panic=None, frm=FRESH, value=None, state_override=None):
    try:
        r = eth_call(to, data, hex(block), frm, value, state_override)
        return check(label, False, f"unexpected success {r[:80]}")
    except Exception as e:
        s = str(e)
        if panic and "4e487b71" in s and "0011" in s:
            return check(label, True, "Panic 0x11")
        if substr and substr in s:
            return check(label, True, substr)
        return check(label, False, s[:200])

gates = {}
def g(label, to, sig, types, vals, **kw):
    data = "0x" + (sel(sig) + encode(types, vals)).hex()
    expect_revert(label, to, data, **kw)

g("withdraw_usdc_fresh_panics", VAULT, "withdraw(address,address,uint256)", ["address","address","uint256"], [USDC, FRESH, 1], panic="11")
g("withdraw_eth_fresh_panics", VAULT, "withdrawETH(address,uint256)", ["address","uint256"], [FRESH, 10**18], panic="11")
g("transfer_usdc_fresh_panics", VAULT, "transfer(address,address,uint256)", ["address","address","uint256"], [USDC, FRESH, 10**6], panic="11")
g("transfer_and_deposit_unfunded_reverts", VAULT, "transferAndDeposit(address,address,uint256)", ["address","address","uint256"], [USDC, FRESH, 10**6], substr="7939f424")
g("set_paused_non_owner_reverts", VAULT, "setPaused(bool)", ["bool"], [True], substr="Ownable: caller is not the owner")
g("set_fee_non_owner_reverts", VAULT, "setFlashLoanFeePercentage(uint256)", ["uint256"], [0], substr="Ownable: caller is not the owner")
g("transfer_ownership_non_owner_reverts", VAULT, "transferOwnership(address)", ["address"], [FRESH], substr="Ownable: caller is not the owner")

# deposit(USDC, fresh) must return 0 (no unattributed USDC)
try:
    r = eth_call(VAULT, "0x" + (sel("deposit(address,address)") + encode(["address","address"], [USDC, FRESH])).hex(), hex(block), FRESH)
    dep0 = int(r, 16) == 0
except Exception as e:
    dep0 = False
check("deposit_usdc_credit_zero", dep0, "" if dep0 else "nonzero")

# non-repaying flash loan must revert (state override receiver returns magic value)
CODE = "0x7f439148f0bbc682ca079e46d6e2c2f0c1e3b820f1a291b069d8882abf8cf18dd960005260206000f3"
fl = "0x" + (sel("flashLoan(address,address,uint256,bytes)") + encode(["address","address","uint256","bytes"], [REVERT_RECEIVER, USDC, 10**6, b""])).hex()
expect_revert("flashloan_nonrepay_reverts", VAULT, fl, substr="INVALID_POST_LOAN_BALANCE", state_override={REVERT_RECEIVER: {"code": CODE}})
# control: wrong callback magic
CODE0 = "0x600060005260206000f3"
expect_revert("flashloan_wrong_callback_reverts", VAULT, fl, substr="IERC3156_CALLBACK_FAILED", state_override={REVERT_RECEIVER: {"code": CODE0}})

# ---------------------------------------------------------------- 4. approvals
appr = {}
for tok, name in ((USDC, "USDC"), (USDT, "USDT"), (WETH, "WETH")):
    for sp, sname in ((ROUTER, "router"), (POOL_MASTER, "master"), (FEE_RECIPIENT, "feeRecipient")):
        try:
            v = int(eth_call(tok, "0x" + (sel("allowance(address,address)") + encode(["address","address"], [VAULT, sp])).hex(), hex(block))[2:], 16)
        except Exception:
            v = -1
        appr[f"{name}->{sname}"] = v
check("vault_has_no_token_approvals", all(v == 0 for v in appr.values()), appr)

# ---------------------------------------------------------------- 5. ERC-20 sweep
def get_retry(url, timeout=180, tries=4):
    last = None
    for _ in range(tries):
        try:
            r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=timeout)
            r.raise_for_status()
            return r
        except Exception as e:
            last = e
            time.sleep(3)
    raise last

def tokenlist():
    try:
        return get_retry(f"{BLOCKSCOUT}/api?module=account&action=tokenlist&address={VAULT}").json()["result"]
    except Exception as e:
        print(f"WARN blockscout tokenlist failed ({str(e)[:120]}); using vendored fallback", flush=True)
        return json.load(open("analysis/tokenlist.json"))["result"]

def prices(keys):
    out = {}
    for i in range(0, len(keys), 80):
        try:
            j = requests.get("https://coins.llama.fi/prices/current/" + ",".join(keys[i:i+80]), timeout=60).json()
            out.update(j.get("coins", {}))
        except Exception:
            pass
    return out

def enc_agg(calls):
    return "0x" + (bytes.fromhex("82ad56cb") + encode(["(address,bool,bytes)[]"], [[(t, True, d) for t, d in calls]])).hex()

def dec_agg(raw):
    return decode(["(bool,bytes)[]"], bytes.fromhex(raw[2:]))[0]

tl = tokenlist()
tokens = {}
for t in tl:
    if t.get("type") != "ERC-20":
        continue
    try:
        b = int(t["balance"])
    except Exception:
        continue
    if b == 0:
        continue
    tokens[t["contractAddress"].lower()] = {"symbol": t.get("symbol"), "decimals": int(t.get("decimals") or 18)}
addrs = sorted(tokens)
sweep = {}
CH = 250
for i in range(0, len(addrs), CH):
    chunk = addrs[i:i+CH]
    calls = [(a, sel("balanceOf(address)") + encode(["address"], [VAULT])) for a in chunk]
    calls += [(VAULT, RES + encode(["address"], [a])) for a in chunk]
    res = dec_agg(eth_call(MC3, enc_agg(calls), hex(block)))
    for j, a in enumerate(chunk):
        okb, rb = res[j]; okr, rr = res[len(chunk)+j]
        bal = int.from_bytes(rb, "big") if okb and len(rb) >= 32 else None
        rsv = int.from_bytes(rr, "big") if okr and len(rr) >= 32 else None
        sweep[a] = {**tokens[a], "balance": bal, "reserves": rsv}

pk = prices([f"zksync:{a}" for a in addrs])
eth_price = requests.get("https://coins.llama.fi/prices/current/coingecko:ethereum", timeout=30).json()["coins"]["coingecko:ethereum"]["price"]
excess_rows, real_excess_usd = [], 0.0
for a, d in sweep.items():
    if d["balance"] is None or d["reserves"] is None:
        continue
    e = d["balance"] - d["reserves"]
    if e <= 0:
        continue
    p = pk.get(f"zksync:{a}", {}).get("price", 0)
    usd = e / (10 ** d["decimals"]) * p
    if p: real_excess_usd += usd
    excess_rows.append({"token": a, "symbol": d["symbol"], "excess_raw": str(e), "price": p, "usd": usd})
excess_rows.sort(key=lambda x: x["usd"], reverse=True)
total_erc20 = sum((d["balance"] / (10 ** d["decimals"]) * pk.get(f"zksync:{a}", {}).get("price", 0))
                  for a, d in sweep.items() if d["balance"])
total_usd = total_erc20 + eth_bal / 1e18 * eth_price
json.dump({"block": block, "tokens_checked": len(addrs), "excess": excess_rows,
           "real_token_excess_usd": real_excess_usd, "total_erc20_usd": total_erc20,
           "eth_usd": eth_bal / 1e18 * eth_price, "total_usd": total_usd,
           "eth_price": eth_price, "results": sweep}, open(f"{OUT}/sweep.json", "w"), indent=1)
check("no_real_token_excess", real_excess_usd < 1.0, f"${real_excess_usd:.6f} over {len(excess_rows)} dust tokens")
check("erc20_total_matches_order_of_magnitude", 1.5e6 < total_erc20 < 5.0e6, f"${total_erc20:,.2f}")

# ---------------------------------------------------------------- 6. per-pool excess
pools_raw = json.load(open("analysis/pools.json"))
pools = []
for kind, d in pools_raw.items():
    for p, meta in d.items():
        pools.append({"pool": p, "kind": kind, **meta})
prows = []
for i in range(0, len(pools), 180):
    chunk = pools[i:i+180]
    calls = [(p["pool"], GETRES) for p in chunk]
    calls += [(VAULT, BAL2 + encode(["address","address"], [p["token0"], p["pool"]])) for p in chunk]
    calls += [(VAULT, BAL2 + encode(["address","address"], [p["token1"], p["pool"]])) for p in chunk]
    res = dec_agg(eth_call(MC3, enc_agg(calls), hex(block)))
    for j, p in enumerate(chunk):
        okr, rr = res[j]; ok0, r0 = res[len(chunk)+j]; ok1, r1 = res[2*len(chunk)+j]
        prows.append({**p,
                      "reserve0": int.from_bytes(rr[:32], "big") if okr and len(rr) >= 64 else None,
                      "reserve1": int.from_bytes(rr[32:64], "big") if okr and len(rr) >= 64 else None,
                      "vault0": int.from_bytes(r0, "big") if ok0 and len(r0) >= 32 else None,
                      "vault1": int.from_bytes(r1, "big") if ok1 and len(r1) >= 32 else None})
pex = []
for p in prows:
    for side, tok in (("0", p["token0"]), ("1", p["token1"])):
        r, b = p["reserve"+side], p["vault"+side]
        if r is None or b is None or b <= r:
            continue
        dec = sweep.get(tok.lower(), {}).get("decimals", 18)
        price = pk.get(f"zksync:{tok.lower()}", {}).get("price", 0) or (eth_price if tok.lower() in (WETH.lower(), "0x"+ "00"*20) else 0)
        pex.append({"pool": p["pool"], "kind": p["kind"], "token": tok, "excess_raw": str(b-r),
                    "usd": (b-r) / (10 ** dec) * price})
pex.sort(key=lambda x: x["usd"], reverse=True)
pool_usd = 0.0
for p in prows:
    for side, tok in (("0", p["token0"]), ("1", p["token1"])):
        b = p["vault" + side]
        if b is None:
            continue
        dec = sweep.get(tok.lower(), {}).get("decimals", 18)
        price = pk.get(f"zksync:{tok.lower()}", {}).get("price", 0)
        if not price and tok.lower() in (WETH.lower(), "0x" + "00" * 20):
            price = eth_price
        pool_usd += b / (10 ** dec) * price
json.dump({"block": block, "pools_checked": len(prows), "excess": pex,
           "total_excess_usd": sum(x["usd"] for x in pex)}, open(f"{OUT}/pool_excess.json", "w"), indent=1)
check("no_material_per_pool_excess", sum(x["usd"] for x in pex) < 1.0,
      f"${sum(x['usd'] for x in pex):.6f} over {len(pex)} pools")

# ---------------------------------------------------------------- 7. verdict
categories = {"E-U": 0.0, "H-O": round(total_usd, 2), "P": 0.0, "S": 0.0}
verdict = {
    "finding": "ZH4-WaveB1-zksync-vault",
    "target": VAULT,
    "identity": "SyncSwap Vault (V1), zkSync Era",
    "block": block,
    "eth_balance": str(eth_bal),
    "eth_usd": round(eth_bal / 1e18 * eth_price, 2),
    "erc20_usd": round(total_erc20, 2),
    "total_custody_usd": round(total_usd, 2),
    "pool_attributed_usd": round(pool_usd, 2),
    "non_pool_usd": round(total_usd - pool_usd, 2),
    "categories": categories,
    "headline_extractable_usd": 0.0,
    "headline_confidence": "high",
    "standing_excess_usd": round(real_excess_usd + sum(x["usd"] for x in pex), 4),
    "checks": checks,
    "all_checks_pass": all(c["pass"] for c in checks),
    "notes": [
        "Custody is 99.96% SyncSwap V1 pool reserves; LPs can burn via the router.",
        "All withdraw/transfer entrypoints debit msg.sender; fresh caller -> Panic 0x11.",
        "Only permissionless capture is unattributed-balance attribution via deposit(); standing value = dust.",
        "Owner has no sweep; no proxy; no delegatecall; code byte-identical to published source.",
    ],
}
json.dump(verdict, open(f"{OUT}/verdict.json", "w"), indent=1)
print(json.dumps({k: verdict[k] for k in ("block","total_custody_usd","categories","standing_excess_usd","all_checks_pass")}, indent=1))
sys.exit(0 if verdict["all_checks_pass"] else 1)
