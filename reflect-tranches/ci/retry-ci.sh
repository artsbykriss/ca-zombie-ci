#!/usr/bin/env bash
# Retry the CI helper until it produces a run; fall back to GitLab.
set -uo pipefail
FOLDER=reflect-tranches
LOG=/home/heisenberg/CA/$FOLDER/ci-run-1.log
for i in 1 2 3 4 5 6 7 8; do
  echo "===== attempt $i $(date -u +%FT%TZ) =====" | tee -a "$LOG"
  rm -rf "/tmp/opencode/ca-zombie-ci-$FOLDER"
  if bash /home/heisenberg/CA/ci/ci-run.sh "$FOLDER" >>"$LOG" 2>&1; then
    echo "GITHUB CI OK on attempt $i" | tee -a "$LOG"
    exit 0
  fi
  sleep 15
done
echo "===== github failed; trying gitlab =====" | tee -a "$LOG"
for i in 1 2 3; do
  if bash /home/heisenberg/CA/ci/gitlab-run.sh "$FOLDER" >>"$LOG" 2>&1; then
    echo "GITLAB CI OK on attempt $i" | tee -a "$LOG"
    exit 0
  fi
  sleep 20
done
echo "ALL CI ATTEMPTS FAILED" | tee -a "$LOG"
exit 1
