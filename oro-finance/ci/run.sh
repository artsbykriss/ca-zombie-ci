#!/usr/bin/env bash
# oro-finance heavy/reproducible job (GitHub Actions).
#
# Re-runs the read-only gating simulations against the live Oro Finance core program on Solana
# mainnet and writes the evidence to ci-out/. No secrets, no keyed RPC URLs, no transactions
# are signed or sent: everything is simulateTransaction(sigVerify=false).
#
# NOTE: this job is network-bound, not CPU-bound; it is run in CI so the evidence is
# independently reproducible from a clean machine.
set -uo pipefail
cd "$(dirname "$0")/.."          # -> oro-finance/
mkdir -p ci-out

python3 -m pip install --quiet --disable-pip-version-check solders==0.29.0 || true
python3 -c "import solders, sys; print('solders ok', solders.__version__ if hasattr(solders,'__version__') else '')" || exit 1

export PYTHONPATH="$PWD/analysis"
OUT=ci-out/oro_sim_results.txt
: > "$OUT"

echo "### environment" | tee -a "$OUT"
date -u | tee -a "$OUT"
python3 - <<'PY' 2>&1 | tee -a "$OUT"
import sys
sys.path.insert(0, "analysis")
import rpc2
print("endpoints (keyless):", [e.split('?')[0][:38] for e in rpc2.endpoints()])
print("slot:", rpc2.call("getSlot", [{"commitment": "finalized"}]))
PY

run_case () {  # $1 = label, rest = KEY=VAL overrides for sim_sell.py
  local label="$1"; shift
  echo "" | tee -a "$OUT"
  echo "### $label" | tee -a "$OUT"
  python3 analysis/sim_sell.py "$@" 2>&1 | tee -a "$OUT"
}

# --- control: replay the real Sell tx (account layout recovered from slot 441901540) --------
run_case "CONTROL sell (real layout, no substitution)" 
# --- E-U test 1: substitute the caller-supplied Pyth price account ------------------------
run_case "TEST pyth_price := SOL/USD PriceUpdateV2 (feed substitution)" \
         pyth_price=11CBincUUU7WZiNrvw8HeMvrbepXdxxNKs92BXC5y35
run_case "TEST pyth_price := different XAU/USD PriceUpdateV2 account" \
         pyth_price=12dE9PgzF3YXr9uaibS1RNUixKJkuw5diBVS8SuUtx3o
# --- E-U test 2: substitute the seller's whitelist PDA -----------------------------------
run_case "TEST whitelist := another wallet's whitelist PDA" \
         whitelist=C2GM9BrMcYncU1UJgMi5hnUictDJpVY7a4KhvZ59Bk4S
# --- E-U test 3: substitute the protocol vaults ------------------------------------------
run_case "TEST vault_b (USDC vault) := seller's own USDC ATA" \
         vault_b=RHprvisJEt9aYzQcnbH7unxpcAtBZHKbBsTbLErpTQc
# --- E-U test 4: substitute the Price PDA ------------------------------------------------
run_case "TEST price_account := GOLD vault token account" \
         price_account=BTfWpVQahbeUyhtwN7ATFjmBdv1wfdVPR5K6oYAnWHrx
# --- E-U test 5: unprivileged seller -----------------------------------------------------
run_case "TEST seller := non-whitelisted attacker wallet" \
         seller=7orgFWEBNCsqspUTX8AZurjRfHrgRYZiswm4ewqJmH9E \
         authority=7orgFWEBNCsqspUTX8AZurjRfHrgRYZiswm4ewqJmH9E

# --- update_price: admin address constraint ---------------------------------------------
echo "" | tee -a "$OUT"
echo "### TEST update_price with unprivileged signer (admin address constraint)" | tee -a "$OUT"
python3 - <<'PY' 2>&1 | tee -a "$OUT"
import sys
sys.path.insert(0, "analysis")
from explore import run
A = "7orgFWEBNCsqspUTX8AZurjRfHrgRYZiswm4ewqJmH9E"
HKMT = "HKMT2i4kGzktb4AVo4fKkHK4AmpxVyvGEAfotVX3tML4"
SYS = "11111111111111111111111111111111"
run("update_price", "00" * 40, [(A, True, True), (HKMT, False, True), (SYS, False, False)]
    + [(A, False, True)] * 8)
PY

echo "" | tee -a "$OUT"
echo "### live state" | tee -a "$OUT"
python3 - <<'PY' 2>&1 | tee -a "$OUT"
import sys, json
sys.path.insert(0, "analysis")
import rpc2
slot = rpc2.call("getSlot", [{"commitment": "finalized"}])
mint = rpc2.call("getAccountInfo", ["GoLDppdjB1vDTPSGxyMJFqdnj134yH6Prg9eqsGDiw6A",
                                    {"encoding": "jsonParsed"}])["value"]["data"]["parsed"]["info"]
print("slot", slot)
print("GOLD supply", mint["supply"], "mintAuthority", mint["mintAuthority"], "freeze", mint["freezeAuthority"])
r = rpc2.call("getTokenAccountsByOwner",
              ["HKMT2i4kGzktb4AVo4fKkHK4AmpxVyvGEAfotVX3tML4",
               {"programId": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},
               {"encoding": "jsonParsed"}])
for x in r["value"]:
    i = x["account"]["data"]["parsed"]["info"]
    print("protocol vault", x["pubkey"], i["mint"], i["tokenAmount"]["amount"])
PY

echo "" | tee -a "$OUT"
echo "DONE" | tee -a "$OUT"
