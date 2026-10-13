#!/usr/bin/env bash
# Nuri CL (Scroll) — custom CI job: heavy read-only enumeration.
# No secrets are read or printed. Keyless public Scroll RPC only.
# Enumeration is best-effort (the forge suite is the primary evidence);
# a transient public-RPC failure must not skip the PoC tests.
set -uo pipefail
cd "$(dirname "$0")/.."
echo "== Nuri CL enumeration =="
if ! python3 ci/enumerate.py; then
  echo "== ENUMERATION FAILED (non-fatal; see above) =="
fi
echo "== done =="
exit 0
