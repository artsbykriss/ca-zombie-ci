#!/usr/bin/env bash
# Cluster CI verification: re-read the public state behind the three primary verdicts.
# No secrets, no keyed RPCs, no transactions. Writes ci-out/verification.json.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

python3 - <<'PY'
import json, subprocess, urllib.request, datetime

RPC = {
    "telos": "https://rpc.telos.net",
    "syscoin": "https://rpc.syscoin.org",
    "arbitrum": "https://arb1.arbitrum.io/rpc",
}

def rpc(chain, method, params):
    req = urllib.request.Request(
        RPC[chain],
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.load(r)
    if "error" in d:
        raise RuntimeError(d["error"])
    return d["result"]

def sig(s):
    return subprocess.check_output(["cast", "sig", s], text=True).strip()

def call(chain, to, signature, args=(), block="latest"):
    data = sig(signature) + "".join(a[2:].rjust(64, "0") for a in args)
    return rpc(chain, "eth_call", [{"to": to, "data": data}, block])

def word(h, i=0):
    return h[2 + i * 64: 2 + (i + 1) * 64]

def num(h, i=0):
    return int(word(h, i), 16)

out = {"generated_at": datetime.datetime.utcnow().isoformat() + "Z", "checks": {}, "pass": True}

def check(section, name, ok, detail):
    out["checks"].setdefault(section, []).append({"check": name, "pass": bool(ok), "detail": detail})
    if not ok:
        out["pass"] = False

# ---------------- Zappy / Telos ----------------
try:
    blk = int(rpc("telos", "eth_blockNumber", []), 16)
    ap = "0x9E0081f597d4381Aa10F6CfC6960165a2431f2F1"
    tm = "0xb1f92104e1ad5ed84592666efb1eb52b946e6e68"
    sp = "0xe696c38b79307f65f2e00bc6c572c2b83e048e36"
    pf = "0xe421fc686099c4dec31c9d58b51de9608665fbf2"
    B = hex(blk)
    bal = int(rpc("telos", "eth_getBalance", [ap, B]), 16) / 1e18
    debt = num(call("telos", tm, "getEntireSystemDebt()", (), B)) / 1e18
    count = num(call("telos", tm, "getTroveOwnersCount()", (), B))
    price = num(call("telos", pf, "fetchPrice()", (), B)) / 1e18
    sp_dep = num(call("telos", sp, "getTotalLUSDDeposits()", (), B))
    vault = "0x57ed6bd35a6ce815079855cd0b21331d1d5d0a0e"
    vault_code = rpc("telos", "eth_getCode", [vault, "latest"])
    red_val = (1 - 0.0515) / price * 0.01697655 if price else 0
    check("zappy", "active_pool_tlos > 2M", bal > 2_000_000, f"{bal:.4f}")
    check("zappy", "system debt 10k-15k USDM", 10_000 < debt < 15_000, f"{debt:.4f}")
    check("zappy", "trove count == 1", count == 1, str(count))
    check("zappy", "oracle price in (0.01,0.03)", 0.01 < price < 0.03, f"{price:.8f}")
    check("zappy", "redemption value in (0.80,0.87)", 0.80 < red_val < 0.87, f"{red_val:.4f}")
    check("zappy", "stability pool deposits == 0", sp_dep == 0, str(sp_dep))
    check("zappy", "anyUSDC vault is EOA (0 bytes)", len(vault_code) <= 2, f"code chars={len(vault_code)}")
    out.setdefault("blocks", {})["telos"] = blk
except Exception as e:
    check("zappy", "RPC/read failure", False, repr(e))

# ---------------- PegaSys / Syscoin ----------------
try:
    blk = int(rpc("syscoin", "eth_blockNumber", []), 16)
    pairs = [
        ("0x2CDF912CbeaF76d67feaDC994D889c2F4442b300", "USDC/WSYS"),
        ("0x8c741Cd1Dc4D027034ce864FFD660BFa44c24674", "USDC/USDT"),
        ("0xDA3995D0ADDb43935A0c17c187C271Cc6c07Df21", "USDC/PSYS"),
        ("0x56Dbc5768CE4D674228e6825Cb919b402aF428Fc", "USDT/DAI"),
        ("0x1a7400F4DFE299DBac8034bD2Bb0B3B17fCA9342", "WSYS/PSYS"),
    ]
    zero_surplus = True
    details = {}
    B = hex(blk)
    for p, label in pairs:
        r = call("syscoin", p, "getReserves()", (), B)
        t0 = "0x" + call("syscoin", p, "token0()", (), B)[-40:]
        t1 = "0x" + call("syscoin", p, "token1()", (), B)[-40:]
        b0 = num(call("syscoin", t0, "balanceOf(address)", [p], B))
        b1 = num(call("syscoin", t1, "balanceOf(address)", [p], B))
        surplus0 = b0 - num(r, 0)
        surplus1 = b1 - num(r, 1)
        details[label] = {"reserve0": num(r, 0), "reserve1": num(r, 1), "surplus0": surplus0, "surplus1": surplus1}
        if surplus0 != 0 or surplus1 != 0:
            zero_surplus = False
    r = call("syscoin", "0x2CDF912CbeaF76d67feaDC994D889c2F4442b300", "getReserves()", (), B)
    usdc = num(r, 0) / 1e6
    wsys = num(r, 1) / 1e18
    sys_price = 0.002040132293426376
    implied_usdc = sys_price / (usdc / wsys)
    chef = "0x3D974158e4C70dD5204b62AceDa9fd1330f33C7b"
    name_hex = call("syscoin", chef, "name()", (), B)
    nb = bytes.fromhex(name_hex[2:])
    nlen = int.from_bytes(nb[32:64], "big")
    name = nb[64:64 + nlen].decode(errors="ignore")
    check("pegasys", "all pair balances == reserves", zero_surplus, json.dumps(details))
    check("pegasys", "implied USDC < $0.01", implied_usdc < 0.01, f"{implied_usdc:.8f}")
    check("pegasys", "Chef quest is an ERC20", "Chef quest" in name, name)
    out.setdefault("blocks", {})["syscoin"] = blk
except Exception as e:
    check("pegasys", "RPC/read failure", False, repr(e))

# ---------------- Arbitris / DORY ----------------
try:
    blk = int(rpc("arbitrum", "eth_blockNumber", []), 16)
    hook = "0x6b70fef40d3925881251c018164dbcec6bc94040"
    dory = "0x33b49f2264e85bb124d2730dc180182717d436ae"
    usdc = "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
    pm = "0x360e68faccca8ca495c1b759fd9eee466db9fb32"
    B = hex(blk)
    code = rpc("arbitrum", "eth_getCode", [hook, B])
    size = (len(code) - 2) // 2
    perms = call("arbitrum", hook, "getHookPermissions()", (), B)
    true_words = [i for i in range(14) if num(perms, i) != 0]
    hook_usdc = num(call("arbitrum", usdc, "balanceOf(address)", [hook], B))
    hook_dory = num(call("arbitrum", dory, "balanceOf(address)", [hook], B))
    dory_pm = num(call("arbitrum", dory, "balanceOf(address)", [pm], B)) / 1e18
    check("arbitris", "hook runtime 6k-8k bytes", 6000 <= size <= 8000, str(size))
    check("arbitris", "only afterSwap permission", true_words == [7], str(true_words))
    check("arbitris", "low14 == 0x40", (int(hook, 16) & 0x3fff) == 0x40, hex(int(hook, 16) & 0x3fff))
    check("arbitris", "hook holds no USDC/DORY", hook_usdc == 0 and hook_dory == 0, f"usdc={hook_usdc} dory={hook_dory}")
    check("arbitris", "pool has >30k DORY", dory_pm > 30_000, f"{dory_pm:.4f}")
    out.setdefault("blocks", {})["arbitrum"] = blk
except Exception as e:
    check("arbitris", "RPC/read failure", False, repr(e))

with open("ci-out/verification.json", "w") as f:
    json.dump(out, f, indent=2)
print(json.dumps(out, indent=2))
print("ALL_CHECKS_PASS" if out["pass"] else "SOME_CHECKS_FAILED")
PY
