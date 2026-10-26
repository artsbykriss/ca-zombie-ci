#!/usr/bin/env python3
"""Extract the access-control map for every store instruction at a given commit.

Parses programs/store/src/lib.rs, associating each `pub fn <name>` with any preceding
#[access_control(...)] attribute, and classifies by the role/authority required.
"""
import re, subprocess, sys, json, os

REPO = "/tmp/opencode/gmx-solana-repo"
HERE = os.path.dirname(os.path.abspath(__file__))
COMMIT = sys.argv[1] if len(sys.argv) > 1 else "8af1e70"

src = subprocess.run(["git", "-C", REPO, "show", f"{COMMIT}:programs/store/src/lib.rs"],
                     capture_output=True, text=True).stdout
lines = src.splitlines()

insns = []
cur_ac = []
for i, ln in enumerate(lines):
    m = re.search(r"#\[access_control\((.*)\)\]", ln)
    if m:
        cur_ac.append(m.group(1))
    fm = re.match(r"\s+pub fn ([a-z0-9_]+)", ln)
    if fm:
        name = fm.group(1)
        insns.append({"name": name, "access_control": list(cur_ac), "line": i + 1})
        cur_ac = []
    elif ln.strip() and not ln.strip().startswith("//") and not ln.strip().startswith("#[") \
            and not re.match(r"\s+(pub fn|[a-z_]+:)", ln) and cur_ac:
        # reset accumulated attribute if we hit unrelated code
        if "fn " not in ln:
            cur_ac = []

def classify(ac):
    s = " ".join(ac)
    if not s:
        return "NONE"
    roles = re.findall(r"only_[a-z_]+|only\(", s)
    if "only_oracle_controller" in s: return "ORACLE_CONTROLLER"
    if "only_gt_controller" in s: return "GT_CONTROLLER"
    if "only_market_keeper" in s: return "MARKET_KEEPER"
    if "only_market_config_keeper" in s: return "MARKET_CONFIG_KEEPER"
    if "only_order_keeper" in s: return "ORDER_KEEPER"
    if "only_price_keeper" in s: return "PRICE_KEEPER"
    if "only_feature_keeper" in s: return "FEATURE_KEEPER"
    if "only_config_keeper" in s: return "CONFIG_KEEPER"
    if "only_admin" in s: return "ADMIN"
    if "ensure_has_any_role" in s:
        rr = re.search(r"ensure_has_any_role_with_ctx\(\s*ctx,\s*\[(.*?)\]", s)
        return "ANY[" + (rr.group(1).replace(" ", "") if rr else "?") + "]"
    return "OTHER:" + s[:80]

out = []
for it in insns:
    it["gate"] = classify(it["access_control"])
    out.append(it)

ungated = [i for i in out if i["gate"] == "NONE"]
print(f"commit {COMMIT}: {len(out)} instructions, {len(ungated)} with NO access_control gate\n")
print("=== UNGATED (no #[access_control]) ===")
for i in ungated:
    print(f"  {i['name']}")
print("\n=== GATED ===")
for i in out:
    if i["gate"] != "NONE":
        print(f"  {i['gate']:22s} {i['name']}")

with open(os.path.join(HERE, f"access_control_map_{COMMIT}.json"), "w") as f:
    json.dump(out, f, indent=2)
