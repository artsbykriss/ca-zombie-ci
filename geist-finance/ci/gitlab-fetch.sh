#!/usr/bin/env bash
# Fetch artifacts (ci-out/) from the latest geist-finance GitLab pipeline into ci-artifacts/.
# Usage: bash ci/gitlab-fetch.sh <pipeline_id>
set -uo pipefail
PID="${1:?usage: gitlab-fetch.sh <pipeline_id>}"
PROJ=87588756
TOKEN=$(grep '^GITLAB_ACCESS_TOKEN=' /home/heisenberg/CA/.env | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/^"//;s/"$//')
API="https://gitlab.com/api/v4"
cd "$(dirname "$0")/.."

echo "== pipeline $PID =="
for i in $(seq 1 150); do
  ST=$(curl -sS -H "PRIVATE-TOKEN: $TOKEN" "$API/projects/$PROJ/pipelines/$PID" 2>/dev/null \
       | python3 -c "import json,sys;print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
  echo "[gl] status=$ST ($(date -u +%H:%M:%S))"
  case "$ST" in success|failed|canceled|skipped) break;; esac
  sleep 60
done

echo "== jobs =="
curl -sS -H "PRIVATE-TOKEN: $TOKEN" "$API/projects/$PROJ/pipelines/$PID/jobs" -o /tmp/opencode/gl-jobs-final.json
python3 -c "
import json
for j in json.load(open('/tmp/opencode/gl-jobs-final.json')):
    print(j['id'], j['name'], j['status'], j.get('web_url'))
"
mkdir -p ci-artifacts
python3 -c "
import json
ids=[str(j['id']) for j in json.load(open('/tmp/opencode/gl-jobs-final.json')) if j['name'] in ('scan','poc')]
print('\n'.join(ids))
" > /tmp/opencode/gl-art-jobids.txt
while read -r JOB; do
  [ -z "$JOB" ] && continue
  echo "[gl] downloading artifacts of job $JOB"
  if curl -sS -f -H "PRIVATE-TOKEN: $TOKEN" "$API/projects/$PROJ/jobs/$JOB/artifacts" -o "/tmp/opencode/gl-art-$JOB.zip"; then
    unzip -o -q "/tmp/opencode/gl-art-$JOB.zip" -d ci-artifacts/ && echo "  ok"
  else
    echo "  no artifacts"
  fi
done < /tmp/opencode/gl-art-jobids.txt
# keep a copy of the scan results in ci-out/ so a later CI run can skip the rescan
if [ -d ci-artifacts/ci-out ]; then cp -f ci-artifacts/ci-out/* ci-out/ 2>/dev/null || true; fi
ls -la ci-artifacts/ ci-out/ 2>/dev/null | head -25
