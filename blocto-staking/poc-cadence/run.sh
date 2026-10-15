#!/usr/bin/env bash
# =============================================================================
# BloctoTokenStaking (Flow mainnet 0x0f9df91c9121c460) -- LOCAL-ONLY Cadence PoC
#
# Proves/disproves three gate claims about the LIVE Blocto staking system:
#
#   C1. The PUBLIC minter capability (&{BloctoPass.MinterPublic}.mintBasicNFT) lets an
#       UNPRIVILEGED external account trigger BloctoPass minting; while
#       BloctoTokenStaking.stakingEnabled == false the mint reverts inside
#       Admin.addStakerRecord (pre-condition). With stakingEnabled == true the same
#       mint succeeds and yields a pass with an EMPTY staker record (zero tokens).
#
#   C2. Staker.withdrawUnstakedTokens / withdrawRewardedTokens have NO stakingEnabled
#       pre-condition, so a pass holder can still pull tokens out of their own
#       tokensUnstaked / tokensRewarded buckets while the system is FROZEN.
#
#   C3. Entitlement isolation: an outside account cannot reach the pass private
#       collection reference or the staking Admin through public capabilities/storage.
#
# EVERYTHING here runs against a throwaway local `flow emulator`.
# No transaction is ever built, signed or sent to a real network. Pure reads on real
# networks are not even used by this script (contract sources are vendored).
#
# Usage:  bash poc-cadence/run.sh
# Output: <ci-out>/cadence-poc/poc.log          full transcript
#         <ci-out>/cadence-poc/poc_result.json  machine-readable PASS/FAIL per claim
#         <ci-out>/cadence-poc/evidence/*.txt   raw CLI output per step
#
# Exit code: 0  harness completed (read poc_result.json for the verdict)
#            3  harness could not run at all (flow CLI/emulator unusable)
# =============================================================================

set -uo pipefail

POC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$POC_DIR/.." && pwd)"
RUNTIME="$POC_DIR/.runtime"
OUT_DIR="${POC_OUT_DIR:-$PARENT_DIR/ci-out/cadence-poc}"
EVIDENCE="$OUT_DIR/evidence"
STEPS="$RUNTIME/steps"
LOG="$OUT_DIR/poc.log"
CHECKS="$RUNTIME/checks.jsonl"
RESULT="$OUT_DIR/poc_result.json"

# Deadline for the whole scenario (seconds). The parent's CI budget is ~10 min.
# Override with POC_DEADLINE=<seconds> if the machine is slow.
GLOBAL_DEADLINE="${POC_DEADLINE:-660}"
START_TS=$(date +%s)

mkdir -p "$OUT_DIR" "$EVIDENCE" "$RUNTIME" "$STEPS"
: > "$LOG"
: > "$CHECKS"

log()  { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$LOG"; }
die()  { log "FATAL: $*"; finish 3; }

# --------------------------------------------------------------------------- #
# result recording
# --------------------------------------------------------------------------- #
record() { # claim check status detail
    python3 -c 'import json,sys
print(json.dumps({"claim": sys.argv[1], "check": sys.argv[2], "status": sys.argv[3], "detail": sys.argv[4]}))' \
        "$1" "$2" "$3" "$4" >> "$CHECKS"
}

DEP_FT_ADDR=""; DEP_NFT_ADDR=""; BLOCTO_ADDR=""; USER_ADDR=""

finish() { # <exit code>
    local rc="${1:-0}"
    python3 - "$CHECKS" "$RESULT" "${DEP_FT_ADDR:-}" "${DEP_NFT_ADDR:-}" "${BLOCTO_ADDR:-}" "${USER_ADDR:-}" <<'PY' 2>&1 | tee -a "$LOG"
import json, sys, datetime
checks_path, out_path = sys.argv[1], sys.argv[2]
addrs = dict(zip(("dep-ft", "dep-nft", "blocto", "user"), sys.argv[3:7]))
checks = []
try:
    with open(checks_path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                checks.append(json.loads(line))
except FileNotFoundError:
    pass
claims = {}
for c in checks:
    claims.setdefault(c["claim"], []).append(c)
for claim in ("C1", "C2", "C3"):
    if not claims.get(claim):
        claims[claim] = [{"claim": claim, "check": "claim_not_executed", "status": "FAIL",
                          "detail": "no checks recorded -- harness aborted before reaching this claim"}]
summary = {"status": "PASS" if all(x["status"] == "PASS" for v in claims.values() for x in v) else "FAIL",
           "checks_total": sum(len(v) for v in claims.values()),
           "checks_failed": sum(1 for v in claims.values() for x in v if x["status"] != "PASS")}
doc = {
    "poc": "blocto-staking gates C1/C2/C3 (Cadence, local emulator only)",
    "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "target": "BloctoTokenStaking @ Flow mainnet 0x0f9df91c9121c460 (live code, local deployment)",
    "harness": "flow emulator + flow CLI (no real network writes)",
    "address_map": addrs,
    "overall": summary,
    "claims": {k: {"status": "PASS" if all(x["status"] == "PASS" for x in v) else "FAIL", "checks": v}
               for k, v in claims.items()},
}
with open(out_path, "w") as fh:
    json.dump(doc, fh, indent=2, sort_keys=False)
print("==== OVERALL: %s (%d checks, %d failed) ====" % (summary["status"], summary["checks_total"], summary["checks_failed"]))
for k in ("C1", "C2", "C3"):
    bad = [x for x in claims[k] if x["status"] != "PASS"]
    print("  %s: %s  (%d checks%s)" % (k, "PASS" if not bad else "FAIL", len(claims[k]),
                                       "" if not bad else ", %d failed" % len(bad)))
PY
    cp -f "$CHECKS" "$OUT_DIR/checks.jsonl" 2>/dev/null
    cp -f "$STEPS"/*.out "$EVIDENCE/" 2>/dev/null
    log "wrote $RESULT"
    tail -n 12 "$LOG"
    exit "$rc"
}

EMU_PID=""
trap 'kill "${EMU_PID:-}" 2>/dev/null' EXIT

# --------------------------------------------------------------------------- #
# flow CLI discovery / install
# --------------------------------------------------------------------------- #
FLOW=""
flow_v2() { [ -n "${1:-}" ] && [ -x "$1" ] && "$1" version 2>/dev/null | grep -qE 'Version: *v2\.'; }
if flow_v2 "${FLOW_CLI:-}"; then FLOW="$FLOW_CLI"; fi
if [ -z "$FLOW" ] && flow_v2 "$(command -v flow 2>/dev/null || true)"; then FLOW="$(command -v flow)"; fi
if [ -z "$FLOW" ] && flow_v2 "$HOME/.local/bin/flow"; then FLOW="$HOME/.local/bin/flow"; fi
if [ -z "$FLOW" ]; then
    log "a working Flow CLI v2 was not found -- installing (needs network) ..."
    sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)" </dev/null >>"$LOG" 2>&1
    if flow_v2 "$HOME/.local/bin/flow"; then FLOW="$HOME/.local/bin/flow"; fi
fi
if [ -z "$FLOW" ] || ! "$FLOW" version >>"$LOG" 2>&1; then
    log "FATAL: could not obtain a working flow CLI"
    record C1 flow_cli FAIL "flow CLI unavailable"
    record C2 flow_cli FAIL "flow CLI unavailable"
    record C3 flow_cli FAIL "flow CLI unavailable"
    finish 3
fi
log "flow CLI: $("$FLOW" version 2>/dev/null | tr -d '\n')  ($FLOW)"

# --------------------------------------------------------------------------- #
# ports
# --------------------------------------------------------------------------- #
port_free() { ! timeout 2 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/$1" >/dev/null 2>&1; }
EMU_PORT=""; EMU_REST_PORT=""; EMU_ADMIN_PORT=""; EMU_DEBUG_PORT=""
for cand in "3679 8898 8098 2355" "3678 8897 8097 2354" "3677 8896 8096 2353" "3676 8895 8095 2352"; do
    set -- $cand
    if port_free "$1" && port_free "$2" && port_free "$3" && port_free "$4"; then
        EMU_PORT="$1"; EMU_REST_PORT="$2"; EMU_ADMIN_PORT="$3"; EMU_DEBUG_PORT="$4"; break
    fi
done
if [ -z "$EMU_PORT" ]; then
    log "FATAL: no free port quadruple found"
    record C1 ports FAIL "no free port quadruple"
    record C2 ports FAIL "no free port quadruple"
    record C3 ports FAIL "no free port quadruple"
    finish 3
fi
log "emulator ports: grpc=$EMU_PORT rest=$EMU_REST_PORT admin=$EMU_ADMIN_PORT debug=$EMU_DEBUG_PORT"

# --------------------------------------------------------------------------- #
# clean runtime + bootstrap config (only the service account, valid on its own)
# --------------------------------------------------------------------------- #
rm -rf "$RUNTIME"; mkdir -p "$RUNTIME" "$STEPS"
: > "$CHECKS"

python3 - "$RUNTIME" "$EMU_PORT" <<'PY'
import json, sys, secrets
runtime, port = sys.argv[1], sys.argv[2]
svc_priv = secrets.token_hex(32)
with open(runtime + "/emulator-account.pkey", "w") as fh:
    fh.write("0x" + svc_priv)
cfg = {"networks": {"emulator": "127.0.0.1:" + port},
       "accounts": {"emulator-account": {"address": "f8d6e0586b0a20c7",
                                        "key": {"type": "file", "location": runtime + "/emulator-account.pkey"}}}}
with open(runtime + "/flow.json", "w") as fh:
    json.dump(cfg, fh, indent=2)
PY
log "generated local service account key (throwaway, never leaves $RUNTIME)"

# --------------------------------------------------------------------------- #
# start emulator
# --------------------------------------------------------------------------- #
log "starting flow emulator (local only, chain-id=emulator) ..."
( cd "$RUNTIME" && exec "$FLOW" emulator \
    --config-path "$RUNTIME/flow.json" \
    --port "$EMU_PORT" --rest-port "$EMU_REST_PORT" --admin-port "$EMU_ADMIN_PORT" --debugger-port "$EMU_DEBUG_PORT" \
    --storage-limit=false ) >"$RUNTIME/emulator.log" 2>&1 &
EMU_PID=$!
EMU_UP=0
for _ in $(seq 1 60); do
    if ! kill -0 "$EMU_PID" 2>/dev/null; then break; fi
    if ! port_free "$EMU_PORT"; then EMU_UP=1; break; fi
    sleep 1
done
if [ "$EMU_UP" != 1 ]; then
    log "FATAL: emulator did not come up"; tail -n 30 "$RUNTIME/emulator.log" >>"$LOG"
    record C1 emulator FAIL "emulator did not start"
    record C2 emulator FAIL "emulator did not start"
    record C3 emulator FAIL "emulator did not start"
    finish 3
fi
log "emulator up (pid $EMU_PID)"

# --------------------------------------------------------------------------- #
# create accounts
# --------------------------------------------------------------------------- #
FLOWRUN() { # name, then CLI args
    local name="$1"; shift
    local out="$STEPS/$name.out" rc
    local now; now=$(date +%s)
    if [ $((now - START_TS)) -gt "$GLOBAL_DEADLINE" ]; then
        echo "GLOBAL-DEADLINE-EXCEEDED: step '$name' not executed" >"$out"
        echo 124 >"$STEPS/$name.exit"
        { echo "----- [$name] SKIPPED (deadline)"; } >>"$LOG"
        return 124
    fi
    local t0 t1
    t0=$(date +%s)
    ( cd "$RUNTIME" && timeout 240 "$FLOW" "$@" --config-path "$RUNTIME/flow.json" --network emulator --skip-version-check -y ) >"$out" 2>&1
    rc=$?
    t1=$(date +%s)
    echo "$rc" >"$STEPS/$name.exit"
    echo "$((t1 - t0))s" >"$STEPS/$name.dur"
    { echo "----- [$name] exit=$rc  ($((t1 - t0))s)"; cat "$out"; } >>"$LOG"
    return $rc
}
step_exit() { cat "$STEPS/$1.exit" 2>/dev/null || echo 999; }
tx_sealed() { grep -q 'SEALED' "$STEPS/$1.out" 2>/dev/null; }
# "transaction execute failed"  -> the tx body ran and reverted (runtime error / panic)
# "transaction preprocess failed" -> rejected by the Cadence checker before execution
tx_runtime_error() { grep -q 'transaction execute failed' "$STEPS/$1.out" 2>/dev/null; }
tx_checker_error() { grep -q 'transaction preprocess failed' "$STEPS/$1.out" 2>/dev/null; }
tx_error() { tx_runtime_error "$1" || tx_checker_error "$1"; }
field() { python3 "$POC_DIR/tools/cadence_json.py" "$2" <"$STEPS/$1.out" 2>/dev/null; }

tx() { # name txfile signer argsjson
    local name="$1" file="$2" signer="$3" args="${4:-[]}"
    FLOWRUN "$name" transactions send "$RUNTIME/transactions/$file" --signer "$signer" --args-json "$args" --compute-limit 9999
}
sc() { # name scriptfile argsjson
    local name="$1" file="$2" args="${3:-[]}"
    FLOWRUN "$name" scripts execute "$RUNTIME/scripts/$file" --args-json "$args" --output json
}

assert_eq() { # claim check expected actual
    if [ "$3" == "$4" ]; then record "$1" "$2" PASS "expected=$3 observed=$4"
    else record "$1" "$2" FAIL "expected=$3 observed=$4"; fi
}
assert_num() { # claim check expected actual [tol]
    local tol="${5:-0.000001}"
    if python3 -c 'import sys; e,a,t=map(float,sys.argv[1:4]); sys.exit(0 if abs(e-a)<=t else 1)' "$3" "$4" "$tol" 2>/dev/null; then
        record "$1" "$2" PASS "expected=$3 observed=$4"
    else
        record "$1" "$2" FAIL "expected=$3 observed=$4"
    fi
}
expect_success() { # claim check step  (transaction)
    local rc; rc=$(step_exit "$3")
    if [ "$rc" == "0" ] && tx_sealed "$3" && ! tx_error "$3"; then
        record "$1" "$2" PASS "transaction '$3' executed and sealed successfully"
    elif [ "$rc" == "0" ] && ! tx_sealed "$3"; then
        record "$1" "$2" FAIL "step '$3' did not execute (rejected before running): $(head -c 300 "$STEPS/$3.out" | tr '\n' ' ')"
    else
        record "$1" "$2" FAIL "step '$3' failed (exit $rc): $(head -c 300 "$STEPS/$3.out" | tr '\n' ' ')"
    fi
}
expect_script_ok() { # claim check step  (script)
    local rc; rc=$(step_exit "$3")
    if [ "$rc" == "0" ] && grep -q '"type"' "$STEPS/$3.out"; then
        record "$1" "$2" PASS "script '$3' returned a value"
    else
        record "$1" "$2" FAIL "script '$3' failed (exit $rc): $(head -c 300 "$STEPS/$3.out" | tr '\n' ' ')"
    fi
}
expect_revert() { # claim check step pattern
    local rc out; rc=$(step_exit "$3"); out="$STEPS/$3.out"
    if tx_checker_error "$3"; then
        record "$1" "$2" FAIL "step '$3' was rejected by the checker, not reverted at runtime: $(tr '\n' ' ' < "$out" | grep -oE 'transaction preprocess failed.{0,200}' | head -1)"
    elif ! tx_runtime_error "$3"; then
        record "$1" "$2" FAIL "step '$3' did NOT revert at runtime (no execution error): $(head -c 300 "$out" | tr '\n' ' ')"
    elif grep -qF "$4" "$out"; then
        record "$1" "$2" PASS "step '$3' reverted at runtime (exit $rc) matching: $4"
    else
        record "$1" "$2" FAIL "step '$3' reverted but without expected text '$4': $(tr '\n' ' ' < "$out" | head -c 400)"
    fi
}
expect_checker_reject() { # claim check step regex  -- must be rejected by the checker (never executed)
    local rc out; rc=$(step_exit "$3"); out="$STEPS/$3.out"
    if tx_runtime_error "$3"; then
        record "$1" "$2" FAIL "step '$3' EXECUTED and only failed at runtime -- expected a check-time rejection"
    elif ! tx_checker_error "$3"; then
        record "$1" "$2" FAIL "step '$3' shows neither a runtime nor a checker error (exit $rc): $(head -c 300 "$out" | tr '\n' ' ')"
    elif grep -qE "$4" "$out"; then
        local msg
        msg=$(tr '\n' ' ' < "$out" | grep -oE "$4.{0,120}" | head -1)
        record "$1" "$2" PASS "step '$3' rejected by the cadence checker before execution: $msg"
    else
        record "$1" "$2" FAIL "step '$3' was rejected but not for the expected reason '$4': $(tr '\n' ' ' < "$out" | grep -oE 'error:.{0,200}' | head -1)"
    fi
}

# --------------------------------------------------------------------------- #
# generate 4 keypairs + create 4 accounts (service account pays)
# --------------------------------------------------------------------------- #
gen_account() { # name -> prints address on success
    local name="$1" kp pub priv addr raw out="$STEPS/gen_$1.out"
    : > "$out"
    kp=$( ( cd "$RUNTIME" && "$FLOW" keys generate --config-path "$RUNTIME/flow.json" --skip-version-check --output json ) 2>>"$out" | grep -o '{.*}' | tail -1)
    pub=$(printf '%s' "$kp" | python3 -c 'import json,sys; print(json.load(sys.stdin)["public"])' 2>>"$out") || true
    priv=$(printf '%s' "$kp" | python3 -c 'import json,sys; print(json.load(sys.stdin)["private"])' 2>>"$out") || true
    if [ -z "${priv:-}" ] || [ -z "${pub:-}" ]; then
        log "gen_account $name: 'flow keys generate' failed -- see $out"
        return 1
    fi
    printf '0x%s' "$priv" >"$RUNTIME/$name.pkey"
    raw=$( ( cd "$RUNTIME" && timeout 120 "$FLOW" accounts create --key "$pub" --config-path "$RUNTIME/flow.json" --network emulator \
            --skip-version-check -y --output json ) 2>&1 )
    rc=$?
    { echo "----- accounts create $name (exit $rc)"; echo "$raw"; } >>"$out"
    if [ "$rc" != "0" ]; then
        log "gen_account $name: 'flow accounts create' failed (exit $rc) -- see $out"
        return 1
    fi
    addr=$(printf '%s' "$raw" | grep -o '{.*}' | tail -1 |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["address"])' 2>/dev/null)
    if [ -z "${addr:-}" ]; then
        log "gen_account $name: could not parse new account address -- see $out"
        return 1
    fi
    addr=$(python3 -c "print(format(int('$addr',16),'016x'))")
    printf '%s %s\n' "$name" "$addr" >>"$RUNTIME/accounts.txt"
    printf '%s' "$addr"
}

log "creating accounts (dep-ft, dep-nft, blocto, user) ..."
: > "$RUNTIME/accounts.txt"
DEP_FT_ADDR=$(gen_account dep-ft)   || die "could not create account dep-ft"
DEP_NFT_ADDR=$(gen_account dep-nft) || die "could not create account dep-nft"
BLOCTO_ADDR=$(gen_account blocto)   || die "could not create account blocto"
USER_ADDR=$(gen_account user)       || die "could not create account user"
log "accounts: dep-ft=0x$DEP_FT_ADDR dep-nft=0x$DEP_NFT_ADDR blocto=0x$BLOCTO_ADDR user=0x$USER_ADDR"
log "address rewrite: 0xf233dcee88fe0abe->0x$DEP_FT_ADDR  0x1d7e57aa55817448->0x$DEP_NFT_ADDR  0x0f9df91c9121c460->0x$BLOCTO_ADDR  0x5555555555555555->0x$USER_ADDR"

# --------------------------------------------------------------------------- #
# materialise sources with local addresses + full flow.json
# --------------------------------------------------------------------------- #
mkdir -p "$RUNTIME/contracts/deps" "$RUNTIME/transactions" "$RUNTIME/scripts"
cp "$POC_DIR/contracts/"*.cdc "$RUNTIME/contracts/"
cp "$POC_DIR/contracts/deps/"*.cdc "$RUNTIME/contracts/deps/"
cp "$POC_DIR/transactions/"*.cdc "$RUNTIME/transactions/"
cp "$POC_DIR/scripts/"*.cdc "$RUNTIME/scripts/"

find "$RUNTIME/contracts" "$RUNTIME/transactions" "$RUNTIME/scripts" -name '*.cdc' -print0 | xargs -0 sed -i \
    -e "s/0xf233dcee88fe0abe/0x${DEP_FT_ADDR}/g" \
    -e "s/0x1d7e57aa55817448/0x${DEP_NFT_ADDR}/g" \
    -e "s/0x0f9df91c9121c460/0x${BLOCTO_ADDR}/g" \
    -e "s/0x5555555555555555/0x${USER_ADDR}/g"

python3 - "$POC_DIR/flow.json" "$RUNTIME/flow.json" "$DEP_FT_ADDR" "$DEP_NFT_ADDR" "$BLOCTO_ADDR" "$USER_ADDR" <<'PY'
import json, sys
tpl, out = sys.argv[1], sys.argv[2]
doc = open(tpl).read()
vals = {"__DEP_FT_ADDR__": sys.argv[3], "__DEP_NFT_ADDR__": sys.argv[4],
        "__BLOCTO_ADDR__": sys.argv[5], "__USER_ADDR__": sys.argv[6],
        "__DEP_FT_KEY__": json.dumps({"type": "file", "location": sys.argv[2].rsplit("/", 1)[0] + "/dep-ft.pkey"}),
        "__DEP_NFT_KEY__": json.dumps({"type": "file", "location": sys.argv[2].rsplit("/", 1)[0] + "/dep-nft.pkey"}),
        "__BLOCTO_KEY__": json.dumps({"type": "file", "location": sys.argv[2].rsplit("/", 1)[0] + "/blocto.pkey"}),
        "__USER_KEY__": json.dumps({"type": "file", "location": sys.argv[2].rsplit("/", 1)[0] + "/user.pkey"})}
doc = doc.replace('"source": "contracts', '"source": "%s/contracts' % sys.argv[2].rsplit("/", 1)[0])
for k, v in vals.items():
    doc = doc.replace(k, v)
json.loads(doc)  # must stay valid JSON
open(out, "w").write(doc)
PY

# --------------------------------------------------------------------------- #
# deploy contracts in dependency order (explicit: `flow project deploy` may reorder)
# --------------------------------------------------------------------------- #
deploy() { # account name path
    FLOWRUN "deploy_$2" accounts add-contract "$3" --signer "$1"
}
log "deploying contracts ..."
deploy dep-nft  ViewResolver               "$RUNTIME/contracts/deps/ViewResolver.cdc"               || true
deploy dep-ft   Burner                     "$RUNTIME/contracts/deps/Burner.cdc"                     || true
deploy dep-nft  NonFungibleToken           "$RUNTIME/contracts/deps/NonFungibleToken.cdc"           || true
deploy dep-ft   FungibleToken              "$RUNTIME/contracts/deps/FungibleToken.cdc"              || true
deploy dep-nft  MetadataViews              "$RUNTIME/contracts/deps/MetadataViews.cdc"              || true
deploy dep-ft   FungibleTokenMetadataViews "$RUNTIME/contracts/deps/FungibleTokenMetadataViews.cdc" || true
deploy blocto   BloctoToken                "$RUNTIME/contracts/BloctoToken.cdc"                    || true
deploy blocto   BloctoTokenStaking         "$RUNTIME/contracts/BloctoTokenStaking.cdc"             || true
deploy blocto   BloctoPassStamp            "$RUNTIME/contracts/BloctoPassStamp.cdc"                || true
deploy blocto   BloctoPass                 "$RUNTIME/contracts/BloctoPass.cdc"                     || true

DEPLOY_FAILED=0
for c in ViewResolver Burner NonFungibleToken FungibleToken MetadataViews FungibleTokenMetadataViews \
         BloctoToken BloctoTokenStaking BloctoPassStamp BloctoPass; do
    if [ "$(step_exit "deploy_$c")" != "0" ]; then DEPLOY_FAILED=1; log "DEPLOY FAILED: $c"; fi
done
if [ "$DEPLOY_FAILED" != 0 ]; then
    record C1 deployment FAIL "one or more contracts failed to deploy (see evidence/deploy_*.out)"
    record C2 deployment FAIL "one or more contracts failed to deploy"
    record C3 deployment FAIL "one or more contracts failed to deploy"
    finish 3
fi
log "all 10 contracts deployed"

# --------------------------------------------------------------------------- #
# scenario
# --------------------------------------------------------------------------- #
json_args() { python3 -c 'import json,sys; print(json.dumps([json.loads(a) for a in sys.argv[1:]]))' "$@"; }
addr_arg() { python3 -c 'import json,sys; print(json.dumps([{"type":"Address","value":"0x"+sys.argv[1]}]))' "$1"; }
id_arg() { python3 -c 'import json,sys; print(json.dumps([{"type":"UInt64","value":sys.argv[1]}]))' "$1"; }
amt_arg() { python3 -c 'import json,sys; print(json.dumps([{"type":"UFix64","value":sys.argv[1]}]))' "$1"; }

log "=== phase A: setup (mirror live state: public minter capability + user account) ==="
tx a1_publish_minter setup_publish_minter.cdc blocto
tx a2_user_setup     setup_user.cdc           user
tx a3_create_minter  admin_create_minter.cdc  blocto
tx a4_fund_user      admin_fund_user.cdc      blocto "$(python3 -c 'import json,sys; print(json.dumps([{"type":"Address","value":"0x"+sys.argv[1]},{"type":"UFix64","value":"1000.00000000"}]))' "$USER_ADDR")"
sc a5_state_before   state.cdc
expect_script_ok A0 setup.state_script_readable a5_state_before
sc a6_user_funded    user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_num A0 setup.user_funded_with_blt "1000" "$(field a6_user_funded bltVaultBalance)"
assert_eq A0 setup.minter_capability_published "$(step_exit a1_publish_minter)" 0
assert_eq A0 setup.user_account_setup        "$(step_exit a2_user_setup)" 0
assert_eq A0 setup.staking_enabled_at_boot   "true" "$(field a5_state_before stakingEnabled)"

# ---------------------------------------------------------------- C1 ---------
log "=== phase B: C1 -- public mint while frozen must revert ==="
tx b1_freeze         admin_end_auction.cdc    blocto
expect_success C1 C1a.freeze_transaction_succeeded b1_freeze
sc b2_state_frozen   state.cdc
expect_script_ok C1 C1a.frozen_state_script_readable b2_state_frozen
assert_eq C1 C1a.frozen_state_reached "false" "$(field b2_state_frozen stakingEnabled)"
SUPPLY_BEFORE=$(field b2_state_frozen bloctoPassTotalSupply)
assert_eq C1 C1a.pass_supply_before "$SUPPLY_BEFORE" "0"

tx b3_mint_frozen    user_mint_pass_public.cdc user "$(addr_arg "$BLOCTO_ADDR")"
expect_revert C1 C1b.public_mint_reverts_while_frozen b3_mint_frozen \
    "Cannot register a staker operator if the staking auction"
sc b4_state_after_frozen_mint state.cdc
sc b5_user_after_frozen_mint  user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_eq C1 C1b.pass_supply_unchanged "$SUPPLY_BEFORE" "$(field b4_state_after_frozen_mint bloctoPassTotalSupply)"
assert_eq C1 C1b.no_pass_deposited   "[]" "$(field b5_user_after_frozen_mint passIDs)"

log "=== phase B2: C1 -- same public mint while unfrozen succeeds (empty staker record) ==="
tx b6_unfreeze       admin_start_auction.cdc  blocto
expect_success C1 C1c.unfreeze_transaction_succeeded b6_unfreeze
sc b7_state_unfrozen state.cdc
assert_eq C1 C1c.unfrozen_state_reached "true" "$(field b7_state_unfrozen stakingEnabled)"
tx b8_mint_unfrozen  user_mint_pass_public.cdc user "$(addr_arg "$BLOCTO_ADDR")"
expect_success C1 C1c.public_mint_succeeds_while_unfrozen b8_mint_unfrozen
sc b9_state_after_mint state.cdc
sc b10_user_after_mint user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_eq C1 C1c.pass_supply_incremented "1" "$(field b9_state_after_mint bloctoPassTotalSupply)"
PASS_ID=$(field b10_user_after_mint 'passIDs[0]')
ID_ARG="$(id_arg "$PASS_ID")"
assert_eq C1 C1c.pass_deposited_to_external_signer "0" "$PASS_ID"
sc b11_staker_info staker_info.cdc "$(id_arg "$PASS_ID")"
expect_script_ok C1 C1d.staker_info_readable b11_staker_info
assert_eq C1 C1d.minted_pass_staker_is_same_id "$PASS_ID" "$(field b11_staker_info id)"
assert_num C1 C1d.minted_pass_has_zero_tokens "0" "$(field b11_staker_info totalTokensInRecord)"
assert_num C1 C1d.minted_pass_staked_bucket_zero "0" "$(field b11_staker_info tokensStaked)"
assert_num C1 C1d.minted_pass_unstaked_bucket_zero "0" "$(field b11_staker_info tokensUnstaked)"
assert_num C1 C1d.minted_pass_rewarded_bucket_zero "0" "$(field b11_staker_info tokensRewarded)"
sc b12_pass_owner user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_num C1 C1d.minted_pass_vault_zero "0" "$(field b12_pass_owner passVaultBalance)"

# ---------------------------------------------------------------- C2 ---------
log "=== phase C: C2 -- withdrawals keep working while frozen ==="
tx c1_deposit  user_deposit_to_pass.cdc  user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"100.00000000"}')"
expect_success C2 C2a.deposit_into_pass c1_deposit
tx c2_stake    user_stake_new_tokens.cdc user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"100.00000000"}')"
expect_success C2 C2a.stake_new_tokens_while_unfrozen c2_stake
sc c3_info_after_stake staker_info.cdc "$ID_ARG"
assert_num C2 C2a.tokens_committed "100" "$(field c3_info_after_stake tokensCommitted)"
tx c4_request_unstaking user_request_unstaking.cdc user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"50.00000000"}')"
expect_success C2 C2a.request_unstaking c4_request_unstaking
sc c5_info_after_request staker_info.cdc "$ID_ARG"
assert_num C2 C2a.tokens_unstaked_bucket "50" "$(field c5_info_after_request tokensUnstaked)"
assert_num C2 C2a.tokens_committed_remaining "50" "$(field c5_info_after_request tokensCommitted)"

log "--- freeze the system (stakingEnabled=false, the live state) ---"
tx c6_freeze   admin_end_auction.cdc blocto
expect_success C2 C2b.freeze_before_withdraw_transaction c6_freeze
sc c7_state_frozen2 state.cdc
assert_eq C2 C2b.frozen_before_withdraw "false" "$(field c7_state_frozen2 stakingEnabled)"

tx c8_withdraw_unstaked user_withdraw_unstaked.cdc user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"50.00000000"}')"
expect_success C2 C2b.withdraw_unstaked_tokens_while_frozen c8_withdraw_unstaked
sc c9_info_after_withdraw staker_info.cdc "$ID_ARG"
assert_num C2 C2b.unstaked_bucket_emptied "0" "$(field c9_info_after_withdraw tokensUnstaked)"
sc c10_user_after_withdraw user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_num C2 C2b.tokens_landed_in_pass_vault "50" "$(field c10_user_after_withdraw passVaultBalance)"

tx c11_pull_out user_withdraw_pass_vault.cdc user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"50.00000000"}')"
expect_success C2 C2b.tokens_withdrawable_to_wallet c11_pull_out
sc c12_user_after_pullout user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_num C2 C2b.wallet_balance_after_pullout "950" "$(field c12_user_after_pullout bltVaultBalance)"

log "--- rewards while frozen ---"
tx c13_move_tokens  admin_move_tokens.cdc  blocto "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}')"
expect_success C2 C2c.move_tokens_while_frozen c13_move_tokens
sc c14_info_after_move staker_info.cdc "$ID_ARG"
assert_num C2 C2c.tokens_now_staked "50" "$(field c14_info_after_move tokensStaked)"
tx c15_pay_rewards  admin_pay_rewards.cdc  blocto "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}')"
expect_success C2 C2c.pay_rewards_while_frozen c15_pay_rewards
sc c16_info_after_rewards staker_info.cdc "$ID_ARG"
assert_num C2 C2c.reward_paid_into_rewarded_bucket "1" "$(field c16_info_after_rewards tokensRewarded)"

tx c17_withdraw_rewarded user_withdraw_rewarded.cdc user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"1.00000000"}')"
expect_success C2 C2c.withdraw_rewarded_tokens_while_frozen c17_withdraw_rewarded
sc c18_info_after_reward_withdraw staker_info.cdc "$ID_ARG"
assert_num C2 C2c.rewarded_bucket_emptied "0" "$(field c18_info_after_reward_withdraw tokensRewarded)"
sc c19_user_after_reward_withdraw user_state.cdc "$(addr_arg "$USER_ADDR")"
assert_num C2 C2c.reward_landed_in_pass_vault "1" "$(field c19_user_after_reward_withdraw passVaultBalance)"

log "--- negative control: the SAME frozen state does gate the staking direction ---"
tx c20_stake_unstaked_frozen neg_user_stake_unstaked_frozen.cdc user "$(json_args '{"type":"UInt64","value":"'"$PASS_ID"'"}' '{"type":"UFix64","value":"1.00000000"}')"
expect_revert C2 C2d.staking_direction_still_gated c20_stake_unstaked_frozen \
    "Cannot stake if the staking auction isn't in progress"

# ---------------------------------------------------------------- C3 ---------
log "=== phase D: C3 -- entitlement / admin isolation ==="
tx d1_private_call atk_private_call_via_public_cap.cdc blocto "$(addr_arg "$USER_ADDR")"
expect_checker_reject C3 C3a.private_call_not_compilable_through_public_cap d1_private_call 'has no member .borrowBloctoPassPrivate'
tx d1b_private_call_plain atk_private_call_via_plain_concrete.cdc blocto "$(addr_arg "$USER_ADDR")"
expect_checker_reject C3 C3a.entitled_call_not_compilable_even_after_narrowing d1b_private_call_plain 'requires .*authorization|unauthorized|entitlement'
tx d2_private_probe atk_private_cap_probe.cdc blocto "$(addr_arg "$USER_ADDR")"
expect_success C3 C3a.no_private_reference_from_public_capability d2_private_probe
tx d3_admin_probe atk_staking_admin_probe.cdc user "$(addr_arg "$BLOCTO_ADDR")"
expect_success C3 C3b.staking_admin_unreachable_from_outside d3_admin_probe
tx d4_admin_other_storage atk_staking_admin_other_storage.cdc user "$(addr_arg "$BLOCTO_ADDR")"
expect_checker_reject C3 C3b.other_account_storage_not_accessible d4_admin_other_storage 'cannot access .borrow. because function requires .Storage'

log "=== done: scenario executed ==="
log "slowest steps: $(for f in "$STEPS"/*.dur; do printf '%s %s\n' "$(cat "$f")" "$(basename "$f" .dur)"; done 2>/dev/null | sort -rn | head -8 | tr '\n' ' ')"
finish 0
