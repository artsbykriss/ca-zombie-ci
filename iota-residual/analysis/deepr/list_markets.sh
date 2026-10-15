#!/usr/bin/env bash
# Enumerate Deepr Finance IOTA EVM comptroller markets (read-only).
cd "$(dirname "$0")"
C=0xee07121d97FDEA35675e02017837a7a43aeDa48F
MARKETS=$(./rpc_iota.sh $C 0xb0772d0b)
echo "raw_getAllMarkets: $MARKETS"
# decode: offset 0x20, count at word1, then addresses at words 2..5
python3 - <<'EOF'
raw = open('/dev/stdin').read() if False else None
EOF
python3 - "$MARKETS" <<'PYEOF'
import sys
raw = sys.argv[1][2:]
words = [raw[i:i+64] for i in range(0, len(raw), 64)]
count = int(words[1], 16)
addrs = ['0x' + words[2+i][24:] for i in range(count)]
print('\n'.join(addrs))
PYEOF
