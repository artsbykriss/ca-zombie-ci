#!/usr/bin/env bash
# Heavy job for the Streamflow (Solana) read-only financial-security study.
# Runs the full live-state enumeration + USD quantification + the simulation battery.
# Read-only: public keyless Solana JSON-RPC only (getAccountInfo / getProgramAccounts /
# getMultipleAccounts / simulateTransaction sigVerify=false). No keys, no signing, no sends.
set -euo pipefail

echo "== env =="; python3 --version; pwd
mkdir -p ci-out

cd analysis

echo "== 1/3 live-state enumeration + USD quantification =="
python3 enum_all.py 2>&1 | tee ../ci-out/enum.log || echo "enum_all failed (continuing)" | tee -a ../ci-out/enum.log

echo "== 2/3 simulation battery =="
python3 sim_battery.py 2>&1 | tee ../ci-out/sims.log || echo "sim_battery failed (continuing)" | tee -a ../ci-out/sims.log

echo "== 3/4 vesting program probe =="
timeout 1500 python3 vesting_probe.py 2>&1 | tee ../ci-out/vesting.log || echo "vesting_probe failed/timed out (continuing)" | tee -a ../ci-out/vesting.log

echo "== 4/4 reward-pool probe =="
timeout 900 python3 reward_probe.py 2>&1 | tee ../ci-out/reward.log || echo "reward_probe failed/timed out (continuing)" | tee -a ../ci-out/reward.log

echo "== collect artifacts =="
for f in live_state.json sims.json sim_state.json vesting_live.json reward_sims.json census.json programs.json; do
  [ -f "$f" ] && cp "$f" ../ci-out/ || true
done
ls -la ../ci-out
echo "== done =="
