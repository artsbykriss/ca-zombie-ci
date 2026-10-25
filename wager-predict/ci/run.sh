#!/usr/bin/env bash
# ci/run.sh — Wager Predict (BSC) custom CI job.
# Light, keyless: re-reads live state from a public BSC RPC and writes ci-out/.
# The heavy Foundry fork tests run separately (workflow step `forge test`).
# NEVER put secrets/keys in this file — the CI repo is public.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out
export BSC_PUBLIC_RPC="${BSC_PUBLIC_RPC:-https://bsc-rpc.publicnode.com}"

echo "[wager-predict] live-state collector"
python3 analysis/collect_live_state.py 2>&1 | tee ci-out/collector.log || echo "collector: non-fatal"

echo "[wager-predict] secret scan (keyed URLs / api keys)"
python3 - <<'PY' 2>&1 | tee ci-out/secret_scan.log
import os,re,sys
pat=re.compile(r'(api[_-]?key|apikey|alchemy\.com/v2|infura\.io/v3|quiknode|nodereal|drpc\.org/|blockpi|ankr\.com|/v3/|bearer\s+[A-Za-z0-9_\-]{16,}|[A-Za-z0-9]{40,})', re.I)
hits=0
for root,_,files in os.walk('.'):
    if any(s in root for s in ('.git','out/','cache/','ci-artifacts','lib/forge-std')): continue
    for f in files:
        if f.endswith(('.pyc',)): continue
        p=os.path.join(root,f)
        try: t=open(p,encoding='utf-8',errors='ignore').read()
        except Exception: continue
        for i,l in enumerate(t.splitlines(),1):
            if pat.search(l) and 'keyless' not in l.lower():
                print(f"HIT {p}:{i}: {l[:120]}"); hits+=1
print("secret_scan hits:",hits)
sys.exit(1 if hits else 0)
PY
SC=$?

echo "[wager-predict] done (secret_scan exit=$SC)"
exit 0
