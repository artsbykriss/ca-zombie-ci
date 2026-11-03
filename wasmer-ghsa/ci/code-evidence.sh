#!/usr/bin/env bash
# Code-level evidence for the GHSA-v2h8-j899-r676 range question.
# Fetches lib/compiler-singlepass/src/codegen.rs at the two released 7.x tags and at main,
# then shows whether the vulnerable implicit-else lowering and the fix are present.
set -uo pipefail
REPO="wasmerio/wasmer"
PATH_IN_REPO="lib/compiler-singlepass/src/codegen.rs"
tmp="$(mktemp -d)"
echo "# codegen.rs evidence — $(date -u +%FT%TZ)"
echo "# repo=$REPO path=$PATH_IN_REPO"
for ref in v7.4.2 v7.5.0 main; do
  f="$tmp/codegen-$ref.rs"
  code=$(curl -4 -sSL -A "Mozilla/5.0 (ci)" -o "$f" -w "%{http_code}" \
    "https://raw.githubusercontent.com/$REPO/$ref/$PATH_IN_REPO")
  echo
  echo "## $ref  http=$code  bytes=$(wc -c < "$f")  md5=$(md5sum "$f" | cut -d' ' -f1)"
done
echo
echo "## diff v7.4.2 -> v7.5.0 (empty means byte-identical)"
diff -q "$tmp/codegen-v7.4.2.rs" "$tmp/codegen-v7.5.0.rs" && echo "IDENTICAL"
echo
echo "## vulnerable-lowering markers in v7.5.0"
grep -n "param_types.len() == return_types.len()" "$tmp/codegen-v7.5.0.rs"
grep -n "We might hit a situation where an Operator::If is missing an Operator::Else" "$tmp/codegen-v7.5.0.rs"
grep -n "fn emit_if_block_end" "$tmp/codegen-v7.5.0.rs" || echo "emit_if_block_end: ABSENT (expected on vulnerable builds)"
echo
echo "## fix markers in main"
grep -n "fn emit_if_block_end" "$tmp/codegen-main.rs"
grep -n "emit_if_block_end(was_unreachable)" "$tmp/codegen-main.rs"
echo
echo "## releases"
curl -4 -sS -A "Mozilla/5.0 (ci)" "https://api.github.com/repos/$REPO/releases?per_page=5" \
  | python3 -c 'import json,sys
for r in json.load(sys.stdin): print(r["tag_name"], r["published_at"], "prerelease" if r["prerelease"] else "")'
echo
echo "## fix PR"
curl -4 -sS -A "Mozilla/5.0 (ci)" "https://api.github.com/repos/$REPO/pulls/7128" \
  | python3 -c 'import json,sys
d=json.load(sys.stdin)
print("number",d.get("number"),"merged",d.get("merged"),"merged_at",d.get("merged_at"))
print("title",d.get("title"))
print("merge_commit",d.get("merge_commit_sha"),"base",(d.get("base") or {}).get("ref"))
print("changed_files",d.get("changed_files"),"+",d.get("additions"),"-",d.get("deletions"))'
rm -rf "$tmp"
