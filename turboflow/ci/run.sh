#!/usr/bin/env bash
# ci/run.sh — reproduce the TurboFlow (svm-bridge) gating proofs on the CI runner.
# All steps are READ-ONLY: public keyless JSON-RPC reads + simulateTransaction(sigVerify=false).
# No transaction is ever signed or sent. No secrets are used or printed.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"    # -> turboflow/
cd "$ROOT"
OUT="$ROOT/ci-out"
mkdir -p "$OUT"
LOG="$OUT/ci-results.txt"
: > "$LOG"

PID=HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg
REVIEW_SIG=2o6TW2zCEKX144NQZrH8MZQpsD2AU9LSTZ4wAuw16vQaUeB3XdVm3y2YDNn7fC39Ftb6Yaj3FZKS5FDEHMNQ3Fmx
DEPOSIT_SIG=2TKqCWUjibKxKgSaSVAeXWTL55GV6ZrQyP36gizQ2GGsW1hyJVuNWrVwuKW3wxQMBNVEJwQThbDKUETkxgm3a7hP
NONREVIEWER=9jfktqKRQASH8gYyiaLoFnG6u5RG8NsK99qPWVYfmPZ4   # PROPOSE_ROLE holder, NOT REVIEW_ROLE
CUSTODY=6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2
FOREIGN=FYmWdMq9KT87jpZomMQR7Y2r4a2KbEiXkoDJcHMAP1vq

run() { echo "### $1" | tee -a "$LOG"; shift; "$@" 2>&1 | tee -a "$LOG"; echo | tee -a "$LOG"; sleep 1; }

echo "TurboFlow svm-bridge CI reproduction — $(date -u +%FT%TZ)" | tee -a "$LOG"
echo "slot:" | tee -a "$LOG"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import sys; sys.path.insert(0, "analysis")
from rpc import call
print(call("getSlot", [{"commitment": "finalized"}]))
PY

cd "$ROOT/analysis"
run "1. program/upgrade-authority probe"      python3 probe.py "$PID"
run "2. role registry (RoleData members)"     python3 role_scan.py
run "3. REVIEW_ROLE gate on review_token"     python3 sim_swap.py "$REVIEW_SIG" b6c03990c1accb27 "$NONREVIEWER"
run "4. deposit_token custody PDA binding"    python3 sim_sub.py "$DEPOSIT_SIG" 0b9c60da27a3b413 --patch-u64 0=4000 --replace "$CUSTODY=$FOREIGN"
run "5. set_contract_status role gate"        python3 probe_fields.py 6536c6cd5ff3eebb 4
run "6. grant_role role gate"                 python3 probe_fields.py daea800f5221ecfd 3
run "7. apply_risk_config role gate"          python3 probe_fields.py 88159e4093744f50 5
run "8. propose_deposit role gate"            python3 auto_chain.py 010a4814fd248a0e "$(python3 -c 'print("00"*200)')" "GUAujt5S2yvnY4HVj5ysiiHfskmLXPkcbVfxcgLVd1is,8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47,8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4,779z6J7LDEXTR94SeEXTRjnaXHMAv9tkiWqnsth69AW9,9WaDMCXisKv1TXB395DJX6HFy2Mtoy4giab2mh6gNed8,dbrv6zgi9hP8iDwtWNfCpMfk4h2s6BxgeCfhmDxkJm9,TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA,11111111111111111111111111111111"
run "9. ReviewTokenSolV1 derived accounts"    python3 auto_chain.py 246e06b47c8fa3e5 "6e8e000000000000343301ce010e60afedb22717bd63192f54145a3f965a33bb82d2c7029eb2ce1e2082640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" "2V8qS36vGHzZogZupifnXsB2u4cg8JRQEWAfY3PaVWW5,GUAujt5S2yvnY4HVj5ysiiHfskmLXPkcbVfxcgLVd1is,8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47,8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4,2WpgSwhTXohXDxxCMmdaKgdaiuD62H6XreDMvu3PykLS,779z6J7LDEXTR94SeEXTRjnaXHMAv9tkiWqnsth69AW9,FT4U9VFurWMzytf6891F21aBaWfi2eRPEf7kiU6wYyj8,6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2,CHFMoiPZUJAUrrTW21yJbgDKBbGPwL2swEPcDE5C23Kx,GMziBUjxqeA6wyXHjZB7hRCh6J8ysRwkJwTZRdXWEkKo,7GWMbRpd6haQrnLPCfDgHiVNDaPwghMDpTEythvc1Drz,TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA,TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA,11111111111111111111111111111111"
run "10. live custody + BSC balances"         python3 final_state.py
run "11. enumerate program state"             python3 enumerate_state.py

cd "$ROOT"
echo "== done; results in $LOG ==" | tee -a "$LOG"
