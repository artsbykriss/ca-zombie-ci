#!/usr/bin/env bash
# Watch a GitHub CI run and fetch logs/artifacts into the folder.
# Usage: bash ci/gh-fetch.sh <run_id>
set -uo pipefail
RUN="${1:?usage: gh-fetch.sh <run_id>}"
ENV_FILE="/home/heisenberg/CA/.env"
GH_KEY=$(grep '^CHRIS_GITHUB_API_KEY=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"')
[ -n "$GH_KEY" ] && export GH_TOKEN="$GH_KEY"
REPO="artsbykriss/ca-zombie-ci"
cd "$(dirname "$0")/.."

echo "[ci] watching run $RUN"
for i in $(seq 1 200); do
  ST=$(gh run view "$RUN" --repo "$REPO" --json status,conclusion -q '.status + " " + (.conclusion // "")' 2>/dev/null)
  echo "[ci] $ST ($(date -u +%H:%M:%S))"
  case "$ST" in completed*) break;; esac
  sleep 60
done

echo "[ci] final: $(gh run view "$RUN" --repo "$REPO" --json status,conclusion -q '.status + " " + (.conclusion // "")' 2>/dev/null)"
gh run view "$RUN" --repo "$REPO" --log > ci-log.txt 2>/dev/null || true
rm -rf ci-artifacts; mkdir -p ci-artifacts
gh run download "$RUN" --repo "$REPO" -D ci-artifacts 2>/dev/null || echo "[ci] no artifacts"
mkdir -p ci-out
find ci-artifacts -path '*ci-out*' -type f -exec cp -f {} ci-out/ \; 2>/dev/null || true
ls -la ci-out/ ci-artifacts/ 2>/dev/null | head -20
