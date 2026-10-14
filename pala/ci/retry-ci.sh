#!/usr/bin/env bash
# Retry loop: push Pala CI via GitHub; if it fails, try GitLab; repeat.
set -uo pipefail
LOGDIR=/tmp/opencode
for attempt in 1 2 3 4 5 6; do
  echo "=== attempt $attempt $(date -u +%H:%M:%S) ==="
  bash /home/heisenberg/CA/ci/ci-run.sh pala > "$LOGDIR/pala-ci-retry-$attempt.log" 2>&1
  rc=$?
  echo "github attempt $attempt exit=$rc"
  if [ $rc -eq 0 ]; then
    echo "GITHUB_CI_SUCCESS attempt=$attempt"
    exit 0
  fi
  # check if the failure was only the push (transient) — try gitlab next
  bash /home/heisenberg/CA/ci/gitlab-run.sh pala /home/heisenberg/CA/pala/ci/gitlab-pala.yml > "$LOGDIR/pala-gl-retry-$attempt.log" 2>&1
  rc2=$?
  echo "gitlab attempt $attempt exit=$rc2"
  if [ $rc2 -eq 0 ]; then
    echo "GITLAB_CI_SUCCESS attempt=$attempt"
    exit 0
  fi
  sleep 20
done
echo "ALL_ATTEMPTS_FAILED"
exit 1
