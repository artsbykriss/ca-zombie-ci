#!/usr/bin/env bash
# Heavy job for ZH4-05 Faiyah Staking: live state scan, wei-exact math check,
# full stake enumeration for the two live XEF pools and the locked 2027 pools.
# Read-only. No secrets. Results -> ../ci-out/ (uploaded as artifact).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
cd analysis

python3 -m pip install --quiet requests >/dev/null 2>&1 || true

echo "== scan all 46 pools =="
python3 scan_v2.py > ../ci-out/scan.log 2>&1
cp pools_state_v2.json ../ci-out/

echo "== wei-exact reward math =="
python3 verify_math.py > ../ci-out/verify_math.log 2>&1
cp verify_math.json ../ci-out/

echo "== enumerate #41/#42 (claimable now) =="
python3 enumerate_claims.py 41,42 --out ../ci-out/claims_4142.json > ../ci-out/claims_4142.log 2>&1

echo "== enumerate #33/#37/#44/#45/#21 (locked accrued) =="
python3 enumerate_claims.py 33,37,44,45,21 --out ../ci-out/claims_locked.json > ../ci-out/claims_locked.log 2>&1

echo "== monitor snapshot =="
python3 monitor.py --baseline monitor_baseline.json --out ../ci-out/monitor_snapshot.json > ../ci-out/monitor.log 2>&1 || true

echo "== summary =="
python3 - <<'PY' > ../ci-out/summary.txt
import json
for name in ('claims_4142.json','claims_locked.json'):
    try:
        d=json.load(open('../ci-out/'+name))
    except Exception as e:
        print(name,'ERR',e); continue
    print(name,'block',d['block'])
    for k,v in d['pools'].items():
        print(' #%s accrued=%s claimableNow=%s count=%s bad=%s' % (
            k, v['accruedTotal'], v['claimableNow'], v['claimableNowCount'], v['badReads']))
PY
cat ../ci-out/summary.txt
echo "DONE"
