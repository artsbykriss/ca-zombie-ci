#!/usr/bin/env bash
# Retry dispatch + wait + fetch artifacts for bril-finance (network-flaky fallback).
set -uo pipefail
export GH_TOKEN=$(grep '^CHRIS_GITHUB_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
REPO=artsbykriss/ca-zombie-ci
BR=bril-finance
FOLDER=/home/heisenberg/CA/bril-finance

echo "[dispatch] attempt loop"
for i in $(seq 1 12); do
  if gh workflow run poc.yml --repo "$REPO" --ref "$BR" -f finding="$BR" 2>&1; then
    echo "[dispatch] ok on attempt $i"; break
  fi
  echo "[dispatch] attempt $i failed, retry in 15s"
  sleep 15
done

echo "[wait] polling for run"
RUN_ID=""
for i in $(seq 1 120); do
  sleep 10
  RUN_ID=$(gh run list --repo "$REPO" --workflow poc.yml --limit 40 --json databaseId,headBranch,createdAt \
      -q "[.[] | select(.headBranch == \"$BR\")] | first | .databaseId" 2>/dev/null)
  if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then echo "[wait] run $RUN_ID"; break; fi
done
[ -z "$RUN_ID" ] && { echo "no run found"; exit 1; }

for i in $(seq 1 180); do
  st=$(gh run view "$RUN_ID" --repo "$REPO" --json status,conclusion -q '.status + " " + (.conclusion // "")' 2>/dev/null)
  echo "[wait] $st"
  case "$st" in
    completed*) break;;
  esac
  sleep 15
done

gh run view "$RUN_ID" --repo "$REPO" --log > "$FOLDER/ci-log.txt" 2>/dev/null || true
rm -rf "$FOLDER/ci-artifacts"; mkdir -p "$FOLDER/ci-artifacts"
gh run download "$RUN_ID" --repo "$REPO" --dir "$FOLDER/ci-artifacts" 2>&1 || true
echo "[done] run https://github.com/$REPO/actions/runs/$RUN_ID"
ls -R "$FOLDER/ci-artifacts" | head -20
