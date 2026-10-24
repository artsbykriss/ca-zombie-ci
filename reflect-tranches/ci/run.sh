#!/usr/bin/env bash
# Heavy job for reflect-tranches. READ-ONLY: nothing is signed for broadcast or sent.
#  1) read-only simulateTransaction replays of REAL mainnet txs (control + role-less signer)
#  2) LiteSVM harness: deployed ELFs + cloned accounts + a fresh signer
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"
mkdir -p ci-out

export CARGO_TERM_COLOR=never
export RUST_BACKTRACE=1

echo "[ci] python read-only replay (single-instruction, VALIDATED control)"
python3 -m pip install --quiet --disable-pip-version-check solders 2>/dev/null \
  || pip3 install --quiet solders 2>/dev/null || true
python3 -u analysis/sim_real.py > ci-out/sim_real.txt 2>&1 || echo "[ci] sim_real exited non-zero"
tail -30 ci-out/sim_real.txt || true

echo "[ci] python read-only whole-tx replay (control + role-less signer)"
python3 -u analysis/sim_real2.py > ci-out/sim_real2.txt 2>&1 || echo "[ci] sim_real2 exited non-zero"
tail -20 ci-out/sim_real2.txt || true

if ! command -v cargo >/dev/null 2>&1; then
  echo "[ci] installing rust toolchain"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable >/dev/null
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
fi
rustc --version || true

cd poc
echo "[ci] building LiteSVM harness"
cargo build --release 2>&1 | tail -20
echo "[ci] running LiteSVM harness"
set +e
cargo run --release --quiet -- "$PWD" 2>&1 | tee "$HERE/ci-out/litesvm-auth.txt"
RC=${PIPESTATUS[0]}
set -e
echo "[ci] harness exit=$RC"

cd "$HERE"
python3 - <<'PY' | tee ci-out/sanity.json
import json, os, re
out = {"ok": True}
s1 = open("ci-out/sim_real.txt").read() if os.path.exists("ci-out/sim_real.txt") else ""
out["claim_fees_control_success"] = "[A CONTROL (real signer)] err = None" in s1
out["claim_fees_unpriv_rejected"] = bool(re.search(r"\[B UNPRIVILEGED signer\] err = \{'InstructionError'", s1))
hv = open("ci-out/litesvm-auth.txt").read() if os.path.exists("ci-out/litesvm-auth.txt") else ""
out["create_permission_ok"] = bool(re.search(r"\[OK \] create_permission_account", hv))
out["attacker_zero_roles"] = "roles tail = 0000000000000000000000000000" in hv
out["supremo_gate_passed"] = bool(re.search(r"real SUPREMO -> InstructionError\(0, Custom\(6001\)\)", hv))
out["claim_fees_real_authority_ok"] = bool(re.search(r"\[OK \] real proxy authority", hv))
out["attacker_rejections"] = len(re.findall(r"\[ERR\].*attacker", hv))
print(json.dumps(out, indent=1))
PY
echo "DONE"
