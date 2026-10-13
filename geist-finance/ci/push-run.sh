#!/usr/bin/env bash
# Fast CI path for geist-finance on the new GitHub CI account (artsbykriss/ca-zombie-ci):
# shallow clone + rsync + force-push + dispatch + wait + fetch logs/artifacts.
# Usage: bash ci/push-run.sh
set -uo pipefail
ENV_FILE="/home/heisenberg/CA/.env"
GH_KEY=$(grep '^CHRIS_GITHUB_API_KEY=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"')
[ -n "$GH_KEY" ] && export GH_TOKEN="$GH_KEY"
REPO="artsbykriss/ca-zombie-ci"
FOLDER="geist-finance"
SRC="/home/heisenberg/CA/$FOLDER"
WORK="/tmp/opencode/geist-work2"

mkdir -p "$WORK"
cd "$WORK"
if [ ! -d .git ]; then
  git init -q && git remote add origin "https://github.com/$REPO.git"
fi
git remote set-url origin "https://github.com/$REPO.git"
git fetch --depth 1 --filter=blob:none origin main -q || { echo "fetch failed"; exit 1; }
git checkout -q -B "$FOLDER" FETCH_HEAD

rsync -a --delete \
  --exclude '.git/' --exclude 'out/' --exclude 'cache/' --exclude 'ci-artifacts/' \
  --exclude 'ci-log.txt' --exclude 'gitlab-log.txt' --exclude '*.pyc' --exclude '__pycache__/' \
  "$SRC/" "$FOLDER/"

git add -A "$FOLDER" >/dev/null
git -c user.name="zombie-ci" -c user.email="zombie-ci@users.noreply.github.com" \
    commit -q -m "ci: $FOLDER $(date -u +%FT%TZ)" || echo "[ci] no changes"
git push -f origin "$FOLDER" -q || { echo "push failed"; exit 1; }
echo "[ci] pushed branch $FOLDER"

gh workflow run poc.yml --repo "$REPO" --ref "$FOLDER" -f finding="$FOLDER" >/dev/null 2>&1 \
  || { echo "dispatch failed"; exit 1; }

RUN_ID=""
for i in $(seq 1 60); do
  sleep 5
  RUN_ID=$(gh run list --repo "$REPO" --workflow poc.yml --limit 40 \
             --json databaseId,headBranch \
             -q "[.[] | select(.headBranch == \"$FOLDER\") | .databaseId] | first" 2>/dev/null)
  [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ] && break
done
[ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ] && { echo "no run found"; exit 1; }
echo "[ci] run: https://github.com/$REPO/actions/runs/$RUN_ID"
gh run watch "$RUN_ID" --repo "$REPO" --interval 20 >/dev/null 2>&1
CONCLUSION=$(gh run view "$RUN_ID" --repo "$REPO" --json conclusion -q '.conclusion' 2>/dev/null)
echo "[ci] conclusion: $CONCLUSION"
gh run view "$RUN_ID" --repo "$REPO" --log > "$SRC/ci-log.txt" 2>/dev/null || true
rm -rf "$SRC/ci-artifacts"; mkdir -p "$SRC/ci-artifacts"
gh run download "$RUN_ID" --repo "$REPO" -D "$SRC/ci-artifacts" 2>/dev/null || true
# merge any ci-out produced by the run into the local ci-out (so later runs can skip the rescan)
if [ -d "$SRC/ci-artifacts" ]; then
  find "$SRC/ci-artifacts" -path '*ci-out*' -type f -exec cp -f {} "$SRC/ci-out/" \; 2>/dev/null || true
fi
ls -la "$SRC/ci-out" "$SRC/ci-artifacts" 2>/dev/null
echo "RUN_URL=https://github.com/$REPO/actions/runs/$RUN_ID"
[ "$CONCLUSION" = "success" ] || exit 1
