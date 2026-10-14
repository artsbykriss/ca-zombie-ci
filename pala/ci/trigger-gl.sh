#!/usr/bin/env bash
# Focused retry: trigger a GitLab pipeline for the already-pushed gl-ci branch and wait for it.
set -uo pipefail
TOKEN=$(grep '^GITLAB_ACCESS_TOKEN=' /home/heisenberg/CA/.env | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/^"//;s/"$//')
PID=87640433
OUT=/tmp/opencode/pala-gl-trigger.log
: > "$OUT"

trigger() {
  curl -s -m 60 -H "PRIVATE-TOKEN: $TOKEN" -X POST \
    "https://gitlab.com/api/v4/projects/$PID/pipeline" --data "ref=gl-ci" 2>/dev/null
}

for i in $(seq 1 40); do
  R=$(trigger)
  PIPE=$(echo "$R" | python3 -c "import sys,json
try:
    d=json.load(sys.stdin); print(d.get('id',''))
except Exception:
    print('')" 2>/dev/null)
  if [ -n "$PIPE" ]; then
    echo "pipeline $PIPE triggered (attempt $i)" | tee -a "$OUT"
    break
  fi
  echo "attempt $i: no pipeline id ($(echo "$R" | head -c 120))" >> "$OUT"
  sleep 30
done
[ -n "${PIPE:-}" ] || { echo "FAILED to trigger"; exit 1; }

# wait for completion
for j in $(seq 1 90); do
  sleep 20
  S=$(curl -s -m 60 -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/$PID/pipelines/$PIPE" 2>/dev/null | python3 -c "import sys,json
try:
    d=json.load(sys.stdin); print(d.get('status',''))
except Exception:
    print('')" 2>/dev/null)
  echo "poll $j: status=$S" >> "$OUT"
  case "$S" in success|failed|canceled|skipped) break;; esac
done
echo "FINAL_STATUS=$S pipeline=$PIPE" | tee -a "$OUT"

# fetch job trace
JOB=$(curl -s -m 60 -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/$PID/pipelines/$PIPE/jobs" 2>/dev/null | python3 -c "import sys,json
try:
    d=json.load(sys.stdin); print(d[0]['id'] if d else '')
except Exception:
    print('')" 2>/dev/null)
echo "JOB=$JOB" >> "$OUT"
if [ -n "$JOB" ]; then
  curl -s -m 90 -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/$PID/jobs/$JOB/trace" -o /home/heisenberg/CA/pala/gitlab-log.txt
  curl -sL -m 120 -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/$PID/jobs/$JOB/artifacts" -o /tmp/opencode/pala-gl-art2.zip
  mkdir -p /home/heisenberg/CA/pala/gitlab-artifacts && unzip -o /tmp/opencode/pala-gl-art2.zip -d /home/heisenberg/CA/pala/gitlab-artifacts >/dev/null 2>&1
  ls -la /home/heisenberg/CA/pala/gitlab-artifacts/
fi
[ "$S" = "success" ] || exit 1
