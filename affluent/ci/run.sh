#!/usr/bin/env bash
# Affluent (TON) heavy job — runs in GitHub Actions (cwd = finding folder root).
# Installs the native TON emulator bindings (tonpy, public PyPI) and runs the
# read-only TVM emulation harness. Writes results to ci-out/ (uploaded artifact).
# No secrets, no transactions.
set -uo pipefail
echo "[affluent-ci] python: $(python3 --version 2>&1)"
python3 -m pip install --quiet --disable-pip-version-check "tonpy==0.0.0.1.4rc0" 2>&1 | tail -3
mkdir -p ci-out
echo "[affluent-ci] running ton_emu.py ..."
TON_EMU_OUT="$PWD/ci-out" python3 ci/ton_emu.py
echo "[affluent-ci] running ton_chain.py (decisive live-path chain) ..."
TON_EMU_OUT="$PWD/ci-out" python3 ci/ton_chain.py
echo "[affluent-ci] results:"
ls -la ci-out || true
python3 - <<'PY' || true
import json
for f,label in [("ci-out/ton_emu_results.json","ton_emu"),("ci-out/ton_chain_results.json","ton_chain")]:
    try:
        d=json.load(open(f)); print(label, json.dumps(d)[:500])
    except Exception as e:
        print(label, "err", e)
PY
