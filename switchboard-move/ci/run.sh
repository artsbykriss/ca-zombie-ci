#!/usr/bin/env bash
# Z3-C2 Switchboard-Move CI job: re-run live-state verification (read-only, public endpoints).
set -uo pipefail
cd "$(dirname "$0")/.."

echo "[ci] python: $(python3 --version)"
mkdir -p ci-out

# 1) main verification: live Sui/Aptos state + deployed-bytecode checks + Aptos simulation
python3 analysis/ci_verify.py
RC=$?
echo "[ci] ci_verify exit code: $RC"

# 2) copy supporting evidence dumps into ci-out
for f in analysis/sui_queues.json analysis/sui_oracles.json analysis/sui_aggregators.json \
         analysis/aptos_queue_census.json analysis/sui_events_all_versions.json analysis/sui_attack_forensics.json; do
  [ -f "$f" ] && cp "$f" ci-out/ || true
done

# 3) extra: dump the live queue/oracle state fresh (independent of the checks)
python3 - <<'EOF' > ci-out/live_state_dump.txt 2>&1 || true
import json, sys
sys.path.insert(0, 'analysis')
from sui_query import q
from aptos_view import view
PKG = '0xfea54925b5ac1912331e2e62049849b37842efaea298118b66f85a59057752b8'
for name, addr in [('main','0x7fdf7235bf3bd872ad093927deb2ff5f1645d1b6dabbfd4a03c3e0442788ce12'),
                   ('guardian','0x3434a45114f5f8fc577557a9a3dda54c1799fee5271313f2599a1093c4a8ba01')]:
    print('=== Aptos queue:', name)
    print(json.dumps(view(PKG+'::queue::view_queue', [], [addr]), indent=1)[:1500])
for name, addr in [('main','0x6e43354b8ea2dfad98eadb33db94dcc9b1175e70ee82e42abc605f6b7de9e910'),
                   ('guardian','0x662f5642dc730289b5c8084b67e4e092428e825a97071c5cb5c691dfb2cc88f7')]:
    print('=== Sui queue:', name)
    d = q('{ object(address: "%s") { asMoveObject { contents { json } } } }' % addr)
    print(json.dumps(d, indent=1)[:1500])
EOF

ls -la ci-out/
exit $RC
