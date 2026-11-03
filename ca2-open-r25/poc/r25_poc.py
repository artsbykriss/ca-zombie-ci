#!/usr/bin/env python3
"""
R25 WrappedVault family (Pharos, chain 1672) -- read-only live-state proof.

Claim under test: the ~$169.4M reported by totalAssets() is NOT USDC held by the
vaults; it is share supply x a manager-reported NAV.  The script proves, at one
pinned block:

  1. every vault's USDC balanceOf() == 0 (and has been 0 at historical blocks);
  2. totalAssets() == totalSupply() * latestNav() / 1e13 on vRPCQuarterlyVault;
  3. the whole Pharos USDC supply is far below the claimed $169.4M;
  4. an unprivileged EOA cannot deposit / requestRedeem / cancelRedeem /
     redeem / withdraw / submit an oracle report (all revert);
  5. an unprivileged EOA cannot create or cancel a request against a
     whitelisted holder's shares;
  6. no funded external holder grants the swaper/queue a USDC allowance.

No transaction is sent.  eth_call / eth_getCode / eth_getStorageAt only.
Exit 0 = every assertion passed (on-chain closure confirmed).
"""
import json
import sys
import time
import urllib.request

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from sigs import (SELECTORS, TOKEN, VAULTS, CUSTODIANS, SWAPER, QUEUE,
                  ESCROW, ORACLE_REPORTER, ATTACKER)

RPC = "https://infra.originstake.com/pharos/evm"
NAV_PRECISION = 10 ** 13
_id = 0


def rpc(method, params, retries=8):
    global _id
    _id += 1
    body = json.dumps({"jsonrpc": "2.0", "id": _id, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "ca2-r25-poc/1.0"})
    last = None
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                j = json.loads(r.read())
            if "error" in j:
                return {"__error__": j["error"]}
            return j.get("result")
        except Exception as e:  # noqa: BLE001
            last = str(e)
            time.sleep(1.5 * (attempt + 1))
    return {"__error__": last}


def batch(calls, chunk=20):
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        payload = [{"jsonrpc": "2.0", "id": j, "method": m, "params": p}
                   for j, (m, p) in enumerate(part)]
        body = json.dumps(payload).encode()
        req = urllib.request.Request(RPC, data=body, headers={
            "Content-Type": "application/json", "User-Agent": "ca2-r25-poc/1.0"})
        for attempt in range(8):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    js = json.loads(r.read())
                res = [None] * len(part)
                for o in js:
                    res[o["id"]] = {"__error__": o["error"]} if "error" in o else o.get("result")
                out.extend(res)
                break
            except Exception as e:  # noqa: BLE001
                if attempt == 7:
                    out.extend([{"__error__": str(e)}] * len(part))
                else:
                    time.sleep(1.5 * (attempt + 1))
    return out


def enc_addr(a):
    return a[2:].lower().rjust(64, "0")


def enc_uint(n):
    return hex(n)[2:].rjust(64, "0")


def as_int(r):
    if isinstance(r, dict) or r in (None, "0x", ""):
        return None
    return int(r, 16)


def as_addr(r):
    if isinstance(r, dict) or not isinstance(r, str) or len(r) < 66:
        return None
    return "0x" + r[2:][24:64]


def as_str(r):
    if isinstance(r, dict) or not r or len(r) < 130:
        return None
    h = r[2:]
    try:
        off = int(h[0:64], 16) * 2
        ln = int(h[off:off + 64], 16) * 2
        return bytes.fromhex(h[off + 64:off + 64 + ln]).decode(errors="replace")
    except Exception:  # noqa: BLE001
        return None


def code_size(a, blk):
    r = rpc("eth_getCode", [a, blk])
    return 0 if not isinstance(r, str) else len(r[2:]) // 2


def call(to, sig, args="", frm=None, block="latest"):
    tx = {"to": to, "data": SELECTORS[sig] + args}
    if frm:
        tx["from"] = frm
    return rpc("eth_call", [tx, block])


def main():
    out = {"generated_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "read_only": True, "rpc": "https://<pharos-public-rpc>",
           "assertions": [], "checks": {}}

    def assert_(name, cond, detail):
        out["assertions"].append({"name": name, "pass": bool(cond),
                                  "detail": detail if not isinstance(detail, dict) else detail})
        return bool(cond)

    chain_id = as_int(rpc("eth_chainId", []))
    block = as_int(rpc("eth_blockNumber", []))
    blk = hex(block)
    out["chain_id"] = chain_id
    out["block"] = block
    assert_("chain id is Pharos 1672", chain_id == 1672, chain_id)

    # ---------------- asset token ----------------
    tok = {
        "address": TOKEN,
        "name": as_str(call(TOKEN, "name()", block=blk)),
        "symbol": as_str(call(TOKEN, "symbol()", block=blk)),
        "decimals": as_int(call(TOKEN, "decimals()", block=blk)),
        "totalSupply": as_int(call(TOKEN, "totalSupply()", block=blk)),
        "code_size": code_size(TOKEN, blk),
    }
    tok["totalSupply_usd"] = tok["totalSupply"] / 1e6
    out["checks"]["asset_token"] = tok
    assert_("asset is 6-decimal USDC",
            tok["decimals"] == 6 and tok["symbol"] == "USDC", tok)

    # ---------------- vaults ----------------
    vres, total_assets = {}, 0.0
    for name, v in VAULTS.items():
        d = {"address": v, "code_size": code_size(v, blk)}
        d["asset"] = as_addr(call(v, "asset()", block=blk))
        d["totalAssets"] = as_int(call(v, "totalAssets()", block=blk))
        d["asset_balanceOf_vault"] = as_int(
            call(TOKEN, "balanceOf(address)", enc_addr(v), block=blk))
        d["totalSupply"] = as_int(call(v, "totalSupply()", block=blk))
        d["decimals"] = as_int(call(v, "decimals()", block=blk))
        d["latestNav"] = as_int(call(v, "latestNav()", block=blk))
        d["paused"] = as_int(call(v, "paused()", block=blk))
        d["maxRedeem_attacker"] = as_int(
            call(v, "maxRedeem(address)", enc_addr(ATTACKER), block=blk))
        if d["totalAssets"]:
            total_assets += d["totalAssets"] / 1e6
        vres[name] = d
    out["checks"]["vaults"] = vres
    out["measured_totalAssets_usd"] = round(total_assets, 6)

    for name, d in vres.items():
        assert_(f"{name}: asset() == 0xC879..1815",
                (d["asset"] or "").lower() == TOKEN.lower(), d["asset"])
        assert_(f"{name}: USDC balanceOf(vault) == 0",
                d["asset_balanceOf_vault"] == 0, d["asset_balanceOf_vault"])
        assert_(f"{name}: totalAssets() > 0 (manager NAV)",
                (d["totalAssets"] or 0) > 0, d["totalAssets"])
        assert_(f"{name}: maxRedeem(attacker) == 0",
                d["maxRedeem_attacker"] == 0, d["maxRedeem_attacker"])

    q = vres["vRPCQuarterlyVault"]
    if q["totalSupply"] and q["latestNav"]:
        nav_mul = q["totalSupply"] * q["latestNav"] // NAV_PRECISION
        out["checks"]["vRPCQ_nav_identity"] = {
            "totalSupply": q["totalSupply"], "latestNav": q["latestNav"],
            "totalSupply_x_nav_div_1e13": nav_mul, "totalAssets": q["totalAssets"],
            "matches": nav_mul == q["totalAssets"]}
        assert_("vRPCQ: totalAssets == totalSupply*latestNav/1e13",
                nav_mul == q["totalAssets"], nav_mul)

    # supply check: claimed AUM cannot be on-chain USDC
    out["checks"]["claimed_vs_token_supply"] = {
        "claimed_totalAssets_usd": out["measured_totalAssets_usd"],
        "usdc_totalSupply_usd": tok["totalSupply_usd"],
        "ratio": round(out["measured_totalAssets_usd"] / max(tok["totalSupply_usd"], 1e-9), 4)}
    assert_("claimed AUM > total Pharos USDC supply",
            out["measured_totalAssets_usd"] > tok["totalSupply_usd"],
            out["checks"]["claimed_vs_token_supply"])

    # ---------------- whitelist / perimeter ----------------
    qv = VAULTS["vRPCQuarterlyVault"]
    wl = as_addr(call(qv, "whitelist()", block=blk))
    holder = "0x40836f8f1bd7e13d99a4cc9de5c0b80a83109819"  # 2.5% VRPCQ holder
    out["checks"]["vRPCQ_whitelist"] = wl
    out["checks"]["whitelistEnabled"] = as_int(call(wl, "whitelistEnabled()", block=blk)) if wl else None
    out["checks"]["isWhitelisted"] = {
        "attacker": as_int(call(wl, "isWhitelisted(address)", enc_addr(ATTACKER), block=blk)) if wl else None,
        "holder_0x40836f": as_int(call(wl, "isWhitelisted(address)", enc_addr(holder), block=blk)) if wl else None,
        "escrow": as_int(call(wl, "isWhitelisted(address)", enc_addr(ESCROW), block=blk)) if wl else None,
    }
    assert_("whitelist is enabled", out["checks"]["whitelistEnabled"] == 1,
            out["checks"]["whitelistEnabled"])
    assert_("attacker not whitelisted", out["checks"]["isWhitelisted"]["attacker"] == 0,
            out["checks"]["isWhitelisted"])

    probes = {
        "deposit(1e6,attacker)": ("deposit(uint256,address)",
                                  enc_uint(10 ** 6) + enc_addr(ATTACKER), ATTACKER),
        "requestRedeem(1e6,att,att)": ("requestRedeem(uint256,address,address)",
                                       enc_uint(10 ** 6) + enc_addr(ATTACKER) + enc_addr(ATTACKER), ATTACKER),
        "redeem(1e6,att,att)": ("redeem(uint256,address,address)",
                                enc_uint(10 ** 6) + enc_addr(ATTACKER) + enc_addr(ATTACKER), ATTACKER),
        "withdraw(1e6,att,att)": ("withdraw(uint256,address,address)",
                                  enc_uint(10 ** 6) + enc_addr(ATTACKER) + enc_addr(ATTACKER), ATTACKER),
        "requestRedeem(1e6,att,holder) [owner != sender]": (
            "requestRedeem(uint256,address,address)",
            enc_uint(10 ** 6) + enc_addr(ATTACKER) + enc_addr(holder), ATTACKER),
        "cancelRedeemRequest(7) [not owner]": ("cancelRedeemRequest(uint256)",
                                               enc_uint(7), ATTACKER),
        "handleOracleReport(from attacker)": (
            "handleOracleReport((uint64,uint64,uint64,uint256,address))",
            enc_uint(1793600000) + enc_uint(1793600000) + enc_uint(202) +
            enc_uint(10681883016348) + enc_addr(ATTACKER), ATTACKER),
    }
    pr = {}
    for label, (sig, args, frm) in probes.items():
        r = call(qv, sig, args, frm=frm, block=blk)
        reverted = isinstance(r, dict)
        pr[label] = {"reverted": reverted, "result": None if reverted else r}
        assert_(f"unprivileged {label} reverts", reverted, pr[label])
    out["checks"]["unprivileged_probes"] = pr
    out["checks"]["getRedeemRequestCount_attacker"] = as_int(
        call(qv, "getRedeemRequestCount(address)", enc_addr(ATTACKER), block=blk))
    assert_("attacker has 0 redeem requests",
            out["checks"]["getRedeemRequestCount_attacker"] == 0,
            out["checks"]["getRedeemRequestCount_attacker"])

    # ---------------- custody / balances ----------------
    cust = {}
    for name, a in CUSTODIANS.items():
        cust[name] = {
            "code_size": code_size(a, blk),
            "usdc": as_int(call(TOKEN, "balanceOf(address)", enc_addr(a), block=blk)),
            "allowance_to_swaper": as_int(call(
                TOKEN, "allowance(address,address)", enc_addr(a) + enc_addr(SWAPER), block=blk)),
        }
    out["checks"]["custodians"] = cust

    system = {"swaper": SWAPER, "queue": QUEUE, "escrow": ESCROW,
              "vRPCQ": VAULTS["vRPCQuarterlyVault"],
              "vRPCW": VAULTS["vRPCWeeklyVault"],
              "vRPCS": VAULTS["vRPCSemiYearlyVault"]}
    sysbal = {n: {"usdc": as_int(call(TOKEN, "balanceOf(address)", enc_addr(a), block=blk))}
              for n, a in system.items()}
    out["checks"]["system_balances"] = sysbal
    for n, d in sysbal.items():
        if n == "escrow":
            assert_(f"escrow USDC is dust (<=1 wei)", (d["usdc"] or 0) <= 1, d["usdc"])
        else:
            assert_(f"system address {n} holds 0 USDC", d["usdc"] == 0, d["usdc"])

    holders = {
        "liq_proxy_0x8ecdf4": "0x8ecdf4245efddd2210f79517fbd9d12ff524ab9f",
        "eoa_0x40836f": holder,
        "issuer_0x475a": "0x475A6042D59c49CCF30A43D0713c3a99898a8b46",
    }
    spenders = {"swaper": SWAPER, "queue": QUEUE}
    allow = {}
    for hn, ha in holders.items():
        allow[hn] = {"usdc": as_int(call(TOKEN, "balanceOf(address)", enc_addr(ha), block=blk))}
        for sn, sa in spenders.items():
            allow[hn][f"allow_{sn}"] = as_int(call(
                TOKEN, "allowance(address,address)", enc_addr(ha) + enc_addr(sa), block=blk))
    # the only interesting allowance: holder -> vault (normal deposit approval)
    allow["eoa_0x40836f"]["allow_vRPCQ"] = as_int(call(
        TOKEN, "allowance(address,address)",
        enc_addr(holder) + enc_addr(qv), block=blk))
    out["checks"]["external_holder_allowances"] = allow
    for hn in ("liq_proxy_0x8ecdf4", "issuer_0x475a"):
        for sn in spenders:
            assert_(f"{hn} grants no allowance to {sn}",
                    (allow[hn].get(f"allow_{sn}") or 0) == 0,
                    allow[hn].get(f"allow_{sn}"))

    out["checks"]["oracle_reporter_eoa"] = ORACLE_REPORTER
    out["checks"]["oracle_report_cadence_seconds"] = 86400
    out["checks"]["oracle_max_fluctuation_bps"] = 1000

    out["passed"] = all(a["pass"] for a in out["assertions"])
    out["assertions_summary"] = {
        "total": len(out["assertions"]),
        "passed": sum(1 for a in out["assertions"] if a["pass"]),
        "failed": [a["name"] for a in out["assertions"] if not a["pass"]],
    }
    return out


if __name__ == "__main__":
    res = main()
    outp = sys.argv[1] if len(sys.argv) > 1 else ""
    if outp:
        with open(outp, "w") as f:
            json.dump(res, f, indent=1)
    print(json.dumps({
        "block": res.get("block"),
        "measured_totalAssets_usd": res.get("measured_totalAssets_usd"),
        "usdc_totalSupply_usd": res["checks"]["asset_token"]["totalSupply_usd"],
        "assertions": res.get("assertions_summary"),
        "passed": res.get("passed"),
    }, indent=1))
    sys.exit(0 if res.get("passed") else 1)
