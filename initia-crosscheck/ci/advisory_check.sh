#!/usr/bin/env bash
# Has the CWA-2026-006 withheld trigger detail been published? (advisory promised it
# "once chains have had a chance to upgrade"). Also records the current advisory blob SHA.
set -uo pipefail
cd "$(dirname "$0")/.."
O=ci-out; mkdir -p "$O"
OUT="$O/advisory_freshness.txt"; : > "$OUT"
say(){ echo "$@" | tee -a "$OUT"; }

say "== CWA-2026-006 advisory freshness $(date -u +%FT%TZ) =="
RAW="https://raw.githubusercontent.com/CosmWasm/advisories/main/CWAs/CWA-2026-006.md"
curl -sSL -o "$O/CWA-2026-006.md" "$RAW"
say "fetched: $(wc -l < "$O/CWA-2026-006.md") lines"
say "sha256:  $(sha256sum "$O/CWA-2026-006.md" | cut -d' ' -f1)"
say ""
say "withheld-detail marker present? (should still be true if unpublished):"
grep -n "More detail will be added" "$O/CWA-2026-006.md" | sed 's/^/  /' | tee -a "$OUT" || say "  NOT PRESENT (detail may have been published)"
say ""
say "exploitation-in-production line:"
grep -n "no reports of this vulnerability being exploited in production" "$O/CWA-2026-006.md" | sed 's/^/  /' | tee -a "$OUT" || true
say ""
say "advisory repo commit history (last 5 commits touching this file):"
curl -sSL "https://api.github.com/repos/CosmWasm/advisories/commits?path=CWAs/CWA-2026-006.md&per_page=5" \
  | grep -E '"date"|"message"' | head -20 | sed 's/^/  /' | tee -a "$OUT" || say "  (api failed)"

say ""
say "== Hexens WASMageddon (public root-cause write-up, 2026-09-29) =="
curl -sSL -o "$O/hexens_wasmageddon.html" "https://hexens.io/research/wasmer-sandbox-escape-rce" || true
if [ -s "$O/hexens_wasmageddon.html" ]; then
  say "page bytes: $(wc -c < "$O/hexens_wasmageddon.html")"
  say "mentions release_locations_value: $(grep -c release_locations_value "$O/hexens_wasmageddon.html")"
  say "mentions 'deliberately omits': $(grep -c 'deliberately omits' "$O/hexens_wasmageddon.html")"
fi
say "== DONE =="
