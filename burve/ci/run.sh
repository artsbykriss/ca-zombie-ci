#!/usr/bin/env bash
# Light custom CI job for the Burve finding: re-dump the LIVE diamond state (keyless public RPCs)
# into ci-out/. No secrets, no transactions. Read-only.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
OUT=ci-out/burve-live-state.txt
{
  echo "== Burve live-state dump =="
  date -u +%FT%TZ
  echo
  echo "--- diamond tokens / vertices / owner ---"
  python3 - <<'PY'
import sys
sys.path.insert(0, "analysis")
from bera import rpc, call, words, addr
D = "0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089"
blk = int(rpc("eth_blockNumber", []), 16)
print("block", blk, hex(blk))
raw = call(D, "0xaa6ca808"); w = words(raw); n = int(w[1], 16)
print("numTokens", n, "numVertices", int(call(D, "0x9d5d7807"), 16))
print("owner", addr(words(call(D, "0x8da5cb5b"))[0]))
print("adjustor", addr(words(call(D, "0x6ed7a2c3"))[0]))
for i in range(n):
    t = addr(w[2+i])
    try:
        act = addr(words(call(D, "0x907d17cd" + "0"*24 + t[2:]))[0])
    except Exception:
        act = "?"
    print(f"  token[{i}] {t} vault={act}")
PY
  echo
  echo "--- vault custody (Diamond shares -> assets) ---"
  python3 analysis/custody.py
} > "$OUT" 2>&1
echo "wrote $OUT"
tail -40 "$OUT"
