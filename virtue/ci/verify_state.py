#!/usr/bin/env python3
"""Virtue (IOTA L1) — read-only live-state verification (public RPC only, no secrets).
Asserts the on-chain facts cited in the report and writes ci-out/state_check.json."""
import json, subprocess, sys, os, datetime

RPC = "https://api.mainnet.iota.cafe"

def rpc(method, params, retries=5):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    last = None
    for _ in range(retries):
        out = subprocess.run(["curl", "-s", "-m", "40", "-X", "POST", RPC,
                              "-H", "Content-Type: application/json", "-d", payload],
                             capture_output=True, text=True).stdout
        try:
            d = json.loads(out)
            if "result" in d:
                return d["result"]
            last = d
        except Exception as e:
            last = {"parse_error": str(e), "raw": out[:300]}
    return {"error": last}

def get_obj(oid, opts):
    r = rpc("iota_getObject", [oid, opts])
    return r.get("data") if isinstance(r, dict) else None

PKGS = {
    "framework": "0x7400af41a9b9d7e4502bc77991dbd1171f90855564fd28afa172a5057beb083b",
    "treasury":  "0xd3b63e603a78786facf65ff22e79701f3e824881a12fa3268d62a75530fe904f",
    "oracle":    "0x7eebbee92f64ba2912bdbfba1864a362c463879fc5b3eacc735c1dcb255cc2cf",
    "cdp_orig":  "0x34fa327ee4bb581d81d85a8c40b6a6b4260630a0ef663acfe6de0e8ca471dd22",
    "cdp_v2":    "0xcdeeb40cd7ffd7c3b741f40a8e11cb784a5c9b588ce993d4ab86479072386ba1",
    "sp_orig":   "0xc7ab9b9353e23c6a3a15181eb51bf7145ddeff1a5642280394cd4d6a0d37d83b",
    "sp_v2":     "0xe50fa492446245d9dd4bc61641a4ab2e72cd1276703d6ae8e41377a046b0929b",
    "recovery":  "0x732ce63849c64d630f256f2a926c90b309ffbc6a9a6806239088e1649ff8c952",
    "pyth_rule": "0xed5a8dac2ca41ae9bdc1c7f778b0949d3e26c18c51ed284c4cfa4030d0bb64c2",
    "sb_rule":   "0x39fb7adf0abd75b31868e17706b8600cc943bc27422fb582f6e14282029cd5f0",
}
VAULTS = {
    "IOTA":       "0xaf306be8419cf059642acdba3b4e79a5ae893101ae62c8331cefede779ef48d5",
    "CERT_swirl": "0xc9cb494657425f350af0948b8509efdd621626922e9337fd65eb161ec33de259",
    "IBTC":       "0xcc094d9e3b491b0c943bb18daf07a49bd951f34688f9610d90982de06fc0c5c9",
    "CERT_b":     "0x53b6405d2672be1e73f8ddea1766dbda57f1fed677be58fbfedc9fdddaafdd26",
}
SP = "0x6101272394511caf38ce5a6d120d3b4d009b6efabae8faac43aa9ac938cec558"
TREASURY = "0x81f525f4fa5b2d3cf58677d3e39aabc4b0a1ca25cbba605033cfe417e47b0a16"
TREASURYCAP = "0x0695bf8ccbe4e91970d5d95cfefda996b2fa913bca3724e91153017bcd345934"
AGG_IOTA = "0x052c40b4e8f16df5238457f3a7b3b0eeaa49c6bc8acc22f6a7790ab32495b2c6"
POS_ATTACKER = "0x2eeb8289676db61a0ae32502a358a1875cd89a6a22e20c80d1add4d16eb503a7"  # linked_table node of 0x381d5b5f.. in Vault<IOTA>
ATTACKER = "0x381d5b5fa3ae0ba5b3d0ce3421a43d48397cf6eb2a87e624d56dec5e68e7c7e9"

checks = []
def ck(name, cond, detail):
    checks.append({"check": name, "pass": bool(cond), "detail": detail})
    print(("PASS " if cond else "FAIL ") + name + " :: " + str(detail)[:180])

# 1. packages live
for k, pkg in PKGS.items():
    d = get_obj(pkg, {"showType": True, "showOwner": True})
    ck(f"pkg_live[{k}]", bool(d) and d.get("type") == "package", d.get("type") if d else None)

# 2. vaults + balances
vsum = {}
for k, v in VAULTS.items():
    d = get_obj(v, {"showType": True, "showContent": True})
    f = (d or {}).get("content", {}).get("fields", {})
    vsum[k] = {"type": (d or {}).get("type"), "balance": f.get("balance"),
               "supply": f.get("limited_supply", {}).get("fields", {}).get("supply")}
    ck(f"vault_live[{k}]", bool(d) and "vault::Vault" in (d.get("type") or ""), vsum[k])

# 3. the latent position (4.94M VUSD vs 1.027 IOTA)
d = get_obj(POS_ATTACKER, {"showContent": True})
f = (d or {}).get("content", {}).get("fields", {})
val = f.get("value", {}).get("fields", {}).get("value", {}).get("fields", {})
ck("latent_position_debt", str(val.get("debt_amount")) == "4942737620436", val.get("debt_amount"))
ck("latent_position_coll", str(val.get("coll_amount")) == "1027000000", val.get("coll_amount"))
ck("latent_position_owner", f.get("name") == "0x381d5b5fa3ae0ba5b3d0ce3421a43d48397cf6eb2a87e624d56dec5e68e7c7e9", f.get("name"))

# 4. SP balance + positions sum
d = get_obj(SP, {"showType": True, "showContent": True})
f = (d or {}).get("content", {}).get("fields", {})
ck("sp_vusd_balance", str(f.get("vusd_balance")) == "189497634597", f.get("vusd_balance"))

# 5. Treasury module versions: CDP empty (frozen), recovery registered
d = get_obj(TREASURY, {"showContent": True})
f = (d or {}).get("content", {}).get("fields", {})
mv = f.get("module_versions_map", {}).get("fields", {}).get("contents", [])
vers = {}
for e in mv:
    k = e["fields"]["key"]["fields"]["name"]
    v = e["fields"]["value"]["fields"]["contents"]
    vers[k] = v
cdp_key = [k for k in vers if "witness::VirtueCDP" in k]
rec_key = [k for k in vers if "recovery::VirtueRecovery" in k]
ck("treasury_cdp_versions_empty", bool(cdp_key) and vers[cdp_key[0]] == [], vers)
ck("treasury_recovery_v1", bool(rec_key) and vers[rec_key[0]] == ["1"], vers)

# 6. VUSD supply
d = get_obj(TREASURYCAP, {"showContent": True})
f = (d or {}).get("content", {}).get("fields", {})
ck("vusd_total_supply", str(f.get("total_supply", {}).get("fields", {}).get("value")) == "5197561500789",
   f.get("total_supply"))

# 7. IOTA aggregator weights: switchboard 0, pyth 1
d = get_obj(AGG_IOTA, {"showContent": True})
f = (d or {}).get("content", {}).get("fields", {})
w = {e["fields"]["key"]["fields"]["name"]: e["fields"]["value"]
     for e in f.get("weights", {}).get("fields", {}).get("contents", [])}
pyth_w = [v for k, v in w.items() if "pyth_rule::PythRule" in k]
sb_w = [v for k, v in w.items() if "switchboard_rule::SwitchboardRule" in k]
ck("agg_pyth_weight_1", pyth_w == [1], w)
ck("agg_switchboard_absent_or_0", sb_w in ([], [0]), w)

# 8. attacker still holds VUSD
r = rpc("iotax_getBalance", [ATTACKER, "0xd3b63e603a78786facf65ff22e79701f3e824881a12fa3268d62a75530fe904f::vusd::VUSD"])
ck("attacker_vusd_balance", str((r or {}).get("totalBalance")) == "4146017571771", (r or {}).get("totalBalance"))

latest = rpc("iota_getLatestCheckpointSequenceNumber", [])
print("\nlatest checkpoint:", latest)
failed = [c for c in checks if not c["pass"]]
print(f"\nSTATE SUMMARY: {len(checks)-len(failed)}/{len(checks)} checks passed")
os.makedirs("ci-out", exist_ok=True)
with open("ci-out/state_check.json", "w") as fp:
    json.dump({"timestamp": datetime.datetime.utcnow().isoformat() + "Z",
               "latest_checkpoint": latest, "checks": checks, "all_passed": not failed}, fp, indent=1)
sys.exit(0 if not failed else 1)
