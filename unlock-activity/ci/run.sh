#!/usr/bin/env bash
# Light live-state + activity dump for the Unlock governance sub-finding.
# Heavy work (fork tests) runs in the workflow's `forge test` step.
# No secrets / keyed URLs are written to ci-out (the repo is public).
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out

echo "[unlock-activity] dumping live state at latest Base block (public RPC fallback)"
python3 analysis/dump_live_state.py > ci-out/dump-stdout.txt 2> ci-out/dump-stderr.txt
rc=$?
echo "[unlock-activity] dump rc=$rc"
if [ -f ci-out/live-state.json ]; then
  python3 - <<'EOF'
import json
d=json.load(open('ci-out/live-state.json'))
print('block', d.get('block'), 'ts', d.get('timestamp'))
print('quorum', d['governor'].get('quorum'))
print('timelock', {k:d['timelock'].get(k) for k in ('UP','ETH','USDC','WETH')})
print('deployer votes', d['holders']['deployer_0x81dd'].get('votes'))
print('whale votes', d['holders']['whale_0xf5c2'].get('votes'))
print('safe votes', d['holders']['safe_0x3074'].get('votes'))
print('activity', d.get('activity',{}).get('n_proposals'), d.get('activity',{}).get('outcomes'))
EOF
fi

# keep the decoded full-history tables with the artifact
cp -f analysis/proposals.csv ci-out/proposals.csv 2>/dev/null || true
cp -f analysis/votes.csv ci-out/votes.csv 2>/dev/null || true
cp -f analysis/activity_summary.json ci-out/activity_summary.json 2>/dev/null || true

exit $rc
