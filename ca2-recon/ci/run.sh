#!/usr/bin/env bash
# CA2-recon CI: validate the disposition table and re-run the read-only OPEN sanity checks.
# Public RPCs only. No keys, no transactions.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "[ca2-recon] validating candidate table"
python3 analysis/gen.py > ci-out/counts.json
python3 analysis/render.py
python3 analysis/build_readme.py
python3 analysis/prior_coverage.py

python3 - <<'PY' > ci-out/validation.txt
import json,csv,sys,re
rows=list(csv.DictReader(open("analysis/candidates.csv")))
counts=json.load(open("analysis/counts.json"))
ok=True
def check(name,cond,detail=""):
    global ok
    print(("PASS" if cond else "FAIL"), name, detail)
    ok = ok and cond

check("row count == 198", len(rows)==198, f"got {len(rows)}")
check("counts.enumerated matches", counts["enumerated"]==len(rows))
disp={}
for r in rows: disp[r["disposition"]]=disp.get(r["disposition"],0)+1
check("disposition sum == rows", sum(disp.values())==len(rows), json.dumps(disp,sort_keys=True))
allowed={"README-CRITICAL","README-HIGH","README-LOW","README-REJECTED","AGENT-ONLY-LEAD","PRIOR-COVERED","PRIOR-PARTIAL","NOT-A-PROTOCOL","OPEN"}
bad=set(disp)-allowed
check("all dispositions allowed", not bad, str(bad))
opens=[r for r in rows if r["disposition"]=="OPEN"]
check("OPEN rows == 9", len(opens)==9, f"got {len(opens)}")
check("every OPEN names an address/program", all(re.search(r"0x|T[A-Za-z0-9]{20,}|C[A-Z0-9]{20,}|[0-9a-f]{40,}|[a-z0-9_.]+\.near", r["candidate"]+r["basis"]+r["funds_or_at_risk"]) for r in opens))
check("README has OPEN section", "## 4. OPEN list" in open("README.md").read())
check("README contains each OPEN name", all(r["candidate"].split(" ")[0] in open("README.md").read() for r in opens))
# secret scan: keyed URLs / env assignments / long hex secrets
import subprocess
pat=r"(ALCHEMY_API_KEY=|INFURA_API_KEY=|DRPC_API_KEY=|ankr\.com/v2/|g\.alchemy\.com/v2/[A-Za-z0-9_-]{12,}|api\.etherscan\.io/v2/api\?.*apikey=)"
scan=subprocess.run(["grep","-rInE",pat,"README.md","analysis","ci-out/live-checks.json","ci-out/counts.json"],capture_output=True,text=True)
hits=[l for l in scan.stdout.splitlines()]
check("no keyed URLs / secret assignments", not hits, "; ".join(hits[:3]))
print("RESULT", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
PY

cat ci-out/validation.txt

echo "[ca2-recon] live read-only checks"
python3 analysis/live_checks.py ci-out/live-checks.json > ci-out/live-checks.log 2>&1 || echo "live checks partially failed (see log)"
python3 - <<'PY' | tee ci-out/live-summary.txt
import json
d=json.load(open("ci-out/live-checks.json"))["checks"]
r=d["r25_pharos"]
ad=r.get("asset_decimals") or 6
usd=sum(v["totalAssets_raw"]/(10**ad) for v in r["vaults"] if v["totalAssets_raw"])
print("R25 block", r["block"], "vaults", len(r["vaults"]), "asset_decimals", ad, "measured_usd", round(usd,2))
print("Gambit", d["gambit_bsc"]["usdt"], d["gambit_bsc"]["wbnb"], d["gambit_bsc"]["redeem_1000_usdt"])
print("ApolloX", d["apollox_bsc"])
print("Tron block", d["tron_trio"]["block"])
for c in d["tron_trio"]["contracts"]:
    print("Tron", c["address"], c.get("balance_sun"), c.get("constant_result"), c.get("energy_used"))
PY

echo "[ca2-recon] done"
