#!/usr/bin/env bash
# symbols.sh — Phase E: pclntab function inventory for the downloaded binaries
# (works even when the ELF symbol table is stripped). READ-ONLY static analysis.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../ci-out"
DL="/tmp/cwa006-bin"
mkdir -p "$OUT/symbols"

echo "=== build pclntab_dump ==="
( cd "$HERE/pclntab_dump" && go build -o /tmp/pclntab_dump . ) 2>&1 | head -5 || true
[ -x /tmp/pclntab_dump ] || { echo "pclntab_dump build failed"; exit 0; }

for name in $(python3 -c "import json;print(' '.join(json.load(open('$OUT/binfp.json')).keys()))" 2>/dev/null); do
  # find the downloaded binary for this chain
  BIN=""
  for cand in "$DL/$name.bin" $(find "$DL/$name" -type f -size +5M 2>/dev/null); do
    [ -f "$cand" ] && head -c4 "$cand" | grep -q $'\x7fELF' && BIN="$cand" && break
  done
  [ -z "$BIN" ] && { echo "[E] $name: no binary"; continue; }
  echo "[E] $name: $BIN"
  timeout 1200 /tmp/pclntab_dump "$BIN" > "$OUT/symbols/$name.functions.txt" 2>"$OUT/symbols/$name.err" || true
  N=$(wc -l < "$OUT/symbols/$name.functions.txt" 2>/dev/null || echo 0)
  echo "[E] $name: $N functions"
  {
    echo "## $name ($BIN)"
    echo "## cgo / Go re-entry symbols"
    grep -E 'runtime\.cgocallback|crosscall2|runtime\.needm|runtime\.asmcgocall' "$OUT/symbols/$name.functions.txt" | head -20
    echo "## wasmvm callbacks (cSet/cGet/cQueryExternal/_cgoexp)"
    grep -E 'internal/api\.(cSet|cGet|cDelete|cQueryExternal)|_cgoexp_.*(cSet|cGet|cQueryExternal)' "$OUT/symbols/$name.functions.txt" | head -30
    echo "## bank/mint call targets"
    grep -Ei '(BaseKeeper|mintbankkeeper|x/mint/keeper|BaseSendKeeper)\.(MintCoins|SendCoins|addCoins|setBalance)' "$OUT/symbols/$name.functions.txt" | head -40
    echo "## sdk.Context / itab"
    grep -Ei 'types\.Context\.(KVStore|CacheContext|Value)|go:itab' "$OUT/symbols/$name.functions.txt" | head -20
  } > "$OUT/symbols/$name.report.txt" 2>&1
done
ls -la "$OUT/symbols" | head -30
